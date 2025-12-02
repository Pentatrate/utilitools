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
	end,
	relaunch = function()
		local launchArgs = table.concat(arg, " ")

		local osName = love.system.getOS()
		local command = ""

		if osName == "Windows" then
			command = "start beatblock.exe " .. launchArgs
		elseif osName == "OS X" then
			command = "open beatblock.app " .. launchArgs .. " &"
		else -- assume Linux
			command = "./beatblock " .. launchArgs .. " &"
		end

		love.window.close()
		os.execute(command)
		love.event.quit()
	end,
	folderManager = {
		ignoreFiles = { [".git"] = true, [".gitignore"] = true, [".vscode"] = true, [".lovelyignore"] = true, [".nolovelyignore"] = true, ["config.json"] = true, unused = true },
		copy = function(to, from, isMod, hasGit)
			if isMod and not hasGit and mods.utilitools.config.gitFix and love.filesystem.exists(to .. "/.git") then hasGit = true forceprint("Has git") end
			for i, fileName in ipairs(love.filesystem.getDirectoryItems(from)) do
				local toFile = to .. "/" .. fileName
				local fromFile = from .. "/" .. fileName
				local fromFileInfo = love.filesystem.getInfo(fromFile)
				if fromFileInfo and (not isMod or not utilitools.folderManager.ignoreFiles[fileName]) then
					if fromFileInfo.type == "file" then
						local fileExtention
						if isMod then
							fileExtention = utilitools.string.split(fromFile, "%.")
							fileExtention = ({ lua = true, json = true, md = true, toml = true })[fileExtention[#fileExtention]]
						end
						local fromFileData = love.filesystem.read(fileExtention and "string" or "data", fromFile)
						if isMod and fileExtention then
							fromFileData = fromFileData:gsub(string.char(13) .. string.char(10), string.char(10)):gsub(string.char(10), string.char(13) .. string.char(10))
						end
						love.filesystem.write(toFile, fromFileData)
					elseif fromFileInfo.type == "directory" then
						love.filesystem.createDirectory(toFile)
						utilitools.folderManager.copy(toFile, fromFile, isMod, hasGit)
					end
				end
			end
		end,
		delete = function(path, isMod)
			for _, fileName in ipairs(love.filesystem.getDirectoryItems(path)) do
				local filePath = path .. "/" .. fileName
				local fileInfo = love.filesystem.getInfo(filePath)
				if fileInfo and (not isMod or not utilitools.folderManager.ignoreFiles[fileName]) then
					if fileInfo.type == "file" then
						if not love.filesystem.remove(filePath) then forceprint("failed to delete " .. filePath) end
					elseif fileInfo.type == "directory" then
						utilitools.folderManager.delete(filePath, isMod)
					end
				end
			end
			if not love.filesystem.remove(path) then forceprint("failed to delete " .. path) end
		end,
		compare = function(path, path2, isMod, prints)
			if love.filesystem.getInfo(path) == nil then if prints then forceprint("No directory: " .. tostring(path)) end return false end
			if love.filesystem.getInfo(path2) == nil then if prints then forceprint("No directory: " .. tostring(path2)) end return false end

			for _, fileName in ipairs(love.filesystem.getDirectoryItems(path)) do
				local filePath = path .. "/" .. fileName
				local fileInfo = love.filesystem.getInfo(filePath)
				local filePath2 = path2 .. "/" .. fileName
				local fileInfo2 = love.filesystem.getInfo(filePath2)
				if fileInfo and (not isMod or not utilitools.folderManager.ignoreFiles[fileName]) then
					if fileInfo2 == nil then if prints then forceprint("No file: " .. tostring(filePath2)) end return false end
					if fileInfo.type ~= fileInfo2.type then if prints then forceprint("Different file types: " .. tostring(fileInfo.type) .. " " .. tostring(fileInfo2.type)) end return false end

					if fileInfo.type == "file" then
						local content, size = love.filesystem.read(filePath)
						local content2, size2 = love.filesystem.read(filePath2)
						content = content:gsub(string.char(13) .. string.char(10), string.char(10))
						content2 = content2:gsub(string.char(13) .. string.char(10), string.char(10))
						if content ~= content2 then if prints then
							forceprint("Different file content: " .. tostring(filePath) .. " (" .. size .. ") " .. tostring(filePath2) .. " (" .. size2 .. ") => " .. (size - size2))
							for i = 1, #content do
								if content:sub(i, i) ~= content2:sub(i, i) then
									forceprint("Char " .. i .. ": \"" .. tostring(content:sub(i, i)) .. '" | "' .. tostring(content2:sub(i, i)) .. '" | '  .. tostring(content:sub(i, i):byte()) .. " " .. tostring(content2:sub(i, i):byte()))
									break
								end
							end
						end return false end
					elseif fileInfo.type == "directory" then
						return utilitools.folderManager.compare(filePath, filePath2, isMod, prints)
					end
				end
			end
			return true
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
