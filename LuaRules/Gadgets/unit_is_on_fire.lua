-- $Id: unit_is_on_fire.lua 3309 2008-11-28 04:25:20Z google frog $

function gadget:GetInfo()
  return {
    name      = "Units on fire",
    desc      = "Aaagh! It burns! It burns!",
    author    = "quantum",
    date      = "Mar, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
-- BEGIN SYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Spring.SetGameRulesParam("unitsOnFire",1)

--//SETTINGS

local fireDmg   = 0.5 --// in 1/gameframe
local allyBonus = 1 --// do less damage to allied units

--//VARS

local gameFrame = 0

--//LOCALS

local random = math.random
local Spring = Spring
local gadget = gadget
local AreTeamsAllied    = Spring.AreTeamsAllied
local GetGameFrame      = Spring.GetGameFrame
local AddUnitDamage     = Spring.AddUnitDamage
local SetUnitRulesParam = Spring.SetUnitRulesParam
local SetUnitCloak      = Spring.SetUnitCloak

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local flamerWeaponDefs = {}
for i=1,#WeaponDefs do
  if (WeaponDefs[i].type=="Flame" or 
      WeaponDefs[i].fireStarter >=100 or 
      WeaponDefs[i].name:lower():find("napalm")) then --// == flamethrower or napalm
     --// 0.5 cus we want to differ trees an metal/tanks 
     --// (fireStarter-tag: 1.0->always flame trees, 2.0->always flame units/buildings too)
    flamerWeaponDefs[i]=WeaponDefs[i].fireStarter
  end
end

local unitsOnFire = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID,
                            attackerID, attackerDefID, attackerTeam)
  if (flamerWeaponDefs[weaponID]) then
    if (UnitDefs[unitDefID].customParams.fireproof~="1") then
      local fireStarter = flamerWeaponDefs[weaponID]
      if ((random()*10*(2-allyBonus))<fireStarter) then
        local mult = 1
        if (not attackerTeam)or(AreTeamsAllied(unitTeam, attackerTeam)) then
          mult = allyBonus
        end
        unitsOnFire[unitID] = {
          startFrame = gameFrame, 
          fireLength = fireStarter*450*(random()*0.3+0.7)*mult, 
          fireDmg    = fireDmg,
          attackerID = attackerID,
		  --attackerDefID = attackerDefID,
		  weaponID	= weaponID,
        }
		SetUnitCloak(unitID, false, 10000)
        SetUnitRulesParam(unitID, "on_fire", 1)
      end
    end
  end
end

function gadget:UnitDestroyed(unitID)
  if (unitsOnFire[unitID]) then
    unitsOnFire[unitID] = nil
  end
end

function gadget:GameFrame(n)
  gameFrame = n
  if (n%6<1)and(next(unitsOnFire)) then
    local burningUnits = {}
    local cnt = 1
    for unitID, t in pairs(unitsOnFire) do
      if ((n-t.startFrame) > t.fireLength) then
        SetUnitRulesParam(unitID, "on_fire", 0)
		SetUnitCloak(unitID, false, false)
        unitsOnFire[unitID] = nil
      else
        AddUnitDamage(unitID,t.fireDmg*6,0,t.attackerID, t.weaponDefID )
		--Spring.Echo(t.attackerDefID)
        burningUnits[cnt] = unitID
        cnt=cnt+1
      end
    end
    if (cnt>1) then
      _G.burningUnits = burningUnits
      SendToUnsynced("onFire")
      _G.burningUnits = nil
    end
  end
end


--------------------------------------------------------------------------------
-- END SYNCED
--------------------------------------------------------------------------------
else
--------------------------------------------------------------------------------
-- BEGIN UNSYNCED
--------------------------------------------------------------------------------

local SYNCED  = SYNCED
local scLuaUI = Script.LuaUI

function WrapToLuaUI()
  if (scLuaUI('onFire')) then
    local burningUnits = {}
    for i,unitID in spairs(SYNCED.burningUnits) do
      burningUnits[i] = unitID
    end
    scLuaUI.onFire(burningUnits)
  end
end

function gadget:Initialize()
  gadgetHandler:AddSyncAction('onFire',WrapToLuaUI)
end

end

