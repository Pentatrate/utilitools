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
	mod = {
		lastPressed = false,
		keyBindsPressed = {}
	},
	register = { registered = false },
	listening = {
		listening = false,
		category = "",
		keyId = "",
		keysPressed = {}
	},
	text = {
		replace = {
			["key:escape"] = "Esc",
			["key:+"] = "Plus",
			["key:-"] = "Minus",
			["key:."] = "Period",
			["key:,"] = "Comma",
			["key:/"] = "Slash",
			["key:return"] = "Enter",
			mouse1 = "LMB",
			mouse2 = "RMB",
			mouse3 = "MMB"
		}
	}
}

function keybinds.raw.getKeys(category)
	return assert(gameKeys[category], "keybinds.raw.getKeys: no category: " .. tostring(category))
end
function keybinds.raw.getKeybinds(category, keyId)
	return assert(keybinds.raw.getKeys(category)[keyId], "keybinds.raw.getKeys: no key: " .. tostring(category) .. " " .. tostring(keyId))
end

function keybinds.raw.setKey(category, keyId, binds, dontSave)
	keybinds.raw.getKeys(category)[keyId] = binds
	if not dontSave then saveControls() end
end

function keybinds.raw.addKeybind(category, keyId, bind, dontSave)
	if keybinds.raw.getKeys(category)[keyId] == nil then keybinds.raw.getKeys(category)[keyId] = {} end
	if not helpers.hasValue(keybinds.raw.getKeybinds(category, keyId), bind) then
		table.insert(keybinds.raw.getKeybinds(category, keyId), bind)
	end
	if not dontSave then saveControls() end
end
function keybinds.raw.removeKeybind(category, keyId, bind, dontSave)
	local keyBindings = keybinds.raw.getKeybinds(category, keyId)
	for i = #keyBindings, 1, -1 do if keyBindings[i] == bind then table.remove(keyBindings, i) end end
	if not dontSave then saveControls() end
end



function keybinds.mod.getCategory(mod) return "utilitools_" .. mod.id end
function keybinds.mod.getId(mod, keyId) return mod.id .. "_" .. keyId end

function keybinds.mod.getKeys(mod)
	return assert(keys[keybinds.mod.getCategory(mod)], "keybinds.mod.getKeys: no category: " .. tostring(mod))
end
function keybinds.mod.getKeybinds(mod, keyId)
	return assert(keybinds.mod.getKeys(mod)[keybinds.mod.getId(mod, keyId)], "keybinds.mod.getKeybinds: no key: " .. tostring(mod) .. " " .. tostring(keyId))
end

function keybinds.mod.addKeybind(mod, keyId, bind, dontSave)
	local already = false
	for i = #keybinds.mod.getKeybinds(mod, keyId), 1, -1 do
		local v = keybinds.mod.getKeybinds(mod, keyId)[i]
		local same = true
		for k, _ in pairs(v[1]) do
			if bind[1][k] == nil then same = false break end
		end
		for k, _ in pairs(bind[1]) do
			if v[1][k] == nil then same = false break end
		end
		if same and v[2] == bind[2] then already = true break end
	end
	if not already then table.insert(keybinds.mod.getKeybinds(mod, keyId), bind) end

	for k, _ in pairs(bind[1]) do
		keybinds.raw.setKey("utilitools", "utilitools_" .. k, { k }, true)
	end
	keybinds.raw.setKey("utilitools", "utilitools_" .. bind[2], { bind[2] }, true)

	if not dontSave then saveControls() end
end
function keybinds.mod.removeKeybind(mod, keyId, bind, dontSave)
	for i = #keybinds.mod.getKeybinds(mod, keyId), 1, -1 do
		local v = keybinds.mod.getKeybinds(mod, keyId)[i]
		local same = true
		for k, _ in pairs(v[1]) do
			if bind[1][k] == nil then same = false break end
		end
		for k, _ in pairs(bind[1]) do
			if v[1][k] == nil then same = false break end
		end
		if same and v[2] == bind[2] then table.remove(keybinds.mod.getKeybinds(mod, keyId), i) end
	end
	if not dontSave then saveControls() end
end

function keybinds.mod.pressed(mod, keyId, hold)
	for _, v in ipairs(keybinds.mod.getKeybinds(mod, keyId)) do
		local holding = true
		for k, _ in pairs(v[1]) do
			if not maininput:down("utilitools_" .. k) then
				holding = false
				break
			end
		end
		if holding and ((not hold and maininput:pressed("utilitools_" .. v[2])) or (hold and maininput:down("utilitools_" .. v[2]))) then
			return true, utilitools.table.tableAmount(v[1])
		end
	end
	return false
end

function keybinds.mod.checkBindsStart()
	if keybinds.listening.listening then return end
	keybinds.mod.keyBindsPressed = {}
end
function keybinds.mod.checkBinds(mod, binds)
	if project.useImgui and imgui.love.GetWantCaptureKeyboard() then return end
	if type(binds) ~= "table" then return end
	if keybinds.listening.listening then return end

	for key, func in pairs(binds) do
		if type(func) == "function" then
			local pressed, amount = keybinds.mod.pressed(mod, key, key == keybinds.mod.lastPressed)
			if pressed then
				table.insert(keybinds.mod.keyBindsPressed, key == keybinds.mod.lastPressed and 1 or #keybinds.mod.keyBindsPressed + 1, { key = key, amount = amount, func = func })
			end
		end
	end
end
function keybinds.mod.checkBindsEnd()
	if keybinds.listening.listening then return end
	if #keybinds.mod.keyBindsPressed == 0 then keybinds.mod.lastPressed = false return end
	if keybinds.mod.keyBindsPressed[1] and keybinds.mod.keyBindsPressed[1].key == keybinds.mod.lastPressed then return end

	local highest = keybinds.mod.keyBindsPressed[1]
	for _, keybind in ipairs(keybinds.mod.keyBindsPressed) do
		if keybind.amount > highest.amount then
			highest = keybind
		elseif keybind.amount < highest.amount then
			-- nothing
		elseif keybind.key > highest.key then
			highest = keybind
		end
	end

	highest.func()
	keybinds.mod.lastPressed = highest.key
end

function keybinds.register.newKey(mod, keyId, binds)
	if keys[keybinds.mod.getCategory(mod)] == nil then keys[keybinds.mod.getCategory(mod)] = {} end
	if keybinds.mod.getKeys(mod)[keybinds.mod.getId(mod, keyId)] == nil then
		keybinds.mod.getKeys(mod)[keybinds.mod.getId(mod, keyId)] = binds
		keybinds.register.registered = true

		for _, bind in ipairs(binds) do
			for k, _ in pairs(bind[1]) do
				keybinds.raw.setKey("utilitools", "utilitools_" .. k, { k }, true)
			end
			keybinds.raw.setKey("utilitools", "utilitools_" .. bind[2], { bind[2] }, true)
		end
	end
end
function keybinds.register.finish() if keybinds.register.registered then saveControls() end end



function keybinds.getKeybinds(category, keyId, modded)
	if modded then
		return keybinds.mod.getKeybinds(category, keyId)
	else
		if category ~= "controltable" then
			return keybinds.raw.getKeybinds(category, keyId)
		else
			return assert(controltable[keyId], "keybinds.getKeybinds: no key: " .. tostring(categorymod) .. " " .. tostring(keyId))
		end
	end
end



function keybinds.listening.listen(category, keyId, modded)
	if category == "controltable" then return end

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
				keybinds.listening.listening = false
				if utilitools.prompts.listening then
					utilitools.prompts.close()
				end
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
function keybinds.listening.stop() keybinds.listening.listening = false keybinds.listening.keysPressed = {} end



function keybinds.text.keyLabel(keyId)
	if keybinds.text.replace[keyId] then
		return keybinds.text.replace[keyId]
	elseif keyId:sub(1, #"key:") == "key:" then
		return utilitools.string.capitalise(keyId:sub(#"key:" + 1))
	end
	return keyId
end
function keybinds.text.generate(category, keyId, modded, group)
	local keyLabel = ""
	local amount = 0
	for _, v in ipairs(keybinds.getKeybinds(category, keyId, modded)) do
		if keyLabel ~= "" then keyLabel = keyLabel .. " or " end
		if modded then
			local first = true
			for k, _ in pairs(v[1]) do
				keyLabel = keyLabel .. (first and "" or " + ") .. keybinds.text.keyLabel(k)
				first = false
			end
			keyLabel = keyLabel .. (first and "" or " + ") .. keybinds.text.keyLabel(v[2])
		else
			keyLabel = keyLabel .. keybinds.text.keyLabel(v)
		end
		amount = amount + 1
	end
	if group and amount > 1 then keyLabel = "(" .. keyLabel .. ")" end
	return keyLabel
end

return keybinds