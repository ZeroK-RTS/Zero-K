function widget:GetInfo()
	return {
		name      = "Mobile Factory Helper",
		desc      = "Displays queues of the fake units.",
		author    = "Shaman",
		date      = "12 January 2024",
		license   = "CC-0",
		layer     = 2500,
		enabled   = true,
		alwaysStart = true,
	}
end

local drawCount = 0
local wantDraw = false
local drawThese = {}
local wantedUnits = {}
local watchUnitsForUnselection = {}
local CMD_QUEUE_MODE = 34225

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.customParams.ismobilefac then
		wantedUnits[i] = true
	end
end

local spDrawUnitCommands = Spring.DrawUnitCommands
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitRulesParam = Spring.GetUnitRulesParam

local watchDefs = {
	[UnitDefNames["athena"].id] = true
}

local function CheckForAthenaUnselection(oldselect, newselect)
	local notInTab2 = {}
	for k, _ in pairs(oldselect) do
		if newselect[k] == nil then
			Spring.GiveOrderToUnit(k, CMD_QUEUE_MODE, {0}, 0) -- turn off queue mode.
			watchUnitsForUnselection[k] = nil
		end
	end
	watchUnitsForUnselection = newselect
end

function widget:UnitDestroyed(unitID)
	watchUnitsForUnselection[unitID] = nil
end

function widget:SelectionChanged(selectedUnits)
	if not (selectedUnits and selectedUnits[1]) then
		CheckForAthenaUnselection(watchUnitsForUnselection, {})
		wantDraw = false
		return
	end
	drawCount = 0
	local watchUnits = {}
	for i = 1, #selectedUnits do
		local unitID = selectedUnits[i]
		local unitDef = spGetUnitDefID(unitID)
		if wantedUnits[unitDef] then
			if watchDefs[unitDef] then
				watchUnits[unitID] = true
				watchUnitsForUnselection[unitID] = true
			end
			local queueUnit = spGetUnitRulesParam(unitID, "queueunit")
			if queueUnit then
				drawCount = drawCount + 1
				drawThese[drawCount] = spGetUnitRulesParam(unitID, "queueunit")
			end
		end
	end
	CheckForAthenaUnselection(watchUnitsForUnselection, watchUnits)
	wantDraw = drawCount > 0
end

local function DoDraw()
	if wantDraw and drawCount > 0 then
		for i = 1, drawCount do
			spDrawUnitCommands(drawThese[i])
		end
	end
end

function widget:DrawWorld()
	DoDraw()
end
