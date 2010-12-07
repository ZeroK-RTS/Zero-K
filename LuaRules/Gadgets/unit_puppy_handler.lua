
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

local puppyDefID
local puppyWeaponID


local function HidePuppy(unitID)
  -- send the puppy to the stratosphere, cloak it
  Spring.MoveCtrl.Enable(unitID)
  local x, y, z = Spring.GetUnitPosition(unitID)
  Spring.MoveCtrl.SetPosition(unitID, x, y + 1000000, z)
  Spring.SetUnitCloak(unitID, 4)
end


local function RestorePuppy(unitID, x, y, z)
  Spring.SetUnitCloak(unitID, false)
  Spring.MoveCtrl.SetPosition(unitID, x, y, z)
  Spring.MoveCtrl.Disable(unitID)
end

local function PuppyShot(unitID, unitDefID)
  -- the puppy fired its weapon, hide it
  HidePuppy(unitID)
end


function gadget:Initialize()
  local puppyDef =  UnitDefNames.puppy
  puppyDefID = puppyDef.id
  puppyWeaponID = puppyDef.weapons[1].weaponDef  
  Script.SetWatchWeapon(puppyWeaponID, true)
  gadgetHandler:RegisterGlobal("PuppyShot", PuppyShot)
end

function gadget:Shutdown()
  gadgetHandler:DeregisterGlobal("PuppyShot")
  Script.SetWatchWeapon(puppyWeaponID, false)
end


function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
  if weaponID == puppyWeaponID and Spring.ValidUnitID(attackerID) and 
    attackerTeam and unitTeam and not Spring.AreTeamsAllied(unitTeam, attackerTeam) then
    -- the puppy hit something, destroy it
    Spring.DestroyUnit(attackerID, false, true)
  end
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