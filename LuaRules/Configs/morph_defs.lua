-- $Id: morph_defs.lua 4643 2009-05-22 05:52:27Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local SUC = Spring.Utilities.CMD
local CMD_MORPH = SUC.MORPH
local CMD_MORPH_STOP = SUC.MORPH_STOP

local morphDefs = {}

--------------------------------------------------------------------------------
-- customparams
--------------------------------------------------------------------------------

for i = 1,#UnitDefs do
	local ud = UnitDefs[i]
	local cp = ud.customParams
	local name = ud.name

	local morphList = (cp.morphto_1 and true) or false
	local index = 1
	local append = (morphList and ("_" .. index)) or ""

	while true do
		local morphTo = cp["morphto" .. append]
		if not morphTo then
			break
		end
		
		local targetDef = UnitDefNames[morphTo]
		morphDefs[name] = morphDefs[name] or {}
		morphDefs[name][#morphDefs[name] + 1] = {
			into = morphTo,
			time = cp["morphtime" .. append] or (cp["level" .. append] and math.floor((targetDef.metalCost - ud.metalCost) / (6 * (cp["level" .. append] + 1)))),	-- or 30,
			metal = tonumber(cp["morphcost" .. append]),
			energy = tonumber(cp["morphcost" .. append]),
			combatMorph = (cp["combatmorph" .. append] == "1"),
		}
		
		if morphList then
			index = index + 1
			append = ("_" .. index)
		else
			break
		end
	end
end

--------------------------------------------------------------------------------
-- basic (non-modular) commander handling
--------------------------------------------------------------------------------
local comms = {"armcom", "corcom", "commrecon", "commsupport", "benzcom", "cremcom"}
local baseComMorph = {
	[0] = {time = 10, cost = 0},
	[1] = {time = 25, cost = 250},
	[2] = {time = 30, cost = 300},
	[3] = {time = 40, cost = 400},
	[4] = {time = 50, cost = 500},
}

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
