-- $Id: morph_defs.lua 4643 2009-05-22 05:52:27Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")

local morphDefs = {

	chicken_drone = {
		[1] = {
			into = 'chickend',
			energy = 15,
			time = 20,
		},
		[2] = {
			into = 'chickenspire',
			energy = 600,
			time = 90,
		},
	},
}

local baseComMorph = {
	[0] = {time = 10, cost = 0},
	[1] = {time = 25, cost = 250},
	[2] = {time = 30, cost = 300},
	[3] = {time = 40, cost = 400},
	[4] = {time = 50, cost = 500},
}

--------------------------------------------------------------------------------
-- customparams
--------------------------------------------------------------------------------
for i=1,#UnitDefs do
	local ud = UnitDefs[i]
	local cp = ud.customParams
	local name = ud.name
	local morphTo = cp.morphto
	if morphTo then
		local targetDef = UnitDefNames[morphTo]
		morphDefs[name] = morphDefs[name] or {}
		morphDefs[name][#morphDefs[name] + 1] = {
			into = morphTo,
			time = cp.morphtime or (cp.level and math.floor((targetDef.metalCost - ud.metalCost) / (6 * (cp.level+1)))),	-- or 30,
			metal = tonumber(cp.morphcost),
			energy = tonumber(cp.morphcost),
			combatMorph = cp.combatmorph == "1",
		}
	end
end

--------------------------------------------------------------------------------
-- basic (non-modular) commander handling
--------------------------------------------------------------------------------
local comms = {"armcom", "corcom", "commrecon", "commsupport", "benzcom", "cremcom"}

for i = 1, #comms do
	for j = 0,4 do
		local source = comms[i] .. j
		local destination = comms[i] .. (j+1)
		morphDefs[source] = {
			into = destination,
			time = baseComMorph[j].time,
			metal = baseComMorph[j].cost,
			energy = baseComMorph[j].cost,
			combatMorph = true,
		}
	end
end


--------------------------------------------------------------------------------
-- modular commander handling
--------------------------------------------------------------------------------
local comMorph = {	-- not needed
	[1] = {time = 20,},
	[2] = {time = 25,},
	[3] = {time = 30,},
	[4] = {time = 35,},
	[5] = {time = 40,},
}

local customComms = {}

local function InitUnsafe()
	if not Spring.GetPlayerList then
		return
	end
	for name, id in pairs(Spring.GetPlayerList()) do	-- pairs(playerIDsByName) do
		-- copied from PlanetWars
		local commData, success
		local customKeys = select(11, Spring.GetPlayerInfo(id))
		local commDataRaw = customKeys and customKeys.commanders
		if not (commDataRaw and type(commDataRaw) == 'string') then
			if commDataRaw then
				err = "Comm data entry for player "..id.." is in invalid format"
			end
			commData = {}
		else
			commDataRaw = string.gsub(commDataRaw, '_', '=')
			commDataRaw = Spring.Utilities.Base64Decode(commDataRaw)
			--Spring.Echo(commDataRaw)
			local commDataFunc, err = loadstring("return "..commDataRaw)
			if commDataFunc then
				success, commData = pcall(commDataFunc)
				if not success then
					err = commData
					commData = {}
				end
			end
		end
		if err then
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, 'Comm Morph warning: ' .. err)
		end

		for series, subdata in pairs(commData) do
			customComms[id] = customComms[id] or {}
			customComms[id][series] = subdata
		end
	end
end

local function CheckForExistingMorph(morphee, target)
	local array = morphDefs[morphee]
	if not array then
		return false
	end
	if array.into then
		return (array.into == target)
	end
	for index,morphOpts in pairs(array) do
		if morphOpts.into and morphOpts.into == target then
			return true
		end
	end
	return false
end

InitUnsafe()
for id, playerData in pairs(customComms) do
	Spring.Echo("Setting morph for custom comms for player: "..id)
	for chassisName, array in pairs(playerData) do
		for i=1,#array do
			--Spring.Echo(array[i], array[i+1])
			local targetDef = array[i+1] and UnitDefNames[array[i+1]]
			local originDef = UnitDefNames[array[i]] or UnitDefNames[array[i]]
			if targetDef and originDef then
				--Spring.Echo("Configuring comm morph: "..(array[i]) , array[i+1])
				local sourceName, targetName = originDef.name, targetDef.name
				local morphCost
				local morphOption = comMorph[i] and Spring.Utilities.CopyTable(comMorph[i], true) or {}
				
				morphOption.into = array[i+1]
				-- set time
				morphOption.time = math.floor( (targetDef.metalCost - originDef.metalCost) / (5 * (i+1)) ) or morphOption.time
				--morphOption.time = math.floor((targetDef.metalCost - originDef.metalCost)/10) or morphOption.time
				--morphOption.time = math.floor(15 + i*5) or morphOption.time
				morphOption.combatMorph = true
				-- copy, checking that this morph isn't already defined
				morphDefs[sourceName] = morphDefs[sourceName]  or {}
				if not CheckForExistingMorph(sourceName, targetName) then
					morphDefs[sourceName][#(morphDefs[sourceName]) + 1] = morphOption
				else
					Spring.Echo("Duplicate morph, exiting")
				end
			end
		end
	end
end

--check that the morphs were actually inserted
--[[
for i,v in pairs(morphDefs) do
	Spring.Echo(i)
	if v.into then Spring.Echo("\t"..v.into)
	else
		for a,b in pairs(v) do Spring.Echo("\t"..b.into) end
	end
end
]]--

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local MAX_MORPH = 0
local UPGRADING_BUILD_SPEED = 250

local function DefCost(paramName, udSrc, udDst)
	local pSrc = udSrc[paramName]
	local pDst = udDst[paramName]
	if (not pSrc) or (not pDst) then
		return 0
	end
	local cost = (pDst - pSrc)
	if (cost < 0) then
		cost = 0
	end
	return math.floor(cost)
end

local function BuildMorphDef(udSrc, morphData)
	local udDst = UnitDefNames[morphData.into]
	if (not udDst) then
		Spring.Log(gadget:GetInfo().name, LOG.WARNING, 'Morph gadget: Bad morph dst type: ' .. morphData.into)
		return
	else
		if (CMD_MORPH + MAX_MORPH >= CMD_MORPH_STOP ) then --reached next custom command ID in the list (see: customcmds.h.lua)
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, 'Morph CMD_ID is overflowing/overlapping with other command.')
		end
		if (CMD_MORPH_STOP + MAX_MORPH >= 2*CMD_MORPH_STOP-CMD_MORPH ) then --reached next custom command ID in the list (see: customcmds.h.lua)
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, 'Morph Stop CMD_ID is overflowing/overlapping with other command.')
		end
		local unitDef = udDst
		local newData = {}
		newData.into = udDst.id
		newData.time = morphData.time or math.floor(unitDef.buildTime*7/UPGRADING_BUILD_SPEED)
		newData.increment = (1 / (30 * newData.time))
		newData.metal = morphData.metal or DefCost('metalCost', udSrc, udDst)
		newData.energy = morphData.energy or DefCost('energyCost', udSrc, udDst)
		newData.combatMorph = morphData.combatMorph or false
		newData.resTable = {
			m = (newData.increment * newData.metal),
			e = (newData.increment * newData.energy)
		}
		newData.facing = morphData.facing
		newData.tooltip = 'Morph ' .. newData.into .. ' ' .. newData.time .. ' ' .. newData.metal

		MAX_MORPH = MAX_MORPH + 1 -- CMD_MORPH is the "generic" morph command. "Specific" morph command start at CMD_MORPH+1
		newData.cmd = CMD_MORPH + MAX_MORPH
		newData.stopCmd = CMD_MORPH_STOP + MAX_MORPH

		if (type(GG.MorphInfo)~="table") then
			GG.MorphInfo = {["CMD_MORPH_BASE_ID"]=CMD_MORPH,["CMD_MORPH_STOP_BASE_ID"]=CMD_MORPH_STOP}
		end
		if (type(GG.MorphInfo[udSrc.id])~="table") then
			GG.MorphInfo[udSrc.id]={}
		end
		GG.MorphInfo[udSrc.id][udDst.id]=newData.cmd
		GG.MorphInfo["MAX_MORPH"] = MAX_MORPH

		newData.texture = morphData.texture
		return newData
	end
end

local function ValidateMorphDefs(mds)
	local newDefs = {}
	for src, morphData in pairs(mds) do
		local udSrc = UnitDefNames[src]
		if (not udSrc) then
			Spring.Log("Morph", LOG.WARNING, 'Morph gadget: Bad morph src type: ' .. src)
		else
			newDefs[udSrc.id] = {}
			if (morphData.into) then
				local morphDef = BuildMorphDef(udSrc, morphData)
				if (morphDef) then
					newDefs[udSrc.id][morphDef.cmd] = morphDef
				end
			else
				for _, morphData in pairs(morphData) do
					local morphDef = BuildMorphDef(udSrc, morphData)
					if (morphDef) then
						newDefs[udSrc.id][morphDef.cmd] = morphDef
					end
				end
			end
		end
	end
	return newDefs
end

return ValidateMorphDefs(morphDefs), MAX_MORPH

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
