local banScroll, banListScroll

local function showBanInfo(k, v)
	banScroll:Clear()

	local bs_w = banScroll:GetWide()
	local offset_y = 5

	local name_id = vgui.Create("DLabel", banScroll)
	name_id:SetText("Banned User: " .. v["banned_name"] .. " (" .. v["banned_steamid"]..")")
	name_id:SetFont("adminme_btn")
	name_id:SetTextColor(cols.main_btn_text)
	name_id:SetSize(bs_w, 30)
	name_id:SetPos(0, offset_y)

	offset_y = offset_y + name_id:GetTall() + 10

	local ban_at = vgui.Create("DLabel", banScroll)
	ban_at:SetText("Banned At: " .. os.date("%m/%d/%Y %r", tonumber(v["banned_timestamp"])))
	ban_at:SetFont("adminme_btn")
	ban_at:SetSize(bs_w, 25)
	ban_at:SetTextColor(cols.main_btn_text)
	ban_at:SetPos(0, offset_y)

	offset_y = offset_y + ban_at:GetTall() + 10

	local ban_len = vgui.Create("DLabel", banScroll)
	ban_len:SetText("Banned Until: " .. os.date("%m/%d/%Y %r", tonumber(v["banned_timestamp"]) + v["banned_time"]) .. " - length (".. v["banned_time"] .."s)")
	ban_len:SetFont("adminme_btn")
	ban_len:SetSize(bs_w, 30)
	ban_len:SetTextColor(cols.main_btn_text)
	ban_len:SetPos(0, offset_y)

	offset_y = offset_y + ban_len:GetTall() + 10

	local banner = vgui.Create("DLabel", banScroll)
	banner:SetText("Banner: " .. v["banner_name"] .. "(" .. v["banned_steamid"] .. ")")
	banner:SetFont("adminme_btn")
	banner:SetSize(bs_w, 30)
	banner:SetTextColor(cols.main_btn_text)
	banner:SetPos(0, offset_y)

	offset_y = offset_y + banner:GetTall() + 10

	local reason = vgui.Create("DLabel", banScroll)
	reason:SetText("Reason: " .. v["banned_reason"])
	reason:SetFont("adminme_btn")
	reason:SetSize(bs_w, 30)
	reason:SetTextColor(cols.main_btn_text)
	reason:SetPos(0, offset_y)

	local delete_btn = vgui.Create("DButton", banScroll)
	delete_btn:SetSize(175, 40)
	delete_btn:SetPos(banScroll:GetWide() - 180, banScroll:GetTall() - 45)
	delete_btn:SetText("Set Ban Inactive")
	function delete_btn:DoClick()
		RunConsoleCommand("am_unban", v["banned_steamid"])

		timer.Simple(1, function()
			net.Start("am.requestBanList")
			net.SendToServer()
		end)
	end
end

net.Receive("am.syncBanList", function()
	local res = net.ReadTable()

	banListScroll:Clear()
	banScroll:Clear()

	if (#res == 0) then return end

	for k, v in pairs(res) do
		local btn = banListScroll:Add("DButton")
		btn:SetText("")
		btn:SetSize(banListScroll:GetWide(), 50)
		function btn:DoClick()
			showBanInfo(k, v)
		end
		function btn:Paint(w, h)
			local col = cols.main_btn

			if (self:IsHovered() or activePlayer == k) then
				col = cols.main_btn_hover
			end

			draw.RoundedBox(0, 0, 0, w, h, col)
			draw.SimpleText(v["banned_name"], "adminme_btn_small", w / 2, h / 4, cols.main_btn_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("ID: " .. v["banned_steamid"], "adminme_btn_small", w / 2, 3 * h / 4, cols.main_btn_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
end)

hook.Add("AddAdditionalMenuSections", "am.addBanMenu", function(stor)
	local function populateList(scroller, main)
		main:Clear()

		net.Start("am.requestBanList")
		net.SendToServer()

		banListScroll = scroller

		banScroll = vgui.Create("DScrollPanel", main)
		banScroll:SetSize(main:GetWide() - 40, main:GetTall() - 10)
		banScroll:SetPos(35, 5)

		local liLay = vgui.Create("DIconLayout", banScroll)
		liLay:SetSize(banScroll:GetWide(), banScroll:GetTall())
		liLay:SetPos(0, 0)
		liLay:SetSpaceY(5)

		local sbar = banScroll:GetVBar()

		function sbar:Paint( w, h )
			draw.RoundedBox( 0, 0, 0, w, h, cols.main_btn)
		end
		function sbar.btnUp:Paint( w, h )
			draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 100 ) )
		end
		function sbar.btnDown:Paint( w, h )
			draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 100 ) )
		end
		function sbar.btnGrip:Paint( w, h )
			draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 100 ) )
		end
	end
	if (LocalPlayer():hasPerm("banmgmt")) then
		stor["Bans"] = populateList
	end
end)
