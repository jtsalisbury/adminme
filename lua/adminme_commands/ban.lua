am.addCMD("ban", "Bans a player", "Administration", function(caller, target, reason, server, duration)
	local isPlayer = type(target) == "Player" 

	// Notifications
	if (duration.seconds == 0) then
		am.notify(nil, am.green, caller:Nick(), am.def, " has banned ", am.red, isPlayer && target:Nick() || target, " indefinitely", am.def, " on ", am.red, server.info.name, am.def, " because of ", am.red, reason)
	else
		am.notify(nil, am.green, caller:Nick(), am.def, " has banned ", am.red, isPlayer && target:Nick() || target, am.def, " for ", am.red, duration.pretty , am.def, " on ", am.red, server.info.name, am.def, " because of ", am.red, reason)
	end

	// Insert ban into the database
	local query = am.db:insert("bans")
		query:insert("banned_steamid", isPlayer && target:SteamID() || target)
		query:insert("banned_name", isPlayer && target:Nick() || "n/a")
		query:insert("banned_timestamp", os.time())
		query:insert("banned_reason", reason)
		query:insert("banned_time", duration.seconds)
		query:insert("banner_steamid", caller:SteamID())
		query:insert("banner_name", caller:Nick())
		query:insert("banned_ip", isPlayer && target:IPAddress() || "n/a")
		query:insert("serverid", server.id)
	query:execute()

	if (isPlayer) then
		target:Kick("You have been banned! Time: " .. duration.pretty .. " Reason: "..reason);
	end	
end):addParam({
	name = "target",
	type = "player"
}):addParam({
	name = "reason",
	type = "string"
}):addParam({
	name = "server",
	type = "server",
	useArgList = true,
	optional = true,
	defaultUI = "global"
}):addParam({
	name = "time",
	type = "duration",
	optional = true,
	defaultUI = "indefinitely"
}):setPerm("ban")

am.addCMD("unbanid", "Unbans a player by their steamid. Note: global unbans will deactive ALL bans", "Administration", function(caller, target, server, deleteBan)
	// Optionally delete and unban if it exists
	am.db:select("bans"):where("banned_steamid", target):where("ban_active", 1):callback(function(res)
		if (#res == 0) then
			return
		end

		am.notify(nil, am.green, caller:Nick(), am.def, " has unbanned ", am.red, target, am.def, " on ", am.red, server.info.name)

		// Delete the ban
		if (deleteBan) then
			local query = am.db:delete("bans")
			query:where("banned_steamid", target)
			query:where("ban_active", 1)

			if (server.id != 0) then
				query:where("serverid", server.id)
			end

			query:execute()
		else
			// Keep the record, but unban it
			local query = am.db:update("bans")
			query:where("banned_steamid", target)
			query:where("ban_active", 1)
			query:update("ban_active", 0)

			// Support for server id or global
			if (server.id != 0) then
				query:where("serverid", server.id)
			end	

			query:execute()
		end
	end):execute()
end):addParam({
	name = "targetid",
	type = "string"
}):addParam({
	name = "server", 
	type = "server", 
	useArgList = true, 
	optional = true,
	defaultUI = "global"
}):addParam({
	name = "delete ban", 
	type = "bool",
	optional = true, 
	defaultUI = "true"
}):setPerm("unban")