include "constants.lua"

local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitIsBuilding = Spring.GetUnitIsBuilding
local spGetUnitHealth = Spring.GetUnitHealth

local base = piece 'base'
local floatl, floatr = piece('float_l','float_r')
local pad = piece 'pad'
local pontoon = piece 'pontoon'

local emitPieces = {piece('emit04', 'emit08', 'emit012')}

local smokePiece = {base}

-- Signal definitions
local SIG_BUILD = 2

--[[
local function PadAdjust()
	Signal(SIG_BUILD)
	SetSignalMask(SIG_BUILD)
	while true do
		local buildee = spGetUnitIsBuilding(unitID)
		--Spring.Echo(buildee)
		if buildee then
			local progress = select(5, spGetUnitHealth(buildee))
			Move(pad, z_axis, -20 + (40*progress))
			--Spring.Echo(progress)
		else
			Move(pad, z_axis, -20)
		end
		Sleep(500)
	end
end
]]

local function Unstick()
	Signal(SIG_BUILD)
	SetSignalMask(SIG_BUILD)
	GG.Script.UnstickFactory(unitID)
end

function script.Activate()
	--StartThread(PadAdjust)
	--[[
	SetUnitValue(YARD_OPEN, 1)	--Tobi said its not necessary
	while GetUnitValue(YARD_OPEN) ~= 1 do
		SetUnitValue(BUGGER_OFF, 1)
		Sleep(1500)
	end
	]]--
	SetUnitValue(COB.INBUILDSTANCE, 1)
	--SetUnitValue(COB.BUGGER_OFF, 0)
	StartThread(Unstick)
end

function script.Deactivate()
	--[[
	SetUnitValue(YARD_OPEN, 1)	--Tobi said its not necessary
	while GetUnitValue(YARD_OPEN) ~= 0 do
		SetUnitValue(BUGGER_OFF, 1)
		Sleep(1500)
	end
	]]--
	Signal(SIG_BUILD)
	SetUnitValue(COB.INBUILDSTANCE, 0)
	--SetUnitValue(COB.BUGGER_OFF, 0)
	Move(pad, z_axis, 0)
end


function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Spring.SetUnitNanoPieces(unitID, emitPieces)
end

function script.QueryBuildInfo()
	return pad
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(base, SFX.NONE)
		Explode(pontoon, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(base, SFX.NONE)
		Explode(pontoon, SFX.NONE)
		return 2
	elseif severity <= .99 then
		Explode(base, SFX.NONE)
		Explode(pontoon, SFX.NONE)
		return 2
	else
		Explode(base, SFX.NONE)
		Explode(pontoon, SFX.NONE)
		return 2
	end
end
