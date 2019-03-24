
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

local throwDefs = {}
local throwWeaponDef = {}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.customParams.thrower_gather then
		throwDefs[i] = {
			radius = tonumber(ud.customParams.thrower_gather),
		}
	end
end

for i = 1, #WeaponDefs do
	local wd = WeaponDefs[i]
	if wd.customParams.thower_weapon then
		throwWeaponDef[i] = true
	end
end

local GetEffectiveWeaponRange = Spring.Utilities.GetEffectiveWeaponRange
local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Shared functions
local spGetUnitDefID = Spring.GetUnitDefID
local getMovetype = Spring.Utilities.getMovetype

local canBeThrown = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.isGroundUnit then -- includes sea units
		canBeThrown[i] = true
	end
end

local function ValidThrowTarget(unitID, targetID)
	if unitID == targetID then
		return false
	end
	local _, _, _, speed = Spring.GetUnitVelocity(targetID)
	if speed > 6 then
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

local GRAVITY = (Game.gravity/30/30)

local FEATURE = 102
local GROUND = 103
local UNIT = 117

local MIN_FLY_TIME = 120
local MAX_FLY_TIME = 150

local throwUnits = IterableMap.New()
local physicsRestore = IterableMap.New()
local UPDATE_PERIOD = 6

function gadget:ProjectileCreated(proID, proOwnerID, weaponDefID)
	if not weaponDefID and throwWeaponDef[weaponDefID] then
		return
	end
	
	local data = throwUnits.Get(proOwnerID)
	if not data then
		return
	end
	
	-- Calculate target position.
	local targetType, targetPos = Spring.GetProjectileTarget(proID)
	local tx, ty, tz
	if targetType == GROUND then
		tx, ty, tz = targetPos[1], targetPos[2], targetPos[3]
	else
		_, _, _, tx, ty, tz = Spring.GetUnitPosition(targetPos, true)
	end
	ty = math.max(ty, 0)
	
	-- Calculate horizontal aiming parameters based on projectile owner position.
	local _,_,_, ox, oy, oz = Spring.GetUnitPosition(proOwnerID, true)
	local odx, ody, odz = tx - ox, ty - oy, tz - oz
	local fireDistance = math.sqrt(odx^2 + odz^2)
	
	local maxRange = GetEffectiveWeaponRange(data.unitDefID, -ody, data.weaponNum)
	if maxRange and fireDistance > maxRange*1.05 then
		maxRange = maxRange*1.05
		odx = odx*maxRange/fireDistance
		odz = odz*maxRange/fireDistance
	end
	
	local nearUnits = Spring.GetUnitsInCylinder(ox, oz, data.def.radius)
	if nearUnits then
		for i = 1, #nearUnits do
			local nearID = nearUnits[i]
			local physicsData = physicsRestore and physicsRestore.Get(nearID)
			if ((not physicsData) or (not physicsData.drag) or physicsData.drag > -0.4) and ValidThrowTarget(proOwnerID, nearID) then
				local _,_,_, _, ny, _ = Spring.GetUnitPosition(nearID, true)
				local ndy = ty - ny
				local flyTime = math.max(MIN_FLY_TIME, math.min(MAX_FLY_TIME, math.sqrt(math.abs(ndy))*10))
				
				local px, py, pz = odx/flyTime, flyTime*GRAVITY/2 + ndy/flyTime, odz/flyTime
				local vx, vy, vz = Spring.GetUnitVelocity(nearID)
				GG.AddGadgetImpulseRaw(nearID, px - vx, py - vy, pz - vz, true, true, nil, nil, true)
				SetUnitDrag(nearID, 0)
				GG.SetCollisionDamageMult(nearID, 0)
				Spring.SetUnitLeaveTracks(nearID, false)
				physicsRestore.Add(nearID, 
					{
						drag = -1.5,
						collisionResistence = -5*flyTime/MIN_FLY_TIME,
					}
				)
				SendToUnsynced("addFlying", nearID, Spring.GetUnitDefID(nearID), flyTime)
				GG.Floating_InterruptFloat(nearID)
			end
		end
	end
	
	Spring.DeleteProjectile(proID)
end

function gadget:UnitPreDamaged_GetWantedWeaponDef()
	local wantedWeaponList = {}
	for wdid = 1, #WeaponDefs do
		if throwWeaponDef[wdid] then
			wantedWeaponList[#wantedWeaponList + 1] = wdid
		end
	end 
	return wantedWeaponList
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	if weaponID and throwWeaponDef[weaponID] then
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
				unitDefID = unitDefID,
				weaponNum = 1,
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
	if Script.SetWatchProjectile then
		for id, _ in pairs(throwWeaponDef) do
			Script.SetWatchProjectile(id, true)
		end
	end
end

local function ReinstatePhysics(unitID, data)
	if data.drag then
		SetUnitDrag(unitID, math.max(0, math.min(1, data.drag)))
		data.drag = data.drag + 0.05
		if data.drag >= 1 then
			Spring.SetUnitLeaveTracks(unitID, true)
			SetUnitDrag(unitID, 1)
			data.drag = nil
		end
	end
	
	if data.collisionResistence then
		GG.SetCollisionDamageMult(unitID, math.max(0, math.min(1, data.collisionResistence)))
		data.collisionResistence = data.collisionResistence + 0.066
		if data.collisionResistence >= 1 then
			GG.SetCollisionDamageMult(unitID)
			SendToUnsynced("removeFlying", unitID)
			return true -- remove unit
		end
	end
end

function gadget:GameFrame(n)
	if n%2 == 0 then
		physicsRestore.Apply(ReinstatePhysics)
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Line drawing

local glVertex            = gl.Vertex
local spIsUnitInView      = Spring.IsUnitInView
local spGetUnitPosition   = Spring.GetUnitPosition
local spGetUnitLosState   = Spring.GetUnitLosState
local spValidUnitID       = Spring.ValidUnitID
local spGetMyAllyTeamID   = Spring.GetMyAllyTeamID
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

local function DrawWire(emitUnitID, recUnitID, spec, myAllyTeam, x, y, z)
	local point = {}
	if spValidUnitID(recUnitID) then
		local los = spGetUnitLosState(recUnitID, myAllyTeam, false)
		if (spec or (los and los.los)) and (spIsUnitInView(emitUnitID) or spIsUnitInView(recUnitID)) then
			local topX, topY, topZ = GetUnitTop(emitUnitID, x, y, z)
			point[1] = {x, y, z}
			point[2] = {topX, topY, topZ}
			local _,_,_, rX, rY, rZ = Spring.GetUnitPosition(recUnitID, true)
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

local function DrawThrowerWires(unitID, data, index, spec, myAllyTeam)
	if not UnitIsActive(unitID) then
		return
	end
	local los = spGetUnitLosState(unitID, myAllyTeam, false)
	if spec or (los and los.los) then
		local _,_,_, x, y, z = Spring.GetUnitPosition(unitID, true)
		local nearUnits = Spring.GetUnitsInCylinder(x, z, data.def.radius)
		if nearUnits then
			for i = 1, #nearUnits do
				local nearID = nearUnits[i]
				if UnitIsActive(nearID) and ValidThrowTarget(unitID, nearID) and not alreadyWired[nearID] then
					DrawWire(unitID, nearID, spec, myAllyTeam, x, y, z)
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
		throwers.Apply(DrawThrowerWires, fullview, spGetMyAllyTeamID())
	end
end

function gadget:DrawWorld()
	DrawWorldFunc()
end

function gadget:DrawWorldRefraction()
	DrawWorldFunc()
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Flying lups

local Lups

local particleIDs = {}

local flyFX = {
	{
		class = 'StaticParticles', 
		options = {
			life        = 250,
			sizeMod     = 4,
			colormap    = {{0, 0.4, 0.05, 0.006},{0, 0.6, 0.05, 0.006}, {0, 0.4, 0.05, 0.006}, {0, 0, 0, 0.006}},
			texture     = 'bitmaps/GPL/groundflash.tga',
			count       = 1,
			quality     = 1, -- Low
			noIconDraw = true,
		}
	}
} 

local function removeFlying(_, unitID)
	if not particleIDs[unitID] then
		return
	end
	for i = 1, #particleIDs[unitID] do
		Lups.RemoveParticles(particleIDs[unitID][i])
	end
	particleIDs[unitID] = nil
end

local function addFlying(_, unitID, unitDefID, flyTime)
	removeFlying(nil, unitID)
	particleIDs[unitID] = {}
	local teamID = Spring.GetUnitTeam(unitID)
	local allyTeamID = Spring.GetUnitAllyTeam(unitID)
	local radius = Spring.GetUnitRadius(unitID)
	local height = Spring.GetUnitHeight(unitID)
	for i,fx in pairs(flyFX) do
		fx.options.unit = unitID
		fx.options.unitDefID = unitDefID
		fx.options.team      = teamID
		fx.options.allyTeam  = allyTeamID
		fx.options.size = radius * (fx.options.sizeMod or 1)
		fx.options.pos = {0, height/2, 0}
		fx.options.life = flyTime*1.15
		particleIDs[unitID][#particleIDs[unitID] + 1] = Lups.AddParticles(fx.class,fx.options)
	end
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Gadget interface

function gadget:Initialize()
	gadgetHandler:AddSyncAction("addFlying", addFlying)
	gadgetHandler:AddSyncAction("removeFlying", removeFlying)
	
	for _, unitID in pairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
	end
end

function gadget:Update()
	if (not Lups) then
		Lups = GG['Lups']
	end
end


function gadget:Shutdown()
	gadgetHandler.RemoveSyncAction("addFlying")
    gadgetHandler.RemoveSyncAction("removeFlying")
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
end
