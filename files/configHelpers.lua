local mod, configOptions, docs
local configHelpers = {}
configHelpers.convertType = function(type)
	return "input" .. type:sub(1, 1):upper() .. type:sub(2)
end
configHelpers.exists = function(key)
	if key == nil then return false end
	if type(key) ~= "string" then return false end
	if mod == nil then return false end
	if configOptions == nil then return false end
	if configOptions[key] == nil then return false end
	if type(configOptions[key]) ~= "table" then return false end
	if configOptions[key].name == nil then return false end
	if configOptions[key].default == nil then return false end
	if configOptions[key].type == nil or type(configOptions[key].type) ~= "string" then return false end
	if configOptions[key].type == "hidden" then return false end
	if configOptions[key].type == "" or configHelpers[configHelpers.convertType(configOptions[key].type)] == nil then return false end
	return true
end
configHelpers.failReason = function(key)
	if key == nil then return "No key" end
	if type(key) ~= "string" then return "Key not string" end
	if mod == nil then return "No mod" end
	if configOptions == nil then return "No config options" end
	if configOptions[key] == nil then return "No setting" end
	if type(configOptions[key]) ~= "table" then return "Setting not table" end
	if configOptions[key].name == nil then return "No name" end
	if configOptions[key].default == nil then return "No default" end
	if configOptions[key].type == nil then return "No type" end
	if type(configOptions[key].type) ~= "string" then return "Type not string" end
	if configOptions[key].type == "hidden" then return "Hidden" end
	if configOptions[key].type == "" or configHelpers[configHelpers.convertType(configOptions[key].type)] == nil then
		return
			"Invalid type: " .. configHelpers.convertType(configOptions[key].type)
	end
	return "Success"
end
configHelpers.checkTemp = function(key)
	if configHelpers.failReason(key) ~= "No setting" then return false end
	if key:sub(-#"_temp") == "_temp" then
		return configHelpers.exists(key:sub(1, -1 - #"_temp"))
	else
		return false
	end
end
configHelpers.input = function(key)
	if not configHelpers.exists(key) then
		imgui.Text("Failed: " .. configHelpers.failReason(key))
		return
	end
	configHelpers[configHelpers.convertType(configOptions[key].type)](key)
end
configHelpers.default = function()
	for k, v in pairs(configOptions) do
		if configHelpers.exists(k) then
			mod.config[k] = v.default
		end
	end
end
configHelpers.off = function()
	for k, v in pairs(configOptions) do
		if configHelpers.exists(k) and v.off ~= nil then
			mod.config[k] = v.off
		end
	end
end
configHelpers.doc = function(key, force, noSep)
	if key == nil then return end
	if mod == nil then return end
	if docs == nil then return end
	if docs[key] == nil then return end

	if not force and (mod.config.documentation == nil or mod.config.documentation == "none") then return end

	local v = docs[key]
	if type(v) == "table" then
		if mod.config.documentation == "short" or v.long == nil then
			v = v.short
		else
			v = v.long
		end
	end
	if v then
		imgui.TextWrapped(tostring(v))
		if not noSep then imgui.Separator() end
	end
end
configHelpers.convertLabel = function(key)
	return configOptions[key].name .. "##" .. mod.id .. "Config_" .. key
end
configHelpers.tooltip = function(key, index)
	if not configHelpers.exists(key) then return end
	if mod.config.tooltips == nil or mod.config.tooltips == "none" then return end

	local tooltip
	if index and configOptions[key].valueTooltips then
		tooltip = configOptions[key].valueTooltips[index]
	end
	if tooltip == nil then tooltip = configOptions[key].tooltips end
	if tooltip then
		if type(tooltip) == "table" then
			if mod.config.tooltips == "short" or tooltip.long == nil then
				tooltip = tooltip.short
			else
				tooltip = tooltip.long
			end
		end
		if tooltip then
			return tostring(tooltip)
		end
	end
end
configHelpers.inputBool = function(key)
	if not configHelpers.exists(key) then
		imgui.Text("Failed.")
		return
	end
	mod.config[key] = utilitools.imguiHelpers.inputBool(
		configHelpers.convertLabel(key), mod.config[key], configOptions[key].default,
		configHelpers.tooltip(key)
	)
end
configHelpers.inputInt = function(key)
	if not configHelpers.exists(key) then
		imgui.Text("Failed.")
		return
	end
	mod.config[key] = utilitools.imguiHelpers.inputInt(
		configHelpers.convertLabel(key), mod.config[key], configOptions[key].default,
		configHelpers.tooltip(key), configOptions[key].flags,
		configOptions[key].step, configOptions[key].stepFast
	)
end
configHelpers.inputFloat = function(key)
	if not configHelpers.exists(key) then
		imgui.Text("Failed.")
		return
	end
	mod.config[key] = utilitools.imguiHelpers.inputFloat(
		configHelpers.convertLabel(key), mod.config[key], configOptions[key].default,
		configHelpers.tooltip(key), configOptions[key].flags,
		configOptions[key].step, configOptions[key].stepFast, configOptions[key].format
	)
end
configHelpers.inputText = function(key)
	if not configHelpers.exists(key) then
		imgui.Text("Failed.")
		return
	end
	mod.config[key] = utilitools.imguiHelpers.inputText(
		configHelpers.convertLabel(key), mod.config[key], configOptions[key].default,
		configHelpers.tooltip(key), configOptions[key].flags,
		configOptions[key].size
	)
end
configHelpers.inputMultiline = function(key)
	if not configHelpers.exists(key) then
		imgui.Text("Failed.")
		return
	end
	mod.config[key] = utilitools.imguiHelpers.inputMultiline(
		configHelpers.convertLabel(key), mod.config[key], configOptions[key].default,
		configHelpers.tooltip(key), configOptions[key].flags,
		configOptions[key].size
	)
end
configHelpers.inputCombo = function(key)
	if not configHelpers.exists(key) then
		imgui.Text("Failed.")
		return
	end
	local valueTooltips = {}
	for i, _ in ipairs(configOptions[key].values) do
		valueTooltips[i] = configHelpers.tooltip(key, i)
	end
	mod.config[key] = utilitools.imguiHelpers.inputCombo(
		configHelpers.convertLabel(key), mod.config[key], configOptions[key].default,
		configHelpers.tooltip(key), configOptions[key].flags,
		configOptions[key].values, valueTooltips
	)
end
configHelpers.inputEase = function(key)
	if not configHelpers.exists(key) then
		imgui.Text("Failed.")
		return
	end
	mod.config[key] = utilitools.imguiHelpers.inputEase(
		configHelpers.convertLabel(key), mod.config[key], configOptions[key].default,
		configHelpers.tooltip(key), configOptions[key].flags
	)
end
configHelpers.inputColor = function(key)
	if not configHelpers.exists(key) then
		imgui.Text("Failed.")
		return
	end
	mod.config[key] = utilitools.imguiHelpers.inputColor(
		configHelpers.convertLabel(key), mod.config[key], configOptions[key].default,
		configHelpers.tooltip(key), configOptions[key].flags
	)
end
configHelpers.inputList = function(key)
	if not configHelpers.exists(key) then
		imgui.Text("Failed.")
		return
	end
	mod.config[key], mod.config[key .. "_temp"] = utilitools.imguiHelpers.inputList(
		configHelpers.convertLabel(key), mod.config[key], configOptions[key].default,
		configHelpers.tooltip(key), configOptions[key].flags,
		mod.config[key .. "_temp"], configOptions[key].size
	)
end
configHelpers.inputKey = function(key)
	if not configHelpers.exists(key) then
		imgui.Text("Failed.")
		return
	end
	utilitools.imguiHelpers.inputKey(
		configHelpers.convertLabel(key), mod,
		key, configHelpers.tooltip(key), true
	)
end
configHelpers.inputBranch = function()
	mods.utilitools.config.branches[mod.id] = utilitools.imguiHelpers.inputBranch(mod, configHelpers.tooltip("branches"))
end
configHelpers.condTreeNode = function(label, key, target, same, func, flags)
	if not configHelpers.exists(key) then return end
	utilitools.imguiHelpers.condTreeNode(
		label, configOptions[key].name, mod.config[key], target, same, func, flags
	)
end
configHelpers.treeNode = function(...) utilitools.imguiHelpers.treeNode(...) end
configHelpers.setMod = function(mod2)
	mod = mod2
	utilitools.fileManager[mod.id].configOptions.load()
	utilitools.fileManager[mod.id].documentation.load()
	configOptions = utilitools.files[mod.id].configOptions
	docs = utilitools.files[mod.id].documentation
end
configHelpers.registerMod = function(mod2)
	if utilitools.fileManager[mod2.id] == nil then
		utilitools.fileManager.registerMod(mod2, {})
	end
	if utilitools.fileManager[mod2.id].configOptions == nil then
		utilitools.fileManager.registerFile(mod2, {
			name = "configOptions",
			extension = "json",
			load = false
		})
	end
	if utilitools.fileManager[mod2.id].documentation == nil then
		utilitools.fileManager.registerFile(mod2, {
			name = "documentation",
			extension = "json",
			load = false
		})
	end
	configHelpers.setMod(mod2)
	for k, v in pairs(configOptions) do
		if configHelpers.exists(k) or configHelpers.failReason(k) == "Hidden" then
            if mod.config[k] == nil then
                mod.config[k] = v.default
                modlog(mod, "Initializing config option: " .. k)
            end
			if v.type == "key" then
				utilitools.keybinds.register.newKey(mod, k, v.default)
			end
		else
			modlog(mod, "Invalid config option: " .. k)
		end
	end
	if utilitools.mods[mod.id].cullConfig then
		for k, _ in pairs(mod.config) do
			-- Penta: Intentionally not using `configHelpers.exists(k)` here to preserve settings when an update accidentally invalides configs
			if configOptions[k] == nil and not configHelpers.checkTemp(k) then
				mod.config[k] = nil
				modlog(mod, "Unused config option: " .. k)
			end
		end
	end
end
configHelpers.presets = {
	menuOptions = function()
		configHelpers.input("documentation")
		configHelpers.input("tooltips")
	end,
	menuButtons = function()
		if imgui.Button("Default") then
			utilitools.prompts.confirm("You will reset all configs for this mod to default", configHelpers.default)
		end
		imgui.SameLine()
		if imgui.Button("Off") then
			utilitools.prompts.confirm("You will turn all mod features off", configHelpers.off)
		end
		if mod == mods.utilitools then
			if imgui.Button("Reload All Files") then
				utilitools.fileManager.loadAll(true)
			end
		else
			if imgui.Button("Reload Mod Files") then
				utilitools.fileManager[mod.id].loadMultiple(nil, true)
			end
		end
	end,
	search = function()
		local prevSearch = mod.config.search
		configHelpers.input("search")
		if mod.config.search ~= "" and prevSearch ~= mod.config.search then
			utilitools.config.search[mod.id] = { {}, {}, {}, {}, {} }
			local function find(s)
				return s:lower():find(mod.config.search:lower(), nil, true)
			end
			for k, v in pairs(configOptions) do
				if configHelpers.exists(k) and k ~= "search" then
					for i, v2 in ipairs({
						find(v.name) == 1,
						not not find(v.name),
						(function()
							if k ~= "combo" then return false end
							if v.values == nil then return false end
							for _, v3 in pairs(v.values) do
								if find(v3) then
									return true
								end
							end
						end)(),
						not not find(configHelpers.tooltip(k)),
						(function()
							if k ~= "combo" then return false end
							if v.valueTooltips == nil then return false end
							for i2, _ in pairs(v.valueTooltips) do
								if find(configHelpers.tooltip(k, i2)) then
									return true
								end
							end
						end)()
					}) do
						if v2 then
							table.insert(utilitools.config.search[mod.id][i], k)
							break
						end
					end
				end
			end
		end
		if utilitools.config.search[mod.id] ~= nil then
			for i, v in ipairs(utilitools.config.search[mod.id]) do
				if #v > 0 then
					imgui.SeparatorText(({ "Match Start", "Match Name", "Match Value", "Match Tooltip", "Match Value Tooltip" })
						[i])
					table.sort(v, function(a, b)
						if configOptions[a].name == configOptions[b].name then
							return a < b
						end
						return configOptions[a].name < configOptions[b].name
					end)
					for _, v2 in ipairs(v) do
						configHelpers.input(v2)
					end
				end
			end
		end
	end,
	updateOptions = function()
		mods.utilitools.config.updates[mod.id] = utilitools.imguiHelpers.inputBool(
			"Update " .. mod.name .. "##" .. mod.id, mods.utilitools.config.updates[mod.id], true,
			"Allow the version for only this mod to be autoupdated"
		)
		configHelpers.inputBranch()
	end
}

return configHelpers
