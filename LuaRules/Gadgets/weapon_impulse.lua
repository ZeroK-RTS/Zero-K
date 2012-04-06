
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
		impulseWeaponID[wd.id] = {
			impulse = tonumber(wd.customParams.impulse), 
			normalDamage = (wd.customParams.normaldamage and true or false)
		}
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

local thereIsStuffToDo = false
local unitByID = {count = 0, data = {}}
local unit = {}

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
		
		local mag = impulseWeaponID[weaponDefID].impulse*GRAVITY_BASELINE/dis*impulseMult[moveTypeByID[unitDefID]]/mass[unitDefID]
		
		local x,y,z 
		if moveTypeByID[unitDefID] == 0 then
			x,y,z = (ux-ax)*mag, (uy-ay)*mag, (uz-az)*mag
		elseif moveTypeByID[unitDefID] == 1 then
			x,y,z = (ux-ax)*mag, (uy-ay)*mag * GUNSHIP_VERTICAL_MULT, (uz-az)*mag
		elseif moveTypeByID[unitDefID] == 2 then
			x,y,z = (ux-ax)*mag, (uy-ay)*mag+impulseWeaponID[weaponDefID].impulse/(8*mass[unitDefID]), (uz-az)*mag
		end
		
		if not unit[unitID] then
			unit[unitID] = {
				moveType = moveTypeByID[unitDefID],
				x = x, y = y, z = z
			}
			unitByID.count = unitByID.count + 1
			unitByID.data[unitByID.count] = unitID
		else
			unit[unitID].x = unit[unitID].x + x
			unit[unitID].y = unit[unitID].y + y
			unit[unitID].z = unit[unitID].z + z
		end
		
		thereIsStuffToDo = true
		
		if impulseWeaponID[weaponDefID].normalDamage then
			return damage
		else
			return 0
		end
	end
	return damage
end

function gadget:GameFrame(f)
	if thereIsStuffToDo then
		for i = 1, unitByID.count do
			local unitID = unitByID.data[i]
			local data = unit[unitID]
			if data.moveType == 1 then
				local vx, vy, vz = Spring.GetUnitVelocity(unitID)
				Spring.SetUnitVelocity(unitID, vx + data.x, vy + data.y, vz + data.z)
			else
				Spring.AddUnitImpulse(unitID, data.x, data.y, data.z)
			end
		end
		unitByID = {count = 0, data = {}}
		unit = {}
		thereIsStuffToDo = false
	end
end