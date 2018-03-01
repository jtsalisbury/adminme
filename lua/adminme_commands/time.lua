am.addCMD("mytime", "Retrieves and shows your play time", "General", function(ply)
	local q = am.db:select("play_times"):where("steamid", ply:SteamID()):callback(
		function(res)
			if (!res) then 
				am.notify(ply, "Error retrieving data!")
				return
			end
			
			local timePretty = string.FormattedTime(res[1]["play_time_seconds"])

			am.notify(ply, "You have played ", am.green, timePretty["h"], am.def, " hours, ", am.green, timePretty["m"], am.def, " minutes, and ", am.green, timePretty["s"], am.def, " seconds!")
		end)
	:execute()
end):setPerm("time")