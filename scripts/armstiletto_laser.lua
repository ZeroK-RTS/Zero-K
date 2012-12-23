include "constants.lua"
include "fakeUpright.lua"
include "bombers.lua"

local  base, Lwing, LwingTip, Rwing, RwingTip, jet1, jet2,xp,zp,preDrop, drop, LBSpike, LFSpike,RBSpike, RFSpike = piece("Base", "LWing", "LWingTip", "RWing", "RWingTip", "Jet1", "Jet2","x","z","PreDrop", "Drop", "LBSpike", "LFSpike","RBSpike", "RFSpike")
local smokePiece = {base, jet1, jet2}

local sound_index = 0
local BOMB_DELAY = 1

function script.Create()
	Hide( preDrop)
	Hide( drop)
	
	FakeUprightInit(xp, zp, drop)
	
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

function script.FireWeapon1()
	if Spring.GetUnitFuel(unitID) < 1 or Spring.GetUnitRulesParam(unitID, "noammo") == 1 then
		return
	end
	
	for i = 1, 80 do
		local xx, xy, xz = Spring.GetUnitPiecePosDir(unitID,xp)
		local zx, zy, zz = Spring.GetUnitPiecePosDir(unitID,zp)
		local bx, by, bz = Spring.GetUnitPiecePosDir(unitID,base)
		local xdx = xx - bx
		local xdy = xy - by
		local xdz = xz - bz
		local zdx = zx - bx
		local zdy = zy - by
		local zdz = zz - bz
		local angle_x = math.atan2(xdy, math.sqrt(xdx^2 + xdz^2))
		local angle_z = math.atan2(zdy, math.sqrt(zdx^2 + zdz^2))

		Turn( preDrop , x_axis, angle_x)
		Turn( preDrop , z_axis, -angle_z)
		
		EmitSfx( drop,  FIRE_W2 )
		if sound_index == 0 then
			local px, py, pz = Spring.GetUnitPosition(unitID)
			Spring.PlaySoundFile("sounds/weapon/LightningBolt.wav", 4, px, py, pz)
		end
		sound_index = sound_index + 1
		if sound_index >= 6 then
			sound_index = 0
		end
		
		Sleep(35) -- fire density
	end
	
	Reload()
end


function script.QueryWeapon1()
	return drop
end

function script.AimFromWeapon1() 
	return drop 
end

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
		return 2
	end
end