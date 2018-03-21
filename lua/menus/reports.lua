local reportListScroll, mainSection
local activeReport

local function showReportInfo(data)
	activeReport = data["id"]

	PrintTable(data)

	mainSection:Clear()

	local headerPanel = vgui.Create("am.HeaderPanel", mainSection)
	headerPanel:SetSize(mainSection:GetWide() - 50, mainSection:GetTall() - 50)
	headerPanel:SetHHeight(80)
	headerPanel:SetHText("ID: " .. data["id"])
	headerPanel:SetPos(25, 25)

	local creator = vgui.Create("DLabel", headerPanel)
	creator:SetSize(headerPanel:GetWide() - 30, 40)
	creator:SetPos(15, 55)
	creator:SetFont("adminme_header")
	creator:SetTextColor(cols.header_text)
	creator:SetText("Created By: " .. data["creator_nick"] .. " (" .. data["creator_steamid"] .. ")")

	local against = vgui.Create("DLabel", headerPanel)
	against:SetSize(headerPanel:GetWide() - 30, 40)
	against:SetPos(15, 85)
	against:SetFont("adminme_header")
	against:SetTextColor(cols.header_text)
	against:SetText("Against: " .. data["target_nick"] .. " (" .. data["target_steamid"] .. ")")

	local server = vgui.Create("DLabel", headerPanel)
	server:SetSize(headerPanel:GetWide() - 30, 40)
	server:SetPos(15, 115)
	server:SetFont("adminme_header")
	server:SetTextColor(cols.header_text)
	server:SetText("Server: " .. data["server"])

	local state = vgui.Create("DLabel", headerPanel)
	state:SetSize(headerPanel:GetWide() - 30, 40)
	state:SetPos(15, 145)
	state:SetFont("adminme_header")
	state:SetTextColor(cols.header_text)
	state:SetText("State: " .. data["state"] .. " - In Review")

	local reason = vgui.Create("DLabel", headerPanel)
	reason:SetSize(headerPanel:GetWide() - 30, 40)
	reason:SetPos(15, 175)
	reason:SetFont("adminme_header")
	reason:SetTextColor(cols.header_text)
	reason:SetText("Reason: " .. data["reason"])

	local execute = vgui.Create("DButton", headerPanel)
	execute:SetSize(150, 40)
	execute:SetPos(15, 225)
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
		draw.SimpleText("Close Report", "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	function execute:DoClick()
		LocalPlayer():ConCommand("am_creport " .. data["id"]);

		timer.Simple(1, function()
			net.Start("am.requestReportList")
			net.SendToServer()
		end)
	end
end

net.Receive("am.syncReportList", function()
	local res = net.ReadTable()

	reportListScroll:Clear()
	mainSection:Clear()

	activeReport = nil

	if (#res == 0) then return end

	local spacer = vgui.Create("DPanel", reportListScroll)
	spacer:SetSize(reportListScroll:GetWide(), 5)
	function spacer:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255))
	end

	for k, v in pairs(res) do
		local btn = reportListScroll:Add("DButton")
		btn:SetText("")
		btn:SetSize(reportListScroll:GetWide() - 40, 50)
		function btn:DoClick()
			showReportInfo(v)
		end
		function btn:Paint(w, h)
			local col = cols.item_btn_bg
			local textCol = Color(0, 0, 0)

			if (self:IsHovered()) then
				col = cols.item_btn_bg_hover
			end

			if (activeReport == v["id"]) then
				col = cols.item_btn_bg_active
				textCol = cols.item_btn_text_active
			end

			draw.RoundedBox(8, 0, 0, w, h, col)
			draw.SimpleText(v["target_nick"], "adminme_btn_small", 15, h / 2, textCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end
end)

hook.Add("AddAdditionalMenuSections", "am.addReportMenu", function(stor)
	local function populateList(scroller, main)
		main:Clear()
		activeReport = nil

		mainSection = main

		net.Start("am.requestReportList")
		net.SendToServer()

		reportListScroll = scroller
	end
	if (LocalPlayer():hasPerm("creport")) then
		stor["Reports"] = populateList
	end
end)
