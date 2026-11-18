return { -- these keys are global
	reloadHotkey = function() utilitools.fileManager.loadAll(true) end,
	relaunchHotkey = utilitools.relaunch.relaunch,
	foldHotkey = function() utilitools.config.foldAll = true end
}