if not Script.GetSynced() then return end

function gadget:GetInfo()
	return {
		name    = "Fire Once command",
		author  = "Sprung",
		license = "PD",
		layer   = 0,
		enabled = true,
	}
end

local TARGET_UNIT = 1
local TARGET_POS = 2

local spGetUnitWeaponTarget = Spring.GetUnitWeaponTarget
local spGetUnitCurrentCommand = Spring.GetUnitCurrentCommand
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spSetUnitTarget = Spring.SetUnitTarget
local CMD_ATTACK = CMD.ATTACK
local CMD_REMOVE = CMD.REMOVE
local CMD_OPT_CTRL = CMD.OPT_CTRL
local CMD_OPT_SHIFT = CMD.OPT_SHIFT

local fakeWeaponByNum = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.weapons then
		for j = 1, #ud.weapons do
			local weaponDefID = ud.weapons[j].weaponDef
			local wd = WeaponDefs[weaponDefID]
			if wd.customParams and wd.customParams.bogus then
				fakeWeaponByNum[i] = fakeWeaponByNum[i] or {}
				fakeWeaponByNum[i][j] = true
			end
		end
	end
end


function gadget:ScriptEndBurst(unitID, unitDefID, weaponNum)
	if (fakeWeaponByNum[unitDefID] and fakeWeaponByNum[unitDefID][weaponNum]) then
		return
	end
	local targetType, isUserTarget, targetID = spGetUnitWeaponTarget(unitID, weaponNum)
	if not isUserTarget then
		return
	end

	local cmdID, cmdOpt, cmdTag, cmdParam1, cmdParam2, cmdParam3, cmdParam4 = spGetUnitCurrentCommand(unitID)
	local singleTarget = (cmdID == CMD_ATTACK and (cmdParam4 or 0) == 0 and Spring.Utilities.IsBitSet(cmdOpt, CMD_OPT_CTRL))
	if not singleTarget then
		-- FIXME: jinking/kiting units might get a move command inserted in front (tested with gator)
		return
	end

	if  (targetType ~= TARGET_UNIT or cmdParam2 or cmdParam1 ~= targetID)
	and (targetType ~= TARGET_POS  or ((cmdParam4 or 0) ~= 0) or cmdParam1 ~= targetID[1] or cmdParam2 ~= targetID[2] or cmdParam3 ~= targetID[3]) then
		return
	end

	if Spring.Utilities.GetUnitRepeat(unitID) then
		spSetUnitTarget(unitID, nil)
		spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0)
		spGiveOrderToUnit(unitID, CMD_ATTACK, {cmdParam1, cmdParam2, cmdParam3}, Spring.Utilities.AndBit(cmdOpt, CMD_OPT_SHIFT))
	else
		--[[ Unit keeps shooting otherwise; doesn't seem to affect Set Target negatively though.
			 Has to be before REMOVE because else if there's 2 commands in a row, the unit already
			 starts doing the second command by the time the target it set to nil ]]
		spSetUnitTarget(unitID, nil)
		spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0)
	end
end
