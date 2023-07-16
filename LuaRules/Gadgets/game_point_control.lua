--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Point Control Victory",
		desc      = "Implements a point control victory condition for Team vs Team games.",
		author    = "GoogleFrog",
		date      = "16 July 2023",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true
	}
end

if (not gadgetHandler:IsSyncedCode()) then
	return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local vector = Spring.Utilities.Vector

local objUnitDefID = UnitDefNames["obj_artefact"].id

local EDGE_SIDE_PAD = 0.1
local EDGE_PAD = 0.1
local MID_PAD = -0.1

local toCreate = false
local checkLoss = false

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local objectives = IterableMap.New()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SpawnStructuresForAllyTeam(rect, count, allyTeamID)
	local teams = Spring.GetTeamList(allyTeamID)
	local teamID = teams[1]
	
	for i = 0, count - 1 do
		local sidePad = EDGE_SIDE_PAD + (1 - 2*EDGE_SIDE_PAD) * i / (count - 1)
		local midFactor = 1 - 2 * math.abs(0.5 - i / (count - 1))
		local towardsPad = (1 - midFactor) * EDGE_PAD + midFactor * MID_PAD
		if allyTeamID == 1 then
			towardsPad = 1 - towardsPad
		end
		local pos = vector.Add(rect[1], vector.Add(vector.Mult(sidePad, rect[2]), vector.Mult(towardsPad, rect[3])))
		local unitID = GG.SpawnPregameStructure(objUnitDefID, teamID, pos, true)
	end
end

local function PlaceArtefacts()
	local minEdgeProp = math.min(
		(Spring.GetGameRulesParam("mex_min_x_prop") or 0),
		1 - (Spring.GetGameRulesParam("mex_max_x_prop") or 1),
		(Spring.GetGameRulesParam("mex_min_z_prop") or 0),
		1 - (Spring.GetGameRulesParam("mex_max_z_prop") or 1))
	
	local edgePadding = math.min(math.min(Game.mapSizeX, Game.mapSizeZ))*math.max(minEdgeProp - 0.04, 0.03)
	local boxes = GG.GetPlanetwarsBoxes(0.1, 0.1, 0.38, edgePadding)
	--Spring.Utilities.TableEcho(boxes, "boxes")
	
	local rect = boxes.neutral
	--vector.DrawLine(rect[1], vector.Add(rect[1], rect[2]))
	--vector.DrawLine(rect[1], vector.Add(rect[1], rect[3]))
	--vector.DrawLine(vector.Add(rect[1], rect[2]), vector.Add(rect[1], vector.Add(rect[2], rect[3])))
	--vector.DrawLine(vector.Add(rect[1], rect[3]), vector.Add(rect[1], vector.Add(rect[2], rect[3])))
	
	local teamSide, edgeSide = rect[2], rect[3]
	local teamFacingLength = vector.AbsVal(teamSide)
	local spawnsPerTeam = 2
	if teamFacingLength > 3700 then
		spawnsPerTeam = 3
	end
	if teamFacingLength > 9000 then
		spawnsPerTeam = 4
	end
	if teamFacingLength > 16000 then
		spawnsPerTeam = 5
	end
	
	--vector.DrawPoint(rect[1], teamFacingLength)
	--vector.DrawPoint(vector.Add(rect[1], vector.Mult(0.1, rect[2])), "VEC 2")
	--vector.DrawPoint(vector.Add(rect[1], vector.Mult(0.1, rect[3])), "VEC 3")
	
	SpawnStructuresForAllyTeam(rect, spawnsPerTeam, 0)
	SpawnStructuresForAllyTeam(rect, spawnsPerTeam, 1)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function QueueRecreateObjective(unitID)
	toCreate = toCreate or {}
	local x, y, z = Spring.GetUnitPosition(unitID)
	local allyTeamID = Spring.GetUnitAllyTeam(unitID)
	if allyTeamID > 1 then
		return
	end
	
	toCreate[#toCreate + 1] = {
		x = x,
		z = z,
		allyTeamID = 1 - allyTeamID,
		direction = Spring.GetUnitBuildFacing(unitID)
	}
end

local function DoLossCheck(allyTeamID)
	for unitID, data in IterableMap.Iterator(objectives) do
		if unitID and Spring.GetUnitAllyTeam(unitID) == allyTeamID then
			return false
		end
	end
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if unitDefID == objUnitDefID then
		IterableMap.Add(objectives, unitID)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if unitDefID == objUnitDefID then
		QueueRecreateObjective(unitID)
		IterableMap.Remove(objectives, unitID)
		checkLoss = true
	end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	checkLoss = true
end

function gadget:GameFrame(n)
	if toCreate then
		for i = 1, #toCreate do
			local data = toCreate[i]
			local teams = Spring.GetTeamList(data.allyTeamID)
			local teamID = teams[1]
			Spring.CreateUnit(objUnitDefID, data.x, Spring.GetGroundHeight(data.x, data.z), data.z, data.direction, teamID, false, true)
		end
		toCreate = false
	end
	if checkLoss or n%600 == 0 then
		local lossTeamOne = DoLossCheck(0)
		local lossTeamTwo = DoLossCheck(1)
		if (lossTeamOne and true or false) ~= (lossTeamTwo and true or false) then
			if lossTeamOne then
				GG.CauseVictory(1)
			else
				GG.CauseVictory(0)
			end
		end
	end
end

function gadget:Initialize()
	local modOpt = (Spring.GetModOptions() or {}).artefact_control
	if modOpt ~= "1" and modOpt ~= 1 then
		gadgetHandler:RemoveGadget()
		return
	end
	if Spring.GetGameFrame() <= 0 then
		PlaceArtefacts()
	end
end
