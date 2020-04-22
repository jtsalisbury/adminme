function am.notify(ply, ...)
	if (ply == nil) then ply = player.GetAll() end

	local tbl = {...}
	local tTbl = {}

	for k,v in pairs(tbl) do
		if (type(v) == "number") then
			v = tostring(v)
		end

		tTbl[ k ] = v
	end

	net.Start("am.notify")
		net.WriteTable(tTbl)
	net.Send(ply)
end

function am.print(...)
	print("[AdminMe]: ", ...)
end

function am.addToRank(caller, target, rankid, serverid, expireTime)
	// Verify the servers exist
	if (!ndoc.table.am.servers[ serverid ] && serverid != 0) then
		am.notify(caller, "Server specified is incorrect! Please use only those from below!")

		for k,v in ndoc.pairs(ndoc.table.am.servers) do
			am.notify(caller, v.name)
		end

		return
	end


	// Verify the user has the rank
	local rankAlreadySet = false
	if (ndoc.table.am.users[target:SteamID()][rankid] && ndoc.table.am.users[target:SteamID()][rankid][serverid]) then
		am.notify(caller, "The user is already that rank on that server - this will overwrite any expiration time")
		rankAlreadySet = true
	end

	// Verify the rank exists
	if (!ndoc.table.am.permissions[rankid]) then
		am.notify(caller, "Invalid rank specified! Please use only those below!")

		for rankid, rankInfo in ndoc.pairs(ndoc.table.am.permissions) do

			am.notify(caller, rankInfo.name)
		end
	end

	// Get an updated expiration time
	expireTime = expireTime && expireTime + os.time() || 0
	
	// Update the database
	if (rankAlreadySet) then
		am.db:update("users"):update("expires", expireTime):where("steamid", target:SteamID()):where("rankid", rankid):where("serverid", serverid):execute()
	else
		am.db:insert("users"):insert("expires", expireTime):insert("steamid", target:SteamID()):insert("rankid", rankid):insert("serverid", serverid):insert("name", target:Nick()):execute()
	end

	ndoc.table.am.users[target:SteamID()][rankid] = ndoc.table.am.users[target:SteamID()][rankid] || {}
	ndoc.table.am.users[target:SteamID()][rankid][serverid] = ndoc.table.am.users[target:SteamID()][rankid][serverid] || {}
	ndoc.table.am.users[target:SteamID()][rankid][serverid].expires = expireTime
end

function am.removeFromRank(caller, target, rankid, serverid)
	// Verify the servers exist
	if (serverid && !ndoc.table.am.servers[ serverid ] && serverid != 0) then
		am.notify(caller, "Server specified is incorrect! Please use only those from below!")

		for k,v in ndoc.pairs(ndoc.table.am.servers) do
			am.notify(caller, v.name)
		end

		return
	end

	// Verify the user has the rank
	if (rankdid && !ndoc.table.am.users[target:SteamID()][rankid]) then
		am.notify(caller, "Invalid rank specified! Please use only those below!")

		for rankid,v in ndoc.pairs(ndoc.table.am.users[target:SteamID()]) do
			local rankName = ndoc.table.am.permissions[rankid].name

			am.notify(caller, rankName)
		end

		return
	end

	// Delete row entry
	if (rankid && serverid != nil) then // Delete rank on server
		am.db:delete("users"):where("steamid", target:SteamID()):where("rankid", rankid):where("serverid", serverid):execute()
		ndoc.table.am.users[target:SteamID()][rankid][serverid] = nil

		// If there are no scopes left, remove the rank
		local entryCount = 0
		for k,v in ndoc.pairs(ndoc.table.am.users[target:SteamID()][rankid]) do
			entryCount = entryCount + 1
		end
		
		// Remove user from rank entirely if there's nothing there
		if (entryCount == 0) then
			ndoc.table.am.users[target:SteamID()][rankid] = nil
		end
		//if (table.Count(ndoc.table.am.users[target:SteamID()][rankid]) == 0)
	elseif (rankid) then // Delete all servers with that rank
		am.db:delete("users"):where("steamid", target:SteamID()):where("rankid", rankid):execute()
		ndoc.table.am.users[target:SteamID()][rankid] = nil
	else // Delete all ranks on all servers
		am.db:delete("users"):where("steamid", target:SteamID()):execute()
		ndoc.table.am.users[target:SteamID()] = am.getDefaultUserProfile()
	end
end

function am.addPlayerEvent(target, event)
	target.events = target.events or {}

	table.insert(target.events, {["ev"] = event, ["time"] = os.time()})
	ndoc.table.am.events[ target:SteamID() ] = ndoc.table.am.events[ target:SteamID() ] || {}

	ndoc.table.am.events[ target:SteamID() ][ os.time() ] = event

	local q = am.db:insert("logs")
		q:insert("steamid", target:SteamID())
		q:insert("event", event)
		q:insert("timestamp", os.time())
	q:execute()
end

function am.pullServerInfo()
	am.db:select("servers"):callback(function(res)
		// Grab all servers
		for k,v in pairs(res) do
			am.print("Found server " .. v["name"])
			ndoc.table.am.servers[v["id"]] = {ip = v["ip"], port = v["port"], name = v["name"]}
		end
	end):execute()
end

function am.checkExpiredRank(ply)
	if (!ndoc.table.am.users[ply:SteamID()]) then
		return
	end

	// Loop through player's rank
	for rankid, info in ndoc.pairs(ndoc.table.am.users[ply:SteamID()]) do
		if (!info) then
			continue
		end

		for scope, scopeInfo in ndoc.pairs(info) do
			// Ensure the rank isn't permenant
			if (scopeInfo.expires == 0) then
				continue
			end

			print(rankid)
			local rankName = ndoc.table.am.permissions[rankid].name

			// Test for expiration
			if (scopeInfo.expires <= os.time()) then
				am.removeFromRank(ply, ply, rankid, scope)

				am.notify(ply, "Your rank of ", am.green, rankName, am.def, " has expired and you've been removed!")
				am.notify(nil, am.green, ply:Nick(), am.def, " has been auto-removed from ", am.red, rankName)
				continue
			else
				local expire_time = os.date("%m/%d/%Y - %H:%M:%S", v)
				am.notify(ply, "Your rank of ", am.green, rankName, am.def, " will expire on ", am.red, expire_time)
			end
		end
	end
end

// Function to loop through all the players and check if they're rank has expired
function am.checkAllExpired()
	timer.Create("am.rank_expiration_check", am.config.expire_check_time, 0, function()
		am.print("Checking for expired ranks..")
		for k,v in pairs(player.GetAll()) do
			am.checkExpiredRank(v)
		end
	end)
end	

function am.getDefaultUserProfile()
	// TODO: These should be removed once config can be saved
	local defaultRankId = nil
	for rankid,rankinfo in ndoc.pairs(ndoc.table.am.permissions) do
		if (rankinfo.name == am.config.default_rank) then
			defaultRankId = rankid
		end
	end

	return {
		[defaultRankId] = { 
			[0] = {
				expires = 0
			}
			
		}
	}	
end

function am.pullUserInfo(ply)
	if (not am.db.connection) then
		am.db:connect()
	end

	// A default entry for the default rank
	ndoc.table.am.users[ ply:SteamID() ] = am.getDefaultUserProfile()

	// Select all user info
	local query = am.db:select("users"):where("steamid", ply:SteamID()):callback(function(res)
		if (!IsValid(ply)) then
			return
		end

		// Default construct
		local ranks = am.getDefaultUserProfile()

		for k, row in pairs(res) do	
			// Make sure the server exists
			if (!ndoc.table.am.servers[row["serverid"]]) then
				am.removeFromRank(ply, ply, row["rankid"], row["serverid"])
				continue
			end

			// Make sure the rank still exists
			if (!ndoc.table.am.permissions[row["rankid"]]) then
				am.removeFromRank(ply, ply, row["rankid"], row["serverid"]) 
				continue
			end

			// Structure: user{} -> rank id -> scope id -> expiresOn 
			ranks[ row["rankid"] ] = ranks[ row["rankid"] ] || { }
			ranks[ row["rankid"] ][row["serverid"]] = {
				expires = row["expires"]
			}
		end

		ndoc.table.am.users[ply:SteamID()] = ranks;
		
		// We add all ranks regardless, but now let's see if one is expired
		am.checkExpiredRank(ply)
	end):execute()

	// Get the current play time for the user
	am.db:select("play_times"):where("steamid", ply:SteamID()):callback(function(res)
		// No play time :(
		if (#res == 0) then
			ndoc.table.am.play_times[ply:SteamID()] = 0
			return
		end

		ndoc.table.am.play_times[ply:SteamID()] = res[1]["play_time_seconds"];
	end):execute()
end

function am.pullGroupInfo()
	am.db:select("ranks"):callback(function(res)
		for k,v in pairs(res) do
			local rankid = v["id"]
			local rankName = v["rank"]
			local perms = util.JSONToTable(v["perms"])
			local hierarchy = v["hierarchy"]

			ndoc.table.am.permissions[rankid] = {perm = perms, hierarchy = hierarchy, name = rankName}

			am.print("Found user group: " .. rankName)
		end

		hook.Call("am.RanksLoaded", GAMEMODE)
	end):execute()
end

// Update the play time of the current user
function am.updatePlayTime(ply) 
	local newTime = ply:getPlayTime()

	// Zero play time indicates a new player!
	if (ndoc.table.am.play_times[ply:SteamID()] != 0) then
		am.db:insert("play_times"):insert("steamid", ply:SteamID()):insert("nick", ply:Nick()):insert("last_join", os.time()):insert("play_time_seconds", newTime):execute()
	else
		am.db:update("play_times"):update("last_join", os.time()):update("play_time_seconds", newTime):where("steamid", ply:SteamID()):execute()
	end	
end

// TODO: Update warnings - get rid of json!
function am.pullWarningInfo(ply)
	if (!IsValid(ply)) then return end

	// Cache the user info and init warning table
	local sid = ply:SteamID()
	ndoc.table.am.warnings[ v["steamid"] ] = {}

	// Select all the warnings for the user
	am.db:select("warnings"):where("steamid", sid):callback(function(res)
		if (#res == 0) then
			return
		end

		// Insert warning data into networked table
		ndoc.table.am.warnings[sid].warningCount = #res
		for k,row in pairs(res) do
			table.insert(ndoc.table.am.warnings[sid].warnings, {
				admin = row["admin_nick"],
				reason = row["reason"],
				timestamp = row["timestamp"],
				warningNum = row["warningNum"]
			})
		end

		if (table.Count(res) > 0) then
			am.notify(am.getAdmins(), "Warning! ", am.def, " Player ", am.red, ply:Nick(), am.def, " is on the warning list!")
		end
	end):execute()
end

// Handles checking if a user is banned by the IP or steamid
function am.checkBan(ply, lender)
	local steamid = ply:SteamID()
	local ip = ply:IPAddress()

	// Check to see if the user is banned via their steamid
	local query = am.db:select("bans")
		query:where("banned_steamid", steamid)
		query:where("ban_active", 1)
		query:callback(function(v)
			if (table.Count(v) == 0) then return end

			v = v[1]

			// If it hasn't expired
			if (v["banned_timestamp"] + v["banned_time"] > os.time()) then

				// Check for family sharing
				if (lender) then
					local query = am.db:insert("bans")
						query:insert("banned_steamid", ply:SteamID())
						query:insert("banned_name", v["banned_name"])
						query:insert("banned_timestamp", v["banned_timestamp"])
						query:insert("banned_reason", v["banned_reason"])
						query:insert("banned_time", v["banned_time"])
						query:insert("banner_steamid", v["banner_steamid"])
						query:insert("banner_name", v["banner_name"])
					query:execute()
				end

				// Kick the user
				ply:Kick("You're banned!\nReason: "..v['banned_reason'].. "\nBanned by: "..v["banner_name"].."\nTime left: ".. (v["banned_timestamp"] + v["banned_time"] - os.time()) .. " seconds\nAppeal at: ".. am.config.website)
				return
			else
				// Not banned, mark the ban as inactive
				local query = am.db:update("bans")
					query:update("ban_active", 0)
					query:where("id", v["id"])
				query:execute()
			end
		end)

	query:execute()

	// Check to see if the user is banned via their IP
	local query = am.db:select("bans")
		query:where("banned_ip", ip)
		query:where("ban_active", 1)
		query:callback(function(v)
			if (table.Count(v) == 0) then return end

			v = v[1]

			// Check to see if it has expired
			if (v["banned_timestamp"] + v["banned_time"] > os.time()) then

				// Family sharing checks
				if (lender) then
					local query = am.db:insert("bans")
						query:insert("banned_steamid", ply:SteamID())
						query:insert("banned_name", v["banned_name"])
						query:insert("banned_timestamp", v["banned_timestamp"])
						query:insert("banned_reason", v["banned_reason"])
						query:insert("banned_time", v["banned_time"])
						query:insert("banner_steamid", v["banner_steamid"])
						query:insert("banner_name", v["banner_name"])
					query:execute()
				end

				// Kick 'em!
				ply:Kick("You're banned!\nReason: "..v['banned_reason'].. "\nBanned by: "..v["banner_name"].."\nTime left: ".. (v["banned_timestamp"] + v["banned_time"] - os.time()) .. " seconds\nAppeal at: ".. am.config.website)
				return
			else

				// Mark the ban as inactive
				local query = am.db:update("bans")
					query:update("ban_active", 0)
					query:where("id", v["id"])
				query:execute()
			end
		end)
	query:execute()
end

// Pull bans for menu editing / viewing
util.AddNetworkString("am.requestBanList")
util.AddNetworkString("am.syncBanList")

net.Receive("am.requestBanList", function(_, ply)
	if (!ply:hasPerm("banmgmt")) then return end

	local query = am.db:select("bans"):where("ban_active", 1):callback(function(res)
		net.Start("am.syncBanList")
			net.WriteTable(res)
		net.Send(ply)

	end):execute()
end)
