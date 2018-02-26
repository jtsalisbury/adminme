util.AddNetworkString("am.adminModeToggled")

hook.Add("PlayerSpawn", "SetGodMode", function(ply)
	if (ply.adminmode) then
		ply:GodEnable()
	end
end)

am.addCMD("adminmode", 'Toggles admin mode on yourself', 'Administration', function(caller)
	caller.adminmode = !caller.adminmode

	caller:SetNWBool("inAdminMode", caller.adminmode)

	if (caller.adminmode) then
		caller:GodEnable()
		caller.old_model = caller:GetModel()

		caller:SetModel("models/player/riot.mdl")
	else
		caller:GodDisable()
		caller:SetModel(caller.old_model)
	end

	am.notify(caller, "You have" .. (caller.adminmode and " entered admin mode" or " exited admin mode"))

	net.Start("am.adminModeToggled")
	net.Send(caller)
end):setPerm("adminmode")