am.addCMD("refresh", 'Forces the system to refresh all groups and permissions', 'Misc', function(caller, target)
	am.pullGroupInfo()

	for k,v in pairs(player.GetAll()) do
		am.pullUserInfo(v)
	end
end):setPerm("refresh")