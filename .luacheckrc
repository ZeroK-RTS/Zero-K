ignore = {
  "611", -- GF wishes to permit lines consisting entirely of whitespace
}
self = false
unused_args = false
-- unused = false -- Another false negatives, false positives conundrum
max_line_length = false
allow_defined_top = true -- We're going to get a lot of false negatives with this disabled, but a lot of false positives with it enabled. Pick your poison.
stds.ext = {
  globals = { "math.round", "math.bit_or", "table.ifind", "table.show", "table.save", "table.echo", "table.print" }
}
stds.spring = {
  read_globals = { "CMD", "CMDTYPE", "Script", "LOG" },
  globals = { "include", "Spring", "VFS", "UnitDefs", "UnitDefNames", "FeatureDefs", "FeatureDefNames", "WeaponDefs", "WeaponDefNames", "Game", "Platform" }
}
stds.widgets = {
  read_globals = { "LUAUI_DIRNAME", "KEYSYMS", "GL" },
  globals = { "widget", "widgetHandler", "WG", "gl", "options", "options_path", "options_order" }
}
stds.gadgets = {
  globals = { "gadget", "gadgetHandler", "GG" }
}
stds.customcmds = {
  globals = {
    -- Automatically generated from customcmds.h.lua
    "CMD_SET_FERRY",
"CMD_RETREAT_ZONE",
"CMD_SETHAVEN",
"CMD_RESETFIRE",
"CMD_RESETMOVE",
"CMD_BUILDPREV		",
"CMD_RADIALBUILDMENU",
"CMD_SET_AI_START",
"CMD_BUILD",
"CMD_NEWTON_FIREZONE",
"CMD_STOP_NEWTON_FIREZONE",
"CMD_CHEAT_GIVE",
"CMD_FIRE_ONCE",
"CMD_FACTORY_GUARD",
"CMD_AREA_GUARD",
"CMD_ORBIT",
"CMD_SELECTION_RANK",
"CMD_ORBIT_DRAW",

"CMD_GLOBAL_BUILD",
"CMD_GBCANCEL",
"CMD_STOP_PRODUCTION",

"CMD_SELECT_MISSILES",

"CMD_AREA_MEX",
"CMD_STEALTH",
"CMD_CLOAK_SHIELD",
"CMD_MINE",
"CMD_EMBARK",
"CMD_DISEMBARK",
"CMD_TRANSPORTTO",
"CMD_EXTENDED_LOAD",
"CMD_EXTENDED_UNLOAD",
"CMD_LOADUNITS_SELECTED",
"CMD_AUTO_CALL_TRANSPORT",
"CMD_RAW_MOVE",
"CMD_RAW_BUILD",
"CMD_MORPH_UPGRADE_INTERNAL",
"CMD_UPGRADE_STOP",
"CMD_MORPH",
"CMD_MORPH_STOP",
"CMD_REARM",
"CMD_FIND_PAD",
"CMD_UNIT_FLOAT_STATE",
"CMD_PRIORITY",
"CMD_MISC_PRIORITY",
"CMD_RETREAT",
"CMD_UNIT_BOMBER_DIVE_STATE",
"CMD_AP_FLY_STATE",
"CMD_AP_AUTOREPAIRLEVEL",
"CMD_UNIT_SET_TARGET",
"CMD_UNIT_CANCEL_TARGET",
"CMD_UNIT_SET_TARGET_CIRCLE",
"CMD_ONECLICK_WEAPON",
"CMD_PLACE_BEACON",
"CMD_WAIT_AT_BEACON",
"CMD_ABANDON_PW",
"CMD_RECALL_DRONES",
"CMD_TOGGLE_DRONES",
"CMD_ANTINUKEZONE",
"CMD_UNIT_KILL_SUBORDINATES",
"CMD_DISABLE_ATTACK",
"CMD_PUSH_PULL",
"CMD_UNIT_AI",
"CMD_WANT_CLOAK",
"CMD_DONT_FIRE_AT_RADAR",
"CMD_JUMP",
"CMD_WANTED_SPEED",
"CMD_TIMEWARP",
"CMD_TURN",
"CMD_AIR_STRAFE",
"CMD_PREVENT_OVERKILL",
"CMD_TRANSFER_UNIT",

"CMD_RAMP",
"CMD_LEVEL",
"CMD_RAISE",
"CMD_SMOOTH",
"CMD_RESTORE",
"CMD_BUMPY",
"CMD_TERRAFORM_INTERNAL",
  }
}
std = "lua51+ext+spring"
files['LuaUI/Widgets/*.lua'].std     = "+customcmds+widgets"
files['LuaRules/Gadgets/*.lua'].std  = "+customcmds+gadgets"
