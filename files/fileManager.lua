local fileManager = { data = {} }

local function load(mod, file, reload)
	if not file.extension then modwarn(mod, "fileManager: No file extension specified") return end

	utilitools.files[mod.id] = utilitools.files[mod.id] or {}
	local modFiles = utilitools.files[mod.id]

	local path = utilitools.folderManager.modPath(mod) .. "/"

	local validExtensions = {
		lua = function()
			local chunk, e = love.filesystem.load(path)
			if e then modlog(mod, "Error while loading file " .. path .. " of " .. mod.name .. ":\n" .. e) return end

			modFiles[file.name] = setfenv(chunk, setmetatable({ mod = mod }, { __index = _G }))

			if not file.call then return true end

			modFiles[file.name] = modFiles[file.name]()

			-- loaded function in module
			if type(modFiles[file.name]) == "table" and type(modFiles[file.name].loaded) == "function" then modFiles[file.name].loaded(mod, file, reload) end
			return true
		end,
		json = function() return utilitools.try(mod, function() modFiles[file.name] = dpf.loadJson(path) end) end
	}

	if not validExtensions[file.extension] then modwarn(mod, "fileManager: Invalid file extension", file.extension, "specified") return end

	if reload then modFiles[file.name] = nil end
	if modFiles[file.name] then return end

	if file.name ~= "config" or file.extension ~= "lua" then path = path .. "files/" end
	if file.path then path = path .. file.path .. "/" end
	path = path .. file.name .. "."

	path = path .. file.extension
	if not love.filesystem.getInfo(path, "file") then modwarn(mod, "fileManager: File", file.name, "doesnt exist at", path) return end

	if validExtensions[file.extension]() then
		if mod == mods.utilitools and not ({ configOptions = true, documentation = true })[file.name] then
			utilitools[file.name] = utilitools.files.utilitools[file.name]
		end
	else
		modlog(mod, "Failed to load file", file.name .. "." .. file.extension)
	end
end
local function registerFile(mod, file)
	if utilitools.fileData[mod.id][file.name] then return end

	utilitools.fileData[mod.id][file.name] = {
		name = file.name,
		load = function(reload) load(mod, file, reload) end
	}

	-- temporary backwards compat for now
	fileManager[mod.id][file.name] = utilitools.fileData[mod.id][file.name]

	if file.load then utilitools.fileData[mod.id][file.name].load() end
end

function fileManager.registerMod(mod, files)
	if utilitools.fileData[mod.id] then return end

	utilitools.fileData[mod.id] = {}
	utilitools.fileLoaders[mod.id] = function(files2, reload)
		local function loadFile(fileName, file)
			file = file or utilitools.fileData[mod.id][fileName]
			if not file or not file.load then return end
			file.load(reload)
		end
		if not files2 then -- load all
			for fileName, file in pairs(utilitools.fileData[mod.id]) do loadFile(fileName, file) end
		else
			for _, fileName in ipairs(files2) do loadFile(fileName) end
		end
	end

	-- temporary backwards compat for now
	fileManager[mod.id] = utilitools.fileData[mod.id]

	for name, file in pairs(files) do file.name = name registerFile(mod, file) end
end

function fileManager.loadAll(reload) for _, fileLoader in pairs(utilitools.fileLoaders) do fileLoader(nil, reload) end end

return fileManager
