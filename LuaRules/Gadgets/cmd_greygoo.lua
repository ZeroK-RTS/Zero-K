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

include("LuaRules/Configs/customcmds.h.lua")

if (not gadgetHandler:IsSyncedCode()) then
	return
end

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")

local handled = IterableMap.New()
local featurecache = {}
local needLOS = true

local areaGreyGooDesc = {
	id      = CMD_GREYGOO,
	type    = CMDTYPE.ICON_UNIT_FEATURE_OR_AREA,
	name    = 'Grey Goo', -- TODO: better name. Marketing was out today.
	action  = 'greygoo',
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
local spIsPosInLos = Spring.IsPosInLos
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local CommandOrder = 123456
local sqrt = math.sqrt

local validFeatures = {}
local _, GooDefs = VFS.Include("LuaRules/Configs/grey_goo_defs.lua")

for i = 1, #FeatureDefs do
	local fdef = FeatureDefs[i]
	if fdef.customParams and fdef.customParams.fromunit then
		validFeatures[i] = true
	end
end

local function Distance(x1, x2, y1, y2)
	return sqrt(((x2 - x1) * (x2 - x1)) + ((y2 - y1) * (y2 - y1)))
end

local function GetEligiableWrecksInArea(x, z, radius, allyID) -- Looks for wrecks in LOS that are nearby.
	local check = spGetFeaturesInCylinder(x, z, radius)
	local ret = {}
	for i = 1, #check do
		local featureID = check[i]
		if featurecache[featureID] then
			if needLOS then
				local x, y, z = spGetFeaturePosition(featureID)
				if needLOS and spIsPosInLos(x, y, z, allyID) then
					ret[#ret + 1] = featureID
				end
			else
				ret[#ret + 1] = featureID
			end
		end
	end
	return ret
end

local function GetClosestWreck(x, z, cx, cz, radius, ally)
	local wrecks = GetEligiableWrecksInArea(cx, cz, radius, ally)
	if #wrecks == 0 then -- double safety.
		return nil
	end
	local lowestDistance = math.huge
	local lowestID
	for i = 1, #wrecks do
		local id = wrecks[i]
		local x2, y2, z2 = spGetFeaturePosition(id)
		local d = Distance(x, x2, z, z2)
		if d < lowestDistance then
			lowestID = id
			lowestDistance = d
		end
	end
	return lowestID
end

local function IsThereEligiableWreckNearby(x, z, radius, allyteam) -- stupid check. (for when we don't want the closest wreck)
	local check = GetEligiableWrecksInArea(x, z, radius, allyteam)
	return #check > 0 and check[1] or nil
end

function gadget:FeatureCreated(featureID, allyTeamID)
	local featuredef = spGetFeatureDefID(featureID)
	featurecache[featureID] = validFeatures[featuredef]
end

function gadget:FeatureDestroyed(featureID)
	featurecache[featureID] = nil
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
	if cmdID == CMD_GREYGOO then -- screen against bad things
		if not GooDefs[unitDefID] or not (#cmdParams == 1 or #cmdParams == 4) then
			Spring.Echo("Invalid params? " .. tostring(cmdParams[1]) .. ", " .. tostring(cmdParams[2]) .. ", " .. tostring(cmdParams[3]) .. ", " .. tostring(cmdParams[4]))
			return false
		end
	else
		return true
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	if GooDefs[unitDefID] then
		--Spring.Echo("Injecting Command to " .. unitID .. "(Cmd: " .. tostring(CMD_GREYGOO) .. ")")
		spInsertUnitCmdDesc(unitID, CommandOrder, areaGreyGooDesc)
	end
end

function gadget:CommandFallback(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag) -- used for "free" command management since we have a command that isn't an engine command.
	if cmdID ~= CMD_GREYGOO then
		--Spring.Echo("GREYGOO: CMDFALLBACK: bad cmd")
		return false, false -- don't care (not ours)
	else
		local data = IterableMap.Get(handled, unitID)
		if data and data.done then
			--Spring.Echo("GREYGOO: DONE")
			IterableMap.Remove(handled, unitID)
			return true, true -- we're done with this command.
		elseif not data then
			--Spring.Echo("GREYGOO: INITIALIZING with params: " .. tostring(cmdParams[1]) .. ", " .. tostring(cmdParams[2]) .. ", " .. tostring(cmdParams[3]) .. ", " .. tostring(cmdParams[4]))
			local allyteam = spGetUnitAllyTeam(unitID)
			if #cmdParams == 1 then -- this is a single feature command.
				local id = cmdParams[1]
				if id < Game.maxUnits then -- unitID instead of featureID
					return true, true
				end
				id = id - Game.maxUnits
				local valid = spValidFeatureID(id)
				--Spring.Echo("ID: " .. id .. " (Valid: " .. tostring(valid) .. ")")
				if not valid then
					return true, true -- this is invalid since it's targeting a unit (wtf)
				else
					cmdParams = id -- we set this to just a number so our gameframe check can differentiate between a single command and an area command.
					-- Note: We don't need to worry about LOS as I think it won't work out of LOS (returns a map position, probably)
				end
			elseif not IsThereEligiableWreckNearby(cmdParams[1], cmdParams[3], cmdParams[4], allyteam) then -- there's nothing that we can use in the radius.
				--Spring.Echo("GREYGOO: No eligible wrecks nearby")
				return true, true
			end
			local persistent = cmdOptions.alt and #cmdParams > 1
			IterableMap.Add(handled, unitID, {def = unitDefID, done = false, params = cmdParams, goal = -9999, updates = 0, persistent = persistent}) -- we found a new unit!
		end
		return true, false -- we're still not done here.
	end
end

function gadget:GameFrame(f)
	if f%5 == 0 then -- 6hz
		for unitID, data in IterableMap.Iterator(handled) do
			if not data.done then -- don't handle things that are done.
				data.updates = data.updates + 1
				--Spring.Echo("GreyGoo: Update " .. unitID .. ": Goal: " .. data.goal)
				local currentcmd = spGetUnitCommands(unitID, 1)
				if not spValidUnitID(unitID) or #currentcmd == 0 or currentcmd[1].id ~= CMD_GREYGOO then -- safety. first we check if we have any commands, then if we're not doing grey goo anymore.
					--Spring.Echo("Invalid unit or not working")
					IterableMap.Remove(handled, unitID)
				else
					local range = GooDefs[data.def].range
					local wantedrange = range * 0.1 -- puts us clearly in range
					if type(data.params) ~= "table" then -- this is a single command
						local featureID = data.params
						if spValidFeatureID(featureID) then
							if data.goal ~= featureID then -- we haven't set the move goal yet.
								local x, y, z = spGetFeaturePosition(featureID) -- find the location of our target.
								spSetUnitMoveGoal(unitID, x, y, z, wantedrange)
								data.goal = featureID
							end
						else
							data.done = true
						end
					else -- this is an area command.
						local commandRadius = data.params[4]
						local commandX = data.params[1]
						local commandZ = data.params[3]
						local allyTeam = spGetUnitAllyTeam(unitID)
						local x, y, z = spGetUnitPosition(unitID)
						if data.goal == -9999 or not spValidFeatureID(data.goal) then -- haven't set a goal yet or our current greygoo task is complete.
							local id = GetClosestWreck(x, z, commandX, commandZ, commandRadius, allyTeam)
							if id then
								local gx, gy, gz = spGetFeaturePosition(id)
								spSetUnitMoveGoal(unitID, gx, gy, gz, wantedrange)
								data.goal = id
							elseif not data.persistent then
								data.done = true
							end
						elseif data.updates == 3 then -- check if we're within range (fires off every 3rd update, this staggers the check)
							data.updates = 0
							local px, py, pz = spGetFeaturePosition(data.goal)
							if Distance(px, x, pz, z) > range * 0.98 then
								spSetUnitMoveGoal(unitID, px, py, pz, wantedrange) -- we may have been pushed by allies or other grey gooers. prevents softlock.
							end
						end
					end
				end
			end
		end
	end
end

function gadget:Initalize()
	gadgetHandler:RegisterCMDID(CMD_GREYGOO)
	Spring.SetCustomCommandDrawData(CMD_GREYGOO, "Reclaim", {0.8, 0.3, 0.3, 0.7}, true)
	for _, unitID in pairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
	end
end
