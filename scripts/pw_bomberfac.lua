include "constants.lua"

local spGetUnitTeam = Spring.GetUnitTeam

--pieces
local base = piece("base")
local nano1, nano2, nano3, nano4 = piece("nano1", "nano2", "nano3", "nano4")
local build = piece("build")

--local vars
local nanoPieces = {nano1, nano2, nano3, nano4}
local smokePiece = {base}

--opening animation
local function Open()
	--SetUnitValue(COB.BUGGER_OFF, 1)
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

--closing animation of the factory
local function Close()
	--SetUnitValue(COB.BUGGER_OFF, 0)
	SetUnitValue(COB.INBUILDSTANCE, 0)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
	Turn(build, x_axis, math.rad(180))
	Turn(build, z_axis, math.rad(45)) -- Just... don't ask.
end

function script.QueryBuildInfo()
	return build
end

function script.QueryLandingPads()
	return { build }
end

function script.Activate ()
	if Spring.GetUnitRulesParam(unitID, "planetwarsDisable") == 1 or GG.applyPlanetwarsDisable then
		return
	end
	
	StartThread(Open)
end

function script.Deactivate()
	StartThread(Close)
end

--death and wrecks
function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if (severity <= .25) then
		return 1 -- corpsetype
	elseif (severity <= .5) then
		return 1 -- corpsetype
	else
		return 2 -- corpsetype
	end
end
