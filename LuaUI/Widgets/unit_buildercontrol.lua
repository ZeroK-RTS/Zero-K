--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Builder Manager",
    desc      = "v0.01 Manage your builders with buttons.",
    author    = "CarRepairer",
    date      = "2010-04-25",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
	enabled	  = false  
 }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Game'
options = {
	selectidle = {
		name = 'Select An Idle Builder',
		type = 'button',
		OnChange = function() end
	}
	
}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local echo = Spring.Echo

local builders = {}


local myTeamID

local bPoint = 0




--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function isBuilder(ud) 
	return ud.isBuilder
end

local function GetFirstCommand(unitID)
	local queue = Spring.GetUnitCommands(unitID)
	return queue and queue[1]
end

options.selectidle.OnChange = function()

	local selB
	
	local selNextB = true

	local units = Spring.GetSelectedUnits()
	if units and #units == 1 then
		local udid = Spring.GetUnitDefID( units[1] )
		local ud = UnitDefs[udid]
		if ud and isBuilder(ud) then
			selB = units[1]
			selNextB = false
		end
	end
	
	local firstB
	
	for i=1,2 do
		for bID, _ in pairs(builders) do
			if not firstB then
				firstB = bID
			end
			
			
			
			if selNextB then
				bPoint = bID
				local c1 = GetFirstCommand(bID)
				if not c1 then
					local x,y,z = Spring.GetUnitPosition(bID)
					Spring.SelectUnitArray({bID})
					Spring.SetCameraTarget(x,y,z, 1)
					return
				end
			end
			
			if bID == selB then
				selNextB = true
			end
			
		end
	end
	
end

--------------------------------------------------------------------------------

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	local ud = UnitDefs[unitDefID]
	if not ud then return end
	
	if isBuilder(ud) then
		builders[unitID] = true
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	builders[unitID] = nil
end
 
function widget:Initialize()
	local _, _, spec, team = Spring.GetPlayerInfo(Spring.GetMyPlayerID()) 
	myTeamID = team

	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		widget:UnitCreated(unitID, unitDefID, myTeamID)
	end
end




--------------------------------------------------------------------------------











