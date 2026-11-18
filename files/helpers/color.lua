local color = {}

function color.hsvToRgb(h, s, v)
	-- https://en.wikipedia.org/wiki/HSL_and_HSV#Color_conversion_formulae
	local function f(n)
		local k = (n + h / 60) % 6
		return v - v * s * math.max(0, math.min(k, 4 - k, 1))
	end
	return f(5), f(3), f(1)
end

return color
