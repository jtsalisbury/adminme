--[[am.addCMD("genkey", "Generate a new rank key", 'Misc', function(caller, rank, scope)
	if (not ndoc.table.am.permissions[ rank ]) then return end
	if (not ndoc.table.am.servers[ scope ] and scope != "global") then return end
	
	local generated_key = util.CRC(rank .. math.random(1, 1000) .. game.GetMap())

	local already_a_code = true
	while already_a_code do
		already_a_code = false

		local query = am.db:select("keys")
			query:where("key", generated_key)
			query:limit(1)
			query:callback(function(result)
				if (#result == 1) then
					already_a_code = true
				end
			end)
		query:execute()
	end

	local query = am.db:insert("keys")
		query:insert("key", generated_key)
		query:insert("rank", rank)
		query:insert("scope", scope)
	query:execute()

	am.notify(caller, "New key created for rank: ", am.green, rank, am.def, " with a key: ", am.green, generated_key)

end):addParam("rank", "string"):addParam("scope", "string"):setPerm("genkey")


am.addCMD("redeem", "Redeem a key", 'Misc', function(caller, key)

	local query = am.db:select("keys")
		query:where("key", key)
		query:callback(function(result)
			
			local result = result[1]

			if (result[ "redeemed_by" ] == nil or string.len(result["redeemed_by"]) < 1) then
				
				local rank = result[ "rank" ]
				
				local query = am.db:update("keys")
					query:update("redeemed_by", caller:SteamID())
					query:where("key", key)
				query:execute()

				local query = am.db:select("users")
					query:where("steamid", caller:SteamID())
					query:limit(1)
					query:callback(function(result)
						if (#result == 1) then
							am.db:update("users"):update("rank", rank):where("steamid", caller:SteamID()):update("name", caller:Nick()):execute()
						else
							am.db:insert("users"):insert("rank", rank):insert("steamid", caller:SteamID()):insert("name", caller:Nick()):execute()
						end
					end)
				query:execute()

				ndoc.table.adminMe.players[ caller ] = rank

			else
				am.notify(caller, "This key has been redeemed!")
			end
		end)
	query:execute()

end):addParam("key", "string")]]
