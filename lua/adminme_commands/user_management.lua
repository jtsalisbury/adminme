am.addCMD("adduser", "Adds a player to a rank", "User Mgmt", function(caller, target, rank, server, duration)
	// Add to rank will handle verification
	am.addToRank(caller, target, rank.id, server.id, duration && duration.seconds || nil)

	// Send it!
	if (duration.seconds != 0) then
		am.notify(nil, am.green, caller:Nick(), am.def, " has added ", am.green, target:Nick(), am.def, " to ", am.green, rank.info.name, am.def, " on ", am.green, server.info.name, am.def, " for ", am.green, duration.pretty)
	else
		am.notify(nil, am.green, caller:Nick(), am.def, " has added ", am.green, target:Nick(), am.def, " to ", am.green, rank.info.name, am.def, " on ", am.green, server.info.name, am.def, " indefinitely")
	end
end):addParam({
	name = "target",
	type = "player"
}):addParam({
	name = "rank",
	type = "rank",
	useArgList = true
}):addParam({
	name = "server", 
	type = "server", 
	useArgList = true
}):addParam({
	name = "time", 
	type = "duration", 
	optional = true,
	defaultUI = 0
}):setPerm("usermgmt")

am.addCMD("remuser", "Removes a user from a specific rank and server", "User Mgmt", function(caller, target, rank, server)
	// Remove from rank will handle verification
	// Will also handle different parameter availability	
	// Note that: We pass in defaults for rank and server, but we verify they're correct here, such that the UI example can be updated nicely
	am.removeFromRank(caller, target, rank && rank.id || nil, server && server.id)

	// Different handles based on information provided
	if (rank.id && server.id) then
		am.notify(nil, am.green, caller:Nick(), am.def, " has removed ", am.red, target:Nick(), am.def, " from ", am.red, rank.info.name, am.def, " on ", am.red, server.info.name)
	elseif (rank.id) then
		am.notify(nil, am.green, caller:Nick(), am.def, " has removed ", am.red, target:Nick(), am.def, " from ", am.red, server.info.name, am.def, " on ", am.red, "global ")
	else
		am.notify(nil, am.green, caller:Nick(), am.def, " has removed ", am.red, target:Nick(), am.def, " from ", am.red, "all ranks", am.def, " on ", am.red, "global")
	end	
end):addParam({
	name = "target",
	type = "player"
}):addParam({
	name = "rank", 
	type = "rank", 
	useArgList = true, 
	optional = true,
	defaultUI = "all"
}):addParam({
	name = "server", 
	type = "server", 
	useArgList = true, 
	optional = true,
	defaultUI = "global"
}):setPerm("usermgmt")