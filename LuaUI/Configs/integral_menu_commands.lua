

local cmdPosDef = include("Configs/integral_menu_commands_orders.lua", nil, VFS.RAW_FIRST)
local factoryUnitPosDef = include("Configs/integral_menu_commands_factory.lua", nil, VFS.RAW_FIRST)
local factory_commands, econ_commands, defense_commands, special_commands = include("Configs/integral_menu_commands_build.lua", nil, VFS.RAW_FIRST)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return cmdPosDef, factoryUnitPosDef, factory_commands, econ_commands, defense_commands, special_commands

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
