local cmd_mt = {}
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
	self.category = isstring(category) and category or "No Category"

	// Register a console command for each alias
	for k,v in pairs(aliases) do
		concommand.Add("am_" .. v, function(pl, cmd, args)
			am.runCommand(pl, self, args)
		end)
	end

	// Setup each alias to reference the new command
	for k, alias in ipairs(self.aliases) do
		am.cmds[ alias ] = self
		ndoc.table.am.commands [ alias ] = {help = helptext, params = {}, cat = category}
	end

	return self
end

function cmd_mt:addParam(name, type, useArgList, optional, default) 
	if !am.argTypes[type] then
		error("invalid argument type " .. tostring(type))
	end

	// Update the param list
	table.insert(self.params, {
		name = name,
		type = type,
		optional = optional,
		useArgList = useArgList,
		default = default
	})


	// Update each alias for the command
	for k,v in pairs(self.aliases) do
		ndoc.table.am.commands[ v ].params[ #self.params ] = {name, type, default, arg_list}
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
			concommand.Remove("am_" .. v)
		end

	end

	return self
end

// Returns the player (if they're there) based off steamid or nickname
am.argTypes["player"] = function(argument, pl)
	// Return the current player
	if argument == "^" then
		if IsValid(pl) then
			return pl
		end
		return nil, "you cant reference yourself when running command from server"
	end

	// We are looking for a steamid for a current player, or just the steamid if not found
	if argument:find("STEAM_") then
		for k,v in pairs(player.GetAll()) do
			if v:SteamID() == argument then
				return v
			end
		end

		return argument
	end

	argument = argument:lower()

	local found = nil

	// We are looking for a player by name
	for k,v in pairs(player.GetAll()) do
		if v:Nick() == argument then return v end
		if string.find(string.lower(v:Nick()), argument) then
			// Two or more players matching the name
			if found then 
				return nil, "two players matched substring, give a more exact name" 
			end

			found = v
		end
	end

	// Return found or nil if we can't target them
	if found then 
		if (found:getHierarchy() >= pl:getHierarchy() && found != pl) then
			am.notify(pl, "You can't target them!")
			return 
		end

		return found 
	end

	return nil, "no player found"
end

// Returns the original string
am.argTypes["string"] = function(argument) return argument end

// Returns a number if possible
am.argTypes["number"] = function(argument)
	local num = tonumber(argument)
	if num == nil then return nil, "malformatted number" end
	return num
end

// Returns a truthy text as a boolean
am.argTypes["bool"] = function(argument)
	if argument[1] == "y" || argument[1] == "t" || argument[1] == "true" then 
		return true 
	end

	return false
end

// Returns money formatted as a number
am.argTypes["money"] = function(argument)
	if string.sub(argument, 1, 1) == "$" then
		return am.argTypes["money"](string.sub(argument, 2))
	end
	return am.argTypes["number"](argument)
end

// Will return an object with server id and information
am.argTypes["server"] = function(arg)
	for id,info in ndoc.pairs(ndoc.table.am.servers) do
		if (info.name == arg) then
			return { id = id, info = info }
		end
	end
end

// Will return an object with rank id and information
am.argTypes["rank"] = function(arg)
	for id,info in ndoc.pairs(ndoc.table.am.permissions) do
		if (info.name == arg) then
			return { id = id, info = info }
		end
	end
end

// Potential entries
am.argOptions = {}
am.argOptions["duration"] = {
	["s"] = function(time) return time end,
	["min"] = function(time) return time * 60 end,
	["hr"] = function(time) return time * 60 * 60 end,
	["d"] = function(time) return time * 60 * 60 * 24 end,
	["mon"] = function(time) return time * 60 * 60 * 24 * 30 end,
	["yr"] = function(time) return time * 60 * 60 * 24 * 30 * 12 end
}

// Returns a table of tables with rank ids and names
am.argOptions["rank"] = function()
	local options = {}

	for id,info in ndoc.pairs(ndoc.table.am.permissions) do
		table.insert(options, {
			id = id,
			name = info.name
		})
	end

	return options
end

// Returns a table of tables with server ids and names
am.argOptions["server"] = function()
	local options = {}

	for id,info in ndoc.pairs(ndoc.table.am.servers) do
		table.insert(options, {
			id = id,
			name = info.name
		})
	end

	return options
end

am.argTypes["duration"] = function(arg)
	local numString = ""

	// Match the string as 100 yr or any variation
	local time, modifier = string.match(arg, "([%d]*)%s*([%a]*)")
	if (!time || !modifier) then
		return
	end

	// Make sure we have a valid conversion factor
	if (!am.argOptions["duration"][ modifier ]) then
		print('error 2' .. modifier)
		return
	end

	// Grab the modified time
	local moddedTime = am.argOptions["duration"][ modifier ](time)

	// Return the formated duration
	return {
		seconds = moddedTime,
		pretty = time .. " " .. modifier
	}
end

// Helper function based on duration
function am.modTime(time, format)
	if (!am.argOptions[format]) then
		return nil
	end

	return am.argOptions[format](time)
end

// Add a new command
function am.addCMD(...)
	// Make sure to return the object and create it
	return setmetatable({}, cmd_mt):ctor(...)
end

local quotes = {
	["\'"] = true,
	["\""] = true
}

// Parse a line to return a table of words/quoted phrases
function am.parseLine(line)
	local parts = {}

	local index = 1
	while index ~= nil do
		index = string.find(line, "%S", index)
		if not index then break end

		local cur = string.sub(line, index, index)
		if quotes[cur] then
			// In a quote, search for the end quote
			local closer = string.find(line, cur, index + 1)
			local quotedString = string.sub(line, index + 1, closer && closer - 1 or nil)
			
			// Add it
			table.insert(parts, quotedString)
			
			if not closer then break end
			index = closer
		else
			// Not in a quote, search for the next whitespace and return the word
			local nextSpace = string.find(line, "%s", index)
			local word = string.sub(line, index, nextSpace && nextSpace - 1 or nil)

			// Add it
			table.insert(parts, word)
			
			if not nextSpace then break end
			index = nextSpace
		end
	end

	// Return the words and phrases
	return parts
end

// Execute the command
function am.runCommand(pl, command, arguments)
	// Check to ensure we have the correct permissions
	if !command.permCheck(pl) then
		am.notify(pl, "Sorry! You don't have permission to run this command.")
		return
	end

	// More args passed than we can handle. Join them together and set it as the last arg
	if (#arguments > #command.params) then
		local newLastArg = table.concat(arguments, " ", #command.params, #arguments)

		// We only cycle to available params, so we don't have to remove the rest of the table entries
		arguments[#command.params] = newLastArg
	end
		
	// Begin parsing the params with their arguments	
	local execParams = {}
	local validParams = true
	for index,paramData in pairs(command.params) do
		local curVal = arguments[index]

		// Convert to appropriate type
		local converted = curVal != nil && am.argTypes[paramData.type](curVal, pl) || nil

		// Make sure it's allowed
		local isValid = true
		if (paramData.useArgList && converted) then
			isValid = false // assume false until we find it

			// Get all options for the param type
			local options = am.argOptions[paramData.type]
			if (isfunction(options)) then
				options = options()
			end

			// Compare the name and id of the option (this should only really be used for servers and ranks)
			for k,v in pairs(options) do
				if (istable(v)) then
					if (v.id == converted.id) then
						isValid = true
						break
					end
				end
			end
		end

		// Determine if the param is missing and optional
		if (!converted && !paramData.optional || !isValid) then
			am.notify(ply, "Invalid value for ", paramData.name)
			validParams = false
		elseif (!converted && paramData.optional) then
			converted = paramData.default // set to default
		end

		// Push it to the params to be executed
		table.insert(execParams, converted)
	end

	// Make sure we are still valid
	if (!validParams) then
		return
	end

	// Add player events
	for k,v in pairs(execParams) do
		if (type(v) == "Player") then
			am.addPlayerEvent(v, pl:Nick() .. " used " ..command.aliases[ 1 ].. " on " .. v:Nick())
		end
	end

	am.addPlayerEvent(pl, pl:Nick() .. " used " .. command.aliases[ 1 ])

	// Call the hook
	hook.Call("PlayerRanCommand", GAMEMODE, command, pl, unpack(execParams))

	// Execute the command callback
	command.callback(pl, unpack(execParams))
end
