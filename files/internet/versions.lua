local versions = {}

versions.convert = function(v)
	local r = utilitools.string.split(v, "%.")
	for i, n in ipairs(r) do
		r[i] = tonumber(n:match("%d+"))
	end
	return r
end
versions.check = function(base, other, func, notOther)
	base = versions.convert(base)
	other = versions.convert(other)
	for i, a in ipairs(base) do
		if func(a, other[i] or 0) then return true end
		if not notOther and func(other[i] or 0, a) then return false end
	end
	if #base < #other then
		for i = #base + 1, #other do
			if func(0, other[i]) then return true end
			if not notOther and func(other[i], 0) then return false end
		end
	end
	return false
end
versions.equalTo = function(base, other) return not versions.check(base, other, function(a, b) return a ~= b end) end
versions.lessThan = function(base, other) return versions.check(base, other, function(a, b) return a < b end) end
versions.greaterThan = function(base, other) return versions.check(base, other, function(a, b) return a > b end) end
versions.lessThanOrEqualTo = function(...) return not versions.greaterThan(...) end
versions.moreThanOrEqualTo = function(...) return not versions.lessThan(...) end
versions["="] = versions.equalTo
versions["<"] = versions.lessThan
versions[">"] = versions.greaterThan
versions["<="] = versions.lessThanOrEqualTo
versions[">="] = versions.moreThanOrEqualTo
versions.fromTil = function(base, min, max) return versions["<="](min, base) and versions["<="](base, max) end
versions.between = function(base, min, max) return versions["<"](min, base) and versions["<"](base, max) end
versions.compare = function(base, operation, other, other2)
	return versions[operation](base, other, other2)
end

return versions
