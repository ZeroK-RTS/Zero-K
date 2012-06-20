include 'constants.lua'

local base, body, rfjet, lfjet, rffan, lffan, rgun, rbarrel, rflare1, rflare2, lgun, lbarrel, lflare1, lflare2, eye, rthruster, rrjet, rrfanbase, rrfan, lthruster, lrjet, lrfanbase, lrfan = piece('base', 'body', 'rfjet', 'lfjet', 'rffan', 'lffan', 'rgun', 'rbarrel', 'rflare1', 'rflare2', 'lgun', 'lbarrel', 'lflare1', 'lflare2', 'eye', 'rthruster', 'rrjet', 'rrfanbase', 'rrfan', 'lthruster', 'lrjet', 'lrfanbase', 'lrfan')

local gun = 1
local attacking = false

local spGetUnitVelocity = Spring.GetUnitVelocity

local emits = {
	{flare = rflare1, barrel = rbarrel},
	{flare = lflare1, barrel = lbarrel},
	{flare = rflare2, barrel = rbarrel},
	{flare = lflare2, barrel = lbarrel},
}

local SIG_AIM = 1
local SIG_RESTORE = 2

smokePiece = { base}

local function Activate()
	Spin( rffan , y_axis, rad(360), rad(360) )
	Spin( lffan , y_axis, rad(360), rad(360) )
	Spin( rrfan , y_axis, rad(360), rad(360) )
	Spin( lrfan , y_axis, rad(360), rad(360) )
	Sleep(60)
end

local function Deactivate()
	Spin( rffan , y_axis, rad(0), rad(360) )
	Spin( lffan , y_axis, rad(0), rad(360) )
	Spin( rrfan , y_axis, rad(0), rad(360) )
	Spin( lrfan , y_axis, rad(0), rad(360) )
	Sleep(60)
end

local function TiltBody()

	while  true  do
		if attacking then
			Turn( body , x_axis, 0, math.rad(45) )
			Turn( rthruster , x_axis, 0, math.rad(45) )
			Turn( lthruster , x_axis, 0, math.rad(45) )
			Sleep(250)
		else
			local vx,_,vz = spGetUnitVelocity(unitID)
			local speed = vx*vx + vz*vz
			if speed > 0.5 then
				Turn( body , x_axis, math.rad(22.5), math.rad(45) )
				Turn( rthruster , x_axis, math.rad(22.5), math.rad(45) )
				Turn( lthruster , x_axis, math.rad(22.5), math.rad(45) )
				Sleep(250)
			else
				Turn( body , x_axis, 0, math.rad(45) )
				Turn( rthruster , x_axis, 0, math.rad(45) )
				Turn( lthruster , x_axis, 0, math.rad(45) )
				Sleep(250)
			end
		end
	end
end

function script.Create()
	
	Turn( rfjet , x_axis, math.rad(-90) )
	Turn( lfjet , x_axis, math.rad(-90) )
	Turn( rrjet , x_axis, math.rad(-90) )
	Turn( lrjet , x_axis, math.rad(-90) )

	Turn( rrfanbase , z_axis, math.rad(-22.5) )
	Turn( lrfanbase , z_axis, math.rad(22.5) )

	StartThread(SmokeUnit)
	StartThread(TiltBody)
end

local function RestoreAfterDelay()
	
	Signal( SIG_RESTORE)
	SetSignalMask( SIG_RESTORE)

	Sleep(3000)
	attacking = false
end

function script.AimWeapon(num,heading,pitch)

	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)

	attacking = true
	Sleep(30)
	
	StartThread(RestoreAfterDelay)
	return true
end

function script.QueryWeapon(num)
	return emits[gun].flare
end

function script.AimFromWeapon(num)
	return eye
end

function script.Shot(num)
	EmitSfx( emits[gun].flare,  1024 )
	EmitSfx( emits[gun].barrel,  1025 )
	gun = (gun)%4 + 1
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if  severity <= 0.25  then
		return 1
	elseif severity <= 0.50  then
		Explode(base, sfxFall)
		Explode(body, sfxShatter)
		Explode(rthruster, sfxFall)
		Explode(lthruster, sfxFall)
		Explode(rffan, sfxShatter)
		Explode(lffan, sfxShatter)
		return 1
	else
		Explode(body, sfxShatter)
		Explode(rfjet, sfxFall + sfxFire)
		Explode(lfjet, sfxFall + sfxFire)
		Explode(rffan, sfxFall + sfxFire)
		Explode(lffan, sfxFall + sfxFire)
		Explode(rgun, sfxExplode)
		Explode(rbarrel, sfxExplode)
		Explode(rflare1, sfxExplode)
		Explode(rflare2, sfxExplode)
		Explode(lgun, sfxExplode)
		Explode(lbarrel, sfxExplode)
		Explode(lflare1, sfxExplode)
		Explode(lflare2, sfxExplode)
		Explode(eye, sfxExplode)
		Explode(rthruster, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(rrjet, sfxExplode)
		Explode(rrfanbase, sfxExplode)
		Explode(rrfan, sfxExplode)
		Explode(lthruster, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(lrjet, sfxExplode)
		Explode(lrfanbase, sfxExplode)
		Explode(lrfan, sfxExplode)
		return 2
	end
end
