if (not gadgetHandler:IsSyncedCode()) then
	return
end

function gadget:GetInfo()
	return {
		name = "LockOptions",
		desc = "Modoption for locking units. 90% Copypasted from game_perks.lua",
		author = "Storage",
		license = "Public Domain",
		layer = -1,
		enabled = true,
	}
end



local disabledunitsstring = Spring.GetModOptions().disabledunits or ""
local disabledunits = {}

if (disabledunitsstring=="" and #disabledunits==0) then --no unit to disable, exit
	return
end

if disabledunitsstring ~= "" then 
	for i in string.gmatch(disabledunitsstring, '([^+]+)') do
		--I should check whether the unit name actually exists, but it seems UnitDefNames hasn't been created at this stage yet
		disabledunits[#disabledunits+1] = i
	end
end


local function UnlockUnit(unitID, lockDefID)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
	if (cmdDescID) then
		local cmdArray = {disabled = false}
		Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
	end
end

local function LockUnit(unitID, lockDefID)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
	if (cmdDescID) then
		local cmdArray = {disabled = true}
		Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
	end
end

local function RemoveUnit(unitID, lockDefID)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
	if (cmdDescID) then
		Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
	end
end

local function SetBuildOptions(unitID, unitDefID)
	local unitDef = UnitDefs[unitDefID]
	if (unitDef.isBuilder) then
		for _, buildoptionID in pairs(unitDef.buildOptions) do
			for _,unit in pairs(disabledunits) do
				if (UnitDefNames[unit]) then 
					RemoveUnit(unitID, UnitDefNames[unit].id)
				end
			end
			--for _,unit in pairs(lockedUnits) do
			--	if (UnitDefNames[unit]) then 
			--		LockUnit(unitID, UnitDefNames[unit].id)
			--	end
			--end
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	SetBuildOptions(unitID, unitDefID)
end

function gadget:Initialize()
	local units = Spring.GetAllUnits()
	for i=1, #units do
		local udid = Spring.GetUnitDefID(units[i])
		gadget:UnitCreated(units[i], udid)
	end
end
