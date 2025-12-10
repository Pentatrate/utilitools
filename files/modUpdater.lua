local modUpdater = {
	fileCache = {}
}

modUpdater.getSub = function(mod)
	if type(mod) ~= "table" then error("modUpdater.getSub: expected table for mod") end
	return utilitools.modLinks[version][mod.id].organisation .. "/" .. utilitools.modLinks[version][mod.id].repository
end
modUpdater.releaseData = function(mod, redownload)
	if type(mod) ~= "table" then error("modUpdater.releaseData: expected table for mod") end

	local url = "https://api.github.com/repos/" .. modUpdater.getSub(mod) .. "/releases/latest"

	local rawData = utilitools.internet.request(url, "json", redownload)
	if rawData == nil then return end

	return rawData
end
modUpdater.branch = function(mod, branch)
	if type(mod) ~= "table" then error("modUpdater.branch: expected table for mod") end
	branch = branch or mods.utilitools.config.branches[mod.id]
	if branch and ((branch == "      " and modUpdater.releaseData(mod) and modUpdater.releaseData(mod).name ~= nil) or (branch ~= "      " and utilitools.modLinks[version][mod.id]["branch"][branch])) then return branch end
	local defaultBranch = mod.config.branch or mods.utilitools.config.defaultBranch
	if defaultBranch == "      " and (modUpdater.releaseData(mod) == nil or modUpdater.releaseData(mod).name == nil) then
		return "main"
	end
	return mod.config.branch or mods.utilitools.config.defaultBranch
end

modUpdater.getModInfo = function(mod, recheck)
	if type(mod) ~= "table" then error("modUpdater.checkModVersion: expected table for mod") end

	if recheck or modUpdater.fileCache[mod.id] == nil then
		modUpdater.fileCache[mod.id] = dpf.loadJson(utilitools.folderManager.modPath(mod) .. "/mod.json")
	end
	return modUpdater.fileCache[mod.id]
end

-- downloading
modUpdater.changeMessage = function(mod, branch, redownload)
	if type(mod) ~= "table" then error("modUpdater.downloadLink: expected table for mod") end
	branch = modUpdater.branch(mod, branch)

	if branch == "      " then
		if modUpdater.releaseData(mod, redownload) == nil then return end
		return modUpdater.releaseData(mod).name .. "\n" .. modUpdater.releaseData(mod).body
	else
		return utilitools.internet.request("https://api.github.com/repos/" .. modUpdater.getSub(mod) .. "/commits/" .. branch, "json", redownload).commit.message
	end
end
modUpdater.downloadLink = function(mod, branch)
	if type(mod) ~= "table" then error("modUpdater.downloadLink: expected table for mod") end
	branch = modUpdater.branch(mod, branch)

	if branch == "      " then
		if modUpdater.releaseData(mod) == nil then return end
		for _, v in ipairs(modUpdater.releaseData(mod).assets) do
			if v.name:sub(-#".zip") == ".zip" then
				return v.browser_download_url
			end
		end
		return modUpdater.releaseData(mod).assets[1].browser_download_url
	else
		return "https://github.com/" .. modUpdater.getSub(mod) .. "/archive/refs/heads/" .. branch .. ".zip"
	end
end
modUpdater.directDownloadMod = function(mod, url, onlyCompare, force, redownload, message)
	if type(mod) ~= "table" then error("modUpdater.directDownloadMod: expected table for mod") end

	local rawData = utilitools.internet.request(url, nil, redownload)
	if rawData == nil then return end

	local fileData = love.filesystem.newFileData(rawData, "modZip.zip")
	love.filesystem.mount(fileData, "modZip")
	for _, fileName in pairs(love.filesystem.getDirectoryItems("modZip")) do
		local path = utilitools.folderManager.modPath(mod)
		local downloadPath = "modZip/" .. fileName
		local newConfigs
		if not force or not beatblockPlus2_0Update then
			newConfigs = dpf.loadJson(downloadPath .. "/mod.json")
			newConfigs.config = mod.config
			dpf.saveJson(downloadPath .. "/mod.json", newConfigs)
		end
		if force or utilitools.versions.more(newConfigs.version, modUpdater.getModInfo(mod).version) then
			if onlyCompare then
				forceprint("Comparing " .. mod.name .. " (" .. modUpdater.getModInfo(mod).version .. ") by " .. mod.author)
				forceprint("Same content: " .. tostring(utilitools.folderManager.compare(path, downloadPath, true, true)))
				forceprint("Same content: " .. tostring(utilitools.folderManager.compare(downloadPath, path, true, true)))
			else
				mods.utilitools.config.updated.hasUpdated = true
				mods.utilitools.config.updated.mods = mods.utilitools.config.updated.mods or {}
				mods.utilitools.config.updated.mods[mod.id] = {
					oldVersion = modUpdater.getModInfo(mod).version,
					version = newConfigs.version,
					message = message
				}
				utilitools.folderManager.delete(path, true)
				utilitools.folderManager.copy(path, downloadPath, true)
				modUpdater.fileCache[mod.id] = nil
				forceprint("Downloaded mod " .. mod.id)
			end
		else
			log(mod, "No new mod version for " .. mod.id .. " (current: " .. modUpdater.getModInfo(mod).version .. " >= downloaded: " .. newConfigs.version .. ")")
		end
		break
	end
	love.filesystem.unmount("modZip.zip")
end
modUpdater.downloadMod = function(mod, branch, onlyCompare, force, redownload)
	if type(mod) ~= "table" then error("modUpdater.downloadMod: expected table for mod") end
	branch = modUpdater.branch(mod, branch)
	modUpdater.directDownloadMod(mod, modUpdater.downloadLink(mod, branch), onlyCompare, force, redownload, modUpdater.changeMessage(mod, branch, redownload))
end

-- scanning
modUpdater.getModVersion = function (mod, branch, redownload)
	if type(mod) ~= "table" then error("modUpdater.getModVersion: expected table for mod") end
	branch = modUpdater.branch(mod, branch)

	if branch ~= "      " then
		local url = "https://raw.githubusercontent.com/" .. modUpdater.getSub(mod) .. "/refs/heads/" .. branch .. "/mod.json"

		local rawData = utilitools.internet.request(url, "json", redownload)
		if rawData == nil then return end
		return rawData.version
	else
		if modUpdater.releaseData(mod) == nil then return end
		return modUpdater.releaseData(mod).tag_name
	end
end
modUpdater.checkModVersion = function (mod, branch, redownload)
	if type(mod) ~= "table" then error("modUpdater.checkModVersion: expected table for mod") end
	branch = modUpdater.branch(mod, branch)

	local version = modUpdater.getModVersion(mod, branch, redownload)
	if version == nil then return end
	return utilitools.versions.more(version, modUpdater.getModInfo(mod).version)
end
modUpdater.checkModVersions = function(redownload)
	local r1 = false
	local r2 = {}
	for modId, mod in pairs(mods) do
		if utilitools.modLinks[version][modId] then
			if mods.utilitools.config.updates[modId] ~= false and modUpdater.checkModVersion(mod, nil, redownload) then
				forceprint(modId)
				r1 = true
				r2[modId] = true
			end
		end
	end
	return r1, r2
end
modUpdater.updateMods = function(redownload)
	if mod.config.autoUpdate == false then
		log(mod, "modUpdater.updateMods: autoUpdate is false")
	end
	local outdated, outdatedMods = modUpdater.checkModVersions(redownload)
	if outdated then
		for modId, _ in pairs(outdatedMods) do
			log(mod, "modUpdater.updateMods: Updating " .. modId)
			modUpdater.downloadMod(mods[modId], nil, false, false, redownload)
		end
		return true
	else
		log(mod, "modUpdater.updateMods: All mods up to date")
	end
end

return modUpdater