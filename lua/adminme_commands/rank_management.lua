util.AddNetworkString("am.updateRankMenu")

am.addCMD("addrank", "Create a rank", "Rank Mgmt", function(caller, name, hierarchy, permissionSet)

    // Update rank and refresh 
    am.db:insert("ranks")
        :insert("rank", name)
        :insert("hierarchy", hierarchy)
        :insert("perms", util.TableToJSON(permissionSet))
        :callback(function(res)
            am.pullGroupInfo()

            net.Start("am.updateRankMenu")
            net.Send(caller)
             
            am.notify(am.getAdmins(), am.green, caller:Nick(), am.def, " has added the rank ", am.green, name)
        end)
    :execute()

end):addParam({
	name = "name",
	type = "string"
}):addParam({
	name = "hierarchy",
	type = "number",
	optional = true,
    default = 0,
    defaultUI = 0
}):addParam({
	name = "permissions",
	type = "permissions",
	optional = true,
    default = { "*" },
    defaultUI = "*"
}):setPerm("rankmgmt"):disableUI()

am.addCMD("modifyrank", "Modify an existing rank", "Rank Mgmt", function(caller, rank, newName, newHierarchy, newPermissionSet)
    // Verification done internally to ensure the rank exists
    ndoc.table.am.permissions[rank.id] = {
        name = newName,
        hierarchy = newHierarchy,
        perm = newPermissionSet 
    }

    net.Start("am.updateRankMenu")
    net.Send(caller)

    // Update it in the database
    am.db:update("ranks")
        :update("rank", newName)
        :update("hierarchy", newHierarchy)
        :update("perms", util.TableToJSON(newPermissionSet))
        :where("id", rank.id)
    :execute()

    am.notify(am.getAdmins(), am.green, caller:Nick(), am.def, " has updated the rank ", am.green, newName)

end):addParam({
	name = "rank",
	type = "rank"
}):addParam({
    name = "new name",
    type = "string"
}):addParam({
	name = "hierarchy",
	type = "number",
	optional = true,
    default = 0,
    defaultUI = 0
}):addParam({
	name = "permissions",
	type = "permissions",
	optional = true,
    default = { "*" },
    defaultUI = "*"
}):setPerm("rankmgmt"):disableUI()

am.addCMD("removerank", "Create a rank", "Rank Mgmt", function(caller, rank)
    if (rank.info.name == am.config.default_rank) then
		am.notify(caller, "Invalid value for rank")
		return
	end

    am.db:delete("ranks"):where("id", rank.id):callback(function()
        am.notify(am.getAdmins(), am.green, caller:Nick(), am.def, " has deleted the rank ", am.green, rank.info.name)

        ndoc.table.am.permissions[rank.id] = nil

        net.Start("am.updateRankMenu")
        net.Send(caller)
    end):execute()

end):addParam({
	name = "rank",
	type = "rank"
}):setPerm("rankmgmt"):disableUI()