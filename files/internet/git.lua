local git = {
	restApiUrl = "https://api.github.com/"
}

function git.buildUrl(url, data)
	local v = ""
	local i = url:find("{", 1, true)

	if not i then return url end

	local j = 0
	while i do
		v = v .. url:sub(j + 1, i - 1)

		j = url:find("}", i + 1, true)
		if j then
			local optional = url:sub(i + 1, i + 1) == "/"
			local key = url:sub(i + (optional and 2 or 1), j - 1)
			if not data[key] then
				if optional then return v else modwarn(mod, "No key", url, data) return false end
			end

			v = v .. data[key]
		else modwarn(mod, "Invalid", url, data) return false end
		i = url:find("{", j + 1, true)
	end
	return v
end
function git.restApiRequest(user, repo, endPoint, rerequest, fileType) -- unused
	local url
	local gitType = "application/vnd.github+json"
	local type = "json"
	local repoSummary

	if endPoint ~= "repo" then
		local success
		success, repoSummary = git.restApiRequest(user, repo, "repo")
		if not success then return false end
	end

	local endPoints = {
		repo = { url = git.restApiUrl .. "repos/{user}/{repo}" }
	}

	if not endPoints[endPoint] then return false end

	url = git.buildUrl(endPoints[endPoint].url, { user = user, repo = repo })
	gitType = endPoints[endPoint].gitType or gitType
	type = endPoints[endPoint].type or type

	local headers
	headers = {
		["User-Agent"] = "Pentatrate/utilitools (" .. mods.utilitools.version .. ")",
		Accept = gitType
	}
	return utilitools.internet.request(url, type, rerequest, headers)
end

return git