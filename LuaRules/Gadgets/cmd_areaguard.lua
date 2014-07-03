--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Area Guard",
    desc      = "Replace Guard with Area Guard",
    author    = "CarRepairer",
    date      = "2013-06-12",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- includes

include "LuaRules/Configs/customcmds.h.lua"

local echo = Spring.Echo


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if gadgetHandler:IsSyncedCode() then -- SYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- vars


local areaGuardCmd = {
    id      = CMD_AREA_GUARD,
    name    = "Guard2",
    action  = "areaguard",
	cursor  = 'Guard',
    type    = CMDTYPE.ICON_UNIT_OR_AREA,
	tooltip = "Guard the unit or units",
	--hidden	= true,
}


--------------------------------------------------------------------------------
-- functions

local function DoAreaGuard( unitID, unitTeam, unitTeam, cmdParams, cmdOptions )
	local cmdOptions2 = {}
	if (cmdOptions.shift) then table.insert(cmdOptions2, "shift")   end
	if (cmdOptions.alt)   then table.insert(cmdOptions2, "alt")   end
	if (cmdOptions.ctrl)  then table.insert(cmdOptions2, "ctrl")  end
	if (cmdOptions.right) then table.insert(cmdOptions2, "right") end
	
    if #cmdParams == 1 then
        Spring.GiveOrderToUnit(unitID, CMD.GUARD, {cmdParams[1]}, cmdOptions2)
        return
    end
	
	if (not cmdOptions.shift) then
		Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, cmdOptions2)
		table.insert(cmdOptions2, "shift")
	end
	
	local alreadyGuarding = {}
	local cmdQueue = Spring.GetCommandQueue(unitID, -1);
	for _,cmd in ipairs(cmdQueue) do
		if cmd.id == CMD.GUARD and #cmd.params == 1 then
			alreadyGuarding[ cmd.params[1] ] = true
		end
	end
	
    local units = Spring.GetUnitsInSphere( unpack(cmdParams) )
    for _,otherUnitID in ipairs( units ) do
		if otherUnitID ~= unitID and not alreadyGuarding[otherUnitID] then
			local teamID = Spring.GetUnitTeam(otherUnitID)
			if Spring.AreTeamsAllied( unitTeam, teamID ) then
				Spring.GiveOrderToUnit(unitID, CMD.GUARD, {otherUnitID}, cmdOptions2)
			end
		end
    end
	
end



--------------------------------------------------------------------------------
-- callins



function gadget:UnitCreated(unitID, unitDefID, team)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD.GUARD)
    if cmdDescID then
        local cmdArray = {hidden = true}
        Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
		Spring.InsertUnitCmdDesc(unitID, 500, areaGuardCmd)
    end
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
    if cmdID == CMD_AREA_GUARD then
        DoAreaGuard( unitID, unitTeam, unitTeam, cmdParams, cmdOptions )
        return false
    end
    
	return true
end

function gadget:Initialize()
    for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		--local team = spGetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, team)
    end
end




-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else  -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------


local function SelectedUnitCanRepair() -- cache this?
	local selUnits = Spring.GetSelectedUnits()
	if not selUnits[1] then
		return nil -- no selected units
	end
	local unitID, unitDefID
	local canRepair
	for i = 1, #selUnits do
		unitID    = selUnits[i]
		unitDefID = Spring.GetUnitDefID(unitID)
		if not unitDefID then
			return
		end
		local ud = UnitDefs[unitDefID]
		if ud.canRepair then
			return true
		end
	end
	return false
end



--------------------------------------------------------------------------------
-- callins

--[[
function gadget:DefaultCommand(type,id)
	--echo 'DefaultCommand'
	if type == 'unit' then
		
		local target_team = Spring.GetUnitTeam(id)
		if Spring.AreTeamsAllied( target_team, Spring.GetLocalTeamID() ) then
			if SelectedUnitCanRepair() then
				local hp, maxHp,_,_,buildProgress = Spring.GetUnitHealth(id)
				if not buildProgress or buildProgress < 1 or hp < maxHp then
					return -- let the default command be repair
				end
			end
			
			return CMD_AREA_GUARD
		end
	end
end	
--]]

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
end
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
