am.addCMD("ban", 'Bans a player', 'Administration', function(caller, target, ptime, time_type, reason)
	local time = am.modTime(time_type, ptime)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has banned ', am.red, target:Nick(), am.def, ' for ', am.red, ptime .." "..time_type, am.def, ' because of ', am.red, reason)

	local query = am.db:insert("bans")
		query:insert("banned_steamid", target:SteamID())
		query:insert("banned_name", target:Nick())
		query:insert("banned_timestamp", os.time())
		query:insert("banned_reason", reason)
		query:insert("banned_time", time)
		query:insert("banner_steamid", caller:SteamID())
		query:insert("banner_name", caller:Nick())
		query:insert("banned_ip", target:IPAddress())
	query:execute()

	target:Kick("You have been banned! Time: "..ptime.." "..time_type.." Reason: "..reason);

end):addParam('target', 'player'):addParam('time', 'number'):addParam('time_type', 'time_type'):addParam('reason', 'string'):setPerm("ban")

am.addCMD("banid", 'Bans a player by steam id', 'Administration', function(caller, target, ptime, time_type, reason)
	local time = am.modTime(time_type, ptime)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has banned ', am.red, target, am.def, ' for ', am.red, ptime, ' ', time_type, am.def, ' because of ', am.red, reason)

	local query = am.db:insert("bans")
		query:insert("banned_steamid", target)
		query:insert("banned_name", 'null')
		query:insert("banned_timestamp", os.time())
		query:insert("banned_reason", reason)
		query:insert("banned_time", time)
		query:insert("banner_steamid", caller:SteamID())
		query:insert("banner_name", caller:Nick())
	query:execute()

end):addParam('targetid', 'string'):addParam('time', 'number'):addParam('time_type', 'time_type'):addParam('reason', 'string'):setPerm("ban")

am.addCMD("unban", 'Unbans a player', 'Administration', function(caller, target)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has unbanned ', am.red, target)

	local query = am.db:update("bans")
		query:where("banned_steamid", target)
		query:where("ban_active", 1)
		query:update("ban_active", 0)
	query:execute()

end):addParam('targetid', 'string'):setPerm("unban")

am.addCMD("removeban", 'Unbans a player and deletes the record of the ban', 'Administration', function(caller, target)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has removed the ban for ', am.red, target)

	local query = am.db:delete("bans")
		query:where("banned_steamid", target)
		query:where("ban_active", 1)
	query:execute()

end):addParam('targetid', 'string'):setPerm("unban")
