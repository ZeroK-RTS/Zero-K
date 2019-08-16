--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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

local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spSetUnitRulesParam = Spring.SetUnitRulesParam

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local unit = {}
local unitByID = {data = {}, count = 0}

local unitDefData, waterCannonIterable, waterCannonIndexable = include("LuaRules/Configs/water_effect_defs.lua")

for id, data in pairs(UnitDefs) do
	if data.customParams then
		if data.customParams.amph_regen then
			if not unitDefData[id] then
				unitDefData[id] = {}
			end
			unitDefData[id].healthRegen = tonumber(data.customParams.amph_regen)
		end
		if data.customParams.amph_submerged_at then
			if not unitDefData[id] then
				unitDefData[id] = {}
			end
			unitDefData[id].submergedAt = tonumber(data.customParams.amph_submerged_at)
		end
	end
end

local REGEN_PERIOD = 13
local SECOND_MULT = REGEN_PERIOD/30

local LOS_ACCESS = {inlos = true}

local function updateWeaponFromTank(unitID)

	local data = unit[unitID]
	local effect = unitDefData[data.unitDefID]

	local proportion = unit[unitID].storage/effect.tankMax

	local projectiles = math.floor(proportion*effect.bonusProjectiles)+2
	
	spSetUnitRulesParam(unitID, "water_projectiles", projectiles)
	
	-- these numbers are configable too!!!
	Spring.SetUnitWeaponState(unitID, 1, {
		range = proportion*effect.scalingRange + effect.baseRange,
		projectileSpeed = proportion*10+8,
		projectiles = projectiles,
	})

end

function shotWaterWeapon(unitID)
	
	local data = unit[unitID]
	local effect = unitDefData[data.unitDefID]
	
	data.storage = data.storage - effect.shotCost

	if data.storage < 0 then
		data.storage = 0
	end
	
	updateWeaponFromTank(unitID)
	
	--local proportion = unit[unitID].storage/effect.tankMax
	--local reloadFrames = 2 - proportion
    --
	--if math.random() > reloadFrames%1 then
	--	reloadFrames = math.floor(reloadFrames)
	--else
	--	reloadFrames = math.ceil(reloadFrames)
	--end
	--
	--Spring.SetUnitWeaponState(unitID, 1, {
	--	reloadFrame = Spring.GetGameFrame() + reloadFrames,
	--})
	
	Spring.SetUnitRulesParam(unitID,"watertank",data.storage, LOS_ACCESS)
end

GG.shotWaterWeapon = shotWaterWeapon

function gadget:GameFrame(n)
	
	if n%REGEN_PERIOD == 0 then

		local i = 1
		while i <= unitByID.count do
			local unitID = unitByID.data[i]
			local data = unit[unitID]
			local effect = unitDefData[data.unitDefID]

			if Spring.ValidUnitID(unitID) then
				local x,y,z = Spring.GetUnitPosition(unitID)
				local height = Spring.GetGroundHeight(x,z) or y
				local stunned_or_inbuild = spGetUnitIsStunned(unitID) or (Spring.GetUnitRulesParam(unitID, "disarmed") == 1)
				if not stunned_or_inbuild then
					if data.storage and data.storage ~= effect.tankMax then
						local regenHeight = -height
						if regenHeight > effect.submergedAt then
							regenHeight = effect.submergedAt
						end
						if regenHeight < effect.baseHeight then
							regenHeight = effect.baseHeight
						end
						data.storage = data.storage + regenHeight*effect.tankRegenRate*SECOND_MULT/effect.submergedAt
						if data.storage > effect.tankMax then
							data.storage = effect.tankMax
						end
						Spring.SetUnitRulesParam(unitID,"watertank",data.storage, LOS_ACCESS)
						updateWeaponFromTank(unitID)
					end
					if height < 0 then
						local hp, maxHp = Spring.GetUnitHealth(unitID)
						local regenMult = (Spring.GetUnitRulesParam(unitID,"totalBuildPowerChange") or 1)
						local newHp = hp + math.min(-height,effect.submergedAt) * effect.healthRegen * regenMult * SECOND_MULT/effect.submergedAt
						Spring.SetUnitHealth(unitID, newHp)
					end
				end
				i = i + 1
			else
				unit[unitByID.data[unitByID.count] ].index = i
				unitByID.data[i] = unitByID.data[unitByID.count]
				unitByID.data[unitByID.count] = nil
				unit[unitID] = nil
				unitByID.count = unitByID.count - 1
			end
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if unitDefData[unitDefID] then
		local tankMax = unitDefData[unitDefID].tankMax
		unitByID.count = unitByID.count + 1
		unitByID.data[unitByID.count] = unitID
		unit[unitID] = {
			storage = tankMax,
			index = unitByID.count,
			unitDefID = unitDefID,
		}
		if tankMax then
			Spring.SetUnitRulesParam(unitID,"watertank",unit[unitID].storage, LOS_ACCESS)
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if unit[unitID] then
		unit[unitByID.data[unitByID.count] ].index = unit[unitID].index
		unitByID.data[unit[unitID].index] = unitByID.data[unitByID.count]
		unitByID.data[unitByID.count] = nil
		unit[unitID] = nil
		unitByID.count = unitByID.count - 1
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
