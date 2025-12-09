local st = Gamestate:new('UtilitoolsModCheck')

st:setInit(function(self)
	self.errorSprite = ez.newjson("assets/error/error"):instance()
	shuv.resetPal()
	te.play("assets/music/caution.ogg", "stream", "music")

	local function addText(text) self.text = self.text .. text end
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
	self.text = ""
	addText("Mod Checks:\n")
	if utilitools.modChecks.dependencies then
		addText("\n--==--\n\nDependencies:\n")
		for modId, mods2 in pairs(utilitools.dependencies) do
			addText("\n[" .. modId .. "] " .. mods[modId].name .. " (" .. mods[modId].version .. ") by " .. mods[modId].author .. " requires:\n")
			for modId2, data in pairs(mods2) do
				addText("-> " .. modId2)
				if mods[modId2] then
					addText(" (currently " .. mods[modId2].version .. ")")
				end
                if data.reason then
                    addText(": " .. data.reason)
                end
				if data.versions then
                    addText("\nVersion must be ")
                    for i, v in ipairs(data.versions) do
                        if i ~= 1 then addText(" or ") end
						if v[1] == "fromTil" then
							addText("from " .. v[2] .. " til " .. v[3])
						elseif v[1] == "between" then
							addText("between " .. v[2] .. " and " .. v[3])
						elseif v[1] == "=" or v[1] == "equal" then
							addText(v[2])
						elseif preWords[v[1]] then
							addText(preWords[v[1]] .. " " .. v[2])
						elseif sufWords[v[1]] then
							addText(v[2] .. " " .. sufWords[v[1]])
						else
							addText(v[1] .. " " .. v[2])
						end
					end
				end
				addText("\n")
			end
		end
	end
    if utilitools.modChecks.incompatibilities then
		addText("\n--==--\n\nIncompatibilities:\n")
		for modId, mods2 in pairs(utilitools.incompatibilities) do
			addText("\n" .. mods[modId].name .. " (" .. modId .. ") " .. mods[modId].version .. " by " .. mods[modId].author .. " conflicts with:\n")
			for modId2, data in pairs(mods2) do
				addText("-> " .. modId2 .. " (" .. mods[modId2].name .. ") " .. mods[modId2].version .. " by " .. mods[modId2].author)
				if data.reason then
					addText(": " .. data.reason)
				end
				if data.versions then
                    addText("\nVersion cannot be ")
                    for i, v in ipairs(data.versions) do
                        if i ~= 1 then addText(" or ") end
						if v[1] == "fromTil" then
							addText("from " .. v[2] .. " til " .. v[3])
						elseif v[1] == "between" then
							addText("between " .. v[2] .. " and " .. v[3])
						elseif v[1] == "=" or v[1] == "equal" then
							addText(v[2])
						elseif preWords[v[1]] then
							addText(preWords[v[1]] .. " " .. v[2])
						elseif sufWords[v[1]] then
							addText(v[2] .. " " .. sufWords[v[1]])
						else
							addText(v[1] .. " " .. v[2])
						end
					end
				end
				addText("\n")
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
	rtf:drawRich(self.text, project.res.cx, 124, fonts.main, 1, 1, 1, project.res.x, 'center')
end)

st:setFgDraw(function(self) end)

return st
