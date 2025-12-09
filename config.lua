local configHelpers = utilitools.configHelpers
configHelpers.setMod(mod)

configHelpers.treeNode("Menu Options", function()
	configHelpers.presets.menuOptions()
	imgui.Separator()
	configHelpers.presets.menuButtons()
	imgui.Separator()
	configHelpers.presets.updateOptions()
	imgui.Separator()
	configHelpers.input("autoUpdate")
end, 2 ^ 5)
configHelpers.treeNode("Advanced", function()
	configHelpers.input("isolateLogs")
	configHelpers.input("unknownPrints")
	imgui.Separator()
    configHelpers.input("modPath")
	imgui.Separator()
	configHelpers.input("reloadHotkey")
	configHelpers.input("relaunchHotkey")
	imgui.Separator()
	configHelpers.input("gitFix")
end)
configHelpers.treeNode("Search", function()
	configHelpers.presets.search()
end)
configHelpers.condTreeNode("Full Mod Description", "documentation", "none", false, function()
	configHelpers.doc("fullDescription")
end)
configHelpers.treeNode("Version Manager", function()
utilitools.try(mod, function()
	if imgui.Button("Relaunch Game") then utilitools.config.save(mod) utilitools.relaunch() end
	if imgui.Button("Reload Mod Files") then utilitools.modUpdater.fileCache = {} end
	configHelpers.doc("autoUpdate")
	configHelpers.input("autoUpdate")
	configHelpers.input("defaultBranch")
	imgui.Separator()
	configHelpers.input("showCompareMod")
	configHelpers.input("showForceMod")
	imgui.Separator()
	local modAmount = 0
	local modsSorted = utilitools.table.keysToValues(mods)
	table.sort(modsSorted)
	for _, modId in ipairs(modsSorted) do
		local mod = mods[modId]
		if utilitools.modLinks[version][modId] then
			if modAmount ~= 0 then imgui.Separator() end
			imgui.Indent()
			imgui.TextWrapped(mod.name .. " (" .. mod.version .. ") by " .. mod.author)
			imgui.Indent()
			if not utilitools.versions.equal(utilitools.modUpdater.getModInfo(mod).version, mod.version) then
				imgui.TextWrapped("Restart to finish mod version update to " .. utilitools.modUpdater.getModInfo(mod).version)
			end
			if not utilitools.versions.equal(utilitools.modUpdater.getModVersion(mod), utilitools.modUpdater.getModInfo(mod).version) or mods.utilitools.config.showForceMod then
				imgui.AlignTextToFramePadding()
				imgui.TextWrapped("Latest version: " .. utilitools.modUpdater.getModVersion(mod))
				imgui.SameLine()
				if utilitools.modUpdater.checkModVersion(mod) then
					if imgui.Button("Update Version##" .. mod.id) then
						utilitools.modUpdater.downloadMod(mod)
					end
				else
					if imgui.Button("Force Update Version Anyways##" .. mod.id) then
						utilitools.prompts.confirm("You will override your mod files with an older version", function() utilitools.modUpdater.downloadMod(mod, nil, false, true) end)
					end
				end
			end
			if mods.utilitools.config.showCompareMod and imgui.Button("Compare Files##" .. mod.id) then
				utilitools.modUpdater.downloadMod(mod, nil, true, true)
			end
			local space = imgui.GetContentRegionAvail().x
			mods.utilitools.config.updates[mod.id] = utilitools.imguiHelpers.inputBool(
				"Updates##" .. modId, mods.utilitools.config.updates[mod.id], true,
				configHelpers.tooltip("updates")
			)
			imgui.SameLine(math.max(0, imgui.GetContentRegionAvail().x - space / 2))
			mods.utilitools.config.branches[mod.id] = utilitools.imguiHelpers.inputBranch(mods[modId], configHelpers.tooltip("branches"))
			imgui.Unindent()
			imgui.Unindent()
			modAmount = modAmount + 1
		end
	end
end)
end)
