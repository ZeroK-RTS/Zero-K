include "constants.lua"

local base, body, turret, torpedo = piece('base', 'body', 'turret', 'torpedo')
local rbarrel1, rbarrel2, lbarrel1, lbarrel2, rflare, lflare, mflare = piece('rbarrel1', 'rbarrel2', 'lbarrel1', 'lbarrel2', 'rflare', 'lflare', 'mflare')
local rfleg, rffoot, lfleg, lffoot, rbleg, rbfoot, lbleg, lbfoot =  piece('rfleg', 'rffoot', 'lfleg', 'lffoot', 'rbleg', 'rbfoot', 'lbleg', 'lbfoot')

local vents = {rffoot, lffoot, rbfoot, lbfoot, piece('ventf1', 'ventf2', 'ventr1', 'ventr2', 'ventr3')}

local SIG_WALK = 1
local SIG_AIM = 2
local SIG_RESTORE = 4
local SIG_BOB = 8
local SIG_FLOAT = 32

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Swim functions

local function Bob()
	Signal(SIG_BOB)
	SetSignalMask(SIG_BOB)
	
	Turn( rfleg, x_axis, math.rad(0),math.rad(60))
	Turn( rffoot, x_axis, math.rad(0),math.rad(60))
	
	Turn( rbleg, x_axis, math.rad(0),math.rad(60))
	Turn( rbfoot, x_axis, math.rad(0),math.rad(60))
	
	Move( rfleg, y_axis, 0,1)
	Move( rbleg, y_axis, 0,1)
	
	Turn( lfleg, x_axis, math.rad(0),math.rad(60))
	Turn( lffoot, x_axis, math.rad(0),math.rad(60))
	
	Turn( lbleg, x_axis, math.rad(0),math.rad(60))
	Turn( lbfoot, x_axis, math.rad(0),math.rad(60))
	
	Move( lfleg, y_axis, 0,1)
	Move( lbleg, y_axis, 0,1)
	
	while true do
		Turn(base, x_axis, math.rad(math.random(-1,1)), math.rad(math.random()) )
		Turn(base, z_axis, math.rad(math.random(-1,1)), math.rad(math.random()) )
		Move(base, y_axis, math.rad(math.random(0,3)), math.rad(math.random(1,2)) )
		Sleep(2000)
		Turn(base, x_axis, math.rad(math.random(-1,1)), math.rad(math.random()) )
		Turn(base, z_axis, math.rad(math.random(-1,1)), math.rad(math.random()) )
		Move(base, y_axis, math.rad(math.random(-3,0)), math.rad(math.random(1,2)) )
		Sleep(2000)
	end
end

local function SinkBubbles()
    SetSignalMask(SIG_FLOAT)
    while true do
        for i=1,#vents do
            EmitSfx(vents[i], SFX.BUBBLE)
        end
        Sleep(66)
    end
end
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Swim gadget callins

function Float_startFromFloor()
	Signal(SIG_WALK)
        Signal(SIG_FLOAT)
	StartThread(Bob)
end

function Float_stopOnFloor()
	Signal(SIG_BOB)
        Signal(SIG_FLOAT)
end

function Float_rising()
        Signal(SIG_FLOAT)
end

function Float_sinking()
        Signal(SIG_FLOAT)
        StartThread(SinkBubbles)
end

function Float_crossWaterline(speed)
        --Signal(SIG_FLOAT)
end

function Float_stationaryOnSurface()
        Signal(SIG_FLOAT)
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

local gunPieces = {
    [0] = {flare = lflare, recoil = lbarrel2},
    [1] = {flare = rflare, recoil = rbarrel2},
}
local gun_1 = 0
local beamCount = 0

local SPEED = 1.9

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)

	while true do
		
		local speedmult = (1 - (Spring.GetUnitRulesParam(unitID,"slowState") or 0))*SPEED

		-- right
		Turn( rfleg, x_axis, math.rad(40),math.rad(40)*speedmult)
		Turn( rffoot, x_axis, math.rad(-40),math.rad(40)*speedmult)
		
		Turn( rbleg, x_axis, math.rad(5),math.rad(10)*speedmult)
		Turn( rbfoot, x_axis, math.rad(-40),math.rad(80)*speedmult)
		
		Move( rfleg, y_axis, 0.6,1.2*speedmult)
		Move( rbleg, y_axis, 0.6,1.2*speedmult)
		
		-- left
		Turn( lfleg, x_axis, math.rad(-20),math.rad(120)*speedmult)
		Turn( lffoot, x_axis, math.rad(35),math.rad(150)*speedmult)
		
		Turn( lbleg, x_axis, math.rad(0),math.rad(45)*speedmult)
		Turn( lbfoot, x_axis, math.rad(0),math.rad(46)*speedmult)

		Move( lfleg, y_axis, 1,4.4*speedmult)
		Move( lbleg, y_axis, 1,2*speedmult)
		
		Move( body, y_axis, 1.5,1*speedmult)
		Sleep(500/speedmult) -- ****************
		
		-- right
		Turn( rbleg, x_axis, math.rad(-50),math.rad(110)*speedmult)
		Turn( rbfoot, x_axis, math.rad(50),math.rad(180)*speedmult)
		
		Move( rfleg, y_axis, 3.2,5.2*speedmult)
		Move( rbleg, y_axis, 2,2.8*speedmult)
		
		-- left
		Turn( lfleg, x_axis, math.rad(0),math.rad(40)*speedmult)
		Turn( lffoot, x_axis, math.rad(0),math.rad(80)*speedmult)
		
		Move( lfleg, y_axis, 0,2*speedmult)
		Move( lbleg, y_axis, 0,2*speedmult)
		
		Move( body, y_axis, 1,1*speedmult)
		Sleep(500/speedmult) -- ****************
		
		-- right
		Turn( rfleg, x_axis, math.rad(-20),math.rad(120)*speedmult)
		Turn( rffoot, x_axis, math.rad(35),math.rad(150)*speedmult)
		
		Turn( rbleg, x_axis, math.rad(0),math.rad(45)*speedmult)
		Turn( rbfoot, x_axis, math.rad(0),math.rad(46)*speedmult)
		
		Move( rfleg, y_axis, 1,4.4*speedmult)
		Move( rbleg, y_axis, 1,2*speedmult)
		
		
		-- left
		Turn( lfleg, x_axis, math.rad(40),math.rad(40)*speedmult)
		Turn( lffoot, x_axis, math.rad(-40),math.rad(40)*speedmult)
		
		Turn( lbleg, x_axis, math.rad(5),math.rad(10)*speedmult)
		Turn( lbfoot, x_axis, math.rad(-40),math.rad(80)*speedmult)
		
		Move( lfleg, y_axis, 0.6,1.2*speedmult)
		Move( lbleg, y_axis, 0.6,1.2*speedmult)
		
		Move( body, y_axis, 3,2*speedmult)
		Sleep(500/speedmult) -- ****************
		
		-- right
		Turn( rfleg, x_axis, math.rad(0),math.rad(40)*speedmult)
		Turn( rffoot, x_axis, math.rad(0),math.rad(80)*speedmult)
		
		Move( rfleg, y_axis, 0,2)
		Move( rbleg, y_axis, 0,2)
		
		-- left
		Turn( lbleg, x_axis, math.rad(-50),math.rad(110)*speedmult)
		Turn( lbfoot, x_axis, math.rad(50),math.rad(180)*speedmult)
		
		Move( lfleg, y_axis, 3.2,5.2*speedmult)
		Move( lbleg, y_axis, 2,2.8*speedmult)
		
		Move( body, y_axis, 1,1*speedmult)
		Sleep(500/speedmult) -- ****************
	end
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	Signal(SIG_WALK)
	
	Turn( rfleg, x_axis, math.rad(0),math.rad(60))
	Turn( rffoot, x_axis, math.rad(0),math.rad(60))
	
	Turn( rbleg, x_axis, math.rad(0),math.rad(60))
	Turn( rbfoot, x_axis, math.rad(0),math.rad(60))
	
	Move( rfleg, y_axis, 0,1)
	Move( rbleg, y_axis, 0,1)
	
	Turn( lfleg, x_axis, math.rad(0),math.rad(60))
	Turn( lffoot, x_axis, math.rad(0),math.rad(60))
	
	Turn( lbleg, x_axis, math.rad(0),math.rad(60))
	Turn( lbfoot, x_axis, math.rad(0),math.rad(60))
	
	Move( lfleg, y_axis, 0,1)
	Move( lbleg, y_axis, 0,1)
	
	GG.Floating_StopMoving(unitID)
end

function script.Create()
	Turn( rfleg, x_axis, math.rad(0))
	Turn( rffoot, x_axis, math.rad(0))
	
	Turn( rbleg, x_axis, math.rad(0))
	Turn( rbfoot, x_axis, math.rad(0))
end

function script.QueryWeapon(num)
	if num == 2 then
		if beamCount < 2 then
			if beamCount == 1 then
				Spring.SetUnitWeaponState(unitID, 1, "range", 0)
			end
			return mflare
		else
			if beamCount == 2 then
				Spring.SetUnitWeaponState(unitID, 1, "range", 550)
			end
			if beamCount >= 24 then
				beamCount = 0
			end
			return gunPieces[gun_1].flare
		end
	elseif num == 1 then
		return torpedo
	end
end

function script.AimFromWeapon(num)
	if num == 2 then
		return turret
	elseif num == 1 then
		return torpedo
	end
end

local function RestoreAfterDelay()
    Signal(SIG_RESTORE)
    SetSignalMask(SIG_RESTORE)
    Sleep(6000)
    Turn(turret, y_axis, 0, math.rad(90))
    Turn(lbarrel1, x_axis, 0, math.rad(45))
    Turn(rbarrel1, x_axis, 0, math.rad(45))    
end

function script.AimWeapon(num, heading, pitch)
	if num == 2 then
		local reloadState = Spring.GetUnitWeaponState(unitID, 1 , 'reloadState')
		if reloadState < 0 or reloadState - Spring.GetGameFrame() < 90 then
			GG.Floating_AimWeapon(unitID)
		end
		Signal(SIG_AIM)
		SetSignalMask(SIG_AIM)
		Turn(turret, y_axis, heading, math.rad(180))
		Turn(lbarrel1, x_axis, -pitch, math.rad(90))
		Turn(rbarrel1, x_axis, -pitch, math.rad(90))
		WaitForTurn(turret, y_axis)
		WaitForTurn(rbarrel1, x_axis)
        WaitForTurn(lbarrel1, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	elseif num == 1 then
		return true
	end
end

function script.Shot(num)
	if num == 2 then
		beamCount = beamCount + 1
		if beamCount > 24 then
			beamCount = 0
		end
		gun_1 = 1 - gun_1
--		for i=1,12 do
--			EmitSfx(gunPieces[gun_1].flare, 1024)
--		end
		Move(gunPieces[gun_1].recoil, z_axis, -10)
		Move(gunPieces[gun_1].recoil, z_axis, 0, 10)
	elseif num == 1 then
		local height = select(2, Spring.GetUnitPosition(unitID))

		if height < 18 then
			Spring.PlaySoundFile("sounds/weapon/torpedo.wav", 10, px, py, pz)
		else
			Spring.PlaySoundFile("sounds/weapon/torp_land.wav", 10, px, py, pz)
		end
	end
end

-- should also explode the leg pieces but I really cba...
function script.Killed(recentDamage, maxHealth)
    local severity = recentDamage/maxHealth
    if severity <= 50 then
        Explode(turret, sfxNone)
        Explode(body, sfxNone)
        return 1
    elseif severity <= 99 then
        Explode(body, sfxShatter)
        Explode(turret, sfxShatter)
        Explode(lbarrel1, sfxFall + sfxSmoke)
        Explode(rbarrel2, sfxFall + sfxSmoke)
        return 2
    else
        Explode(body, sfxShatter)
        Explode(turret, sfxShatter)
        Explode(lbarrel1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
        Explode(rbarrel2, sfxFall + sfxSmoke + sfxFire + sfxExplode)    
        return 2
    end
end
