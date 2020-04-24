am.addCMD("kick", 'Kicks a player', 'Administration', function(caller, target, reason)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has kicked ', am.red, target:Nick(), am.def, ' for ', am.green, reason)

	target:Kick(reason)
end):addParam({
	name = 'target', 
	type 'player'
}):addParam({
	name = "reason", 
	type = "string"
}):setPerm("kick")

--[[am.addCMD("gkick", "Sends a query to all servers and kicks the desired player", function(caller, target, reason)
	
	local tab = am:newSMessage()
	tab.type = "kick"
	tab.body = {}
	tab.body.caller = caller:Nick()
	tab.body.steamid = target
	tab.body.reason = reason

	am:sendGQuery(tab)

end):addParam('steamid', 'string'):addParam('reason', 'string'):setPerm('kick')]]