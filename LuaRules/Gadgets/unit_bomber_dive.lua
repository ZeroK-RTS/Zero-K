function gadget:GetInfo()
	return {
		name = "Bomber Dive",
		desc = "Causes certain bombers to dive under shields",
		author = "Google Frog",
		date = "30 May 2011",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")

local DEFAULT_COMMAND_STATE = 1

local unitBomberDiveState = {
	id      = CMD_UNIT_BOMBER_DIVE_STATE,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Dive State',
	action  = 'divestate',
	tooltip	= 'Toggles dive controls',
	params 	= {0, 'Never','When Shielded','When Attacking','Constant'}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--SYNCED
if gadgetHandler:IsSyncedCode() then

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local bomberWeaponNamesDefs, bomberWeaponDefs, bomberUnitDefs = include("LuaRules/Configs/bomber_dive_defs.lua")

local UPDATE_FREQUENCY = 60

local bombers = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function temporaryDive(unitID, duration)
	Spring.MoveCtrl.SetAirMoveTypeData(unitID, "wantedHeight", bombers[unitID].diveHeight)
	bombers[unitID].resetTime = UPDATE_FREQUENCY * math.ceil((Spring.GetGameFrame() + duration)/UPDATE_FREQUENCY)
end

function Bomber_Dive_fired(unitID)
	Spring.MoveCtrl.SetAirMoveTypeData(unitID, "wantedHeight", bombers[unitID].orgHeight)
	bombers[unitID].resetTime = false
end
GG.Bomber_Dive_fired = Bomber_Dive_fired

function Bomber_Dive_fake_fired(unitID)
	if unitID and Spring.ValidUnitID(unitID) and bombers[unitID] and bombers[unitID].diveState == 2 then 
		temporaryDive(unitID, 150)
	end
end
GG.Bomber_Dive_fake_fired = Bomber_Dive_fake_fired

function gadget:ShieldPreDamaged(proID, proOwnerID, shieldEmitterWeaponNum, shieldCarrierUnitID, bounceProjectile)

	if proID and bomberWeaponNamesDefs[Spring.GetProjectileName(proID)] then
		if proOwnerID and Spring.ValidUnitID(proOwnerID) and bombers[proOwnerID] and bombers[proOwnerID].diveState == 1 then
			if shieldCarrierUnitID and Spring.ValidUnitID(shieldCarrierUnitID) and shieldEmitterWeaponNum then
				local wid = UnitDefs[Spring.GetUnitDefID(shieldCarrierUnitID)].weapons[shieldEmitterWeaponNum+1].weaponDef
				if WeaponDefs[wid] and WeaponDefs[wid].shieldPower >= bombers[proOwnerID].diveDamage then
					temporaryDive(proOwnerID, 150)
				end
			end
		end
		return 0
	end
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	if weaponID and bomberWeaponDefs[weaponID] then
		return -0.0001
	end
end

function gadget:GameFrame(n)
	if n%UPDATE_FREQUENCY == 0 then
		for unitID, data in pairs(bombers) do
			if data.resetTime == n then
				Spring.MoveCtrl.SetAirMoveTypeData(unitID, "wantedHeight", bombers[unitID].orgHeight)
				data.resetTime = false
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Command Handling
local function ToggleDiveCommand(unitID, cmdParams, cmdOptions)
	if bombers[unitID] then
		local state = cmdParams[1]
		if cmdOptions.right then
			state = (state - 2)%4
		end
		local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD_UNIT_BOMBER_DIVE_STATE)
		
		if (cmdDescID) then
			unitBomberDiveState.params[1] = state
			Spring.EditUnitCmdDesc(unitID, cmdDescID, { params = unitBomberDiveState.params})
		end
		bombers[unitID].diveState = state
		if state == 3 then
			Spring.MoveCtrl.SetAirMoveTypeData(unitID, "wantedHeight", bombers[unitID].diveHeight)
			bombers[unitID].resetTime = false
		elseif state == 0 then
			Spring.MoveCtrl.SetAirMoveTypeData(unitID, "wantedHeight", bombers[unitID].orgHeight)
		end
	end
	
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID ~= CMD_UNIT_BOMBER_DIVE_STATE) then
		return true  -- command was not used
	end
	ToggleDiveCommand(unitID, cmdParams, cmdOptions)  
	return false  -- command was used
end


function gadget:UnitCreated(unitID, unitDefID, teamID)

	if not bomberUnitDefs[unitDefID] then
		return
	end
	
	bombers[unitID] = {
		diveState = DEFAULT_COMMAND_STATE, -- 0 = off, 1 = with shield, 2 = when attacking, 3 = always
		diveDamage = bomberUnitDefs[unitDefID].diveDamage,
		diveHeight = bomberUnitDefs[unitDefID].diveHeight,
		orgHeight = bomberUnitDefs[unitDefID].orgHeight,
		resetTime = false,
	}
	
	Spring.MoveCtrl.SetAirMoveTypeData(unitID, "wantedHeight", bombers[unitID].orgHeight)
	
	Spring.InsertUnitCmdDesc(unitID, unitBomberDiveState)
	ToggleDiveCommand(unitID, {DEFAULT_COMMAND_STATE}, {})

end

function gadget:UnitDestroyed(unitID)
	if bombers[unitID] then
		bombers[unitID] = nil
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function gadget:Initialize()

	_G.bombers = bombers
	-- register command
	gadgetHandler:RegisterCMDID(CMD_UNIT_BOMBER_DIVE_STATE)
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
	
end


end