include "constants.lua"

local base, body, turret, rbarrel1, rbarrel2, lbarrel1, lbarrel2, rflare, lflare = piece('base', 'body', 'turret', 'rbarrel1', 'rbarrel2', 'lbarrel1', 'lbarrel2', 'rflare', 'lflare')
local rfleg, rffoot, lfleg, lffoot, rbleg, rbfoot, lbleg, lbfoot =  piece('rfleg', 'rffoot', 'lfleg', 'lffoot', 'rbleg', 'rbfoot', 'lbleg', 'lbfoot')

local SIG_WALK = 1
local SIG_AIM = 2
local SIG_RESTORE = 4

local gunPieces = {
    [0] = {flare = lflare, recoil = lbarrel2},
    [1] = {flare = rflare, recoil = rbarrel2},

}
local gun_1 = 0

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)

	while true do
		
		-- right
		Turn( rfleg, x_axis, math.rad(40),math.rad(40))
		Turn( rffoot, x_axis, math.rad(-40),math.rad(40))
		
		Turn( rbleg, x_axis, math.rad(5),math.rad(10))
		Turn( rbfoot, x_axis, math.rad(-40),math.rad(80))
		
		Move( rfleg, y_axis, 0.3,0.6)
		Move( rbleg, y_axis, 0.3,0.6)
		
		-- left
		Turn( lfleg, x_axis, math.rad(-20),math.rad(120))
		Turn( lffoot, x_axis, math.rad(35),math.rad(150))
		
		Turn( lbleg, x_axis, math.rad(0),math.rad(45))
		Turn( lbfoot, x_axis, math.rad(0),math.rad(46))

		Move( lfleg, y_axis, 0.5,2.2)
		Move( lbleg, y_axis, 0.5,1)
		
		Move( body, y_axis, 1,1)
		Sleep(500) -- ****************
		
		-- right
		Turn( rbleg, x_axis, math.rad(-50),math.rad(110))
		Turn( rbfoot, x_axis, math.rad(50),math.rad(180))
		
		Move( rfleg, y_axis, 1.6,2.6)
		Move( rbleg, y_axis, 1,1.4)
		
		-- left
		Turn( lfleg, x_axis, math.rad(0),math.rad(40))
		Turn( lffoot, x_axis, math.rad(0),math.rad(80))
		
		Move( lfleg, y_axis, 0,1)
		Move( lbleg, y_axis, 0,1)
		
		Move( body, y_axis, 0.5,1)
		Sleep(500) -- ****************
		
		-- right
		Turn( rfleg, x_axis, math.rad(-20),math.rad(120))
		Turn( rffoot, x_axis, math.rad(35),math.rad(150))
		
		Turn( rbleg, x_axis, math.rad(0),math.rad(45))
		Turn( rbfoot, x_axis, math.rad(0),math.rad(46))
		
		Move( rfleg, y_axis, 0.5,2.2)
		Move( rbleg, y_axis, 0.5,1)
		
		
		-- left
		Turn( lfleg, x_axis, math.rad(40),math.rad(40))
		Turn( lffoot, x_axis, math.rad(-40),math.rad(40))
		
		Turn( lbleg, x_axis, math.rad(5),math.rad(10))
		Turn( lbfoot, x_axis, math.rad(-40),math.rad(80))
		
		Move( lfleg, y_axis, 0.3,0.6)
		Move( lbleg, y_axis, 0.3,0.6)
		
		Move( body, y_axis, 1,1)
		Sleep(500) -- ****************
		
		-- right
		Turn( rfleg, x_axis, math.rad(0),math.rad(40))
		Turn( rffoot, x_axis, math.rad(0),math.rad(80))
		
		Move( rfleg, y_axis, 0,1)
		Move( rbleg, y_axis, 0,1)
		
		-- left
		Turn( lbleg, x_axis, math.rad(-50),math.rad(110))
		Turn( lbfoot, x_axis, math.rad(50),math.rad(180))
		
		Move( lfleg, y_axis, 1.6,2.6)
		Move( lbleg, y_axis, 1,1.4)
		
		Move( body, y_axis, 0.5,1)
		Sleep(500) -- ****************
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
	
end

function script.Create()
	Turn( rfleg, x_axis, math.rad(0))
	Turn( rffoot, x_axis, math.rad(0))
	
	Turn( rbleg, x_axis, math.rad(0))
	Turn( rbfoot, x_axis, math.rad(0))
end

function script.QueryWeapon(num)
    return gunPieces[gun_1].flare
end

function script.AimFromWeapon(num)
    return turret
end

local function RestoreAfterDelay()
    Signal(SIG_RESTORE)
    SetSignalMask(SIG_RESTORE)
    Sleep(6000)
    Turn(turret, y_axis, 0, math.rad(90))
    Turn(lbarrel1, x_axis, 0, math.rad(45))
    Turn(lbarrel2, x_axis, 0, math.rad(45))    
end

function script.AimWeapon(num, heading, pitch)
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
end

function script.FireWeapon(num)
    EmitSfx(gunPieces[gun_1].flare, 1024)
    Move(gunPieces[gun_1].recoil, z_axis, -10)
    Move(gunPieces[gun_1].recoil, z_axis, 0, 5)
    gun_1 = 1 - gun_1
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
