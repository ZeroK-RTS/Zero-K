
function widget:GetInfo()
	return {
		name      = "Antinuke Coverage",
		desc      = "Displays antinuke coverage of enemies and allies. Takes antinuke shadow into account.",
		author    = "Google Frog",
		date      = "Dec 10, 2009", --updated May 3, 2015
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true
	}
end


--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

local nukeDefs = {
	[UnitDefNames["corsilo"].id] = true,
}

local intDefs = {
	[UnitDefNames["armamd"].id] = {
		range = 2500,
		rangeSq = 2500^2,
		static = true,
	},
	[UnitDefNames["reef"].id] ={
		range = 1200,
		rangeSq = 1200^2,
		static = false,
	},
}

local myTeamID = Spring.GetMyTeamID()
local myAllyTeamID = Spring.GetMyAllyTeamID()

--------------------------------------------------------------------------------
-- Globals
--------------------------------------------------------------------------------

local enemyInt = {}
local enemyNuke = {}

local allyInt = {}
local allyNuke = {}

local specUnit = {}

local spectating = Spring.GetSpectatingState()

--------------------------------------------------------------------------------
-- Unit handling
--------------------------------------------------------------------------------

local function AddSpecUnit(unitID, unitDefID)
	if intDefs[unitDefID] or nukeDefs[unitDefID] then
		specUnit[unitID] = true
	end
end

local function AddUnit(unitID, unitDefID, intMap, nukeMap)
	if intDefs[unitDefID] then
	
		if intMap[unitID] then
			return
		end
		
		local def = intDefs[unitDefID] 
		local _,_,inBuild = Spring.GetUnitIsStunned(unitID)
		
		intMap[unitID] = {
			range = def.range,
			rangeSq = def.rangeSq,
			static = def.static,
			incomplete = inBuild,
		}
		
		if def.static then
			local x,_,z = Spring.GetUnitPosition(unitID)
			intMap[unitID].x = x
			intMap[unitID].z = z
		end
	elseif nukeDefs[unitDefID] then
	
		if nukeMap[unitID] then
			return
		end
		
		local _,_,inBuild = Spring.GetUnitIsStunned(unitID)
		local x,y,z = Spring.GetUnitPosition(unitID)
		nukeMap[unitID] = {
			x = x,
			y = y,
			z = z,
			incomplete = inBuild,
		}
	end
end

local function RemoveUnit(unitID)
	enemyInt[unitID] = nil
    enemyNuke[unitID] = nil
    allyInt[unitID] = nil
	allyNuke[unitID] = nil
	specUnit[unitID] = nil
end  

function widget:UnitEnteredLos(unitID, unitTeam)
	if not Spring.AreTeamsAllied(myTeamID, unitTeam) and not spectating then
		local unitDefID = Spring.GetUnitDefID(unitID)
		AddUnit(unitID, unitDefID, enemyInt, enemyNuke)
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if spectating then
		AddSpecUnit(unitID, unitDefID)
	else
		if Spring.AreTeamsAllied(myTeamID, unitTeam) then
			AddUnit(unitID, unitDefID, allyInt, allyNuke)
		end
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if allyInt[unitID] then
		allyInt[unitID].incomplete = false
	elseif allyNuke[unitID] then
		allyNuke[unitID].incomplete = false
	end
end

function widget:UnitDestroyed(unitID, unitTeam, unitAllyTeam)
	RemoveUnit(unitID)
end

-- Game frame is used to check whether an enemy unit should be treated as dead.
-- Also updates spectating state.
function widget:GameFrame(n)
	if n%15 ~= 3 or spectating then
		return
	end

	for unitID, def in pairs(enemyInt) do
		local inLos = (not def.static) or select(2, Spring.GetPositionLosState(def.x, 0, def.z))
		if Spring.GetUnitDefID(unitID) then
			if def.incomplete then
				local _,_,inBuild = Spring.GetUnitIsStunned(unitID)
				if not inBuild then
					def.incomplete = false
				end
			end
		else
			if inLos then
				enemyInt[unitID] = nil
			end
		end
	end
	
	for unitID, def in pairs(enemyNuke) do
		local inLos = select(2, Spring.GetPositionLosState(def.x, 0, def.z))
		if Spring.GetUnitDefID(unitID) then
			if def.incomplete then
				local _,_,inBuild = Spring.GetUnitIsStunned(unitID)
				if not inBuild then
					def.incomplete = false
				end
			end
		else
			if inLos then
				enemyNuke[unitID] = nil
			end
		end
	end
	
	spectating = Spring.GetSpectatingState()
end

-- Sorts the spectator units into their correct ally or enemy lists from the point
-- of view of a particular ally team.
local function SortUnitsIntoAllyEnemy(matchAllyTeam)
	for unitID,_ in pairs(specUnit) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local allyTeam = Spring.GetUnitAllyTeam(unitID)
		if allyTeam == matchAllyTeam then
			enemyInt[unitID] = nil
			enemyNuke[unitID] = nil
			AddUnit(unitID, unitDefID, allyInt, allyNuke)
		else 
			allyInt[unitID] = nil
			allyNuke[unitID] = nil
			AddUnit(unitID, unitDefID, enemyInt, enemyNuke)
		end
	end
end

-- Add All Units
function widget:Initialize()
	local units = Spring.GetAllUnits()
	for i=1,#units do
		local unitID = units[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		if spectating then
			AddSpecUnit(unitID, unitDefID)
		else
			local allyTeam = Spring.GetUnitAllyTeam(unitID)
			if allyTeam == myAllyTeam then
				AddUnit(unitID, unitDefID, allyInt, allyNuke)
			else
				AddUnit(unitID, unitDefID, enemyInt, enemyNuke)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Decide What to Draw
--------------------------------------------------------------------------------

local drawNuke
local drawAntinuke

function widget:SelectionChanged(newSelection)
	drawNuke = false
	drawAntinuke = false
	for i = 1, #newSelection do
		local unitID = newSelection[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		if unitDefID then
			if nukeDefs[unitDefID] then
				if spectating then
					local allyTeam = Spring.GetUnitAllyTeam(unitID)
					SortUnitsIntoAllyEnemy(allyTeam)
				end
				local x,y,z = Spring.GetUnitPosition(unitID)
				drawNuke = {x,y,z}
				return
			elseif intDefs[unitDefID] then
				if spectating then
					local allyTeam = Spring.GetUnitAllyTeam(unitID)
					SortUnitsIntoAllyEnemy(allyTeam)
				end
				drawAntinuke = true
				return
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Interception checks
--------------------------------------------------------------------------------

local function InCircle(x,y,radiusSq)
	return x*x + y*y <= radiusSq
end

local function GetNukeIntercepted(ux, uz, px, pz, tx, tz, radiusSq)
	-- Unit position, Launcher position, Target position

	-- Translate projectile position to the origin.
	ux, uz, tx, tz, px, pz = ux - px, uz - pz, tx - px, tz - pz, 0, 0
	
	-- Get direction from projectile to target
	local tDir 
	if tx == 0 then
		if tz == 0 then
			return InCircle(ux, uy, radiusSq)
		elseif tz > 0 then
			tDir = math.pi/4
		else
			tDir = math.pi*3/4
		end
	elseif tx > 0 then
		tDir = math.atan(tz/tx)
	else
		tDir = math.atan(tz/tx) + math.pi
	end
	
	-- Rotate space such that direction from projectile to target is 0
	-- The nuke projectile will travel along the positive x-axis
	local cosDir = math.cos(-tDir)
	local sinDir = math.sin(-tDir)
	ux, uz = ux*cosDir - uz*sinDir, uz*cosDir + ux*sinDir
	tx, tz = tx*cosDir - tz*sinDir, tz*cosDir + tx*sinDir
	
	-- Find intersection of antinuke range with x-axis
	-- Quadratic formula, a = 1
	local b = -2*ux
	local c = ux^2 + uz^2 - radiusSq
	local determinate = b^2 - 4*c
	if determinate < 0 then
		-- No real solutions so the circle does not intersect x-axis.
		-- This means that antinuke projectile does not cross intercept
		-- range.
		return false
	end
	
	determinate = math.sqrt(determinate)
	local leftInt = (-b - determinate)/2
	local rightInt = (-b + determinate)/2
	
	--Spring.Echo(tDir*180/math.pi)
	--Spring.Echo("Unit X: " .. ux .. ", Unit Z: " .. uz)
	--Spring.Echo("Tar X: " .. tx .. ", Tar Z: " .. tz)
	--Spring.Echo("Left: " .. leftInt .. ", Right: " .. rightInt)
	
	-- IF the nuke does not fall short of coverage AND
	-- the projectile is still within coverage
	if leftInt < tx and rightInt > 0 then
		return true
	end
	return false
end

--------------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------------

local spTraceScreenRay		= Spring.TraceScreenRay
local spGetGroundHeight		= Spring.GetGroundHeight
local spGetMouseState       = Spring.GetMouseState
local spGetActiveCommand 	= Spring.GetActiveCommand

local glColor               = gl.Color
local glLineWidth           = gl.LineWidth
local glDrawGroundCircle    = gl.DrawGroundCircle
local glBeginEnd            = gl.BeginEnd
local glVertex              = gl.Vertex
local GL_LINES              = GL.LINES

local function VertexList(point)
	for i = 1, #point do
		glVertex(point[i])
	end
end

local function Draw()
	
	if drawNuke then
		
		local _, cmdID = spGetActiveCommand()
		
		if cmdID ~= CMD.ATTACK then
			return
		end
		
		local mx, my = spGetMouseState()
		local _, mouse = spTraceScreenRay(mx, my, true, true)
				
		if not mouse then
			return
		end
		
		local px, pz = drawNuke[1], drawNuke[3]
		local intercepted = false
		
		for unitID, def in pairs(enemyInt) do
			glLineWidth(2)
			
			local ux, uz
			if def.static then
				ux, uz = def.x, def.z
			else
				ux,_,uz = Spring.GetUnitPosition(unitID)
			end
			
			if ux then
				local thisIntercepted = GetNukeIntercepted(ux, uz, px, pz, mouse[1], mouse[3], def.rangeSq)
				if thisIntercepted then
					glColor(1,0,0,1)
					intercepted = true
				else
					glColor(0,1,0,1)
				end
				
				glDrawGroundCircle(ux, 0, uz, def.range, 40 )
			end
		end
	
		local vertices = {drawNuke, mouse}
  
		if intercepted then
			glColor(1,0,0,1)
		else
			glColor(0,1,0,1)
		end
		glLineWidth(2)
		glBeginEnd(GL_LINES, VertexList, vertices)
		
		glLineWidth(1)
		glColor(1, 1, 1, 1)
		
	elseif drawAntinuke then
	
	
	end
	

end

function widget:DrawInMiniMap()

	--DrawInMinimap()

end

	
function widget:DrawWorldPreUnit()
	
	Draw()
	
end