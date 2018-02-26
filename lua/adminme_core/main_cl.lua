
include("vgui/dscrollpanel2.lua")
include("vgui/am_textentry.lua")
include("vgui/am_headerpanel.lua")

local aHUD
local notifications = {}
net.Receive("am.hudLog", function()
	if (not IsValid(aHUD)) then
		aHUD = vgui.Create("DScrollPanel2")	-- it's ugly how garry made the scroll bar on the right. this one is on the left
		aHUD:SetSize(600, 100)
		aHUD:SetPos(5, 5)
	end

	if (not LocalPlayer():inAdminMode()) then
		aHUD:SetVisible(false)
	else
		aHUD:SetVisible(true)
	end

	if (#notifications == 40) then
		table.remove(notifications, 1)
	end
	local str = net.ReadString()
	local type = net.ReadInt(32)

	table.insert(notifications, {os.date("%I:%M %p", os.time()), str, type})

	aHUD:Clear()
	local notifications = table.Reverse(notifications)

	for k,v in pairs(notifications) do
		local l = vgui.Create("DLabel")
		l:SetParent(aHUD)
		l:SetPos(10, 20 * k)
		l:SetText("       " .. v[1] .. " | " .. v[2])
		l:SetColor(Color(255, 255, 255))
		l:SizeToContents()

		function l:DoRightClick()
			local menu = DermaMenu()
			menu:SetPos(gui.MousePos())
			menu:AddOption("Copy Line", function() SetClipboardText(v[1] .. " | " ..v[2]) end)
		end
	end
end)

--CapsAdmin
function Wrap( string, width )
	 local tbl = string.Explode( " ", string )
	local str = { "" }
	local pos = 1

	for k,v in pairs( tbl ) do

		local test = str[pos] .. " " .. v
		local size = surface.GetTextSize( test )

		if size > width - 40 then

			str[pos] = string.Trim( str[pos] )
			pos = pos + 1
			str[pos] = ( str[pos] or "" ) .. v

		else

			str[pos] = str[pos] .. " " .. v

		end

	end

	return str
end



local distance_between = 20
local rect_width = 12
local DisabledColor = Color(100, 100, 100)
function doDisabled(panel, w, h)
	local rect_height = h * 3
	local num_rects = math.ceil(w / (rect_width + distance_between))

	draw.NoTexture()
	surface.SetDrawColor(DisabledColor)

	for i = 0, num_rects do
		surface.DrawTexturedRectRotated(i * (rect_width + distance_between), h / 2, rect_width, rect_height, 45)
	end

end

surface.CreateFont("adminme_head", {
		font = "Open Sans",
		size = 36,
	})

surface.CreateFont("adminme_btn", {
		font = "Open Sans",
		size = 30,
	})

surface.CreateFont("adminme_header", {
			font = "Open Sans",
			size = 25,
		})

surface.CreateFont("adminme_ctrl", {
			font = "Open Sans",
			size = 20,
		})


surface.CreateFont("adminme_btn_small", {
		font = "Open Sans",
		size = 20,
	})

net.Receive("am.notify", function()
	local tbl = net.ReadTable()
	chat.AddText(Color(0, 0, 0), "{AdminMe}: ", Color(255, 255, 255), unpack(tbl))
end)

function clientNotify(...)
	local tbl = {...}
	chat.AddText(Color(0, 0, 0), "{AdminMe}: ", Color(255, 255, 255), unpack(tbl))
end

cols = {
	header = Color(240, 240, 240),
	header_text = Color(60, 60, 60),
	header_underline = Color(200, 200, 200),
	header_btn_hover = Color(230, 230, 230),
	header_btn_active = Color(220, 220, 220),

	item_btn_text = Color(255, 255, 255),
	item_btn_bg = Color(255, 255, 255),
	item_btn_bg_hover = Color(245, 245, 245),
	item_btn_bg_active = Color(52, 152, 219),
	item_btn_text_active = Color(255, 255, 255),

	ctrl_text = Color(0, 0, 0),
	ctrl_text_entry = Color(240, 240, 240),
	ctrl_text_highlight = Color(52, 152, 219),
	ctrl_text_disabled = Color(248, 248, 248),

	ctrl_entry = Color(0, 0, 0),
	ctrl_entry_entry = Color(240, 240, 240),
	ctrl_entry_highlight = Color(52, 152, 219),
	ctrl_entry_disabled = Color(248, 248, 248),

	head_panel_outline = Color(52, 152, 219),
	head_panel_head_bg = Color(52, 152, 219),
	head_panel_text = Color(255, 255, 255),
	head_panel_bg = Color(255, 255, 255),

	main_btn_bg = Color(255, 255, 255),
	main_btn_hover = Color(248, 248, 248),
	main_btn_outline = Color(240, 240, 240),
	main_btn_disabled = Color(245, 245, 245),


	close_btn = Color(40, 39, 41),
	close_btn_hover = Color(30, 29, 31),
	main_bg = Color(255, 255, 255),
	main_btn = Color(240, 240, 240),
	main_btn_hover = Color(220, 220, 220),
	main_btn_text = Color(0, 0, 0),
	sub_btn = Color(220, 220, 220),
	sub_btn_dark = Color(190, 190, 190),
	sub_btn_hover = Color(200, 200, 200),
	section_bg = Color(230, 230, 230),
}

local frame
local function createMenu()
	if (IsValid(frame)) then return end

	frame = vgui.Create("DFrame")
	frame:SetSize(ScrW() * 5/6 , ScrH() * 5/6)
	frame:ShowCloseButton(false)
	frame:Center()
	frame:SetTitle("")
	frame:SetVisible(true)
	frame:MakePopup()

	function frame:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, cols.main_bg)
	end

	local header = vgui.Create("DPanel", frame)
	header:SetSize(frame:GetWide(), 60)
	function header:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, cols.header)
		draw.RoundedBox(0, 0, h - 1, w, 1, cols.header_underline)

		draw.SimpleText("AdminMe", "adminme_head", 15, h / 2, cols.header_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local fW, fH = frame:GetWide(), frame:GetTall()

	local hOffset = header:GetTall() / 2 - 15
	local close = vgui.Create("DButton", header)
	close:SetPos(fW - 30 - hOffset, hOffset)
	close:SetSize(30, 30)
	close:SetText("")
	function close:Paint(w, h)
		local col = cols.header

		if (self:IsHovered()) then
			col = cols.main_btn_hover
		end

		draw.RoundedBox(4, 0, 0, 30, 30, col)
		draw.SimpleText("x", "adminme_head", w / 2, h / 2 - 2, cols.header_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	function close:DoClick()
		frame:Close()
	end

	local listOfSections = {}
	hook.Call("AddAdditionalMenuSections", GAMEMODE, listOfSections)

	local offset_x = 150
	local activeSection = nil

	local itemScroller = vgui.Create("DScrollPanel", frame)
	itemScroller:SetSize(180, fH - header:GetTall())
	itemScroller:SetPos(0, header:GetTall())

	local scB = itemScroller:GetVBar()
	function scB:Paint( w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255))
	end
	function scB.btnUp:Paint( w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255))
	end
	function scB.btnDown:Paint( w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255))
	end
	function scB.btnGrip:Paint( w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255))
	end

	local itemList = vgui.Create("DIconLayout", itemScroller)
	itemList:SetPos(10, 0)
	itemList:SetSize(itemScroller:GetWide() - 10, itemScroller:GetTall())
	itemList:SetSpaceY(10)
	itemList:SetSpaceX(0)


	local mainSection = vgui.Create("DPanel", frame)
	mainSection:SetSize(fW - itemList:GetWide(), fH - header:GetTall())
	mainSection:SetPos(itemList:GetWide(), header:GetTall())
	function mainSection:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255))
	end

	for k,v in pairs(listOfSections) do
		surface.SetFont("adminme_btn")
		local w, h = surface.GetTextSize(k)

		local sectionBtn = vgui.Create("DButton", header)
		sectionBtn:SetSize(w + 20, header:GetTall() - 1)
		sectionBtn:SetPos(offset_x, 0)
		sectionBtn:SetText("")
		function sectionBtn:Paint(w, h)
			local col = cols.header

			if (self:IsHovered()) then
				col = cols.header_btn_hover
			end

			if (activeSection == k) then
				col = cols.header_btn_active
			end

			draw.RoundedBox(0, 0, 0, w, h, col)
			draw.SimpleText(k, "adminme_header", w / 2, h / 2, cols.header_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		function sectionBtn:DoClick()
			itemList:Clear()

			if (frame.extras and #frame.extras > 0) then
				for k,v in pairs(frame.extras) do
					v:Remove()
				end
			end
			
			v(itemList, mainSection, frame)

			activeSection = k
		end

		offset_x = offset_x + sectionBtn:GetWide()
	end
end
concommand.Add("menu", createMenu)


--Motd stuff
net.Receive("am.motd", function()
	local panel = vgui.Create("DFrame")
	panel:SetWide(ScrW() * 2 / 3)
	panel:SetTall(ScrH() * 2 / 3)
	panel:ShowCloseButton(false)
	panel:MakePopup()
	panel:Center()

	local content = vgui.Create("HTML", panel)
	content:SetSize(panel:GetWide() - 10, panel:GetTall() - 65)
	content:SetPos(5, 5)
	content:OpenURL("http://projectaxiom.org/forums/index.php?topic=2.0")

	local close = vgui.Create("DButton", panel)
	close:SetSize(100, 50)
	close:SetPos(panel:GetWide() / 2 - close:GetWide() / 2, panel:GetTall() - close:GetTall() - 5)
	close:SetText("Close")
	function close:DoClick()
		panel:Remove()
	end
end)
