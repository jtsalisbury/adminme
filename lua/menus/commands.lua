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

		if (param.optional && param.defaultUI) then
			// TODO: consolidate this to just "default" or something, which may be hard even though we have objects returned and stuff
			pStr = pStr .. " = " .. param.defaultUI
		end

		pStr = pStr .. ">"
	end

	return pStr
end

// Here we will map types to specific creation sets
local paramTypes = {}
paramTypes["string"] = {
	create = function(paramData) 
		local placeholder = paramData.name

		local entry = vgui.Create("am.DTextEntry")
		entry:SetFont("adminme_btn_small")
		entry:SetSize(150, 35)
		if (paramData.defaultUI) then
			entry:SetText(paramData.defaultUI)
		end
		entry:SetPlaceholder(placeholder)

		return entry
	end,
	get = function(element)
		return element:GetText() && "'" .. element:GetText() .. "'"
	end
}

// Number is a derivation with setnumeric true
paramTypes["number"] = {
	create = function(paramData)
		local strEle = paramTypes["string"].create(paramData)
		strEle:SetNumeric(true)

		return strEle
	end,
	get = function(element)
		return element:GetText() && tonumber(element:GetText())
	end
}

local function createCombo(paramData, options)
	local entry = vgui.Create("DComboBox", layout)
	entry:SetFont("adminme_btn_small")
	entry:SetSize(150, 35)
	function entry:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, cols.main_btn_outline)
		draw.RoundedBox(0, 1, 1, w - 2, h - 2, cols.main_btn_bg)
	end

	for k,v in pairs(options) do
		entry:AddChoice(v)

		if (paramData.defaultUI && tostring(paramData.defaultUI) == v) then
			entry:ChooseOptionID(k)
		end
	end

	function entry:DoClick()
		if (self:IsMenuOpen()) then
			return self:CloseMenu()
		end
		
		self:OpenMenu()

		local dmenu = self.Menu:GetCanvas():GetChildren()

		for i = 1, #dmenu do
			local dlabel = dmenu[i]

			dlabel:SetFont("adminme_btn_small")

			function dlabel:Paint(w, h)
				draw.RoundedBox(0, 0, 0, w, h, cols.ctrl_entry_entry)
				draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(255, 255, 255))
			end
		end
	end

	return entry
end

paramTypes["bool"] = {
	create = function(paramData)
		return createCombo(paramData, {"true", "false"})
	end,
	get = function(element)
		return element:GetSelected()
	end
}

paramTypes["duration"] = {
	create = function(paramData)
		local container = vgui.Create("DPanel")
		function container:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
		end
		container:SetSize(150, 35)

		// Modify a bit to add a default UI portion for the type 
		local numEntry = paramTypes["number"].create(paramData)
		numEntry:SetParent(container)

		local typeSelect = createCombo({ defaultUI = "s" }, {"s", "min", "hr", "d", "mon", "yr"})
		typeSelect:SetParent(container)

		numEntry:SetPos(0, 0)
		numEntry:SetSize(80, 35)

		typeSelect:SetPos(90, 0)
		typeSelect:SetSize(60, 35)

		// Create controls
		container.controls = {
			numEntry,
			typeSelect			
		}

		return container
	end,
	get = function(element)
		local num = element.controls[1]:GetText()
		local type = element.controls[2]:GetSelected()

		if (!num || !tonumber(num) || tonumber(num) < 0) then
			return nil
		end

		return num .. type
	end
}

paramTypes["player"] = {
	create = function(paramData)
		local container = vgui.Create("DPanel")
		function container:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
		end
		container:SetSize(250, 35)

		local players = {}
		for k,v in pairs(player.GetAll()) do
			table.insert(players, v:Nick())
		end

		local comboSelect = createCombo({ defaultUI = "player" }, { "steamid", "player" })
		local playerSelect = createCombo({}, players)
		local steamIDEntry = paramTypes["string"].create({ name = "" })

		comboSelect:SetParent(container)
		playerSelect:SetParent(container)
		steamIDEntry:SetParent(container)
		
		comboSelect:SetSize(90, 35)
		playerSelect:SetSize(150, 35)
		steamIDEntry:SetSize(150, 35)

		comboSelect:SetPos(0, 0)
		playerSelect:SetPos(100, 0)
		steamIDEntry:SetPos(100, 0)
		
		steamIDEntry:SetVisible(false)

		function comboSelect:OnSelect(index, val) 
			if (val == "steamid") then
				steamIDEntry:SetVisible(true)
				playerSelect:SetVisible(false)
			else
				steamIDEntry:SetVisible(false)
				playerSelect:SetVisible(true)
			end
		end	

		// Create controls
		container.controls = {
			comboSelect,
			playerSelect,
			steamIDEntry
		}

		return container
	end,
	get = function(element)
		local option = element.controls[1]:GetSelected()
		local steamIDEntry = element.controls[3]:GetText()
		local playerEntry = element.controls[2]:GetSelected()

		if (option == "steamid") then
			if (!string.find(steamIDEntry, "STEAM_")) then
				return nil
			end
			
			return steamIDEntry
		end

		if (!playerEntry || #playerEntry == 0) then
			return nil
		end

		return "'" .. playerEntry .. "'"
	end
}

paramTypes["server"] = {
	create = function(paramData) 
		local options = {}
		for k,info in ndoc.pairs(ndoc.table.am.servers) do
			table.insert(options, info.name)
		end

		return createCombo(paramData, options)
	end,
	get = function(element)
		return element:GetSelected()
	end
}

paramTypes["rank"] = {
	create = function(paramData) 
		local options = {}
		for k,info in ndoc.pairs(ndoc.table.am.permissions) do
			if (info.name == am.config.default_rank) then
				continue
			end

			table.insert(options, info.name)
		end

		return createCombo(paramData, options)
	end,
	get = function(element)
		return element:GetSelected()
	end
}

paramTypes["money"] = {
	create = function(paramData)
		local strEle = paramTypes["string"].get(paramData)
		strEle:SetNumeric(true)

		return strEle
	end,
	get = function(element)
		local val = element:GetText()
		if (!val || !tonumber(val) || tonumber(val) < 0) then
			return nil
		end

		return val
	end
}

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
		bgPnl:SetSize(headerPanel:GetWide() - 20, 0)
		bgPnl:SetPos(10, 55 + example:GetTall() + 15 + help:GetTall() + 15)
		function bgPnl:Paint( w, h )
			draw.RoundedBox(0, 0, 0, w, h, cols.ctrl_text_entry)
			draw.RoundedBox(0, 1, 1, w - 2, h - 2, cols.container_bg)
		end

		local layout = vgui.Create("DIconLayout", bgPnl)
		layout:SetSize(bgPnl:GetWide() - 20, 0)
		layout:SetPos(10, 10)
		layout:SetSpaceY(10)
		layout:SetLayoutDir(LEFT)

		local entries = {}
		local numParams = 0
		for k,paramInfo in ndoc.pairs(info.params) do
			local createdEntry = paramTypes[paramInfo.type].create(paramInfo)
			local paramContainer = layout:Add("DPanel")
			paramContainer:SetSize(layout:GetWide(), 35)
			function paramContainer:Paint(w, h)
				draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
			end

			local paramLabel = vgui.Create("DLabel", paramContainer)
			paramLabel:SetFont("adminme_btn_small")
			paramLabel:SetTextColor(cols.header_text)
			paramLabel:SetText(paramInfo.name)
			paramLabel:SetSize(100, 35)
			paramLabel:SetPos(0, 0)

			createdEntry:SetParent(paramContainer)
			createdEntry:SetPos(110, 0)
			table.insert(entries, {
				type = paramInfo.type,
				entry = createdEntry
			})

			numParams = numParams + 1
		end
		local expectedParamHeight = (numParams + 1) * 35 + (10 * numParams)
		bgPnl:SetTall(expectedParamHeight + 20)
		layout:SetTall(expectedParamHeight)

		local execute = vgui.Create("DButton", layout)
		execute:SetSize(150, 35)
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

			for k,entryInfo in pairs(entries) do
				local val = paramTypes[entryInfo.type].get(entryInfo.entry)

				if (val == nil) then 
					return
				end

				str = str .. " " .. val
			end

			LocalPlayer():ConCommand(str)
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

			if (!info.enableUI || !info.enabled) then
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
