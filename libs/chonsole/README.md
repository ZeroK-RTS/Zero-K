Modern chili console for the Spring Engine.

## Features
- history persistant through restarts, history autocomplete
- detailed command overview
- custom command support (/gamerules, /execw, etc.)
- integration with liblobby for Spring lobby communication
- i18n

## Dependencies
- Spring 101.x+
- [chili](https://github.com/gajop/chiliui)
- [liblobby](https://github.com/gajop/liblobby) (optional, support for Spring lobby communication)
- [i18n](https://github.com/gajop/i18n) (optional, support for i18n)

## Install
1. Obtain the repository either by adding it as a git submodule or by copying the entire structure in to your Spring game folder. Put it anywhere (although /libs is suggested and used by default).
2. Copy the file ui_chonsole_load.lua to the luaui/widgets and luarules/gadgets folders and modify the CHONSOLE_FOLDER path.

## Customization
Basic configuration can be done in the _luaui/config/globals.lua_ file.
It is possible to set console size, position, color of the suggestions and more.

Chonsole can also be extended by creating custom commands and contexes.
This is done by creating extension files and putting them in the _exts_ folder.
Chonsole already comes with four extensions: 
- core: improves existing engine functionality
- exec: allows execution of arbitrary Lua code
- rules: allows modifications of {game,team,unit}rule variables
- lobby: provides commands for connecting to the Spring Lobby server

Each extension can have the following:
- command table: defines commands that can be executed
- conext table: defines contexts which modify how text is interpreted (e.g. _Allies:_ is an context included by default)
- an additional i18n file can be put in the _exts/i18n_ folder

The command table has the following format:
```lua
	commands = {
		{
			command = string, -- name of the command to be displayed
			description = string, -- description used to explain the command to the user
			cheat = boolean, -- whether command requires cheat to be executed (extensions don't need to very if cheating is enabled, this is handled by chonsole automatically)
			suggestions = function(cmd, cmdParts)
				local suggestions = {}
				-- this function is used to generate the (sub)suggestions for the command, optional
				-- this is done to present the user a list of valid (or suggested) arguments
				return suggestions
			end,
			exec = function(command, cmdParts)
				-- function that executes the command, mandatory
			end,
			execs = function(luaCommandStr)
				-- function that executes the command in a synced gadget, optional
				-- in case this is wanted, the user should first send required data using Sync(...) in the exec command
			end,
			execu = function(luaCommandStr)
				-- function that executes the command in an unsynced gadget, optional
				-- in case this is wanted, the user should first send required data using Unsync(...) in the execs command
			end,
		},
		-- list of commands
	}
```

The context table has the following format:
```lua
	context = {
		{
			name = string, -- name of the context, used internally to differentiate between them
			parse = function(txt)
				-- function that returns true if the matching string (starting with /) belongs to the given context, mandatory
				-- for example, it could be used to match all strings starting with /a as belonging to the "allies" context
			end,
			exec = function(str, context)
				-- function that executes the string in the given context, mandatory
				-- this is used to execute the text following the command, e.g. in the case of "allies", it should send the entered text as a chat command to all allies
			end
		},
		-- list of contexts
	}
```

For additional details, check the existing examples.
