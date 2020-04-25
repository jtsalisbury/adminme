
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

		return nil
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
		if (info.name == arg || id == tonumber(arg)) then
			return { id = id, info = info }
		end
	end
end

// Will return an object with rank id and information
am.argTypes["rank"] = function(arg)
	for id,info in ndoc.pairs(ndoc.table.am.permissions) do
		if (info.name == arg || id == tonumber(arg)) then
			return { id = id, info = info }
		end
	end
end

am.argTypes["duration"] = function(arg)
	local numString = ""

	// Match the string as 100 yr or any variation
	local time, modifier = string.match(arg, "([%d]*)%s*([%a]*)")
	time = time && tonumber(time) || nil
	if (!time || !modifier) then
		return
	end

	if (time < 0) then
		return
	end

	// Make sure we have a valid conversion factor
	if (!am.argOptions["duration"][ modifier ]) then
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

// Returns a formatted permission set
am.argTypes["permissions"] = function(arg)
    local perms = string.Split(arg, ",")
    local permVisited = {}

    local validPerms = am.argOptions["permissions"]()

    // Loop through passed perms
    for k,v in pairs(perms) do
        if (v == "") then
            continue
        end

        local perm = string.Trim(v)

        // Check to make sure it's valid and that it isn't a repeat
        if (perm && !validPerms[perm]) then
            return nil
        end

        table.insert(permVisited, perm)
    end

    return permVisited
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

am.argOptions["permissions"] = function()
    local options = {
        ["*"] = true
    }

    for id,info in ndoc.pairs(ndoc.table.am.commands) do
        if (!info.restrictedTo) then
            continue
        end

        options[ info.restrictedTo ] = true
    end

    return options
end