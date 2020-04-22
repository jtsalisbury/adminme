util.AddNetworkString("am.syncReportList")
util.AddNetworkString("am.requestReportList")

am.addCMD("report", 'Report a player', 'Administration', function(caller, target, reason)
	// We don't want players to report more than once a session
	if (caller.reports && caller.reports[ target ]) then
		am.notify(caller, "You've already reported this player!")
		return
	end

	caller.reports = caller.reports || {}
	caller.reports[ target ] = true

	// Create a new report
	local q = am.db:insert("reports")
		:insert("creator_steamid", caller:SteamID())
		:insert("creator_nick", caller:Nick())
		:insert("target_steamid", target:SteamID())
		:insert("target_nick", target:Nick())
		:insert("server", am.config.server_name)
		:insert("state", 0)
		:insert("reason", reason)
		:callback(function(res)
			// Notify all the admins
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

	// Grab all the active reports
	local q = am.db:select("reports"):where("state", 0)
		:callback(function(res)
			// Send it back to the client
			net.Start("am.syncReportList")
				net.WriteTable(res)
			net.Send(ply)
			
		end)
	:execute()
end)

hook.Add("PlayerInitialSpawn", "am.activeReports", function(ply)
	// Send all the reports to the player once they initialize
	timer.Simple(30, function() 
		if (ply:hasPerm("creport")) then
			local q = am.db:select("reports")
				:where("state", 0)
				:where("server", am.config.server_name)
				:callback(function(res)
					local count = #res

					if (#res == 0) then return end

					// Notification that there are open reports
					am.notify(ply, "There are currently ", am.red, count, am.def, " open reports!")
				end)
			:execute()
		end
	end)
end)