function widget:GetInfo()
   return {
      name         = "Auto Reclaim/Heal/Assist",
      desc         = "Makes idle unselected builders automatically repair nearby damages units, reclaim nearby wrecks and assist nearby construction.",
      author       = "dyth68",
      date         = "2020",
      license      = "PD", -- should be compatible with Spring
      layer        = 11,
      enabled      = false
   }
end

local myteam = Spring.GetMyTeamID()
local UPDATE_FRAME=30
local ConStack = {}
local GetUnitPosition = Spring.GetUnitPosition
local GiveOrderToUnit = Spring.GiveOrderToUnit
local GetMyTeamID = Spring.GetMyTeamID
local GetUnitDefID = Spring.GetUnitDefID
local Echo = Spring.Echo
local sqrt = math.sqrt


local ConController = {
	unitID,
	cmdPos,
	
	
	new = function(self, unitID)
		-- Echo("IdleConAssist added: " .. unitID)
		self = deepcopy(self)
		self.unitID = unitID
		return self
	end,

	unset = function(self)
		-- Echo("IdleConAssist removed: " .. self.unitID)
		GiveOrderToUnit(self.unitID,CMD.STOP, {}, {""},1)
		return nil
	end,
	
	
	handle=function(self)
		local cmdQueue = Spring.GetUnitCommands(self.unitID, 3);
		if (#cmdQueue == 0) then
			if (not Spring.IsUnitSelected(self.unitID)) then              --if unit is not selected
				self.cmdPos = {GetUnitPosition(self.unitID)}
				Spring.GiveOrderToUnit(self.unitID, CMD.FIGHT, self.cmdPos, {})   --command unit to reclaim
				-- printThing("order", Spring.GetUnitCommands(self.unitID, 2), "")
			end
		else
			-- Want to issue the order to stop doing stuff if con has finished its work and is returning to its original location so that com can get through reclaim fields
			-- Also want to be very very sure we're only issuing this stop command if the only commands the unit has is the one this widget inserted
			if #cmdQueue == 2 and self.cmdPos and cmdQueue[1].id == CMD.FIGHT and cmdQueue[2].id == CMD.FIGHT then
				local posCmd1 = cmdQueue[1].params
				local posCmd2 = cmdQueue[2].params
				if posCmd2[1] == self.cmdPos[1] and posCmd2[2] == self.cmdPos[2] and posCmd2[3] == self.cmdPos[3] and posCmd1[1] == self.cmdPos[1] and posCmd1[2] == self.cmdPos[2] and posCmd1[3] == self.cmdPos[3] then
					GiveOrderToUnit(self.unitID,CMD.STOP, {}, {""},1)
					self.cmdPos = nil
				end
			end
		end
	end
}

function printThing(theKey, theTable, indent)
	if (type(theTable) == "table") then
		Echo(indent .. theKey .. ":")
		for a, b in pairs(theTable) do
			printThing(tostring(a), b, indent .. "  ")
		end
	else
		Echo(indent .. theKey .. ": " .. tostring(theTable))
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
		if UnitDefs[unitDefID].canReclaim and not UnitDefs[unitDefID].isFactory and (unitTeam==GetMyTeamID()) then
			ConStack[unitID%UPDATE_FRAME][unitID] = ConController:new(unitID);
		end
end

function widget:UnitDestroyed(unitID) 
	if not (ConStack[unitID%UPDATE_FRAME][unitID]==nil) then
		ConStack[unitID%UPDATE_FRAME][unitID]=ConStack[unitID%UPDATE_FRAME][unitID]:unset();
	end
end

function widget:GameFrame(n) 
	for _,Con in pairs(ConStack[n%UPDATE_FRAME]) do 
		Con:handle()
	end
end


function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- The rest of the code is there to disable the widget for spectators
local function DisableForSpec()
	if Spring.GetSpectatingState() then
		widgetHandler:RemoveWidget()
	end
end

local function DisableForCommshare() -- this breaks commshare very badly by not allowing them to issue orders to our cons unless they rapidly issue orders to them.
	if Spring.GetMyTeamID() ~= myteam or #Spring.GetPlayerList(Spring.GetMyTeamID()) > 1 then
		widgetHandler:RemoveWidget()
	end
end

function widget:Initialize()
	DisableForSpec()
	DisableForCommshare()
	local units = Spring.GetTeamUnits(Spring.GetMyTeamID())
	-- Echo("IdleConAssist initializing")
	for i=0, UPDATE_FRAME + 1 do
		ConStack[i] = {}
	end
	for i=1, #units do
		DefID = GetUnitDefID(units[i])
		if (UnitDefs[DefID].canReclaim and not UnitDefs[DefID].isFactory)  then
			if (ConStack[units[i]%UPDATE_FRAME][units[i]]==nil) then
				ConStack[units[i]%UPDATE_FRAME][units[i]]=ConController:new(units[i])
			end
		end
	end
end


function widget:PlayerChanged (playerID)
	DisableForSpec()
	DisableForCommshare()
end
