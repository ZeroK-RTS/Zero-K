function gadget:GetInfo()
	return {
		name      = "Area Grey Goo Handler",
		desc      = "Units will consume all wreckage in an area",
		author    = "Shaman",
		date      = "April 1, 2021",
		license   = "CC-0",
		layer     = 5,
		enabled   = true,
	}
end

if (not gadgetHandler:IsSyncedCode()) then
	return
end
local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")

local handled = IterableMap.New()
local wantedUnitDefs = {}
local featurecache = {}

local areaGreyGooDesc = {
	id      = CMD_GREYGOO,
	type    = CMDTYPE.ICON_UNIT_FEATURE_OR_AREA,
	name    = 'Reclaim (Grey Goo)', -- TODO: better name. Marketing was out today.
	action  = 'reclaim', -- this may break things for modders with cons that grey goo!
	tooltip	= 'Marks an area or wreckage for grey goo.',
}

-- Speed ups --
local spGetUnitPosition = Spring.GetUnitPosition
local spGetFeaturePosition = Spring.GetFeaturePosition
local spGetFeaturesInCylinder = Spring.GetFeaturesInCylinder
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spSetUnitMoveGoal = Spring.SetUnitMoveGoal
local spGetFeatureDefID = Spring.GetFeatureDefID
local spValidFeatureID = Spring.ValidFeatureID
local spValidUnitID = Spring.ValidUnitID
local spGetUnitCommands = Spring.GetUnitCommands
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc
local CommandOrder = 123456
local sqrt = math.sqrt

local validFeatures = {}
local _, GooDefs = VFS.Include("LuaRules/Configs/grey_goo_defs.lua")

for def, _ in pairs(GooDefs) do
	wantedUnitDefs[def] = true
end

for i = 1, #FeatureDefs do
	local fdef = FeatureDefs[i]
	if fdef.customParams and fdef.customParams.fromunit then
		validFeatures[i] = true
	end
end

local function Distance(x1, x2, y1, y2)
	return sqrt(((x2 - x1) * (x2 - x1)) + ((y2 - y1) * (y2 - y1)))
end

local function GetEligiableWrecksInArea(x, z, radius)
	local check = spGetFeaturesInCylinder(x, z, radius)
	local ret = {}
	for i = 1, #check do
		if featurecache[check[i]] then
			ret[#ret + 1] = check[i]
		end
	end
	return ret
end

local function GetClosestWreck(x, z, cx, cz, radius)
	local wrecks = GetEligiableWrecksInArea(cx, cz, radius)
	if #wrecks == 0 then -- double safety.
		return nil
	end
	local lowestDistance = math.huge
	local lowestID
	for i = 1, #wrecks do
		local id = wrecks[i]
		local x2, _, z2 = spGetFeaturePosition(id)
		local d = Distance(x, x2, z, z2)
		if d < lowestDistance then
			lowestID = id
			lowestDistance = d
		end
	end
	return lowestID
end

local function IsThereEligiableWreckNearby(x, z, radius)
	local check = spGetFeaturesInCylinder(x, z, radius)
	for i = 1, #check do
		if featurecache[check[i]] then
			return check[i] -- return the lowest one in range
		end
	end
	return nil
end

function gadget:FeatureCreated(featureID, allyTeamID)
	local featuredef = spGetFeatureDefID(featureID)
	featurecache[featureID] = validFeatures[featuredef]
end

function gadget:FeatureDestroyed(featureID)
	featurecache[featureID] = nil
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
	if cmdID == CMD_GREYGOO and not wantedUnitDefs[unitDefID] then -- screen against non-grey gooers using area greygoo.
		return false
	else
		return true
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if wantedUnitDefs[unitDefID] then
		spInsertUnitCmdDesc(unitID, CommandOrder, areaGreyGooDesc)
	end
end

function gadget:CommandFallback(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag) -- used for "free" command management since we have a command that isn't an engine command.
	if cmdID ~= CMD_GREYGOO then
		return false, false -- don't care (not ours)
	else
		local data = IterableMap.Get(handled, unitID)
		if data and data.done then
			IterableMap.Remove(handled, unitID)
			return true, true -- we're done with this command.
		elseif not data then
			if #cmdParams == 1 then -- this is a single feature command.
				local id = cmdParams[1]
				if id < Game.maxUnits then
					return true, true -- this is invalid since it's targeting a unit (wtf)
				else
					local id = cmdParams[1] - Game.MaxUnits -- expects: (unitid or Game.maxUnits+featureid) so to get featureID we need to subtract Game.maxUnits.
					cmdParams = id -- we set this to just a number so our gameframe check can differentiate between a single command and an area command.
					if not spValidFeatureID(id) then
						return true, true
					else -- check if this is a good def to target.
						if not featurecache[id] then
							return true, true
						end
					end
				end
			elseif not IsThereEligiableWreckNearby(cmdParams[1], cmdParams[3], cmdParams[4]) then -- there's nothing that we can use in the radius.
				return true, true
			end
			IterableMap.Add(handled, unitID, {def = unitDefID, done = false, params = cmdParams, goal = -9999} -- we found a new unit!
		end
		return true, false -- we're still not done here.
	end
end

function gadget:GameFrame(f)
	if f%5 == 0 then -- 6hz
		for unitID, data in IterableMap.Iterator(handled) do
			if not data.done then -- don't handle things that are done.
				local unitDef = data.def
				local greygooconfig = GooDefs[data.def]
				local currentcmd = spGetUnitCommands(unitID, 1)
				if spValidUnitID(unitID) or #currentcmd == 0 or currentcmd[1].id ~= CMD_GREYGOO then -- safety. first we check if we have any commands, then if we're not doing grey goo anymore.
					IterableMap.Remove(handled, unitID)
				else
					local params = data.params
					local range = greygooconfig.range
					local wantedrange = range * 0.1 -- puts us clearly in range, and gives us bonus targets, potentially.
					if type(params) ~= "table" then -- this is a single command
						if spValidFeatureID(params) then
							if data.goal ~= params then -- we haven't set the move goal yet.
								local x, y, z = spGetFeaturePosition(params) -- find the location of our target.
								spSetUnitMoveGoal(unitID, x, y, z, wantedrange)
								data.goal = params
							end
						else
							data.done = true
						end
					else -- this is an area command.
						if data.goal == -9999 or not spValidFeatureID(data.goal) then -- haven't set a goal yet or our current greygoo task is complete.
							local x, y, z = spGetUnitPosition(unitID)
							local newgoal = IsThereEligiableWreckNearby(x, z, range)
							if newgoal then
								data.goal = newgoal -- set our new goal to a nearby wreck in range (we're still eating something, no sense moving onto other things yet)
							else
								local id = GetClosestWreck(x, z, params[1], params[3], params[4])
								if id then
									local gx, gy, gz = spGetFeaturePosition(id)
									spSetUnitMoveGoal(unitID, gx, gy, gz, wantedrange)
									data.goal = id
								else
									data.done = true
								end
							end
						end
					end
				end
			end
		end
	end
end
