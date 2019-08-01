include "constants.lua"

local base, Lwing, LwingTip, Rwing, RwingTip, jet1, jet2, drop, LBSpike, LFSpike,RBSpike, RFSpike = piece("Base", "LWing", "LWingTip", "RWing", "RWingTip", "Jet1", "Jet2", "Drop", "LBSpike", "LFSpike","RBSpike", "RFSpike")
local smokePiece = {base, jet1, jet2}

--constants



--signals
local SIG_Aim = 1

--cob values

function script.Create()	
	Turn(Lwing, z_axis, math.rad(90))
	Turn(Rwing, z_axis, math.rad(-90))	
	Turn(LwingTip, z_axis, math.rad(-165))
	Turn(RwingTip, z_axis, math.rad(165))
	
end

function script.Activate()
	
	Turn(Lwing, z_axis, math.rad(90), 2)
	Turn(Rwing, z_axis, math.rad(-90), 2)
	Turn(LwingTip, z_axis, math.rad(-165), 2) --160
	Turn(RwingTip, z_axis, math.rad(165), 2) -- -160
end

function script.Deactivate()
	Turn(Lwing, z_axis, math.rad(10), 2)
	Turn(Rwing, z_axis, math.rad(-10), 2)
	Turn(LwingTip, z_axis, math.rad(-30), 2) -- -30
	Turn(RwingTip, z_axis, math.rad(30), 2) --30
end

function script.MoveRate(moveRate)

	if moveRate == 2 then
		if not Static_Var_1 then
		
			Static_Var_1 = 1
			Turn(base, z_axis, math.rad(-(240.000000)), 120.000000)
			WaitForTurn(base, z_axis)
			Turn(base, z_axis, math.rad(-(120.000000)), 180.000000)
			WaitForTurn(base, z_axis)
			Turn(base, z_axis, math.rad(-(0.000000)), 120.000000)
			Static_Var_1 = 0
		end
	end
end



function script.QueryWeapon1()
	 return drop
end

function script.AimFromWeapon1() return base end

function script.AimWeapon1(heading, pitch)
	
	if (GetUnitValue(GG.Script.CRASHING) == 1) then return false end
	return true
end

function script.BlockShot1()
	return (GetUnitValue(GG.Script.CRASHING) == 1)
end

function script.Killed(recentDamage, maxHealth)
	local severity = (recentDamage/maxHealth) * 100
	if severity < 50 then
		Explode(base, SFX.NONE)
		Explode(jet1, SFX.SMOKE)
		Explode(jet2, SFX.SMOKE)
		Explode(Lwing, SFX.NONE)
		Explode(Rwing, SFX.NONE)
		return 1
	elseif severity < 100 then
		Explode(base, SFX.SHATTER)
		Explode(jet1, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(jet2, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(Lwing, SFX.FALL + SFX.SMOKE)
		Explode(Rwing, SFX.FALL + SFX.SMOKE)
		return 2
	else
		Explode(base, SFX.SHATTER)
		Explode(jet1, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(jet2, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(Lwing, SFX.SMOKE + SFX.EXPLODE)
		Explode(Rwing, SFX.SMOKE + SFX.EXPLODE)
		Explode(LwingTip, SFX.SMOKE + SFX.EXPLODE)
		Explode(RwingTip, SFX.SMOKE + SFX.EXPLODE)
		return 2
	end
end