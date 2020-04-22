local mt = FindMetaTable("Player")

// Overwrite default IsAdmin to return whether the player meets the hierarchial requirement for at least one rank
local isadmin = mt.IsAdmin
function mt:IsAdmin()
	local ourHeir = self:getHierarchy()
	
	// Find the admin rank and determine if its set hierarchy is lte
	for rankid, info in ndoc.pairs(ndoc.table.am.permissions) do
		if (info.name == am.config.admin_rank) then
			if (ourHeir > info.hierarchy) then
				return true
			end
		end
	end

	return isadmin(self)
end

// Determines if a user has the correct hierarchy to be considered a superadmin
local issa = mt.IsSuperAdmin
function mt:IsSuperAdmin()
	local ourHeir = self:getHierarchy()

	// Find the superadmin rank and determine if its set hierarchy is lte
	for rankid, info in ndoc.pairs(ndoc.table.am.permissions) do
		if (info.name == am.config.superadmin_rank) then
			if (ourHeir > info.hierarchy) then
				return true
			end
		end
	end

	return issa(self)
end

// Returns a list of the rank ids for a user
function mt:getRankIds()
	return ndoc.table.am.users[ self:SteamID() ]
end

// Determines whether a user is a user group
local isug = mt.IsUserGroup
function mt:IsUserGroup(str)
	if (self:getRankIds() == nil) then
		return false
	end

	for rankid,v in ndoc.pairs(self:getRankIds()) do
		if (ndoc.table.am.permissions[rankid].name == str) then 
			return true
		end
	end

	return false
end

// Returns the highest user group of a user
local gug = mt.GetUserGroup
function mt:GetUserGroup()
	local _, rankid = self:getHierarchy()

	return ndoc.table.am.permissions[rankid].name
end

// Determines whether a player has the correct rank to execute a permission
function mt:hasPerm(perm)
	local rankids = self:getRankIds()

	for rankid, _ in ndoc.pairs(rankids) do
		for _, p in ndoc.pairs(ndoc.table.am.permissions[rankid].perm) do
			if (p == perm || p == "*") then return true end
		end
	end

	return false
end

// Returns whether the player is in admin mode
function mt:inAdminMode() 
	return SERVER && self.adminmode || self:GetNWBool("inAdminMode")
end

// Return the largest hierarchial value and the corresponding rankid for a user
function mt:getHierarchy()
	local ourLargestHeirarchy = 0
	local ourLargestRank

	// We don't have any data for the user
	if (!ndoc.table.am.users[ self:SteamID() ]) then
		return 0, 0
	end

	// Loop through the user's ranks
	for k,v in ndoc.pairs(ndoc.table.am.users[ self:SteamID() ]) do
		local curHeirarchy = ndoc.table.am.permissions[ k ].hierarchy

		if (curHeirarchy > ourLargestHeirarchy) then
			ourLargestHeirarchy = curHeirarchy
			ourLargestRank = k
		end
	end

	return ourLargestHeirarchy, ourLargestRank
end

// Returns the number in seconds that a player has been on the server
function mt:getPlayTime()
	local pastTime = ndoc.table.am.play_times[self:SteamID()]
	if (!pastTime) then
		pastTime = 0
	end

	return CurTime() - self._joinTime + pastTime
end

hook.Add('PlayerNoClip', 'cannoclip', function(ply)
	return ply:hasPerm("noclip") and ply:inAdminMode()
end)

// Returns a table of all online admin players
function am.getAdmins()
	local temp = {}

	// Find admins
	for k,v in pairs(player.GetAll()) do
		if (!v:IsAdmin()) then continue end

		table.insert(temp, v)
	end

	return temp
end