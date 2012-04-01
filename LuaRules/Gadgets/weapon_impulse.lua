
function gadget:GetInfo()
  return {
    name      = "Weapon Impulse ",
    desc      = "Implements impulse relaint weapons because engine impelementation is prettymuch broken.",
    author    = "Google Frog",
    date      = "1 April 2012",
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

local GRAVITY = Game.gravity
local GRAVITY_BASELINE = 120

local GUNSHIP_VERTICAL_MULT = 0.5 -- pre3vents rediculus gunship climb

local impulseMult = {
	[0] = 0.022, -- fixedwing
	[1] = 0.0054, -- gunships
	[2] = 0.0032, -- other
}
local impulseWeaponID = {}


for i=1,#WeaponDefs do
	local wd = WeaponDefs[i]
	if wd.customParams and wd.customParams.impulse then
		impulseWeaponID[wd.id] = tonumber(wd.customParams.impulse)
		Spring.Echo(wd.name)
	end
end

local moveTypeByID = {}
local mass = {}

for i=1,#UnitDefs do
	local ud = UnitDefs[i]
	mass[i] = ud.mass
	if ud.canFly then
		if (ud.isFighter or ud.isBomber) then
			moveTypeByID[i] = 0 -- plane
		else
			moveTypeByID[i] = 1 -- gunship
		end
	elseif not (ud.isBuilding or ud.isFactory or ud.speed == 0) then
		moveTypeByID[i] = 2 -- ground/sea
	else
		moveTypeByID[i] = false -- structure
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:UnitUnloaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	if Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(transportID) then
		Spring.SetUnitVelocity(unitID, 0, 0, 0)
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function distance(x1,y1,z1,x2,y2,z2)
	return math.sqrt((x1-x2)^2 + (y1-y2)^2 + (z1-z2)^2)
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)
	--Spring.AddUnitImpulse(unitID,0,3,0)
	if impulseWeaponID[weaponDefID] and Spring.ValidUnitID(attackerID) and moveTypeByID[unitDefID] then
		
		local _, _, inbuild = Spring.GetUnitIsStunned(unitID)
		if inbuild then
			return 0
		end
		
		local ux, uy, uz = Spring.GetUnitPosition(unitID)
		local ax, ay, az = Spring.GetUnitPosition(attackerID)
		
		local dis = distance(ux,uy,uz,ax,ay,az)
		
		local mag = impulseWeaponID[weaponDefID]*GRAVITY_BASELINE/dis*impulseMult[moveTypeByID[unitDefID]]/mass[unitDefID]
		
		if moveTypeByID[unitDefID] == 0 then
			Spring.AddUnitImpulse(unitID,(ux-ax)*mag,(uy-ay)*mag,(uz-az)*mag)
		elseif moveTypeByID[unitDefID] == 1 then
			local vx, vy, vz = Spring.GetUnitVelocity(unitID)
			Spring.SetUnitVelocity(unitID, vx + (ux-ax)*mag, vy + (uy-ay)*mag * GUNSHIP_VERTICAL_MULT, vz + (uz-az)*mag)
		elseif moveTypeByID[unitDefID] == 2 then
			Spring.AddUnitImpulse(unitID,(ux-ax)*mag,(uy-ay)*mag+10/mass[unitDefID],(uz-az)*mag)
		end
		--local bx, by, bz = Spring.GetUnitBasePosition(unitID)
		--local height = Spring.GetGroundHeight(bx,bz)
		--if math.abs(by-height) < 0.01 then
		--	Spring.AddUnitImpulse(unitID,0,0.16*GRAVITY/70,0)
		--end
		return 0
	end
	return damage
end