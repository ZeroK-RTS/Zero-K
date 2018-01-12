
function gadget:GetInfo()
	return {
		name      = "Teleport Throw",
		desc      = "Implements teleportation thrower unit",
		author    = "Google Frog",
		date      = "12 Janurary 2018",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local teleportWeapons = {
	[WeaponDefNames["amphlaunch_teleport_gun"].id] = true,
}

local throwDefs = {
	[UnitDefNames["amphlaunch"].id] = {
		radius = 150
	},
}

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Shared functions
local spGetUnitDefID = Spring.GetUnitDefID
local getMovetype = Spring.Utilities.getMovetype

local canBeThrown = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.speed > 0 and getMovetype(ud) == 2 then -- Only ground or sea units
		canBeThrown[i] = true
	end
end

local function ValidThrowTarget(unitID, targetID)
	if unitID == targetID then
		return false
	end
	local _, _, _, speed = Spring.GetUnitVelocity(targetID)
	if speed > 7 then
		-- Dart speed is 5.1.
		-- Normal launch speed is 9.9
		return false 
	end
	local unitDefID = spGetUnitDefID(targetID)
	return canBeThrown[unitDefID]
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- SYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function SetUnitDrag(unitID, drag)
	local ux, uy, uz = Spring.GetUnitPosition(unitID)
	local rx, ry, rz = Spring.GetUnitRotation(unitID)
	local vx, vy, vz = Spring.GetUnitVelocity(unitID)
	Spring.SetUnitPhysics(unitID, ux, uy, uz, vx, vy, vz, rx, ry, rz, drag, drag, drag)
end

local throwUnits = IterableMap.New()
local dragRestore = IterableMap.New()
local UPDATE_PERIOD = 6

function gadget:ProjectileCreated(proID, proOwnerID, weaponDefID)
	if not weaponDefID and teleportWeapons[weaponDefID] then
		return
	end
	
	local data = throwUnits.Get(proOwnerID)
	if not data then
		return
	end
	
	local _,_,_, x, y, z = Spring.GetUnitPosition(proOwnerID, true)
	local px, py, pz = Spring.GetProjectileVelocity(proID)
	
	local nearUnits = Spring.GetUnitsInCylinder(x, z, data.def.radius)
	if nearUnits then
		for i = 1, #nearUnits do
			local nearID = nearUnits[i]
			local dragData = dragRestore and dragRestore.Get(nearID)
			if ((not dragData) or dragData.drag > -0.4) and ValidThrowTarget(proOwnerID, nearID) then
				GG.AddGadgetImpulseRaw(nearID, px, py, pz, true, true, nil, nil, true)
				dragRestore.Add(nearID, 
					{
						drag = -0.6
					}
				)
			end
		end
	end
	
	Spring.DeleteProjectile(proID)
end

function gadget:UnitPreDamaged_GetWantedWeaponDef()
	local wantedWeaponList = {}
	for wdid = 1, #WeaponDefs do
		if teleportWeapons[wdid] then
			wantedWeaponList[#wantedWeaponList + 1] = wdid
		end
	end 
	return wantedWeaponList
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	if weaponID and teleportWeapons[weaponID] then
		return 0
	end
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Unit Handler

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if throwDefs[unitDefID] then
		throwUnits.Add(unitID, 
			{
				def = throwDefs[unitDefID],
			}
		)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	throwUnits.Remove(unitID)
end

function gadget:Initialize()
	for _, unitID in pairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
	end
end

local function IncreaseDrag(unitID, data)
	SetUnitDrag(unitID, math.max(0, math.min(1, data.drag)))
	data.drag = data.drag + 0.05
	return data.drag >= 1 -- Return true to remove
end

function gadget:GameFrame(n)
	if n%2 == 0 then
		dragRestore.Apply(IncreaseDrag)
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local glVertex            = gl.Vertex
local spIsUnitInView      = Spring.IsUnitInView
local spGetUnitPosition   = Spring.GetUnitPosition
local spGetUnitLosState   = Spring.GetUnitLosState
local spValidUnitID       = Spring.ValidUnitID
local spGetMyTeamID       = Spring.GetMyTeamID
local spGetUnitVectors    = Spring.GetUnitVectors
local spGetUnitDefID      = Spring.GetUnitDefID
local spGetLocalTeamID    = Spring.GetLocalTeamID
local spGetUnitIsStunned  = Spring.GetUnitIsStunned
local spGetUnitRulesParam = Spring.GetUnitRulesParam

local throwers = IterableMap.New()
local alreadyWired = {}

local function UnitIsActive(unitID)
	if not spValidUnitID(unitID) then
		return false
	end
	
	local stunned_or_inbuild, stunned, inbuild = spGetUnitIsStunned(unitID) 
	local disarmed = (spGetUnitRulesParam(unitID, "disarmed") == 1)
	return not (stunned_or_inbuild or disarmed)
end

local function DrawBezierCurve(pointA, pointB, pointC,pointD, amountOfPoints)
	local step = 1/amountOfPoints
	glVertex (pointA[1], pointA[2], pointA[3])
	for i=0, 1, step do
		local x = pointA[1]*((1-i)^3) + pointB[1]*(3*i*(1-i)^2) + pointC[1]*(3*i*i*(1-i)) + pointD[1]*(i*i*i)
		local y = pointA[2]*((1-i)^3) + pointB[2]*(3*i*(1-i)^2) + pointC[2]*(3*i*i*(1-i)) + pointD[2]*(i*i*i)
		local z = pointA[3]*((1-i)^3) + pointB[3]*(3*i*(1-i)^2) + pointC[3]*(3*i*i*(1-i)) + pointD[3]*(i*i*i)
		glVertex(x,y,z)
	end
	glVertex(pointD[1],pointD[2],pointD[3])
end

local function GetUnitTop (unitID, x,y,z)
	local height = Spring.GetUnitHeight(unitID) -- previously hardcoded to 50
	local top = select(2, spGetUnitVectors(unitID))
	local offX = top[1]*height
	local offY = top[2]*height
	local offZ = top[3]*height
	return x+offX, y+offY, z+offZ
end

local function DrawWire(emitUnitID, recUnitID, spec, myTeam, x, y, z)
	local point = {}
	if spValidUnitID(recUnitID) then
		local los = spGetUnitLosState(recUnitID, myTeam, false)
		if (spec or (los and los.los)) and (spIsUnitInView(emitUnitID) or spIsUnitInView(recUnitID)) then
			local topX, topY, topZ = GetUnitTop(emitUnitID, x, y, z)
			point[1] = {x, y, z}
			point[2] = {topX, topY, topZ}
			local rX, rY, rZ = Spring.GetUnitPosition(recUnitID, true)
			topX, topY, topZ = GetUnitTop(recUnitID, rX, rY, rZ)
			point[3] = {topX,topY,topZ}
			point[4] = {rX, rY, rZ}
			gl.PushAttrib(GL.LINE_BITS)
			gl.DepthTest(true)
			gl.Color (0, 1, 0.5, math.random()*0.05 + 0.15)
			gl.LineWidth(3)
			gl.BeginEnd(GL.LINE_STRIP, DrawBezierCurve, point[1], point[2], point[3], point[4], 10)
			gl.DepthTest(false)
			gl.Color (1,1,1,1)
			gl.PopAttrib()
		end
	end
end

local function DrawThrowerWires(unitID, data, index, spec, myTeam)
	if not UnitIsActive(unitID) then
		return
	end
	local los = spGetUnitLosState(unitID, myTeam, false)
	if spec or (los and los.los) then
		local _,_,_, x, y, z = Spring.GetUnitPosition(unitID, true)
		local nearUnits = Spring.GetUnitsInCylinder(x, z, data.def.radius)
		if nearUnits then
			for i = 1, #nearUnits do
				local nearID = nearUnits[i]
				if UnitIsActive(nearID) and ValidThrowTarget(unitID, nearID) and not alreadyWired[nearID] then
					DrawWire(unitID, nearID, spec, myTeam, x, y, z)
					alreadyWired[nearID] = true
				end
			end
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	if throwDefs[unitDefID] then
		throwers.Add(unitID, 
			{
				def = throwDefs[unitDefID],
			}
		)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	throwers.Remove(unitID)
end

local function DrawWorldFunc()
	if throwers.GetIndexMax() > 0 then
		local _, fullview = Spring.GetSpectatingState()
		alreadyWired = {}
		throwers.Apply(DrawThrowerWires, fullview, spGetMyTeamID())
	end
end

function gadget:DrawWorld()
	DrawWorldFunc()
end
function gadget:DrawWorldRefraction()
	DrawWorldFunc()
end

function gadget:Initialize()
	for _, unitID in pairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
end
