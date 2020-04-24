hook.Add("PlayerCanHearPlayersVoice", "MutePlayers", function(listener, talker)
	if (talker.muted) then
		return false
	end
end)

hook.Add("PlayerSay", "GagPlayers", function(ply)
	if (ply.gagged) then
		am.notify(ply, "You are gagged and cannot use the text chat!")
		return ""
	end
end)

am.addCMD("mute", "Mutes a player", 'Chat', function(caller, target)
	target.muted = true

	am.notify(nil, am.green, caller:Nick(), am.def, " has muted ", am.red, target:Nick())
end):addParam({
	name = "target", 
	type = "player"
}):setPerm("mute")

am.addCMD("unmute", "Unmutes a player", 'Chat', function(caller, target)
	target.muted = false

	am.notify(nil, am.green, caller:Nick(), am.def, " has unmuted ", am.red, target:Nick())
end):addParam({
	name = "target", 
	type = "player"
}):setPerm("mute")

am.addCMD("gag", "Gags a player", 'Chat', function(caller, target)
	target.gagged = true

	am.notify(nil, am.green, caller:Nick(), am.def, " has gagged ", am.red, target:Nick())
end):addParam({
	name = "target", 
	type = "player"
}):setPerm("gag")

am.addCMD("ungag", "Ungags a player", 'Chat', function(caller, target)
	target.gagged = false

	am.notify(nil, am.green, caller:Nick(), am.def, " has ungagged ", am.red, target:Nick())
end):addParam({
	name = "target", 
	type = "player"
}):setPerm("gag")