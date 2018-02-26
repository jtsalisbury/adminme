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

	local function populateList(scroller, main)
		for k,v in pairs(player.GetAll()) do
			local btn = scroller:Add("DButton")
			btn:SetText("")
			btn:SetSize(scroller:GetWide(), 20)
			btn.target = v
			function btn:DoClick()
				loadEvents(v, main)
			end
			function btn:Paint(w, h)
				local col = cols.main_btn

				if (self:IsHovered() or activePlayer == v) then
					col = cols.main_btn_hover
				end

				draw.RoundedBox(0, 0, 0, w, h, col)
				draw.SimpleText(v:Nick(), "adminme_btn_small", w / 2, h / 2, cols.main_btn_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
	end

	if (LocalPlayer():hasPerm("playerevents")) then
		stor["Player Events"] = populateList
	end
end)