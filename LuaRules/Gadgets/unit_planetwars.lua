function gadget:GetInfo()
	return {
		name = "Planet Wars Structures",
		desc = "Spawns neutral structures for planetwars",
		author = "GoogleFrog",
		date = "27, April 2011",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

------------------------------------------------------------------------
------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
	return
end

local mapWidth = Game.mapSizeX
local mapHeight = Game.mapSizeZ
local lava = (Game.waterDamage > 0)

local unitData = {}
local unitsByID = {}
local stuffToReport = {data = {}, count = 0}

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)

	if unitsByID[unitID] and not paralyzer then
		unitsByID[unitID].totalDamage = (unitsByID[unitID].totalDamage or 0) + damage
		if attackerTeam then
			unitsByID[unitID].teamDamages[attackerTeam] = (unitsByID[unitID].teamDamages[attackerTeam] or 0) + damage
		else
			unitsByID[unitID].anonymous = (unitsByID[unitID].anonymous or 0) + damage
		end
	end
end

local function addStuffToReport(stuff)
	stuffToReport.count = stuffToReport.count + 1
	stuffToReport.data[stuffToReport.count] = stuff
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if unitsByID[unitID] then
		local unit = unitsByID[unitID]
		local name = unit.name
		addStuffToReport(name .. ",total," .. (unit.totalDamage or 0))
		addStuffToReport(name .. ",anon," .. (unit.anonymous or 0))
		for teamID, damage in pairs(unit.teamDamages) do
			addStuffToReport(name .. "," .. teamID .. "," .. damage)
		end
		unitsByID[unitID] = nil
	end
end

------------------------------------------------------------------------
------------------------------------------------------------------------

local function normaliseBoxes(box)
	box.left = box.left/mapWidth
	box.top = box.top/mapHeight
	box.right = box.right/mapWidth
	box.bottom = box.bottom/mapHeight
end

local function spawnStructures(left, top, right, bottom)
	local gaiaID = Spring.GetGaiaTeamID()
	local xBase = mapWidth*left
	local xRand = mapWidth*(right-left)
	local zBase = mapHeight*top
	local zRand = mapHeight*(bottom-top)
	
	for _,info in pairs(unitData) do
		local giveUp = 0
		local x = xBase + math.random()*xRand
		local z = zBase + math.random()*zRand
		local direction = math.floor(math.random()*4)
		local defID = UnitDefNames[info.unitname] and UnitDefNames[info.unitname].id
		
		if not defID then
			Spring.Echo('Planetwars error: Missing structure def ' .. info.unitname)
		elseif info.isDestroyed then
			--do nothing
		else
			while Spring.TestBuildOrder(defID, x, 0 ,z, direction) == 0 and (lava and Spring.GetGroundHeight(x,z) <= 0) and giveUp < 25 do
				x = xBase + math.random()*xRand
				z = zBase + math.random()*zRand
				giveUp = giveUp + 1
			end
			
			local unitID = Spring.CreateUnit(info.unitname, x, 0, z, direction, gaiaID)
			Spring.SetUnitNeutral(unitID,true)
			unitsByID[unitID] = {name = info.unitname, teamDamages = {}}
		end
	end
end

function gadget:GameStart()

	local box = {[0] = {}, [1] = {}}
	box[0].left, box[0].top, box[0].right, box[0].bottom  = Spring.GetAllyTeamStartBox(0)
	box[1].left, box[1].top, box[1].right, box[1].bottom = Spring.GetAllyTeamStartBox(1)
	
	if not (box[0].right and box[1].right) then
		spawnStructures(0.35,0.35,0.65,0.65)
	end
	
	normaliseBoxes(box[0])
	normaliseBoxes(box[1])
	
	if box[0].right - box[0].left >= 0.9 and box[1].right - box[1].left >= 0.9 then -- north vs south
		spawnStructures(0.1,0.44,0.9,0.56)
	elseif box[0].bottom - box[0].top >= 0.9 and box[1].bottom - box[1].top >= 0.9 then -- east vs west
		spawnStructures(0.44,0.1,0.56,0.9)
	else -- random idk boxes
		spawnStructures(0.35,0.35,0.65,0.65)
	end
end

function gadget:Initialize()
	
	local modOptions = (Spring and Spring.GetModOptions and Spring.GetModOptions()) or {}
	local pwDataRaw = modOptions.planetwarsstructures
	local pwDataFunc, err, success
	
	if not (pwDataRaw and type(pwDataRaw) == 'string') then
		err = "Planetwars data entry in modoption is empty or in invalid format"
		unitData = {}
	else
		pwDataRaw = string.gsub(pwDataRaw, '_', '=')
		pwDataRaw = Spring.Utilities.Base64Decode(pwDataRaw)
		pwDataFunc, err = loadstring("return "..pwDataRaw)
		if pwDataFunc then
			success, unitData = pcall(pwDataFunc)
			if not success then	-- execute Borat
				err = unitData
				unitData = {}
			end
		end
	end
	if err then 
		Spring.Echo('Planetwars error: ' .. err)
	end

	if not unitData then 
		unitData = {} 
	end
	
	local spawningAnything = false
	for i,v in pairs(unitData) do
		if (v.isDestroyed~=1) then 
			spawningAnything = true
			break
		end
	end
	
	if not spawningAnything then
		gadgetHandler:RemoveGadget()
	end
	
end

------------------------------------------------------------------------
------------------------------------------------------------------------

function gadget:GameOver()	
	for i =1, stuffToReport.count do
		Spring.SendCommands("wbynum 255 SPRINGIE:structurekilled,".. stuffToReport.data[i])
	end
end