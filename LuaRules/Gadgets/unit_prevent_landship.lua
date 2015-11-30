--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Prevent Landship",
    desc      = "Prevents ships from moving about on land.",
    author    = "Google Frog",
    date      = "16 August 2015",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local shipDefs = {}

for unitDefID = 1, #UnitDefs do
	local ud = UnitDefs[unitDefID]
	if ud.moveDef.family == "ship" then
		shipDefs[unitDefID] = -ud.moveDef.depth
	end
end

local ALLY_ACCESS = {allied = true}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local PERIOD = 25

local GRAVITY = Game.gravity

local shipList = {}
local shipMap = {}

local function AddShip(unitID, unitDefID)
	local index = #shipList + 1
	local data = {
		index = index,
		unitID = unitID,
		maxHeight = shipDefs[unitDefID],
		landTime = 0
	}
	shipList[index] = data
	shipMap[unitID] = data
end

local function RemoveShip(unitID)
	local index = shipMap[unitID].index
	local endIndex = #shipList
	
	shipList[endIndex].index = index
	shipList[index] = shipList[endIndex]
	
	shipList[endIndex] = nil
	shipMap[unitID] = nil
end

local function UpdateShip(data)
	local unitID = data.unitID
	local x, y, z = Spring.GetUnitPosition(unitID)
	if y and y > data.maxHeight then
		local groundHeight = Spring.GetGroundHeight(x,z)
		if groundHeight and groundHeight > data.maxHeight then
			if groundHeight > y - 0.1 then
				if data.landTime < 2 then
					data.landTime = data.landTime + 1
				else
					data.moveDisable = true
					Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 0, ALLY_ACCESS)
					GG.UpdateUnitAttributes(unitID)
					GG.DetatchFromGround(unitID, 1, 0.25, 0.0002*GRAVITY)
					GG.AddGadgetImpulseRaw(unitID, 0, 0.001, 0, true, true)
				end
			end
			return
		end
	end
	
	if data.moveDisable then
		data.moveDisable = false
		Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 1, ALLY_ACCESS)
		GG.UpdateUnitAttributes(unitID)
	end
	data.landTime = 0
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:GameFrame(frame)
	if frame%PERIOD == 0 then
		for i = 1, #shipList do
			local data = shipList[i]
			if Spring.ValidUnitID(data.unitID) then
				UpdateShip(data)
			else
				RemoveShip(data.unitID)
			end
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	if shipDefs[unitDefID] then
		AddShip(unitID, unitDefID)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	if shipMap[unitID] then
		RemoveShip(unitID)
	end
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end
