am.addCMD("slay", 'Slays a player', 'Administration', function(caller, target)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has slain ', am.red, target:Nick())

	target:Kill()
end):addParam('target', 'player'):setPerm("slay")
