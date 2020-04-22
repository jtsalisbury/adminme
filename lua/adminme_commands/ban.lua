am.addCMD("ban", "Bans a player", "Administration", function(caller, target, reason, duration)
	// Notifications
	if (duration.seconds == 0) then
		am.notify(nil, am.green, caller:Nick(), am.def, " has banned ", am.red, target:Nick(), " indefinitely", am.def, " because of ", am.red, reason)
	else
		am.notify(nil, am.green, caller:Nick(), am.def, " has banned ", am.red, target:Nick(), am.def, " for ", am.red, duration.pretty , am.def, " because of ", am.red, reason)
	end

	// Insert ban into the database
	local query = am.db:insert("bans")
		query:insert("banned_steamid", IsValid(target) && target:SteamID() || target)
		query:insert("banned_name", IsValid(target) && target:Nick() || "n/a")
		query:insert("banned_timestamp", os.time())
		query:insert("banned_reason", reason)
		query:insert("banned_time", duration.seconds)
		query:insert("banner_steamid", caller:SteamID())
		query:insert("banner_name", caller:Nick())
		query:insert("banned_ip", IsValid(target) && target:IPAddress() || "n/a")
	query:execute()

	if (target) then
		target:Kick("You have been banned! Time: " .. duration.pretty .. " Reason: "..reason);
	end	

end):addParam("target", "player"):addParam("reason", "string"):addParam("time", "duration", false, true, {
	seconds = 0,
	pretty = ""
}):setPerm("ban")

am.addCMD("unban", "Unbans a player", "Administration", function(caller, target, deleteBan)
	am.notify(nil, am.green, caller:Nick(), am.def, " has unbanned ", am.red, target)

	// Optionally delete and unban
	if (deleteBan) then
		local query = am.db:delete("bans")
			query:where("banned_steamid", target)
			query:where("ban_active", 1)
		query:execute()
	else
		local query = am.db:update("bans")
			query:where("banned_steamid", target)
			query:where("ban_active", 1)
			query:update("ban_active", 0)
		query:execute()
	end

end):addParam("targetid", "string"):addParam("delete ban", "bool", false, true):setPerm("unban")