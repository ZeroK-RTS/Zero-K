include "constants.lua"
include "bombers.lua"

local fuselage = piece 'fuselage' 
local wingl = piece 'wingl' 
local wingr = piece 'wingr' 
local enginel = piece 'enginel' 
local enginer = piece 'enginer' 
local head = piece 'head' 
local turretbase = piece 'turretbase' 
local turret = piece 'turret' 
local sleevel = piece 'sleevel' 
local sleever = piece 'sleever' 
local barrell = piece 'barrell' 
local barrelr = piece 'barrelr' 
local flarel = piece 'flarel' 
local flarer = piece 'flarer' 
local bombl = piece 'bombl' 
local bombr = piece 'bombr' 

local bFirepoint1 = false
local bFirepoint2 = false
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function script.Create()
	Turn(turret, y_axis, math.pi)
	StartThread(GG.Script.SmokeUnit, smokePiece)
	Move(wingl, x_axis, -5, 7)
	Move(wingr, x_axis, 5, 7)
	Hide(turretbase)
	Hide(turret)
	Hide(sleevel)
	Hide(barrell)
	Hide(sleever)
	Hide(barrelr)
end

function script.Activate()
	Move(wingl, x_axis, 0, 7)
	Move(wingr, x_axis, 0, 7)
end

function script.Deactivate()
	Move(wingl, x_axis, -5, 7)
	Move(wingr, x_axis, 5, 7)
end

local function RestoreAfterDelay()
	Sleep(Static_Var_1)
	Turn(turret, y_axis, math.rad(180), math.rad(90))
	Turn(sleevel, x_axis, 0, math.rad(50))
	Turn(sleever, x_axis, 0, math.rad(50))
end

function script.AimWeapon(num, heading, pitch)
	return true
end

function script.QueryWeapon(num)
	if num == 1 then
	return bFirepoint1 and bombl or bombr
	elseif num == 2 then
	return bFirepoint2 and flarel or flarer
	end
end

function script.AimFromWeapon(num)
	if num == 1 then
	return bFirepoint1 and bombl or bombr
	elseif num == 2 then
	return bFirepoint2 and flarel or flarer
	end
end

function script.AimWeapon(num, heading, pitch)
	if num == 1 then
		return (Spring.GetUnitRulesParam(unitID, "noammo") ~= 1)
	elseif num == 2 then
		Signal(SIG_AIM_2)
		SetSignalMask(SIG_AIM_2)
		Turn(turret, y_axis, math.rad(heading), math.rad(390))
		Turn(sleevel, x_axis, 0, math.rad(350))
		Turn(sleever, x_axis, 0, math.rad(350))
		WaitForTurn(turret, y_axis)
		WaitForTurn(sleevel, x_axis)
		WaitForTurn(sleever, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	end
end


function script.Shot(num)
	if num == 1 then
	bFirepoint1 = not bFirepoint1
	elseif num == 2 then
	EmitSfx(turret, 1025)
	if bFirepoint2 then
		EmitSfx(flarel, 1024)
	else
		EmitSfx(flarer, 1024)
	end
	bFirepoint2 = not bFirepoint2
	end
end

function script.FireWeapon(num)
	if num == 1 then
	Sleep(66)
	Reload()
	end
end

function script.AimFromWeapon(num)
	return bFirepoint2 and flarel or flarer
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .5 then
	Explode(fuselage, SFX.NONE)
	Explode(head, SFX.NONE)
	Explode(wingl, SFX.NONE)
	Explode(wingr, SFX.NONE)
	Explode(enginel, SFX.NONE)
	Explode(enginer, SFX.NONE)
	Explode(turret, SFX.NONE)
	Explode(sleevel, SFX.NONE)
	Explode(sleever, SFX.NONE)
	return 1
	else	
	Explode(fuselage, SFX.FALL + SFX.SMOKE)
	Explode(head, SFX.FALL + SFX.SMOKE + SFX.FIRE)
	Explode(wingl, SFX.FALL + SFX.SMOKE)
	Explode(wingr, SFX.FALL + SFX.SMOKE)
	Explode(enginel, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
	Explode(enginer, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
	Explode(turret, SFX.FALL + SFX.SMOKE + SFX.FIRE)
	Explode(sleevel, SFX.FALL + SFX.SMOKE)
	Explode(sleever, SFX.FALL + SFX.SMOKE)
	return 2
	end
end
