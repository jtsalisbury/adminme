include("command.lua")
include("command_types.lua")

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

	if (#line == 0) then
		return parts
	end

	local index = 1
	while index ~= nil do
		index = string.find(line, "%S", index)
		if not index then break end

		local cur = string.sub(line, index, index)
		if quotes[cur] then
			// In a quote, search for the end quote
			local closer = string.find(line, cur, index + 1) 
			local quotedString = string.sub(line, index + 1, closer && closer - 1 || nil)
			
			// Add it
			table.insert(parts, quotedString)
			
			if not closer then break end
			index = closer + 1
		else
			// Not in a quote, search for the next whitespace and return the word
			local nextSpace = string.find(line, "%s", index)
			local word = string.sub(line, index, nextSpace && nextSpace - 1 || nil)

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
		local converted = nil
		if (curVal != nil) then
			converted = am.argTypes[paramData.type](curVal, pl, useArgList)
		end

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
		if (converted == nil && !paramData.optional || !isValid) then
			am.notify(ply, "Invalid value for ", paramData.name)
			validParams = false
		elseif (converted == nil && paramData.optional) then
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
