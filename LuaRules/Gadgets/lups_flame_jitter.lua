-- $Id: lups_flame_jitter.lua 3643 2009-01-03 03:00:52Z jk $
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Lups Flamethrower Jitter",
    desc      = "Flamethrower jitter FX with LUPS",
    author    = "jK",
    date      = "Apr, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end

if (Game.version=="0.76b1") then
	return false
end


if (gadgetHandler:IsSyncedCode()) then
-------------------------------------------------------------------------------------
-- -> SYNCED
-------------------------------------------------------------------------------------

  --// Speed-ups
  local SendToUnsynced = SendToUnsynced

  -------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------

  local thisGameFrame = 0
  local lastLupsSpawn = {}

  function FlameShot(unitID,unitDefID,_, weapon)
    if ( ((lastLupsSpawn[unitID] or 0) - thisGameFrame) <= -15 ) then
      lastLupsSpawn[unitID] = thisGameFrame
      SendToUnsynced("flame_FlameShot", unitID, unitDefID, weapon)
    end
  end


  function gadget:GameFrame(n)
    thisGameFrame = n
    SendToUnsynced("flame_GameFrame")
  end

  -------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------

  function gadget:Initialize()
    gadgetHandler:RegisterGlobal("FlameShot",FlameShot)
    gadgetHandler:RegisterGlobal("FlameSetDir",FlameSetDir)
    gadgetHandler:RegisterGlobal("FlameSetFirePoint",FlameSetFirePoint)
  end

  function gadget:Shutdown()
    gadgetHandler:DeregisterGlobal("FlameShot")
    gadgetHandler:DeregisterGlobal("FlameSetDir")
    gadgetHandler:DeregisterGlobal("FlameSetFirePoint")
  end

else
-------------------------------------------------------------------------------------
-- -> UNSYNCED
-------------------------------------------------------------------------------------

  local particleCnt  = 1
  local particleList = {}

  local lastShoot = {}

  function FlameShot(_,unitID, unitDefID, weapon)
    local n = Spring.GetGameFrame()
    if ((lastShoot[unitID] or 0) > (n-10) ) then
      return
    end
    lastShoot[unitID] = n

    local posx,posy,posz, dirx,diry,dirz = Spring.GetUnitWeaponVectors(unitID,weapon-1)
    local wd  = WeaponDefs[UnitDefs[unitDefID].weapons[weapon].weaponDef]
    local weaponRange = wd.range*wd.duration

    local speedx,speedy,speedz = Spring.GetUnitVelocity(unitID)
    local partpos = "x*delay,y*delay,z*delay|x="..speedx..",y="..speedy..",z="..speedz

    particleList[particleCnt] = {
      class        = 'JitterParticles2',
      colormap     = { {1,1,1,1},{1,1,1,1} },
      count        = 6,
      life         = weaponRange / 12,
      delaySpread  = 25,
      force        = {0,1.5,0},
      --forceExp     = 0.2,

      partpos      = partpos,
      pos          = {posx,posy,posz},

      emitVector   = {dirx,diry,dirz},
      emitRotSpread= 10,

      speed        = 7,
      speedSpread  = 0,
      speedExp     = 1.5,

      size         = 15,
      sizeGrowth   = 5.0,

      scale        = 1.5,
      strength     = 1.0,
      heat         = 2,
    }
    particleCnt = particleCnt + 1

    particleList[particleCnt] = {
      class        = 'SimpleParticles2',
      colormap     = { {1, 1, 1, 0.01},
                       {1, 1, 1, 0.01},
                       {0.75, 0.5, 0.5, 0.01},
                       {0.35, 0.15, 0.15, 0.25},
                       {0.1, 0.035, 0.01, 0.2},
                       {0, 0, 0, 0.01} },
      count        = 4,
      life         = weaponRange / 12,
      delaySpread  = 25,

      force        = {0,1,0},
      --forceExp     = 0.2,

      partpos      = partpos,
      pos          = {posx,posy,posz},

      emitVector   = {dirx,diry,dirz},
      emitRotSpread= 8,

      rotSpeed     = 1,
      rotSpread    = 360,
      rotExp       = 9,

      speed        = 7,
      speedSpread  = 0,
      speedExp     = 1.5,

      size         = 2,
      sizeGrowth   = 4.0,
      sizeExp      = 0.7,

      --texture     = "bitmaps/smoke/smoke06.tga",
      texture     = "bitmaps/GPL/flame.png",
    }
    particleCnt = particleCnt + 1

    particleList[particleCnt] = {
      class        = 'SimpleParticles2',
      colormap     = { {1, 1, 1, 0.01}, {0, 0, 0, 0.01} },
      count        = 20,
      --delay        = 20,
      life         = weaponRange / 48,
      lifeSpread   = 20,
      delaySpread  = 15,

      force        = {0,1,0},
      --forceExp     = 0.2,

      partpos      = partpos,
      pos          = {posx,posy,posz},

      emitVector   = {dirx,diry,dirz},
      emitRotSpread= 3,

      rotSpeed     = 1,
      rotSpread    = 360,
      rotExp       = 9,

      speed        = 7,
      speedSpread  = 0,

      size         = 2,
      sizeGrowth   = 4.0,
      sizeExp      = 0.65,

      --texture     = "bitmaps/smoke/smoke06.tga",
      texture     = "bitmaps/GPL/flame.png",
    }
    particleCnt = particleCnt + 1

  end

  function GameFrame()
    if (particleCnt>1) then
      particleList.n = particleCnt
      GG.Lups.AddParticlesArray(particleList)
      particleList = {}
      particleCnt  = 1
    end
  end

  -------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------

  function gadget:Initialize()
    gl.DeleteTexture("bitmaps/GPL/flame.png")
    gadgetHandler:AddSyncAction("flame_GameFrame", GameFrame)
    gadgetHandler:AddSyncAction("flame_FlameShot", FlameShot)
  end

  function gadget:Shutdown()
    gadgetHandler:RemoveSyncAction("flame_FlameShot")
  end

end