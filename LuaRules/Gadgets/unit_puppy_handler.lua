
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Puppy Handler",
    desc      = "Handlers the puppy weapon",
    author    = "quantum",
    date      = "Dec 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false  --  no unsynced code
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- shortcuts
local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitDefID = Spring.GetUnitDefID
local spValidUnitID = Spring.ValidUnitID

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local puppyDefID
local puppyWeaponID
local puppyLosRadius


local function HidePuppy(unitID)
  -- send the puppy to the stratosphere, cloak it
  Spring.MoveCtrl.Enable(unitID)
  local x, y, z = Spring.GetUnitPosition(unitID)
  Spring.MoveCtrl.SetPosition(unitID, x, y + 1000000, z)
  Spring.SetUnitCloak(unitID, 4)
  -- Spring.SetUnitSensorRadius(unitID, "los", 0)
  Spring.SetUnitStealth(unitID, true)
  Spring.SetUnitNoDraw(unitID, true)
  -- Spring.SetUnitNoSelect(unitID, true)
  Spring.SetUnitNoMinimap(unitID, true)
  Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, {})
end


local function RestorePuppy(unitID, x, y, z)
  Spring.SetUnitCloak(unitID, false)
  Spring.MoveCtrl.SetPosition(unitID, x, y, z)
  Spring.SetUnitBlocking(unitID, false, false)	-- allows it to clip into wrecks (workaround for puppies staying in heaven)
  Spring.MoveCtrl.Disable(unitID)
  Spring.SetUnitBlocking(unitID, true, true)	-- restores normal state once they land
  -- Spring.SetUnitSensorRadius(unitID, "los", puppyLosRadius)
  Spring.SetUnitStealth(unitID, false)
  Spring.SetUnitNoDraw(unitID, false)
  -- Spring.SetUnitNoSelect(unitID, false)
  Spring.SetUnitNoMinimap(unitID, false)
  Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, {})
end

local function PuppyShot(unitID, unitDefID)
  -- the puppy fired its weapon, hide it
  HidePuppy(unitID)
end

function gadget:Initialize()
  local puppyDef =  UnitDefNames.puppy
  puppyDefID = puppyDef.id
  puppyWeaponID = puppyDef.weapons[1].weaponDef
  puppyLosRadius = puppyDef.losRadius
  Script.SetWatchWeapon(puppyWeaponID, true)
  gadgetHandler:RegisterGlobal("PuppyShot", PuppyShot)
end

function gadget:Shutdown()
  gadgetHandler:DeregisterGlobal("PuppyShot")
  Script.SetWatchWeapon(puppyWeaponID, false)
end

-- in event of shield impact, gets data about both units and passes it to UnitPreDamaged
function gadget:ShieldPreDamaged(proID, proOwnerID, shieldEmitterWeaponNum, shieldCarrierUnitID, bounceProjectile)
	local attackerTeam, attackerDefID, defenderTeam, defenderDefID
	if spValidUnitID(proOwnerID) then
		attackerDefID = spGetUnitDefID(proOwnerID)
		if attackerDefID ~= puppyDefID then return false end	-- nothing to do with us, exit
		attackerTeam = spGetUnitTeam(proOwnerID)
	end
	if spValidUnitID(shieldCarrierUnitID) then
		defenderTeam = spGetUnitTeam(shieldCarrierUnitID)
		defenderDefID = spGetUnitDefID(shieldCarrierUnitID)
	end
	-- we don't actually have the weaponID, but can assume it is puppyWeaponID
	gadget:UnitPreDamaged(shieldCarrierID, defenderDefID, defenderTeam, 0, false, puppyWeaponID, proOwnerID, attackerDefID, attackerTeam)
	return false
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
  if weaponID == puppyWeaponID and spValidUnitID(attackerID) then
    if attackerTeam and unitTeam then
      -- attacker and attacked units are known (both units are alive)
      if spAreTeamsAllied(unitTeam, attackerTeam) then
        -- attacked unit is an ally
        if unitDefID == puppyDefID then
          -- attacked unit is an allied puppy, cancel damage
          return 0
        end
      else
        -- attacked unit is an enemy, self-destruct the puppy
        Spring.DestroyUnit(attackerID, false, true)
        return damage
      end
    end    
  end
  return damage
end


function gadget:Explosion(weaponID, px, py, pz, ownerID)
  if weaponID == puppyWeaponID and Spring.ValidUnitID(ownerID) then
    -- the puppy landed
    RestorePuppy(ownerID, px, py, pz)
  end
  return false
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------