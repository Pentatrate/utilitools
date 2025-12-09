local fileManager = {}

local function load(mod, file, reload)
	if file.name ~= "loadAll" then
		if utilitools.files[mod.id] == nil then utilitools.files[mod.id] = {} end
		if reload then utilitools.files[mod.id][file.name] = nil end

		if utilitools.files[mod.id][file.name] == nil then
			local path = utilitools.folderManager.modPath(mod) .. "/"
			if file.name ~= "config" or file.extension ~= "lua" then path = path .. "files/" end
			path = path .. file.name .. "."
			if file.extension == "lua" then
				path = path .. "lua"
				if love.filesystem.getInfo(path, "file") then
					local chunk, e = love.filesystem.load(path)
					if e then
						log(mod, "Error while loading file " .. path .. " of " .. mod.name .. ":\n" .. e)
					else
						utilitools.files[mod.id][file.name] = setfenv(chunk,
							setmetatable({ mod = mod }, { __index = _G }))
						if file.call then
							utilitools.files[mod.id][file.name] = utilitools.files[mod.id][file.name]()
						end
						if mod == mods.utilitools and not ({ configOptions = true, documentation = true })[file.name] then
							utilitools[file.name] = utilitools.files.utilitools[file.name]
						end
						log(mod, "Loaded " .. path)
					end
				end
			elseif file.extension == "json" then
				path = path .. "json"
				if love.filesystem.getInfo(path, "file") then
					utilitools.files[mod.id][file.name] = dpf.loadJson(path)
					if mod == mods.utilitools and not ({ configOptions = true, documentation = true })[file.name] then
						utilitools[file.name] = utilitools.files.utilitools[file.name]
					end
					log(mod, "Loaded " .. path)
				end
			end
		end
	end
end
fileManager.registerFile = function(mod, file)
	if file.name ~= "loadMultiple" then
		fileManager[mod.id][file.name] = {
			name = file.name,
			call = file.call,
			load = function(reload) load(mod, file, reload) end
		}
		if file.load then
            fileManager[mod.id][file.name].load()
		end
	end
end
fileManager.registerMod = function(mod, files)
	if ({ registerFile = true, registerMod = true, loadAll = true })[mod.id] then return end

	if fileManager[mod.id] == nil then
		fileManager[mod.id] = {
			loadMultiple = function(files2, reload)
				local function loadFile(file)
					if file.name ~= "loadMultiple" then
						if file.load then file.load(reload) end
					end
				end
				if files2 == nil then -- load all
					for fileName, file in pairs(fileManager[mod.id]) do
						if fileName ~= "loadMultiple" then
							loadFile(file)
						end
					end
				else
					for _, fileName in ipairs(files2) do
						if fileName ~= "loadMultiple" then
							local file = fileManager[mod.id][fileName]
							if file then
								loadFile(file)
							end
						end
					end
				end
			end
		}
	end
	for name, file in pairs(files) do
		file.name = name
		fileManager.registerFile(mod, file)
	end
end

fileManager.loadAll = function(reload)
	for modId, v in pairs(fileManager) do
		if not ({ registerFile = true, registerMod = true, loadAll = true })[modId] then
			v.loadMultiple(nil, reload)
		end
	end
end

return fileManager
