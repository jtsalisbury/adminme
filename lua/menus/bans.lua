local banListScroll, mainSection
local activeBan
local banListLayout

local function showBanInfo(sid, info)
	banListLayout:Clear()
	activeBan = sid

	for i = 1, #info.bans do
		local banInfo = info.bans[i]

			// Container panel
		local banPnl = vgui.Create("am.HeaderPanel", banListLayout)
		banPnl:SetSize(mainSection:GetWide() - 20, 200)
		banPnl:SetHHeight(80)
		banPnl:SetHText(banInfo.banned_name .. " - " .. banInfo.banned_steamid)

		// Holds all records
		local liLay = vgui.Create("DIconLayout", banPnl)
		liLay:SetPos(10, 50)
		liLay:SetSpaceY(5)
		liLay:SetSize(banPnl:GetWide() - 30, banPnl:GetTall() - 60)
		
		local bs_w = liLay:GetWide()

		// Banned at
		local ban_at = vgui.Create("DLabel", liLay)
		ban_at:SetText("Banned At: " .. os.date("%m/%d/%Y %r", tonumber(banInfo.banned_timestamp)))
		ban_at:SetFont("adminme_section_btn")
		ban_at:SetSize(bs_w, 25)
		ban_at:SetTextColor(cols.main_btn_text)

		// Get the duration and length string
		local lenStr = os.date("%m/%d/%Y %r", tonumber(banInfo.banned_timestamp) + banInfo.banned_time) .. " - length (".. banInfo.banned_time .."s)"
		if (banInfo.banned_time == 0) then
			lenStr = "indefinitely"
		end 

		// Banned length and duration
		local ban_len = vgui.Create("DLabel", liLay)
		ban_len:SetText("Banned Until: " .. lenStr)
		ban_len:SetFont("adminme_section_btn")
		ban_len:SetSize(bs_w, 30)
		ban_len:SetTextColor(cols.main_btn_text)

		// Banned server
		local ban_scope = vgui.Create("DLabel", liLay)
		ban_scope:SetText("Banned On: " .. ndoc.table.am.servers[banInfo.serverid].name)
		ban_scope:SetFont("adminme_section_btn")
		ban_scope:SetSize(bs_w, 30)
		ban_scope:SetTextColor(cols.main_btn_text)

		// Who did the banning
		local banner = vgui.Create("DLabel", liLay)
		banner:SetText("Banner: " .. banInfo.banner_name .. " (" .. banInfo.banner_steamid .. ")")
		banner:SetFont("adminme_section_btn")
		banner:SetSize(bs_w, 30)
		banner:SetTextColor(cols.main_btn_text)

		// Need to adjust panel size to properly wrap
		// Normally I'd use SetAutoStretchVertical, but it doesn't seem to work correctly with GetTall
		local reasonText = "Reason: " .. banInfo.banned_reason
		local reasonHeight = am.getVerticalSize(reasonText, "adminme_btn_small", bs_w - 20)
		
		// Why were they banned
		local reason = vgui.Create("DLabel", liLay)
		reason:SetText(reasonText)
		reason:SetFont("adminme_section_btn")
		reason:SetSize(bs_w, reasonHeight)
		reason:SetTextColor(cols.main_btn_text)
		reason:SetWrap(true)

		// Ban controls
		local container = vgui.Create("DPanel", liLay)
		container:SetSize(bs_w, 35)
		function container:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
		end

		local unban = vgui.Create("DButton", container)
		unban:SetSize(175, 35)
		unban:SetPos(0, 0)
		unban:SetText("")
		function unban:Paint(w, h)
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
		function unban:DoClick()
			RunConsoleCommand("am_unban", banInfo.banned_steamid, banInfo.serverid, false)

			timer.Simple(1, function()
				net.Start("am.requestBanList")
				net.SendToServer()
			end)
		end

		local removeBan = vgui.Create("DButton", container)
		removeBan:SetSize(175, 35)
		removeBan:SetPos(180, 0)
		removeBan:SetText("")
		function removeBan:Paint(w, h)
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
			draw.SimpleText("Delete Ban", "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		function removeBan:DoClick()
			RunConsoleCommand("am_unban", banInfo.banned_steamid, banInfo.serverid, true)

			timer.Simple(1, function()
				net.Start("am.requestBanList")
				net.SendToServer()
			end)
		end

		// All panel heights + the header height + buffer + space between panels
		local panelHeight = ban_at:GetTall() + ban_len:GetTall() + ban_scope:GetTall() + banner:GetTall() + reasonHeight + unban:GetTall() + 55 + 30
		banPnl:SetTall(panelHeight)
		liLay:SetSize(banPnl:GetWide() - 20, banPnl:GetTall() - 40)

	end
end

local banList = nil;
local function repopulateList(scroller, main, search_text) 
	scroller:Clear()
	if (!banList) then
		return
	end

	// Spacer for the search control
	local spacer = vgui.Create("DPanel", scroller)
	spacer:SetSize(scroller:GetWide(), 50)
	function spacer:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 0))
	end

	// Add all active bans
	local tW, tH = surface.GetTextSize("X")
	for sid, info in pairs(banList) do
		// Names and steamids 
		if (!string.find(info.nick, search_text) && !string.find(sid, search_text) && search_text != "") then
			continue
		end

		// Button to bring up a specific ban
		local btn = scroller:Add("DButton")
		btn:SetText("")
		btn:SetSize(scroller:GetWide(), tH + 20)
		function btn:DoClick()
			showBanInfo(sid, info)
		end
		function btn:Paint(w, h)
			local col = cols.item_btn_bg
			local textCol = cols.item_btn_text

			// Hovered
			if (self:IsHovered()) then
				col = cols.item_btn_bg_hover
				textCol = cols.item_btn_text_hover
			end

			// Active
			local adjustedWidth = w - 20
			if (activeBan == sid) then
				col = cols.item_btn_bg_active
				textCol = cols.item_btn_text_active
				adjustedWidth = w - 10
			end

			draw.RoundedBox(0, 10, 0, adjustedWidth, h, col)
			draw.SimpleText(info.nick != "n/a" && info.nick || sid .. " (" .. #info.bans..")", "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
end

// Received once we ask for the bans
net.Receive("am.syncBanList", function()
	local res = net.ReadTable()

	// Clear the ban list and section after an update
	banListScroll:Clear()
	banListLayout:Clear()

	activeBan = nil

	// No bans
	if (#res == 0) then return end

	// Add all the bans for by steamid
	banList = {}
	for k,ban in pairs(res) do
		banList[ ban["banned_steamid"] ] = banList[ ban["banned_steamid"] ] || {
			nick = ban["banned_name"],
			bans = {}
		}

		table.insert(banList[ ban["banned_steamid"] ].bans, ban)
	end

	repopulateList(banListScroll, mainSection, "")
end)

hook.Add("AddAdditionalMenuSections", "am.addBanMenu", function(stor)
	local function populateList(scroller, main, frame)
		main:Clear()
		activeBan = nil

		mainSection = main
		banListScroll = scroller

		// Main scrollpanel for bans
		local banScroll = vgui.Create("DScrollPanel", main)
		banScroll:SetSize(main:GetWide() - 20, main:GetTall() - 20)
		banScroll:SetPos(10, 10)

		// Hide the scrollbar
		local sbar = banScroll:GetVBar()
		sbar:SetSize(0, 0)

		// Layout for all the bans
		banListLayout = vgui.Create("DIconLayout", banScroll)
		banListLayout:SetSize(banScroll:GetWide(), banScroll:GetTall())
		banListLayout:SetPos(0, 0)
		banListLayout:SetSpaceY(10)

		// Background for the search control
		local posX = frame:GetWide() - main:GetWide() - scroller:GetWide()
		local search_bg = vgui.Create("DPanel", frame)
		search_bg:SetSize(scroller:GetWide(), 50)
		search_bg:SetPos(posX, 0)
		function search_bg:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, cols.item_scroll_bg)
		end

		// Search control
		local search = vgui.Create("am.DTextEntry", search_bg)
		search:SetSize(search_bg:GetWide() - 20, search_bg:GetTall() - 20)
		search:SetPos(10, 10)
		search:SetFont("adminme_ctrl")
		search:SetPlaceholder("Search for user...")

		frame.extras = {search_bg, search}

		// Repopulate on change
		function search:OnChange()
			repopulateList(scroller, main, self:GetText())
		end

		// Grab the bans
		net.Start("am.requestBanList")
		net.SendToServer()
	end
	if (LocalPlayer():hasPerm("banmgmt")) then
		stor["Bans"] = {cback = populateList, useItemList = true}
	end
end)
