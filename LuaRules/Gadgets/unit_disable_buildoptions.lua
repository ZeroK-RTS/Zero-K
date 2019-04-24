-- $Id: unit_disable_buildoptions.lua 4456 2009-04-20 13:23:49Z google frog $
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name			= "Disable Buildoptions",
		desc			= "Disables wind if wind is too low, units if waterdepth is not appropriate.",
		author		= "quantum",
		date			= "May 11, 2008",
		license	 = "GNU GPL, v2 or later",
		layer		 = 0,
		enabled	 = true	--	loaded by default?
	}
end

--------------------------------------------------------------------------------
--config
--------------------------------------------------------------------------------

--local breakEvenWind = 0.91 --actual value
--local breakEvenWind = 0.21 --only maps like comet should be marked as no-wind, not maps like Tundra

--------------------------------------------------------------------------------
--speedups
--------------------------------------------------------------------------------

local FindUnitCmdDesc = Spring.FindUnitCmdDesc
local GetUnitPosition = Spring.GetUnitPosition
local GetGroundHeight = Spring.GetGroundHeight
local disableWind
--values: {unitID, reason,}
local alwaysDisableTable = {}
local alwaysHideTable    = {}

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------


if (not gadgetHandler:IsSyncedCode()) then
	return false
end


local function DisableBuildButtons(unitID, disableTable)
	for _, disable in ipairs(disableTable) do
		local cmdDescID = Spring.FindUnitCmdDesc(unitID, -disable[1])
		if (cmdDescID) then
			local cmdArray = {disabled = true, tooltip = disable[2]}
			Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
		end
	end
end

local function HideBuildButtons(unitID, hide)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -hide)
	if (cmdDescID) then
		local cmdArray = {hidden = true}
		Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
	end
end
--[[
function gadget:Initialize()
	--local moWindMax = tonumber(Spring.GetModOptions() and Spring.GetModOptions().maxwind or -1)
	--local windMax = moWindMax >=0 and moWindMax or Game.windMax*0.1
	--local windMax = Game.windMax*0.1
	
	--if (windMax < breakEvenWind) then
	--	table.insert(alwaysDisableTable, {UnitDefNames["energywind"].id, "Unit disabled: Wind is too weak on this map.",})
	--	table.insert(alwaysDisableTable, {UnitDefNames["corwin"].id, "Unit disabled: Wind is too weak on this map.",})
	--end
	
end
--]]
function gadget:UnitCreated(unitID, unitDefID)
	local disableTable = {}
	local unitDef = UnitDefs[unitDefID]
	local posX, posY, posZ = GetUnitPosition(unitID)
	local groundheight = GetGroundHeight(posX, posZ)
	
	for key, value in ipairs(alwaysDisableTable) do
		disableTable[key] = value
	end
	
	for key, value in ipairs(alwaysHideTable) do
		HideBuildButtons(unitID, value)
	end
	
	--amph facs
	if (unitDef.isFactory and unitDef.buildOptions) then
		for _, buildoptionID in ipairs(unitDef.buildOptions) do
			if (UnitDefs[buildoptionID] and UnitDefs[buildoptionID].moveDef) then
				local moveData = UnitDefs[buildoptionID].moveDef
				if (moveData and moveData.family and moveData.depth) then
					if (moveData.family == "ship") then
						if (-groundheight < moveData.depth) then
							disableTable[#disableTable + 1] = {buildoptionID, "Unit disabled: Water is too shallow here."}
						end
					elseif (moveData.family ~= "hover") then
						if (-groundheight > moveData.depth) then
							disableTable[#disableTable + 1] = {buildoptionID, "Unit disabled: Water is too deep here."}
						end
					end
				end
			end
		end
	end
	
	DisableBuildButtons(unitID, disableTable)
end

-- AllowCommand is probably overkill

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

