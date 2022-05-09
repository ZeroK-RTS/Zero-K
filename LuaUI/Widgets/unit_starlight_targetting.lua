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
local SlowAimStack = {}
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
local BerthaUnitDefID = UnitDefNames["staticheavyarty"].id
local DRPUnitDefID = UnitDefNames["raveparty"].id

local immobiles = {}
for unitDefID, unitDef in pairs(UnitDefs) do
  if unitDef.isImmobile then
    immobiles[unitDefID] = true
  end
end

function sqdist(p, x, y, z)
	return (p[1]-x)^2 + (p[2]-y)^2 + (p[3]-z)^2
end

function getTargetToClosest(targetPos, precise)
	if targetPos ~= nil then
		local nearUnits = Spring.GetUnitsInRectangle(targetPos[1]-2000, targetPos[3]-2000, targetPos[1]+2000, targetPos[3]+2000)
		local shortestDist = math.max
		local bestSol = nil
		for k, v in pairs(nearUnits) do
			if not (Spring.IsUnitAllied(v)) and (Spring.IsUnitInLos(v) or immobiles[Spring.GetUnitDefID(v)] or not precise) then
				local x,y,z = Spring.GetUnitPosition(v)
				local dist = sqdist(targetPos, x, y, z)
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

function newSlowAimer(unitID, prcs)
	SlowAimStack[unitID] = {
		unitID = unitID,
		pos= {GetUnitPosition(unitID)},
		targetPos = nil,
		currentTarget = nil,
		precise = prcs
	}
end

function updateSlowAimer(unitID)
	local currSlowAimer = SlowAimStack[unitID]
	local targetType, isUserTarget, unitIDorPos = Spring.GetUnitWeaponTarget(unitID, 1)
	if targetType == 1 then
		local targetX, targetY, targetZ = Spring.GetUnitPosition(unitIDorPos)
		if currSlowAimer.currentTarget ~= unitIDorPos or targetZ == nil then
			if not isUserTarget then
				local newTarget = getTargetToClosest(currSlowAimer.targetPos, currSlowAimer.precise)
				if newTarget ~= nil then
					local targetX, targetY, targetZ = Spring.GetUnitPosition(newTarget)
					currSlowAimer.targetPos = {targetX, targetY, targetZ}
					currSlowAimer.currentTarget = newTarget
					--Echo("trying set target")
					--Spring.MarkerAddPoint(targetX, targetY, targetZ, newTarget)
					Spring.GiveOrderToUnit(unitID, CMD_ATTACK, newTarget, 0);
					--Echo("Set")
					return
				end
			end
		end
		if targetZ ~= nil then
			currSlowAimer.targetPos = {targetX, targetY, targetZ}
		end
		currSlowAimer.currentTarget = unitIDorPos
	end
end

function isSlowAimer(unitDefID)
	return (unitDefID == StarlightUnitDefID) or (unitDefID == BerthaUnitDefID) or (unitDefID == DRPUnitDefID)
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
		if isSlowAimer(unitDefID)
		and (unitTeam==GetMyTeamID()) then
			newSlowAimer(unitID, unitDefID == StarlightUnitDefID)
		end
end

function widget:UnitDestroyed(unitID) 
	if not (SlowAimStack[unitID]==nil) then
		SlowAimStack[unitID]=nil
		GiveOrderToUnit(unitID,CMD_STOP, {}, {""},0)
	end
end

function widget:GameFrame(n) 
	-- Every frame updates are acceptable for units this big and rare
	--if (n%UPDATE_FRAME==0) then
		for unitId,_ in pairs(SlowAimStack) do 
			updateSlowAimer(unitId)
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
		if isSlowAimer(unitDefID) then
			if  (SlowAimStack[unitID]==nil) then
				newSlowAimer(unitID, unitDefID == StarlightUnitDefID)
			end
		end
	end
end


function widget:PlayerChanged (playerID)
	DisableForSpec()
end
