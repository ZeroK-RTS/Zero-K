function gadget:GetInfo()
	return {
		name = "Planet Wars Structures",
		desc = "Spawns neutral structures for planetwars",
		author = "GoogleFrog",
		date = "27, April 2011",
		license = "Public Domain",
		layer = math.huge,
		enabled = true
	}
end

------------------------------------------------------------------------
------------------------------------------------------------------------
if (not gadgetHandler:IsSyncedCode()) then
	return
end
------------------------------------------------------------------------
------------------------------------------------------------------------
local defender = nil

include "LuaRules/Configs/customcmds.h.lua"

local abandonCMD = {
    id      = CMD_ABANDON_PW,
    name    = "Abandon",
    action  = "abandon",
	cursor  = 'Repair',
    type    = CMDTYPE.ICON,
	tooltip = "Abandon this building (marks it as neutral)",
}

local spGetGroundHeight	= Spring.GetGroundHeight

local mapWidth = Game.mapSizeX
local mapHeight = Game.mapSizeZ
local lava = (Game.waterDamage > 0)
local TRANSLOCATION_MULT = 0.95		-- start box is dispaced towards center by (distance to center) * this to get PW spawning area

local unitData = {}
local unitsByID = {}
local stuffToReport = {data = {}, count = 0}

GG.pwUnitsByID = unitsByID

------------------------------------------------------------------------
------------------------------------------------------------------------

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

local function spawnStructures(left, top, right, bottom, team)
	local teamID = team or Spring.GetGaiaTeamID()
	local xBase = mapWidth*left
	local xRand = mapWidth*(right-left)
	local zBase = mapHeight*top
	local zRand = mapHeight*(bottom-top)
	
	for _,info in pairs(unitData) do
		if type(info) == "table" then
			Spring.Echo("Processing PW structure: "..info.unitname)
			local giveUp = 0
			local x = xBase + math.random()*xRand
			local z = zBase + math.random()*zRand
			local direction = math.floor(math.random()*4)
			local defID = UnitDefNames[info.unitname] and UnitDefNames[info.unitname].id
			
			if not defID then
				Spring.Echo('Planetwars error: Missing structure def ' .. info.unitname)
			elseif info.isDestroyed == 1 then
				--do nothing
			else
				while (Spring.TestBuildOrder(defID, x, 0 ,z, direction) == 0 or (lava and Spring.GetGroundHeight(x,z) <= 0)) and giveUp < 25 do
					x = xBase + math.random()*xRand
					z = zBase + math.random()*zRand
					giveUp = giveUp + 1
				end
				
				local unitID = Spring.CreateUnit(info.unitname, x, spGetGroundHeight(x,z), z, direction, teamID)
				Spring.SetUnitNeutral(unitID,true)
				Spring.InsertUnitCmdDesc(unitID, 500, abandonCMD)
				unitsByID[unitID] = {name = info.unitname, teamDamages = {}}
			end
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
	
	local x1,y1,x2,y2 = 0.35, 0.35, 0.65, 0.65
	if defender then
		local n = select(6, Spring.GetTeamInfo(defender))
		local x1,y1,x2,y2 = box[n].left, box[n].top, box[n].right, box[n].bottom
		--Spring.Echo(x1,x2,y1,y2)
		local midX, midY = (x1 + x2)/2, (y1+y2)/2
		-- displace towards middle
		-- warning: will break with FFAs (see box var initialization above)
		x1 = math.max(x1 + TRANSLOCATION_MULT*(0.5 - midX), 0.1)
		y1 = math.max(y1 - TRANSLOCATION_MULT*(0.5 - midY), 0.1)
		x2 = math.min(x2 + TRANSLOCATION_MULT*(0.5 - midX), 0.9)
		y2 = math.min(y2 - TRANSLOCATION_MULT*(0.5 - midY), 0.9)
		spawnStructures(x1, y1, x2, y2, defender)
	elseif box[0].right - box[0].left >= 0.9 and box[1].right - box[1].left >= 0.9 then -- north vs south
		spawnStructures(0.1,0.44,0.9,0.56)
	elseif box[0].bottom - box[0].top >= 0.9 and box[1].bottom - box[1].top >= 0.9 then -- east vs west
		spawnStructures(0.44,0.1,0.56,0.9)
	else -- random idk boxes
		spawnStructures(0.35,0.35,0.65,0.65)
	end	
end

function gadget:Initialize()
	if Spring.GetGameFrame() > 0 then	--game has started
		local units = Spring.GetAllUnits()
		for i=1,#units do
			local unitID = units[i]
			local unitDefID = Spring.GetUnitDefID(unitID)
			local unitDef = UnitDefs[unitDefID]
			if unitDef.name:find("pw_") then	-- is PW
				unitsByID[unitID] = {name = unitDef.name, teamDamages = {}}
			end
		end
	
	else
	
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
		
		for _,teamID in pairs(Spring.GetTeamList()) do
			local keys = select(7, Spring.GetTeamInfo(teamID))
			if keys and keys.defender then
				defender = teamID
				break
			end
		end
		
		-- spawning code
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
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if unitsByID[unitID] and cmdID == CMD_ABANDON_PW then
		local gaiaTeam = Spring.GetGaiaTeamID()
		Spring.TransferUnit(unitID, gaiaTeam, true)
		Spring.SetUnitNeutral(unitID, true)
		return false
	end
	return true
end

------------------------------------------------------------------------
------------------------------------------------------------------------

function gadget:GameOver()	
	for i =1, stuffToReport.count do
		Spring.SendCommands("wbynum 255 SPRINGIE:structurekilled,".. stuffToReport.data[i])
	end
end