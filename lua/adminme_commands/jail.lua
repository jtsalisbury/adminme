am.addCMD("jail", 'Jails a player', 'Administration', function(caller, target, reason, duration)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has jailed ', am.red, target:Nick(), am.def, ' for ', am.red, duration.pretty, am.def, ' because of ', am.red, reason)

	// Do the jailing
	target.jailed = true
	target:Freeze(true)

	// Print the jail time left on the target's HUD
	local tLeft = duration.seconds
	timer.Create("jail_"..target:SteamID(), 1, tLeft, function()
		target:PrintMessage(HUD_PRINTCENTER, "You have ".. tLeft .."s left")
		tLeft = tLeft - 1
	end)

	// Undo the jail time
	timer.Simple(tLeft, function()
		if (IsValid(target) && target.jailed) then
			target:Freeze(false)
			target.jailed = false
		end
	end)
end):addParam({
	name = 'target', 
	type = 'player'
}):addParam({
	name = 'reason', 
	type = 'string'
}):addParam({
	name = 'time', 
	type = 'duration'
}):setPerm("jail")

am.addCMD("unjail", 'Unjails a player', 'Administration', function(caller, target)
	if (!target.jailed) then return end
	
	am.notify(nil, am.green, caller:Nick(), am.def, ' has unjailed ', am.red, target:Nick())

	// Destroy the countdown timer
	timer.Destroy("jail_"..target:SteamID())

	// Unjail them
	target.jailed = false
	target:Freeze(false)
end):addParam({
	name = 'target', 
	type = 'player'
}):setPerm("jail")
