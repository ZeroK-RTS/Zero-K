function widget:GetInfo() return {
	name    = "Show selected unit range",
	author  = "very_bad_soldier / versus666",
	date    = "October 21, 2007 / September 08, 2010",
	license = "GNU GPL v2",
	layer   = 0,
	enabled = true,
} end

local spGetSelUnitsSorted	= Spring.GetSelectedUnitsSorted
local spGetUnitViewPosition	= Spring.GetUnitViewPosition
local spGetUnitRulesParam   = Spring.GetUnitRulesParam
local spGetUnitWeaponState  = Spring.GetUnitWeaponState
local spIsGUIHidden 		= Spring.IsGUIHidden

local glColor            = gl.Color
local glLineWidth        = gl.LineWidth
local glDrawGroundCircle = gl.DrawGroundCircle

options_path = 'Settings/Interface/Defense and Cloak Ranges'
options = {
	showselectedunitrange = {
		name = 'Show selected unit(s) range(s)',
		type = 'bool',
		value = false,
		OnChange = function (self)
			if self.value then
				widgetHandler:UpdateCallIn("DrawWorldPreUnit")
			else
				widgetHandler:RemoveCallIn("DrawWorldPreUnit")
			end
		end,
	},
}

local commDefIDs = {}
local wepRanges = {}
for unitDefID, unitDef in pairs(UnitDefs) do
	if unitDef.customParams.dynamic_comm then
		commDefIDs[unitDefID] = true
	end

	local weapons = unitDef.weapons
	if #weapons > 0 then
		wepRanges[unitDefID] = {}
		local entryIndex = 0
		for weaponIndex = 1, #weapons do
			local weaponRange = WeaponDefs[weapons[weaponIndex].weaponDef].range
			if (weaponRange > 32) then -- 32 and under are fake weapons
				entryIndex = entryIndex + 1
				wepRanges[unitDefID][entryIndex] = weaponRange
			end
		end
	end
end

local function DrawRangeCircle(ux,uy,uz,range,r)
	glColor(1.0 - (r / 5), 0, 0, 0.35)
	glDrawGroundCircle(ux, uy, uz, range, 40)
end

local function DrawComRanges(unitDefID,unitIDs)
	for i = 1, #unitIDs do
		local unitID = unitIDs[i]
		local ux, uy, uz = spGetUnitViewPosition(unitID)
		local weap1 = spGetUnitRulesParam(unitID, "comm_weapon_num_1")
		if weap1 then
			local weapRange = spGetUnitWeaponState(unitID,weap1,"range")
			if weapRange then
				DrawRangeCircle(ux,uy,uz,weapRange,1)
			end
		end

		local weap2 = spGetUnitRulesParam(unitID, "comm_weapon_num_2")
		if weap2 then
			local weapRange = spGetUnitWeaponState(unitID,weap2,"range")
			if weapRange then
				DrawRangeCircle(ux,uy,uz,weapRange,2)
			end
		end
	end
end

local function DrawUnitsRanges(uDefID, uIDs)
	local uWepRanges = wepRanges[uDefID]
	if uWepRanges then
		for i = 1, #uIDs do
			local ux, uy, uz = spGetUnitViewPosition(uIDs[i])
			for r = 1, #uWepRanges do
				DrawRangeCircle(ux,uy,uz,uWepRanges[r],r)
			end
		end
	end
end

function widget:DrawWorldPreUnit()
	if spIsGUIHidden() then
		return
	end

	glLineWidth(1.5)

	local selUnits = spGetSelUnitsSorted()
	for uDefID, uIDs in pairs(selUnits) do
		if commDefIDs[uDefID] then -- Dynamic comm have different ranges and different weapons activated
			DrawComRanges(uDefID, uIDs)
		else
			DrawUnitsRanges(uDefID, uIDs)
		end
	end

	glColor(1, 1, 1, 1)
	glLineWidth(1.0)
end

function widget:Initialize()
	widgetHandler:RemoveCallIn("DrawWorldPreUnit")
end
