local function rankHasPerm(id, perm)
    if (!id) then
        return false
    end

    for k,v in ndoc.pairs(ndoc.table.am.permissions[id].perm) do
        if (v == perm) then
            return true
        end
    end

    return false
end

local activeAction
local function populateMain(main, id)
    main:Clear()
    surface.SetFont("adminme_btn_small")
    local tW, tH = surface.GetTextSize("X")

    // Panel to hold all the settings
    local editingRank = id && ndoc.table.am.permissions[id] 
    
    local settingsPanel = vgui.Create("am.HeaderPanel", main)
    settingsPanel:SetSize(main:GetWide() - 20, main:GetTall() - 20)
    settingsPanel:SetPos(10, 10)
    settingsPanel:SetHHeight(80)
    settingsPanel:SetHText((editingRank && "Editing " .. editingRank.name || "New Rank") .. (id == 0 && " - Default Rank" || ""))

    // What can you do here
    local helpLabel = vgui.Create("DLabel", settingsPanel)
    helpLabel:SetFont("adminme_btn_small")
    helpLabel:SetTextColor(cols.header_text)
    helpLabel:SetText("Edit the name, hierarchy and permissions for this rank below")
    helpLabel:SetSize(settingsPanel:GetWide() - 20, 35)
    helpLabel:SetPos(10, 50)

    // New command name
    local nameLabel = vgui.Create("DLabel", settingsPanel)
    nameLabel:SetFont("adminme_btn_small")
    nameLabel:SetTextColor(cols.header_text)
    nameLabel:SetPos(10, 95)
    nameLabel:SetSize(100, 35)
    nameLabel:SetText("Name")
    
    local editName = vgui.Create("am.DTextEntry", settingsPanel)
    editName:SetFont("adminme_btn_small")
    editName:SetPos(110, 95)
    editName:SetSize(150, 35)
    editName:SetText(editingRank && editingRank.name || "")

    // New command hierarchy
    local hierLabel = vgui.Create("DLabel", settingsPanel)
    hierLabel:SetFont("adminme_btn_small")
    hierLabel:SetTextColor(cols.header_text)
    hierLabel:SetText("Hierarchy")
    hierLabel:SetSize(100, 35)
    hierLabel:SetPos(10, 140)

    local hierName = vgui.Create("am.DTextEntry", settingsPanel)
    hierName:SetFont("adminme_btn_small")
    hierName:SetPos(110, 140)
    hierName:SetSize(150, 35)
    hierName:SetText(editingRank && editingRank.hierarchy || "")
    hierName:SetNumeric(true)

    // Container for all the permissions
    local checkboxContainer = vgui.Create("DIconLayout", settingsPanel)
    checkboxContainer:SetSize(920, 500)
	checkboxContainer:SetPos(350, 95)
    checkboxContainer:SetSpaceX(10)
	checkboxContainer:SetSpaceY(5)
	checkboxContainer:SetLayoutDir(LEFT)

    // Add global perms if we have them
    local permValues = {}
    local hasAll = rankHasPerm(id, "*")
    if (hasAll) then
        permValues = {"*"}
    end

    // Checkbox for global
    local check = checkboxContainer:Add("DCheckBoxLabel")
    check:SetSize(300, 20)
    check:SetText("*")
    check:SetFont("adminme_btn_small")
    check:SetTextColor(cols.header_text)
    check:SetValue(hasAll)
    function check:OnChange(val) 
        if (!val) then
            table.RemoveByValue(permValues, "*")
        else
            table.insert(permValues, "*")    
        end
    end

    // Begin adding all the other checkboxes
    local restrictCount = 0
    for k,info in ndoc.pairs(ndoc.table.am.commands) do
        if (!info.restrictedTo) then
            continue
        end

        restrictCount = restrictCount + 1

        local check = checkboxContainer:Add("DCheckBoxLabel")
        check:SetSize(300, 20)
        check:SetText(info.restrictedTo)
        check:SetFont("adminme_btn_small")
        check:SetTextColor(cols.header_text)
        check:SetValue(rankHasPerm(id, info.restrictedTo))
        function check:OnChange(val) 
            if (!val) then
                table.RemoveByValue(permValues, info.restrictedTo)
            else
                table.insert(permValues, info.restrictedTo)    
            end
        end
    end 

    // Update the rank
    local update = vgui.Create("DButton", settingsPanel)
	update:SetSize(150, 35)
    update:SetPos(10, 560)
	update:SetText("")
	function update:Paint(w, h)
		local col = cols.main_btn_bg
		local textCol = Color(0, 0, 0)

		// Hovered
		if (self:IsHovered()) then
			col = cols.main_btn_hover
		end

		// Disabled
		if (self:GetDisabled()) then
			col = cols.main_btn_disabled
		end

		// Paint the button - make it pretty!
		draw.RoundedBox(0, 0, 0, w, h, cols.main_btn_outline)
		draw.RoundedBox(0, 1, 1, w - 2, h - 2, col)
		draw.SimpleText(id && "Update Rank" || "Add Rank", "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
    function update:DoClick()
        PrintTable(permValues)
        local permString = table.concat(permValues, ",")

        if (id) then
            RunConsoleCommand("am_modifyrank", id, editName:GetText(), hierName:GetText(), permString)
        else
            RunConsoleCommand("am_addrank", editName:GetText(), hierName:GetText(), permString)
        end
    end

    // Update the rank
    local delete = vgui.Create("DButton", settingsPanel)
	delete:SetSize(150, 35)
    delete:SetPos(170, 560)
	delete:SetText("")
    if (!id || id == 0) then
        // Disable for new rank and default rank
        delete:SetDisabled(true)
    end
	function delete:Paint(w, h)
		local col = cols.main_btn_bg
		local textCol = Color(0, 0, 0)

		// Hovered
		if (self:IsHovered()) then
			col = cols.main_btn_hover
		end

		// Disabled
		if (self:GetDisabled()) then
			col = cols.main_btn_disabled
		end

		// Paint the button - make it pretty!
		draw.RoundedBox(0, 0, 0, w, h, cols.main_btn_outline)
		draw.RoundedBox(0, 1, 1, w - 2, h - 2, col)
		draw.SimpleText("Delete Rank", "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
    function delete:DoClick()
        local permString = table.concat(permValues, ",")

        RunConsoleCommand("am_removerank", id)
    end
end

local function repopulateList(scroller, main)
    scroller:Clear()
    
    // Spacer for the search control
    local spacer = vgui.Create("DPanel", scroller)
    spacer:SetSize(scroller:GetWide(), 55)
    function spacer:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 0))
    end

    for id,info in ndoc.pairs(ndoc.table.am.permissions) do
        PrintTable(info)
        surface.SetFont("adminme_btn_small")
        local tW, tH = surface.GetTextSize(info.name)

        // Create the button for the player
        local btn = scroller:Add("DButton")
        btn:SetText("")
        btn:SetSize(scroller:GetWide(), tH + 20)
        function btn:DoClick()
            activeAction = id
            populateMain(main, id)
        end
        function btn:Paint(w, h)
            local col = cols.item_btn_bg
            local textCol = cols.item_btn_text

            // Hovered
            if (self:IsHovered()) then
                col = cols.item_btn_bg_hover
                textCol = cols.item_btn_text_hover
            end	

            // Active
            local adjustedWidth = w - 20
            if (activeAction == id) then
                col = cols.item_btn_bg_active
                textCol = cols.item_btn_text_active
                adjustedWidth = w - 10
            end

            draw.RoundedBox(0, 10, 0, adjustedWidth, h, col)
            draw.SimpleText(info.name, "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

local theScroller, mainPnl
net.Receive("am.updateRankMenu", function()
    if (!IsValid(mainPnl)) then
        return
    end
    
    timer.Simple(.5, function()
        activeAction = nil
        
        theScroller:Clear()
        mainPnl:Clear()
        repopulateList(theScroller, mainPnl)
    end)    
end)

local function populateList(scroller, main, frame)
    theScroller = scroller
    mainPnl = main

    activeAction = nil

    // Place a background holder for the new rank button
    local posX = frame:GetWide() - main:GetWide() - scroller:GetWide()
    local actionBG = vgui.Create("DPanel", frame)
    actionBG:SetSize(scroller:GetWide(), 55)
    actionBG:SetPos(posX, 0)
    function actionBG:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, cols.item_scroll_bg)
    end

    // New rank 
    local newRank = vgui.Create("DButton", actionBG)
    newRank:SetText("")
    newRank:SetSize(actionBG:GetWide(), 35)
    newRank:SetPos(0, 10)
    function newRank:DoClick()
        activeAction = "create"
        populateMain(main)
    end
    function newRank:Paint(w, h)
        local col = cols.item_btn_bg
        local textCol = cols.item_btn_text

        // Hovered button
        if (self:IsHovered()) then
            col = cols.item_btn_bg_hover
            textCol = cols.item_btn_text_hover
        end

        // Active button
        local adjustedWidth = w - 20
        if (activeAction == "create") then
            col = cols.item_btn_bg_active
            textCol = cols.item_btn_text_active
            adjustedWidth = w - 10
        end

        draw.RoundedBox(0, 10, 0, adjustedWidth, h, col)
        draw.SimpleText("New Rank", "adminme_btn_small", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    frame.extras = { actionBG}
    repopulateList(scroller, main)
end

hook.Add("AddAdditionalMenuSections", "am.addRankManagementMenu", function(stor)
	if (LocalPlayer():hasPerm("rankmgmt")) then
		stor["Ranks"] = {cback = populateList, useItemList = true}
	end
end)