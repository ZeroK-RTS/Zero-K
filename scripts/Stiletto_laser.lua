include "constants.lua"
include "fakeUpright.lua"

local  base, Lwing, LwingTip, Rwing, RwingTip, jet1, jet2,x,z,preDrop, drop, LBSpike, LFSpike,RBSpike, RFSpike = piece("Base", "LWing", "LWingTip", "RWing", "RWingTip", "Jet1", "Jet2","z","x","PreDrop", "Drop", "LBSpike", "LFSpike","RBSpike", "RFSpike")
smokePiece = {base, jet1, jet2}


--signals
local SIG_Aim = 1
local SIG_Fire = 2

--cob values
local CRASHING = 97
local Static_Var_1, firing
local sound_index = 0

function script.Create()
	
	Spring.UnitScript.Hide( preDrop)
	Spring.UnitScript.Hide( drop)
	FakeUprightInit(x,z,drop)

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
		if  not Static_Var_1   then
		
			Static_Var_1 = 1
			Turn( base , z_axis, math.rad(-(240.000000)), 120.000000 )
			WaitForTurn(base, z_axis)
			Turn( base , z_axis, math.rad(-(120.000000)), 180.000000 )
			WaitForTurn(base, z_axis)
			Turn( base , z_axis, math.rad(-(0.000000)), 120.000000 )
			Static_Var_1 = 0
		end
	end
end

function FireLoop()
	
Spring.UnitScript.SetSignalMask ( SIG_Fire )
  while(firing) do
	
  
  	FakeUprightTurn(unitID,x,z,preDrop,base)
  	EmitSfx( drop,  2049 )
  	if sound_index == 0 then
  	
  	    local px, py, pz = Spring.GetUnitPosition(unitID)
		Spring.PlaySoundFile("sounds/otaunit/LGHTHVY1.WAV", 10, px, py, pz)
  	end
  	sound_index = sound_index + 1
  	if sound_index >= 6 then
  	
  	    sound_index = 0
  	end
  	Sleep( 25) -- fire density
  end
end


function script.FireWeapon1()
	
	if Spring.GetUnitFuel(unitID) < 1 then
			return
	end
	
	Spring.UnitScript.Sleep( 1300) -- Delay before fire. For a burst 2, bursttime 5 bogus bomb, the target point is reached at about 2300.
	firing = 1
	StartThread(FireLoop)
	Spring.UnitScript.Sleep( 2030 ) -- Duration of burst. The number of frames is roughly (time - 30) * 1000 / 30.
	firing = 0
	Spring.UnitScript.Signal(SIG_Fire)
	Spring.UnitScript.Sleep( 500) --delay before fuel runs out, to let it retreat a little
	Spring.SetUnitFuel(unitID,0)
	
	return (0)
	
	
end

function script.QueryWeapon1()
	 return drop
end

function script.AimFromWeapon1() return base end

function script.AimWeapon1(heading, pitch)
	
	if (GetUnitValue(CRASHING) == 1) then return false end
	return true
end

function script.BlockShot1()
	return (GetUnitValue(CRASHING) == 1)
end

function script.Killed(recentDamage, maxHealth)
	local severity = (recentDamage/maxHealth) * 100
	if severity < 50 then
		Explode(base, sfxNone)
		Explode(jet1, sfxSmoke)
		Explode(jet2, sfxSmoke)
		Explode(Lwing, sfxNone)
		Explode(Rwing, sfxNone)
		return 1
	elseif severity < 100 then
		Explode(base, sfxShatter)
		Explode(jet1, sfxSmoke + sfxFire + sfxExplode)
		Explode(jet2, sfxSmoke + sfxFire + sfxExplode)
		Explode(Lwing, sfxFall + sfxSmoke)
		Explode(Rwing, sfxFall + sfxSmoke)
		return 2
	else
		Explode(base, sfxShatter)
		Explode(jet1, sfxSmoke + sfxFire + sfxExplode)
		Explode(jet2, sfxSmoke + sfxFire + sfxExplode)
		Explode(Lwing, sfxSmoke + sfxExplode)
		Explode(Rwing, sfxSmoke + sfxExplode)
		Explode(LwingTip, sfxSmoke + sfxExplode)
		Explode(RwingTip, sfxSmoke + sfxExplode)
		return 3
	end
end