// TODO: get rid of this 

am.addCMD("warn", 'Warn a player', 'Administration', function(caller, target, reason)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has warned ', am.red, target:Nick(), am.def, " for ", am.green, reason)

	// Initialize the info if it's not already
	local fdata = ndoc.table.am.warnings[ target:SteamID() ]
	if (fdata == nil) then
		ndoc.table.am.warnings[ target:SteamID() ] = {
			warningCount = 0,
			warnings = {},
			nick = target:Nick()
		}
	end

	// Update the netdoc table
	local warningNum = ndoc.table.am.warnings[ target:SteamID() ].warningCount + 1
	
	ndoc.table.am.warnings[ target:SteamID() ].warningCount = warningNum
	ndoc.table.am.warnings[ target:SteamID() ].warnings[warningNum] = {
		["admin"] = caller:Nick(),
		["reason"] = reason,
		["timestamp"] = os.time(),
		["warningNum"] = warningNum
	}
	
	// Save the new warning
	am.db:insert("warnings")
		:insert("nick", target:Nick())
		:insert("steamid", target:SteamID())
		:insert("reason", reason)
		:insert("warningNum", ndoc.table.am.warnings[ target:SteamID() ].warningCount)
		:insert("admin_nick", caller:Nick())
		:insert("timestamp", os.time())
	:execute()
end):addParam('target', 'player'):addParam("reason", "string"):setPerm("warnings")