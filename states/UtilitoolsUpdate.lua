local st = Gamestate:new('UtilitoolsModCheck')

st:setInit(function(self)
	self.errorSprite = ez.newjson("assets/error/error"):instance()
	shuv.resetPal()
	te.play("assets/music/fishing/fishinAmbient.ogg", "stream", "music")

	local function addText(text) self.text = self.text .. text end
	self.text = "Updated mods (press accept or back to continue):"
	local amount = 0
	for k, v in pairs(mods.utilitools.config.updated.mods or {}) do
		local mod = mods[k]
		if mod and utilitools.versions.equal(v.version, mod.version) then
			addText("\n\n- " .. mod.name .. " by " .. mod.author .. "\nupdated from " .. v.oldVersion .. " to " .. v.version)
			if v.message then
				addText("\n-----=====#=====-----\n")
				addText(v.message)
				addText("\n-----=====#=====-----")
			end
			amount = amount + 1
		end
	end
	if amount == 0 then forceprint("UHHHHHMMMMM WHY DIDNT ANYTHING UPDATE?") self.continue = true end
	self.initState = mods.utilitools.config.updated.initState
	mods.utilitools.config.updated = {}
end)

st:setUpdate(function(self, dt)
    self.errorSprite:update(dt)
	if maininput:pressed("accept") or maininput:pressed("back")or self.continue then
		utilitools.config.save(mods.utilitools)
		te.stop('music')
		if bs.states.Menu == nil then dofile('preload/states.lua') end
		cs = bs.load(self.initState or project.initState)
		cs:init()
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
