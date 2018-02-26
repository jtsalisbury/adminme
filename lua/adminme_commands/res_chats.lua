am.addCMD("a", 'Admin chat', 'Chat', function(caller, text)
	for k,v in pairs(player.GetAll()) do
		if (!v:IsAdmin() and v ~= caller) then continue end

		local c = caller:IsAdmin() and '[Admin Chat] ' or '[TO ADMINS] '

		am.notify(v, am.red, c, team.GetColor(caller:Team()), caller:Nick(),': ', am.def, text)
	end
end):addParam('text', 'string')
