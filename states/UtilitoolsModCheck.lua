local st = Gamestate:new('UtilitoolsModCheck')

st:setInit(function(self)
	self.errorSprite = ez.newjson("assets/error/error"):instance()
	shuv.resetPal()
	te.play("assets/music/caution.ogg", "stream", "music")

	local function addToError(text) self.modChecks = self.modChecks .. text end
	self.modChecks = ""
	addToError("Mod Checks:\n")
	if utilitools.modChecks.dependencies then
		addToError("\n--==--\n\nDependencies:\n")
		for modId, mods2 in pairs(utilitools.dependencies) do
			addToError("\n" .. mods[modId].name .. " (" .. modId .. ") " .. mods[modId].version .. " by " .. mods[modId].author .. " requires:\n")
			for modId2, data in pairs(mods2) do
				addToError("-> " .. modId2)
				if data.reason then
					addToError(": " .. data.reason)
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
				addToError("\n")
			end
		end
	end
end)

st:setUpdate(function(self, dt)
    self.errorSprite:update(dt)
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
