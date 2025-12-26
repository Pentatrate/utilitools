local st = Gamestate:new('UtilitoolsEmpty')

st:setInit(function(self) end)

st:setUpdate(function(self, dt) end)

st:setBgDraw(function(self) end)

st:setFgDraw(function(self) end)

return st
