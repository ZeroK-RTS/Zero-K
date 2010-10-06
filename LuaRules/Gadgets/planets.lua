--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spAreTeamsAllied     = Spring.AreTeamsAllied
local spEcho               = Spring.Echo
local spGetGaiaTeamID      = Spring.GetGaiaTeamID
local spGetModOptions      = Spring.GetModOptions
local spGetTeamColor       = Spring.GetTeamColor
local spGetTeamInfo        = Spring.GetTeamInfo
local spGetTeamList        = Spring.GetTeamList
local spGetUnitDefID       = Spring.GetUnitDefID
local spGetUnitPosition    = Spring.GetUnitPosition
local spGetUnitTeam        = Spring.GetUnitTeam
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spValidUnitID        = Spring.ValidUnitID
local spGetLocalTeamID     = Spring.GetLocalTeamID
local spGetSpectatingState = Spring.GetSpectatingState
local sGetUnitHealth 	   = Spring.GetUnitHealth

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Planets",
		desc = "Enables planets (duh!)",
		author = "KDR_11k (David Becker)",
		date = "2008-03-04",
		license = "Public Domain",
		layer = 4,
		enabled = false
	}
end

local planet = UnitDefNames.planet.id
local incomePerPlanet = spGetModOptions().income or 10
local occupationRange = 200
local defaultOccupationStrength=0

local tutorialmessage = true

local planetOverlap = spGetModOptions().overlap

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local planets = {}

local occupiers={}

local pattern = spGetModOptions().pattern or "standoff"
local number = spGetModOptions().planetcount or 10

local lastIncome = {}
local allyTeam={}

local patterns={
	orion={
		{.3,.1}, {.8,.15},
		{.4,.45},{.5,.5},{.6,.55},
		{.2,.85},{.7,.9},
	},
	standoff={
		{.5,.05},
		{.15,.25},{.85,.25},
		{.4,.35},{.6,.35},
		{.4,.65},{.6,.65},
		{.15,.75},{.85,.75},
		{.5,.95},
	},
	lineandside={
		{.51,.1},{.5,.36},{.52,.63},{.48,.9},
		{.05,.4},{.20,.5},{.07,.62},
		{.95,.41},{.78,.5},{.96,.6},
	},
	trail={
		{.05,.05},{.2,.32},{.4,.55},{.6,.45},{.8,.68},{.95,.95},
		{.9,.15},{.1,.85},
	}
}

function gadget:Initialize()
	if patterns[pattern] then
		local mx = Game.mapSizeX
		local mz = Game.mapSizeZ
		for i,data in pairs(patterns[pattern]) do
			planets[i]= {
				x=mx*data[1], z=mz*data[2],
				lastOwner=nil,
			}
		end
	else
		for i = 1,(number*312) do
			math.random(10) --add some randomness
		end
		
		for i = 1,number/2 do
			local x = math.random(Game.mapSizeX)
			local z = math.random(Game.mapSizeZ)
			
			if planetOverlap == "0" then
				local r2 = (occupationRange*2)^2
				local r = (occupationRange)^2
				local redo = true
				local n = 0
				
				local mx = Game.mapSizeX/2
				local mz = Game.mapSizeZ/2
				   
				while redo and n < 20 do 
					redo = false
					spEcho("n " .. n)
					if (pattern == "randompoint" and (x-mx)^2+(z-mz) < r) 
					or (pattern == "randomx" and (x-mx)^2 < r)
					or (pattern == "randomz" and (z-mz)^2 < r) then
						x = math.random(Game.mapSizeX)
						z = math.random(Game.mapSizeZ)
						redo = true
					end
					
					for _,p in pairs(planets) do
						local d = (x-p.x)^2+(z-p.z)^2
						if d < r2 then
							x = math.random(Game.mapSizeX)
							z = math.random(Game.mapSizeZ)
							redo = true
						end
					end
					n = n+1
				end
			end
			
			planets[i * 2 - 1] = {
				x = x,
				z = z,
				lastOwner = nil,
			}
			if pattern == "randompoint" then
				planets[i * 2] = {
					x = Game.mapSizeX - x,
					z = Game.mapSizeZ - z,
					lastOwner = nil,
				}
			elseif pattern == "randomx" then
				planets[i * 2] = {
					x = Game.mapSizeX - x,
					z = z,
					lastOwner = nil,
				}
			elseif pattern == "randomz" then
				planets[i * 2] = {
					x = x,
					z = Game.mapSizeZ - z,
					lastOwner = nil,
					lastStrength = 0,
					lastOccupier = nil,
				}
			else
				local x = math.random(Game.mapSizeX)
				local z = math.random(Game.mapSizeZ)
				
				if planetOverlap == "0" then
					local r2 = (occupationRange*2)^2
					local r = (occupationRange)^2
					local redo = true
					local n = 0
				   
					while redo and n < 20 do 
						redo = false
					
						for _,p in pairs(planets) do
							local d = (x-p.x)^2+(z-p.z)^2
							if d < r2 then
								x = math.random(Game.mapSizeX)
								z = math.random(Game.mapSizeZ)
								redo = true
							end
						end
						n = n+1
					end
				end
				
				planets[i * 2] = {
					x = x,
					z = z,
					lastOwner = nil,
					lastStrength = 0,
					lastOccupier = nil,
				}
			end
			
		end
	end

	for _,t in ipairs(spGetTeamList()) do
		_,_,_,_,_,allyTeam[t] = spGetTeamInfo(t)
		spEcho(t..": "..allyTeam[t])
	end

	for i,ud in pairs(UnitDefs) do
		if ud.customParams.occupationstrength then
			occupiers[i]=tonumber(ud.customParams.occupationstrength)
		end
	end

	for _,t in ipairs(spGetTeamList()) do
		lastIncome[t] = 0
	end
	
	GG.planets = planets
	GG.occupationRange = occupationRange
	_G.planets = planets
	GG.lastIncome = lastIncome
	_G.lastIncome = lastIncome

end

function gadget:GameFrame(f)
	if f % 30 < .1 then
		for i,p in pairs(planets) do
			local owner = nil
			local contested = false
			local strength = 0
			local occupier = nil
			for _,u in ipairs(spGetUnitsInCylinder(p.x, p.z, occupationRange)) do
				local t = spGetUnitTeam(u)
				local oc = occupiers[spGetUnitDefID(u)] or defaultOccupationStrength
				local _,_,_,_,done = sGetUnitHealth(u)
				if oc > 0 and done == 1 then --0 marks units that shouldn't occupy
					if not owner then
						owner = t
						occupier=u
					elseif not spAreTeamsAllied(owner, t) then
						if oc > strength then
							owner = t
							contested = false
							occupier=u
						elseif oc == strength then
							contested = true
							occupier=nil
						end
					end
					if oc > strength then
						strength = oc
						occupier=u
					end
				end
			end
			if not contested and owner then
				p.lastOwner = owner
				p.lastStrength = incomePerPlanet * strength
				p.lastOccupier = occupier
				local ao = allyTeam[owner]
				for t, a in pairs(allyTeam) do
					if a == ao then
						lastIncome[t] = lastIncome[t] + incomePerPlanet * strength
						Spring.AddTeamResource (t, "m", incomePerPlanet * strength)
					end
				end
			else
				p.lastOwner = nil
				p.lastStrength = 0
				p.lastOccupier = nil
			end
		end
	end
	if f == 900 then
		local teams = {}
		for _,t in ipairs(spGetTeamList()) do
			teams[t] = true
		end
		for _,p in pairs(planets) do
			for t,_ in pairs(teams) do
				if allyTeam[t] == allyTeam[p.lastOwner] then
					teams[t]=nil
				end
			end
		end
		for team,_ in pairs(teams) do
			GG.message[team].text = "You do not have any metal spots!"
			GG.message[team].hint = "Capture metal spots by building metal extractors in them"
			GG.message[team].timeout = f + 180
		end
	end
end

else

--UNSYNCED

local GL_BACK              = GL.BACK
local GL_LEQUAL            = GL.LEQUAL
local GL_LINES             = GL.LINES
local GL_TRIANGLE_FAN      = GL.TRIANGLE_FAN
local glBeginEnd           = gl.BeginEnd
local glBillboard          = gl.Billboard
local glCallList           = gl.CallList
local glColor              = gl.Color
local glCreateList         = gl.CreateList
local glCulling            = gl.Culling
local glDeleteList         = gl.DeleteList
local glDepthTest          = gl.DepthTest
local glDrawGroundCircle   = gl.DrawGroundCircle
local glLighting           = gl.Lighting
local glLineStipple        = gl.LineStipple
local glLoadIdentity       = gl.LoadIdentity
local glPopMatrix          = gl.PopMatrix
local glPushMatrix         = gl.PushMatrix
local glRotate             = gl.Rotate
local glScale              = gl.Scale
local glText               = gl.Text
local glTranslate          = gl.Translate
local glUnitShape          = gl.UnitShape
local glVertex             = gl.Vertex

local gaia = spGetGaiaTeamID()
local circle

local Vertex = glVertex
local Lighting = glLighting
local PushMatrix = glPushMatrix
local Translate = glTranslate
local UnitShape = glUnitShape
local PopMatrix = glPopMatrix
local Color = glColor
local DrawGroundCircle = glDrawGroundCircle
local GetTeamColor = spGetTeamColor
local CallList = glCallList

local function Line(sx,sy,sz,tx,ty,tz)
	Vertex(sx,sy,sz)
	Vertex(tx,ty,tz)
end

function gadget:DrawWorldPreUnit()
	glCulling(GL_BACK)
	for i,p in spairs(SYNCED.planets) do
		Lighting(true)
		PushMatrix()
		Translate(p.x, 90, p.z)
		UnitShape(planet, p.lastOwner or gaia)
		PopMatrix()
		Lighting(false)
		if p.lastOwner then
			glCulling(false)
			PushMatrix()
			local r,g,b = GetTeamColor(p.lastOwner or gaia)
			Color(r,g,b,.2)
			Translate(p.x, 0, p.z)
			CallList(circle)
			PopMatrix()
			glCulling(GL_BACK)
		end
		Color(1,1,1,1)
	end
	glCulling(false)
end

function gadget:DrawWorld()
	local team=spGetLocalTeamID()
	local _,spec=spGetSpectatingState()
	for i,p in spairs(SYNCED.planets) do
		local r,g,b = GetTeamColor(p.lastOwner or gaia)
		Color(r,g,b,1)
		DrawGroundCircle(p.x, 0, p.z, occupationRange, 30)
		if p.lastOwner and (spec or spAreTeamsAllied(team,p.lastOwner)) then
			PushMatrix()
			Translate(p.x, 90, p.z)
			glBillboard()
			glText("+"..p.lastStrength,0,0,24,"oc")
			PopMatrix()
			if spValidUnitID(p.lastOccupier) then --line occupied
				local x,y,z=spGetUnitPosition(p.lastOccupier)
				glDepthTest(GL_LEQUAL)
				glLineStipple("bla")
				DrawGroundCircle(x, 0, z, 30, 12)
				glBeginEnd(GL_LINES,Line,x,0,z,p.x,0,p.z)
				glLineStipple(false)
				glDepthTest(false)
			end
		end
	end
	Color(1,1,1,1)
end

function gadget:DrawInMiniMap(mmsx, mmsy)
	glPushMatrix()
	glLoadIdentity()
	glTranslate(0,1,0)
	glScale(2/Game.mapSizeX, 2/Game.mapSizeZ, 1)
	glRotate(90,1,0,0)
	Lighting(true)
	for i,p in spairs(SYNCED.planets) do
		PushMatrix()
		Translate(p.x/2, 0, p.z/2)
		UnitShape(planet, p.lastOwner or gaia)		PopMatrix()
	end
	glPopMatrix()
	Lighting(false)
end

function gadget:Initialize()
	circle = glCreateList(glBeginEnd,GL_TRIANGLE_FAN)
end

function gadget:Shutdown()
	glDeleteList(circle)
end

end
