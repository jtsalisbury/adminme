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


hook.Add("AddAdditionalMenuSections", "am.addCommandSection", function(stor)
	local sorted = sortCmdsIntoCats()

	local function populateMain(cmd, info, main)
		main:Clear()

		local headerPanel = vgui.Create("am.HeaderPanel", main)
		headerPanel:SetSize(main:GetWide() - 50, main:GetTall() - 50)
		headerPanel:SetHHeight(80)
		headerPanel:SetHText(cmd)
		headerPanel:SetPos(25, 25)

		local pStr = ""
		for k,v in ndoc.pairs(info.params) do
			pStr = pStr .. " <" .. v[1] .. ">"
		end

		local example = vgui.Create("am.DTextEntry", headerPanel)
		example:SetSize(headerPanel:GetWide() - 30, 40)
		example:SetPos(15, 55)
		example:SetDisabled(true)
		example:SetPlaceholder("am_" .. cmd .. " " .. pStr)

		local help = vgui.Create("DLabel", headerPanel)
		help:SetSize(headerPanel:GetWide() - 30, 40)
		help:SetPos(15, 100)
		help:SetFont("adminme_header")
		help:SetTextColor(cols.header_text)
		help:SetAutoStretchVertical(true)
		help:SetText(info.help)

		local offset_x = 15
		local param_ident, type
		local pos = 1
		local paramStor = {}
		local pCount = table.Count(info.params)

		local bgPnl = vgui.Create("DPanel", headerPanel)
		bgPnl:SetSize(headerPanel:GetWide() - 30, 100)
		bgPnl:SetPos(15, 55 + example:GetTall() + 15 + help:GetTall() + 15)
		function bgPnl:Paint( w, h )
			draw.RoundedBox(8, 0, 0, w, h, cols.ctrl_text_entry)
			draw.RoundedBox(8, 1, 1, w - 2, h - 2, cols.ctrl_text_disabled)
		end

		local layout = vgui.Create("DIconLayout", bgPnl)
		layout:SetSize(bgPnl:GetWide() - 30, 35)
		layout:SetPos(15, 32.5)
		layout:SetSpaceY(100)
		layout:SetSpaceX(0)

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
					draw.RoundedBox(4, 0, 0, w, h, cols.ctrl_entry_entry)
					draw.RoundedBox(4, 1, 1, w - 2, h - 2, Color(255, 255, 255))
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

					PrintTable(paramStor)
				end

			elseif (type == "string" or type == "number") then
				local txt = param_ident
				if (default) then
					txt = param_ident .. " (def: " .. default .. ")"
				end

				local entry = vgui.Create("am.DTextEntry", layout)
				entry:SetSize(itemWidth, layout:GetTall())
				entry:SetPlaceholder(txt)
				entry:SetTheme("LIGHT")

				function entry:OnTextChanged()
					paramStor[ curPos ] = '"' .. self:GetValue() .. '"'
				end

			elseif (type == "player" or type == "time_type" or type == "bool") then
				local entry = vgui.Create("DComboBox", layout)
				entry:SetSize(itemWidth, layout:GetTall())
				entry:SetFont("adminme_ctrl")
				function entry:Paint(w, h)
					draw.RoundedBox(4, 0, 0, w, h, cols.ctrl_entry_entry)
					draw.RoundedBox(4, 1, 1, w - 2, h - 2, Color(255, 255, 255))
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

					PrintTable(paramStor)
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

			draw.RoundedBox(4, 0, 0, w, h, cols.main_btn_outline)
			draw.RoundedBox(4, 1, 1, w - 2, h - 2, col)
			draw.SimpleText("Execute", "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		function execute:DoClick()
			local str = "am_" .. cmd

			for k,v in pairs(paramStor) do
				print(k .. " : " .. v)
				str = str .. " " .. v
			end

			LocalPlayer():ConCommand(str);
		end
	end

	local function repopulateList(scroller, main, search_text)
		activeCmd = nil
		scroller:Clear()

		local spacer = vgui.Create("DPanel", scroller)
		spacer:SetSize(scroller:GetWide(), 60)
		function spacer:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255))
		end

		for cmd, info in ndoc.pairs(ndoc.table.am.commands) do
			if (string.find(cmd, search_text) == nil && search_text != "") then
				continue
			end

			if (not LocalPlayer():hasPerm(info.restrictedTo)) then
				continue
			end

			local cmd_btn = vgui.Create("DButton", scroller)
			cmd_btn:SetSize(scroller:GetWide() - 40, 50)
			cmd_btn:SetText("")
			cmd_btn.cmd = cmd

			function cmd_btn:Paint(w, h)
				local col = cols.item_btn_bg
				local textCol = Color(0, 0, 0)

				if (self:IsHovered()) then
					col = cols.item_btn_bg_hover
				end

				if (activeCmd == cmd) then
					col = cols.item_btn_bg_active
					textCol = cols.item_btn_text_active
				end

				draw.RoundedBox(8, 0, 0, w, h, col)
				draw.SimpleText(cmd, "adminme_btn_small", 15, h / 2, textCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end
			function cmd_btn:DoClick()
				populateMain(cmd, info, main)

				activeCmd = cmd
			end
		end
	end

	local function populateList(scroller, main, frame)
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

		local activeCmd
		local cmdsInCat = 0
		
		repopulateList(scroller, main, "")
	end

	stor["Commands"] = populateList
end)
