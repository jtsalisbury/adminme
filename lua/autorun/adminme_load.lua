am = am or {}

am.green = Color(25, 255, 25)
am.red   = Color(255, 25, 25)
am.def   = Color(255, 255, 255)

am.config = am.config or {}
if (SERVER) then
	resource.AddFile("resource/fonts/Roboto-Regular.ttf")

	util.AddNetworkString("am.hud_log")
	util.AddNetworkString("am.notify")

	am.cmds = am.cmds or {}
	am.argTypes = am.argTypes or {}
	am.logs = am.logs or {}

	AddCSLuaFile("am_config.lua")
	AddCSLuaFile("adminme_core/main_cl.lua")
	AddCSLuaFile("adminme_core/main_sh.lua")

	AddCSLuaFile("vgui/dscrollpanel2.lua")
	AddCSLuaFile("vgui/am_textentry.lua")
	AddCSLuaFile("vgui/am_headerpanel.lua")

	hook.Add("ndocLoaded", "waitForNdoc", function() 
		print("Netdoc loaded!")

		ndoc.table.am = ndoc.table.am or {}
		ndoc.table.am.users = ndoc.table.am.users or {}
		ndoc.table.am.permissions = ndoc.table.am.permissions or {}
		ndoc.table.am.servers = ndoc.table.am.servers or {}
		ndoc.table.am.warnings = ndoc.table.am.warnings or {}
		ndoc.table.am.commands = ndoc.table.am.commands or {}
		ndoc.table.am.events   = ndoc.table.am.events or {}
		ndoc.table.am.play_times = ndoc.table.am.play_times or {}

		ezdb = include("ezdb/load_sv.lua")

		include("am_config.lua")
		include("am_config_sql.lua")
		include("adminme_core/main_sv.lua")
		include("adminme_core/main_sh.lua")
		include("adminme_core/helper_sv.lua")
		
		include("adminme_core/command_handler.lua")

		local files = file.Find("adminme_commands/*.lua", "LUA")
		for k,v in pairs(files) do
			include("adminme_commands/"..v)
		end

		local files = file.Find("menus/*.lua", "LUA")
		for k,v in pairs(files) do
			AddCSLuaFile("menus/" .. v)
		end
	end)
else
	timer.Simple(5, function()
		include("am_config.lua")
		include("adminme_core/main_cl.lua")
		include("adminme_core/main_sh.lua")

		local files = file.Find("menus/*.lua", "LUA")

		for k,v in pairs(files) do
			print("Including menu " .. v)
			include("menus/" .. v)
		end
	end)
end

