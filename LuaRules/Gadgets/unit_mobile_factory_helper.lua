if not gadgetHandler:IsSyncedCode() then
	return
end

function gadget:GetInfo()
	return {
		name    = "Fake Factory Queue",
		desc    = "Creates fake units to store factory queues for mobile factories",
		author  = "Shaman",
		date    = "13 Jan 2024", --2013-09-05
		license = "CC-0",
		layer   = -900,
		enabled = true,
	}
end

local fakeUnits = {} -- Attach the fake units to the real units. realUnitID -> fakeUnitID
local mobileFactories = {}
local needsCreation = {}
local usingQueueMode = {}
local blockAttackCommands = {}
local needsSupport = {}

local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spCreateUnit = Spring.CreateUnit
local spGetUnitDefID = Spring.GetUnitDefID
local spDestroyUnit = Spring.DestroyUnit
local spGetUnitPosition = Spring.GetUnitPosition
local spUnitAttach = Spring.UnitAttach
local spSetUnitNoDraw = Spring.SetUnitNoDraw
local spSetUnitNoMinimap = Spring.SetUnitNoMinimap
local spSetUnitNoSelect = Spring.SetUnitNoSelect
local spSetUnitBlocking = Spring.SetUnitBlocking
local spGetUnitCommands = Spring.GetUnitCommands
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc
local spGiveOrderArrayToUnit = Spring.GiveOrderArrayToUnit
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spEditUnitCmdDesc = Spring.EditUnitCmdDesc
local spFindUnitCmdDesc = Spring.FindUnitCmdDesc
local spSetUnitCloak = Spring.SetUnitCloak

local CMD_QUEUE_MODE = Spring.Utilities.CMD.QUEUE_MODE
local CMD_AREA_GUARD = Spring.Utilities.CMD.AREA_GUARD
local CMD_JUMP = Spring.Utilities.CMD.JUMP
local CMD_ORBIT = Spring.Utilities.CMD.ORBIT
local CMD_ORBIT_DRAW = Spring.Utilities.CMD.ORBIT_DRAW
local CMD_RAW_MOVE = Spring.Utilities.CMD.RAW_MOVE
local CMD_JUMP = Spring.Utilities.CMD.JUMP
-- command --

local CommandOrder = 123456
local CommandDesc = {
	id          = CMD_QUEUE_MODE,
	type        = CMDTYPE.ICON_MODE,
	name        = 'queuemode',
	action      = 'queuemode',
	tooltip     = 'Makes queue mode!',
	params      = { '0', 'off', 'on'},
}
local StateCount = #CommandDesc.params-1

local allowedCommandsForQueue = {
	[CMD.STOP] = true,
	[CMD.INSERT] = true,
	[CMD.REMOVE] = true,
	[CMD.WAITCODE_SQUAD] = true,
	[CMD.WAITCODE_GATHER] = true,
	[CMD.WAIT] = true,
	[CMD.TIMEWAIT] = true,
	[CMD.DEATHWAIT] = true,
	[CMD.SQUADWAIT] = true,
	[CMD.GATHERWAIT] = true,
	[CMD.MOVE] = true,
	[CMD.PATROL] = true,
	[CMD.FIGHT] = true,
	[CMD.ATTACK] = true,
	[CMD.GUARD] = true,
	--[CMD.REPAIR] = true,
	--[CMD.RECLAIM] = true, -- Note: Fake factory cannot handle these! These would be "nice to have" though. FIXME for now.
	[CMD_AREA_GUARD] = true,
	[CMD_ORBIT] = true,
	[CMD_ORBIT_DRAW] = true,
	[CMD_RAW_MOVE] = true,
	[CMD_JUMP] = true,
}


local ALLIEDONLY = {
	allied = true,
}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.customParams.ismobilefac then
		needsSupport[i] = tonumber(ud.customParams.mobilefactoryattachnum) or 1
		if ud.customParams.cantreallyattack then
			blockAttackCommands[i] = true
		end
	end
end

local function AddFakeFactory(unitID)
	local x, y, z = spGetUnitPosition(unitID)
	local unitTeam = Spring.GetUnitTeam(unitID)
	local unitDefID = Spring.GetUnitDefID(unitID)
	local fakeUnitID = spCreateUnit("factoryfake", x, y, z, 1, unitTeam)
	if fakeUnitID then
		spUnitAttach(unitID, fakeUnitID, needsSupport[unitDefID])
		spSetUnitNoDraw(fakeUnitID, true)
		spSetUnitNoMinimap(fakeUnitID, true)
		spSetUnitNoSelect(fakeUnitID, true)
		spSetUnitCloak(fakeUnitID, 4)
		spSetUnitBlocking(fakeUnitID, false, false, false, false, false, false, false)
		fakeUnits[unitID] = fakeUnitID
		spSetUnitRulesParam(unitID, "queueunit", fakeUnitID, ALLIEDONLY)
		needsCreation[unitID] = nil
	else
		needsCreation[unitID] = true
	end
end

local function ToggleCommand(unitID, cmdParams)
	local state = cmdParams[1]
	local cmdDescID = spFindUnitCmdDesc(unitID, CMD_QUEUE_MODE)
	if needsCreation[unitID] then
		AddFakeFactory(unitID)
		return
	end
	if (cmdDescID) and not needsCreation[unitID] then
		CommandDesc.params[1] = state
		spEditUnitCmdDesc(unitID, cmdDescID, { params = CommandDesc.params})
	end
	if state == 1 then
		usingQueueMode[unitID] = true
	else
		usingQueueMode[unitID] = nil
	end
end

function gadget:UnitDestroyed(unitID)
	mobileFactories[unitID] = nil
	needsCreation[unitID] = nil
	if fakeUnits[unitID] then
		spDestroyUnit(fakeUnits[unitID], false, true)
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	local factoryUnit = mobileFactories[unitID]
	if factoryUnit then
		local rallyUnit = fakeUnits[factoryUnit]
		local rallyCommandList = spGetUnitCommands(rallyUnit, 300) -- put a sane limit on this so potatos can work.
		if rallyCommandList and #rallyCommandList > 0 then
			for i = 1, #rallyCommandList do
				local cmd = rallyCommandList[i]
				cmd.cmdOpts = cmd.cmdOpts or {}
				spGiveOrderToUnit(unitID, cmd.id, cmd.params, cmd.options)
			end
		end
		mobileFactories[unitID] = nil
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if builderID and not UnitDefs[unitDefID].isImmobile then
		local builderDef = spGetUnitDefID(builderID)
		if needsSupport[builderDef] then
			mobileFactories[unitID] = builderID
		end
	end
	if needsSupport[unitDefID] then
		AddFakeFactory(unitID)
		spInsertUnitCmdDesc(unitID, CommandDesc)
		if UnitDefs[unitDefID].customParams.wantsqueuemode then
			ToggleCommand(unitID, {1})
		end
	end
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
	if not needsSupport[unitDefID] then
		return true
	end
	if cmdID == CMD.ATTACK and blockAttackCommands[unitDefID] and not usingQueueMode[unitID] then
		return false
	end
	if cmdID == CMD_QUEUE_MODE then
		ToggleCommand(unitID, cmdParams)
		return false
	end
	if usingQueueMode[unitID] and allowedCommandsForQueue[cmdID] and not (cmdOptions.internal and cmdID == CMD.PATROL) then
		if needsCreation[unitID] then
			AddFakeFactory(unitID)
		end
		local fakeUnit = fakeUnits[unitID]
		spGiveOrderToUnit(fakeUnit, cmdID, cmdParams, cmdOptions)
		return false
	end
	return true
end
