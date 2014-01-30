--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Default Group Recall Fix",
    desc      = "Fix to the group recall problem.",
    author    = "msafwan, GoogleFrog",
    date      = "30 Jan 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 1002,
	handler   = true,
    enabled   = true,
  }
end

include("keysym.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Camera/Control Group Zoom'
options_order = { 'enabletimeout', 'timeoutlength'}
options = {
	enabletimeout = {
		name = "Enable Timeout",
		type = 'bool',
		value = true,
		desc = "When enabled, the key must be pressed twice in quick sucession to zoom to a control group.",
	},
	timeoutlength = {
		name = "Double Press Speed", 
		type = "number", 
		value = 0.4, 
		min = 0,
		max = 5,
		step = 0.1,
	},
}


local spGetUnitGroup = Spring.GetUnitGroup
local spGetGroupList  = Spring.GetGroupList 
local spGetTimer 			= Spring.GetTimer
local spDiffTimers 			= Spring.DiffTimers
local spGetSelectedUnits = Spring.GetSelectedUnits

local previousGroup = 99
local currentIteration = 1
local previousKey = 99
local previousTime = spGetTimer()
local groupNumber = {
	[KEYSYMS.N_1] = 1,
	[KEYSYMS.N_2] = 2,
	[KEYSYMS.N_3] = 3,
	[KEYSYMS.N_4] = 4,
	[KEYSYMS.N_5] = 5,
	[KEYSYMS.N_6] = 6,
	[KEYSYMS.N_7] = 7,
	[KEYSYMS.N_8] = 8,
	[KEYSYMS.N_9] = 9,
}

local function GroupRecallFix(key, modifier, isRepeat)
	if (not modifier.ctrl and not modifier.alt and not modifier.meta) then --check key for group. Reference: unit_auto_group.lua by Licho
		local group
		if (key ~= nil and groupNumber[key]) then 
			group = groupNumber[key]	
		end
		if (group ~= nil) then
			local selectedUnit = spGetSelectedUnits()
			local groupCount = spGetGroupList() --get list of group with number of units in them
			
			-- First check that the selectio and group in question are the same size.
			if groupCount[group] ~= #selectedUnit then
				previousKey = key
				previousTime = spGetTimer()
				return false
			end
			
			-- Check each unit for membership of the required group
			for i=1,#selectedUnit do
				local unitGroup = spGetUnitGroup(selectedUnit[i])
				if unitGroup ~= group then
					previousKey = key
					previousTime = spGetTimer()
					return false
				end
			end
			
			if previousKey == key and (spDiffTimers(spGetTimer(),previousTime) < options.timeoutlength.value) then
				previousTime = spGetTimer()
				return false
			end
			
			previousKey = key
			previousTime = spGetTimer()
			return true
		end
	end
end

function widget:KeyPress(key, modifier, isRepeat)
	if options.enabletimeout.value then
		return GroupRecallFix(key, modifier, isRepeat)
	end
end