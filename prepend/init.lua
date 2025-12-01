utilitools = {
	mods = {},
	files = {},
	dependencies = {},
	incompatibilities = {},
	modChecks = { general = false, dependencies = false, incompatibilities = false },
	config = {
		foldAll = false,
		save = function(mod)
			if beatblockPlus2_0Update then
				dpf.saveJson(mod.path .. "/config.json", mod.config)
			else
				dpf.saveJson((beatblockPlus2_0Update and mod.path or mods.utilitools.config.modPath .. "/" .. mod.id) .. "/mod.json", { id = mod.id, name = mod.name, author = mod.author, description = mod.description, version = mod.version, enabled = mod.enabled, config = mod.config })
			end
		end,
		search = {}
	},
	try = function(mod, func)
		local success, e = pcall(func)
		if not success then log(mod, debug.traceback(e, 1)) end
	end,
	eases = { -- Copied from kakadus-demo-mods
		"linear",
		"inSine", "outSine", "inOutSine",
		"inQuad", "outQuad", "inOutQuad",
		"inCubic", "outCubic", "inOutCubic",
		"inQuart", "outQuart", "inOutQuart",
		"inQuint", "outQuint", "inOutQuint",
		"inExpo", "outExpo", "inOutExpo",
		"inCirc", "outCirc", "inOutCirc",
		"inElastic", "outElastic", "inOutElastic",
		"inBack", "outBack", "inOutBack",
		"inSquaredCirc", "outSquaredCirc", "inOutSquaredCirc",
		"inBounce", "outBounce", "inOutBounce"
	},
	table = {
		keysToValues = function(t)
			local r = {}
			for k, _ in pairs(t) do table.insert(r, k) end
			return r
		end,
		valuesToKeys = function(t)
			local r = {}
			for _, v in ipairs(t) do r[v] = true end
			return r
		end
	},
	string = {
		split = function(s, c) -- only splits using chars
			if c:sub(1, 1) ~= "%" and #c ~= 1 then
				error("utilitools.string.split: second parameter must be a single character")
			end
			if c:sub(1, 1) == "%" and #c ~= 2 then
				error("utilitools.string.split: second parameter must be a single character (+ escaping character)")
			end
			local r = {}
			for w in s:gmatch("[^" .. c .. "]+") do table.insert(r, w) end
			return r
		end
	},
	imgui = {
		color = function(...) return imgui.ColorConvertFloat4ToU32(imgui.ImVec4_Float(...)) end
	},
	request = function(url, type)
		local code, body = require("https").request(url)

		if code == 200 then
			if type == "json" then
				return json.decode(body)
			else
				return body
			end
		else
			error("Request error: http code " .. code .. " | url: " .. tostring(url))
		end
	end
}

forceprint = print
log = function(mod, text)
	forceprint(
		"[" ..
		tostring(
			(
				mod and mod.id and (
					(
						utilitools.mods[mod.id] and utilitools.mods[mod.id].short and tostring(utilitools.mods[mod.id].short)
					) or mod.id
				)
			) or "??"
		) .. "] " .. tostring(text)
	)
end
print = function(...)
	if mods and mods.utilitools and mods.utilitools.config then
		if mods.utilitools.config.isolateLogs ~= nil and not mods.utilitools.config.isolateLogs then
			forceprint(...)
		end
		if mods.utilitools.config.unknownPrints == true then
			forceprint(debug.traceback(nil, 1))
		end
	end
end

local function utilitoolsRegisterMods()
	if not beatblockPlus2_0Update and not love.filesystem.getInfo(mods.utilitools.config.modPath, "directory") then return end
	local modsData = {}

	local function checkForMod(modId, data)
		if not not (mods[modId]) then
			if data.versions == nil then return true end
			for _, v in ipairs(data.versions) do
				if utilitools.versions.compare(mods[modId].version, v[1], v[2], v[3]) then
					return true
				end
			end
		end
		return false
	end
	local function handleModChecks(mod, mods2, requires)
		for modId, data in pairs(mods2) do
			if checkForMod(modId, data) ~= requires then
				log(mod, "Mod checks failed")
				utilitools.modChecks.general = true
				if requires then
					utilitools.modChecks.dependencies = true
					if utilitools.dependencies[mod.id] == nil then utilitools.dependencies[mod.id] = {} end
					utilitools.dependencies[mod.id][modId] = data
				else
					utilitools.modChecks.incompatibilities = true
					if utilitools.incompatibilities[mod.id] == nil then utilitools.incompatibilities[mod.id] = {} end
					utilitools.incompatibilities[mod.id][modId] = data
				end
			end
		end
	end
	local function registerMod(mod, onlyCompat)
		local path = beatblockPlus2_0Update and mod.path or mods.utilitools.config.modPath .. "/" .. mod.id
		if love.filesystem.getInfo(path, "directory") then
			if love.filesystem.getInfo(path .. "/utilitools.json", "file") then
				if modsData[mod.id] == nil then modsData[mod.id] = dpf.loadJson(path .. "/utilitools.json") end
				utilitools.mods[mod.id] = utilitools.mods[mod.id] or {}
				if onlyCompat then
					for _, v in ipairs({ "short", "config", "cullConfig" }) do
						utilitools.mods[mod.id][v] = modsData[mod.id][v]
					end
					if modsData[mod.id].files and type(modsData[mod.id].files) == "table" then
						utilitools.fileManager.registerMod(mod, modsData[mod.id].files)
					end
					if modsData[mod.id].dependencies and type(modsData[mod.id].dependencies) == "table" then
						handleModChecks(mod, modsData[mod.id].dependencies, true)
					end
					if modsData[mod.id].incompatibilities and type(modsData[mod.id].incompatibilities) == "table" then
						handleModChecks(mod, modsData[mod.id].incompatibilities, false)
					end
				else
					if modsData[mod.id].config then
						utilitools.fileManager.utilitools.configHelpers.load()
						utilitools.configHelpers.registerMod(mod, modsData[mod.id].files)
					end
					log(mod, "Registering " .. mod.id)
				end
			end
		else
			log(mod, "No folder found for " .. mod.id)
		end
	end

	registerMod(mods.utilitools, true)
	registerMod(mods.utilitools)
	for k, v in pairs(mods) do
		if k ~= "utilitools" then registerMod(v, true) end
	end
	if not utilitools.modChecks.general then
		for k, v in pairs(mods) do
			if k ~= "utilitools" then registerMod(v) end
		end
	end
	utilitools.keybinds.register.finish()
end

-- Penta: just putting this here...
love.keyboard.setTextInput(true)
