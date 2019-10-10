function gadget:GetInfo()
  return {
    name      = "Nuke Explosion Chooser",
    desc      = "Chooses which nuke explosion to spawn based on altitude.",
    author    = "jK, Anarchid",
    date      = "Dec, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

local GetGroundHeight = Spring.GetGroundHeight

local nux = {}
local defaultSuccessExplosion = [[LONDON_FLAT]]
local defaultInterceptExplosion = [[ANTINUKE]]

if (not gadgetHandler:IsSyncedCode()) then
  return false
end

local wantedList = {}

--// find nukes
for i = 1, #WeaponDefs do
	local wd = WeaponDefs[i]
	--note that area of effect is radius, not diameter here!
	if (wd.damageAreaOfEffect >= 800 and wd.targetable) then
		nux[wd.id] = wd.damageAreaOfEffect
		wantedList[#wantedList + 1] = wd.id
		Script.SetWatchExplosion(wd.id, true)
	end
end

function gadget:Explosion_GetWantedWeaponDef()
	return wantedList
end

function gadget:Explosion(weaponID, px, py, pz, ownerID)
	if (nux[weaponID] and py-math.max(0, GetGroundHeight(px,pz))>200) then
		Spring.SpawnCEG(defaultInterceptExplosion, px, py, pz, 0, 0, 0, nux[weaponID])
	else
		return false
	end
	return true -- always suppress engine/weapon default effects
end
