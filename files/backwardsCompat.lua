local changesToConfig = false
for k, v in pairs(mod.config.branches) do
	if v == "      " then
		mod.config.branches = "Latest Release## "
		changesToConfig = true
	end
end
if changesToConfig then
	utilitools.config.save(mods.utilitools)
end