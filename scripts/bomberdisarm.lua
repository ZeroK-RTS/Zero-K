include "constants.lua"
include "fakeUpright.lua"
include "bombers.lua"
include "fixedwingTakeOff.lua"

local base, Lwing, LwingTip, Rwing, RwingTip, jet1, jet2,xp,zp,preDrop, drop, LBSpike, LFSpike,RBSpike, RFSpike = piece("Base", "LWing", "LWingTip", "RWing", "RWingTip", "Jet1", "Jet2","x","z","PreDrop", "Drop", "LBSpike", "LFSpike","RBSpike", "RFSpike")
local smokePiece = {base, jet1, jet2}

local doingRun = false
local preDropMoved = false
local sound_index = 0
local BOMB_DELAY = 1

local SIG_TAKEOFF = 1
local takeoffHeight = UnitDefNames["bomberdisarm"].wantedHeight

function script.Create()
	SetInitialBomberSettings()
	Hide(preDrop)
	Hide(drop)
	
	GG.FakeUpright.FakeUprightInit(xp, zp, drop)
	Turn(Lwing, z_axis, math.rad(90))
	Turn(Rwing, z_axis, math.rad(-90))
	Turn(LwingTip, z_axis, math.rad(-165))
	Turn(RwingTip, z_axis, math.rad(165))
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
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
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
end


function script.FireWeapon(checkHeight)
	if doingRun then
		return
	end
	if RearmBlockShot() then
		return
	end
	SetUnarmedAI()
	
	doingRun = true
	
	local i = 1
	while i <= 80 do
		local stunned_or_inbuild = Spring.GetUnitIsStunned(unitID) or (Spring.GetUnitRulesParam(unitID,"disarmed") == 1)
		if not stunned_or_inbuild then
			
			if checkHeight then
				local x, y, z = Spring.GetUnitPosition(unitID)
				local height = math.max(0, Spring.GetGroundHeight(x, z))
				if height + 15 > y then
					Move(preDrop, y_axis, math.max(15, height - y))
					preDropMoved = true
				elseif preDropMoved then
					Move(preDrop, y_axis,0)
					preDropMoved = false
				end
			end
			
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
	
			Turn(preDrop, x_axis, angle_x)
			Turn(preDrop, z_axis, -angle_z)
			
			EmitSfx(drop, GG.Script.FIRE_W2)
			if sound_index == 0 then
				local px, py, pz = Spring.GetUnitPosition(unitID)
				Spring.PlaySoundFile("sounds/weapon/LightningBolt.wav", 4, px, py, pz)
			end
			sound_index = sound_index + 1
			if sound_index >= 6 then
				sound_index = 0
			end
			i = i + 1
		end
		local slowMult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)
		Sleep(35/slowMult) -- fire density
	end
	
	doingRun = false
	Reload()
end

function StartRun()
	script.FireWeapon(true)
end

function script.QueryWeapon()
	return drop
end

function script.AimFromWeapon()
	return drop
end

function script.AimWeapon(heading, pitch)
	if (GetUnitValue(GG.Script.CRASHING) == 1) then
		return false
	end
	return true
end

function script.BlockShot()
	return (GetUnitValue(GG.Script.CRASHING) == 1)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 or (Spring.GetUnitMoveTypeData(unitID).aircraftState == "crashing") then
		Explode(base, SFX.NONE)
		Explode(jet1, SFX.SMOKE)
		Explode(jet2, SFX.SMOKE)
		Explode(Lwing, SFX.NONE)
		Explode(Rwing, SFX.NONE)
		return 1
	elseif severity < 0.75 then
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
