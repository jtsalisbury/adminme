am.addCMD("jail", 'Jails a player', 'Administration', function(caller, target, time, time_type, reason)
	local thetime = am.modTime(time_type, time)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has jailed ', am.red, target:Nick(), am.def, ' for ', am.red, time..time_type, am.def, ' because of ', am.red, reason)

	target.jailed = true
	target:Freeze(true)

	local tLeft = thetime
	timer.Create("jail_"..target:SteamID(), 1, thetime, function()

		target:PrintMessage(HUD_PRINTCENTER, "You have ".. tLeft .."s left")
		tLeft = tLeft - 1
	end)

	timer.Simple(thetime, function()
		if (IsValid(target) and target.jailed) then
			target:Freeze(false)
			target.jailed = false
		end
	end)
end):addParam('target', 'player'):addParam("time", 'number'):addParam("time type", 'time_type'):addParam('reason', 'string'):setPerm("jail")

am.addCMD("unjail", 'Unjails a player', 'Administration', function(caller, target)
	if (!target.jailed) then return end
	
	am.notify(nil, am.green, caller:Nick(), am.def, ' has unjailed ', am.red, target:Nick())
	timer.Destroy("jail_"..target:SteamID())

	target.jailed = false
	target:Freeze(false)
end):addParam('target', 'player'):setPerm("jail")
