local activePlayer
local function showWarnings(sid, data, sc)
	activePlayer = sid

	sc:Clear()

	local nick      = data.nick
	local warnCount = data.warningCount
	local warnings  = data.warnings

	// Loop through and print each warning
	for k,warning in ndoc.pairs(warnings) do
		// Main panel
		local panel = sc:Add("am.HeaderPanel")
		panel:SetWide(sc:GetWide())
		panel:SetHHeight(80)
		panel:SetHText("Warning #" .. warning.warningNum)

		local height = 40

		// Admin that issued the warning
		local admin = vgui.Create("DLabel", panel)
		admin:SetPos(10, 10 + height)
		admin:SetText("Warned by: " .. warning.admin)
		admin:SetFont("adminme_btn_small")
		admin:SizeToContents()
		admin:SetTextColor(cols.main_btn_text)

		height = height + admin:GetTall() + 5

		// Time warned
		local time = vgui.Create("DLabel", panel)
		time:SetPos(10, 10 + height)
		time:SetText("Date / Time: " .. os.date("%m/%d/%Y at %I:%M%p", warning.timestamp))
		time:SetFont("adminme_btn_small")
		time:SizeToContents()
		time:SetTextColor(cols.main_btn_text)

		height = height + time:GetTall() + 5

		// Need to adjust panel size to properly wrap
		// Normally I'd use SetAutoStretchVertical, but it doesn't seem to work correctly with GetTall
		local reasonText = "Reason: " .. warning.reason
		local reasonHeight = am.getVerticalSize(reasonText, "adminme_btn_small", panel:GetWide() - 20)

		// Reason why
		local reason = vgui.Create("DLabel", panel)
		reason:SetPos(10, 10 + height)
		reason:SetText(reasonText)
		reason:SetFont("adminme_btn_small")
		reason:SetTextColor(cols.main_btn_text)
		reason:SetSize(panel:GetWide() - 20, reasonHeight)
		reason:SetWrap(true)

		height = height + reason:GetTall()

		panel:SetTall(height + 15)
	end
end

hook.Add("AddAdditionalMenuSections", "am.addWarningsMenu", function(stor)
	local function repopulateList(scroller, main, txt, liLay)
		scroller:Clear()

		// Spacer in the scroller to allow room for the search 
		local spacer = vgui.Create("DPanel", scroller)
		spacer:SetSize(scroller:GetWide(), 50)
		function spacer:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 0))
		end

		txt = string.lower(txt)

		// Loop through each warning
		for k,plyData in ndoc.pairs(ndoc.table.am.warnings) do
			// Match search text
			if (!string.find(string.lower(k), txt) and !string.find(string.lower(plyData.nick), txt)) then
				continue
			end

			surface.SetFont("adminme_btn_small")
			local tW, tH = surface.GetTextSize("X")

			// Print the name and # of warnings
			local btn = scroller:Add("DButton")
			btn:SetText("")
			btn:SetSize(scroller:GetWide(), tH + 20)
			function btn:DoClick()
				showWarnings(k, plyData, liLay)
			end
			function btn:Paint(w, h)
				local col = cols.item_btn_bg
				local textCol = cols.item_btn_text

				// Hovered button
				if (self:IsHovered()) then
					col = cols.item_btn_bg_hover
					textCol = cols.item_btn_text_hover
				end

				// Active button
				local adjustedWidth = w - 20
				if (activePlayer == k) then
					col = cols.item_btn_bg_active
					textCol = cols.item_btn_text_active
					adjustedWidth = w - 10
				end

				draw.RoundedBox(0, 10, 0, adjustedWidth, h, col)
				draw.SimpleText(plyData.nick .. " (" .. plyData.warningCount .. ")", "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
	end

	local function populateList(scroller, main, frame)
		main:Clear()
		activePlayer = nil

		// Main scrollpanel for names
		local warnScroll = vgui.Create("DScrollPanel", main)
		warnScroll:SetSize(main:GetWide() - 20, main:GetTall() - 10)
		warnScroll:SetPos(10, 10)

		// Layout for all the warnings
		local liLay = vgui.Create("DIconLayout", warnScroll)
		liLay:SetSize(warnScroll:GetWide(), warnScroll:GetTall())
		liLay:SetPos(0, 0)
		liLay:SetSpaceY(10)

		// Hide the scrollbar
		local sbar = warnScroll:GetVBar()
		sbar:SetSize(0, 0)

		// Search bar background
		local posX = frame:GetWide() - main:GetWide() - scroller:GetWide()
		local search_bg = vgui.Create("DPanel", frame)
		search_bg:SetSize(scroller:GetWide(), 50)
		search_bg:SetPos(posX, 0)
		function search_bg:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, cols.item_scroll_bg)
		end

		// Actual search utility
		local search = vgui.Create("am.DTextEntry", search_bg)
		search:SetSize(search_bg:GetWide() - 20, search_bg:GetTall() - 20)
		search:SetPos(10, 10)
		search:SetFont("adminme_ctrl")
		search:SetPlaceholder("Search for player...")

		frame.extras = {search_bg, search}

		// Repopulate on change
		function search:OnChange()
			repopulateList(scroller, main, self:GetText(), liLay)
		end

		// Default
		repopulateList(scroller, main, "", liLay)
	end
	if (LocalPlayer():hasPerm("warning")) then
		stor["Warnings"] = {cback = populateList, useItemList = true}
	end
end)