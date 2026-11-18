utilitools = utilitools or {}

utilitools.mods = utilitools.mods or {}

utilitools.files = utilitools.files or {}
utilitools.fileData = utilitools.fileData or {}
utilitools.fileLoaders = utilitools.fileLoaders or {}

utilitools.dependencies = utilitools.dependencies or {}
utilitools.incompatibilities = utilitools.incompatibilities or {}
utilitools.modChecks = utilitools.modChecks or { general = false, dependencies = false, incompatibilities = false }

function utilitools.context()
	local function getContext(contextAmount, minDepth, fullStack, lineNumbers)
		if not utilitools then return "error: utilitools not loaded" end
		local pathInfos = utilitools.string.split(debug.traceback(), "\n")

		local success, text = utilitools.try(nil, function()
			table.remove(pathInfos, 1)

			contextAmount = contextAmount or 0
			minDepth = minDepth or 1

			local function getSingleContext(depth)
				depth = depth or 1
				local pathInfo = pathInfos[depth]

				if not pathInfo then return false, true, "error: invalid depth (" .. depth .. "/" .. #pathInfos .. ")" end
				local errorPos = utilitools.string.split(pathInfo:sub(2), ":")
				errorPos[1] = errorPos[1]:gsub("\\", "/") or "unknown file"
				errorPos[2] = tonumber(errorPos[2])
				local errorPosString = errorPos[1] .. ":" ..( errorPos[2] or " unknown line") .. ":"

				local dumpPath = "Mods/lovely/dump/" .. errorPos[1]
				local inDump = love.filesystem.getInfo(dumpPath)
				local filePath = inDump and dumpPath or errorPos[1]
				if not love.filesystem.getInfo(filePath) then return false, false, errorPosString .. " error: file not in filesystem" end

				local contents = love.filesystem.read(filePath)
				if type(contents) ~= "string" then return false, false, errorPosString .. " error: file (" .. filePath .. ") might have incompatible encoding" end

				local lines = {}
				local context = {}
				for line in love.filesystem.lines(filePath) do
					table.insert(lines, line)
				end
				for i = math.max(1, errorPos[2] - contextAmount), math.min(#lines, errorPos[2] + contextAmount) do
					local prepend = lineNumbers and i .. "\t|" or ""
					local append = ""
					if i == errorPos[2] then append = " <<<<< <<<<< HERE <<<<< <<<<<" end
					table.insert(context, prepend .. lines[i] .. append)
				end
				return true, false, "Context: " .. errorPosString .. "\n" .. table.concat(context, "\n")
			end

			if fullStack then
				local contexts = {}
				for depth = minDepth, #pathInfos do
					local success, abort, context = getSingleContext(depth)
					if abort then break end
					table.insert(contexts, context)
				end
				return "Contexts: " .. table.concat(contexts, "\n")
			else
				local firstError
				local depth = minDepth
				while true do
					local success, abort, context = getSingleContext(depth)
					firstError = firstError or context
					if abort then return firstError end
					if success then return context end
					depth = depth + 1
				end
			end
		end)
		return success and text or ""
	end
	if mods and mods.crash_context and mods.crash_context.enabled and mods.crash_context.config.context then
		modlog(mods.crash_context, getContext(mods.crash_context.config.surroundingLines, 4, mods.crash_context.config.fullStack, mods.crash_context.config.lineNumbers))
	else
		modlog(nil, getContext(4, 4, true, true))
	end
end

function utilitools.try(mod, func, silent) return xpcall(func, function(error) if not silent then modwarn(mod, error) end end) end

utilitools.table = utilitools.table or {}
function utilitools.table.keysToValues(t)
	local r = {}
	for k, _ in pairs(t) do table.insert(r, k) end
	return r
end
function utilitools.table.valuesToKeys(t)
	local r = {}
	for _, v in ipairs(t) do r[v] = true end
	return r
end
function utilitools.table.emptyTable(t)
	if type(t) ~= "table" then return false end
	for _, _ in pairs(t) do return false end
	return true
end
function utilitools.table.tableAmount(t)
	if type(t) ~= "table" then return -1 end
	local i = 0
	for _, _ in pairs(t) do i = i  + 1 end
	return i
end

utilitools.string = utilitools.string or {}
function utilitools.string.split(s, c) -- only splits using chars
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
function utilitools.string.toClipboard(t)
	t = tostring(t)
	modlog(mods.utilitools, "Copied to clipboard: ", t)
	love.system.setClipboardText(t)
	if cs and cs.p and cs.p.hurtPulse then cs.p:hurtPulse() end
	utilitools.prompts.custom({ title = "Copied to clipboard!", message = t })
end
function utilitools.string.concat(...)
	local args = { ... }
	local maxIndex = 0

	for i, _ in pairs(args) do if i > maxIndex then maxIndex = i end end

	local text = ""

	if #args == 0 then
		text = "nil"
	else
		for i = 1, maxIndex do
			local t = args[i]
			if i ~= 1 then text = text .. " | " end
			if type(t) == "table" then
				if utilitools.table.emptyTable(t) then
					text = text .. "{}"
				elseif not utilitools.try(mod, function() text = text .. json.encode(t) end, true) then
					text = text .. tostring(t)
				end
			else
				text = text .. tostring(t)
			end
		end
	end

	return text
end
function utilitools.string.capitalise(s)
	if type(s) ~= "string" then return "" end
	return s == "" and s or s:sub(1, 1):upper() .. s:sub(2)
end

utilitools.folderManager = utilitools.folderManager or {}
utilitools.folderManager.ignoreFiles = {
	[".git"] = true, [".gitignore"] = true, [".vscode"] = true, -- misc
	[".lovelyignore"] = true, [".nolovelyignore"] = true, -- lovely
	["config.json"] = true, -- BeatblockPlus
	unused = true, -- Beattools and Utilitools
	LvlData = true, -- Detailed Accuracy by mawl
	customsounds = true -- Lemontweaks by gooberlemonade
}
function utilitools.folderManager.isIgnored(fileName, isMod, ignore)
	if not isMod then return false end
	if utilitools.folderManager.ignoreFiles[fileName] then return true end
	return ignore and ignore[fileName]
end
function utilitools.folderManager.copy(to, from, isMod, hasGit, ignore)
	if isMod and not hasGit and mods.utilitools.config.gitFix and love.filesystem.getInfo(to .. "/.git") then hasGit = true modlog(mod, "Has git") end
	love.filesystem.createDirectory(to)
	for i, fileName in ipairs(love.filesystem.getDirectoryItems(from)) do
		local toFile = to .. "/" .. fileName
		local fromFile = from .. "/" .. fileName
		local fromFileInfo = love.filesystem.getInfo(fromFile)
		if fromFileInfo and not utilitools.folderManager.isIgnored(fileName, isMod, ignore) then
			if fromFileInfo.type == "file" then
				local fileExtention
				if isMod then
					fileExtention = utilitools.string.split(fromFile, "%.")
					fileExtention = ({ lua = true, json = true, md = true, toml = true })[fileExtention[#fileExtention]]
				end
				local fromFileData = love.filesystem.read(isMod and fileExtention and hasGit and "string" or "data", fromFile)
				if isMod and fileExtention and hasGit then
					fromFileData = fromFileData:gsub(string.char(13) .. string.char(10), string.char(10)):gsub(string.char(10), string.char(13) .. string.char(10))
				end
				love.filesystem.write(toFile, fromFileData)
			elseif fromFileInfo.type == "directory" then
				love.filesystem.createDirectory(toFile)
				utilitools.folderManager.copy(toFile, fromFile, isMod, hasGit, ignore)
			end
		end
	end
end
function utilitools.folderManager.delete(path, isMod, ignore, info)
	info = info or love.filesystem.getInfo(path)
	if not info then modwarn(mod, "utilitools.folderManager.delete: doesnt exist", path) return end
	if info.type == "directory" then
		for _, fileName in ipairs(love.filesystem.getDirectoryItems(path)) do
			local filePath = path .. "/" .. fileName
			local fileInfo = love.filesystem.getInfo(filePath)
			if fileInfo and not utilitools.folderManager.isIgnored(fileName, isMod, ignore) then
				if fileInfo.type == "file" then
					if not love.filesystem.remove(filePath) then modwarn(mod, "utilitools.folderManager.delete: failed to delete 2", filePath) end
				elseif fileInfo.type == "directory" then
					utilitools.folderManager.delete(filePath, isMod, ignore, fileInfo)
				end
			end
		end
	end
	if not love.filesystem.remove(path) then modwarn(mod, "utilitools.folderManager.delete: failed to delete 1", path) end
end
function utilitools.folderManager.compare(path, path2, isMod, prints, ignore)
	local mod = mods.utilitools
	if love.filesystem.getInfo(path) == nil then if prints then modlog(mod, "No directory: " .. tostring(path)) end return false end
	if love.filesystem.getInfo(path2) == nil then if prints then modlog(mod, "No directory: " .. tostring(path2)) end return false end

	for _, fileName in ipairs(love.filesystem.getDirectoryItems(path)) do
		local filePath = path .. "/" .. fileName
		local fileInfo = love.filesystem.getInfo(filePath)
		local filePath2 = path2 .. "/" .. fileName
		local fileInfo2 = love.filesystem.getInfo(filePath2)
		if fileInfo and not utilitools.folderManager.isIgnored(fileName, isMod, ignore) then
			if fileInfo2 == nil then if prints then modlog(mod, "No file: " .. tostring(filePath2)) end return false end
			if fileInfo.type ~= fileInfo2.type then if prints then modlog(mod, "Different file types: " .. tostring(fileInfo.type) .. " " .. tostring(fileInfo2.type)) end return false end

			if fileInfo.type == "file" then
				local content, size = love.filesystem.read(filePath)
				local content2, size2 = love.filesystem.read(filePath2)
				content = content:gsub(string.char(13) .. string.char(10), string.char(10))
				content2 = content2:gsub(string.char(13) .. string.char(10), string.char(10))
				if content ~= content2 then if prints then
					modlog(mod, "Different file content: " .. tostring(filePath) .. " (" .. size .. ") " .. tostring(filePath2) .. " (" .. size2 .. ") => " .. (size - size2))
					for i = 1, #content do
						if content:sub(i, i) ~= content2:sub(i, i) then
							modlog(mod, "Char " .. i .. ": \"" .. tostring(content:sub(i, i)) .. '" | "' .. tostring(content2:sub(i, i)) .. '" | '  .. tostring(content:sub(i, i):byte()) .. " " .. tostring(content2:sub(i, i):byte()))
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
function utilitools.folderManager.modPath(mod)
	if not mod then error(utilitools.string.concat("utilitools.folderManager.modPath: no mod", mod)) end
	return mod.path
end
function utilitools.folderManager.getModsFolder()
	local modPath = require("lovely").mod_dir
	local _, pos = modPath:find(love.filesystem.getIdentity())
	return modPath:sub(pos + 2):gsub("\\", "/")
end

utilitools.window = utilitools.window or {}
function utilitools.window.message(mod, message, options, functions, allowEscape, additionalTitle)
	local buttonPressed = love.window.showMessageBox(mod.name .. (additionalTitle or ""), message, options)
	if not options[buttonPressed] and not allowEscape then error("Tried to escape the dialogue") end
	if type(functions[buttonPressed]) == "function" then functions[buttonPressed]() end
end

utilitools.config = utilitools.config or { foldAll = false }
function utilitools.config.save(mod)
	if bbp and bbp.utils and bbp.utils.saveConfig then
		bbp.utils.saveConfig(mod.id)
	else
		dpf.saveJson(mod.path .. "/config.json", mod.config)
	end
end

utilitools.relaunch = utilitools.relaunch or {}
utilitools.relaunch.doRelaunch = false
function utilitools.relaunch.relaunch(crash)
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

	local success = false
	utilitools.try(mod, function()
		love.window.close()
		os.execute(command)
		love.event.quit()
		success = true
	end)
	if not success then
		utilitools.relaunch.doRelaunch = true
		if crash then error("Utilitools: Failed to quit") end
	end
end

utilitools.init = utilitools.init or { inited = false }
function utilitools.init.fileLoader()
	if utilitools.fileManager then return end
	local path = utilitools.folderManager.modPath(mods.utilitools) .. "/files/fileManager.lua"
	local chunk, e = love.filesystem.load(path)
	if e then
		error("Error while loading file " .. path .. " of Utilitools: " .. e)
	else
		utilitools.fileManager = setfenv(chunk, setmetatable({}, { __index = _G }))()
	end
end
function utilitools.init.registerMods()
	local modsMetadata = {}

	local function checkForMod(modId, data)
		if not mods[modId] then return false end
		if not data.versions then return true end
		for _, v in ipairs(data.versions) do if utilitools.versions.compare(mods[modId].version, v[1], v[2], v[3]) then return true end end
		return false
	end
	local function handleModChecks(mod, mods2, requires)
		for modId, data in pairs(mods2) do
			if checkForMod(modId, data) ~= requires then
				local type = requires and "dependencies" or "incompatibilities"
				utilitools.modChecks.general = true
				utilitools.modChecks[type] = true
				utilitools[type][mod.id] = utilitools[type][mod.id] or {}
				utilitools[type][mod.id][modId] = data
			end
		end
	end
	local function registerMod(mod, onlyCompat)
		if not mod.enabled then return end
		local path = utilitools.folderManager.modPath(mod)
		if not love.filesystem.getInfo(path, "directory") then modlog(mod, "No folder found for " .. mod.id) return end
		if not love.filesystem.getInfo(path .. "/utilitools.json", "file") then return end

		modsMetadata[mod.id] = modsMetadata[mod.id] or dpf.loadJson(path .. "/utilitools.json")
		local modMetadata = modsMetadata[mod.id]
		utilitools.mods[mod.id] = utilitools.mods[mod.id] or {}
		local modData = utilitools.mods[mod.id]

		if onlyCompat then
			if log then log:defineEnvironment(mod.id, 2, 2) end
			local function set(k) modData[k] = modMetadata[k] end
			for _, v in ipairs({ "config", "cullConfig", "ignore" }) do set(v) end

			local function tableExists(k) return modMetadata[k] and type(modMetadata[k]) == "table" end
			if tableExists("files") then             set("files")             utilitools.fileManager.registerMod(mod, modData.files) end
			if tableExists("dependencies") then      set("dependencies")      handleModChecks(mod, modData.dependencies,       true) end
			if tableExists("incompatibilities") then set("incompatibilities") handleModChecks(mod, modData.incompatibilities, false) end
		else
			if modMetadata.config then utilitools.configHelpers.registerMod(mod, modMetadata.files) end
		end
	end

	registerMod(mods.utilitools, true)
	registerMod(mods.utilitools)
	for k, v in pairs(mods) do if k ~= "utilitools" then registerMod(v, true) end end
	if not utilitools.modChecks.general then for k, v in pairs(mods) do if k ~= "utilitools" then registerMod(v) end end end
	utilitools.keybinds.register.finish()
end
function utilitools.init.prompts()
	local mod = mods.utilitools
	local slickMessage = "You thought you were slick... (Tried to escape the dialogue)"
	if mod.config.askUpdate then
		if not mod.config.autoUpdate then
			utilitools.window.message(
				mod, "Welcome to Utilitools!\nDo you want to enable auto updating for mods?\n\n(You will be able to change this in the configs)",
				{
					"Yes, proceed",
					"No, dont ask again"
				},
				{
					function() mod.config.autoUpdate = true end,
					nil -- nothing, already false
				}
			)
		end
		if mod.config.autoUpdate then
			utilitools.window.message(
				mod, "Auto updating will require internet access.\nMods will *not* be scanned for viruses.\nAre you sure?\n\n(You will be able to change this in the configs)",
				{
					"Yes, enable",
					"Nevermind, don't enable"
				},
				{
					nil, -- nothing, already true
					function() mod.config.autoUpdate = false end
				}
			)
		end

		mod.config.askUpdate = false
		utilitools.config.save(mod)
	end
	if mod.askDontUseInternet and not mod.config.autoUpdate and not mod.config.dontUseInternet then
		utilitools.window.message(
			mod, "You have disabled autoupdating.\nDo you want to be reminded of an update instead so you can update it manually?\n\n(You will be able to change this in the configs)",
			{
				"Yes, enable",
				"No, dont ask again"
			},
			{
				nil, -- nothing, already false
				function() mod.config.dontUseInternet = true end
			}
		)

		mod.askDontUseInternet = false
		utilitools.config.save(mod)
	end
end
function utilitools.init.init()
	if utilitools.init.inited then return end
	local mod = mods.utilitools
	utilitools.init.inited = true

	utilitools.init.fileLoader()

	if log then
		log:defineEnvironment("unknown-mod", 2, 2)
		log:defineEnvironment("utilitools", 2, 2)
	end

	utilitools.init.registerMods()
	utilitools.backwardsCompat()

	utilitools.init.prompts()

	local success, outdated
	if not mod.config.dontUseInternet then success, outdated = utilitools.modUpdater2.updateOutdatedMods() end

	if mod.config.autoUpdate and success and outdated then
		utilitools.relaunch.doRelaunch = true
		utilitools.config.save(mod)
		cs = bs.load("UtilitoolsEmpty")
	else
		updateControls()
		if mod.config.updated.hasUpdated then
			if cs.name ~= project.initState then mod.config.updated.initState = cs.name end
			cs = bs.load("UtilitoolsUpdate")
		elseif utilitools.modChecks.general then -- mod checks failed (dependency/incompatibility)
			cs = bs.load("UtilitoolsModCheck")
		end
		mod.config.updated.hasUpdated = false
	end
end

local forceprint = print
function modlog(mod, ...)
	local modLabel = tostring(mod and mod.id or "unknown-mod")
	local text = utilitools.string.concat(...)
	if log then log(text, modLabel) else forceprint("[" .. modLabel .. "] " .. text) end
end
function modwarn(mod, ...)
	modlog(mod, debug.traceback(utilitools.string.concat(...)))
	utilitools.context()
end
print = function(...)
	if mods and mods.utilitools and mods.utilitools.config then
		local mod = mods.utilitools
		if mod.config.isolateLogs == false then forceprint(...) end
		if mod.config.unknownPrints == true then forceprint(debug.traceback("Traceback", 1)) end
	else forceprint(...) end
end

-- Penta: just putting this here...
love.keyboard.setTextInput(true)
