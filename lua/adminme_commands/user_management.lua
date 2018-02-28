hook.Add("am.RanksLoaded", "AddUserRanks", function() 
	local ranks = {}
	for k,v in ndoc.pairs(ndoc.table.am.permissions) do
		table.insert(ranks, k)
	end

	am.addCMD("adduser", "Adds a player to a rank", "User Mgmt", function(caller, target, server, rank)
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
				if (#res == 1) then
					local tempConstr = util.JSONToTable(res[1]["rank"])

					if (tempConstr[ rank ]) then
						local tempHold = tempConstr[ rank ]

						for k,v in pairs(servers) do
							if (!table.HasValue(tempHold, v)) then
								table.insert(tempHold, v)
							end
						end

						tempConstr[ rank ] = tempHold					
					else
						tempConstr[ rank ] = servers
					end

					am.db:update("users"):update("rank", util.TableToJSON(tempConstr)):update("name", target:Nick()):where("steamid", target:SteamID()):execute()
				else
					local tempConstr = {}
					tempConstr[ rank ] = servers

					am.db:insert("users"):insert("rank", util.TableToJSON(tempConstr)):insert("name", target:Nicker()):insert("steamid", target:SteamID()):execute()
				end

				am.notify(nil, am.green, caller:Nick(), am.def, " has added ", am.green, target:Nick(), am.def, " to ", am.green, rank, am.def, " on ", am.green, server)

				am.pullUserInfo(target)
			end)
		q:execute()	
	end):addParam("target", "player"):addParam("Server(s)", "string"):addParam("rank", "string", nil, ranks):setPerm("usermgmt")

	am.addCMD("tadduser", "Temporarily add a user to rank for a specified amount of time", "User Mgmt", function(caller, target, rank, server, time, time_type)
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

		local modTime = am.modTime(time_type, time)

		local q = am.db:select("users")
			q:where("steamid", target:SteamID())
			q:limit(1)
			q:callback(function(res)
				if (#res == 1) then
					local tempConstr = util.JSONToTable(res[1]["rank"])

					if (tempConstr[ rank ]) then
						local tempHold = tempConstr[ rank ]

						for k,v in pairs(servers) do
							if (!table.HasValue(tempHold, v)) then
								table.insert(tempHold, v)
							end
						end

						tempConstr[ rank ] = tempHold					
					else
						tempConstr[ rank ] = servers
					end

					local tempTimes = util.JSONToTable(res[1]["expires"]) or {}
					tempTimes[ rank ] = os.time() + modTime

					am.db:update("users"):update("rank", util.TableToJSON(tempConstr)):update("name", target:Nick()):where("steamid", target:SteamID()):update("expires", util.TableToJSON(tempTimes)):execute()
				else
					local tempConstr = {}
					tempConstr[ rank ] = servers

					local tempTimes = {}
					tempTimes[ rank ] = os.time() + modTime

					am.db:insert("users"):insert("rank", util.TableToJSON(tempConstr)):insert("name", target:Nicker()):insert("steamid", target:SteamID()):insert("expires", util.TableToJSON(tempTimes)):execute()
				end

				am.notify(nil, am.green, caller:Nick(), am.def, " has added ", am.green, target:Nick(), am.def, " to ", am.green, rank, am.def, " on ", am.green, server, am.def, " until ", am.green, os.date("%m/%d/%Y - %H:%M:%S", os.time() + modTime))

				am.pullUserInfo(target)
			end)
		q:execute()	

	end):addParam("target", "player"):addParam("rank", "string", nil, ranks):addParam("Server(s)", "string"):addParam("time", "number", "1"):addParam("time type", "time_type", "d"):setPerm("usermgmt")

	am.addCMD("remuser", "Removes all ranks from a player", "User Mgmt", function(caller, target)
		local q = am.db:delete("users")
			q:where("steamid", target:SteamID())
			q:callback(function()
				am.pullUserInfo(target)
			end)
		q:execute()

		am.notify(nil, am.green, caller:Nick(), am.def, " has removed ", am.red, target:Nick(), am.def, " from all ranks!")
	end):addParam("target", "player"):setPerm("usermgmt")

	am.addCMD("remrank", "Removes a user from a specific rank and server", "User Mgmt", function(caller, target, rank, server)
		am.removeFromRank(caller, target, rank, server)
		
	end):addParam("target", "player"):addParam("rank", "string"):addParam("server", "string"):setPerm("usermgmt")

end)