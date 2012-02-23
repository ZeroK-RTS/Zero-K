
function gadget:GetInfo()
  return {
    name      = "Water Effects",
    desc      = "Umbrela (;Þ) gadget for dealing with units that do things in the water. Water tank weapons and extra regen.",
    author    = "Google Frog",
    date      = "24 Feb 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local tank = {}
local tankByID = {data = {}, count = 0}

local TANK_MAX = 300
local REGEN_PERIOD = 13
local SHOT_COST = 1.2
local REGEN_RATE = 6

local function updateWeaponFromTank(unitID)

	local proportion = tank[unitID].storage/TANK_MAX

	Spring.SetUnitWeaponState(unitID, 0, {
		range = proportion*200 + 100,
		projectileSpeed = proportion*10+7.5,
		reloadTime = 0.2 - 0.1*proportion,
	})

end

--local last

function shotWaterWeapon(unitID)
	--[[
	local frame = Spring.GetGameFrame()
    if last then
        Spring.Echo(frame-last)
    end
    last = frame
	--]]
	tank[unitID].storage = tank[unitID].storage - SHOT_COST

	if tank[unitID].storage < 0 then
		tank[unitID].storage = 0
	end
	
	updateWeaponFromTank(unitID)
	
	Spring.SetUnitRulesParam(unitID,"watertank",tank[unitID].storage, {inlos = true})
end

GG.shotWaterWeapon = shotWaterWeapon

function gadget:GameFrame(n)
	
	if n%REGEN_PERIOD == 0 then

		local i = 1
		while i <= tankByID.count do
			local unitID = tankByID.data[i]

			if Spring.ValidUnitID(unitID) then
				local height = select(2, Spring.GetUnitPosition(unitID))

				if height < 0 then
					if tank[unitID].storage ~= TANK_MAX then
						tank[unitID].storage = tank[unitID].storage + math.max(-height,16)*REGEN_RATE*0.0625
						if tank[unitID].storage > TANK_MAX then
							tank[unitID].storage = TANK_MAX
						end
						Spring.SetUnitRulesParam(unitID,"watertank",tank[unitID].storage, {inlos = true})
						updateWeaponFromTank(unitID)
					end
				end
				i = i + 1
			else
				tank[tankByID.data[tankByID.count]].index = i
				tankByID.data[i] = tankByID.data[tankByID.count]
				tankByID.data[tankByID.count] = nil
				tank[unitID] = nil
				tankByID.count = tankByID.count - 1
			end
		end
		
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if unitDefID == UnitDefNames["amphraider2"].id then	
		tankByID.count = tankByID.count + 1
		tankByID.data[tankByID.count] = unitID
		tank[unitID] = {
			storage = TANK_MAX,
			index = tankByID.count,
		}
		Spring.SetUnitRulesParam(unitID,"watertank",tank[unitID].storage, {inlos = true})
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if tank[unitID] then
		tank[tankByID.data[tankByID.count]].index = tank[unitID].index
		tankByID.data[tank[unitID].index] = tankByID.data[tankByID.count]
		tankByID.data[tankByID.count] = nil
		tank[unitID] = nil
		tankByID.count = tankByID.count - 1
	end
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local team = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, team)
	end
end
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------