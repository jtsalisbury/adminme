local sorted = sorted or {}
local function sortCmdsIntoCats()
	if (#sorted > 0) then
		return sorted
	end

	for k,v in ndoc.pairs(ndoc.table.am.commands) do
		sorted[ v.cat ] = sorted[ v.cat ] or {}

		sorted[ v.cat ][ k ] = {help = v.help, params = v.params, gamemode = v.gamemode, restrictedTo = v.restrictedTo}
	end

	return sorted
end

// Helper function to generate  list of params
local function generateParamString(params)
	local pStr = ""
	for k,param in ndoc.pairs(params) do
		pStr = pStr .. " <" .. param.name

		if (param.optional && param.uiDefault) then
			// TODO: consolidate this to just "default" or something, which may be hard even though we have objects returned and stuff
			pStr = pStr .. " = " .. param.uiDefault
		end

		pStr = pStr .. ">"
	end

	return pStr
end

hook.Add("AddAdditionalMenuSections", "am.addCommandSection", function(stor)
	local sorted = sortCmdsIntoCats()

	local function populateMain(cmd, info, main)
		main:Clear()

		local headerPanel = vgui.Create("am.HeaderPanel", main)
		headerPanel:SetSize(main:GetWide() - 20, main:GetTall() - 20)
		headerPanel:SetHHeight(80)
		headerPanel:SetHText(cmd)
		headerPanel:SetPos(10, 10)

		local example = vgui.Create("am.DTextEntry", headerPanel)
		example:SetSize(headerPanel:GetWide() - 20, 40)
		example:SetPos(10, 50)
		example:SetDisabled(true)
		example:SetPlaceholder("am_" .. cmd .. " " .. generateParamString(info.params))

		local help = vgui.Create("DLabel", headerPanel)
		help:SetSize(headerPanel:GetWide() - 20, 40)
		help:SetPos(10, 100)
		help:SetFont("adminme_btn_small")
		help:SetTextColor(cols.header_text)
		help:SetAutoStretchVertical(true)
		help:SetText(info.help)

		local offset_x = 15
		local param_ident, type
		local pos = 1
		local paramStor = {}
		local pCount = table.Count(info.params)

		local bgPnl = vgui.Create("DPanel", headerPanel)
		bgPnl:SetSize(headerPanel:GetWide() - 20, 100)
		bgPnl:SetPos(10, 55 + example:GetTall() + 15 + help:GetTall() + 15)
		function bgPnl:Paint( w, h )
			draw.RoundedBox(0, 0, 0, w, h, cols.ctrl_text_entry)
			draw.RoundedBox(0, 1, 1, w - 2, h - 2, cols.container_bg)
		end

		local layout = vgui.Create("DIconLayout", bgPnl)
		layout:SetSize(bgPnl:GetWide() - 20, 35)
		layout:SetPos(10, 32.5)
		layout:SetSpaceY(100)
		layout:SetSpaceX(10)

		local pCount = 1
		for k,v in ndoc.pairs(info.params) do
			pCount = pCount + 1
		end

		local itemWidth = (bgPnl:GetWide() - 30) / pCount

		if (itemWidth > 150) then
			itemWidth = 150
		end

		for _,param_info in ndoc.pairs(info.params) do
			param_ident = param_info[1]
			type  = param_info[2]
			local default = param_info[3]
			local argList = param_info[4]
			local curPos = pos

			local count = 0

			if (argList) then
				local entry = vgui.Create("DComboBox", layout)
				entry:SetSize(itemWidth, layout:GetTall())
				entry:SetFont("adminme_ctrl")
				function entry:Paint(w, h)
					draw.RoundedBox(0, 0, 0, w, h, cols.main_btn_outline)
					draw.RoundedBox(0, 1, 1, w - 2, h - 2, cols.main_btn_bg)
				end
				function entry:DoClick()
					if (self:IsMenuOpen()) then
				        return self:CloseMenu()
				    end
				    
				    self:OpenMenu()

				    local dmenu = self.Menu:GetCanvas():GetChildren()

				    for i = 1, #dmenu do
				        local dlabel = dmenu[i]

				        dlabel:SetFont("adminme_ctrl")

				        function dlabel:Paint(w, h)
				            draw.RoundedBox(0, 0, 0, w, h, cols.main_btn_outline)
							draw.RoundedBox(0, 1, 1, w - 2, h - 2, cols.main_btn_bg)
				        end
				    end
				end

				local i = 1
				for k,v in ndoc.pairs(argList) do
					entry:AddChoice(v)

					if (default and v == default) then
						entry:ChooseOptionID(i)
					end

					i = i + 1
				end

				function entry:OnSelect(ind, val)
					paramStor[ curPos ] = val
				end

			elseif (type == "string" or type == "number") then
				local txt = param_ident
				if (default) then
					txt = param_ident .. " (def: " .. default .. ")"
				end

				local entry = vgui.Create("am.DTextEntry", layout)
				entry:SetSize(itemWidth, layout:GetTall())
				entry:SetFont("adminme_ctrl")
				entry:SetPlaceholder(txt)

				function entry:OnTextChanged()
					paramStor[ curPos ] = '"' .. self:GetValue() .. '"'
				end

			elseif (type == "player" or type == "time_type" or type == "bool") then
				local entry = vgui.Create("DComboBox", layout)
				entry:SetSize(itemWidth, layout:GetTall())
				entry:SetFont("adminme_ctrl")
				function entry:Paint(w, h)
					draw.RoundedBox(0, 0, 0, w, h, cols.main_btn_outline)
					draw.RoundedBox(0, 1, 1, w - 2, h - 2, cols.main_btn_bg)
				end
				function entry:DoClick()
					if (self:IsMenuOpen()) then
				        return self:CloseMenu()
				    end
				    
				    self:OpenMenu()

				    local dmenu = self.Menu:GetCanvas():GetChildren()

				    for i = 1, #dmenu do
				        local dlabel = dmenu[i]

				        dlabel:SetFont("adminme_ctrl")

				        function dlabel:Paint(w, h)
				            draw.RoundedBox(0, 0, 0, w, h, cols.ctrl_entry_entry)
							draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(255, 255, 255))
				        end
				    end
				end

				local sids = {}
				if (type == "player") then
					for k,v in pairs(player.GetAll()) do
						entry:AddChoice('"' .. v:Nick() .. '"')

						sids[k] = v:SteamID()
					end
				end

				if (type == "time_type") then
					local i = 1
					for k,v in pairs({"s", "min", "hr", "d", "m", "yr"}) do
						entry:AddChoice(v)

						if (default and v == default) then
							entry:ChooseOptionID(i)
						end

						i = i + 1
					end
				end

				if (type == "bool") then
					entry:AddChoice("true")
					entry:AddChoice("false")

					if (default == "true") then
						entry:ChooseOption(1)
					elseif (default == "false") then
						entry:ChooseOption(2)
					end
				end

				function entry:OnSelect(ind, val)
					if (type == "player") then
						val = '"' .. sids[ ind ] .. '"'
					end

					paramStor[ curPos ] = val
				end
				
			end

			pos = pos + 1
		end

		local execute = vgui.Create("DButton", layout)
		execute:SetSize(itemWidth, layout:GetTall())
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

			draw.RoundedBox(0, 0, 0, w, h, cols.main_btn_outline)
			draw.RoundedBox(0, 1, 1, w - 2, h - 2, col)
			draw.SimpleText("Execute", "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		function execute:DoClick()
			local str = "am_" .. cmd

			for k,v in pairs(paramStor) do
				str = str .. " " .. v
			end

			LocalPlayer():ConCommand(str);
		end
	end

	// Responsible for populating the list of commands
	local function repopulateList(scroller, main, search_text)
		activeCmd = nil
		scroller:Clear()

		// Spacer for the searchbar
		local spacer = vgui.Create("DPanel", scroller)
		spacer:SetSize(scroller:GetWide(), 50)
		function spacer:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 0))
		end

		// Add each command
		for cmd, info in ndoc.pairs(ndoc.table.am.commands) do
			// Match the command	
			if (string.find(cmd, search_text) == nil && search_text != "") then
				continue
			end

			// Ensure we have permission to view it
			if (!LocalPlayer():hasPerm(info.restrictedTo)) then
				continue
			end

			if (!info.enableUI) then
				continue
			end

			surface.SetFont('adminme_btn_small')
			local tW, tH = surface.GetTextSize(cmd)

			// Create the button
			local cmd_btn = scroller:Add("DButton")
			cmd_btn:SetSize(scroller:GetWide(), tH + 20)
			cmd_btn:SetText("")
			cmd_btn.cmd = cmd
			function cmd_btn:Paint(w, h)
				local col = cols.item_btn_bg
				local textCol = cols.item_btn_text

				// Hovered
				if (self:IsHovered()) then
					col = cols.item_btn_bg_hover
					textCol = cols.item_btn_text_hover
				end

				// Active
				local adjustedWidth = w - 20
				if (activeCmd == cmd) then
					col = cols.item_btn_bg_active
					textCol = cols.item_btn_text_active
					adjustedWidth = w - 10
				end

				draw.RoundedBox(0, 10, 0, adjustedWidth, h, col)
				draw.SimpleText(cmd, "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			function cmd_btn:DoClick()
				// Populate the main section with the command info
				populateMain(cmd, info, main)

				activeCmd = cmd
			end
		end
	end

	local function populateList(scroller, main, frame)
		// Create and position the search background
		local posX = frame:GetWide() - main:GetWide() - scroller:GetWide()
		local search_bg = vgui.Create("DPanel", frame)
		search_bg:SetSize(scroller:GetWide(), 50)
		search_bg:SetPos(posX, 0)
		function search_bg:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, cols.item_scroll_bg)
		end

		// Create the search entry
		local search = vgui.Create("am.DTextEntry", search_bg)
		search:SetSize(search_bg:GetWide() - 20, search_bg:GetTall() - 20)
		search:SetPos(10, 10)
		search:SetFont("adminme_ctrl")
		search:SetPlaceholder("Search for command...")

		frame.extras = {search_bg, search}

		// Repopulate the list of commands once we change our text
		function search:OnChange()
			repopulateList(scroller, main, self:GetText())
		end

		// Default
		repopulateList(scroller, main, "")
	end

	stor["Commands"] = {cback = populateList, useItemList = true}
end)
