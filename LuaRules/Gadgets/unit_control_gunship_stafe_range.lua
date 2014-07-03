
function gadget:GetInfo()
  return {
    name      = "Control gunship strafe range",
    desc      = "Clean but rediculus Hax, check this because engine may 'fix' it. Ticket relevant http://springrts.com/mantis/view.php?id=2955",
    author    = "Google Frog",
    date      = "14 Feb 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local corbtrans = UnitDefNames["corbtrans"].id
local armkam = UnitDefNames["armkam"].id
local bladew = UnitDefNames["bladew"].id
local armbrawl = UnitDefNames["armbrawl"].id
local corpyro = UnitDefNames["corpyro"].id

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if unitDefID == corbtrans then
		Spring.SetUnitWeaponState(unitID,1,{range = 300})
		Spring.SetUnitWeaponState(unitID,2,{range = 450})
		Spring.SetUnitWeaponState(unitID,3,{range = 450})
	elseif unitDefID == armkam then
		Spring.SetUnitWeaponState(unitID,1,{range = 270})
	elseif unitDefID == bladew then
		Spring.SetUnitWeaponState(unitID,1,{range = 180})
	elseif unitDefID == armbrawl then
		Spring.SetUnitWeaponState(unitID,1,{range = 600})
	elseif unitDefID == corpyro then
		Spring.SetUnitWeaponState(unitID,1,{range = 260})
	end
end
