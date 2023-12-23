--by Chris Mackey
include "constants.lua"

local ALLY_ACCESS = {allied = true}

--pieces
local base = piece "base"
local altar = piece "altar"
local glow = piece "glow"

local lf_leaf = piece "lf_leaf"
local lb_leaf = piece "lb_leaf"
local rf_leaf = piece "rf_leaf"
local rb_leaf = piece "rb_leaf"

local function hover()
	local spGetUnitShieldState = Spring.GetUnitShieldState
	while true do
		local shieldEnabled, shieldHealth = spGetUnitShieldState(unitID)
		Spin(glow, y_axis, shieldEnabled and (shieldHealth / -4000) or 0)
		Move(glow, y_axis, math.random()*2 + 1, 0.3)
		WaitForMove(glow, y_axis)
		Sleep (200)
		Move(glow, y_axis, math.random() + 0.2, 0.3)
		WaitForMove(glow, y_axis)
		Sleep (200)
	end
end

local function unfoldPetals(rotSpeed)
	Turn(lf_leaf, x_axis, math.rad( 35),  rotSpeed * math.rad( 35))
	Turn(lf_leaf, y_axis, math.rad( -35), rotSpeed * math.rad( 35))
	Turn(lf_leaf, z_axis, math.rad( -80), rotSpeed * math.rad( 80))
	
	Turn(rb_leaf, x_axis, math.rad( -35), rotSpeed * math.rad( 35))
	Turn(rb_leaf, y_axis, math.rad( -35), rotSpeed * math.rad( 35))
	Turn(rb_leaf, z_axis, math.rad( 80),  rotSpeed * math.rad( 80))
	
	Turn(lb_leaf, x_axis, math.rad( -45), rotSpeed * math.rad( 45))
	Turn(lb_leaf, z_axis, math.rad( -75), rotSpeed * math.rad( 75))
	Turn(lb_leaf, y_axis, math.rad( 40),  rotSpeed * math.rad( 40))
	
	Turn(rf_leaf, x_axis, math.rad( 45), rotSpeed * math.rad( 45))
	Turn(rf_leaf, z_axis, math.rad( 75), rotSpeed * math.rad( 75))
	Turn(rf_leaf, y_axis, math.rad( 40), rotSpeed * math.rad( 40))
end

local function initialize()
	Move(altar, y_axis, -3.5, 3)
	Sleep(500)
	unfoldPetals(0.5)

	WaitForMove(glow, y_axis)
	WaitForTurn(lf_leaf, x_axis)
	StartThread(hover)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, {glow})
	StartThread(initialize)
	Spring.SetUnitNanoPieces(unitID, {glow})
end

function script.StartBuilding()
	Spring.SetUnitCOBValue(unitID, COB.INBUILDSTANCE, 1)
end


function script.StopBuilding()
	Spring.SetUnitCOBValue(unitID, COB.INBUILDSTANCE, 0)
end

function script.Activate()
	Spring.SetUnitRulesParam(unitID, "shieldChargeDisabled", 0, ALLY_ACCESS)
	--spSetUnitShieldState(unitID, 1, true)
end

function script.Deactivate()
	Spring.SetUnitRulesParam(unitID, "shieldChargeDisabled", 1, ALLY_ACCESS)
	--spSetUnitShieldState(unitID, 1, false)
end

function script.Killed(recentDamage, maxHealth)
	Explode(altar, SFX.EXPLODE)
	
	Explode(lf_leaf, SFX.EXPLODE)
	Explode(rf_leaf, SFX.EXPLODE)
	Explode(lb_leaf, SFX.EXPLODE)
	Explode(rb_leaf, SFX.EXPLODE)
	
	local severity = recentDamage / maxHealth

	if (severity <= .25) then
		return 1 -- corpsetype
	elseif (severity <= .5) then
		return 1 -- corpsetype
	else
		return 2 -- corpsetype
	end
end
