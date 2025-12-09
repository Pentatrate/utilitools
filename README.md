# Utilitools

(EA Mod)
by Pentatrate

## Info

More up to date info about this mod can be found in the [beatblock modding discord server (invite)](https://discord.gg/VDvPUSCdGZ)
It has a dedicated post named `Utilitools` in the `ea-mods` forum

## How to install

1. Download zip:
	Either directly download the repository as a zip (I recommend this)
	[Screenshot downloading as zip](https://github.com/user-attachments/assets/0653e3ef-cfe0-4b41-825f-a7e786feda4d)

	or download the "latest" release (The latest release may not have features added in later commits)
	[Screenshot to find releases](https://github.com/user-attachments/assets/2acbead3-fad3-476b-9525-43fb1d728cb6)

2. Unzip and place in `beatblock/Mods/` folder (where all the other mods are)

	**!!!Reminder!!!**: Make sure the mod.json file is in `beatblock/Mods/utilitools/mod.json` and **NOT** `beatblock/Mods/utilitools/utilitools/mod.json`

3. Relaunch modded beatblock

## How to set up your mod with utilitools

1. `utilitools.json` (bare minimum)

	Technically optional, but HIGHLY RECOMMENDED.

	Create the `utilitools.json` file in the same folder next to the `mod.json` file with the following content.

	```json
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
