am.addCMD("warn", 'Warn a player', 'Administration', function(caller, target, reason)
	am.notify(nil, am.green, caller:Nick(), am.def, ' has warned ', am.red, target:Nick(), am.def, " for ", am.green, reason)

	local fdata = ndoc.table.am.warnings[ target:SteamID() ]
	if (fdata == nil) then
		ndoc.table.am.warnings[ target:SteamID() ] = {}
		ndoc.table.am.warnings[ target:SteamID() ].warningCount = 0
		ndoc.table.am.warnings[ target:SteamID() ].warningData = {}
		ndoc.table.am.warnings[ target:SteamID() ].nick = target:Nick()
	end

	ndoc.table.am.warnings[ target:SteamID() ].warningCount = ndoc.table.am.warnings[ target:SteamID() ].warningCount + 1
	ndoc.table.am.warnings[ target:SteamID() ].warningData[ ndoc.table.am.warnings[ target:SteamID() ].warningCount ] = {
			["admin"] = caller:Nick(),
			["reason"] = reason,
			["timestamp"] = os.time()
		}

	--get the updated data
	local data = ndoc.table.am.warnings[ target:SteamID() ]
	local unNetdocdTable = {}

	for k,v in ndoc.pairs(ndoc.table.am.warnings[ target:SteamID() ].warningData) do

		unNetdocdTable[k] = {
			["admin"] = v["admin"],
			["reason"] = v["reason"],
			["timestamp"] = v["timestamp"]
		}
	end

	if (fdata != nil) then
		am.db:update("warnings"):update("warnings", data.warningCount):update("warningsData", util.TableToJSON(unNetdocdTable)):where("steamid", target:SteamID()):execute()
	else
		am.db:insert("warnings"):insert("name", target:Nick()):insert("warnings", data.warningCount):insert("warningsData", util.TableToJSON(unNetdocdTable)):insert("steamid", target:SteamID()):execute()
	end

end):addParam('target', 'player'):addParam("reason", "string"):setPerm("warnings")