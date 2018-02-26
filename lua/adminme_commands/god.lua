am.addCMD("god", 'Gods a player', 'Administration', function(caller, target)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has godded ', am.red, target:Nick())

	target:GodEnable()
end):addParam('target', 'player'):setPerm("god")

am.addCMD("ungod", 'UnGods a player', 'Administration', function(caller, target)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has ungodded ', am.red, target:Nick())

	target:GodDisable()
end):addParam('target', 'player'):setPerm("god")
