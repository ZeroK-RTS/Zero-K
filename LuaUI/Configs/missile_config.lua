-- Missile launcher configuration. Shared by the Missile Command Center widget
-- (launch/build behaviour) and integral_menu_config.lua (Launch tab layout), so a
-- missile type is described in exactly one place. One entry per launch button, in
-- display order. Command ids are assigned automatically from CMD_BASE below.
--
-- Entry fields:
--   key       - internal id (widget command table key).
--   unit      - unit def name; supplies the button icon.
--   label     - display name.
--   col, row  - position in the Launch tab grid.
--   tooltip   - button tooltip.
--   cmdType   - "ICON_MAP" (default) or "ICON_UNIT_OR_MAP" (can target a unit).
--   siloBuild - unit this type is built as at a missile silo (enables Alt-click build).
--   zenith    - true for the Zenith meteor controller (special, non-stockpile behaviour).
--   controllerScope - "separate": this button only exists when Eos/Scylla are NOT combined.
--   launch    - list of launchable unit types, each:
--       unit      - unit def name that carries/fires this missile.
--       cmd       - "ATTACK" or "MANUALFIRE".
--       weaponId  - weapon index on that unit.
--       stockpile - "silo" (sits on a silo pad) or "engine" (GetUnitStockpile); omit for Zenith.
--       scope     - "combine": active only when Eos and Scylla are combined.

local CMD_BASE = 39610

local missiles = {
	{ key = "zenith", unit = "zenith", label = "Zenith", col = 1, row = 1,
		zenith = true, cmdType = "ICON_UNIT_OR_MAP",
		tooltip = "Zenith (Meteor Controller)\nRains meteors on the target for a few seconds.",
		launch = { { unit = "zenith", cmd = "ATTACK", weaponId = 1 } },
	},
	{ key = "trinity", unit = "staticnuke", label = "Trinity", col = 2, row = 1,
		tooltip = "Launch Trinity (Strategic Nuke)\nLong-range nuclear missile.",
		launch = { { unit = "staticnuke", cmd = "ATTACK", weaponId = 1, stockpile = "engine" } },
	},
	{ key = "reef", unit = "shipcarrier", label = "Reef Missile", col = 3, row = 1,
		cmdType = "ICON_UNIT_OR_MAP",
		tooltip = "Launch Disarm Missile\nDisables units temporarily.",
		launch = { { unit = "shipcarrier", cmd = "MANUALFIRE", weaponId = 2, stockpile = "engine" } },
	},
	{ key = "scylla", unit = "subtacmissile", label = "Scylla", col = 4, row = 1,
		controllerScope = "separate",
		tooltip = "Launch Scylla (Tactical Nuke)\nSubmarine-launched tactical nuke.",
		launch = { { unit = "subtacmissile", cmd = "ATTACK", weaponId = 1, stockpile = "engine" } },
	},
	{ key = "eos", unit = "tacnuke", label = "Eos", col = 1, row = 2,
		siloBuild = "tacnuke",
		tooltip = "Launch Eos (Tactical Nuke)\nTactical nuclear missile with high damage.\nAlt-click the map to build one.",
		launch = {
			{ unit = "tacnuke", cmd = "ATTACK", weaponId = 1, stockpile = "silo" },
			-- Scylla folds in here only when the Combine Eos and Scylla option is on.
			{ unit = "subtacmissile", cmd = "ATTACK", weaponId = 1, stockpile = "engine", scope = "combine" },
		},
	},
	{ key = "seismic", unit = "seismic", label = "Seismic", col = 2, row = 2,
		siloBuild = "seismic",
		tooltip = "Launch Seismic\nArea denial seismic missile, slows units.\nAlt-click the map to build one.",
		launch = { { unit = "seismic", cmd = "ATTACK", weaponId = 1, stockpile = "silo" } },
	},
	{ key = "shockley", unit = "empmissile", label = "Shockley", col = 3, row = 2,
		siloBuild = "empmissile",
		tooltip = "Launch Shockley (EMP)\nElectromagnetic pulse missile disables units.\nAlt-click the map to build one.",
		launch = { { unit = "empmissile", cmd = "ATTACK", weaponId = 1, stockpile = "silo" } },
	},
	{ key = "inferno", unit = "napalmmissile", label = "Inferno", col = 4, row = 2,
		siloBuild = "napalmmissile",
		tooltip = "Launch Inferno (Napalm)\nNapalm missile with persistent damage.\nAlt-click the map to build one.",
		launch = { { unit = "napalmmissile", cmd = "ATTACK", weaponId = 1, stockpile = "silo" } },
	},
	{ key = "zeno", unit = "missileslow", label = "Zeno", col = 5, row = 2,
		siloBuild = "missileslow",
		tooltip = "Launch Zeno (Slow Missile)\nSlow homing missile with lingering damage.\nAlt-click the map to build one.",
		launch = { { unit = "missileslow", cmd = "ATTACK", weaponId = 1, stockpile = "silo" } },
	},
}

for i = 1, #missiles do
	missiles[i].cmd = CMD_BASE + i - 1
end

return missiles
