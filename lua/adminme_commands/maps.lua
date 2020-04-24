am.addCMD("changelevel", 'Changes the map', 'Misc', function(caller,  map)
	RunConsoleCommand("changelevel", map)
end):addParam({
	name = 'map', 
	type = 'string'
}):setPerm("map")
