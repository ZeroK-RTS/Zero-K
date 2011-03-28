--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spAreTeamsAllied		 = Spring.AreTeamsAllied
local spGetGameFrame         = Spring.GetGameFrame
local spGetSelectedUnits     = Spring.GetSelectedUnits
local spGetUnitDefID         = Spring.GetUnitDefID
local spGetUnitHealth        = Spring.GetUnitHealth
local spGetUnitPosition      = Spring.GetUnitPosition
local spGetUnitTeam          = Spring.GetUnitTeam
local spGetUnitsInCylinder   = Spring.GetUnitsInCylinder
local spSetUnitHealth        = Spring.SetUnitHealth

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Repair Aura",
		desc = "Repairs units in a circle",
		author = "KDR_11k (David Becker), KingRaptor (L.J. Lim)",
		date = "2010-09-17",
		license = "Public Domain",
		layer = 20,
		enabled = false
	}
end

include("LuaRules/Configs/repairaura_defs.lua")

if (gadgetHandler:IsSyncedCode()) then

--SYNCED
local repairers = {}	-- i = unitID, v = unitDef.name
local repairTimeout = {}
local repairSchedule = {}	--i = gameframe, v=array of units with aura awaiting check (i = unitID, v = boolean)

function gadget:Initialize()
	--/luarules reload compatibility
	if Spring.GetGameFrame() > 1 then
		local unitList = Spring.GetAllUnits()
		for i,v in ipairs(unitList) do
			local ud = spGetUnitDefID(v)
			gadget:UnitFinished(v, ud)
		end
	end
end

function gadget:UnitFinished(u, ud, team)
	if	repairerDefs[UnitDefs[ud].name] then
		repairers[u] = UnitDefs[ud].name
		local frame = spGetGameFrame() + framesPerRepair
		if not repairSchedule[frame] then repairSchedule[frame] = {} end
		repairSchedule[frame][u] = true
	end
end

function gadget:UnitDestroyed(u, ud, team)
	if repairers[u] then 
		for i,v in pairs(repairSchedule) do v[u] = nil end
	end
	repairers[u]=nil
	repairTimeout[u]=nil
end

function gadget:UnitDamaged(u, ud, team)
	repairTimeout[u] = spGetGameFrame() + delayAfterHit
end

--optimization: stagger our repair checks to avoid creating a lot of load in one frame
function gadget:GameFrame(n)
	if repairSchedule[n] then
		repairSchedule[n + framesPerRepair] = {}	--prep next repair cycle
		for repairer,_ in pairs(repairSchedule[n]) do
			local repairerTeam = spGetUnitTeam(repairer)
			local posx, _, posz = spGetUnitPosition(repairer)
			local repairerInfo = repairerDefs[repairers[repairer]]
			local unitsInCyl = spGetUnitsInCylinder(posx, posz, repairerInfo.range)
			
			local count = 0
			local repairees = {}
			--filter out units ineligible for repair
			--if #unitsInCyl > 0 then Spring.Echo(#unitsInCyl.." units are in range for repair") end
			for i=1,#unitsInCyl do
				local unit = unitsInCyl[i]
				local unitTeam = spGetUnitTeam(unit)
				local hp, maxHP,_,_,buildProgress = spGetUnitHealth(unit)
				if not ((repairTimeout[unit] and (repairTimeout[unit] > n)) and not repairerInfo.ignoreDelay) and (buildProgress >= 1) and (hp < maxHP) and spAreTeamsAllied(repairerTeam, unitTeam) then
					count = count + 1
					repairees[count] = unit
				end
			end
			--if count > 0 then Spring.Echo(count .. " units passed repair check") end
			--now we can repair!
			local repairStrength = repairerInfo.rate/count
			for i=1, #repairees do
				local unit = repairees[i]
				local buildTime = UnitDefs[spGetUnitDefID(unit)].buildTime
				local hp, maxHP,_,_,buildProgress = spGetUnitHealth(unit)
				local hpGain = (repairStrength/buildTime) * maxHP
				--Spring.Echo("Repairing unit for "..hpGain)
				local newHP = hp + hpGain
				if newHP > maxHP then newHP = maxHP end
				spSetUnitHealth(unit, newHP)
			end
			repairSchedule[n + framesPerRepair][repairer] = true	--schedule next repair
		end
		repairSchedule[n] = nil		--we're done here, clean up
	end
end

else

--UNSYNCED

local GL_LINE_LOOP           = GL.LINE_LOOP
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_SRC_ALPHA           = GL.SRC_ALPHA
local GL_TRIANGLE_STRIP      = GL.TRIANGLE_STRIP
local glBeginEnd             = gl.BeginEnd
local glBlending             = gl.Blending
local glCallList             = gl.CallList
local glColor                = gl.Color
local glCreateList           = gl.CreateList
local glDeleteList           = gl.DeleteList
local glLineWidth            = gl.LineWidth
local glPopMatrix            = gl.PopMatrix
local glPushMatrix           = gl.PushMatrix
local glTexCoord             = gl.TexCoord
local glTexture              = gl.Texture
local glTranslate            = gl.Translate
local glVertex               = gl.Vertex

local repairShape

--TODO: figure out how to set circle radius based on repair range
--since we don't draw the circle at all ATM, this isn't needed, but if we decide to do it in the future...

local function Circle()
	for i=0,39 do
		glVertex(math.cos(i*.05*3.1415)*repairRadius,0,math.sin(i*.05*3.1415)*repairRadius)
	end
end

local size=200

local function Square()
	glTexCoord(0,0)
	glVertex(-size,0,-size)
	glTexCoord(1,0)
	glVertex(size,0,-size)
	glTexCoord(0,1)
	glVertex(-size,0,size)
	glTexCoord(1,1)
	glVertex(size,0,size)
end

local function Shape()
	glTexture(false)
	--glBeginEnd(GL_LINE_LOOP,Circle)
	glTexture(true)
	glBeginEnd(GL_TRIANGLE_STRIP,Square)
end

function gadget:DrawWorldPreUnit()
	glTexture("bitmaps/PD/repair.tga")
	--glBlending(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA)
	glLineWidth(2)
	glColor(.6,.6,.2,1)
	for _,u in ipairs(spGetSelectedUnits()) do
		if repairerDefs[UnitDefs[spGetUnitDefID(u)].name] then
			local x,y,z=spGetUnitPosition(u)
			glPushMatrix()
			glTranslate(x,y,z)
			glCallList(repairShape)
			--Shape()
			glPopMatrix()
		end
	end
	glLineWidth(1)
	glColor(1,1,1,1)
	glTexture(false)
	--glBlending(false)
end

function gadget:Initialize()
	repairShape=glCreateList(Shape)
end

function gadget:Shutdown()
	glDeleteList(repairShape)
end

end
