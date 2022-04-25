function widget:GetInfo()
   return {
      name         = "Starlight Targetting",
      desc         = "Starlight targetting 0.01",
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
local CMD_UNIT_SET_TARGET = 34923

local Starlight_ID = UnitDefNames.mahlazer.id
local StarlightUnitDefID = UnitDefNames["mahlazer"].id

local immobiles = {}
for unitDefID, unitDef in pairs(UnitDefs) do
  if unitDef.isImmobile then
    immobiles[unitDefID] = true
  end
end

function sq(x)
	return x*x
end

function sqdist(p, q)
	return sq(p[1]-q[1]) + sq(p[2]-q[2]) + sq(p[3]-q[3])
end

local StarlightControllerMT
local StarlightController = {
	unitID,
	pos,
	targetPos,
	currentTarget,


	new = function(index, unitID)
		--Echo("StarlightController added:" .. unitID)
		local self = {}
		setmetatable(self, StarlightControllerMT)
		self.unitID = unitID
		self.pos = {GetUnitPosition(self.unitID)}
		self.targetPos = nil
		self.currentTarget = nil
		return self
	end,

	unset = function(self)
		--Echo("StarlightController removed:" .. self.unitID)
		GiveOrderToUnit(self.unitID,CMD_STOP, {}, {""},1)
		return nil
	end,

	getTargetToClosest = function(self)
		if self.targetPos ~= nil then
			local nearUnits = Spring.GetUnitsInRectangle(self.targetPos[1]-2000, self.targetPos[3]-2000, self.targetPos[1]+2000, self.targetPos[3]+2000)
			local shortestDist = 9999999
			local bestSol = nil
			for k, v in pairs(nearUnits) do
				if not (Spring.IsUnitAllied(v)) and (Spring.IsUnitInLos(v) or immobiles[Spring.GetUnitDefID(v)]) then
					local x,y,z = Spring.GetUnitPosition(v)
					local dist = sqdist(self.targetPos, {x,y,z})
					if dist < shortestDist then
						shortestDist = dist
						bestSol = v
					end
				end
			end
			return bestSol
		end
		return nil
	end,

	handle=function(self)
		local targetType, isUserTarget, unitIDorPos = Spring.GetUnitWeaponTarget(self.unitID, 1)
		if targetType == 1 then
			local targetX, targetY, targetZ = Spring.GetUnitPosition(unitIDorPos)
			if self.currentTarget ~= unitIDorPos or targetZ == nil then
				if not isUserTarget then
					local newTarget = self:getTargetToClosest()
					if newTarget ~= nil then
						local targetX, targetY, targetZ = Spring.GetUnitPosition(newTarget)
						self.targetPos = {targetX, targetY, targetZ}
						self.currentTarget = newTarget
						--Echo("trying set target")
						Spring.MarkerAddPoint(targetX, targetY, targetZ, newTarget)
						Spring.GiveOrderToUnit(self.unitID, CMD_ATTACK, newTarget, 0);
						--Echo("Set")
						return
					end
				end
			end
			if targetZ ~= nil then
				self.targetPos = {targetX, targetY, targetZ}
			end
			self.currentTarget = unitIDorPos
		end
	end
}
StarlightControllerMT = {__index = StarlightController}

function widget:UnitFinished(unitID, unitDefID, unitTeam)
		if (unitDefID == Starlight_ID)
		and (unitTeam==GetMyTeamID()) then
			Echo("Registered Starlight")
			StarlightStack[unitID] = StarlightController:new(unitID);
		end
end

function widget:UnitDestroyed(unitID) 
	if not (StarlightStack[unitID]==nil) then
		StarlightStack[unitID]=StarlightStack[unitID]:unset();
	end
end

function widget:GameFrame(n) 
	if (n%UPDATE_FRAME==0) then
		for _,Starlight in pairs(StarlightStack) do 
			Starlight:handle()
		end
	end
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
	Echo("starlight targetting loaded3")
	local units = GetTeamUnits(Spring.GetMyTeamID())
	for i=1, #units do
		local unitDefID = GetUnitDefID(units[i])
		if (unitDefID == StarlightUnitDefID)  then
			if  (StarlightStack[units[i]]==nil) then
				Echo("Registered Starlight")
				StarlightStack[units[i]]=StarlightController:new(units[i])
			end
		end
	end
end


function widget:PlayerChanged (playerID)
	DisableForSpec()
end