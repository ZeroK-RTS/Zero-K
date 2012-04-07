
function gadget:GetInfo()
  return {
    name      = "Jugglenaut Juggle",
    desc      = "Implementes special weapon Juggling for Jugglenaut",
    author    = "Google Frog",
    date      = "1 April 2011",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then -- synced

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local throwWeaponID = {}
local throwWeaponName = {}
local throwShooterID = {[UnitDefNames["gorg"].id] = true}

for i=1,#WeaponDefs do
	local wd = WeaponDefs[i]
	Script.SetWatchWeapon(wd.id,true)
	
	if wd.customParams and wd.customParams.massliftthrow then
		Script.SetWatchWeapon(wd.id,true)
		throwWeaponID[wd.id] = true
		throwWeaponName[wd.name] = wd.id
	end
end

local moveTypeByID = {}

for i=1,#UnitDefs do
	local ud = UnitDefs[i]
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

------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local RISE_TIME = 25
local FLING_TIME = 35
local UPDATE_FREQUENCY = 2
local RISE_HEIGHT = 180

local COLLLECT_RADIUS = 260

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
local gorgs = {}
local projectiles = {}

local flying = {}
local flyingByID = {data = {}, count = 0}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function distance(x1,y1,z1,x2,y2,z2)
	return math.sqrt((x1-x2)^2 + (y1-y2)^2 + (z1-z2)^2)
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function removeFlying(unitID)
	flying[flyingByID.data[flyingByID.count] ].index = flying[unitID].index
	flyingByID.data[flying[unitID].index] = flyingByID.data[flyingByID.count]
	flyingByID.data[flyingByID.count] = nil
	flying[unitID] = nil
	flyingByID.count = flyingByID.count - 1
	
	SendToUnsynced("removeFlying", unitID)
end

local function addFlying(unitID, frame, dx, dy, dz, height, parentDis)
	if flying[unitID] then
		removeFlying(unitID)
	end

	local unitDefID = Spring.GetUnitDefID(unitID)
	local ux, uy, uz = Spring.GetUnitPosition(unitID)
		
	if unitDefID and ux and moveTypeByID[unitDefID] and  moveTypeByID[unitDefID] == 2 then
		local frame = frame or Spring.GetGameFrame()
		
		local dis = distance(ux,uy,uz,dx,dy,dz)
		
		local riseFrame = frame + RISE_TIME + dis*0.2
		local flingFrame = frame + FLING_TIME + dis*0.2 + (dis - parentDis > -50 and (dis - parentDis + 50)*0.02 or 0)
		local flingDuration = flingFrame - riseFrame
		
		flyingByID.count = flyingByID.count + 1
		flyingByID.data[flyingByID.count] = unitID
		flying[unitID] = {
			index = flyingByID.count,
			riseFrame = riseFrame,
			flingFrame = flingFrame,
			flingDuration = flingDuration,
			riseTimer = 3,
			dx = dx, dy = dy, dz = dz,
			fx = ux, fy = height, fz = uz,
		}
		
		SendToUnsynced("addFlying", unitID, unitDefID)
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:ProjectileCreated(proID, unitID)
	if gorgs[unitID] then
		local name = Spring.GetProjectileName(proID)
		if throwWeaponName[name] then
			local x,y,z = Spring.GetUnitPosition(unitID)
			projectiles[proID] = {
				sx = x, sy = y, sz = z,
				parent = unitID,
			}
		end
	end
end

function gadget:ProjectileDestroyed(proID)
	
	if projectiles[proID] then
		local frame = Spring.GetGameFrame()
		local data = projectiles[proID]
		local x,y,z = Spring.GetProjectilePosition(proID)
		y = Spring.GetGroundHeight(x,z) + 20
		local units = Spring.GetUnitsInSphere(data.sx, data.sy, data.sz, COLLLECT_RADIUS)
		local parentDis = distance(data.sx, data.sy, data.sz, x,y,z)
		for i = 1, #units do
			local unitID = units[i]
			if unitID ~= data.parent then
				local ux, uy, uz = Spring.GetUnitPosition(unitID)
				local tx, ty, tz = x + (ux-data.sx)*0.4, y + (uy-data.sy)*0.4, z + (uz-data.sz)*0.4
				local mag = distance(data.sx, data.sy, data.sz, tx, ty, tz)
				tx, ty, tz = (tx-data.sx)*parentDis/mag + data.sx, (ty-data.sy)*parentDis/mag + data.sy, (tz-data.sz)*parentDis/mag + data.sz
				addFlying(unitID, frame, tx, ty, tz, data.sy + RISE_HEIGHT, parentDis)
			end
		end
		projectiles[proID] = nil
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:GameFrame(f)

	if f%UPDATE_FREQUENCY == 0 then
		local i = 1
		while i <= flyingByID.count do
			local unitID = flyingByID.data[i]

			if Spring.ValidUnitID(unitID) then
				local data = flying[unitID]

				local vx, vy, vz = Spring.GetUnitVelocity(unitID)
				local ux, uy, uz = Spring.GetUnitPosition(unitID)
				
				if f < data.riseFrame then
					
					Spring.AddUnitImpulse(unitID, -vx*0.02,  (data.fy - uy)*0.01*(2-vy),  -vz*0.02)
					
					if data.riseTimer then
						if data.riseTimer < 0 then
							Spring.SetUnitRotation(unitID,math.random()*2-1,math.random()*0.2-0.1,math.random()*2-1)
							data.riseTimer = false
						else
							data.riseTimer = data.riseTimer - 1
						end
					end
					
					i = i + 1
				elseif f < data.flingFrame then
				
					local dis = distance(data.dx,data.dy,data.dz,ux,uy,uz)
					local mult = ((data.flingFrame - f)*2/data.flingDuration)^1.8 * 2.5/dis
					Spring.AddUnitImpulse(unitID, (data.dx - ux)*mult,  (data.dy - uy)*mult,  (data.dz - uz)*mult)
				
					i = i + 1
				else
					removeFlying(unitID)
				end
			else
				removeFlying(unitID)
			end
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID)
	if throwShooterID[unitDefID] then
		gorgs[unitID] = true
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	if gorgs[unitID] then
		gorgs[unitID] = nil
	end
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else	--unsynced
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local Lups
local SYNCED = SYNCED

local particleIDs = {}

local flyFX = {
	--{class='UnitPieceLight', options={ delay=24, life=math.huge } },
	{class='StaticParticles', options={
		life        = 30,
		colormap    = { {0.2, 0.1, 1, 0.01, 0.2, 0.1, 1, 0.005} },
		texture     = 'bitmaps/GPL/groundflash.tga',
		count       = 1,
		sizeMod	    = 3,
		repeatEffect = true,
		}
	},
	--{class='SimpleParticles', options={	--FIXME
	--	life        = 50,
	--	speed        = 0.65,
	--	colormap    = { {0.2, 0.1, 1, 1} },
	--	texture     = 'bitmaps/PD/chargeparticles.tga',
	--	partpos	    = "0,0,0",
	--	count        = 15,
	--	rotSpeed     = 1,
	--	rotSpeedSpread = -2,
	--	rotSpread    = 360,
	--	sizeGrowth  = -0.05,		
	--	emitVector   = {0,1,0},
	--	emitRotSpread = 60,		
	--	delaySpread = 180,
	--	sizeMod	    = 10,
	--	}
	--},	
	--{class='ShieldSphere', options={
	--	life		= math.huge,
	--	colormap1 = { {0.2, 0.1, 1, 0.6} },
	--	colormap2 = { {0.2, 0.1, 1, 0.15} }
	--	}
	--},
} 

local function addFlying(_, unitID, unitDefID)
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
		table.insert( particleIDs[unitID], Lups.AddParticles(fx.class,fx.options) )
	end
end

local function removeFlying(_, unitID)
	for i=1,#particleIDs[unitID] do
		Lups.RemoveParticles(particleIDs[unitID][i])
	end
end

function gadget:Initialize()
        gadgetHandler:AddSyncAction("addFlying", addFlying)
	gadgetHandler:AddSyncAction("removeFlying", removeFlying)
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