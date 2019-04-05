--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Spherical LOS",
    desc      = "Approximates sphereical (actually a double cone) LOS by reducing LOS for very high ground units.",
    author    = "Google Frog",
    date      = "31 August 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local UPDATE_FREQUENCY = 15

local units = {count = 0, data = {}}
local unitsByID = {}
local frame = Spring.GetGameFrame()

local function AddSphericalLOSCheck(unitID, unitDefID)
	if unitsByID[unitID] then
		local index = unitsByID[unitID]
		units.data[index].removeAfter = frame + 40
	else
		local ud = UnitDefs[unitDefID]
		units.count = units.count + 1
		--GG.UnitEcho(unitID, "added")
		units.data[units.count] = {
			unitID = unitID,
			los = ud.losRadius,
			airLos = ud.airLosRadius,
			removeAfter = frame + 40,
		}
		unitsByID[unitID] = units.count
	end
end

GG.AddSphereicalLOSCheck = AddSphericalLOSCheck	-- deprecated typo'd version, left in for any reverse compatibility that might be needed
GG.AddSphericalLOSCheck = AddSphericalLOSCheck 

local function checkUnit(unitID, los, airLos)
	if not Spring.ValidUnitID(unitID) then
		return false
	end
	
	local x,y,z = Spring.GetUnitPosition(unitID)
	local ground =  Spring.GetGroundHeight(x,z)

	if ground and y then
		local diff = y - ground
		--GG.UnitEcho(unitID, diff)
		
		if diff < 10 then
			Spring.SetUnitSensorRadius(unitID, "los", los)
			Spring.SetUnitSensorRadius(unitID, "airLos", airLos)
			return true, false
		elseif diff < los then
			Spring.SetUnitSensorRadius(unitID, "los", los - diff)
			Spring.SetUnitSensorRadius(unitID, "airLos", airLos - diff)
		else
			Spring.SetUnitSensorRadius(unitID, "los", 0)
			Spring.SetUnitSensorRadius(unitID, "airLos", 0)
		end
	end

	return true, true
end

function gadget:GameFrame(f)
	if f%UPDATE_FREQUENCY == 3 then
		frame = f
		local i = 1
		while i <= units.count do
			local data = units.data[i]
			local unitID = data.unitID
			local valid, flying = checkUnit(unitID, data.los, data.airLos)
			if valid and (flying or f < data.removeAfter) then
				i = i + 1
			else
				--GG.UnitEcho(unitID, "removed")
				unitsByID[unitID] = nil
				unitsByID[units.data[units.count].unitID] = i
				units.data[i] = units.data[units.count]
				units.count = units.count - 1
			end
		end
	end
end