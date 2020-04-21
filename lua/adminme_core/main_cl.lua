
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
		font = "Roboto",
		size = 36,
	})

surface.CreateFont("adminme_btn", {
		font = "Roboto",
		size = 30,
	})

surface.CreateFont("adminme_section_btn", {
			font = "Roboto",
			size = 20,
		})

surface.CreateFont("adminme_ctrl", {
			font = "Roboto",
			size = 20,
		})


surface.CreateFont("adminme_btn_small", {
		font = "Roboto",
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
	header = Color(255, 255, 255),
	header_text = Color(107, 110, 116),
	header_text_active = Color(255, 255, 255),
	header_underline = Color(200, 200, 200),
	header_btn_hover = Color(200, 200, 200, 51),
	header_btn_active = Color(107, 110, 116),

	item_scroll_bg = Color(107, 110, 116),

	item_btn_text = Color(255, 255, 255),
	item_btn_text_hover = Color(0, 0, 0),
	item_btn_bg = Color(107, 110, 116),
	item_btn_bg_hover = Color(240, 240, 240, 255),
	item_btn_bg_active = Color(210, 220, 222),
	item_btn_text_active = Color(0, 0, 0),

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
	main_bg = Color(210, 220, 222),
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
	
	surface.SetFont('adminme_head')
	local amW, amH = surface.GetTextSize("AdminMe") 

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

	local sidebar = vgui.Create("DPanel", frame)
	sidebar:SetSize(200, frame:GetTall())
	function sidebar:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, cols.header)
		draw.RoundedBox(0, w - 1, 0, 1, h, cols.header_underline)

		draw.SimpleText("AdminMe", "adminme_head", w / 2, 30, cols.header_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.RoundedBox(0, w / 2 - amW / 2 - 5, amH + 30, amW + 10, 1, cols.header_underline)
	end

	// Total height + underline
	local headerHeight = amH + 60

	surface.SetFont('adminme_section_btn')
	local sectionTextW, sectionTextH = surface.GetTextSize("Close") 

	local fW, fH = frame:GetWide(), frame:GetTall()

	local close = vgui.Create("DButton", sidebar)
	close:SetSize(sidebar:GetWide() - 20, sectionTextH + 20)
	close:SetPos(10, fH - close:GetTall() - 10)
	close:SetText("")
	function close:Paint(w, h)
		local col = cols.header

		if (self:IsHovered()) then
			col = cols.header_btn_hover
		end

		draw.RoundedBox(0, 0, 0, w, h, col)
		draw.SimpleText("Close", "adminme_section_btn", w / 2, h / 2, cols.header_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	function close:DoClick()
		frame:Close()
	end

	local listOfSections = {}
	hook.Call("AddAdditionalMenuSections", GAMEMODE, listOfSections)

	local offset_y = 150
	local activeSection = nil

	local itemScroller = vgui.Create("DScrollPanel", frame)
	itemScroller:SetSize(sidebar:GetWide(), fH)
	itemScroller:SetPos(sidebar:GetWide(), 0)
	itemScroller:SetVisible(false)
	function itemScroller:Paint(w, h) 
		draw.RoundedBox( 0, 0, 0, w, h, cols.item_scroll_bg)
	end

	local scB = itemScroller:GetVBar()
	scB:SetSize(0, 0)
	function scB:Paint( w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255, 0))
	end
	function scB.btnUp:Paint( w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255, 0))
	end
	function scB.btnDown:Paint( w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255, 0))
	end
	function scB.btnGrip:Paint( w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255, 0))
	end

	local itemList = vgui.Create("DIconLayout", itemScroller)
	itemList:SetPos(0, 0)
	itemList:SetSize(itemScroller:GetWide(), itemScroller:GetTall())
	itemList:SetSpaceY(10)
	itemList:SetSpaceX(0)

	local mainSection = vgui.Create("DPanel", frame)
	mainSection:SetSize(0, 0)
	function mainSection:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, cols.main_bg)
	end

	for k,v in pairs(listOfSections) do
		local sectionBtn = vgui.Create("DButton", sidebar)
		sectionBtn:SetSize(sidebar:GetWide(), sectionTextH + 20)
		sectionBtn:SetPos(sidebar:GetWide() / 2 - sectionBtn:GetWide() / 2, offset_y)
		sectionBtn:SetText("")
		function sectionBtn:Paint(w, h)
			local col = cols.header
			local textCol = cols.header_text

			if (self:IsHovered()) then
				col = cols.header_btn_hover
			end

			if (activeSection == k) then
				col = cols.header_btn_active
				textCol = cols.header_text_active
			end

			local additionalWidth = 0
			if (v.useItemList) then
				additionalWidth = activeSection == k and 10 or 0
			end
			draw.RoundedBox(0, 10, 0, w - 20 + additionalWidth, h, col)
			draw.SimpleText(k, "adminme_section_btn", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		function sectionBtn:DoClick()
			itemList:Clear()

			mainSection:Clear()
			if (frame.extras and #frame.extras > 0) then
				for k,v in pairs(frame.extras) do
					v:Remove()
				end
			end

			local adjustedMainWidth = fW - itemScroller:GetWide() - sidebar:GetWide()
			local adjustedMainOffset = sidebar:GetWide() + itemScroller:GetWide()
			
			if (!v.useItemList) then
				itemScroller:SetVisible(false)
				adjustedMainWidth = fW - sidebar:GetWide()
				adjustedMainOffset = sidebar:GetWide()
			else
				itemScroller:SetVisible(true)
			end

			mainSection:SetSize(adjustedMainWidth, fH)
			mainSection:SetPos(adjustedMainOffset, 0)

			v.cback(itemList, mainSection, frame)

			activeSection = k
		end

		offset_y = offset_y + sectionBtn:GetTall() + 10
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
