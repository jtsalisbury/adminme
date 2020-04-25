cmd_mt = {}
cmd_mt.__index = cmd_mt
function cmd_mt:ctor(aliases, helptext, category, callback)
	if type(aliases) == "string" then
		aliases = {aliases}
	end

	self.aliases = aliases
	self.helptext = helptext
	self.params = {}
	self.permCheck = function() return true end
	self.callback = callback
	self.canUse = true
	self.category = isstring(category) && category || "No Category"

	// Register a console command for each alias
	for k,v in pairs(aliases) do
		concommand.Add("am_" .. v, function(pl, cmd, _, argStr)
			// Default arg table passed splits wildly, pass it to our handler 
			am.runCommand(pl, self, am.parseLine(argStr))
		end)
	end

	// Setup each alias to reference the new command
	for k, alias in ipairs(self.aliases) do
		am.cmds[ alias ] = self
		ndoc.table.am.commands [ alias ] = {
			help = helptext, 
			params = {}, 
			cat = category, 
			enableUI = true,
			enabled = true
		}
	end

	return self
end

function cmd_mt:disableUI()
	for k, alias in ipairs(self.aliases) do
		ndoc.table.am.commands [ alias ].enableUI = false
	end
end

function cmd_mt:addParam(data)
	local type = data.type
	local useArgList = data.useArgList
	local optional = data.optional
	local default = data.default
	local defaultUI = data.defaultUI
	local name = data.name

	// In this case, we pass a table with values
	if useArgList && !am.argOptions[type] then
		error("no valid argument options for argument type " .. tostring(type))
	end

	if !am.argTypes[type] then
		error("invalid argument type " .. tostring(type))
	end

	// Update the param list
	table.insert(self.params, {
		name = name,
		type = type,
		optional = optional,
		useArgList = useArgList,
		default = default,
	})

	// Update each alias for the command
	for k,v in pairs(self.aliases) do
		ndoc.table.am.commands[ v ].params[ #self.params ] = {
			name = name, 
			type = type, 
			defaultUI = defaultUI,
			optional = optional,
			useArgList = useArgList
		}
	end

	return self
end

// Set the permission group required for this command
function cmd_mt:setPerm(perm)
	self.permCheck = function(pl)
		return pl:hasPerm(perm)
	end

	self.perm = perm

	// Update all instances
	for k,v in pairs(self.aliases) do
		ndoc.table.am.commands[ v ].restrictedTo = perm
	end

	return self
end

// Set a specific gamemode for use
function cmd_mt:setGamemode(gm)
	// Get the gamemode
	if (gm ~= GetConVarString("gamemode")) then
		cmd_mt.canUse = false
		
		// Remove all instances of this command
		for k,v in pairs(self.aliases) do
			am.cmds[ v ].canUse = false
			ndoc.table.am.commands[ v ].gamemode = gm 
			ndoc.table.am.commands[ v ].enabled = false
			concommand.Remove("am_" .. v)
		end
	end

	return self
end