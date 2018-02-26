local mt = FindMetaTable("Player")

local isadmin = mt.IsAdmin
function mt:IsAdmin()
	local ourHeir = self:getHeirarchy()
	local aHeirarchy = ndoc.table.am.permissions[ am.config.admin_rank ].heir or 0

	if (aHeirarchy and ourHeir > aHeirarchy) then
		return true
	end

	return isadmin(self)
end

local issa = mt.IsSuperAdmin
function mt:IsSuperAdmin()
	local ourHeir = self:getHeirarchy()
	local aHeirarchy = ndoc.table.am.permissions[ am.config.superadmin_rank ].heir or 0

	if (aHeirarchy and ourHeir > aHeirarchy) then
		return true
	end

	return issa(self)
end

function mt:getRanks()
	return ndoc.table.am.users[ self:SteamID() ]
end

local isug = mt.IsUserGroup
function mt:IsUserGroup(str)
	if (self:getRanks() == nil) then
		return false
	end

	for k,v in ndoc.pairs(self:getRanks()) do
		if (v == str) then 
			return true
		end
	end

	return false
end

local gug = mt.GetUserGroup
function mt:GetUserGroup()
	local _, rank = self:getHeirarchy()

	return rank
end

function mt:hasPerm(perm)
	local ranks = self:getRanks()

	for rank, _ in ndoc.pairs(ranks) do
		for _, p in ndoc.pairs(ndoc.table.am.permissions[rank].perm) do
			if (p == perm or p == "*") then return true end
		end
	end

	return false
end

function mt:inAdminMode() 
	return SERVER and self.adminmode or self:GetNWBool("inAdminMode")
end

function mt:getHeirarchy()
	local ourLargestHeirarchy = 0
	local ourLargestRank

	if (!ndoc.table.am.users[ self:SteamID() ]) then
		return 0, "user"
	end

	for k,v in ndoc.pairs(ndoc.table.am.users[ self:SteamID() ]) do
		local curHeirarchy = ndoc.table.am.permissions[ k ].heir

		if (curHeirarchy > ourLargestHeirarchy) then
			ourLargestHeirarchy = curHeirarchy
			ourLargestRank = k
		end
	end

	return ourLargestHeirarchy, ourLargestRank
end

hook.Add('PlayerNoClip', 'cannoclip', function(ply)
	return ply:hasPerm("noclip") and ply:inAdminMode()
end)

function am.getAdmins()
	local temp = {}

	for k,v in pairs(player.GetAll()) do
		if (!v:IsAdmin()) then continue end

		table.insert(temp, v)
	end

	return temp
end

function am.modTime(timeType, time)

	if (timeType == "s") then
		time = time, "seconds"
	elseif (timeType == "min") then
		time = time * 60, "minutes"
	elseif (timeType == "hr") then
		time = time * 60 * 60, "hours"
	elseif (timeType == "d") then
		time = time * 60 * 60 * 24, "days"
	elseif (timeType == "m") then
		time = time * 60 * 60 * 24 * 30, "months"
	elseif (timeType == "yr") then
		time = time * 60 * 60 * 24 * 30 * 12, "years"
	end

	return time
end