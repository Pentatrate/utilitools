local keybinds = {
	keysRegistered = false,
	listening = nil
}

keybinds.startListen = function()
	function love.keypressed(key)
		if project.useImgui then -- Fixes bug with imgui breaking after opening the editor menu.
			imgui.love.KeyPressed(key)
		end
		if keybinds.listening then
			keybinds.forceAddKeyValue(keybinds.listening.category, keybinds.listening.key, "key:" .. key)
			keybinds.listening = nil
			if utilitools.prompts.listening then
				utilitools.prompts.close()
			end
		end
	end
end

keybinds.saveControls = function()
	sdfunc.save()
	updateControls()
end

keybinds.getKeys = function(category)
    return savedata.options.bindings[category]
end

keybinds.forceSaveKey = function(category, key, values)
	keybinds.getKeys(category)[key] = values
	keybinds.saveControls()
end
keybinds.forceAddKeyValue = function(category, key, value)
	if not helpers.hasValue(keybinds.getKeys(category)[key], value) then
		table.insert(keybinds.getKeys(category)[key], value)
	end
	keybinds.saveControls()
end
keybinds.forceRemoveKeyValue = function(category, key, value)
    for i = #keybinds.getKeys(category)[key], 1, -1 do
        local v = keybinds.getKeys(category)[key][i]
        if v == value then
            table.remove(keybinds.getKeys(category)[key], i)
        end
    end
    keybinds.saveControls()
end

keybinds.forceListen = function(category, key)
	keybinds.listening = {
		category = category,
		key = key
	}
	keybinds.startListen()
end
keybinds.stopListening = function()
	keybinds.listening = nil
end

keybinds.registerKey = function(mod, key, values)
	if keybinds.getModKeys(mod) == nil then
		savedata.options.bindings[keybinds.getModCategory(mod)] = {}
	end
	if keybinds.getModKeys(mod)[keybinds.keyName(mod, key)] == nil then
		keybinds.getModKeys(mod)[keybinds.keyName(mod, key)] = values
	end
	keybinds.keysRegistered = true
end
keybinds.finishRegistering = function()
	if keybinds.keysRegistered then
		keybinds.saveControls()
	end
end

keybinds.getModCategory = function(mod)
	return "utilitools_" .. mod.id
end
keybinds.getModKeys = function(mod)
    return keybinds.getKeys(keybinds.getModCategory(mod))
end
keybinds.keyName = function (mod, key)
	return mod.id .. "_" .. key
end

keybinds.addKeyValue = function(mod, key, value)
	keybinds.forceAddKeyValue(keybinds.getModCategory(mod), key, value)
end
keybinds.removeKeyValue = function(mod, key, value)
	keybinds.forceRemoveKeyValue(keybinds.getModCategory(mod), key, value)
end

keybinds.listen = function(mod, key)
	keybinds.forceListen(keybinds.getModCategory(mod), key)
end

return keybinds
