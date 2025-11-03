utilitools = {
	mods = {},
	files = {},
	dependencies = {},
	incompatibilities = {},
	modChecks = { general = false, dependencies = false, incompatibilities = false },
	config = {
        foldAll = false,
		save = function(mod)
			local configRenderer = mod.configRenderer
			mod.configRenderer = nil
			dpf.saveJson(mods.utilitools.config.modPath .. "/" .. mod.id .. "/mod.json", mod)
			mod.configRenderer = configRenderer
        end,
		search = {}
    },
	try = function (mod, func)
        local success, e = pcall(func)
		if not success then log(mod, e) end
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
		keysToValues = function (t)
            local r = {}
            for k, _ in pairs(t) do table.insert(r, k) end
			return r
		end
	}
}

forceprint = print
log = function(mod, text)
	forceprint(
		"[" ..
		tostring(
			(
				mod and mod.id and (
					(
						utilitools.mods[mod.id] and tostring(utilitools.mods[mod.id].short)
					) or mod.id
				)
			) or "??"
		) .. "] " .. tostring(text)
	)
end
print = function(...)
	if mods and mods.utilitools and mods.utilitools.config and mods.utilitools.config.isolateLogs ~= nil and not mods.utilitools.config.isolateLogs then
		forceprint(...)
	end
end

local function utilitoolsRegisterMods()
	if not love.filesystem.getInfo(mods.utilitools.config.modPath, "directory") then return end

    local function checkForMod(modId, data)
        if not not (mods[modId]) then
            if data.versions == nil then return true end
			log(mods.utilitools, "Checking for versions")
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

	local modFolders = love.filesystem.getDirectoryItems(mods.utilitools.config.modPath)
	table.sort(modFolders, function(a, b)
		if a == "utilitools" then return true end
		if b == "utilitools" then return false end
		return a < b
	end)
    for _, modId in ipairs(modFolders) do
        local path = mods.utilitools.config.modPath .. "/" .. modId
        if love.filesystem.getInfo(path, "directory") then
            if love.filesystem.getInfo(path .. "/utilitools.json", "file") then
                local data = dpf.loadJson(path .. "/utilitools.json")

                utilitools.mods[modId] = {}
                for _, v in ipairs({ "short", "config", "cullConfig" }) do
                    utilitools.mods[modId][v] = data[v]
                end
                if data.files and type(data.files) == "table" then
                    utilitools.fileManager.registerMod(mods[modId], data.files)
                end
                if data.dependencies and type(data.dependencies) == "table" then
                    handleModChecks(mods[modId], data.dependencies, true)
                end
                if data.incompatibilities and type(data.incompatibilities) == "table" then
                    handleModChecks(mods[modId], data.incompatibilities, false)
                end
                if data.config then
                    utilitools.fileManager.utilitools.configHelpers.load()
                    utilitools.configHelpers.registerMod(mods[modId], data.files)
                end
                log(mods.utilitools, "Registering " .. modId)
            end
        end
    end
	utilitools.keybinds.finishRegistering()
end

-- Penta: just putting this here...
love.keyboard.setTextInput(true)