hook.Add("PhysgunPickup", "AllowPlayerPhysing", function(ply, targ)
	if (targ:IsPlayer() and targ:IsValid()) then
		// Ensure we can actually physgun them
		if (ply:hasPerm("physgun") && targ:getHierarchy() < ply:getHierarchy()) then
			targ:SetMoveType(MOVETYPE_NONE);
			return true
		else
			return
		end
	end
end)

hook.Add("PhysgunDrop", "AllowPlayerDePhysing", function(ply, targ)
	if (targ:IsPlayer()) then
		targ:SetMoveType(MOVETYPE_WALK);
	end
end)
