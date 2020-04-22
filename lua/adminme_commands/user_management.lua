am.addCMD("adduser", "Adds a player to a rank", "User Mgmt", function(caller, target, rank, server, duration)
	// Add to rank will handle verification
	local durationTime = duration && duration.seconds || nil

	am.addToRank(caller, target, rank.id, server.id, durationTime)

	// Send it!
	if (duration) then
		am.notify(nil, am.green, caller:Nick(), am.def, " has added ", am.green, target:Nick(), am.def, " to ", am.green, rank.info.name, am.def, " on ", am.green, server.info.name, am.def, " for ", am.green, duration.pretty)
	else
		am.notify(nil, am.green, caller:Nick(), am.def, " has added ", am.green, target:Nick(), am.def, " to ", am.green, rank.info.name, am.def, " on ", am.green, server.info.name, am.def, "indefinitely")
	end	
end):addParam("target", "player"):addParam("rank", "rank", true):addParam("server", "server", true):addParam("time", "duration", false, true):setPerm("usermgmt")

am.addCMD("remuser", "Removes a user from a specific rank and server", "User Mgmt", function(caller, target, rank, server)

	// Remove from rank will handle verification
	// Will also handle different parameter availability	
	am.removeFromRank(caller, target, rank && rank.id || nil, server && server.id || nil)

	// Different handles based on information provided
	if (rank && server) then
		am.notify(nil, am.green, caller:Nick(), am.def, " has removed ", am.red, target:Nick(), am.def, " from ", am.red, rank.info.name, am.def, " on ", am.red, server.info.name)
	elseif (rank) then
		am.notify(nil, am.green, caller:Nick(), am.def, " has removed ", am.red, target:Nick(), am.def, " from ", am.red, server.info.name, am.def, " on ", am.red, "global ")
	else
		am.notify(nil, am.green, caller:Nick(), am.def, " has removed ", am.red, target:Nick(), am.def, " from ", am.red, "all ranks", am.def, " on ", am.red, "global")
	end	
end):addParam("target", "player"):addParam("rank", "rank", true, true):addParam("server", "server", true, true):setPerm("usermgmt")