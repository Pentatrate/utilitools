local fileManager = { data = {} }

local function load(mod, file, reload)
	if file.name == "loadAll" then modwarn(mod, "fileManager: Tried to load loadAall") return end
	if not file.extension then modwarn(mod, "fileManager: No file extension specified") return end
	local modFiles = utilitools.files[mod.id]
	local path = utilitools.folderManager.modPath(mod) .. "/"
	local validExtensions = {
		lua = function()
			local chunk, e = love.filesystem.load(path)
			if e then
				modlog(mod, "Error while loading file " .. path .. " of " .. mod.name .. ":\n" .. e)
				return
			end

			modFiles[file.name] = setfenv(chunk, setmetatable({ mod = mod }, { __index = _G }))
			if file.call then
				modFiles[file.name] = modFiles[file.name]()
				if type(modFiles[file.name]) == "table" and type(modFiles[file.name].loaded) == "function" then
					modFiles[file.name].loaded(mod, file, reload)
				end
			end
			return true
		end,
		json = function()
			return utilitools.try(mod, function() modFiles[file.name] = dpf.loadJson(path) end)
		end
	}
	if not validExtensions[file.extension] then modwarn(mod, "fileManager: Invalid file extension", file.extension, "specified") return end

	if modFiles == nil then modFiles = {} utilitools.files[mod.id] = modFiles end
	if reload then modFiles[file.name] = nil end
	if modFiles[file.name] then modwarn(mod, "fileManager: File", file.name, "already loaded") return end

	if file.name ~= "config" or file.extension ~= "lua" then path = path .. "files/" end
	if file.path then path = path .. file.path .. "/" end
	path = path .. file.name .. "."

	path = path .. file.extension
	if not love.filesystem.getInfo(path, "file") then modwarn(mod, "fileManager: File", file.name, "doesnt exist at", path) return end

	if validExtensions[file.extension]() then
		if mod == mods.utilitools and not ({ configOptions = true, documentation = true })[file.name] then
			utilitools[file.name] = utilitools.files.utilitools[file.name]
		end
		-- modlog(mod, "Loaded " .. path)
	end
end
fileManager.registerFile = function(mod, file)
	if file.name == "loadMultiple" then return end
	fileManager.data[mod.id][file.name] = {
		name = file.name,
		call = file.call,
		load = function(reload) load(mod, file, reload) end
	}
	fileManager[mod.id][file.name] = fileManager.data[mod.id][file.name]
	if file.load then fileManager.data[mod.id][file.name].load() end
end
fileManager.registerMod = function(mod, files)
	if ({ registerFile = true, registerMod = true, loadAll = true })[mod.id] then return end

	if fileManager.data[mod.id] == nil then
		fileManager.data[mod.id] = {
			loadMultiple = function(files2, reload)
				local function loadFile(file)
					if file.name ~= "loadMultiple" and file.load then file.load(reload) end
				end
				if not files2 then -- load all
					for fileName, file in pairs(fileManager.data[mod.id]) do
						if fileName ~= "loadMultiple" then loadFile(file) end
					end
				else
					for _, fileName in ipairs(files2) do
						if fileName ~= "loadMultiple" then
							local file = fileManager.data[mod.id][fileName]
							if file then loadFile(file) end
						end
					end
				end
			end
		}
		fileManager[mod.id] = fileManager.data[mod.id]
	end
	for name, file in pairs(files) do
		file.name = name
		fileManager.registerFile(mod, file)
	end
end

fileManager.loadAll = function(reload)
	for _, v in pairs(fileManager.data) do
		v.loadMultiple(nil, reload)
	end
end

return fileManager
