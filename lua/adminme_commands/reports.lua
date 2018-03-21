util.AddNetworkString("am.syncReportList")
util.AddNetworkString("am.requestReportList")

am.addCMD("report", 'Report a player', 'Administration', function(caller, target, reason)
	
	if (caller.reports and caller.reports[ target ]) then
		am.notify(caller, "You've already reported this player!")
		return
	end

	caller.reports = caller.reports or {}
	caller.reports[ target ] = true

	local q = am.db:insert("reports")
		:insert("creator_steamid", caller:SteamID())
		:insert("creator_nick", caller:Nick())
		:insert("target_steamid", target:SteamID())
		:insert("target_nick", target:Nick())
		:insert("server", am.config.server_id)
		:insert("state", 0)
		:insert("reason", reason)
		:callback(function(res)

			am.notify(am.getAdmins(), "A new report from ", am.green, caller:Nick(), am.def, " against ", am.red, target:Nick(), am.def, " has been filed for ", am.green, reason)
		
		end)
	:execute()

end):addParam("target", "player"):addParam("reason", "string"):setPerm("report")

am.addCMD("creport", "Closes a report. This shouldn't be called outside of the menu!", "Administration", function(caller, id)

	local q = am.db:update("reports"):update("state", 1):where("id", id)
		:callback(function(res)
			am.notify(am.getAdmins(), "The report with id #" .. id .. " has been closed by " .. caller:Nick())
		end)
	:execute()

end):addParam("id", "number"):setPerm("creport")

net.Receive("am.requestReportList", function(l, ply)
	if (!ply:hasPerm("creport")) then return end
	
	local q = am.db:select("reports"):where("state", 0)
		:callback(function(res)

			net.Start("am.syncReportList")
				net.WriteTable(res)
			net.Send(ply)
			
		end)
	:execute()
end)

hook.Add("PlayerInitialSpawn", "am.activeReports", function(ply)
	timer.Simple(30, function() 
		if (ply:IsAdmin()) then
			local q = am.db:select("reports")
				:where("state", 0)
				:where("server", am.config.server_id)
				:callback(function(res)
					local count = #res

					if (#res == 0) then return end

					am.notify(ply, "There are currently ", am.red, count, am.def, " open reports!")
				end)
			:execute()
		end
	end)
end)