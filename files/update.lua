return function(dt)
	utilitools.config.foldAll = false
	if utilitools.keybinds then
		utilitools.keybinds.mod.checkBindsStart()
		for modId, modFiles in pairs(utilitools.files) do if modFiles.keys then utilitools.keybinds.mod.checkBinds(mods[modId], modFiles.keys) end end
		utilitools.keybinds.mod.checkBindsEnd()
	end
	if utilitools.relaunch and utilitools.relaunch.doRelaunch then utilitools.relaunch.relaunch(true) end
end
