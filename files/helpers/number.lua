local _number = {}

function _number.round(x, multiplier)
	if type(x) ~= "number" then return end
	return helpers.round(x * multiplier) / multiplier
end
function _number.decimals(x)
	if type(x) ~= "number" then return end
	local decimals = 0
	local decimals2 = 0
	while (x * math.pow(10, decimals)) % 1 ~= 0 do
		decimals = decimals + 1

		local decimal = (x * math.pow(10, decimals)) % 10
		decimal = decimal - decimal % 1
		if decimal ~= 0 then
			if decimal ~= 9 then
				decimals2 = decimals
			else
				local decimal2 = (x * math.pow(10, decimals + 1)) % 10
				decimal2 = decimal2 - decimal2 % 1
				if decimal2 < 5 then
					decimals2 = decimals
				end
			end
		end
		if decimals >= 12 then return decimals2 end
	end
	return decimals
end

return _number
