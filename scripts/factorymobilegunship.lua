local base = piece 'base'
local pad = piece 'pad'
local beam1 = piece 'beam1'
local beam2 = piece 'beam2'
local door1 = piece 'door1'
local door2 = piece 'door2'
local post1 = piece 'post1'
local post2 = piece 'post2'
local nano1 = piece 'nano1'
local nano2 = piece 'nano2'

include "constants.lua"

-- Signal definitions
local SIG_MOVE = 1
local SIG_BUILD = 2

function script.Create()
end

function script.Activate()
end

function script.Deactivate()
end

local function StartMoving()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
end

local function Stopping()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
end

function script.StartMoving()
	StartThread(StartMoving)
end

function script.StopMoving()
	StartThread(Stopping)
end

function script.StartBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.StopBuilding()
	Signal(SIG_BUILD)
	SetUnitValue(COB.INBUILDSTANCE, 0)
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),pad)
	return pad
end

function script.Killed(recentDamage, maxHealth)
end
