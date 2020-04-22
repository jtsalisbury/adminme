util.AddNetworkString("am.playSong")
util.AddNetworkString("am.endSong")

am.music = util.JSONToTable(file.Read("am_music.txt", "DATA") or "[]")
ndoc.table.am.music = am.music

// TODO: music

if (am.config.ttt_round_end_music) then
	util.AddNetworkString("am.startRoundEndEvents")
	util.AddNetworkString("am.endRoundEndEvents")

	hook.Add("TTTEndRound", "DoRoundEndEvents", function()
		local data = table.Random(am.music) or {}

		if (table.Count(data) == 0) then
			return
		end

		net.Start("am.startRoundEndEvents")
			net.WriteTable(data)
		net.Broadcast()

		am.notify(nil, "Now playing ", am.green, data[1])
		am.notify(nil, "To disable this for future rounds, type ", am.green, "'am_rem_enabled false'", am.def, " into your console!")
	end)

	hook.Add("TTTPrepareRound", "StopRoundEndEvents", function()
		net.Start("am.endRoundEndEvents")
		net.Broadcast()
	end)
end

am.addCMD("addmusic", 'Adds a YouTube URL to the music playlist. Do not add anything > 1 hour!', 'Music', function(caller, id, startMin, startSec)
	local newURL = "http://www.youtube.com/embed/" .. id .. "?rel=0"

	local apiURL = "https://www.googleapis.com/youtube/v3/videos?id=" .. id .. "&key=" .. am.config.youtube_api_key .. "&part=snippet,contentDetails"

	http.Fetch(apiURL, function(data)
		data = util.JSONToTable(data)

		local name = data["items"][1]["snippet"]["localized"]["title"]
		local length = data["items"][1]["contentDetails"]["duration"]

		local pts = string.Explode("T", length)
		local pts2 = string.Explode("M", pts[2])

		local min = pts2[1]
		local secPts = string.Explode("S", pts2[2])
		local sec = secPts[1]

		table.insert(am.music, {name, newURL, min .. "." .. sec, startMin, startSec})

		ndoc.table.am.music = am.music

		file.Write("am_music.txt", util.TableToJSON(am.music))

		am.notify(caller, am.green, name, am.def, " successfully added!")
	end)

end):addParam('video id', 'string'):addParam('start minute', 'number', 0):addParam('start second', 'number', 0):setPerm("music")

am.addCMD("removesong", "Removes a song based on the ID found in the Music Menu", "Music", function(caller, id)
	table.remove(am.music, id)

	ndoc.table.am.music = am.music

	file.Write("am_music.txt", util.TableToJSON(am.music))

	am.notify(caller, "Removed song!")
end):addParam("playlist id", "number"):setPerm("musicmgmt")


am.addCMD("playsong", "Play a song for yourself based off the ID found on the Music Menu", "Music", function(caller, id)
	net.Start("am.playSong")
		net.WriteInt(id, 16)
	net.Send(caller)

	am.notify(caller, "Now playing ", am.green, ndoc.table.am.music[id][1], am.def, ". Type 'am_endsong' to end this.")
end):addParam("playlist id", "number"):setPerm("musicmgmt")

am.addCMD("playsongall", "Play a song for everyone based off the ID found on the Music Menu", "Music", function(caller, id)
	net.Start("am.playSong")
		net.WriteInt(id, 16)
	net.Broadcast()

	am.notify(nil, "Now playing ", am.green, ndoc.table.am.music[id][1], am.def, ". Type 'am_endsong' to end this. Type 'am_music_enabled false' to never play music.")
end):addParam("playlist id", "number"):setPerm("musicmgmt")

am.addCMD("endsong", "Stop playing a song", "Music", function(caller, id)
	net.Start("am.endSong")
	net.Send(caller)

	am.notify(nil, "Stopped playing!")
end):setPerm("musicmgmt")
