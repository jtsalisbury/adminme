local banListScroll, mainSection
local activeBan

local function showBanInfo(k, v)
	mainSection:Clear()
	activeBan = v["banned_name"]

	local banPnl = vgui.Create("am.HeaderPanel", mainSection)
	banPnl:SetSize(mainSection:GetWide() - 20, mainSection:GetTall() - 20)
	banPnl:SetHHeight(80)
	banPnl:SetHText(v["banned_name"] .. " - " .. v["banned_steamid"])
	banPnl:SetPos(10, 10)

	local liLay = vgui.Create("DIconLayout", banPnl)
	liLay:SetSize(banPnl:GetWide() - 30, banPnl:GetTall() - 70)
	liLay:SetPos(15, 55)
	liLay:SetSpaceY(8)

	local bs_w = liLay:GetWide()

	local ban_at = vgui.Create("DLabel", liLay)
	ban_at:SetText("Banned At: " .. os.date("%m/%d/%Y %r", tonumber(v["banned_timestamp"])))
	ban_at:SetFont("adminme_section_btn")
	ban_at:SetSize(bs_w, 25)
	ban_at:SetTextColor(cols.main_btn_text)

	local ban_len = vgui.Create("DLabel", liLay)
	ban_len:SetText("Banned Until: " .. os.date("%m/%d/%Y %r", tonumber(v["banned_timestamp"]) + v["banned_time"]) .. " - length (".. v["banned_time"] .."s)")
	ban_len:SetFont("adminme_section_btn")
	ban_len:SetSize(bs_w, 30)
	ban_len:SetTextColor(cols.main_btn_text)

	local banner = vgui.Create("DLabel", liLay)
	banner:SetText("Banner: " .. v["banner_name"] .. "(" .. v["banned_steamid"] .. ")")
	banner:SetFont("adminme_section_btn")
	banner:SetSize(bs_w, 30)
	banner:SetTextColor(cols.main_btn_text)

	local reason = vgui.Create("DLabel", liLay)
	reason:SetText("Reason: " .. v["banned_reason"])
	reason:SetFont("adminme_section_btn")
	reason:SetSize(bs_w, 30)
	reason:SetTextColor(cols.main_btn_text)
	reason:SetWrap(true)

	local execute = vgui.Create("DButton", liLay)
	execute:SetSize(175, 35)
	execute:SetText("")
	function execute:Paint(w, h)
		local col = cols.main_btn_bg
		local textCol = cols.header_text

		if (self:IsHovered()) then
			col = cols.main_btn_hover
		end

		if (self:GetDisabled()) then
			col = cols.main_btn_disabled
		end

		draw.RoundedBox(0, 0, 0, w, h, cols.main_btn_outline)
		draw.RoundedBox(0, 1, 1, w - 2, h - 2, col)
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

local banList = nil;
local function repopulateList(scroller, main, search_text) 
	scroller:Clear()
	if (!banList) then
		return
	end

	local spacer = vgui.Create("DPanel", scroller)
	spacer:SetSize(scroller:GetWide(), 50)
	function spacer:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 0))
	end

	local tW, tH = surface.GetTextSize("X")
	for k, v in pairs(banList) do
		if (!string.find(v["banned_name"], search_text) && !string.find(v["banned_steamid"], search_text) && !string.find(v["banner_steamid"], search_text) && !string.find(v["banner_name"], search_text) && search_text != "") then
			continue
		end

		local btn = scroller:Add("DButton")
		btn:SetText("")
		btn:SetSize(scroller:GetWide(), tH + 10)
		function btn:DoClick()
			showBanInfo(k, v)
		end
		function btn:Paint(w, h)
			local col = cols.item_btn_bg
			local textCol = cols.item_btn_text

			if (self:IsHovered()) then
				col = cols.item_btn_bg_hover
				textCol = cols.item_btn_text_hover
			end

			local adjustedWidth = w - 20
			if (activeBan == v["banned_name"]) then
				col = cols.item_btn_bg_active
				textCol = cols.item_btn_text_active
				adjustedWidth = w - 10
			end

			draw.RoundedBox(0, 10, 0, adjustedWidth, h, col)
			draw.SimpleText(v["banned_name"], "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
end

net.Receive("am.syncBanList", function()
	local res = net.ReadTable()

	banListScroll:Clear()
	mainSection:Clear()

	activeBan = nil

	if (#res == 0) then return end

	banList = res
	repopulateList(banListScroll, mainSection, "")
end)

hook.Add("AddAdditionalMenuSections", "am.addBanMenu", function(stor)
	local function populateList(scroller, main, frame)
		main:Clear()
		activeBan = nil

		mainSection = main
		banListScroll = scroller

		local posX = frame:GetWide() - main:GetWide() - scroller:GetWide()
		local search_bg = vgui.Create("DPanel", frame)
		search_bg:SetSize(scroller:GetWide(), 50)
		search_bg:SetPos(posX, 0)
		function search_bg:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, cols.item_scroll_bg)
		end

		local search = vgui.Create("am.DTextEntry", search_bg)
		search:SetSize(search_bg:GetWide() - 20, search_bg:GetTall() - 20)
		search:SetPos(10, 10)
		search:SetFont("adminme_ctrl")
		search:SetPlaceholder("Search for ban...")

		frame.extras = {search_bg, search}

		function search:OnChange()
			repopulateList(scroller, main, self:GetText())
		end

		net.Start("am.requestBanList")
		net.SendToServer()
	end
	if (LocalPlayer():hasPerm("banmgmt")) then
		stor["Bans"] = {cback = populateList, useItemList = true}
	end
end)
