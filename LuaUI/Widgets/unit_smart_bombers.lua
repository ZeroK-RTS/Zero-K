--  Copyright (C) 2016.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Smart Bombers",
    desc      = "Automatically sets bombers to fire at will when following fight or patrol orders, and hold fire otherwise.",
    author    = "aeonios",
    date      = "Nov, 2016",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetUnitCurrentCommand = Spring.GetUnitCurrentCommand
local spGiveOrderToUnit       = Spring.GiveOrderToUnit

local myTeamID

local fightingBombers = {}
local reservedBombers = {}

local CMD_FIGHT = CMD.FIGHT
local CMD_FIRE_STATE = CMD.FIRE_STATE
local FIRESTATE_FIREATWILL = CMD.FIRESTATE_FIREATWILL or 2
local CMD_OPT_INTERNAL = CMD.OPT_INTERNAL

local bomberDefIDs = {
	[UnitDefNames["bomberprec"].id] = true,
	[UnitDefNames["bomberriot"].id] = true,
	[UnitDefNames["bomberdisarm"].id] = true,
	[UnitDefNames["bomberheavy"].id] = true,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UpdatePlayerState()
	myTeamID = Spring.GetMyTeamID()

	local whUpdateFunc = select(1, Spring.GetSpectatingState()) and widgetHandler.RemoveCallIn or widgetHandler.UpdateCallIn
	for _, callin in pairs({
		"GameFrame",
		"UnitFinished",
		"UnitDestroyed",
		"UnitGiven",
		"UnitTaken",
		"UnitCommand",
	}) do
		whUpdateFunc(widgetHandler, callin)
	end
end

local orderParamTable = {0}
local function SetFireState(unitID, fireState)
	orderParamTable[1] = fireState
	spGiveOrderToUnit(unitID, CMD_FIRE_STATE, orderParamTable, CMD_OPT_INTERNAL)
end

local function CheckBombers() -- swap bombers whose commands have changed and update their firestate

	for unitID, oldFirestate in pairs(fightingBombers) do
		if spGetUnitCurrentCommand(unitID) ~= CMD_FIGHT then
			SetFireState(unitID, oldFirestate)
			fightingBombers[unitID] = nil
			reservedBombers[unitID] = true
		end
	end

	for unitID, _ in pairs(reservedBombers) do
		if spGetUnitCurrentCommand(unitID) == CMD_FIGHT then
			local oldFirestate = Spring.Utilities.GetUnitFireState(unitID) or 0
			SetFireState(unitID, FIRESTATE_FIREATWILL)
			fightingBombers[unitID] = oldFirestate
			reservedBombers[unitID] = nil
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget interface

function widget:Initialize()
	UpdatePlayerState()

	for _, unitID in pairs(Spring.GetTeamUnits(myTeamID)) do
		widget:UnitFinished(unitID, Spring.GetUnitDefID(unitID), myTeamID)
	end
end

function widget:PlayerChanged(playerID)
	if playerID ~= Spring.GetMyPlayerID() then
		return
	end
	UpdatePlayerState()
end

function widget:GameFrame(frame)
	if frame % 15 == 0 then
		CheckBombers()
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if (unitTeam ~= myTeamID) or not bomberDefIDs[unitDefID] then
		return
	end

	if spGetUnitCurrentCommand(unitID) == CMD_FIGHT then
		local oldFirestate = Spring.Utilities.GetUnitFireState(unitID) or 0
		SetFireState(unitID, FIRESTATE_FIREATWILL)
		fightingBombers[unitID] = oldFirestate
	else
		reservedBombers[unitID] = true
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	fightingBombers[unitID] = nil
	reservedBombers[unitID] = nil
end

widget.UnitGiven = widget.UnitFinished
widget.UnitTaken = widget.UnitDestroyed

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts)
	if cmdID ~= CMD_FIRE_STATE or cmdOpts.internal or not fightingBombers[unitID] then
		return
	end
	fightingBombers[unitID] = cmdParams[1]
end
