local st = Gamestate:new('UtilitoolsModCheck')

st:setInit(function(self)
	self.errorSprite = ez.newjson("assets/error/error"):instance()
	shuv.resetPal()
	te.play("assets/music/caution.ogg", "stream", "music")

	local function addToError(text) self.modChecks = self.modChecks .. text end
	local preWords = {
		["<"] = "earlier than",
		["less"] = "earlier than",
		[">"] = "later than",
		["more"] = "later than",
	}
	local sufWords = {
		["<="] = "or earlier",
		["lessEquals"] = "or earlier",
		[">="] = "or later",
		["moreEquals"] = "or later"

	}
	self.modChecks = ""
	addToError("Mod Checks:\n")
	if utilitools.modChecks.dependencies then
		addToError("\n--==--\n\nDependencies:\n")
		for modId, mods2 in pairs(utilitools.dependencies) do
			addToError("\n[" .. modId .. "] " .. mods[modId].name .. " (" .. mods[modId].version .. ") by " .. mods[modId].author .. " requires:\n")
			for modId2, data in pairs(mods2) do
				addToError("-> " .. modId2)
                if data.reason then
                    addToError(": " .. data.reason)
                end
				if data.versions then
                    addToError("\nVersion must be ")
                    for i, v in ipairs(data.versions) do
                        if i ~= 1 then addToError(" or ") end
						if v[1] == "fromTil" then
							addToError("from " .. v[2] .. " til " .. v[3])
						elseif v[1] == "between" then
							addToError("between " .. v[2] .. " and " .. v[3])
						elseif v[1] == "=" or v[1] == "equal" then
							addToError(v[2])
						elseif preWords[v[1]] then
							addToError(preWords[v[1]] .. " " .. v[2])
						elseif sufWords[v[1]] then
							addToError(v[2] .. " " .. sufWords[v[1]])
						else
							addToError(v[1] .. " " .. v[2])
						end
					end
				end
				addToError("\n")
			end
		end
	end
    if utilitools.modChecks.incompatibilities then
		addToError("\n--==--\n\nIncompatibilities:\n")
		for modId, mods2 in pairs(utilitools.incompatibilities) do
			addToError("\n" .. mods[modId].name .. " (" .. modId .. ") " .. mods[modId].version .. " by " .. mods[modId].author .. " conflicts with:\n")
			for modId2, data in pairs(mods2) do
				addToError("-> " .. modId2 .. " (" .. mods[modId2].name .. ") " .. mods[modId2].version .. " by " .. mods[modId2].author)
				if data.reason then
					addToError(": " .. data.reason)
				end
				if data.versions then
                    addToError("\nVersion cannot be ")
                    for i, v in ipairs(data.versions) do
                        if i ~= 1 then addToError(" or ") end
						if v[1] == "fromTil" then
							addToError("from " .. v[2] .. " til " .. v[3])
						elseif v[1] == "between" then
							addToError("between " .. v[2] .. " and " .. v[3])
						elseif v[1] == "=" or v[1] == "equal" then
							addToError(v[2])
						elseif preWords[v[1]] then
							addToError(preWords[v[1]] .. " " .. v[2])
						elseif sufWords[v[1]] then
							addToError(v[2] .. " " .. sufWords[v[1]])
						else
							addToError(v[1] .. " " .. v[2])
						end
					end
				end
				addToError("\n")
			end
		end
	end
end)

st:setUpdate(function(self, dt)
    self.errorSprite:update(dt)
	if maininput:pressed("accept") or maininput:pressed("back")then
		te.stop('music')
		love.quit()
		error("Utilitools: Failed to quit game.")
	end
end)

st:setBgDraw(function(self)
	color()
	love.graphics.rectangle('fill', 0, 0, project.res.x, project.res.y)
	self.errorSprite:draw()
	love.graphics.setFont(fonts.main)
    color(1)
	-- text, x, y, font, xscale, yscale, colour, wrapLen, justification, ignoreColour, xSkew, ySkew, extraCharSpacing, rotation, fakeXSkew, fakeYSkew
	rtf:drawRich(self.modChecks, project.res.cx, 124, fonts.main, 1, 1, 1, project.res.x, 'center')
end)

st:setFgDraw(function(self) end)

return st
