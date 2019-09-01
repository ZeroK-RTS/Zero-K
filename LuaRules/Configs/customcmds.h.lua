--------------------------------------------------------------------------------
--
--  Proposed Command ID Ranges:
--
--    all negative:  Engine (build commands)
--       0 -   999:  Engine
--    1000 -  9999:  Group AI
--   10000 - 19999:  LuaUI
--   20000 - 29999:  LuaCob
--   30000 - 39999:  LuaRules
--

-- if you add a command, please order it by ID!

--CMD_RETREAT =	10000
CMD_SET_FERRY = 11000
CMD_RETREAT_ZONE = 10001
CMD_SETHAVEN = CMD_RETREAT_ZONE
CMD_RESETFIRE = 10003
CMD_RESETMOVE = 10004
CMD_BUILDPREV		= 10005
CMD_RADIALBUILDMENU = 10006
CMD_SET_AI_START = 10007
CMD_BUILD = 10010
CMD_NEWTON_FIREZONE = 10283
CMD_STOP_NEWTON_FIREZONE = 10284
CMD_CHEAT_GIVE = 13337
CMD_FACTORY_GUARD = 13921
CMD_AREA_GUARD = 13922
CMD_ORBIT = 13923
CMD_SELECTION_RANK = 13987

-- CMD_CIRCLE_GUARD_DRAW is an evil on the order of CMD.SET_WANTED_MAX_SPEED.
-- It is required because CMD_CIRCLE_GUARD needs two parameters but this
-- causes it to not draw in the command queue.
-- See https://springrts.com/mantis/view.php?id=4931
CMD_ORBIT_DRAW = 13924

CMD_GLOBAL_BUILD = 13925 -- global build command state toggle command
CMD_GBCANCEL = 13926 -- global build command area cancel cmd
CMD_STOP_PRODUCTION = 13954

CMD_SELECT_MISSILES = 14001

CMD_AREA_MEX = 30100
CMD_STEALTH = 31100
CMD_CLOAK_SHIELD = 31101
CMD_MINE = 	31105	-- easymetal2
CMD_EMBARK = 31200 --unit_transport_ai_button.lua
CMD_DISEMBARK = 31201 --unit_transport_ai_button.lua
CMD_TRANSPORTTO = 31202 --unit_transport_ai_button.lua
CMD_EXTENDED_LOAD = 31203 --unit_transport_pickup_floating_amphib.lua
CMD_EXTENDED_UNLOAD = 31204 --unit_transport_pickup_floating_amphib.lua
CMD_LOADUNITS_SELECTED = 31205
CMD_AUTO_CALL_TRANSPORT = 31206 --unit_transport_ai_button.lua
CMD_RAW_MOVE = 31109 --cmd_raw_move.lua
CMD_RAW_BUILD = 31110 --cmd_raw_move.lua -- unregistered raw move
CMD_MORPH_UPGRADE_INTERNAL = 31207
CMD_UPGRADE_STOP = 31208
CMD_MORPH = 31210 -- up to 32209
CMD_MORPH_STOP = 32210 -- up to 33209
CMD_REARM = 33410	-- bomber control
CMD_FIND_PAD = 33411	-- bomber control
CMD_UNIT_FLOAT_STATE = 33412
CMD_PRIORITY = 34220
CMD_MISC_PRIORITY = 34221
CMD_RETREAT = 34223
CMD_UNIT_BOMBER_DIVE_STATE = 34281  -- bomber dive
CMD_AP_FLY_STATE = 34569	-- unit_air_plants
CMD_AP_AUTOREPAIRLEVEL = 34570	-- unit_air_plants
CMD_UNIT_SET_TARGET = 34923 -- unit_target_on_the_move
CMD_UNIT_CANCEL_TARGET = 34924
CMD_UNIT_SET_TARGET_CIRCLE = 34925
CMD_ONECLICK_WEAPON = 35000
CMD_PLACE_BEACON = 35170
CMD_WAIT_AT_BEACON = 35171
CMD_ABANDON_PW = 35200
CMD_RECALL_DRONES = 35300
CMD_TOGGLE_DRONES = 35301
CMD_ANTINUKEZONE = 35130 -- ceasefire
CMD_UNIT_KILL_SUBORDINATES = 35821 -- unit_capture
CMD_DISABLE_ATTACK = 35822 -- unit_launcher
CMD_PUSH_PULL = 35666 -- weapon_impulse
CMD_WANT_ONOFF = 35667
CMD_UNIT_AI = 36214
CMD_WANT_CLOAK = 37382
CMD_DONT_FIRE_AT_RADAR = 38372 -- fire at radar toggle gadget
CMD_JUMP = 38521
CMD_WANTED_SPEED = 38825
CMD_TIMEWARP = 38522
CMD_TURN = 38530
CMD_AIR_STRAFE = 39381
CMD_PREVENT_OVERKILL = 38291
CMD_TRANSFER_UNIT = 38292

-- terraform
CMD_RAMP = 39734
CMD_LEVEL = 39736
CMD_RAISE = 39737
CMD_SMOOTH = 39738
CMD_RESTORE = 39739
CMD_BUMPY = 39740
CMD_TERRAFORM_INTERNAL = 39801

-- not included here, just listed
--[[
CMD_PURCHASE = 32601	-- planetwars, range up to 32601 + #purchases
CMD_MORPH_STOP = 32210	-- range up to 32210 + #morphs
CMD_MORPH = 31210		-- ditto
]]--

-- deprecated
--[[
CMD_PLANTBOMB =     	32523
CMD_AUTOREPAIR =    	33250 	-- up to 33250 + 3
CMD_AUTORECLAIM =   	33251
CMD_AUTOASSIST  =   	33252
CMD_AUTOATTACK  =   	33253
CMD_PRIORITY=			34220
CobButton =         	34520 	-- up to 32520 + different cob buttons
CMD_SCRAMBLE =      	35128
CMD_WRECK =         	36734
CMD_RESTOREBOMB = 		39735
]]--
