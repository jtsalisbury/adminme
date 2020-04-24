local reportListScroll, mainSection
local activeReport

local function showReportInfo(data)
	activeReport = data.id

	mainSection:Clear()

	surface.SetFont("adminme_btn_small")
	local tW, tH = surface.GetTextSize("X")

	local headerPanel = vgui.Create("am.HeaderPanel", mainSection)
	headerPanel:SetSize(mainSection:GetWide() - 20, mainSection:GetTall() - 20)
	headerPanel:SetHHeight(80)
	headerPanel:SetHText("ID: " .. data.id)
	headerPanel:SetPos(10, 10)

	local infoScroll = vgui.Create("DScrollPanel", headerPanel)
	infoScroll:SetSize(headerPanel:GetWide(), headerPanel:GetTall() - 65)
	infoScroll:SetPos(10, 45)

	local sbar = infoScroll:GetVBar()
	sbar:SetSize(0, 0)

	// Layout for all the warnings
	local liLay = vgui.Create("DIconLayout", infoScroll)
	liLay:SetSize(infoScroll:GetWide(), infoScroll:GetTall())
	liLay:SetPos(0, 0)
	liLay:SetSpaceY(10)

	local creator = liLay:Add("DLabel")
	creator:SetSize(headerPanel:GetWide() - 20, tH)
	creator:SetFont("adminme_btn_small")
	creator:SetTextColor(cols.header_text)
	creator:SetText("Created By: " .. data.creator_nick .. " (" .. data.creator_steamid .. ")")

	local against = liLay:Add("DLabel")
	against:SetSize(headerPanel:GetWide() - 20, tH)
	against:SetFont("adminme_btn_small")
	against:SetTextColor(cols.header_text)
	against:SetText("Against: " .. data.target_nick .. " (" .. data.target_steamid .. ")")

	// Show the server
	local server = liLay:Add("DLabel")
	server:SetSize(headerPanel:GetWide() - 20, tH)
	server:SetFont("adminme_btn_small")
	server:SetTextColor(cols.header_text)
	server:SetText("Server: " .. (ndoc.table.am.servers[data.serverid] && ndoc.table.am.servers[data.serverid].name || "can't find server"))

	// Show the state (we only show in review reports right now)
	local state = liLay:Add("DLabel")
	state:SetSize(headerPanel:GetWide() - 20, tH)
	state:SetFont("adminme_btn_small")
	state:SetTextColor(cols.header_text)
	state:SetText("State: In Review")

	local reasonText = "Reason: " .. data.reason
	local reasonHeight = am.getVerticalSize(reasonText, "adminme_btn_small", headerPanel:GetWide() - 20)

	// Show the reason
	local reason = liLay:Add("DLabel")
	reason:SetSize(headerPanel:GetWide() - 20, reasonHeight)
	reason:SetFont("adminme_btn_small")
	reason:SetTextColor(cols.header_text)
	reason:SetText(reasonText)
	reason:SetWrap(true)
	
	// Show the notes
	local originalNotes = data.admin_notes
	local defaultNotes = "Click to modify admin notes"
	local notes = liLay:Add("am.DTextEntry")
	notes:SetSize(headerPanel:GetWide() - 20, 400)
	notes:SetPos(10, 10)
	notes:SetFont("adminme_ctrl")
	notes:SetMultiline(true)
	if (data.admin_notes && #data.admin_notes > 0) then
		notes:SetText(data.admin_notes)
	else 
		notes:SetText(defaultNotes)
	end
	
	// Holds the actions
	local actionContainer = liLay:Add("DPanel")
	actionContainer:SetSize(310, 35)
	function actionContainer:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
	end

	// Control to just update any admin notes of the report
	local saveNotes = vgui.Create("DButton", actionContainer)
	saveNotes:SetSize(150, 35)
	saveNotes:SetPos(0, 0)
	saveNotes:SetText("")
	saveNotes:SetDisabled(true)
	function saveNotes:Paint(w, h)
		local col = cols.main_btn_bg
		local textCol = Color(0, 0, 0)

		if (self:IsHovered()) then
			col = cols.main_btn_hover
		end

		if (self:GetDisabled()) then
			col = cols.main_btn_disabled
		end

		draw.RoundedBox(0, 0, 0, w, h, cols.main_btn_outline)
		draw.RoundedBox(0, 1, 1, w - 2, h - 2, col)
		draw.SimpleText("Save Notes", "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	function saveNotes:DoClick()
		RunConsoleCommand("am_updatereport", data.id, notes:GetText())

		timer.Simple(1, function()
			net.Start("am.requestReportList")
			net.SendToServer()
		end)
	end

	function notes:OnTextChanged()
		if (self:GetText() != originalNotes) then
			saveNotes:SetDisabled(false)
		else
			saveNotes:SetDisabled(true)
		end
	end

	// Control to close and upate the notes of rthe report
	local closeReport = vgui.Create("DButton", actionContainer)
	closeReport:SetSize(150, 35)
	closeReport:SetPos(160, 0)
	closeReport:SetText("")
	function closeReport:Paint(w, h)
		local col = cols.main_btn_bg
		local textCol = Color(0, 0, 0)

		if (self:IsHovered()) then
			col = cols.main_btn_hover
		end

		if (self:GetDisabled()) then
			col = cols.main_btn_disabled
		end

		draw.RoundedBox(0, 0, 0, w, h, cols.main_btn_outline)
		draw.RoundedBox(0, 1, 1, w - 2, h - 2, col)
		draw.SimpleText("Close Report", "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	function closeReport:DoClick()
		local notesToAdd = notes:GetText()
		if (defaultNotes == notesToAdd) then
			notesToAdd = nil
		end
		RunConsoleCommand("am_creport", data.id, notesToAdd)

		timer.Simple(1, function()
			net.Start("am.requestReportList")
			net.SendToServer()
		end)
	end
end

local reportList = nil
local function repopulateList(scroller, main, search_text) 
	scroller:Clear()	
	if (!reportList) then
		return
	end

	local spacer = vgui.Create("DPanel", reportListScroll)
	spacer:SetSize(reportListScroll:GetWide(), 50)
	function spacer:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 0))
	end

	local tW, tH = surface.GetTextSize("X")
	for k, v in pairs(reportList) do
		if (!string.find(v["target_nick"], search_text) && !string.find(v["target_steamid"], search_text) && !string.find(v["creator_nick"], search_text) && !string.find(v["creator_steamid"], search_text) && search_text != "") then
			continue
		end

		local btn = reportListScroll:Add("DButton")
		btn:SetText("")
		btn:SetSize(scroller:GetWide(), tH + 20)
		function btn:DoClick()
			showReportInfo(v)
		end
		function btn:Paint(w, h)
			local col = cols.item_btn_bg
			local textCol = cols.item_btn_text

			if (self:IsHovered()) then
				col = cols.item_btn_bg_hover
				textCol = cols.item_btn_text_hover
			end

			local adjustedWidth = w - 20
			if (activeReport == v["id"]) then
				col = cols.item_btn_bg_active
				textCol = cols.item_btn_text_active
				adjustedWidth = w - 10
			end

			draw.RoundedBox(0, 10, 0, adjustedWidth, h, col)
			draw.SimpleText(v["target_nick"], "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
end

net.Receive("am.syncReportList", function()
	local res = net.ReadTable()

	reportListScroll:Clear()
	mainSection:Clear()

	activeReport = nil

	if (#res == 0) then return end

	reportList = res
	repopulateList(reportListScroll, mainSection, "")
end)

hook.Add("AddAdditionalMenuSections", "am.addReportMenu", function(stor)
	local function populateList(scroller, main, frame)
		main:Clear()
		activeReport = nil

		mainSection = main
		reportListScroll = scroller

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
		search:SetPlaceholder("Search for report...")

		frame.extras = {search_bg, search}

		function search:OnChange()
			repopulateList(scroller, main, self:GetText())
		end

		net.Start("am.requestReportList")
		net.SendToServer()

	end
	if (LocalPlayer():hasPerm("creport")) then
		stor["Reports"] = {cback = populateList, useItemList = true}
	end
end)
