if not utilitools then imgui.Text("Utilitools is disabled") return end
local configHelpers = utilitools.configHelpers
configHelpers.setMod(mod)

configHelpers.treeNode("Menu Options", function()
	configHelpers.presets.menuOptions()
	imgui.Separator()
	configHelpers.presets.menuButtons()
	imgui.Separator()
	configHelpers.input("dontUseInternet")
	configHelpers.input("autoUpdate")
	imgui.Separator()
	configHelpers.presets.updateOptions()
	imgui.Separator()
	configHelpers.input("foldHotkey")
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
--[[ configHelpers.treeNode("Version Manager", function()
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
			if utilitools.modLinks[modId] then
				if modAmount ~= 0 then imgui.Separator() end
				imgui.Indent()
				imgui.TextWrapped(mod.name .. " (" .. mod.version .. ") by " .. mod.author)
				imgui.Indent()
				if not utilitools.versions.equalTo(utilitools.modUpdater.getModInfo(mod).version, mod.version) then
					imgui.TextWrapped("Restart to finish mod version update to " .. utilitools.modUpdater.getModInfo(mod).version)
				end
				utilitools.try(mod, function()
				if not mod.config.dontUseInternet and utilitools.modUpdater.getModVersion(mod) and not utilitools.versions.equalTo(utilitools.modUpdater.getModVersion(mod), utilitools.modUpdater.getModInfo(mod).version) or mods.utilitools.config.showForceMod then
					imgui.AlignTextToFramePadding()
					imgui.TextWrapped("Latest version: " .. tostring(utilitools.modUpdater.getModVersion(mod)))
					imgui.SameLine()
					if not mod.config.dontUseInternet and utilitools.modUpdater.checkModVersion(mod) then
						if imgui.Button("Update Version##" .. mod.id) then
							utilitools.modUpdater.downloadMod(mod)
							utilitools.config.save(mod)
						end
					else
						if imgui.Button("Force Update Version Anyways##" .. mod.id) then
							utilitools.prompts.confirm("You will override your mod files with an older version", function() utilitools.modUpdater.downloadMod(mod, nil, false, true) end)
						end
					end
				end
				end)
				if not mod.config.dontUseInternet and mods.utilitools.config.showCompareMod and imgui.Button("Compare Files##" .. mod.id) then
					utilitools.modUpdater.downloadMod(mod, nil, true, true)
				end
				mods.utilitools.config.branches[mod.id] = utilitools.imguiHelpers.inputBranch(mods[modId], configHelpers.tooltip("branches"))
				imgui.SameLine()
				mods.utilitools.config.updates[mod.id] = utilitools.imguiHelpers.inputBool(
					"Update " .. mod.name .. "##" .. modId, mods.utilitools.config.updates[mod.id], true,
					configHelpers.tooltip("updates")
				)
				imgui.Unindent()
				imgui.Unindent()
				modAmount = modAmount + 1
			end
		end
	end)
end) ]]
configHelpers.treeNode("Version Manager 2", function()
	utilitools.try(mod, function()
		local modUpdater2 = utilitools.modUpdater2
		local data, _, bool
		if imgui.Button("Relaunch Game") then utilitools.config.save(mod) utilitools.relaunch() end
		configHelpers.doc("autoUpdate")
		configHelpers.input("autoUpdate")
		configHelpers.input("defaultBranch")
		imgui.Separator()
		local modAmount = 0
		local modsSorted = utilitools.table.keysToValues(mods)
		table.sort(modsSorted)
		local function imguiMod(mod) -- success
			if not utilitools.modLinks[mod.id] then return true end

			if modAmount ~= 0 then imgui.Separator() end

			imgui.Indent()

			imgui.TextWrapped(mod.name .. " (" .. mod.version .. ") by " .. mod.author)

			imgui.Indent()

			data = { modUpdater2.onSameFiles(mod) } if not data[1] then return unpack(data) end
			_, bool = unpack(data)

			if not bool then
				data = { modUpdater2.getFileVersion(mod) } if not data[1] then return unpack(data) end
				local fileVersion
				_, fileVersion = unpack(data)
				imgui.TextWrapped("Restart to finish update to " .. fileVersion)
			end

			if imgui.Button("Recheck local files##" .. mod.id) then
				data = { modUpdater2.resetFile(mod) } if not data[1] then return unpack(data) end
			end
			utilitools.imguiHelpers.tooltip("Manually checks the version of the mod in the files again.\nThe file mod version and the active mod version may differ if you edit the files while the game is open.")

			data = { modUpdater2.hasLatest(mod) } if not data[1] then return unpack(data) end
			_, bool = unpack(data)

			if not bool then
				if not mods.utilitools.config.dontUseInternet then
					imgui.SameLine()
					if imgui.Button("Check for update##" .. mod.id) then
						data = { modUpdater2.getLatest(mod) } if not data[1] then return unpack(data) end
					end
				end
			else
				local latestVersion

				data = { modUpdater2.getLatestVersion(mod) } if not data[1] then return unpack(data) end
				_, latestVersion = unpack(data)

				data = { modUpdater2.hasLaterVersion(mod) } if not data[1] then return unpack(data) end
				_, bool = unpack(data)

				if bool then
					if not mods.utilitools.config.dontUseInternet then imgui.AlignTextToFramePadding() end
					imgui.TextWrapped("Latest version: " .. tostring(latestVersion))
					if not mods.utilitools.config.dontUseInternet then
						imgui.SameLine()
						if imgui.Button("Update Version##" .. mod.id) then
							data = { modUpdater2.installDownload(mod) } if not data[1] then return unpack(data) end
						end
					end
				else
					data = { modUpdater2.onLatestVersion(mod) } if not data[1] then return unpack(data) end
					_, bool = unpack(data)

					if not bool then
						imgui.TextWrapped("Latest version: " .. tostring(latestVersion))
					end
				end
				--[[ if false and imgui.Button("Force Update Version Anyways##" .. mod.id) then
					utilitools.prompts.confirm("You will override your mod files with an older version", function() utilitools.modUpdater.downloadMod(mod, nil, false, true) end)
				end ]]
			end

			configHelpers.presets.updateOptions(mod)

			imgui.Unindent()
			imgui.Unindent()

			modAmount = modAmount + 1
			return true
		end
		for _, modId in ipairs(modsSorted) do
			local mod = mods[modId]
			local success, error = imguiMod(mod)
			if not success then
				modlog(mods.utilitools, error)
				imgui.TextWrapped(tostring(error))
				break
			end
		end
	end)
end)
