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

function am.removeFromRank(caller, target, rank, server)
	local servers = string.Explode(",", server)
	local allGood = true
	for k,v in pairs(servers) do
		if (not ndoc.table.am.servers[ v ] and v != "global") then
			allGood = false
		end
	end

	if (not allGood) then
		am.notify(caller, "One or more servers specified are incorrect! Please use only those from below!")

		am.notify(caller, "global")
		for k,v in ndoc.pairs(ndoc.table.am.servers) do
			am.notify(caller, k)
		end

		return
	end

	local allGood = false
	for k,v in ndoc.pairs(ndoc.table.am.permissions) do
		if (k == rank) then
			allGood = true
		end
	end

	if (not allGood) then
		am.notify(caller, "Invalid rank specified! Please use only those below!")

		for k,v in ndoc.pairs(ndoc.table.am.permissions) do
			am.notify(caller, k)
		end

		return
	end

	local q = am.db:select("users")
		q:where("steamid", target:SteamID())
		q:limit(1)
		q:callback(function(res)
			if (table.Count(res) == 1) then
				local tempConstr = util.JSONToTable(res[1]["rank"])

				if (tempConstr[ rank ]) then
					local tempHold = tempConstr[ rank ]

					if (server == "global") then
						tempConstr[ rank ] = nil
					else
						for k,v in pairs(servers) do
							if (table.HasValue(tempHold, v)) then
								table.RemoveByValue(tempHold, v)
							end
						end

						if (table.Count(tempHold) == 0) then
							tempConstr[ rank ] = nil
						else
							tempConstr[ rank ] = tempHold
						end
					end

					local tempTimes = util.JSONToTable(res[1]["expires"])
					tempTimes[ rank ] = nil

					tempTimes = util.TableToJSON(tempTimes)

					am.db:update("users"):update("rank", util.TableToJSON(tempConstr)):update("name", target:Nick()):where("steamid", target:SteamID()):update("expires", tempTimes):execute()

					am.notify(nil, am.green, caller:Nick(), am.def, " has removed ", am.red, target:Nick(), am.def, " from ", am.red, rank, am.def, " on ", am.red, server)
				else
					am.notify(caller, "This user is not a part of that rank on any server!")
				end
			end

			am.pullUserInfo(target)
		end)
	q:execute()
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

function am.pullUserInfo(ply)
	if (not am.db.connection) then
		am.db:connect()
	end

	local query = am.db:select("users"):where("steamid", ply:SteamID()):limit(1):callback(function(res)
			if (!IsValid(ply)) then
				return
			end

			ndoc.table.am.users[ ply:SteamID() ] = {
				[am.config.default_rank] = {"global"}
			}

			if (table.Count(res) == 0) then
				return
			end

			local row = res[1]
			local exp = util.JSONToTable(row["expires"]) or {}
			local ranks = util.JSONToTable(row["rank"]) or {}

			for k,v in pairs(ranks) do
				if (!table.HasValue(v, "global") and !table.HasValue(v, am.config.server_id)) then
					if (exp[k]) then
						exp[k] = nil
					end

					ranks[k] = nil
				end
			end

			for k,v in pairs(exp) do
				if (os.time() >= v) then
					am.removeFromRank(ply, ply, k, "global")

					exp[k] = nil
					am.notify(ply, "Your rank of ", am.green, k, am.def, " has expired and you've been removed!")

				else
					local expire_time = os.date("%m/%d/%Y - %H:%M:%S", v)
					am.notify(ply, "Your rank of ", am.green, k, am.def, " will expire on ", am.red, expire_time)
				end
			end

			if (table.Count(exp) > 0) then
				ply.rank_expires_on = exp

				local sid = ply:SteamID()
				timer.Create("rank_expire_check_" .. ply:SteamID(), am.config.expire_check_time, 0, function()

					if (!IsValid(ply)) then

						timer.Destroy("rank_expire_check_" .. sid)
						return
					end

					for k,v in pairs(ply.rank_expires_on) do
						if (v <= os.time()) then
							am.removeFromRank(ply, ply, k, "global")

							ply.rank_expires_on[ k ] = nil

							am.notify(ply, "Your rank of ", am.green, k, am.def, " has expired and you've been removed!")
						end
					end

					if (table.Count(ply.rank_expires_on) == 0) then
						timer.Destroy("rank_expire_check_" .. sid)
					end
				end)
			end

			ndoc.table.am.users[ ply:SteamID() ] = ranks
		end):execute()
end

function am.pullGroupInfo()
	am.db:select("ranks"):callback(function(res)
		for k,v in pairs(res) do
			local rank = v["rank"]
			local perms = util.JSONToTable(v["perms"])
			local heir = v["heirarchy"]

			ndoc.table.am.permissions[rank] = {perm = perms, heir = heir}

			am.print("Found user group: " .. rank)
		end

		hook.Call("am.RanksLoaded", GAMEMODE)
	end):execute()
end

function am.pullWarningInfo(ply)
	if (!IsValid(ply)) then return end

	am.db:select("warnings"):where("steamid", ply:SteamID()):callback(function(res)
		for k,v in pairs(res) do

			am.print('Found warning for: ', v["steamid"])

			ndoc.table.am.warnings[ v["steamid"] ] = {
				warningCount = v["warnings"],
				warningData = util.JSONToTable(v["warningsData"]),
				nick = v["name"]
			}
		end

		if (!IsValid(ply)) then
			return
		end

		if (table.Count(res) > 0) then
			am.notify(am.getAdmins(), "Warning! ", am.def, " Player ", am.red, ply:Nick(), am.def, " is on the warning list!")
		end
	end):execute()
end


function am.checkBan(steamid, ip, ply, lender)
	local query = am.db:select("bans")
		query:where("banned_steamid", steamid)
		query:where("ban_active", 1)
		query:callback(function(v)
			if (table.Count(v) == 0) then return end

			v = v[1]

			if (v["banned_timestamp"] + v["banned_time"] > os.time()) then
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

				ply:Kick("You're banned!\nReason: "..v['banned_reason'].. "\nBanned by: "..v["banner_name"].."\nTime left: ".. (v["banned_timestamp"] + v["banned_time"] - os.time()) .. " seconds\nAppeal at: ".. am.config.website)
				return
			else
				local query = am.db:update("bans")
					query:update("ban_active", 0)
					query:where("id", v["id"])
				query:execute()
			end
		end)

	query:execute()

	local query = am.db:select("bans")
		query:where("banned_ip", ip)
		query:where("ban_active", 1)
		query:callback(function(v)
			if (table.Count(v) == 0) then return end

			v = v[1]

			if (v["banned_timestamp"] + v["banned_time"] > os.time()) then
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

				ply:Kick("You're banned!\nReason: "..v['banned_reason'].. "\nBanned by: "..v["banner_name"].."\nTime left: ".. (v["banned_timestamp"] + v["banned_time"] - os.time()) .. " seconds\nAppeal at: ".. am.config.website)
				return
			else
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
