function widget:GetInfo()
   return {
      name         = "Starlight Targetting",
      desc         = "Starlight targetting 0.1",
      author       = "dyth68",
      date         = "2022",
      license      = "PD", -- should be compatible with Spring
      layer        = 0,
	  handler		= true, --for adding customCommand into UI
      enabled      = true
   }
end


local UPDATE_FRAME=2
local StarlightStack = {}
local GetUnitPosition = Spring.GetUnitPosition
local GiveOrderToUnit = Spring.GiveOrderToUnit
local GetUnitsInCylinder = Spring.GetUnitsInCylinder
local GetUnitIsDead = Spring.GetUnitIsDead
local GetMyTeamID = Spring.GetMyTeamID
local GetUnitDefID = Spring.GetUnitDefID
local GetTeamUnits = Spring.GetTeamUnits
local GetUnitStates = Spring.GetUnitStates
local Echo = Spring.Echo
local GetSpecState = Spring.GetSpectatingState
local CMD_STOP = CMD.STOP
local CMD_ATTACK = CMD.ATTACK
local CMD_UNIT_SET_TARGET = Spring.Utilities.CMD.UNIT_SET_TARGET

local StarlightUnitDefID = UnitDefNames["mahlazer"].id

local immobiles = {}
for unitDefID, unitDef in pairs(UnitDefs) do
  if unitDef.isImmobile then
    immobiles[unitDefID] = true
  end
end

function sqdist(p, q)
	return (p[1]-q[1])^2 + (p[2]-q[2])^2 + (p[3]-q[3])^2
end

function getTargetToClosest(targetPos)
	if targetPos ~= nil then
		local nearUnits = Spring.GetUnitsInRectangle(targetPos[1]-2000, targetPos[3]-2000, targetPos[1]+2000, targetPos[3]+2000)
		local shortestDist = 9999999
		local bestSol = nil
		for k, v in pairs(nearUnits) do
			if not (Spring.IsUnitAllied(v)) and (Spring.IsUnitInLos(v) or immobiles[Spring.GetUnitDefID(v)]) then
				local x,y,z = Spring.GetUnitPosition(v)
				local dist = sqdist(targetPos, {x,y,z})
				if dist < shortestDist then
					shortestDist = dist
					bestSol = v
				end
			end
		end
		return bestSol
	end
	return nil
end

function newStarlight(unitID)
	StarlightStack[unitID] = {
		unitID = unitID,
		pos= {GetUnitPosition(unitID)},
		targetPos = nil,
		currentTarget = nil
	}
end

function updateStarlight(unitID)
	local currStarlight = StarlightStack[unitID]
	local targetType, isUserTarget, unitIDorPos = Spring.GetUnitWeaponTarget(unitID, 1)
	if targetType == 1 then
		local targetX, targetY, targetZ = Spring.GetUnitPosition(unitIDorPos)
		if currStarlight.currentTarget ~= unitIDorPos or targetZ == nil then
			if not isUserTarget then
				local newTarget = getTargetToClosest(currStarlight.targetPos)
				if newTarget ~= nil then
					local targetX, targetY, targetZ = Spring.GetUnitPosition(newTarget)
					currStarlight.targetPos = {targetX, targetY, targetZ}
					currStarlight.currentTarget = newTarget
					--Echo("trying set target")
					--Spring.MarkerAddPoint(targetX, targetY, targetZ, newTarget)
					Spring.GiveOrderToUnit(unitID, CMD_ATTACK, newTarget, 0);
					--Echo("Set")
					return
				end
			end
		end
		if targetZ ~= nil then
			currStarlight.targetPos = {targetX, targetY, targetZ}
		end
		currStarlight.currentTarget = unitIDorPos
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
		if (unitDefID == StarlightUnitDefID)
		and (unitTeam==GetMyTeamID()) then
			newStarlight(unitID)
		end
end

function widget:UnitDestroyed(unitID) 
	if not (StarlightStack[unitID]==nil) then
		StarlightStack[unitID]=nil
		GiveOrderToUnit(unitID,CMD_STOP, {}, {""},0)
	end
end

function widget:GameFrame(n) 
	-- Every frame updates are acceptable for units this big and rare
	--if (n%UPDATE_FRAME==0) then
		for unitId,Starlight in pairs(StarlightStack) do 
			updateStarlight(unitId)
		end
	--end
end

--- COMMAND HANDLING

-- The rest of the code is there to disable the widget for spectators
local function DisableForSpec()
	if GetSpecState() then
		widgetHandler:RemoveWidget(widget)
	end
end


function widget:Initialize()
	DisableForSpec()
	Echo("Starlight targetting loaded")
	local units = GetTeamUnits(Spring.GetMyTeamID())
	for i=1, #units do
		local unitID = units[i]
		local unitDefID = GetUnitDefID(unitID)
		if (unitDefID == StarlightUnitDefID)  then
			if  (StarlightStack[unitID]==nil) then
				newStarlight(unitID)
			end
		end
	end
end


function widget:PlayerChanged (playerID)
	DisableForSpec()
end