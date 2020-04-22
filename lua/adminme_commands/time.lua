am.addCMD("mytime", "Retrieves and shows your play time", "General", function(ply)
	local timePretty = string.FormattedTime(ply:getPlayTime())
	
	am.notify(ply, "You have played ", am.green, timePretty["h"], am.def, " hours, ", am.green, timePretty["m"], am.def, " minutes, and ", am.green, timePretty["s"], am.def, " seconds!")
		
end):setPerm("time")