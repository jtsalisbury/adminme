util.AddNetworkString("am.motd")

am.addCMD("motd", "Opens the motd", 'Misc', function(ply)
	net.Start("am.motd")
	net.Send(ply)
end)

hook.Add("PlayerInitialSpawn", "OpenMotdForPlys", function(ply)
	timer.Simple(5, function() 
		net.Start("am.motd")
		net.Send(ply)
	end)
end)