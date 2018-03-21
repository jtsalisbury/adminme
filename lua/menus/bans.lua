local banListScroll, mainSection
local activeBan

local function showBanInfo(k, v)
	mainSection:Clear()
	activeBan = v["banned_name"]


	local banPnl = vgui.Create("am.HeaderPanel", mainSection)
	banPnl:SetSize(mainSection:GetWide() - 50, mainSection:GetTall() - 50)
	banPnl:SetHHeight(80)
	banPnl:SetHText(v["banned_name"] .. " - " .. v["banned_steamid"])
	banPnl:SetPos(25, 25)

	local liLay = vgui.Create("DIconLayout", banPnl)
	liLay:SetSize(banPnl:GetWide() - 30, banPnl:GetTall() - 70)
	liLay:SetPos(15, 55)
	liLay:SetSpaceY(8)

	local bs_w = liLay:GetWide()

	local ban_at = vgui.Create("DLabel", liLay)
	ban_at:SetText("Banned At: " .. os.date("%m/%d/%Y %r", tonumber(v["banned_timestamp"])))
	ban_at:SetFont("adminme_header")
	ban_at:SetSize(bs_w, 25)
	ban_at:SetTextColor(cols.main_btn_text)

	local ban_len = vgui.Create("DLabel", liLay)
	ban_len:SetText("Banned Until: " .. os.date("%m/%d/%Y %r", tonumber(v["banned_timestamp"]) + v["banned_time"]) .. " - length (".. v["banned_time"] .."s)")
	ban_len:SetFont("adminme_header")
	ban_len:SetSize(bs_w, 30)
	ban_len:SetTextColor(cols.main_btn_text)

	local banner = vgui.Create("DLabel", liLay)
	banner:SetText("Banner: " .. v["banner_name"] .. "(" .. v["banned_steamid"] .. ")")
	banner:SetFont("adminme_header")
	banner:SetSize(bs_w, 30)
	banner:SetTextColor(cols.main_btn_text)

	local reason = vgui.Create("DLabel", liLay)
	reason:SetText("Reason: " .. v["banned_reason"])
	reason:SetFont("adminme_header")
	reason:SetSize(bs_w, 30)
	reason:SetTextColor(cols.main_btn_text)

	local bgPnl = vgui.Create("DPanel", liLay)
	bgPnl:SetSize(liLay:GetWide(), 100)
	function bgPnl:Paint( w, h )
		draw.RoundedBox(8, 0, 0, w, h, cols.ctrl_text_entry)
		draw.RoundedBox(8, 1, 1, w - 2, h - 2, cols.ctrl_text_disabled)
	end

	local layout = vgui.Create("DIconLayout", bgPnl)
	layout:SetSize(bgPnl:GetWide() - 30, 35)
	layout:SetPos(15, 32.5)
	layout:SetSpaceY(100)
	layout:SetSpaceX(0)

	local execute = vgui.Create("DButton", layout)
	execute:SetSize(175, 35)
	execute:SetText("")
	function execute:Paint(w, h)
		local col = cols.main_btn_bg
		local textCol = Color(0, 0, 0)

		if (self:IsHovered()) then
			col = cols.main_btn_hover
		end

		if (self:GetDisabled()) then
			col = cols.main_btn_disabled
		end

		draw.RoundedBox(4, 0, 0, w, h, cols.main_btn_outline)
		draw.RoundedBox(4, 1, 1, w - 2, h - 2, col)
		draw.SimpleText("Set Ban Inactive", "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	function execute:DoClick()
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
	mainSection:Clear()

	activeBan = nil

	if (#res == 0) then return end

	local spacer = vgui.Create("DPanel", banListScroll)
	spacer:SetSize(banListScroll:GetWide(), 5)
	function spacer:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255))
	end

	for k, v in pairs(res) do
		local btn = banListScroll:Add("DButton")
		btn:SetText("")
		btn:SetSize(banListScroll:GetWide() - 40, 50)
		function btn:DoClick()
			showBanInfo(k, v)
		end
		function btn:Paint(w, h)
			local col = cols.item_btn_bg
			local textCol = Color(0, 0, 0)

			if (self:IsHovered()) then
				col = cols.item_btn_bg_hover
			end

			if (activeBan == v["banned_name"]) then
				col = cols.item_btn_bg_active
				textCol = cols.item_btn_text_active
			end

			draw.RoundedBox(8, 0, 0, w, h, col)
			draw.SimpleText(v["banned_name"], "adminme_btn_small", 15, h / 2, textCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end
end)

hook.Add("AddAdditionalMenuSections", "am.addBanMenu", function(stor)
	local function populateList(scroller, main)
		main:Clear()
		activeBan = nil

		mainSection = main

		net.Start("am.requestBanList")
		net.SendToServer()

		banListScroll = scroller
	end
	if (LocalPlayer():hasPerm("banmgmt")) then
		stor["Bans"] = populateList
	end
end)
