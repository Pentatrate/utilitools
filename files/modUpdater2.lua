local modUpdater2 = {
	latestVersions = {},
	fileVersions = {},
	commitMsgs = {},
	downloads = {}
}

function modUpdater2.hasCache(cache, mod, org, branch) -- success, exists, rawData
	if not modUpdater2[cache] then
		return false, utilitools.string.concat("modUpdater2.initCache: cache doesnt exist for", cache)
	end

	if org then
		if modUpdater2[cache][mod.id] and modUpdater2[cache][mod.id][org] and modUpdater2[cache][mod.id][org][branch] then
			if not modUpdater2[cache][mod.id][org][branch].success then
				return false, utilitools.string.concat("modUpdater2.hasCache: already failed for", mod.id)
			end
			return true, true, modUpdater2[cache][mod.id][org][branch].raw
		end
		return true, false
	else
		if modUpdater2[cache][mod.id] then
			if not modUpdater2[cache][mod.id].success then
				return false, utilitools.string.concat("modUpdater2.hasCache: already failed for", mod.id)
			end
			return true, true, modUpdater2[cache][mod.id].raw
		end
		return true, false
	end
end
function modUpdater2.initCache(cache, mod, org, branch) -- success
	if not modUpdater2[cache] then
		return false, utilitools.string.concat("modUpdater2.initCache: cache doesnt exist for", cache)
	end

	modUpdater2[cache][mod.id] = modUpdater2[cache][mod.id] or {}
	if org then
		modUpdater2[cache][mod.id][org] = modUpdater2[cache][mod.id][org] or {}
		modUpdater2[cache][mod.id][org][branch] = modUpdater2[cache][mod.id][org][branch] or {}
		modUpdater2[cache][mod.id][org][branch].success = false
		modUpdater2[cache][mod.id][org][branch].raw = nil
	else
		modUpdater2[cache][mod.id].success = false
		modUpdater2[cache][mod.id].raw = nil
	end
	return true
end
function modUpdater2.successCache(cache, mod, org, branch, rawData) -- success
	if not modUpdater2[cache] then
		return false, utilitools.string.concat("modUpdater2.initCache: cache doesnt exist for", cache)
	end

	if org then
		modUpdater2[cache][mod.id][org][branch].success = true
		modUpdater2[cache][mod.id][org][branch].raw = rawData
	else
		modUpdater2[cache][mod.id].success = true
		modUpdater2[cache][mod.id].raw = rawData
	end
	return true
end
function modUpdater2.resetCache(cache, mod, org, branch) -- success
	if not modUpdater2[cache] then
		return false, utilitools.string.concat("modUpdater2.initCache: cache doesnt exist for", cache)
	end

	if org then
		if modUpdater2[cache][mod.id] and modUpdater2[cache][mod.id][org] and modUpdater2[cache][mod.id][org][branch] then
			modUpdater2[cache][mod.id][org][branch] = nil
		end
	else
		if modUpdater2[cache][mod.id] then
			modUpdater2[cache][mod.id] = nil
		end
	end
	return true
end

function modUpdater2.getData(mod) -- success, org, repo, branch, fork
	if type(mod) ~= "table" then
		return false, utilitools.string.concat("modUpdater2.getData: mod type", type(mod), "isnt a table")
	end
	if not mods[mod.id] then
		return false, utilitools.string.concat("modUpdater2.getData: mod", mod.id, "isnt a mod")
	end
	if not utilitools.modLinks[mod.id] then
		return false, utilitools.string.concat("modUpdater2.getData: mod", mod.id, "isnt linked up")
	end

	local org
	local fork = mods.utilitools.config.forks[mod.id]
	local branches
	local defaultBranch
	if fork and utilitools.modLinks[mod.id].fork and utilitools.modLinks[mod.id].fork[fork] then
		branches = utilitools.modLinks[mod.id].fork[fork].branch
		defaultBranch = utilitools.modLinks[mod.id].fork[fork].default
		org = fork
	else
		branches = utilitools.modLinks[mod.id].branch
		defaultBranch = utilitools.modLinks[mod.id].default
		org = utilitools.modLinks[mod.id].organisation
		fork = nil
	end
	if type(branches) ~= "table" then
		return false, utilitools.string.concat("modUpdater2.getData: mod", mod.id, "has fork", fork, "with invalid branch links")
	end
	if utilitools.table.emptyTable(branches) then
		return false, utilitools.string.concat("modUpdater2.getData: mod", mod.id, "has fork", fork, "with no branches")
	end

	local branch = mods.utilitools.config.branches[mod.id]
	-- checks for if branch exists
	if not (branch and branches[branch]) then branch = mods.utilitools.config.defaultBranch end
	if not (branch and branches[branch]) then branch = defaultBranch end
	if not (branch and branches[branch]) then
		return false, utilitools.string.concat("modUpdater2.getData: mod", mod.id, "has fork", fork, "with invalid default branch")
	end

	return true, org, utilitools.modLinks[mod.id].repository, branch, fork
end

function modUpdater2.getFile(mod) -- success, rawData
	local data = { modUpdater2.getData(mod) } if not data[1] then return unpack(data) end

	data = { modUpdater2.hasCache("fileVersions", mod) } if not data[1] then return unpack(data) end
	local _, exists, rawData = unpack(data)
	if exists then return true, rawData end

	data = { modUpdater2.initCache("fileVersions", mod) } if not data[1] then return unpack(data) end

	local success, error = utilitools.try(mod, function()
		rawData = dpf.loadJson(utilitools.folderManager.modPath(mod) .. "/mod.json")
	end)
	if not success then return false, error end

	if type(rawData) ~= "table" then
		return false, utilitools.string.concat("modUpdater2.getFile: file mod json of", mod.id, "is invalid")
	end

	data = { modUpdater2.successCache("fileVersions", mod, nil, nil, rawData) } if not data[1] then return unpack(data) end
	return true, rawData
end
function modUpdater2.getFileVersion(mod) -- success, fileVersion
	local data = { modUpdater2.getFile(mod) } if not data[1] then return unpack(data) end
	local _, rawData = unpack(data)

	---@diagnostic disable-next-line: need-check-nil, undefined-field
	if type(rawData.version) ~= "string" then
		return false, utilitools.string.concat("modUpdater2.getFile: file version of", mod.id, "is invalid")
	end

	---@diagnostic disable-next-line: need-check-nil, undefined-field
	return true, rawData.version
end
function modUpdater2.resetFile(mod) -- success
	local data = { modUpdater2.getData(mod) } if not data[1] then return unpack(data) end

	data = { modUpdater2.resetCache("fileVersions", mod) } if not data[1] then return unpack(data) end
	return true
end

function modUpdater2.getLink(typ, mod) -- success, url, typ2
	local data = { modUpdater2.getData(mod) } if not data[1] then return unpack(data) end
	local _, org, repo, branch = unpack(data)
	local types = {
		commitModJson = "https://raw.githubusercontent.com/%s/%s/%s/mod.json",
		commitDownload = "https://github.com/%s/%s/archive/%s.zip",
		commitMsg = "https://api.github.com/repos/%s/%s/commits/%s" -- potential ratelimit
	}
	local types2 = {
		commitModJson = "json",
		commitDownload = nil,
		commitMsg = "json"
	}
	if types[typ] then
		return true, string.format(types[typ], org, repo, branch), types2[typ]
	end
	return false, utilitools.string.concat("modUpdater2.getLink: type", typ, "doesnt exist")
end
function modUpdater2.runLink(typ, mod, redownload) -- success, rawData, headers
	local data = { modUpdater2.getLink(typ, mod) } if not data[1] then return unpack(data) end
	local success, url, typ2 = unpack(data)

	if mods.utilitools.config.dontUseInternet then
		return false, utilitools.string.concat("modUpdater2.runLink: internet is disabled")
	end

	local rawData, headers, requestError
	success, rawData, headers, requestError = utilitools.internet.request(url, typ2, redownload, { ["User-Agent"] = "Pentatrate/utilitools (" .. mods.utilitools.version .. ")" })
	if not success then
		return false, requestError
	end
	return true, rawData, headers
end

function modUpdater2.getLatest(mod) -- success, rawData
	local data = { modUpdater2.getData(mod) } if not data[1] then return unpack(data) end
	local _, org, branch
	_, org, _, branch, _ = unpack(data)

	data = { modUpdater2.hasCache("latestVersions", mod, org, branch) } if not data[1] then return unpack(data) end
	local exists, rawData
	_, exists, rawData = unpack(data)
	if exists then return true, rawData end

	data = { modUpdater2.initCache("latestVersions", mod, org, branch) } if not data[1] then return unpack(data) end

	data = { modUpdater2.runLink("commitModJson", mod) } if not data[1] then return unpack(data) end
	_, rawData = unpack(data)

	if type(rawData) ~= "table" then
		return false, utilitools.string.concat("modUpdater2.getLatest: latest mod json of", mod.id, "is invalid")
	end

	data = { modUpdater2.successCache("latestVersions", mod, org, branch, rawData) } if not data[1] then return unpack(data) end
	return true, rawData
end
function modUpdater2.hasLatest(mod) -- success, boolean
	local data = { modUpdater2.getData(mod) } if not data[1] then return unpack(data) end
	local _, org, branch
	_, org, _, branch, _ = unpack(data)

	data = { modUpdater2.hasCache("latestVersions", mod, org, branch) } if not data[1] then return unpack(data) end
	local exists
	_, exists = unpack(data)
	if exists then return true, true end

	return true, false
end
function modUpdater2.getLatestVersion(mod) -- success, latestVersion
	local data = { modUpdater2.getLatest(mod) } if not data[1] then return unpack(data) end
	local _, rawData = unpack(data)

	---@diagnostic disable-next-line: need-check-nil, undefined-field
	if type(rawData.version) ~= "string" then
		return false, utilitools.string.concat("modUpdater2.getLatestVersion: latest version of", mod.id, "is invalid")
	end

	---@diagnostic disable-next-line: need-check-nil, undefined-field
	return true, rawData.version
end

function modUpdater2.hasLaterVersion(mod) -- success, boolean
	local data = { modUpdater2.getFileVersion(mod) } if not data[1] then return unpack(data) end
	local _, fileVersion = unpack(data)

	data = { modUpdater2.getLatestVersion(mod) } if not data[1] then return unpack(data) end
	local latestVersion
	_, latestVersion = unpack(data)

	return true, utilitools.versions.greaterThan(latestVersion, fileVersion)
end
function modUpdater2.onLatestVersion(mod) -- success, boolean
	local data = { modUpdater2.getFileVersion(mod) } if not data[1] then return unpack(data) end
	local _, fileVersion = unpack(data)

	data = { modUpdater2.getLatestVersion(mod) } if not data[1] then return unpack(data) end
	local latestVersion
	_, latestVersion = unpack(data)

	return true, utilitools.versions.equalTo(latestVersion, fileVersion)
end
function modUpdater2.onSameFiles(mod) -- success, boolean
	local data = { modUpdater2.getFileVersion(mod) } if not data[1] then return unpack(data) end
	local _, fileVersion = unpack(data)

	return true, utilitools.versions.equalTo(mod.version, fileVersion)
end

function modUpdater2.getCommit(mod) -- success, rawData
	local data = { modUpdater2.getData(mod) } if not data[1] then return unpack(data) end
	local _, org, branch
	_, org, _, branch, _ = unpack(data)

	data = { modUpdater2.hasCache("commitMsgs", mod, org, branch) } if not data[1] then return unpack(data) end
	local exists, rawData
	_, exists, rawData = unpack(data)
	if exists then return true, rawData end

	data = { modUpdater2.initCache("commitMsgs", mod, org, branch) } if not data[1] then return unpack(data) end

	data = { modUpdater2.runLink("commitMsg", mod) } if not data[1] then return unpack(data) end
	_, rawData = unpack(data)

	if type(rawData) ~= "table" then
		return false, utilitools.string.concat("modUpdater2.getCommit: commit of", mod.id, "is invalid")
	end

	data = { modUpdater2.successCache("commitMsgs", mod, org, branch, rawData) } if not data[1] then return unpack(data) end
	return true, rawData
end
function modUpdater2.getCommitMsg(mod) -- success, msg
	local data = { modUpdater2.getCommit(mod) } if not data[1] then return unpack(data) end
	local _, rawData = unpack(data)

	---@diagnostic disable-next-line: need-check-nil, undefined-field
	if type(rawData.commit) ~= "table" then
		return false, utilitools.string.concat("modUpdater2.getCommitMsg: commit data of", mod.id, "is invalid")
	end
	---@diagnostic disable-next-line: need-check-nil, undefined-field
	if type(rawData.commit.message) ~= "string" then
		return false, utilitools.string.concat("modUpdater2.getCommitMsg: commit message of", mod.id, "is invalid")
	end

	---@diagnostic disable-next-line: need-check-nil, undefined-field
	return true, rawData.commit.message
end

function modUpdater2.getDownload(mod) -- success, rawData
	local data = { modUpdater2.getData(mod) } if not data[1] then return unpack(data) end
	local _, org, branch
	_, org, _, branch, _ = unpack(data)

	data = { modUpdater2.hasCache("downloads", mod, org, branch) } if not data[1] then return unpack(data) end
	local exists, rawData
	_, exists, rawData = unpack(data)
	if exists then return true, rawData end

	data = { modUpdater2.initCache("downloads", mod, org, branch) } if not data[1] then return unpack(data) end

	data = { modUpdater2.runLink("commitDownload", mod) } if not data[1] then return unpack(data) end
	_, rawData = unpack(data)

	if not rawData then
		return false, utilitools.string.concat("modUpdater2.getDownload: download of", mod.id, "is invalid")
	end

	data = { modUpdater2.successCache("downloads", mod, org, branch, rawData) } if not data[1] then return unpack(data) end
	return true, rawData
end
function modUpdater2.installDownload(mod, getMsg) -- success
	local data = { modUpdater2.getDownload(mod) } if not data[1] then return unpack(data) end
	local _, rawData = unpack(data)

	data = { modUpdater2.getFileVersion(mod) } if not data[1] then return unpack(data) end
	local fileVersion
	_, fileVersion = unpack(data)

	data = { modUpdater2.getLatestVersion(mod) } if not data[1] then return unpack(data) end
	local latestVersion
	_, latestVersion = unpack(data)

	local msg = ""
	if getMsg then
		data = { modUpdater2.getCommitMsg(mod) } if not data[1] then return unpack(data) end
		---@diagnostic disable-next-line: cast-local-type
		_, msg = unpack(data)
	end

	local fileData = love.filesystem.newFileData(rawData, "modZip.zip")
	love.filesystem.mount(fileData, "modZip")
	for _, fileName in pairs(love.filesystem.getDirectoryItems("modZip")) do
		local currentPath = utilitools.folderManager.modPath(mod)
		local downloadPath = "modZip/" .. fileName

		if getMsg then
			mods.utilitools.config.updated.hasUpdated = true
			mods.utilitools.config.updated.mods = mods.utilitools.config.updated.mods or {}
			mods.utilitools.config.updated.mods[mod.id] = {
				oldVersion = fileVersion,
				version = latestVersion,
				message = msg
			}
		end

		utilitools.folderManager.delete(currentPath, true)
		utilitools.folderManager.copy(currentPath, downloadPath, true, false, utilitools.mods[mod.id] and utilitools.mods[mod.id].ignore)

		modUpdater2.resetFile(mod)

		modlog(mods.utilitools, "Downloaded mod", mod.id)
		break
	end

	love.filesystem.unmount("modZip.zip")
	return true
end

function modUpdater2.getOutdatedMods() -- success, oneOutdated, outdatedMods
	local oneOutdated = false
	local outdatedMods = {}
	for modId, mod in pairs(mods) do
		if utilitools.modLinks[modId] and mods.utilitools.config.updates[modId] ~= false then
			local data = { modUpdater2.hasLaterVersion(mod) } if not data[1] then return unpack(data) end
			local _, outdated = unpack(data)
			if outdated then
				oneOutdated = true
				outdatedMods[modId] = mod
			end
		end
	end
	return true, oneOutdated, outdatedMods
end
function modUpdater2.updateOutdatedMods() -- success
	local data = { modUpdater2.getOutdatedMods() } if not data[1] then return unpack(data) end
	local _, oneOutdated, outdatedMods = unpack(data)

	local close = false
	if oneOutdated then
		---@diagnostic disable-next-line: param-type-mismatch
		for modId, mod in pairs(outdatedMods) do
			if mods.utilitools.config.autoUpdate then
				data = { modUpdater2.installDownload(mod, true) } if not data[1] then return unpack(data) end
			else
				local buttonPressed = love.window.showMessageBox("Utilitools", "The mod \"" .. mods[modId].name .. "\" is out of date.\nPlease update it manually", { "Close game", "Continue launch" })
				if buttonPressed == 1 then close = true end
			end
		end
	else
		modlog(mod, "modUpdater2.updateOutdatedMods: All mods up to date")
	end
	if close then love.event.quit() end
	return true, oneOutdated
end

return modUpdater2