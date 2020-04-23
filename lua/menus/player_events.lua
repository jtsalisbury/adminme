hook.Add("AddAdditionalMenuSections", "am.addPlayerEventsSection", function(stor)

	local activePlayer
	local function loadEvents(target, main)
		main:Clear()
		activePlayer = target

		local li = vgui.Create("DScrollPanel", main)
		li:SetSize(main:GetWide(), main:GetTall())
		li:SetPos(0, 0)
		local scB = li:GetVBar()
		scB:SetSize(0, 0)

		local list = vgui.Create("DIconLayout", li)
		list:SetSize(li:GetWide() - 20, li:GetTall() - 20)
		list:SetPos(10, 10)
		list:SetSpaceY(0);
		list:SetSpaceX(list:GetWide())

		local requests = ndoc.table.am.events[ target:SteamID() ]

		if (!requests) then
			local msg = list:Add("DLabel")
			msg:SetText("No events for this player!")
			msg:SetFont("adminme_btn_small")
			msg:SetColor(cols.main_btn_text)
			msg:SizeToContents()

			return
		end

		local tW, tH = surface.GetTextSize("X")
		for time,reasonStr in ndoc.pairs(requests) do
			// Custom wrap it, I want extra padding on the left side
			local str = Wrap(os.date("%I:%M %p", time) .. " | " ..reasonStr, list:GetWide() - 30)

			// Event form control
			local ev = list:Add("DLabel")
			ev:SetText('')
			ev:SetFont("adminme_btn_small")
			ev:SetSize(list:GetWide(), #str * (tH + 6) + 30)
			ev:SetColor(cols.main_btn_text)
			ev:SetMouseInputEnabled( true )
			function ev:Paint(w, h)
				draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255))
				draw.RoundedBox(0, 0, h - 1, w, 1, cols.header_underline)

				// Wrap each part of the string
				for k,v in pairs(str) do
					draw.DrawText(v, "adminme_btn_small", 15, (k - 1) * (tH + 6) + 18, cols.main_btn_text, TEXT_ALIGN_LEFT)					
				end
			end

			// Event right click
			function ev:DoRightClick()
				// Create the right click menu
				local menu = DermaMenu()
				menu:SetPos(gui.MousePos())
				menu:AddOption("Copy Line", function() SetClipboardText(os.date("%I:%M %p", time) .. " | " .. reasonStr) end)

				menu:Open()
			end
		end
	end

	local function repopulateList(scroller, main, txt)
		scroller:Clear()
		
		// Spacer for the search control
		local spacer = vgui.Create("DPanel", scroller)
		spacer:SetSize(scroller:GetWide(), 50)
		function spacer:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 0))
		end

		txt = string.lower(txt)
		for k,v in pairs(player.GetAll()) do
			// Match to search critera
			if (!string.find(string.lower(v:Nick()), txt) and !string.find(string.lower(v:SteamID()), txt)) then
				continue
			end
			
			surface.SetFont("adminme_btn_small")
			local tW, tH = surface.GetTextSize(v:Nick())

			// Create the button for the player
			local btn = scroller:Add("DButton")
			btn:SetText("")
			btn:SetSize(scroller:GetWide(), tH + 20)
			btn.target = v
			function btn:DoClick()
				loadEvents(v, main)
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
				if (activePlayer == v) then
					col = cols.item_btn_bg_active
					textCol = cols.item_btn_text_active
					adjustedWidth = w - 10
				end

				draw.RoundedBox(0, 10, 0, adjustedWidth, h, col)
				draw.SimpleText(v:Nick(), "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
	end

	local function populateList(scroller, main, frame)
		activePlayer = nil

		// Add the search background
		local posX = frame:GetWide() - main:GetWide() - scroller:GetWide()
		local search_bg = vgui.Create("DPanel", frame)
		search_bg:SetSize(scroller:GetWide(), 50)
		search_bg:SetPos(posX, 0)
		function search_bg:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, cols.item_scroll_bg)
		end

		// Add the search bar
		local search = vgui.Create("am.DTextEntry", search_bg)
		search:SetSize(search_bg:GetWide() - 20, search_bg:GetTall() - 20)
		search:SetPos(10, 10)
		search:SetFont("adminme_ctrl")
		search:SetPlaceholder("Search for player...")

		frame.extras = {search_bg, search}

		// Repopulate on change
		function search:OnChange()
			repopulateList(scroller, main, self:GetText())
		end

		// Default
		repopulateList(scroller, main, "")
	end

	if (LocalPlayer():hasPerm("playerevents")) then
		stor["Player Events"] = {cback = populateList, useItemList = true}
	end
end)