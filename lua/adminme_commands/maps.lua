am.addCMD("changelevel", 'Changes the map', 'Misc', function(caller,  map)
	RunConsoleCommand("changelevel", map)
end):addParam('map', 'string'):setPerm("map")
