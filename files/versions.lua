local versions = {}

versions.convert = function(v)
	return utilitools.string.split(v, "%.")
end
versions.check = function(base, other, func)
	base = versions.convert(base)
	other = versions.convert(other)
	for i, a in ipairs(base) do
		if func(a, other[i] or 0) then
			return true
		end
	end
	if #base < #other then
		for i = #base + 1, #other do
			if func(0, other[i]) then
				return true
			end
		end
	end
	return false
end
versions.equal = function(base, other) return versions.check(base, other, function(a, b) return a == b end) end
versions.less = function(base, other) return versions.check(base, other, function(a, b) return a < b end) end
versions.more = function(base, other) return versions.check(base, other, function(a, b) return a > b end) end
versions.lessEquals = function(...) return not versions.more(...) end
versions.moreEquals = function(...) return not versions.less(...) end
versions["="] = versions.equal
versions["<"] = versions.less
versions[">"] = versions.more
versions["<="] = versions.lessEquals
versions[">="] = versions.moreEquals
versions.fromTil = function(base, min, max) return versions["<="](min, base) and versions["<="](base, max) end
versions.between = function(base, min, max) return versions["<"](min, base) and versions["<"](base, max) end
versions.compare = function(base, operation, other, other2)
	return versions[operation](base, other, other2)
end

return versions
