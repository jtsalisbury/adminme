//Taken from ULX teleport command; all credit goes to the Ulysees team.
local function playerSend( from, to, force )
	if not to:IsInWorld() and not force then return false end // No way we can do this one
	
	local yawForward = to:EyeAngles().yaw
	local directions = { // Directions to try
		math.NormalizeAngle( yawForward - 180 ), // Behind first
		math.NormalizeAngle( yawForward + 90 ), // Right
		math.NormalizeAngle( yawForward - 90 ), // Left
		yawForward,
	}

	local t = {}
	t.start = to:GetPos() + Vector( 0, 0, 32 ) // Move them up a bit so they can travel across the ground
	t.filter = { to, from }

	local i = 1
	t.endpos = to:GetPos() + Angle( 0, directions[ i ], 0 ):Forward() * 47 // (33 is player width, this is sqrt( 33^2 * 2 ))
	local tr = util.TraceEntity( t, from )
	while tr.Hit do // While it's hitting something, check other angles
		i = i + 1
		if i > #directions then	 // No place found
			if force then
				from.prevPosition = from:GetPos()
				from.prevAngle = from:EyeAngles()
				return to:GetPos() + Angle( 0, directions[ 1 ], 0 ):Forward() * 47
			else
				return false
			end
		end

		t.endpos = to:GetPos() + Angle( 0, directions[ i ], 0 ):Forward() * 47

		tr = util.TraceEntity( t, from )
	end

	from.prevPosition = from:GetPos()
	from.prevAngle = from:EyeAngles()
	return tr.HitPos
end

am.addCMD("bring", 'Brings a player', 'Teleportation', function(caller, target, shouldfreeze)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has brought ', am.red, target:Nick())

	// Send the player to the current
	local pos = playerSend(target, caller, target:GetMoveType() == MOVETYPE_NOCLIP)
	if (pos) then
		hook.Call("SendToAdminHud", GAMEMODE, caller:Nick() .. " brought " .. target:Nick(), 4)

		target:SetPos(pos)
	end

end):addParam('target', 'player'):setPerm("bring")

am.addCMD("goto", 'Sends you to a player', 'Teleportation', function(caller, target)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has gone to ', am.red, target:Nick())

	// Send the caller to the target
	local pos = playerSend(caller, target, target:GetMoveType() == MOVETYPE_NOCLIP)
	if (pos) then
		hook.Call("SendToAdminHud", GAMEMODE, caller:Nick() .. " went to " .. target:Nick(), 4)

		caller:SetPos(pos)
	end

end):addParam('target', 'player'):setPerm("goto")

am.addCMD("return", 'Returns a player to their position before teleportation.', 'Teleportation', function(caller, target)
	local pos = target.prevPosition
	local ang = target.prevAngle
	
	if (!pos or !ang) then am.notify(caller, 'Cant do this, no return point or angle!') return end

	hook.Call("SendToAdminHud", GAMEMODE, caller:Nick() .. " returned " .. target:Nick(), 4)

	am.notify(nil, am.green, caller:Nick(), am.def, ' has returned ', am.red, target:Nick())

	// Put em back!
	target:SetPos(pos)
	target:SetAngles(ang)
end):addParam('target', 'player'):setPerm("bring")
