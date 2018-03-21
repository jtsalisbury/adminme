local function initDB()
	am.db = ezdb.create(am.config.MySQL)

	print("Attempting connection to db...")

	function am.db:onConnected()
		print("Connected to db!")
		
		print("Creating default tables...")

		--schema for database!
		self:create("ranks")
			:create("id", "INTEGER NOT NULL AUTO_INCREMENT")
			:create("rank", "varchar(40) NOT NULL")
			:create("perms", "varchar(400) NOT NULL")
			:create("heirarchy", "INTEGER NOT NULL")
			:primaryKey("id")
		:execute()

		self:create("users")
			:create("id", "INTEGER NOT NULL AUTO_INCREMENT")
			:create("name", "varchar(100) NOT NULL")
			:create("steamid", "varchar(240) NOT NULL")
			:create("rank", "varchar(255) NOT NULL")
			:create("expires", "varchar(255) NOT NULL default 0")
			:primaryKey("id")
		:execute()

		self:create("keys")
			:create("id", "INTEGER NOT NULL AUTO_INCREMENT")
			:create("redeemed_by", "varchar(40)")
			:create("key", "varchar(100) NOT NULL")
			:create("rank", "varchar(40) NOT NULL")
			:primaryKey("id")
		:execute()

		self:create("logs")
			:create("id", "INTEGER NOT NULL AUTO_INCREMENT")
			:create("steamid", "varchar(255) NOT NULL")
			:create("event", "varchar(400) NOT NULL")
			:create("timestamp", "INTEGER NOT NULL")
			:primaryKey("id")
		:execute()

		self:create("bans")
			:create("id", "INTEGER NOT NULL AUTO_INCREMENT")
			:create("banned_steamid", "varchar(255)")
			:create("banned_name", "varchar(255)")
			:create("banned_timestamp", "INTEGER NOT NULL")
			:create("banned_reason", "varchar(255)")
			:create("banned_time", "INTEGER NOT NULL")
			:create("banner_steamid", "varchar(255)")
			:create("banner_name", "varchar(255)")
			:create("ban_active", "boolean not null default 1")
			:create("banned_ip", "varchar(255)")
			:primaryKey("id")
		:execute()

		self:create("play_times")
			:create("id", "INTEGER NOT NULL AUTO_INCREMENT")
			:create("steamid", "varchar(255) NOT NULL")
			:create("nick", "varchar(255) NOT NULL")
			:create("last_join", "INTEGER NOT NULL")
			:create("play_time_seconds", "INTEGER NOT NULL")
			:primaryKey("id")
		:execute()

		self:create("screenCaps")
			:create("id", "INTEGER NOT NULL AUTO_INCREMENT")
			:create("capped_name", "varchar(255) NOT NULL")
			:create("capped_steamid", "varchar(255) NOT NULL")
			:create("capped_timestamp", "INTEGER NOT NULL")
			:create("capper_name", "varchar(255) NOT NULL")
			:create("capper_steamid", "varchar(255) NOT NULL")
			:primaryKey("id")
		:execute()

		self:create("warnings")
			:create("id", "INTEGER NOT NULL AUTO_INCREMENT")
			:create("name", "varchar(255) NOT NULL")
			:create("steamid", "varchar(255) NOT NULL")
			:create("warnings", "INTEGER NOT NULL")
			:create("warningsData", "TEXT NOT NULL")
			:primaryKey("id")
		:execute()

		self:create("servers")
			:create("id", "INTEGER NOT NULL AUTO_INCREMENT")
			:create("ip", "varchar(255) NOT NULL")
			:create("port", "double NOT NULL")
			:create("name", "varchar(50) NOT NULL")
			:primaryKey("id")
		:execute()

		self:create("reports")
			:create("id", "INTEGER NOT NULL AUTO_INCREMENT")
			:create("server", "varchar(255) NOT NULL")
			:create("creator_steamid", "varchar(255) NOT NULL")
			:create("target_steamid", "varchar(255) NOT NULL")
			:create("creator_nick", "varchar(255) NOT NULL")
			:create("target_nick", "varchar(255) NOT NULL")
			:create("state", "INTEGER NOT NULL")
			:create("handler_steamid", "varchar(255)")
			:create("handler_nick", "varchar(255)")
			:create("reason", "varchar(400) NOT NULL")
			:primaryKey("id")
		:execute()

		self:create("suggestions")
			:create("id", "INTEGER NOT NULL AUTO_INCREMENT")
			:create("server", "varchar(255) NOT NULL")
			:create("creator_steamid", "varchar(255) NOT NULL")
			:create("creator_nick", "varchar(255) NOT NULL")
			:create("suggestion", "varchar(400) NOT NULL")
			:create("state", "INTEGER NOT NULL")
			:create("handler_steamid", "varchar(255)")
			:create("handler_nick", "varchar(255)")
			:primaryKey("id")
		:execute()

		am.pullGroupInfo()		

		self:select("servers"):callback(function(res)
			for k,v in pairs(res) do
				am.print("Found server " .. v["name"])
				ndoc.table.am.servers[v["name"]] = {v["ip"], v["port"]}
			end
		end):execute()

		local sits = file.Read("adminme_sit_positions_".. game.GetMap() .. ".txt", "DATA")
		if (sits) then
			am.sits = util.JSONToTable(sits)
		end
	end

	function am.db:onConnectionFailed(error)
		print(error)

		am.db:connect()
	end

	function am.db:onError(query)
		if (query:status() == mysqloo.DATABASE_NOT_CONNECTED) then
			adminme.db:connect()
		end
	end

	am.db:connect()
	
end
initDB()

hook.Add("PlayerInitialSpawn", "am.LoadStuff", function(ply)
	am.pullUserInfo(ply)
	am.pullWarningInfo(ply)

	am.logs[ ply:SteamID() ] = am.logs[ ply:SteamID() ] or {}

	ply._joinTime = CurTime()

	if (am.config.join_leave_notifications) then
		am.notify(nil, "Player ", am.green, ply:Nick(), am.def, " ("..ply:SteamID()..") has joined!")
	end
end)


hook.Add("PlayerAuthed", "am.CheckBans", function(ply)
	local steamid = ply:SteamID()
	local ip = ply:IPAddress()

	am.checkBan(steamid, ip, ply)

	http.Fetch(
		string.format("http://api.steampowered.com/IPlayerService/IsPlayingSharedGame/v0001/?key=%s&format=json&steamid=%s&appid_playing=4000",
			am.config.api_key,
			util.SteamIDTo64(steamid)),

		function(body)
			local body = util.JSONToTable(body)

			local lender = body.response.lender_steamid
			if lender ~= "0" then

				// is our lender banned? if so, ban this account and kick them!
				am.checkBan(util.SteamIDFrom64(lender), ip, ply, true)
			end
		end,

		function(code)
			error(string.format("FamilySharing: Failed API call for %s | %s (Error: %s)\n", ply:Nick(), ply:SteamID(), code))
		end)

end)

hook.Add("PlayerDisconnected", "am.SaveTimes", function(ply)
	local timeToAdd = CurTime() - ply._joinTime

	if (ply.rank_expires_on && #ply.rank_expires_on > 0) then
		timer.Destroy("rank_expire_check_"..ply:SteamID())
	end

	local sid = ply:SteamID()
	local nick = ply:Nick()

	local query = am.db:select("play_times")
		query:where("steamid", sid)
		query:callback(function(res)
			if (#res == 1) then
				print("Updating...")
				am.db:query("UPDATE `play_times` SET `play_time_seconds` = `play_time_seconds` + "..timeToAdd..", `last_join` = "..os.time().." WHERE `steamid` = '"..sid.."'")
			else
				am.db:query("INSERT INTO `play_times` (`steamid`, `nick`, `last_join`, `play_time_seconds`) VALUES ('"..sid.."', '"..nick.."', "..os.time()..","..timeToAdd..")")
			end
		end)
	query:execute()

	if (am.config.joinLeaveMessages) then
		am.notify(nil, "Player ", am.green, ply:Nick(), am.def, " ("..ply:SteamID()..") has left!")
	end
	
	ndoc.table.am.users[ ply:SteamID() ] = nil
	ndoc.table.am.warnings[ ply:SteamID() ] = nil
end)

hook.Add("PlayerSay", "am.checkCommandCall", function(ply, text)
	local firstSpace = string.find(text, "%s")
	local prefix = string.sub(text, 1, 1)
	local cmd = string.lower(string.sub(text, 2, firstSpace and firstSpace - 1 or nil))

	if (table.HasValue(am.config.cmd_prefixes, prefix) and am.cmds[cmd]) then
		cmd = am.cmds[cmd]

		local args 
		if (firstSpace) then
			args = am.parseLine(string.sub(text, firstSpace))
		else
			args = {}
		end

		if (cmd and cmd.canUse) then
			am.runCommand(ply, cmd, args)
			return ""
		end
	end
end)

if (am.config.use_admin_hud) then
	hook.Add("PlayerDeath", "am.printInfoToAdminHud", function(vic, inf, att)
		if (!vic:IsPlayer()) then return end
		
		local lString = vic:Nick() .. " was killed by " .. att:Nick()
		local lType = 1

		net.Start("am.hud_log")
			net.WriteString(lString)
			net.WriteInt(lType, 32)

		for k,v in pairs(player.GetAll()) do
			if (!v:hasPerm("hudlog")) then continue end
			
			net.Send(v)
		end		
	end)

	hook.Add("SendToAdminHud", "am.customPrint", function(string, type)
		net.Start("am.hud_log")
			net.WriteString(string)
			net.WriteInt(type, 32)

		for k,v in pairs(player.GetAll()) do
			if (!v:hasPerm("hudlog")) then continue end
			
			net.Send(v)
		end
	end)

	hook.Add("PlayerDisconnected", "LogDisconnect", function(ply)
		hook.Call("SendToAdminHud", GAMEMODE, ply:Nick() .. "(" .. ply:SteamID() .. ") has left!", 3)
	end)
end

hook.Add("PlayerDeath", "am.PlayerEventsLogging", function(vic, inf, att)
	if (!vic:IsPlayer()) then return end
	
	am.addPlayerEvent(vic, vic:Nick() .. " was killed by " .. att:Nick() .. " with " .. inf:GetClass())
	
	if (att:IsPlayer()) then
		am.addPlayerEvent(att, att:Nick() .. " killed " .. vic:Nick() .. " with " .. inf:GetClass())
	end
end)