am.addCMD("spectate", 'Spectates a player', 'Administration', function(caller, target)
	caller:Spectate(OBS_MODE_CHASE)
	caller:SpectateEntity(target)

	caller.spectating = true
	caller.SReturnPoint = caller:GetPos()
	caller.SReturnAngle = caller:GetAngles()

	caller:DrawViewModel(false)
end):addParam('target', 'player'):setPerm("spectate")

am.addCMD("unspectate", 'Spectates a player', 'Administration', function(caller)
	if (!caller.spectating) then am.notify(caller, 'You arent spectating!') return end

	caller:UnSpectate()
	caller:SetPos(caller.SReturnPoint)
	caller:SetAngles(caller.SReturnAngle)
	caller.spectating = false
	caller:DrawViewModel(true)
end):setPerm("spectate")