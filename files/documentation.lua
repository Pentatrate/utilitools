return { -- Penta: this is in lua and not json because i wanted the multiline string for the full description
	-- Penta: when unspecified, it will default to json and try to load this file by default
	fullDescription = {
		short = [[
## How to set up your mod with utilitools:

1. `utilitools.json` (bare minimum)

	Technically optional, but HIGHLY RECOMMENDED.

	Create the `utilitools.json` file in the same folder next to the `mod.json` file with the following content.

	```
	{ "dependencies": { "utilitools": { reason: "Required API", versions: [ [">=", "!!!current utilitools version, for example 1.1.2!!!"] ] } } }
	```

	Obviously replace the placeholder string with the lowest utilitools version your mod is compatible with.
	Remember to change this value to reflect the current circumstances when updating your mod.

	This should be the minimal requirement since specifying the lowest supported utilitools version will simply force the user to update their old utilitools mods before they get a chance to complain on discord because of a crash.
	(It may sound blunt, but on the other hand I'm happy to at least get any kind of feedback)

2. Dependencies and incompatibilities

	Dependencies and incompatibilities are both specified in basically the same way.
	You may use the `utilitools.json` file of the utilitools mod or the preset in (1) as reference.

	Within the `utilitools.json` file of your mod, add an attribute either called `dependencies` or `incompatibilities`.
	Its value is an object.
	You may now add multiple other mods that your mod interacts with.

	Add an attribute and call it the mod ID of another mod you want to specify compatibility with.
	Its value is an object.
	Inside it, add an attribute `reason`. Its value is a string. Obviously specify the reason the mod is listed there.

	Optional:

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

3. File managing

4. TODO FINISH THIS LOL, GOOD LUCK FUTURE ME

# Version history

1.0.0:

(File) fileManager: File (re)loading
(File) configHelpers
(File) imguiHelpers
(File) prompts
mod interactions (Dependency/Incompatibility)
utilitools.configs.save(mod)
utilitools.try(mod, func)
log(mod, string)
forceprint(...)

1.1.0:

(File) versions: Version comparing
mod interactions (respect versions)
(File) keybinds (+ Additions to imgui/config helpers)
prompts overhaul

1.1.1

Moved files to own folder (files) (affects fileManager)

1.1.2

utilitools.string.split(string, char)

1.1.3

suggest expansion
	rename suggest.run(...) to suggest.suggest(...)
	add suggest.dial(...)

1.1.4

keybinds full rework

]]
	}
}