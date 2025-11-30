-- Penta: I made this for fun, I dont think it's faster or anything lol
local jsonReader = {}
local index = 0
local nextIndex
local contents = ""
local indent = 0
local allowed = { [" "] = true, ["\t"] = true, ["\n"] = true }
local numberChars = {}
local readNext

local function getIndent()
	return (" "):rep(3 * indent)
end
local function advance()
	while allowed[contents:sub(index + 1, index + 1)] do
		index = index + 1
	end
end
local function lookFor(s, requireDataBetween, expect)
	local tempIndex = index
	local firstIndex
	nextIndex = nil
	if not requireDataBetween then
		-- forceprint(getIndent() .. s .. " | " .. contents:sub(tempIndex + 1, tempIndex + #s))
		if contents:sub(tempIndex + 1, tempIndex + #s) == s then
			firstIndex = tempIndex + 1
			nextIndex = tempIndex + #s
		end
	else
		local iterate = true
		local iterations = 0
		while iterate and iterations < 10 do
			iterate = false
			iterations = iterations + 1
			firstIndex, nextIndex = string.find(contents, s, tempIndex + 1, true)
			if nextIndex and string.sub(contents, firstIndex - 1, firstIndex - 1) == "\\" then
				tempIndex = nextIndex + 1
				iterate = true
			end
		end
		if iterations >= 10 then forceprint(getIndent() .. s .. " | Exceeded iteration limit") end
	end
	if nextIndex then
		-- forceprint(getIndent() .. s .. " | found: " .. index + 1 .. " " .. firstIndex - 1 .. " " .. tostring(requireDataBetween) .. " " .. tostring(expect))
		local dataBetween
		if requireDataBetween then dataBetween = string.sub(contents, index + 1, firstIndex - 1) end
		if expect then index = nextIndex end
		if requireDataBetween then return dataBetween end
		return index
	elseif expect then
		error(expect)
	end
end
local function readString()
	-- forceprint(getIndent() .. "start string") indent = indent + 1
	local data = lookFor('"', true, 'String: Expected closing >"<')
	-- forceprint(getIndent() .. "string: " .. tostring(data))
	-- indent = indent - 1 forceprint(getIndent() .. "end string")
	return tostring(data)
end
local function readNumber()
	nextIndex = index
	if string.sub(contents, nextIndex, nextIndex) == "-" then nextIndex = nextIndex + 1 end
	if string.sub(contents, nextIndex, nextIndex) == "0" then
		nextIndex = nextIndex + 1
	else
		if not numberChars[string.sub(contents, nextIndex, nextIndex)] then error("Number: Expected digits") end
		while numberChars[string.sub(contents, nextIndex, nextIndex)] do nextIndex = nextIndex + 1 end
	end
	if string.sub(contents, nextIndex, nextIndex) == "." then
		if not numberChars[string.sub(contents, nextIndex, nextIndex)] then error("Number: Expected decimal digits") end
		while numberChars[string.sub(contents, nextIndex, nextIndex)] do nextIndex = nextIndex + 1 end
	end
	nextIndex = nextIndex - 1
	local number = tonumber(string.sub(contents, index, nextIndex))
	index = nextIndex
	-- forceprint(getIndent() .. "number: " .. tostring(number))
	return number
end
local function readObject()
	-- forceprint(getIndent() .. "start object") indent = indent + 1
	local table = {}
	local iterate = true
	while iterate do
		iterate = false
		advance()
		if lookFor('"') then
			-- forceprint(getIndent() .. "start entry") indent = indent + 1
			index = nextIndex
			local key = readString()
			advance()
			lookFor(":", false, "Object: Expected >:<")
			table[key] = readNext()
			-- indent = indent - 1 forceprint(getIndent() .. "end entry")
			advance()
			if lookFor(",") then
				index = nextIndex
				iterate = true
			end
		end
	end
	advance()
	lookFor("}", false, "Object: Expected closing >}<")
	-- indent = indent - 1 forceprint(getIndent() .. "end object")
	return table
end
local function readArray()
	-- forceprint(getIndent() .. "start array") indent = indent + 1
	local table = {}
	local iterate = true
	local iterations = 0
	while iterate and iterations < 10 do
		iterate = false
		iterations = iterations + 1
		advance()
		table[iterations] = readNext()
		advance()
		if lookFor(",") then
			index = nextIndex
			iterate = true
		end
	end
	advance()
	lookFor("]", false, "Object: Expected closing >]<")
	-- indent = indent - 1 forceprint(getIndent() .. "end array")
	return table
end
local doForCheck = {
	['"'] = readString,
	["{"] = readObject,
	["["] = readArray,
	["-"] = readNumber,
	["null"] = function()
		-- forceprint(getIndent() .. "nil: nil")
		return nil
	end,
	["true"] = function()
		-- forceprint(getIndent() .. "boolean: true")
		return true
	end,
	["false"] = function()
		-- forceprint(getIndent() .. "boolean: false")
		return false
	end
}
for i = 0, 9 do
	doForCheck[tostring(i)] = readNumber
	numberChars[tostring(i)] = true
end
readNext = function()
	-- forceprint(getIndent() .. "start read") indent = indent + 1
	advance()
	for check, func in pairs(doForCheck) do
		if lookFor(check) then
			forceprint("loading " .. check)
			index = nextIndex
			return func()
		end
	end
	error("Expecting value, found nothing")
	-- indent = indent - 1 forceprint(getIndent() .. "end read")
end
jsonReader.readJson = function(path)
	if love.filesystem.getInfo(path, "file") then
		local size
		contents, size = love.filesystem.read("string", path)
		index = 0
		local result = readNext()
		forceprint(contents)
		forceprint(json.encode(result))
		return result
	else
		error("File " .. path .. " not found")
	end
end

-- utilitools.try(mod, function()
-- 	jsonReader.readJson("Custom Levels/###test/manifest.json")
-- end)