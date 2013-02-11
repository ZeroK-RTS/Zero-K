
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

local spGetUnitStates = Spring.GetUnitStates
local CMD_IDLEMODE = CMD.IDLEMODE
local CMD_REPEAT = CMD.REPEAT
local spGiveOrderToUnit = Spring.GiveOrderToUnit

--local BALLISTIC_GUNSHIP_GRAVITY = -0.2
--local BALLISTIC_GUNSHIP_HEIGHT = 600000

--local spAreTeamsAllied = Spring.AreTeamsAllied

local GUNSHIP_VERTICAL_MULT = 0.25 -- prevents rediculus gunship climb

local impulseMult = {
	[0] = 0.022, -- fixedwing
	[1] = 0.004, -- gunships
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

local transportMass = {}
local inTransport = {}

--local risingByID = {count = 0, data = {}}
--local rising = {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- General Functionss

local function AddGadgetImpulse(unitID, unitDefID, x, y, z, moveType) -- could be GG if needed.
	moveType = moveType or moveTypeByID[unitDefID]
	if not unit[unitID] then
		unit[unitID] = {
			moveType = moveType,
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
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Space Gunship Handling
--[[
local function CheckSpaceGunships(f)
	local i = 1
	while i <= risingByID.count do
		local unitID = risingByID.data[i]
		local data = rising[unitID]
		local removeEntry = false
		
		if Spring.ValidUnitID(unitID) then
		
			local _,_,_, ux, uy, uz = Spring.GetUnitPosition(unitID, true)
			local groundHeight = Spring.GetGroundHeight(ux,uz)
			
			if (uy-groundHeight) > BALLISTIC_GUNSHIP_HEIGHT then
				if not data.inSpace then
					--Spring.SetUnitRulesParam(unitID, "inSpace", 1)
					GG.attUnits[unitID] = true
					GG.UpdateUnitAttributes(unitID)
					data.inSpace = true
				end
				AddGadgetImpulse(unitID, 0, 0, BALLISTIC_GUNSHIP_GRAVITY, 0, 1)
			else
				if data.inSpace then
					--Spring.SetUnitRulesParam(unitID, "inSpace", 0)
					GG.attUnits[unitID] = true
					GG.UpdateUnitAttributes(unitID)
					data.inSpace = false
				end
				local vx, vy, vz = Spring.GetUnitVelocity(unitID)
				if vy < 0 then
					removeEntry = true
				end
			end
		else
			removeEntry = false
		end
		
		if removeEntry then
			risingByID.data[i] = risingByID.data[risingByID.count]
			risingByID.data[risingByID.count] = nil
			risingByID.count = risingByID.count - 1
			rising[unitID] = nil
		else
			i = i + 1
		end
	end
end
--]]
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Transport Handling

function gadget:UnitUnloaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	if Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(transportID) then
		Spring.SetUnitVelocity(unitID, 0, 0, 0) -- prevent the impulse capacitor
	end
	
	if transportMass[transportID] then
		transportMass[transportID] = transportMass[transportID] - mass[unitDefID]
		--Spring.Echo(transportMass[transportID])
	end
	inTransport[unitID] = nil
end

function gadget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	if transportMass[transportID] then
		transportMass[transportID] = transportMass[transportID] + mass[unitDefID]
	else
		local tudid = Spring.GetUnitDefID(transportID)
		transportMass[transportID] = mass[tudid] + mass[unitDefID]
	end
	inTransport[unitID] = {id = transportID, def = Spring.GetUnitDefID(transportID)}
	--Spring.Echo(transportMass[transportID])
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if inTransport[unitID] then
		local transportID = inTransport[unitID].id
		if transportMass[transportID] then
			transportMass[transportID] = transportMass[transportID] - mass[unitDefID]
			--Spring.Echo(transportMass[transportID])
		end
		inTransport[unitID] = nil
		--Spring.Echo(transportMass[transportID])
	end
end

function gadget:Initialize()
	-- load active units
	for _, transportID in ipairs(Spring.GetAllUnits()) do
		local transporting = Spring.GetUnitIsTransporting(transportID)
		if transporting then
			for i = 1, #transporting do
				local unitID = transporting[i]
				local unitDefID = Spring.GetUnitDefID(unitID)
				if unitDefID then
					gadget:UnitLoaded(unitID, unitDefID, nil, transportID, nil)
				end
			end
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Main Impulse Handling

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
		
		if inTransport[unitID] then
			unitDefID = inTransport[unitID].def
			unitID = inTransport[unitID].id
		end
		
		local dis = distance(ux,uy,uz,ax,ay,az)
		local myMass = transportMass[unitID] or mass[unitDefID]
		local mag = impulseWeaponID[weaponDefID].impulse*GRAVITY_BASELINE/dis*impulseMult[moveTypeByID[unitDefID]]/myMass
		
		local x,y,z 
		if moveTypeByID[unitDefID] == 0 then
			x,y,z = (ux-ax)*mag, (uy-ay)*mag, (uz-az)*mag
		elseif moveTypeByID[unitDefID] == 1 then
			x,y,z = (ux-ax)*mag, (uy-ay)*mag * GUNSHIP_VERTICAL_MULT, (uz-az)*mag
		elseif moveTypeByID[unitDefID] == 2 then
			x,y,z = (ux-ax)*mag, (uy-ay)*mag+impulseWeaponID[weaponDefID].impulse/(8*myMass), (uz-az)*mag
		end
		
		AddGadgetImpulse(unitID, unitDefID, x, y, z)
		
		--if moveTypeByID[unitDefID] == 1 and attackerTeam and spAreTeamsAllied(unitTeam, attackerTeam) then
		--	unit[unitID].allied	= true
		--end
		
		if impulseWeaponID[weaponDefID].normalDamage then
			return damage
		else
			return 0
		end
	end
	return damage
end

local function AddImpulses()
	if thereIsStuffToDo then
		for i = 1, unitByID.count do
			local unitID = unitByID.data[i]
			local data = unit[unitID]
			if data.moveType == 1 then
				local vx, vy, vz = Spring.GetUnitVelocity(unitID)
				Spring.SetUnitVelocity(unitID, vx + data.x, vy + data.y, vz + data.z)
				
				--if data.allied then
					local states = spGetUnitStates(unitID)
					if states["repeat"] then
						spGiveOrderToUnit(unitID, CMD_REPEAT, {0},{})
					end
				--end
				--[[
				if vy + data.y > 0 and not rising[unitID] then
					rising[unitID] = {inSpace = false}
					risingByID.count = risingByID.count + 1
					risingByID.data[risingByID.count] = unitID
				end
				--]]
			else
				Spring.AddUnitImpulse(unitID, 1,0,0) --dummy impulse (applying impulse>1 make unit less sticky to map surface)
				Spring.AddUnitImpulse(unitID, -1,0,0) --remove dummy impulse
				Spring.AddUnitImpulse(unitID, data.x, data.y, data.z)
				--GG.UnitEcho(unitID,data.y)
			end
		end
		unitByID = {count = 0, data = {}}
		unit = {}
		thereIsStuffToDo = false
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Game Frame

function gadget:GameFrame(f)
	--CheckSpaceGunships()
	AddImpulses()
end