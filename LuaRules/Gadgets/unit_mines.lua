-- $Id: unit_webweapon.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Mines",
    desc      = "Custom Minesweepers",
    author    = "CarRepairer",
    date      = "2008-12-25",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  controlled by mod option
  }
end--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local sweepRange = 150
local SYNCSTR = "unit_mines"
local spGetUnitPosition 	= Spring.GetUnitPosition
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- SYNCED
if gadgetHandler:IsSyncedCode() then  

local spGiveOrderToUnit 	= Spring.GiveOrderToUnit  
local spDestroyUnit         = Spring.DestroyUnit 
local spCreateUnit          = Spring.CreateUnit
local spDestroyUnit         = Spring.DestroyUnit
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc

local spGetUnitsInCylinder 	= Spring.GetUnitsInCylinder
local spGetUnitDefID 		= Spring.GetUnitDefID
local spGetUnitAllyTeam 	= Spring.GetUnitAllyTeam
local spGetTeamInfo			= Spring.GetTeamInfo
local spGetAllyTeamList		= Spring.GetAllyTeamList

local spSetUnitResourcing 	= Spring.SetUnitResourcing
local spSetUnitLosState		= Spring.SetUnitLosState
local spSetUnitLosMask		= Spring.SetUnitLosMask
local spSetUnitBlocking     = Spring.SetUnitBlocking
local spSetUnitCloak        = Spring.SetUnitCloak


local CMDTYPE_ICON_MODE     = CMDTYPE.ICON_MODE
local CMD_CLOAK             = CMD.CLOAK
local CMD_FIRE_STATE        = CMD.FIRE_STATE
local CMD_MOVE_STATE        = CMD.MOVE_STATE
local CMD_ONOFF             = CMD.ONOFF
local CMD_REPEAT            = CMD.REPEAT
local CMD_TRAJECTORY        = CMD.TRAJECTORY
local CMD_SELFD				= CMD.SELFD

local mineDefs = {}
local minesweeperDefs = {}
local sweepingUnits = {}
local triggeredMines = {}

local CMD_SWEEP = 35129

local sweepCmdDesc = {
  id      = CMD_SWEEP,
  type    = CMDTYPE_ICON_MODE,
  name    = 'Sweep',
  cursor  = 'Sweep',
  action  = 'sweep',
  tooltip = 'Sweep for mines.',
  params  = {0, 'Sweep Off', 'Sweep On'},
}

local function AddSweepCmdDesc(unitID)
  local insertID = 
    spFindUnitCmdDesc(unitID, CMD_CLOAK)      or
    spFindUnitCmdDesc(unitID, CMD_ONOFF)      or
    spFindUnitCmdDesc(unitID, CMD_TRAJECTORY) or
    spFindUnitCmdDesc(unitID, CMD_REPEAT)     or
    spFindUnitCmdDesc(unitID, CMD_MOVE_STATE) or
    spFindUnitCmdDesc(unitID, CMD_FIRE_STATE) or
    123456 -- back of the pack
  spInsertUnitCmdDesc(unitID, insertID + 1, sweepCmdDesc)
end

local function AddSweepUnit(unitID)
  AddSweepCmdDesc(unitID)
end


local function SweepCommand(unitID, cmdParams)
	if (type(cmdParams[1]) ~= 'number') then
		return false
	end
    
	local state = (cmdParams[1] == 1)
	local unitAllyTeam = spGetUnitAllyTeam(unitID)
	if (state) then
		SendToUnsynced(SYNCSTR, unitID, unitAllyTeam, true )
		sweepingUnits[unitID] = unitAllyTeam
		spSetUnitResourcing(unitID, 'uue', 10)
	else
		SendToUnsynced(SYNCSTR, unitID, unitAllyTeam, false )
		sweepingUnits[unitID] = nil
		spSetUnitResourcing(unitID, 'uue', 0)
	end
	local cmdDescID = spFindUnitCmdDesc(unitID, CMD_SWEEP)
	if (cmdDescID) then
		sweepCmdDesc.params[1] = (state and '1') or '0'
		spEditUnitCmdDesc(unitID, cmdDescID, { params = sweepCmdDesc.params})
	end
end

function gadget:Initialize()
	local mines = {
		cormine1 =1,
		cormine2 =1,
		cormine3 =1,
		
		armmine1 =1,
		armmine2 =1,
		armmine3 =1,
		
		armdtm =1,
		
	}
	local minesweepers = {
		pioneer		=1,
		corned 		=1,
		
		cornecro	=1,
		armrectr	=1,
		
		arm_marky	=1,
		corvoyr		=1,
		
		armseer		=1,
		corvrad		=1,
		
		armch		=1,
		corch		=1,
		
		armcs		=1,
		corcs		=1,
	}
	
	for mine,_ in pairs(mines) do
		mineDefs[UnitDefNames[mine].id] = true
	end
	for minesweeper,_ in pairs(minesweepers) do
		minesweeperDefs[UnitDefNames[minesweeper].id] = true
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if mineDefs[unitDefID] then
		local _,_,_,_,_,unitAllyTeam = spGetTeamInfo(teamID)
		local allyTeamList = spGetAllyTeamList()
		for _,allyID in ipairs (allyTeamList) do
			if allyID ~= unitAllyTeam then
				spSetUnitLosState(unitID, allyID, {los=false, prevLos=false, radar=false, contRadar=false} )
				spSetUnitLosMask(unitID, allyID, {los=true, prevLos=true, radar=true, contRadar=true} )	
			end
		end
		--spSetUnitCloak(unitID, 4)
		spSetUnitBlocking(unitID, false)
	end
	
	if (minesweeperDefs[unitDefID]) then
		AddSweepUnit(unitID)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	sweepingUnits[unitID] = nil
end

function gadget:GameFrame(n)
	for unitID,allyTeamID in pairs(sweepingUnits) do
		local x,y,z = spGetUnitPosition(unitID)
		if x then
			local unitTable = spGetUnitsInCylinder(x,z, sweepRange)
			for _,curUnitID in ipairs(unitTable) do
				if spGetUnitAllyTeam(curUnitID) ~= allyTeamID then
					local curUnitDefID = spGetUnitDefID(curUnitID)
					if mineDefs[curUnitDefID] then
						spDestroyUnit(curUnitID, true) --selfd only works with 2 params
					end
				end
			end
		end
	end
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions,fromSynced)
	if (minesweeperDefs[unitDefID] and cmdID == CMD_SWEEP) then
		SweepCommand(unitID, cmdParams)  
		return false
	end		
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else --UNSYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetGameFrame		= Spring.GetGameFrame

local glDrawGroundCircle 	= gl.DrawGroundCircle
local glLineWidth        	= gl.LineWidth
local glColor            	= gl.Color
local abs					= math.abs

local myAllyID = -1
local sweepers = {}

local function updateSweepers(_, unitID, allyID, sweeping)
	if allyID == myAllyID then
		sweepers[unitID] = sweeping or nil
	end
end

function gadget:DrawWorld()
	local pulse = abs((spGetGameFrame() % 30) - 15) / 15
	
	glLineWidth(3)
	glColor(0, 1, 1, 0.3)
	for unitID, _ in pairs(sweepers) do
		local x,y,z = spGetUnitPosition(unitID)
		if x then
			glDrawGroundCircle(x,0,z, sweepRange*pulse, 32)
		end
	end
	glLineWidth(1)
	glColor(0,0,0,0)
end

function gadget:Initialize()
  myAllyID = Spring.GetLocalAllyTeamID()
  gadgetHandler:AddSyncAction(SYNCSTR, updateSweepers)
end

end



