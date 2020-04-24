// Returns a table of commands sorted into categories
local sorted = sorted or {}
local function sortCmdsIntoCats()
	if (#sorted > 0) then
		return sorted
	end

	// Do the actual sorting
	for k,v in ndoc.pairs(ndoc.table.am.commands) do
		sorted[ v.cat ] = sorted[ v.cat ] or {}

		sorted[ v.cat ][ k ] = {help = v.help, params = v.params, gamemode = v.gamemode, restrictedTo = v.restrictedTo}
	end

	return sorted
end

// Helper function to generate an execution string
local function generateParamString(params)
	local pStr = ""
	for k,param in ndoc.pairs(params) do
		pStr = pStr .. " <" .. param.name

		// Param has a default
		if (param.optional && param.defaultUI) then
			pStr = pStr .. " = " .. param.defaultUI
		end

		pStr = pStr .. ">"
	end

	return pStr
end

// Here we will map types to specific creation sets

// Control for string types
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

// Helper function to create a combo box based off a set of options
local function createCombo(paramData, options)
	local entry = vgui.Create("DComboBox", layout)
	entry:SetFont("adminme_btn_small")
	entry:SetSize(150, 35)
	function entry:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, cols.main_btn_outline)
		draw.RoundedBox(0, 1, 1, w - 2, h - 2, cols.main_btn_bg)
	end

	// Add each option and if it's default set it
	for k,v in pairs(options) do
		entry:AddChoice(v)

		if (paramData.defaultUI && tostring(paramData.defaultUI) == v) then
			entry:ChooseOptionID(k)
		end
	end

	// Open the combo box with options
	function entry:DoClick()
		if (self:IsMenuOpen()) then
			return self:CloseMenu()
		end
		
		self:OpenMenu()

		local dmenu = self.Menu:GetCanvas():GetChildren()

		// Paint each dlabel
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

// Boolean type (note that this is converted via the command handler to an actual boolean)
paramTypes["bool"] = {
	create = function(paramData)
		return createCombo(paramData, {"true", "false"})
	end,
	get = function(element)
		return element:GetSelected()
	end
}

// Duration type: Has two sub controls (one for time, one for modifier)
paramTypes["duration"] = {
	create = function(paramData)
		local container = vgui.Create("DPanel")
		function container:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
		end
		container:SetSize(150, 35)

		// Create the number entry
		local numEntry = paramTypes["number"].create(paramData)
		numEntry:SetParent(container)

		// Create the option for time
		local typeSelect = createCombo({ defaultUI = "s" }, {"s", "min", "hr", "d", "mon", "yr"})
		typeSelect:SetParent(container)

		numEntry:SetPos(0, 0)
		numEntry:SetSize(80, 35)

		typeSelect:SetPos(90, 0)
		typeSelect:SetSize(60, 35)

		// Store the controls for reference in our get
		container.controls = {
			numEntry,
			typeSelect			
		}

		return container
	end,
	get = function(element)
		// Get the value of each
		local num = element.controls[1]:GetText()
		local type = element.controls[2]:GetSelected()

		// Verify them!
		if (!num || !tonumber(num) || tonumber(num) < 0) then
			return nil
		end

		return num .. type
	end
}

// Param type for play: has two sub controls (one for steamid or player nick and the entry)
paramTypes["player"] = {
	create = function(paramData)
		local container = vgui.Create("DPanel")
		function container:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
		end
		container:SetSize(250, 35)

		// Add a list of all the players
		local players = {}
		for k,v in pairs(player.GetAll()) do
			table.insert(players, v:Nick())
		end

		// Create a combo to select between player and steam id
		local comboSelect = createCombo({ defaultUI = "player" }, { "steamid", "player" })

		// Create the controls for the player and steam id selection
		local playerSelect = createCombo({}, players)
		local steamIDEntry = paramTypes["string"].create({ name = "" })

		// Set parents and sizes
		comboSelect:SetParent(container)
		playerSelect:SetParent(container)
		steamIDEntry:SetParent(container)
		
		comboSelect:SetSize(90, 35)
		playerSelect:SetSize(150, 35)
		steamIDEntry:SetSize(150, 35)

		comboSelect:SetPos(0, 0)
		playerSelect:SetPos(100, 0)
		steamIDEntry:SetPos(100, 0)
		
		// Hide the steam id by default
		steamIDEntry:SetVisible(false)

		// Hide/show the steamid and player entries based on what's selected
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
		// Get the value for everything
		local option = element.controls[1]:GetSelected()
		local steamIDEntry = element.controls[3]:GetText()
		local playerEntry = element.controls[2]:GetSelected()

		// If we want to process a steamid...
		if (option == "steamid") then
			if (!string.find(steamIDEntry, "STEAM_")) then
				return nil
			end
			
			return steamIDEntry
		end

		// Default to processing a player nickname
		if (!playerEntry || #playerEntry == 0) then
			return nil
		end

		return "'" .. playerEntry .. "'"
	end
}

// Selection for server
paramTypes["server"] = {
	create = function(paramData) 
		// Map current servers
		local options = {}
		for k,info in ndoc.pairs(ndoc.table.am.servers) do
			table.insert(options, info.name)
		end

		// Create a combo
		return createCombo(paramData, options)
	end,
	get = function(element)
		return element:GetSelected()
	end
}

// Selection for rank
paramTypes["rank"] = {
	create = function(paramData) 
		// Map the info name (skip the default rank)
		local options = {}
		for k,info in ndoc.pairs(ndoc.table.am.permissions) do
			if (info.name == am.config.default_rank) then
				continue
			end

			table.insert(options, info.name)
		end

		// Create the combo
		return createCombo(paramData, options)
	end,
	get = function(element)
		return element:GetSelected()
	end
}

// Param type for money
paramTypes["money"] = {
	create = function(paramData)
		// It's basically a string type set to numbers only
		local strEle = paramTypes["string"].get(paramData)
		strEle:SetNumeric(true)

		return strEle
	end,
	get = function(element)
		// Make sure we actually have a number and its > 0
		local val = element:GetText()
		if (!val || !tonumber(val) || tonumber(val) < 0) then
			return nil
		end

		return val
	end
}

// Populate the main section (buttons and all that jazz)
local function populateMain(cmd, info, main)
	main:Clear()

	// Create the header panel
	local headerPanel = vgui.Create("am.HeaderPanel", main)
	headerPanel:SetSize(main:GetWide() - 20, main:GetTall() - 20)
	headerPanel:SetHHeight(80)
	headerPanel:SetHText(cmd)
	headerPanel:SetPos(10, 10)

	// Example entry for running from the console
	local example = vgui.Create("am.DTextEntry", headerPanel)
	example:SetSize(headerPanel:GetWide() - 20, 40)
	example:SetPos(10, 50)
	example:SetDisabled(true)
	example:SetPlaceholder("am_" .. cmd .. " " .. generateParamString(info.params))

	// What does this command do?
	local help = vgui.Create("DLabel", headerPanel)
	help:SetSize(headerPanel:GetWide() - 20, 40)
	help:SetPos(10, 100)
	help:SetFont("adminme_btn_small")
	help:SetTextColor(cols.header_text)
	help:SetAutoStretchVertical(true)
	help:SetText(info.help)

	// Background panel for the command params
	local bgPnl = vgui.Create("DPanel", headerPanel)
	bgPnl:SetSize(headerPanel:GetWide() - 20, 0)
	bgPnl:SetPos(10, 55 + example:GetTall() + 15 + help:GetTall() + 15)
	function bgPnl:Paint( w, h )
		draw.RoundedBox(0, 0, 0, w, h, cols.ctrl_text_entry)
		draw.RoundedBox(0, 1, 1, w - 2, h - 2, cols.container_bg)
	end

	// Layout to hold all the controls
	local layout = vgui.Create("DIconLayout", bgPnl)
	layout:SetSize(bgPnl:GetWide() - 20, 0)
	layout:SetPos(10, 10)
	layout:SetSpaceY(10)
	layout:SetLayoutDir(LEFT)

	// Begin creating our controls
	local entries = {}
	local numParams = 0
	for k,paramInfo in ndoc.pairs(info.params) do
		// Create a container for the label + control
		local paramContainer = layout:Add("DPanel")
		paramContainer:SetSize(layout:GetWide(), 35)
		function paramContainer:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
		end

		// Create our control based off param type
		local createdEntry = paramTypes[paramInfo.type].create(paramInfo)

		// Add the created entry to the container
		createdEntry:SetParent(paramContainer)
		createdEntry:SetPos(110, 0)

		// Label for what the param is
		local paramLabel = vgui.Create("DLabel", paramContainer)
		paramLabel:SetFont("adminme_btn_small")
		paramLabel:SetTextColor(cols.header_text)
		paramLabel:SetText(paramInfo.name)
		paramLabel:SetSize(100, 35)
		paramLabel:SetPos(0, 0)

		// Store the controls so we can reference them later when we want to execute	
		table.insert(entries, {
			type = paramInfo.type,
			entry = createdEntry
		})

		numParams = numParams + 1
	end

	// Update the background panel and list layout to our new size!
	local expectedParamHeight = (numParams + 1) * 35 + (10 * numParams)
	bgPnl:SetTall(expectedParamHeight + 20)
	layout:SetTall(expectedParamHeight)

	// Add our execute button
	local execute = vgui.Create("DButton", layout)
	execute:SetSize(150, 35)
	execute:SetText("")
	function execute:Paint(w, h)
		local col = cols.main_btn_bg
		local textCol = Color(0, 0, 0)

		// Hovered
		if (self:IsHovered()) then
			col = cols.main_btn_hover
		end

		// Disabled
		if (self:GetDisabled()) then
			col = cols.main_btn_disabled
		end

		// Paint the button - make it pretty!
		draw.RoundedBox(0, 0, 0, w, h, cols.main_btn_outline)
		draw.RoundedBox(0, 1, 1, w - 2, h - 2, col)
		draw.SimpleText("Execute", "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	function execute:DoClick()
		// Begin constructing our execution string
		local str = "am_" .. cmd

		// Loop through each entry and get the value using its specified type
		for k,entryInfo in pairs(entries) do
			local val = paramTypes[entryInfo.type].get(entryInfo.entry)

			if (val == nil) then 
				return
			end

			str = str .. " " .. val
		end

		// Execute it!
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

hook.Add("AddAdditionalMenuSections", "am.addCommandSection", function(stor)
	local sorted = sortCmdsIntoCats()

	stor["Commands"] = {cback = populateList, useItemList = true}
end)
