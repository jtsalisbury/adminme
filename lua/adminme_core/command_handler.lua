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
	self.pCount = 0
	self.canUse = true
	self.category = isstring(category) and category or "No Category"

	concommand.Add("am_" .. aliases[1], function(pl, cmd, args)
		am.runCommand(pl, self, args)
	end)

	for k, alias in ipairs(self.aliases) do
		am.cmds[ alias ] = self
		ndoc.table.am.commands [ alias ] = {help = helptext, params = {}, cat = category}
	end

	return self
end

function cmd_mt:addParam(name, type)
	if not am.argTypes[type] then
		error("invalid argument type " .. tostring(type))
	end

	table.insert(self.params, {
		name = name,
		type = type
	})

	self.pCount = self.pCount + 1

	for k,v in pairs(self.aliases) do
		ndoc.table.am.commands[ v ].params[ self.pCount ] = {name, type}
	end

	return self
end

function cmd_mt:setPerm(perm)
	self.permCheck = function(pl)
		return pl:hasPerm(perm)
	end

	self.perm = perm

	for k,v in pairs(self.aliases) do
		ndoc.table.am.commands[ v ].restrictedTo = perm
	end

	return self
end

function cmd_mt:setGamemode(gm)
	if (gm ~= GetConVarString("gamemode")) then
		cmd_mt.canUse = false
		
		for k,v in pairs(self.aliases) do
			am.cmds[ v ].canUse = false
			ndoc.table.am.commands[ v ].gamemode = gm 
			concommand.Remove("am_" .. v)
		end

	end

	return self
end

-- PARSE A PLAYER ARGUMENT
am.argTypes["player"] = function(argument, pl)
	if argument == "^" then
		if IsValid(pl) then
			return pl
		end
		return nil, "you cant reference yourself when running command from server"
	end

	if argument:find("STEAM_") then
		for k,v in pairs(player.GetAll()) do
			if v:SteamID() == argument then
				return v
			end
		end

		--return steamid regardless!!
		return argument
	end

	argument = argument:lower()

	local found = nil
	for k,v in pairs(player.GetAll()) do
		if v:Nick() == argument then return v end
		if string.find(string.lower(v:Nick()), argument) then
			if found then return nil, "two players matched substring, give a more exact name" end
			found = v
		end
	end

	if found then return found end
	return nil, "no player found"
end

-- PARSE A STRING ARGUMENT
am.argTypes["string"] = function(argument) return argument end
am.argTypes["number"] = function(argument)
	local num = tonumber(argument)
	if num == nil then return nil, "malformatted number" end
	return num
end
am.argTypes["bool"] = function(argument)
	if argument[1] == "y" or argument[1] == "t" then return true end
	return false
end
am.argTypes["money"] = function(argument)
	if string.sub(argument, 1, 1) == "$" then
		return am.argTypes["money"](string.sub(argument, 2))
	end
	return am.argTypes["number"](argument)
end
am.argTypes["time_type"] = function(arg)
	if (arg ~= "s" and arg ~= "min" and arg ~= "hr" and arg ~= "d" and arg ~= "m" and arg ~= "yr") then return nil end
	return arg
end

--
-- ADD COMMAND
--
function am.addCMD(...)
	return setmetatable({}, cmd_mt):ctor(...)
end

local quotes = {
	["\'"] = true,
	["\""] = true
}
function am.parseLine(line)
	local function skipWhiteSpace(index)
		return string.find(line, "%S", index)
	end

	local function findNextSpace(index)
		return string.find(line, "%s", index)
	end

	local function findClosingQuote(index, type)
		return string.find(line, type, index)
	end

	local parts = {}

	local index = 1
	while index ~= nil do
		index = skipWhiteSpace(index)
		if not index then break end

		local cur = string.sub(line, index, index)
		if quotes[cur] then
			local closer = findClosingQuote(index + 1, cur)
			local quotedString = string.sub(line, index + 1, closer and closer - 1 or nil)
			table.insert(parts, quotedString)
			if not closer then break end
			index = closer
		else
			local nextSpace = findNextSpace(index)
			local word = string.sub(line, index, nextSpace and nextSpace - 1 or nil)
			table.insert(parts, word)
			if not nextSpace then break end
			index = nextSpace
		end
	end

	return parts
end

function am.runCommand(pl, command, arguments)
	if not command.permCheck(pl) then
		am.notify(pl, "Sorry! You don't have permission to run this command.")
		return
	end

	-- make the last argument into one argument
	if #arguments < #command.params then
		am.notify(pl, "Sorry! This command takes " .. (#command.params) .. " arguments!")
		return
	end

	if #arguments > #command.params then
		local extra = {}
		for i = #command.params, #arguments do
			table.insert(extra, arguments[i])
			arguments[i] = nil
		end
		arguments[#command.params] = table.concat(extra, " ")
	end

	local allGood = true

	local function processArguments(index, a, ...)
		if not a then return end

		local param = command.params[index]
		local value, message = am.argTypes[param.type](a, pl)
		if value == nil and message ~= nil then
			allGood = false
			am.notify(pl, "Error: " .. tostring(message))
			return
		end

		return value, processArguments(index + 1, ...)
	end

	local function callIt(...)
		if allGood then
			for k,v in pairs({...}) do
				if (type(v) == "Player") then
					if (v:getHeirarchy() >= pl:getHeirarchy() and command.perm != nil and v != pl) then
						am.notify(pl, "You can't target them!")
						return 
					end

					am.addPlayerEvent(v, pl:Nick() .. " used " ..command.aliases[ 1 ].. " on " .. v:Nick())
				end
			end

			am.addPlayerEvent(pl, pl:Nick() .. " used " .. command.aliases[ 1 ])

			hook.Call("PlayerRanCommand", GAMEMODE, command, pl, ...)

			command.callback(pl, ...)
			return
		end
	end
	callIt(processArguments(1, unpack(arguments)))
end
