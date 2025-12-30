if savedata.utilitools == nil then savedata.utilitools = {} end
if savedata.utilitools.bindings == nil then savedata.utilitools.bindings = {} end
if savedata.options.bindings.utilitools == nil then savedata.options.bindings.utilitools = {} end

local gameKeys = savedata.options.bindings
local keybinds = {}
local keys = savedata.utilitools.bindings

local function saveControls()
	modlog(mod, "Saving controls...")
	keybinds.register.registered = false
	sdfunc.save()
	updateControls()
end


keybinds = {
	raw = {},
	mod = {},
	register = { registered = false },
	listening = {
		listening = false,
		category = "",
		keyId = "",
		keysPressed = {}
	}
}

keybinds.raw.setKey = function(category, keyId, binds, dontSave)
	assert(gameKeys[category], "keybinds.raw.setKey: no category: " .. tostring(category))
	gameKeys[category][keyId] = binds
	if not dontSave then saveControls() end
end
keybinds.raw.addKeybind = function(category, keyId, bind, dontSave)
	assert(gameKeys[category], "keybinds.raw.addKeybind: no category: " .. tostring(category))
	if gameKeys[category][keyId] == nil then gameKeys[category][keyId] = {} end
	if not helpers.hasValue(gameKeys[category][keyId], bind) then
		table.insert(gameKeys[category][keyId], bind)
	end
	if not dontSave then saveControls() end
end
keybinds.raw.removeKeybind = function(category, keyId, bind, dontSave)
	assert(gameKeys[category], "keybinds.raw.removeKeybind: no category: " .. tostring(category))
	local keyBindings = gameKeys[category][keyId]
	if keyBindings == nil then modlog(mod, "keybinds.raw.removeKeybind: no key: " .. tostring(category) .. " " .. tostring(keyId)) return end
	for i = #keyBindings, 1, -1 do if keyBindings[i] == bind then table.remove(keyBindings, i) end end
	if not dontSave then saveControls() end
end

keybinds.mod.getCategory = function(mod) return "utilitools_" .. mod.id end
keybinds.mod.getKeys = function(mod) return assert(keys[keybinds.mod.getCategory(mod)], "keybinds.mod.getKeys: no category: " .. tostring(mod)) end
keybinds.mod.getId = function(mod, keyName) return mod.id .. "_" .. keyName end
keybinds.mod.getKeybinds = function(mod, keyName) return assert(keybinds.mod.getKeys(mod)[keybinds.mod.getId(mod, keyName)], "keybinds.mod.getKeybinds: no key: " .. tostring(mod) .. " " .. tostring(keyName)) end
keybinds.mod.addKeybind = function(mod, keyName, bind, dontSave)
	local already = false
	for i = #keybinds.mod.getKeybinds(mod, keyName), 1, -1 do
		local v = keybinds.mod.getKeybinds(mod, keyName)[i]
		local same = true
		for k, _ in pairs(v[1]) do
			if bind[1][k] == nil then same = false break end
		end
		for k, _ in pairs(bind[1]) do
			if v[1][k] == nil then same = false break end
		end
		if same and v[2] == bind[2] then already = true break end
	end
	if not already then table.insert(keybinds.mod.getKeybinds(mod, keyName), bind) end

	for k, _ in pairs(bind[1]) do
		keybinds.raw.setKey("utilitools", "utilitools_" .. k, { k }, true)
	end
	keybinds.raw.setKey("utilitools", "utilitools_" .. bind[2], { bind[2] }, true)

	if not dontSave then saveControls() end
end
keybinds.mod.removeKeybind = function(mod, keyName, bind, dontSave)
	for i = #keybinds.mod.getKeybinds(mod, keyName), 1, -1 do
		local v = keybinds.mod.getKeybinds(mod, keyName)[i]
		local same = true
		for k, _ in pairs(v[1]) do
			if bind[1][k] == nil then same = false break end
		end
		for k, _ in pairs(bind[1]) do
			if v[1][k] == nil then same = false break end
		end
		if same and v[2] == bind[2] then table.remove(keybinds.mod.getKeybinds(mod, keyName), i) end
	end
	if not dontSave then saveControls() end
end

keybinds.register.newKey = function(mod, keyName, binds)
	if keys[keybinds.mod.getCategory(mod)] == nil then keys[keybinds.mod.getCategory(mod)] = {} end
	if keybinds.mod.getKeys(mod)[keybinds.mod.getId(mod, keyName)] == nil then
		keybinds.mod.getKeys(mod)[keybinds.mod.getId(mod, keyName)] = binds
		keybinds.register.registered = true

		for _, bind in ipairs(binds) do
			for k, _ in pairs(bind[1]) do
				keybinds.raw.setKey("utilitools", "utilitools_" .. k, { k }, true)
			end
			keybinds.raw.setKey("utilitools", "utilitools_" .. bind[2], { bind[2] }, true)
		end
	end
end
keybinds.register.finish = function() if keybinds.register.registered then saveControls() end end

keybinds.listening.listen = function(category, keyId, modded)
	keybinds.listening.listening = true
	keybinds.listening.category = category
	keybinds.listening.keyId = keyId
	keybinds.listening.keysPressed = {}

	function love.keypressed(key)
		if project.useImgui then
			imgui.love.KeyPressed(key)
		end
		if keybinds.listening.listening then
			if modded then
				keybinds.listening.keysPressed["key:" .. key] = true
			else
				keybinds.raw.addKeybind(keybinds.listening.category, keybinds.listening.keyId, "key:" .. key)
			end
		end
	end
	function love.keyreleased(key)
		if project.useImgui then
			imgui.love.KeyReleased(key)
		end
		utilitools.try(mod, function()
			if modded and keybinds.listening.listening and keybinds.listening.keysPressed["key:" .. key] then
				keybinds.listening.keysPressed["key:" .. key] = nil
				local formattedKey = { keybinds.listening.keysPressed, "key:" .. key }
				keybinds.mod.addKeybind(keybinds.listening.category, keybinds.listening.keyId, formattedKey)
				keybinds.listening.listening = false
				if utilitools.prompts.listening then
					utilitools.prompts.close()
				end
			end
		end)
	end
end
keybinds.listening.stop = function()
	keybinds.listening.listening = false
	keybinds.listening.keysPressed = {}
end

keybinds.pressed = function(mod, keyName)
	for _, v in ipairs(keybinds.mod.getKeybinds(mod, keyName)) do
		local holding = true
		for k, _ in pairs(v[1]) do
			if not maininput:down("utilitools_" .. k) then
				holding = false
				break
			end
		end
		if holding and maininput:pressed("utilitools_" .. v[2]) then
			return true
		end
	end
	return false
end

return keybinds