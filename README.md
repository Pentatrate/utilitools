# Utilitools

EA Mod for the game Beatblock

by Pentatrate

![GitHub Downloads](https://img.shields.io/github/downloads/Pentatrate/utilitools/total)

## Info

More up to date info about this mod can be found in the [beatblock modding discord server (invite)](https://discord.gg/VDvPUSCdGZ)
It has a dedicated post named `Utilitools` in the `ea-mods` forum

## How to install

1. Download zip:
	Either directly download the repository as a zip (**I recommend this**)

	[Download link](https://github.com/Pentatrate/utilitools/archive/refs/heads/main.zip)

	or download the "latest" release (The latest release may not have features added in later commits)

	![Screenshot to find releases](https://github.com/user-attachments/assets/2acbead3-fad3-476b-9525-43fb1d728cb6)

2. Unzip and place in `beatblock/Mods/` folder (where all the other mods are)

	**!!!Reminder!!!**: Make sure the mod.json file is in `beatblock/Mods/utilitools/mod.json` and **NOT** `beatblock/Mods/utilitools/utilitools/mod.json`

3. Relaunch modded beatblock

## How to set up your mod with utilitools

This is for mod creators looking to use utilitools as a "dependency".
Definitely message me if you need any additional information regarding utilitools processes or setup, since this README is rather incomplete.
For the following sections, unless otherwise stated, all filepaths provided are relative to your current working directory, the folder of your `mod.json` file.

1. Bare minimum: `utilitools.json`

	Technically optional, but HIGHLY RECOMMENDED.

	Create the `utilitools.json` file in the same folder next to the `mod.json` file with the following content.

	```json
	{ "dependencies": { "utilitools": { reason: "Required API", versions: [ [">=", "!!!current utilitools version, for example 1.2.2!!!"] ] } } }
	```

	Obviously replace the placeholder string with the lowest utilitools version your mod is compatible with.
	Remember to change this value to reflect the current circumstances when updating your mod.

	This should be the minimal requirement since specifying the lowest supported utilitools version will simply force the user to update their old utilitools mods before they get a chance to complain on discord because of a crash.
	(It may sound blunt, but on the other hand I'm happy to at least get any kind of feedback)

2. Dependencies and incompatibilities

	Dependencies and incompatibilities are both specified in basically the same way.
	You may use the `utilitools.json` file **of the utilitools mod** or the example content in (1.) as reference.

	Within the `utilitools.json` file of your mod, add an attribute either called `dependencies` or `incompatibilities`.
	Its value is an object.
	You may now add multiple other mods that your mod interacts with.

	Add an attribute and call it the mod ID of another mod you want to specify compatibility with.
	Its value is an object.
	Inside it, add an attribute `reason`. Its value is a string. Obviously specify the reason the mod is listed there.

	- Optional:

		Add an attribute `versions`. Its value is an array.
		You may now add multiple versions that interact with your mod.
		Utilitools will only act as if the mod exists if its version is in the defined range.
		(Leaving this array empty means that no matter what, utilitools will act as if you do not have the mod installed)

		Add an array with the first entry being the operation you want to check.
		You may choose between `"="`, `"<"`, `"<="`, `">"`, `">="`, `"fromTil"` and `"between"`.
		The second (and, if you chose one of the later two operations, also the third) entry should be a string of a version.

		Optional 2:

		If it interests you, you may check out the `files/versions.lua` file in this mod to see how things work behind the scenes.
		(Take an educated guess as to which functions get called when lol.)

3. Configs

	Utilitools provides you with powerful config functions to cleanly create config options.
	You may use the `utilitools.json` and `files/configOptions.json` files **of the utilitools mod** as reference.

	1. Config Options

		1. Basic Setup

			Within the `utilitools.json` file of your mod, add an attribute either called `config`.
			Its value is an boolean.
			Set it to true.

			With this, you may now create a `files/` folder next to the `mod.json` file.
			Create a `files/configOptions.lua` file or `files/configOptions.json` file.
			All following examples will be in lua

			To make utilitools recognize it as a file to be loaded, you must add it to your `utilitools.json` file.
			For more information about the utilitools file manager, see (4.)

			```jsonc
			{
				// previous utilitools.json content here
				"files": {
					// previous files content here, if any
					"configOptions": {
						"extension": "lua", // or "json", depending on your extension of choice
						"load": true,
						"call": true // only if your file is a .lua extension
					}
				}
			}
			```

			The content of the `files/configOptions.*` file is a table with the config name as a key and a table as its value.
			See the following example in lua.

			```lua
			return {
				editorMenu = {
					type = "bool",
					name = "Configs in Editor",
					tooltips = "Adjust the configs directly in the editor in the same menu format",
					default = true
				}
			}
			```

		2. Required fields

			The `type` field specifies the Dear ImGui input type of the config.
			The currently accepted types are:

			- `bool`: A boolean.
			- `int`: An integer.
				Additional fields: `flags`, `step`, `stepFast`
			- `float`: A floating point number.
				Additional fields: `flags`, `step`, `stepFast`, `format`
			- `text`: Simple text.
				Additional fields: `flags`, `size`
			- `multiline`: Text with line breaks.
				Additional fields: `flags`, `size`
			- `combo`: A dropdown to select an option.
				Additional fields: `flags`, `values`, `valueTooltips`
			- `ease`: A dropdown to select an ease. Eases are provided by the base game.
				Additional fields: `flags`
			- `color`: The color input.
				Additional fields: `flags`
			- `list`: (Not recommended) A string of number separated by a comma, converted to an indexed array in the code.
				Additional fields: `flags`, `size`
			- `key`: A hotkey.
			- `branch`: (Not recommended) A dropdown to select a git branch, rather used internally for autoupdating mods.
			- `sliderInt`: An integer slider.
				Additional fields: `flags`, `min`, `max`, `innerLabel`
			- `sliderFloat` A floating point slider.
				Additional fields: `flags`, `min`, `max`, `innerLabel`

			The `name` field specifies the label of the Dear ImGui input shown to the user.

			The `tooltips` field specifies the tooltip the user recieves upon hovering over the Dear ImGui input.
			In it's most basic form, it is a simple string.
			Optionally, it may be a table consisting of `long` and `short` key-value pairs.
			This requires an additional `tooltips` config option

			```lua
			return {
				editorMenu = {
					-- See previous example for more fields
					tooltips = {
						long = "Adjust the configs directly in the editor in the same menu format",
						short = "Show this menu in the editor"
					}
				}
			}
			```

			The `default` field specifies the default value the config option gets initialized as if it is unset upon the lauch of the game.
			This serves to ensure that the mod does not have the additionally check for `nil` when accessing the config values.

		3. Optional/Specific fields

			There are a few additional fields that arent generally required or are required by a specific input `type`:

			- `off`: (optional)

				Specifies the value the config gets set to when the button gets pressed to turn all configs off.
				Leaving it empty will make the option unaffected by the button to turn all configs off.

			- `flags`: (`int`, `float`, `text`, `multiline`, `combo`, `ease`, `color`, `list`, `sliderInt`, `sliderFloat`)

				Dear ImGui inputs accept optional flags.
				Flags are stored as integers where each binary digit stands for a specific flag.
				Instead of passing a "magic number" as a flag, I recommend adding multiple flags together.
				Individual flags are provided by Dear ImGui in a readable format.
				Here is an example for creating readable window flags.

				```lua
				local windowFlags = imgui.ImGuiWindowFlags_NoTitleBar + imgui.ImGuiWindowFlags_NoResize
				```

				Different input types require different flags.
				The exact details are listed below.

				- `ImGuiInputTextFlags`: `int`, `float`, `text`, `multiline`, `list`
				- `ImGuiComboFlags`: `combo`, `ease`
				- `ImGuiColorEditFlags`: `color`
				- `ImGuiSliderFlags`: `sliderInt`, `sliderFloat`

				There are different ways to look for Dear ImGui flags, like the [Dear ImGui Explorer](https://pthom.github.io/imgui_explorer/), but when all else fails due to the poor documentation, you can always find them in the `lib/cimgui/cdef.lua` file within the game files.
				(Here is the official [Dear ImGui Repository](https://github.com/ocornut/imgui) by the way, it's README might link to other useful resources. Beatblock uses a binding based on [cimgui](https://github.com/ocornut/imgui))

			- `step`, `stepFast`: (`int`, `float`)

				The step fields provide the number that is stepped up or down when pressing the `+` or `-` buttons next to the input.

			- `format`: (`float`)

				The format specifies how the number is rounded/represented.
				It can for example be used to adjust how many decimals the input rounds to.
				The structure might be similar to python formatting, I'm not sure, it's been a while.

			- `size`: (`text`, `multiline`, `list`)

				Specifies the maximum amount of characters allowed in the input field, defaults to 1024.

			- `values`, `valueTooltips`: (`combo`)

				The values of a combo are stored in an indexed array.
				They specify the different options the user can choose from.
				The options may also have their individual tooltip.
				The individual tooltips may again be split into long and short versions.
				The main tooltip explanation can be found in (3.i.b).

				```lua
				return {
					tooltips = {
						-- See previous example for more fields
						values = { "long", "short", "none" },
						valueTooltips = {
							{
								long = "When hovering over menu options, display a detailed tooltip",
								short = "Display detailed tooltip"
							},
							{ short = "Shorten tooltip" }
						}
					}
				}
				```

			- `min`, `max`, `innerLabel`: (`sliderInt`, `sliderFloat`)

				Specify the lower and upper limit of the slider.
				Additionally, the `innerLabel` field may be used to show text within the slider.
				(Otherwise, the `name` field usually shows text next to the input.)

		4. Example Options

			Unfinished D:

	2. Config Helpers

		1. Basic Setup

			After your mod has been equipped with configs, utilitools provides a `utilitools.configHelpers` module for cleanly building your configs.
			To properly prepare the module, prepend the start of your `config.lua` file with the following example code.

			```lua
			if not utilitools then imgui.Text("Utilitools is disabled") return end
			local configHelpers = utilitools.configHelpers
			configHelpers.setMod(mod)

			-- real config start
			configHelpers.input("editorMenu")
			```

			Now, you can just call `configHelpers.input(key)` with your internal config name and not worry about the Dear ImGui code that happens in the background.

		2. Additional functions

			- `configHelpers.doc(key, force, noSep)`
				For the use of this function, create a `files/documentation.lua` or `files/documentation.json` file.
				You may use the `files/documentation.lua` file **of the utilitools mod** as reference.

				To make utilitools recognize it as a file to be loaded, you must add it to your `utilitools.json` file.
				For more information about the utilitools file manager, see (4.)

				```jsonc
				{
					// previous utilitools.json content here
					"files": {
						// previous files content here, if any
						"documentation": {
							"extension": "lua", // or "json", depending on your extension of choice
							"load": true,
							"call": true // only if your file is a .lua extension
						}
					}
				}
				```

				Also create an additional config... that will be made in 3.i.d later sry

				Unfinished D:

			- `configHelpers.treeNode(label, func, flags)`, `configHelpers.condTreeNode = function(label, key, target, same, func, flags)`
				Unfinished D:
			- `configHelpers.presets.menuOptions()`
				Unfinished D:
			- `configHelpers.presets.menuButtons()`
				Unfinished D:
			- `configHelpers.presets.search()`
				Unfinished D:
			- `configHelpers.presets.updateOptions()`
				Unfinished D:
			- `configHelpers.default()`, `configHelpers.off()`
				These functions reset all configs to default or turn all of them to their off value when called.

	3. Imgui helpers

		Unfinished D:

4. Utilitools file manager

	Unfinished D:
