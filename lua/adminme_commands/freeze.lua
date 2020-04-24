am.addCMD("freeze", 'Freezes a player', 'Administration', function(caller, target, reason)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has frozen ', am.red, target:Nick(), am.def, ' for ', am.green, reason)

	target:Freeze(true)
end):addParam({
	name = 'target', 
	type = 'player'
}):addParam({
	name = "reason", 
	type = "string"
}):setPerm("freeze")

am.addCMD("unfreeze", 'UnFreezes a player', 'Administration', function(caller, target)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has unfroze ', am.red, target:Nick())

	target:Freeze(false)
end):addParam({
	name = 'target',
	type = 'player'
}):setPerm("freeze")
