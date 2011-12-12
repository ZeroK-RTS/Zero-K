-- $Id: lups_shockwaves.lua 3171 2008-11-06 09:06:29Z det $

function gadget:GetInfo()
  return {
    name      = "Shockwaves",
    desc      = "",
    author    = "jK",
    date      = "Jan. 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end


if (gadgetHandler:IsSyncedCode()) then

  --// find weapons which cause a shockwave
  for i=1,#WeaponDefs do
    local wd = WeaponDefs[i]
    if (not wd.description:find("ChickenKick")) then
      if (wd.damageAreaOfEffect>70 and not wd.paralyzer) then
        Script.SetWatchWeapon(wd.id,true)
      elseif (wd.type == "DGun") then
        Script.SetWatchWeapon(wd.id,true)
      --elseif (wd.description:find("Clogger")) then
      --  Script.SetWatchWeapon(wd.id,true)
      end
    end
  end

  function gadget:Explosion(weaponID, px, py, pz, ownerID)
    local wd = WeaponDefs[weaponID]
    --if (wd.description=="PlasmaImplosionDumpRocket") then --// Liche
    --  SendToUnsynced("lups_shockwave", px, py, pz, 6.4, 30, 0.13, true)
    --  return true
    --else
    if (wd.type == "DGun") then
      SendToUnsynced("lups_shockwave", px, py, pz, 4.0, 18, 0.13, true)
    else
      --local growth = wd.explosionSpeed
      --local life = wd.areaOfEffect / wd.explosionSpeed
      local growth = (wd.damageAreaOfEffect*1.1)/20
      local life = 23
      SendToUnsynced("lups_shockwave", px, py, pz, growth, life)
    end

    return false
  end

else

  local function SpawnShockwave(_,px,py,pz, growth, life, strength, desintergrator)
    local Lups = GG['Lups']
    if (desintergrator) then
      Lups.AddParticles('SphereDistortion',{pos={px,py,pz}, life=life, strength=strength, growth=growth})
    else
      Lups.AddParticles('ShockWave',{pos={px,py,pz}, growth=growth, life=life})
    end
  end

  function gadget:Initialize()
    gadgetHandler:AddSyncAction("lups_shockwave", SpawnShockwave)
  end

  function gadget:Shutdown()
    gadgetHandler.RemoveSyncAction("lups_shockwave")
  end

end