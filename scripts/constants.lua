--x_axis = 1
--y_axis = 2
--z_axis = 3
SetSFXOccupy = setSFXoccupy		--standard case for function names

CRASHING = 97

SFXTYPE_VTOL = 0
--SFXTYPE_THRUST = 1
SFXTYPE_WAKE1 = 2
SFXTYPE_WAKE2 = 3
SFXTYPE_REVERSEWAKE1 = 4
SFXTYPE_REVERSEWAKE2 = 5

--SFXTYPE_POINTBASED		256
--TBD

sfxNone 		= SFX.NONE
sfxExplode 		= SFX.EXPLODE
sfxBitmap 		= SFX.BITMAP_ONLY
sfxShatter		= SFX.SHATTER
sfxFall	  		= SFX.FALL
sfxSmoke   		= SFX.SMOKE
sfxFire    		= SFX.FIRE
sfxExplodeOnHit = SFX.EXPLODE_ON_HIT

-- Explosion generators
UNIT_SFX1 = 1024
UNIT_SFX2 = 1025
UNIT_SFX3 = 1026
UNIT_SFX4 = 1027
UNIT_SFX5 = 1028
UNIT_SFX6 = 1029
UNIT_SFX7 = 1030
UNIT_SFX8 = 1031

-- Weapons
FIRE_W1 = 2048
FIRE_W2 = 2049
FIRE_W3 = 2050
FIRE_W4 = 2051
FIRE_W5 = 2052
FIRE_W6 = 2053
FIRE_W7 = 2054
FIRE_W8	= 2055

DETO_W1 = 4096
DETO_W2 = 4097
DETO_W3 = 4098
DETO_W4 = 4099
DETO_W5 = 4100
DETO_W6 = 4101
DETO_W7 = 4102
DETO_W8 = 4103

local SMOKEPUFF = 258

function SmokeUnit()
	if not (smokePiece and smokePiece[1]) then return end
	while (GetUnitValue(COB.BUILD_PERCENT_LEFT) ~= 0) do Sleep(400) end
	--Smoke loop
	while true do
		--How is the unit doing?
		local healthPercent = GetUnitValue(COB.HEALTH)
		if (healthPercent < 66) then -- only smoke if less then 2/3rd health left
			EmitSfx(smokePiece[math.random(1,#smokePiece)], SMOKEPUFF)
		end
		Sleep(8*healthPercent + math.random(100,200))
	end
end
