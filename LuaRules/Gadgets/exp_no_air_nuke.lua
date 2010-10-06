-- $Id: exp_no_air_nuke.lua 3171 2008-11-06 09:06:29Z det $

function gadget:GetInfo()
  return {
    name      = "NoAirNuke",
    desc      = "Disables the custom nuke effect, if the nuke is shoot in the air.",
    author    = "jK",
    date      = "Dec, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

local GetGroundHeight = Spring.GetGroundHeight

local nux = {}

if (not gadgetHandler:IsSyncedCode()) then
  return false
end

--// find nukes
for i=1,#WeaponDefs do
  local wd = WeaponDefs[i]
  --note that area of effect is radius, not diameter here!
  if (wd.areaOfEffect >= 300 and wd.targetable) then
    nux[wd.id] = true
    Script.SetWatchWeapon(wd.id, true)
  end
end

function gadget:Explosion(weaponID, px, py, pz, ownerID)
  if (nux[weaponID] and py-GetGroundHeight(px,pz)>100) then
    return true
  end
  return false
end
