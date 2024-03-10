function widget:GetInfo()
	return {
		name         = "Shieldball healthbars UI",
		desc         = "Give a healthbar to shieldballs. Version 1.0",
		author       = "dyth68",
		date         = "2024",
		license      = "PD", -- should be compatible with Spring
		layer        = 11,
		enabled      = true
	}
end

local UPDATE_FRAME=7

local glCallList = gl.CallList
local glPushMatrix = gl.PushMatrix
local glTranslate = gl.Translate
local glRotate = gl.Rotate
local glScale = gl.Scale
local glPopMatrix = gl.PopMatrix
local glCreateList = gl.CreateList
local glDeleteList = gl.DeleteList
local glVertex = gl.Vertex
local glPolygonMode = gl.PolygonMode
local glBeginEnd = gl.BeginEnd
local glLineWidth = gl.LineWidth
local glColor = gl.Color

local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitShieldState = Spring.GetUnitShieldState
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitHealth = Spring.GetUnitHealth
local spGetUnitRulesParam = Spring.GetUnitRulesParam

local strFormat = string.format

local Optics = VFS.Include("LuaRules/Gadgets/Include/Optics.lua")
local Benchmark = false and VFS.Include("LuaRules/Gadgets/Include/Benchmark.lua")
local benchmark = nil -- Benchmark and Benchmark.new()

---------------------------------
local function printThing(theTable, theKey, indent)
	local indent = indent or ""
	local theKey = theKey or "key"
	if (type(theTable) == "table") then
		Spring.Echo(indent .. theKey .. ":")
		for a, b in pairs(theTable) do
			printThing(b, tostring(a), indent .. "  ")
		end
	else
		Spring.Echo(indent .. tostring(theKey) .. ": " .. tostring(theTable))
	end
end
---------------------------------
local shieldUnitDefs = {}


for unitDefID=1, #UnitDefs do
	if UnitDefs[unitDefID].shieldWeaponDef then
		shieldUnitDefs[unitDefID] = true
	end
end
---------------------------------

local function regenStr(regen)
	local sign = (regen >= 0) and "+" or ""
	if regen == 0 then
		return ""
	end
	if math.abs(math.ceil(regen) - regen) < 0.05 then
		return " (" .. sign .. math.ceil(regen - 0.2) .. ")"
	end
	return " (" .. sign .. strFormat("%+.1f", regen) .. ")"
end

---------------------------------

local BASE_FONT_SIZE = 192
local healthBarOffsetZ = 300
local healthBarHeight = 30
local healthBarWidth = 200
local healthBarMargin = 5
local healthBarRoundiness = 5
---------------------------------

-- Map from teamID to array of balls, each ball with location, curr power and total power
local shieldBalls = {}
local drawBallHealthbarList

local font = gl.LoadFont("FreeSansBold.otf", BASE_FONT_SIZE, 0, 0)

local function DrawBallHealthbar()
	for allyTeamID, teamBalls in pairs(shieldBalls) do
		local isAllied = (Spring.GetLocalAllyTeamID() == allyTeamID)
		for _, shieldBall in pairs(teamBalls) do
			local healthBarHeightAboveTheZero = shieldBall.highestTopOfShield + 40
			local healthBarOffsetZ = shieldBall.zStdDev + 60

			-- The outer bar is actually an Octagon to give the impression of rounded corners
			if isAllied then
				glColor(0.5, 0.8, 0.5, 0.5)
			else
				glColor(0.8, 0.5, 0.5, 0.5)
			end
			glPolygonMode(GL.FRONT_AND_BACK, GL.FILL)
			glBeginEnd(GL.TRIANGLE_FAN, function()
				glVertex(shieldBall.x - healthBarWidth + healthBarRoundiness, healthBarHeightAboveTheZero, shieldBall.z - (healthBarOffsetZ + healthBarHeight))
				glVertex(shieldBall.x + healthBarWidth - healthBarRoundiness, healthBarHeightAboveTheZero, shieldBall.z - (healthBarOffsetZ + healthBarHeight))
				glVertex(shieldBall.x + healthBarWidth, healthBarHeightAboveTheZero, shieldBall.z - (healthBarOffsetZ + healthBarHeight - healthBarRoundiness))
				glVertex(shieldBall.x + healthBarWidth, healthBarHeightAboveTheZero, shieldBall.z - (healthBarOffsetZ + healthBarRoundiness))
				glVertex(shieldBall.x + healthBarWidth - healthBarRoundiness, healthBarHeightAboveTheZero, shieldBall.z - (healthBarOffsetZ))
				glVertex(shieldBall.x - healthBarWidth + healthBarRoundiness, healthBarHeightAboveTheZero, shieldBall.z - (healthBarOffsetZ))
				glVertex(shieldBall.x - healthBarWidth, healthBarHeightAboveTheZero, shieldBall.z - (healthBarOffsetZ + healthBarRoundiness))
				glVertex(shieldBall.x - healthBarWidth, healthBarHeightAboveTheZero, shieldBall.z - (healthBarOffsetZ + healthBarHeight - healthBarRoundiness))
			end)


			-- The healthbar container is four lines
			local innerBarWidthWhenFull = healthBarWidth - healthBarMargin
			local innerBarHeight = healthBarHeight - healthBarMargin
			local proportionFull = shieldBall.currShield / shieldBall.totShield

			glPolygonMode(GL.FRONT_AND_BACK, GL.LINE)
			glColor(0.5, 0.5, 0.5, 0.5)
			glBeginEnd(GL.QUADS, function()
				glVertex(shieldBall.x - innerBarWidthWhenFull, healthBarHeightAboveTheZero, shieldBall.z - (healthBarOffsetZ + innerBarHeight))
				glVertex(shieldBall.x + innerBarWidthWhenFull, healthBarHeightAboveTheZero, shieldBall.z - (healthBarOffsetZ + innerBarHeight))
				glVertex(shieldBall.x + innerBarWidthWhenFull, healthBarHeightAboveTheZero, shieldBall.z - (healthBarOffsetZ + healthBarMargin))
				glVertex(shieldBall.x - innerBarWidthWhenFull, healthBarHeightAboveTheZero, shieldBall.z - (healthBarOffsetZ + healthBarMargin))
			end)


			-- The healthbar itself is a rectangle
			local innerBarWidth = 2 * innerBarWidthWhenFull * proportionFull
			glPolygonMode(GL.FRONT_AND_BACK, GL.FILL)
			if isAllied then
				glColor(0.5, 0.3, 1.0, 0.5)
			else
				glColor(0.5, 0.3, 1.0, 0.5)
			end
			glBeginEnd(GL.TRIANGLE_FAN, function()
				glVertex(shieldBall.x - innerBarWidthWhenFull, healthBarHeightAboveTheZero, shieldBall.z - (healthBarOffsetZ + innerBarHeight))
				glVertex(shieldBall.x - innerBarWidthWhenFull + innerBarWidth, healthBarHeightAboveTheZero, shieldBall.z - (healthBarOffsetZ + innerBarHeight))
				glVertex(shieldBall.x - innerBarWidthWhenFull + innerBarWidth, healthBarHeightAboveTheZero, shieldBall.z - (healthBarOffsetZ + healthBarMargin))
				glVertex(shieldBall.x - innerBarWidthWhenFull, healthBarHeightAboveTheZero, shieldBall.z - (healthBarOffsetZ + healthBarMargin))
			end)


			-- The healthbar text
			local fontSize = BASE_FONT_SIZE / 10
			--glScale(fontSize / BASE_FONT_SIZE, fontSize / BASE_FONT_SIZE, fontSize / BASE_FONT_SIZE)
			glPushMatrix()
			glTranslate(shieldBall.x, healthBarHeightAboveTheZero, shieldBall.z - healthBarOffsetZ - innerBarHeight/2 - healthBarMargin/2)
			glRotate(-90, 1, 0, 0)

			local regen = regenStr(math.floor(shieldBall.regen))
			local shieldHpText = tostring(math.floor(shieldBall.currShield)) .. " / " .. tostring(shieldBall.totShield) .. regen .. " max " .. tostring(math.floor(shieldBall.maxCurrentPower))
			font:Begin()
				font:SetTextColor(0.2, 0.2, 0.2, 0.6)
				font:Print(shieldHpText, 0, 0, fontSize, "cv")
			font:End()
			glPopMatrix()
		end
	end
end
---------------------------------

 -- TODO: Use link data
local function shieldsAreTouching(shield1, shield2)
	if not shield2 then
		return false
	end
	local xDiff = shield1.x - shield2.x
	local zDiff = shield1.z - shield2.z
	local yDiff = shield1.y - shield2.y
	local sumRadius = shield1.shieldRadius + shield2.shieldRadius
	return xDiff <= sumRadius and zDiff <= sumRadius and (xDiff*xDiff + yDiff*yDiff + zDiff*zDiff) < sumRadius*sumRadius
end

---------------------------------

local shieldBallsIdsByTeam = {}
local allShieldUnitsByTeam = {}
local allShieldUnitIDsByTeam = {}

local function validShieldUnit(unitID)
	local unitDefID = spGetUnitDefID(unitID)
	if unitDefID and shieldUnitDefs[unitDefID] then
		local _, _, _, _, buildProgress = spGetUnitHealth(unitID)
		if buildProgress == 1 then
			local x,y,z = spGetUnitPosition(unitID)
			if x then
				return true
			end
		end
	end
end

local function updateClustering()
	if benchmark then
		benchmark:Enter("ClusterizeShieldUnits")
	end
	for _, allyTeamID in pairs(Spring.GetAllyTeamList()) do
		local allShieldUnits = {}
		for _, teamID in pairs(Spring.GetTeamList(allyTeamID)) do
			for _,unitID in ipairs(allShieldUnitIDsByTeam[teamID]) do
				local unitDefID = spGetUnitDefID(unitID)
				if unitDefID and shieldUnitDefs[unitDefID] then
					local _, _, _, _, buildProgress = spGetUnitHealth(unitID)
					if buildProgress == 1 then
						local x,y,z = spGetUnitPosition(unitID)
						if x then
							local shieldWep = WeaponDefs[UnitDefs[unitDefID].shieldWeaponDef]
							allShieldUnits[unitID] = {
								shieldMaxCharge  = shieldWep.shieldPower,
								shieldRadius = shieldWep.shieldRadius,
								x = x,
								y = y,
								z = z
							}
						end
					end
				end
			end
		end

		local unitLocations = {}
		local unitNeighborsMatrix = {}
		for unitID, shieldProps in pairs(allShieldUnits) do
			local x,y,z = spGetUnitPosition(unitID)
			unitLocations[#unitLocations + 1] = {
				x = x,
				z = z,
				fID = unitID,
			}
			local unitsInRange = spGetUnitsInCylinder(x, z, shieldProps.shieldRadius*2)
			unitNeighborsMatrix[unitID] = {}
			for _, unitInRange in ipairs(unitsInRange) do
				if shieldsAreTouching(shieldProps, allShieldUnits[unitInRange]) then
					unitNeighborsMatrix[unitID][unitInRange] = true
					if not unitNeighborsMatrix[unitInRange] then
						unitNeighborsMatrix[unitInRange] = {}
					end
					unitNeighborsMatrix[unitInRange][unitID] = true
				end
			end
		end
		local opticsObject = Optics.new(unitLocations, unitNeighborsMatrix, 2, benchmark)
		opticsObject:Run()
		shieldBallsIdsByTeam[allyTeamID] = opticsObject:Clusterize(700)

		allShieldUnitsByTeam[allyTeamID] = allShieldUnits
	end
	if benchmark then
		benchmark:Leave("ClusterizeShieldUnits")
	end
end

---------------------------------
local function getUnitShieldRegen(unitID, ud)
	if spGetUnitRulesParam(unitID, "att_shieldDisabled") == 1 then
		return 0
	end

	local shieldRegen = spGetUnitRulesParam(unitID, "shieldRegenTimer")
	if shieldRegen and shieldRegen > 0 then
		return 0
	end

	local mult = spGetUnitRulesParam(unitID,"totalReloadSpeedChange") or 1 * (1 - (spGetUnitRulesParam(unitID, "shieldChargeDisabled") or 0))
	if mult == 0 then
		return 0
	end

	-- FIXME: take energy stall into account
	local wd = WeaponDefs[ud.shieldWeaponDef]
	local wdc = wd.customParams
	local regen = (wdc.shield_rate_charge and spGetUnitRulesParam(unitID, "shield_rate_override") and
			math.floor(spGetUnitRulesParam(unitID, "shield_rate_override")*15 + 0.5)) or
			tonumber(wdc.shield_rate or wd.shieldPowerRegen)
	if not wd.customParams.slow_immune then
		regen = mult * regen
	end
	return regen
end

---------------------------------
local function updateCurrentShieldBalls()
	for _, teamID in pairs(Spring.GetAllyTeamList()) do
		local shieldBallsIds = shieldBallsIdsByTeam[teamID] or {}
		local allShieldUnits = allShieldUnitsByTeam[teamID] or {}
		local ballsInTeam = {}
		for i = 1, #shieldBallsIds do
			local thisBall = shieldBallsIds[i]
			local totalCurrentShield = 0
			local totalMaxShield = 0
			local totalRegen = 0
			local maxIndividualCurrentPower = 0
			local x_avg, z_avg = 0, 0
			local numUnits = 0
			local highestTopOfShield = 0
			local memberPositionsByUnitID = {}
			for j = 1, #thisBall.members do
				local unitID = thisBall.members[j]
				local x,y,z = spGetUnitPosition(unitID)
				if x then
					local shieldProps = allShieldUnits[unitID]
					totalMaxShield = totalMaxShield + shieldProps.shieldMaxCharge
					local enabled, currPower = spGetUnitShieldState(unitID)
					x_avg = x_avg + x
					z_avg = z_avg + z
					numUnits = numUnits + 1
					if enabled and currPower then
						totalCurrentShield = totalCurrentShield + currPower
						highestTopOfShield = math.max(highestTopOfShield, y + shieldProps.shieldRadius)
						if currPower < shieldProps.shieldMaxCharge then
							totalRegen = totalRegen + getUnitShieldRegen(unitID, UnitDefs[spGetUnitDefID(unitID)])
						end
						maxIndividualCurrentPower = math.max(maxIndividualCurrentPower, currPower)
					end
				end
				memberPositionsByUnitID[unitID] = {x = x, y = y, z = z}
			end
			if numUnits > 0 then
				x_avg = x_avg / numUnits
				z_avg = z_avg / numUnits
			end

			local xStdDev = 0
			local zStdDev = 0
			for j = 1, #thisBall.members do
				local unitID = thisBall.members[j]
				local x = memberPositionsByUnitID[unitID].x
				local z = memberPositionsByUnitID[unitID].z
				if x then
					xStdDev = xStdDev + (x - x_avg) * (x - x_avg)
					zStdDev = zStdDev + (z - z_avg) * (z - z_avg)
				end
			end
			xStdDev = math.sqrt(xStdDev / numUnits)
			zStdDev = math.sqrt(zStdDev / numUnits)


			local ballData = {
				currShield = totalCurrentShield,
				totShield = totalMaxShield,
				x = x_avg,
				z = z_avg,
				highestTopOfShield = highestTopOfShield,
				xStdDev = xStdDev,
				zStdDev = zStdDev,
				numUnits = numUnits,
				regen = totalRegen,
				maxCurrentPower = maxIndividualCurrentPower,
			}
			ballsInTeam[#ballsInTeam + 1] = ballData
		end


		shieldBalls[teamID] = ballsInTeam
	end
	drawBallHealthbarList = glCreateList(DrawBallHealthbar)
end
---------------------------------
-- Keeping track of shield units

function widget:UnitCreated(unitID, unitDefID, teamID)
	if unitDefID and shieldUnitDefs[unitDefID] then
		allShieldUnitIDsByTeam[teamID][unitID] = true
	end
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
	if unitDefID and shieldUnitDefs[unitDefID] then
		allShieldUnitIDsByTeam[teamID][unitID] = nil
	end
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, oldTeamID)
	widget:UnitDestroyed(unitID, unitDefID, oldTeamID)
	widget:UnitCreated(unitID, unitDefID, newTeamID)
end

function widget:UnitTaken(unitID, unitDefID, oldTeamID, newTeamID)
	widget:UnitDestroyed(unitID, unitDefID, oldTeamID)
	widget:UnitCreated(unitID, unitDefID, newTeamID)
end

function widget:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
	widget:UnitCreated(unitID, unitDefID, unitTeam)
end

function widget:UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
	widget:UnitDestroyed(unitID, unitDefID, unitTeam)
end

---------------------------------

function widget:GameFrame(n)
	if (n%UPDATE_FRAME==1) then
		updateClustering()
	end
	updateCurrentShieldBalls()
end

function widget:Initialize()
	for _, teamID in pairs(Spring.GetTeamList()) do
		local teamUnits = {}
		local teamUnitsSpring = Spring.GetTeamUnits(teamID)
		for _, unitID in pairs(teamUnitsSpring) do
			if validShieldUnit(unitID) then
				teamUnits[#teamUnits + 1] = unitID
			end
		end
		allShieldUnitIDsByTeam[teamID] = teamUnits
	end
	updateClustering()
	updateCurrentShieldBalls()
end

function widget:DrawWorld()
	if drawBallHealthbarList then
		glCallList(drawBallHealthbarList)
	end
end
