--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Dev Commands",
    desc      = "v0.01 Dev Commands",
    author    = "CarRepairer",
    date      = "2011-11-17",
    license   = "GPLv2",
    layer     = 5,
    enabled   = false,  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local echo = Spring.Echo
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
options_path = 'Settings/Toolbox/Dev Commands'
options = {
	
	cheat = {	
		name = "Cheat",
		type = 'button',
		OnChange = function(self) Spring.SendCommands({'cheat'}) end,
	},
	nocost = {
		name = "No Cost",
		type = 'button',
		OnChange = function(self) Spring.SendCommands({'nocost'}) end,
	},
	
	spectator = {
		name = "Spectator",
		type = 'button',
		OnChange = function(self) Spring.SendCommands({'spectator'}) end,
	},
	
	godmode = {
		name = "Godmode",
		type = 'button',
		OnChange = function(self) Spring.SendCommands({'godmode'}) end,
	},
	
	testunit = {
		name = "Spawn Testunit",
		type = 'button',
		OnChange = function(self) Spring.SendCommands({'give testunit'}) end,
	},
	
	luauireload = {
		name = "Reload LuaUI",
		type = 'button',
		action = 'luaui reload',
	},
	
	luarulesreload = {
		name = "Reload LuaRules",
		type = 'button',
		OnChange = function(self) Spring.SendCommands({'luarules reload'}) end,
	},
	
	debug = {
		name = "Debug",
		type = 'button',
		action = 'debug',
	},
	debugcolvol = {
		name = "Debug Colvol",
		type = 'button',
		action = 'debugcolvol',
	},
	debugpath = {
		name = "Debug Path",
		type = 'button',
		action = 'debugpath',
	},
	
	
	printunits = {
		name = "Print Units",
		type = 'button',
		OnChange = function(self)
			for i=1,#UnitDefs do
				local ud = UnitDefs[i]
				local name = ud.name
				Spring.Echo("'" .. name .. "',")
			end
		end,
	},
	
}

