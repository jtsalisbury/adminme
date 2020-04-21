local function isOnline(sid) 
	for k,v in pairs(player.GetAll()) do
		if (sid == v:SteamID()) then
			return true
		end
	end

	return false
end

local activePlayer
local function showWarnings(sid, data, sc)
	activePlayer = sid

	sc:Clear()

	local nick      = data.nick
	local warnCount = data.warningCount
	local warnings  = data.warningData

	for k,v in ndoc.pairs(warnings) do

		local panel = sc:Add("DPanel")
		panel:SetWide(sc:GetWide())
		panel:SetTall(20)
		function panel:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, cols.main_btn)
		end

		local height = 0

		local header = vgui.Create("DLabel", panel)
		header:SetPos(10, 5)
		header:SetText("Warning # " .. k .. "/" .. warnCount)
		header:SetFont("adminme_btn_small")
		header:SizeToContents()
		header:SetTextColor(cols.main_btn_text)

		height = height + header:GetTall()

		local admin = vgui.Create("DLabel", panel)
		admin:SetPos(10, 10 + height)
		admin:SetText("Warned by: " .. v.admin)
		admin:SetFont("adminme_btn_small")
		admin:SizeToContents()
		admin:SetTextColor(cols.main_btn_text)

		height = height + admin:GetTall() + 5

		local time = vgui.Create("DLabel", panel)
		time:SetPos(10, 10 + height)
		time:SetText("Date / Time: " .. os.date("%m/%d/%Y at %I:%M%p", v.timestamp))
		time:SetFont("adminme_btn_small")
		time:SizeToContents()
		time:SetTextColor(cols.main_btn_text)

		height = height + time:GetTall() + 5

		local reason = vgui.Create("DLabel", panel)
		reason:SetPos(10, 10 + height)
		reason:SetText("Reason: " .. v.reason)
		reason:SetFont("adminme_btn_small")
		reason:SizeToContents()
		reason:SetTextColor(cols.main_btn_text)

		height = height + reason:GetTall()

		panel:SetTall(height + 15)
	end
end

hook.Add("AddAdditionalMenuSections", "am.addWarningsMenu", function(stor)
	local function repopulateList(scroller, main, txt, liLay)
		scroller:Clear()

		local spacer = vgui.Create("DPanel", scroller)
		spacer:SetSize(scroller:GetWide(), 50)
		function spacer:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 0))
		end

		txt = string.lower(txt)
		for k,v in ndoc.pairs(ndoc.table.am.warnings) do
			if (!string.find(string.lower(k), txt) and !string.find(string.lower(v.nick), txt)) then
				return
			end

			local tW, tH = surface.GetTextSize("X")
			local btn = scroller:Add("DButton")
			btn:SetText("")
			btn:SetSize(scroller:GetWide(), tH + 10)
			function btn:DoClick()
				showWarnings(k, v, liLay)
			end
			function btn:Paint(w, h)
				local col = cols.item_btn_bg
				local textCol = cols.item_btn_text

				if (self:IsHovered()) then
					col = cols.item_btn_bg_hover
					textCol = cols.item_btn_text_hover
				end

				local adjustedWidth = w - 20
				if (activePlayer == k) then
					col = cols.item_btn_bg_active
					textCol = cols.item_btn_text_active
					adjustedWidth = w - 10
				end

				draw.RoundedBox(0, 10, 0, adjustedWidth, h, col)
				draw.SimpleText(v.nick .. " (" .. v.warningCount .. ")", "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
	end

	local function populateList(scroller, main, frame)
		main:Clear()
		activePlayer = nil

		local warnScroll = vgui.Create("DScrollPanel", main)
		warnScroll:SetSize(main:GetWide(), main:GetTall() - 10)
		warnScroll:SetPos(5, 5)

		local liLay = vgui.Create("DIconLayout", warnScroll)
		liLay:SetSize(warnScroll:GetWide(), warnScroll:GetTall())
		liLay:SetPos(0, 0)
		liLay:SetSpaceY(5)

		local sbar = warnScroll:GetVBar()
		sbar:SetSize(0, 0)
		function sbar:Paint( w, h )
			draw.RoundedBox( 0, 0, 0, w, h, Color(0, 0, 0, 0))
		end
		function sbar.btnUp:Paint( w, h )
			draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 0 ) )
		end
		function sbar.btnDown:Paint( w, h )
			draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 0 ) )
		end
		function sbar.btnGrip:Paint( w, h )
			draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 0 ) )
		end

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
		search:SetPlaceholder("Search for player...")

		frame.extras = {search_bg, search}

		function search:OnChange()
			repopulateList(scroller, main, self:GetText(), liLay)
		end

		repopulateList(scroller, main, "", liLay)
	end
	if (LocalPlayer():hasPerm("warning")) then
		stor["Warnings"] = {cback = populateList, useItemList = true}
	end
end)