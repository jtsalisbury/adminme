hook.Add("AddAdditionalMenuSections", "am.addPlayerEventsSection", function(stor)

	local activePlayer
	local function loadEvents(target, main)
		main:Clear()
		activePlayer = target

		print(main:GetTall() - 10, main:GetWide() - 10)

		local li = vgui.Create("DScrollPanel", main)
		li:SetSize(main:GetWide() - 10, main:GetTall() - 10)
		li:SetPos(5, 5)

		local list = vgui.Create("DIconLayout", li)
		list:SetSize(li:GetWide(), li:GetTall())
		list:SetPos(0, 0)
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

		for k,v in ndoc.pairs(requests) do
			local ev = list:Add("DLabel")
			ev:SetText(os.date("%I:%M %p", k) .. " | " ..v)
			ev:SetFont("adminme_btn_small")
			ev:SetColor(cols.main_btn_text)
			ev:SizeToContents()

			function ev:DoRightClick()
				local menu = DermaMenu()
				menu:SetPos(gui.MousePos())
				menu:AddOption("Copy Line", function() SetClipboardText(k .. " | " .. v) end)

				menu:Open()
			end
		end
	end

	local function repopulateList(scroller, main, txt)
		scroller:Clear()
		
		local spacer = vgui.Create("DPanel", scroller)
		spacer:SetSize(scroller:GetWide(), 60)
		function spacer:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255))
		end

		for k,v in pairs(player.GetAll()) do
			txt = string.lower(txt)

			if (!string.find(string.lower(v:Nick()), txt) and !string.find(string.lower(v:SteamID()), txt)) then
				return
			end

			local btn = scroller:Add("DButton")
			btn:SetText("")
			btn:SetSize(scroller:GetWide() - 40, 50)
			btn.target = v
			function btn:DoClick()
				loadEvents(v, main)
			end
			function btn:Paint(w, h)
				local col = cols.item_btn_bg
				local textCol = Color(0, 0, 0)

				if (self:IsHovered()) then
					col = cols.item_btn_bg_hover
				end

				if (activePlayer == v) then
					col = cols.item_btn_bg_active
					textCol = cols.item_btn_text_active
				end

				draw.RoundedBox(8, 0, 0, w, h, col)
				draw.SimpleText(v:Nick(), "adminme_btn_small", 15, h / 2, textCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end
		end
	end

	local function populateList(scroller, main, frame)
		activePlayer = nil

		local search_bg = vgui.Create("DPanel", frame)
		search_bg:SetSize(scroller:GetWide(), 60)
		search_bg:SetPos(0, 60)
		function search_bg:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255))
		end

		local search = vgui.Create("am.DTextEntry", search_bg)
		search:SetSize(scroller:GetWide() - 40, 40)
		search:SetPos(10, 10)
		search:SetFont("adminme_ctrl")
		search:SetPlaceholder("Search...")

		frame.extras = {search_bg, search}

		function search:OnChange()
			repopulateList(scroller, main, self:GetText())
		end

		local search_bg = vgui.Create("DPanel", scroller)
		search_bg:SetSize(scroller:GetWide(), 35)
		function search_bg:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255))
		end

		repopulateList(scroller, main, "")
	end

	if (LocalPlayer():hasPerm("playerevents")) then
		stor["Player Events"] = populateList
	end
end)