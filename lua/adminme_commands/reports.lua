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
		:insert("serverid", am.config.server_id)
		:insert("state", 0)
		:insert("reason", reason)
		:callback(function(res)
			// Notify all the admins
			am.notify(am.getAdmins(), "A new report against ", am.red, target:Nick(), am.def, " has been filed by ", am.green, caller:Nick())
		end)
	:execute()

end):addParam({
	name = "target", 
	type = "player"
}):addParam({
	name = "reason", 
	type = "string"
}):setPerm("report")

am.addCMD("creport", "Closes a report. This shouldn't be called outside of the menu!", "Administration", function(caller, id, notes)
	local q = am.db:update("reports"):update("state", 1):update("admin_notes", notes):where("id", id)
		:callback(function(res)
			am.notify(am.getAdmins(), "Report #" .. id .. " has been closed by " .. caller:Nick())
		end)
	:execute()

end):addParam({
	name = "id", 
	type = "number"
}):addParam({
	name = "notes",
	type = "string",
	optional = true
}):setPerm("creport"):disableUI()

am.addCMD("updatereport", "Updates a report with new notes. This shouldn't be called outside of the menu!", "Administration", function(caller, id, notes)
	local q = am.db:update("reports"):update("admin_notes", notes):where("id", id)
		:callback(function(res)
			am.notify(am.getAdmins(), "Report #" .. id .. " has been updated by " .. caller:Nick())
		end)
	:execute()

end):addParam({
	name = "id", 
	type = "number"
}):addParam({
	name = "notes",
	type = "string",
}):setPerm("creport"):disableUI()

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
				:where("serverid", am.config.server_id)
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