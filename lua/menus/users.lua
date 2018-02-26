/*local activePlayer
local function showUsers(main, ply)
	local backPnl = vgui.Create("DPanel", main)
	backPnl:SetSize(main:GetWide() - 10, main:GetTall() - 10)
	backPnl:SetPos(5, 5)
	function backPnl:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, cols.main_bg)
	end

	local 
end

hook.Add("AddAdditionalMenuSections", "am.addUsersMenu", function(stor)
	local function populateList(scroller, main)
		main:Clear()

		local ourHeir = LocalPlayer():getHeirarchy()
		for k,v in pairs(player.GetAll()) do
			if (ourHeir < v:getHeirarchy()) then
				continue
			end

			local btn = scroller:Add("DButton")
			btn:SetText("")
			btn:SetSize(scroller:GetWide(), 20)
			function btn:DoClick()
				activePlayer = v
				showUsers(main, v)
			end
			function btn:Paint(w, h)
				local col = cols.main_btn

				if (self:IsHovered() or activePlayer == v) then
					col = cols.main_btn_hover
				end

				draw.RoundedBox(0, 0, 0, w, h, col)
				draw.SimpleText(v:Nick(), "adminme_btn_small", w / 2, h / 2, cols.main_btn_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
	end
	if (LocalPlayer():hasPerm("user")) then
		//stor["Users"] = populateList
	end
end)*/