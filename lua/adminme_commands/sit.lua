am.addCMD("sit", 'Sends a target to the sit room', 'Teleportation', function(caller, target)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has sent ', am.red, target:Nick(), am.def, ' to the sit room.')
	if (!am.sitpos) then am:Notify(caller, 'No sit positions available!') return end

	// Cache their current position
	target.ReturnPoint = target:GetPos()
	target.ReturnAngle = target:GetAngles()

	hook.Call("SendToAdminHud", GAMEMODE, caller:Nick() .. " brought " .. target:Nick() .. " to the sit room", 4)
	local pos = am.sitpos [ math.random(1, #am.sitpos) ]

	target:SetPos(pos)
end):addParam('target', 'player'):setPerm("sit")

am.addCMD("addsit", 'Adds a sit position', 'Misc', function(caller)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has added a sit position.')
	am.sitpos = am.sitpos || {}

	// Insert a new sit position
	local sits = am.sitpos
	table.insert(am.sitpos, caller:GetPos())

	file.Write('am_sitpositions_'..game.GetMap()..'.txt', util.TableToJSON(am.sitpos))

	am.notify(caller, 'Added!')
end):setPerm("modifysit")

am.addCMD("setsit", 'Erases all sit positions and adds a new one', 'Misc', function(caller, target)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has wiped all sit positions and added a new one!')

	// Erase the sit positions
	am.sitpos = {}
	table.insert(am.sitpos, caller:GetPos())

	file.Write('am_sitpositions_'..game.GetMap()..'.txt', util.TableToJSON(am.sitpos))
	am.notify(caller, 'Erased and set!')
end):setPerm("modifysit")
