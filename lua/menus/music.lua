local playFrame = nil
CreateConVar("am_rem_enabled", "true", FCVAR_ARCHIVE, "Enables/disables the round end music for TTT")
CreateConVar("am_music_enabled", "true", FCVAR_ARCHIVE, "Enables/disables the playing of ALL music")


net.Receive("am.startRoundEndEvents", function()
	local dt = net.ReadTable()

	if (GetConVar("am_rem_enabled"):GetString() == "true" && GetConVar("am_music_enabled"):GetString() == "true") then
		if (IsValid(playFrame)) then
			playFrame:Close()

			timer.Remove("am.playSongEnd")
		end

		playFrame = vgui.Create("DFrame")
		playFrame:SetSize(0, 0)
		playFrame:SetPos(0, 0)

		local html = vgui.Create("HTML", playFrame)
		html:Dock(FILL)
		html:OpenURL(dt[2] .. "&autoplay=1&t=" .. (tonumber(dt[4]) * 60) + tonumber(dt[5]))
	end
end)

net.Receive("am.endRoundEndEvents", function()
	if (IsValid(playFrame)) then
		playFrame:Close()
	end
end)

net.Receive("am.playSong", function()
	if (IsValid(playFrame)) then
		playFrame:Close()

		timer.Remove("am.playSongEnd")
	end

	if (GetConVar("am_music_enabled"):GetString() == "false") then
		return
	end

	local id   = net.ReadInt(16)
	local data = ndoc.table.am.music[id]

	local url = data[2]

	playFrame = vgui.Create("DFrame")
	playFrame:SetSize(0, 0)
	playFrame:SetPos(0, 0)

	local html = vgui.Create("HTML", playFrame)
	html:Dock(FILL)
	html:OpenURL(url .. "&autoplay=1")


	local len = tonumber(data[3]) * 60
	timer.Create("am.playSongEnd", len, 1, function()
		if (IsValid(playFrame)) then
			playFrame:Close()
		end
	end)
end)

net.Receive("am.endSong", function()
	if (IsValid(playFrame)) then
		playFrame:Close()

		timer.Remove("am.playSongEnd")
	end
end)


hook.Add("AddAdditionalMenuSections", "am.addMusicMenu", function(stor)
	local function populateList(scroller, main, frame)
		main:Clear()

		local liLay = vgui.Create("DListView", main)
		liLay:SetSize(main:GetWide() - 30, main:GetTall() - 30)
		liLay:SetPos(15, 75)
		liLay:SetMultiSelect(false)
		liLay:SetHeaderHeight(40)
		liLay:SetSortable(false)
		liLay:SetDataHeight(25)
		liLay:AddColumn("ID")
		liLay:AddColumn("Title")
		liLay:AddColumn("Length")

		function liLay:Paint(w, h)
			draw.RoundedBox(8, 0, 0, w, h, cols.head_panel_outline)
			draw.RoundedBox(8, 1, 1, w - 2, h - 2, cols.head_panel_bg)
		end
		function liLay:OnRequestResize()
			return false
		end

		local scB = liLay.VBar
		function scB:Paint( w, h )
			draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255, 0))
		end
		function scB.btnUp:Paint( w, h )
			draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255, 0))
		end
		function scB.btnDown:Paint( w, h )
			draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255, 0))
		end
		function scB.btnGrip:Paint( w, h )
			draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255, 0))
		end

		for k,v in ndoc.pairs(ndoc.table.am.music) do
			local name = v[1]
			local url  = v[2]
			local len  = v[3]
			local startMin = v[4]
			local startSec = v[5]

			local pnl = liLay:AddLine(k, name, len)
			pnl.mData = {k, name, url}

			for k,v in pairs(pnl.Columns) do
				v:SetFont("adminme_ctrl")
			end
		end

		//PAINTING OF HEADERS

		local idLbl = vgui.Create("DLabel", main)
		idLbl:SetSize(liLay:GetWide() / 3, 40)
		idLbl:SetPos(15, 75)
		idLbl:SetText("")
		idLbl:SetFont("adminme_btn_small")
		function idLbl:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255))
			draw.RoundedBox(8, 0, 0, w, h, cols.head_panel_head_bg)
			draw.SimpleText("ID", "adminme_btn_small", w / 2, h / 2, cols.head_panel_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		local nameLbl = vgui.Create("DLabel", main)
		nameLbl:SetSize(liLay:GetWide() / 3, 40)
		nameLbl:SetPos(15 + idLbl:GetWide(), 75)
		nameLbl:SetText("")
		nameLbl:SetFont("adminme_btn_small")
		function nameLbl:Paint(w, h)
			draw.RoundedBox(8, 0, 0, w, h, cols.head_panel_head_bg)
			draw.SimpleText("Name", "adminme_btn_small", w / 2, h / 2, cols.head_panel_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		local lenLbl = vgui.Create("DLabel", main)
		lenLbl:SetSize(liLay:GetWide() / 3, 40)
		lenLbl:SetPos(15 + idLbl:GetWide() * 2, 75)
		lenLbl:SetText("")
		lenLbl:SetFont("adminme_btn_small")
		function lenLbl:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255))
			draw.RoundedBox(8, 0, 0, w, h, cols.head_panel_head_bg)
			draw.SimpleText("Length", "adminme_btn_small", w / 2, h / 2, cols.head_panel_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		local hider1 = vgui.Create("DPanel", idLbl)
		hider1:SetSize(15, 25)
		hider1:SetPos(-2, 30)
		function hider1:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, cols.head_panel_head_bg)
		end

		local hider2 = vgui.Create("DPanel", idLbl)
		hider2:SetSize(15, 40)
		hider2:SetPos(idLbl:GetWide() - 15, 0)
		function hider2:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, cols.head_panel_head_bg)
		end

		local hider3 = vgui.Create("DPanel", nameLbl)
		hider3:SetSize(15, 40)
		hider3:SetPos(0, 0)
		function hider3:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, cols.head_panel_head_bg)
		end

		local hider4 = vgui.Create("DPanel", nameLbl)
		hider4:SetSize(15, 40)
		hider4:SetPos(idLbl:GetWide() - 15, 0)
		function hider4:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, cols.head_panel_head_bg)
		end

		local hider5 = vgui.Create("DPanel", lenLbl)
		hider5:SetSize(15, 40)
		hider5:SetPos(0, 0)
		function hider5:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, cols.head_panel_head_bg)
		end

		local hider6 = vgui.Create("DPanel", lenLbl)
		hider6:SetSize(15, 15)
		hider6:SetPos(lenLbl:GetWide() - 10, 30)
		function hider6:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, cols.head_panel_head_bg)
		end

		frame.extras = {liLay, idLbl, nameLbl, lenLbl}

		function liLay:OnRowRightClick(id, pnl)
			local menu = DermaMenu()
			menu:SetPos(gui.MousePos())
			if (LocalPlayer():hasPerm("musicmgmt")) then
				menu:AddOption("Play Song for Yourself", function() RunConsoleCommand("am_playsong", pnl.mData[1]) end)
				menu:AddOption("Play Song for All", function() RunConsoleCommand("am_playsongall", pnl.mData[1]) end)
				menu:AddOption("Remove Song", function() RunConsoleCommand("am_removesong", pnl.mData[1]) pnl:Remove() end)
			end

			menu:Open()
		end
	end
	if (LocalPlayer():hasPerm("music")) then
		stor["Music"] = {cback = populateList, useItemList = false}
	end
end)
