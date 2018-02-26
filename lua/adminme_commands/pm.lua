am.addCMD("pm", "Sends a message to a player", 'Chat', function(ply, target, msg)
	am.notify(ply, am.green, "[PM To ", target:Nick(), "]: ", am.def, msg)
	am.notify(target, am.green, "[PM From ", ply:Nick(), "]: ", am.def, msg)

	ply.reply_to = target
	target.reply_to = ply

end):addParam("receiver", "player"):addParam("message", "string")

am.addCMD("reply", "Send a pm back to your latest PM conversation", 'Chat', function(ply, msg)
	if (not IsValid(ply.reply_to)) then return end

	am.notify(ply, am.green, "[PM To ", ply.reply_to:Nick(), "]: ", am.def, msg)
	am.notify(ply.reply_to, am.green, "[PM From ", ply:Nick(), "]: ", am.def, msg)
end):addParam("message", "string")