am.addCMD("slaynr", "Marks a player for slays on n rounds", 'TTT', function(caller, target, slays)
	if (slays < 0) then return end

	am.notify(nil, am.green, caller:Nick(), am.def, " has marked ", am.red, target:Nick(), am.def, " for ", am.red, slays, am.def, " slays")

	target:SetPData("nrslays", tonumber(slays))
end):setGamemode("terrortown"):addParam("target", "player"):addParam("slays", "number"):setPerm("ttt_slay")

am.addCMD("respawn", "Respawn a player", 'TTT', function(caller, target)
	if ((target:Alive() and target:IsSpec()) or not target:Alive()) then
		timer.Destroy("traitorcheck" .. target:SteamID())

        target:ConCommand("ttt_spectator_mode 0")
        timer.Create("respawndelay", 0.1, 0, function()

        	for k,v in pairs(ents.FindByClass("prop_ragdoll")) do
        		if (v.uqid == target:UniqueID() and IsValid(v)) then
        			CORPSE.SetFound(v, false)
			        player.GetByUniqueID( v.uqid ):SetNWBool( "body_found", false )
			        v:Remove()
			        SendFullStateUpdate()
				elseif v.player_ragdoll then
			        player.GetByUniqueID( v.uqid ):SetNWBool( "body_found", false )
					v:Remove()
			        SendFullStateUpdate()
        		end
        	end

            target:SpawnForRound( true )
            target:SetCredits( ( (target:GetRole() == ROLE_INNOCENT) and 0 ) or GetConVarNumber("ttt_credits_starting") )

            am.notify(nil, am.green, caller:Nick(), am.def, " has respawned ", am.green, target:Nick())

            if target:Alive() then
            	timer.Destroy("respawndelay")
            	return
            end
		end)
	end
end):setGamemode("terrortown"):addParam("target", "player"):setPerm("ttt_respawn")


local function GetLoadoutWeapons(r)
	local tbl = {
		[ROLE_INNOCENT] = {},
		[ROLE_TRAITOR]  = {},
		[ROLE_DETECTIVE]= {}
	};
	for k, w in pairs(weapons.GetList()) do
		if w and type(w.InLoadoutFor) == "table" then
			for _, wrole in pairs(w.InLoadoutFor) do
				table.insert(tbl[wrole], WEPS.GetClass(w))
			end
		end
	end
	return tbl[r]
end

am.addCMD("forcerole", "Forces a user's role", 'TTT', function(caller, target, role)
	if (role ~= "innocent" and role ~= "detective" and role ~= "traitor") then
		am.notify(caller, "Please enter a valid role! (innocent, traitor, detective)")
		return
	end

	local affected_plys = {}
	local starting_credits = GetConVarNumber("ttt_credits_starting")

	local role_credits
	local role_id
	if (role == "innocent") then
		role_id = ROLE_INNOCENT
		role_credits = 0
	end
	if (role == "detective") then
		role_id = ROLE_DETECTIVE
		role_credits = starting_credits
	end
	if (role == "traitor") then
		role_id = ROLE_TRAITOR
		role_credits = starting_credits
	end

	local current_role = target:GetRole()

	if GetRoundState() == 1 or GetRoundState() == 2 then
		am.notify( caller, "The round has not begun!" )
		return
	elseif not target:Alive() then
		am.notify( caller, target:Nick() .. " is dead!" )
		return
	elseif current_role == role_id then
		am.notify( caller, target:Nick() .. " is already " .. role )
		return
	else
		target:ResetEquipment()

    target:SetRole(role_id)
    target:SetCredits(role_credits)
    SendFullStateUpdate()

    target:StripWeapons()

    local items = EquipmentItems[ role_id ]
    if (items) then
      for k, v in pairs(items) do
      	if (v.loadout and v.id) then
      		target:GiveEquipmentItem(v.id)
      	end
      end
  end

    local r = GetRoundState() == ROUND_PREP and ROLE_INNOCENT or target:GetRole()
		local weps = GetLoadoutWeapons(r)
		if not weps then return end

		for _, cls in pairs(weps) do
			if not target:HasWeapon(cls) then
				target:Give(cls)
			end
		end
    end

    am.notify(target, "Your role has been set to " .. role )
end):setGamemode("terrortown"):addParam("target", "player"):addParam("role", "string"):setPerm("ttt_forceRole")

am.addCMD("forcespec", "Forces a player to and from spectator mode", 'TTT', function(caller, target, unspec)
	if (!unspec) then
		target:ConCommand("ttt_spectator_mode 0")
	else
		target:Kill()
		target:SetForceSpec(true)
		target:SetTeam(TEAM_SPEC)
		target:ConCommand("ttt_spectator_mode 1")
		target:ConCommand("ttt_cl_idlepopup")
	end

	if (unspec) then
		am.notify(nil, target:Nick(), " has been forced to spectate!")
	else
		am.notify(nil, target:Nick(), " has been forced to rejoin the living world next round!")
	end
end):setGamemode("terrortown"):addParam("target", "player"):addParam("spec", "bool"):setPerm("ttt_forceSpec")

hook.Add("TTTBeginRound", "SlayNR", function()
	for k,v in pairs(player.GetAll()) do

		if (tonumber(v:GetPData("nrslays", 0)) > 0) then
			v:Kill()

			am.notify(v, "You have been slain and have ", am.red, tonumber(v:GetPData("nrslays")) - 1, am.def, " left!")
			am.notify(nil, v:Nick(), " has been slain this round!")
			v:SetPData("nrslays", tonumber(v:GetPData("nrslays")) - 1)
		end
	end
end)

local function removeBody(corpse)
	CORPSE.SetFound(corpse, false)
	if string.find(corpse:GetModel(), "zm_", 6, true) then
        player.GetByUniqueID( corpse.uqid ):SetNWBool( "body_found", false )
        corpse:Remove()
        SendFullStateUpdate()
	elseif corpse.player_ragdoll then
        player.GetByUniqueID( corpse.uqid ):SetNWBool( "body_found", false )
		corpse:Remove()
        SendFullStateUpdate()
	end
end

am.addCMD("rbody", "Removes a player's dead body", "TTT", function(caller, target)
	local body

	for _, ent in pairs( ents.FindByClass( "prop_ragdoll" )) do
		if ent.uqid == target:UniqueID() and IsValid(ent) then
			body = ent
		end
	end

	if (IsValid(body) and (body.player_ragdoll or string.find(body:GetModel(), "zm_", 6, true))) then
		body:Remove()

		am.notify(nil, caller:Nick(), " has removed a body!")
	else
		am.notify(caller, "No body was found!")
	end

end):setGamemode("terrortown"):addParam("target", "player"):setPerm("ttt_rbody")
