am.addCMD("spectate", 'Spectates a player', 'Administration', function(caller, target)
	// Setup the spectating
	caller:Spectate(OBS_MODE_CHASE)
	caller:SpectateEntity(target)

	// Set their return point and angle
	caller.spectating = true
	caller.SReturnPoint = caller:GetPos()
	caller.SReturnAngle = caller:GetAngles()

	// Hide them
	caller:DrawViewModel(false)
end):addParam({
	name = 'target', 
	type = 'player'
}):setPerm("spectate")

am.addCMD("unspectate", 'Spectates a player', 'Administration', function(caller)
	if (!caller.spectating) then am.notify(caller, 'You arent spectating!') return end

	// Unspectate them
	caller:UnSpectate()
	caller.spectating = false

	// Return to their last position
	caller:SetPos(caller.SReturnPoint)
	caller:SetAngles(caller.SReturnAngle)

	// Show them
	caller:DrawViewModel(true)
end):setPerm("spectate")