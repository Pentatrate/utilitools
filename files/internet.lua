local internet = {
	cache = {},
	httpCodes = {
		[1] = { "Info", {
			[0] = "Continue",
			[1] = "Switching Protocols",
			[2] = "Processing",
			[3] = "Early Hints"
		} },
		[2] = { "Success", {
			[0] = "Ok",
			[1] = "Created",
			[2] = "Accepted",
			[3] = "Non-Authoritative Info",
			[4] = "No Content",
			[5] = "Reset Content",
			[6] = "Partial Content",
			[7] = "Multi Status",
			[8] = "Already Reported",
			[26] = "IM used"
		} },
		[3] = { "Redirect", {
			[0] = "Multiple Choices",
			[1] = "Moved Permanently",
			[2] = "Found",
			[3] = "See Other",
			[4] = "Not Modified",
			[5] = "Use Proxy (deprecated)",
			[6] = "(unused)",
			[7] = "Temporary Redirect",
			[8] = "Permanent Redirect"
		} },
		[4] = { "Client Error", {
			[0] = "Bad Request",
			[1] = "Unauthorized",
			[2] = "Payment Required",
			[3] = "Forbidden",
			[4] = "Not Found",
			[5] = "Method Not Allowed",
			[6] = "Not Acceptible",
			[7] = "Proxy Authentification Required",
			[8] = "Request Timeout",
			[9] = "Conflict",
			[10] = "Gone",
			[11] = "Length Required",
			[12] = "Precondition Failed",
			[13] = "Content Too Large",
			[14] = "URI Too Long",
			[15] = "Unsupported Media Type",
			[16] = "Range Not Satisfiable",
			[17] = "Expectation Failed",
			[18] = "I'm a teapot",
			[21] = "Misdirected Request",
			[22] = "Unprocessable Content",
			[23] = "Locked",
			[24] = "Failed Dependency",
			[25] = "Too Early",
			[26] = "Upgrade Required",
			[28] = "Precondition Required",
			[29] = "Too Many Requests",
			[31] = "Request Header Fields Too Large",
			[51] = "Unavaliable For Legal Reasons"
		} },
		[5] = { "Server Error", {
			[0] = "Internal Server Error",
			[1] = "Not Implemented",
			[2] = "Bad Gateway",
			[3] = "Service Unavaliable",
			[4] = "Gateway Timeout",
			[5] = "HTTP Version Not Supported",
			[6] = "Variant Also Negotiates",
			[7] = "Insufficient Storage",
			[8] = "Loop Detected",
			[10] = "Not Extended",
			[11] = "Network Authentification Required",
		} }
	},
	failureRerequestTime = 120, -- 2 minutes
	types = {
		json = function()
			if utilitools.table.emptyTable(t) then return {} end
			return json.encode(body)
		end
	}
}

function internet.requestError(url, code, body)
	local major = math.floor(code / 100)
	local meaning = internet.httpCodes[major]
	local majorMeaning = meaning and meaning[1] or nil
	local minor = code % 100
	local minorMeaning = meaning and meaning[2] and meaning[2][minor] or nil
	return utilitools.string.concat("Request error: http code ", code, ": ", majorMeaning, ": ", minorMeaning or "not found", " || url: ", url, " || response: ", body)
end
function internet.decode(body, type)
	local r
	if internet.types[type] then
		if utilitools.try(mod, function()
			r = internet.types[type]()
		end) then
			return r
		end
	end
	return body
end
function internet.request(url, type, rerequest, headers, method)
	if mod.config.dontUseInternet then return false end
	local code, body, headersRecieved, time
	local usedCache = false

	local cached = internet.cache[url]
	if not rerequest and cached then
		code, body, headersRecieved, time = cached.code, cached.body, cached.headers, cached.time
		usedCache = true
	else
		code, body, headersRecieved = require("https").request(url, { method = method, headers = headers })
		-- code = 418 body = nil

		time = love.timer.getTime()
		modlog(mod, "URL", url)
		-- modlog(mod, "URL", url, headers, code, body, headersRecieved)
		if code == 200 then
			body = internet.decode(body, type)
			headersRecieved = internet.decode(headersRecieved, "json")
		elseif not usedCache then
			modwarn(mod, internet.requestError(url, code, body))
		end

		local rateLimitHeaders = {
			["x-ratelimit-remaining"] = true,
			["x-ratelimit-used"] = true,
			["x-ratelimit-reset"] = true,
			["x-ratelimit-resource"] = true
		}
		local rateLimitHeadersFound = {}
		local found = false
		for k, _ in pairs(rateLimitHeaders) do if headersRecieved[k] then rateLimitHeadersFound[k] = headersRecieved[k] found = true end end
		if found then modlog(mod, "REQUEST RATE LIMIT STATUS", url, rateLimitHeadersFound) end
		if headersRecieved["x-ratelimit-reset"] then modlog(mod, "REQUEST RATE LIMIT RESET STATUS", headersRecieved["x-ratelimit-reset"], "IN", headersRecieved["x-ratelimit-reset"] - os.time(), "SECONDS, OR", (headersRecieved["x-ratelimit-reset"] - os.time()) / 60, "HOURS") end
		if headersRecieved["x-ratelimit-remaining"] and tonumber(headersRecieved["x-ratelimit-remaining"]) < 1 then mod.config.dontUseInternet = true modwarn(mod, "\n\n\n!!!RATE LIMITED!!!\n\n") end
	end

	internet.cache[url] = { code = code, body = body, headers = headersRecieved, time = time }

	if code == 200 then
		return true, body, headersRecieved
	end
	return false, body, headersRecieved
end

return internet