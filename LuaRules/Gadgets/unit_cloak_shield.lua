-- $Id: unit_cloak_shield.lua 3605 2008-12-31 08:50:31Z google frog $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_cloak_shield.lua
--  brief:   adds a cloak-shield command to units
--  author:  Dave Rodgers, modified by Evil4Zerggin
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "UnitCloakShield",
		desc      = "Adds a cloak-shield command to units",
		author    = "trepan, modified by Evil4Zerggin",
		date      = "May 02, 2007", --updated on 23 January 2014
		license   = "GNU GPL, v2 or later",
		layer     = 1,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  FIXME: (TODO)
--  - wait for UnitFinished() before allowing cloak_shield?
--  - don't allow state changes during pauses (tied to the above)
--
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")
include("LuaRules/Configs/constants.lua")

local SYNCSTR = "unit_cloak_shield"

--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
--  SYNCED
--------------------------------------------------------------------------------

--
--  speed-ups
--

local GetUnitDefID       = Spring.GetUnitDefID
local GetUnitSeparation  = Spring.GetUnitSeparation
local SetUnitCloak       = Spring.SetUnitCloak

local FindUnitCmdDesc    = Spring.FindUnitCmdDesc
local EditUnitCmdDesc    = Spring.EditUnitCmdDesc

local SetUnitRulesParam  = Spring.SetUnitRulesParam
local GetUnitRulesParam  = Spring.GetUnitRulesParam
local GetUnitAllyTeam    = Spring.GetUnitAllyTeam
local GetUnitPosition    = Spring.GetUnitPosition
local GetUnitsInSphere   = Spring.GetUnitsInSphere
local GetUnitIsStunned   = Spring.GetUnitIsStunned

--------------------------------------------------------------------------------

local cloakShieldDefs = {}
local uncloakableDefs = {}
local radiusOverrideDefs = {}

local cloakShieldUnits = {} -- make it global in Initialize()
local cloakers = {}
local cloakees = {} -- 1 = under cloaker, 2 = finished spending recloak rate
local cloakProgress = {}
local lastAreaCloakTime = {}

local UPDATE_RATE = 6

local cloakShieldCmdDesc = {
	id      = CMD_CLOAK_SHIELD,
	type    = CMDTYPE.ICON_MODE,
	name    = 'CloakShield',
	cursor  = 'CloakShield',  -- add with LuaUI?
	action  = 'cloak_shield',
	tooltip = 'Cloak Shield State: Sets whether the unit is cloaking',
	params  = {'0', 'Cloaker Off', 'Cloaker On' }
}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ValidateCloakShieldDefs(mds)
	local newDefs = {}
	for udName, def in pairs(mds) do
		local ud = UnitDefNames[udName]
		if (not ud) then
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, 'Bad cloakShield unit type: ' .. udName)
		else
			local newData = {}
			newData.draw   = def.draw   or true
			newData.init   = def.init   or false
			newData.level  = def.level  or 2
			newData.delay  = def.delay  or 30
			newData.energy = def.energy or 0
			newData.minrad = def.minrad or 64
			newData.maxrad = def.maxrad or 256
			newData.growRate    = def.growRate   or 256
			newData.shrinkRate  = def.shrinkRate or 256
			newData.recloakRate = def.recloakRate or 750
			newData.selfCloak   = def.selfCloak or false
			newData.decloakDistance  = def.decloakDistance or false
			newData.selfDecloakDistance  = def.selfDecloakDistance or false
			newData.moveSpeedMult  = def.moveSpeedMult or false
			newData.isTransport = (ud.transportCapacity >= 1)
			newDefs[ud.id] = newData
		end
	end

	-- print the table (alphabetically)
--[[
	local sorted = {}
	for n, ud in pairs(UnitDefNames) do table.insert(sorted, {n, ud.id}) end
	table.sort(sorted, function(a,b) return (a[1] < b[1]) end)
	for _, name_id in ipairs(sorted) do
		local nd = newDefs[ name_id[2] ]
		if (nd) then
			print('CloakShield ' .. name_id[1])
			print('  draw   = ' .. tostring(nd.draw))
			print('  init   = ' .. tostring(nd.init))
			print('  delay  = ' .. tostring(nd.delay))
			print('  energy = ' .. tostring(nd.energy))
			print('  minrad = ' .. tostring(nd.minrad))
			print('  maxrad = ' .. tostring(nd.maxrad))
			print('  growRate   = ' .. tostring(nd.growRate))
			print('  shrinkRate = ' .. tostring(nd.shrinkRate))
			print('  selfCloak  = ' .. tostring(nd.selfCloak))
			print('  decloakDistance  = ' .. tostring(nd.decloakDistance))
		end
	end
--]]

	return newDefs
end


local function ValidateUncloakableDefs(unclks)
	local newDefs = {}
	for udName, data in pairs(unclks) do
		local ud = UnitDefNames[udName]
		if (not ud) then
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, 'Bad uncloakable unit type: ' .. udName)
		else
			newDefs[ud.id] = true
		end
	end
	return newDefs
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddCloakShieldCmdDesc(unitID, cloakShieldDef)
	cloakShieldCmdDesc.params[1] = (cloakShieldDef.init and '1') or '0'
	local insertID =
		FindUnitCmdDesc(unitID, CMD.CLOAK)      or
		FindUnitCmdDesc(unitID, CMD.ONOFF)      or
		FindUnitCmdDesc(unitID, CMD.TRAJECTORY) or
		FindUnitCmdDesc(unitID, CMD.REPEAT)     or
		FindUnitCmdDesc(unitID, CMD.MOVE_STATE) or
		FindUnitCmdDesc(unitID, CMD.FIRE_STATE) or
		123456 -- back of the pack
	Spring.InsertUnitCmdDesc(unitID, insertID + 1, cloakShieldCmdDesc)
end


local function AddCloakShieldRulesParam(unitID, state)
	SetUnitRulesParam(unitID, "cloak_shield", state and 2 or 0)
end


local function AddCloakShieldUnit(unitID, cloakShieldDef)
	AddCloakShieldCmdDesc(unitID, cloakShieldDef)
	local data = {
		id      = unitID,
		def     = cloakShieldDef,
		draw    = cloakShieldDef.draw,
		radius  = 0,
		minrad  = cloakShieldDef.minrad,
		maxrad  = cloakShieldDef.maxrad,
		energy  = cloakShieldDef.energy / TEAM_SLOWUPDATE_RATE,
		isTransport = cloakShieldDef.isTransport,
		unitRadius  = Spring.GetUnitRadius(unitID),
		recloakRate = cloakShieldDef.recloakRate * UPDATE_RATE / 30, -- Cloak def is in mass/second
	}
	cloakShieldUnits[unitID] = data

	if (cloakShieldDef.init) then
		data.want = true
		cloakers[unitID] = data
	end

	AddCloakShieldRulesParam(unitID, cloakShieldDef.init)
end

local alliedTrueTable = {allied = true}
local function SetUnitCloakAndParam(unitID, level, decloakDistance, selfCloak)
	local newRadius = decloakDistance
	if level then
		local cannotCloak = GetUnitRulesParam(unitID, "cannotcloak")
		if cannotCloak == 1 then
			SetUnitCloak(unitID, 0, GetUnitRulesParam(unitID, "comm_decloak_distance") or false)
		else
			local changeRadius = true
			if (not selfCloak) and cloakers[unitID] and cloakers[unitID].radius > 0 then
				changeRadius = false
				newRadius = 0
			end
			SetUnitCloak(unitID, level, ((changeRadius and decloakDistance) or GetUnitRulesParam(unitID, "comm_decloak_distance") or false))
		end
	else
		local wantCloak = GetUnitRulesParam(unitID, "wantcloak")
		if wantCloak == 1 then
			local cannotCloak = GetUnitRulesParam(unitID, "cannotcloak")
			if cannotCloak == 1 then
				SetUnitCloak(unitID, 0, GetUnitRulesParam(unitID, "comm_decloak_distance") or false)
			else
				SetUnitCloak(unitID, 1, GetUnitRulesParam(unitID, "comm_decloak_distance") or false)
			end
		else
			SetUnitCloak(unitID, 0, GetUnitRulesParam(unitID, "comm_decloak_distance") or false)
		end
	end
	SetUnitRulesParam(unitID, "areacloaked", (level and 1) or 0, alliedTrueTable)
	SetUnitRulesParam(unitID, "areacloaked_radius", (level and newRadius) or 0, alliedTrueTable)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local isTransportCache = {}
local canBurrowCache = {}
local decloakTimeMultCache = {}

local function IsTransport(udid)
	if not isTransportCache[udid] then
		isTransportCache[udid] = ((UnitDefs[udid].transportCapacity >= 1) and 1) or 0
	end
	return (isTransportCache[udid] == 1)
end

local function CanBurrow(udid)
	if not canBurrowCache[udid] then
		canBurrowCache[udid] = (UnitDefs[udid].customParams.idle_cloak and 1) or 0
	end
	return (canBurrowCache[udid] == 1)
end

local function GetUnitDefCloakTimeMult(udid)
	if not decloakTimeMultCache[udid] then
		decloakTimeMultCache[udid] = 1/UnitDefs[udid].mass -- or build time?
	end
	return decloakTimeMultCache[udid]
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
	-- get the cloakShieldDefs
	cloakShieldDefs, uncloakableDefs, radiusOverrideDefs = include("LuaRules/Configs/cloak_shield_defs.lua")

	if (not cloakShieldDefs) then
		gadgetHandler:RemoveGadget()
		return
	end
	gadgetHandler:RegisterCMDID(CMD_CLOAK_SHIELD)

	cloakShieldDefs = ValidateCloakShieldDefs(cloakShieldDefs)
	uncloakableDefs = ValidateUncloakableDefs(uncloakableDefs)

	-- add the CloakShield command to existing units
	for _,unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end

function gadget:Shutdown()
	for _,unitID in ipairs(Spring.GetAllUnits()) do
		SetUnitCloakAndParam(unitID, false)

		local ud = UnitDefs[GetUnitDefID(unitID)]
		local cmdDescID = FindUnitCmdDesc(unitID, CMD_CLOAK_SHIELD)
		if (cmdDescID) then
			Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end
end

--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	local cloakShieldDef = cloakShieldDefs[unitDefID] or GG.Upgrades_UnitCloakShieldDef(unitID)
	if (not cloakShieldDef) then
		return
	end
	AddCloakShieldUnit(unitID, cloakShieldDef)
end


function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	cloakShieldUnits[unitID] = nil
	cloakers[unitID] = nil
	cloakees[unitID] = nil
end


function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	local _,_,_,_,_,newAllyTeam = Spring.GetTeamInfo(teamID, false)
	local _,_,_,_,_,oldAllyTeam = Spring.GetTeamInfo(oldTeamID, false)
	
	if (newAllyTeam ~= oldAllyTeam) then
		if (cloakShieldUnits[unitID]) then
			cloakShieldUnits[unitID].radius = 0
		end
		cloakers[unitID] = nil
		cloakees[unitID] = nil
		SetUnitCloakAndParam(unitID, false)
		local cmdDescID = FindUnitCmdDesc(unitID, CMD_CLOAK_SHIELD)
		if (cmdDescID) then
			cloakShieldCmdDesc.params[1] = (state and '2') or '0'
			EditUnitCmdDesc(unitID, cmdDescID, { params = cloakShieldCmdDesc.params })
		end
	end
end

--------------------------------------------------------------------------------

local function UpdateCloakees(data, frameNum)
	local unitID    = data.id
	local radius    = data.radius
	local level     = data.def.level
	local selfCloak = data.def.selfCloak
	local selfDecloakDistance = data.def.selfDecloakDistance
	local x, y, z = GetUnitPosition(unitID)
	if (x == nil) then
		return
	end
	if Spring.GetUnitRulesParam(unitID, "cloaker_pos_x") then
		x = Spring.GetUnitRulesParam(unitID, "cloaker_pos_x")
		y = Spring.GetUnitRulesParam(unitID, "cloaker_pos_y")
		z = Spring.GetUnitRulesParam(unitID, "cloaker_pos_z")
	end
	local closeUnits = GetUnitsInSphere(x, y, z, radius)
	if (closeUnits == nil) then
		return
	end

	local closestDistSq = false
	local activeCloakee = false
	local recloakUnit = {}
	local recloakDistSq = {}
	
	local allyTeam = GetUnitAllyTeam(unitID)
	for _,cloakee in ipairs(closeUnits) do
		local udid = GetUnitDefID(cloakee)
		if ((not uncloakableDefs[udid]) and (not GetUnitRulesParam(cloakee, "comm_shield_id")) and (GetUnitAllyTeam(cloakee) == allyTeam)) then
			-- see if it's already cloaked, and skip if so
			if GG.GetCloakedAllowed(cloakee) then
				local personalCloak = CanBurrow(udid) or GG.UnitHasPersonalCloak(cloakee, udid)
				if (not personalCloak) then
					if (lastAreaCloakTime[cloakee] or 0) < frameNum - UPDATE_RATE then
						cloakProgress[cloakee] = 0
					end
					lastAreaCloakTime[cloakee] = frameNum
				end
				if (not personalCloak) and (cloakProgress[cloakee] or 0) < 1 then
					local ux,uy,uz = Spring.GetUnitPosition(cloakee)
					local distSq = (ux-x)*(ux-x)+(uy-y)*(uy-y)+(uz-z)*(uz-z)
					recloakUnit[#recloakUnit + 1] = cloakee
					recloakDistSq[#recloakDistSq + 1] = distSq
					if (not closestDistSq) or (distSq < closestDistSq) then
						closestDistSq = distSq
						activeCloakee = cloakee
					end
					-- cloakees[cloakee] = 1 means that the gadget that allows cloak won't actually let the unit cloak
					-- This is so it counts as "attempting to cloak" for the purpose of drawing the cloak range ring,
					-- and so it gets all the required engine and LUS decloak events (eg on firing)
					cloakees[cloakee] = 0
				else
					-- "check cloakees" actually nulls the table, so need to constantly affirm that our already-cloaked units are cloaked
					cloakees[cloakee] = 1
				end
			else
				cloakProgress[cloakee] = 0
				-- Set the cloakee to being handled, otherwise it won't be set to not cloak if it was not allowed to
				-- cloak when it left the cloaker.
				cloakees[cloakee] = 0
			end
			if (cloakee ~= unitID) then
				--other units
				SetUnitCloakAndParam(cloakee, level, radiusOverrideDefs[udid])
			elseif (selfCloak) then
				--self cloak
				SetUnitCloakAndParam(cloakee, level, selfDecloakDistance, selfDecloakDistance and true)
			end
		end
		-- the GetUnitsInSphere() call uses unit midPos's, which can
		-- differ from the unit's position while being transported.
		-- here we do a direct check to see what units the cloakees are
		-- transporting. this does not fix nested transports
		if IsTransport(udid) then
			local transported = Spring.GetUnitIsTransporting(cloakee)
			if transported ~= nil then
				for _,cloakeeLvl2 in ipairs(transported) do
					local udid2 = GetUnitDefID(cloakeeLvl2)
					if (GetUnitAllyTeam(cloakeeLvl2) == allyTeam) then
						SetUnitCloakAndParam(cloakeeLvl2, 4, radiusOverrideDefs[udid2])
						-- note: this gives perfect cloaking, but is the only level
						-- to work under paralysis
						cloakees[cloakeeLvl2] = 1
					end
				end
			end
		end
	end
	--check if the cloaker is a transport
	if (data.isTransport and (radius >= data.unitRadius)) then
		local transported = Spring.GetUnitIsTransporting(unitID)
		if transported ~= nil then
			for _,cloakee in ipairs(transported) do
				local udid = GetUnitDefID(cloakee)
				if (GetUnitAllyTeam(cloakee) == allyTeam) then
					SetUnitCloakAndParam(cloakee, level, radiusOverrideDefs[udid])
					cloakees[cloakee] = 1
				end
			end
		end
	end

	if activeCloakee then
		-- Spend energy on recloak
		local recloakPower = data.recloakRate * (GG.att_ReloadChange[unitID] or 1)
		while activeCloakee do
			local udid = GetUnitDefID(activeCloakee)
			local costMult = GetUnitDefCloakTimeMult(udid)
			cloakProgress[activeCloakee] = (cloakProgress[activeCloakee] or 0) + recloakPower * costMult
			if cloakProgress[activeCloakee] > 1 then
				-- Spend overflow on next-closest unit
				recloakPower = (cloakProgress[activeCloakee] - 1) / costMult
				cloakProgress[activeCloakee] = 1
				
				local closestDistSq = false
				activeCloakee = false
				local candidateCount = #recloakUnit
				for i = 1, candidateCount do
					local cloakee = recloakUnit[i]
					if (cloakProgress[cloakee] or 0) < 1 and ((not closestDistSq) or (recloakDistSq[i] < closestDistSq)) then
						activeCloakee = cloakee
						closestDistSq = recloakDistSq[i]
					end
				end
			else
				activeCloakee = false
				recloakPower = 0
			end
		end
	end
end

function GG.AreaCloakFinishedCharging(unitID)
	return cloakees[unitID] and (cloakees[unitID] == 1)
end

local function UpdateMoveSpeedMult(unitID, data, enabled)
	if data.moveSpeedMult then
		Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", (enabled and data.moveSpeedMult) or 1)
		GG.UpdateUnitAttributes(unitID)
	end
end

local function GrowRadius(cloaker)
	local r = cloaker.radius
	if r <= 0 then
		UpdateMoveSpeedMult(cloaker.id, cloaker.def, true)
	end
	local maxrad = cloaker.maxrad
	if (r >= maxrad) then
		r = maxrad
		return r
	end
	r = (r * r) + cloaker.def.growRate
	r = math.sqrt(r)
	r = (r >= cloaker.maxrad) and cloaker.maxrad or r
	cloaker.radius = r
	Spring.SetUnitRulesParam(cloaker.id, "cloakerRadius", r)

	if (cloaker.draw) then
		SendToUnsynced(SYNCSTR, cloaker.id, r)
	end
end

local function ShrinkRadius(cloaker)
	local r = cloaker.radius
	if (r <= 0) then
		cloaker.radius = 0
		UpdateMoveSpeedMult(cloaker.id, cloaker.def, false)
		return 0
	end
	r = (r * r) - cloaker.def.shrinkRate
	r = (r < 0) and 0 or math.sqrt(r)
	cloaker.radius = r
	Spring.SetUnitRulesParam(cloaker.id, "cloakerRadius", r)
	if (cloaker.draw) then
		SendToUnsynced(SYNCSTR, cloaker.id, r)
	end
	if ((r <= 0) and (not cloaker.want)) then
		cloakers[cloaker.id] = nil
		UpdateMoveSpeedMult(cloaker.id, cloaker.def, false)
	end
end

function gadget:GameFrame(frameNum)
	local checkCloakees = ((frameNum % UPDATE_RATE) < 1)
	if (checkCloakees) then
		for uid in pairs(cloakees) do
			SetUnitCloakAndParam(uid, false)
		end
		cloakees = {}
	end

	for unitID, data in pairs(cloakers) do
		if (data.delay) then
			data.delay = data.delay - 1
			if (data.delay <= 0) then
				data.delay = nil
			end
			ShrinkRadius(data)
		elseif (GetUnitIsStunned(unitID) or (Spring.GetUnitRulesParam(unitID, "disarmed") == 1) or (Spring.GetUnitRulesParam(unitID, "morphDisable") == 1)) then
			ShrinkRadius(data)
		elseif (not data.want) then
			ShrinkRadius(data)
		else
			local newState = Spring.Utilities.GetUnitActiveState(unitID) and (GetUnitRulesParam(unitID, "forcedOff") ~= 1)
			if (newState) then
				GrowRadius(data)
			else
				ShrinkRadius(data)
			end
			
			if (data.active ~= newState) then
				data.active = newState
				if (newState) then
					SetUnitRulesParam(unitID, "cloak_shield", 2)
				else
					SetUnitRulesParam(unitID, "cloak_shield", 1)
					data.delay = data.def.delay
				end
			end
		end

		if (checkCloakees and (data.radius > 0)) then
			UpdateCloakees(data, frameNum)
		end
	end
end

function CloakShieldCommand(unitID, cmdParams)
	if (type(cmdParams[1]) ~= 'number') then
		return false
	end
	local data = cloakShieldUnits[unitID]
	if (not data) then
		return false
	end

	if data.maxrad < 300 and not cmdParams[2] then
		local teamID = Spring.GetUnitTeam(unitID)
		if not teamID then
			return
		end
		local _, _, _, isAiTeam = Spring.GetTeamInfo(teamID)
		if isAiTeam then
			return false
		end
	end

	local state = (cmdParams[1] == 1)
	if (state) then
		cloakers[unitID] = data
		data.want = true
		SetUnitRulesParam(unitID, "cloak_shield", 2)
	else
		data.want = false
		SetUnitRulesParam(unitID, "cloak_shield", 0)
	end

	local cmdDescID = FindUnitCmdDesc(unitID, CMD_CLOAK_SHIELD)
	if (cmdDescID) then
		cloakShieldCmdDesc.params[1] = (state and '1') or '0'
		EditUnitCmdDesc(unitID, cmdDescID, { params = cloakShieldCmdDesc.params })
	end
end


function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_CLOAK_SHIELD] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID ~= CMD_CLOAK_SHIELD) then
		return true  -- command was not used
	end
	CloakShieldCommand(unitID, cmdParams)
	return false  -- command was used
end


function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID ~= CMD_CLOAK_SHIELD) then
		return false  -- command was not used
	end
	CloakShieldCommand(unitID, cmdParams)
	return true, true  -- command was used, remove it
end


--------------------------------------------------------------------------------
--  SYNCED
--------------------------------------------------------------------------------
else
--------------------------------------------------------------------------------
--  UNSYNCED
--------------------------------------------------------------------------------

--
-- speed-ups
--

local GetUnitTeam         = Spring.GetUnitTeam
local GetUnitRadius       = Spring.GetUnitRadius
local GetUnitHeading      = Spring.GetUnitHeading
local GetUnitViewPosition = Spring.GetUnitViewPosition

local GetGameFrame        = Spring.GetGameFrame
local GetFrameTimeOffset  = Spring.GetFrameTimeOffset

local glPushMatrix = gl.PushMatrix
local glPopMatrix  = gl.PopMatrix
local glTranslate  = gl.Translate
local glRotate     = gl.Rotate
local glScale      = gl.Scale
local glCallList    = gl.CallList


--------------------------------------------------------------------------------

local sphereDivs = 16
local sphereArcs = 32

local drawUnits = {}

local sphereList = 0
local negSphereList = 0

local setupMatList  = 0
local resetMatList  = 0
local backMatList   = 0
local frontMatList  = 0
local atiFixMatList = 0

local shieldList = 0

local miniMapXformList = 0

local trans = {0.1, 0.28, 0.60 }


--------------------------------------------------------------------------------

local function SphereVertex(x, y, z, neg)
	if (neg) then
		gl.Normal(-x, -y, -z)
	else
		gl.Normal(x, y, z)
	end
	gl.Vertex(x, y, z)
end


local function DrawSphere(divs, arcs, neg)
	local cos = math.cos
	local sin = math.sin
	local twoPI = (2.0 * math.pi)
	local divRads = math.pi / divs
	local minRad = sin(divRads)

	-- sides
	for d = 4, (divs - 2) do
		
	if (d < 7) then
		gl.Material({
			ambient  = { 0, 0, 0 },
			diffuse  = { 0, 0, 0, trans[d-3]},
			emission = { 0.05, 0.10, 0.15 },
			specular = { 0.25, 0.75, 1 },
			shininess = 4
		})
	elseif (d > 10) then
		gl.Material({
			ambient  = { 0, 0, 0 },
			diffuse  = { 0, 0, 0, trans[15-d]},
			emission = { 0.05, 0.10, 0.15 },
			specular = { 0.25, 0.75, 1 },
			shininess = 4
		})
	else
		gl.Material({
			ambient  = { 0, 0, 0 },
			diffuse  = { 0, 0, 0, 1.0 },
			emission = { 0.05, 0.10, 0.15 },
			specular = { 0.25, 0.75, 1.0 },
			shininess = 4
		})
	end
	
	gl.BeginEnd(GL.QUAD_STRIP, function()
			local topRads = divRads * (d + 0)
			local botRads = divRads * (d + 1)
			local top = cos(topRads)
			local bot = cos(botRads)
			local topRad = sin(topRads)
			local botRad = sin(botRads)
		
			for i = 0, arcs do
				local a = i * (2.0 * math.pi) / arcs
				SphereVertex(sin(a) * topRad, top, cos(a) * topRad, neg)
				SphereVertex(sin(a) * botRad, bot, cos(a) * botRad, neg)
			end
		end)
	end
	
	-- bottom
	gl.BeginEnd(GL.TRIANGLE_FAN, function()
		SphereVertex(0, -1, 0, neg)
		for i = 0, arcs do
			local a = -i * (2.0 * math.pi) / arcs
			SphereVertex(sin(a) * minRad, -cos(divRads), cos(a) * minRad, neg)
		end
	end)
	gl.Material({
	ambient  = { 0, 0, 0 },
	diffuse  = { 0, 0, 0, 0.5 },
	emission = { 0.05, 0.10, 0.15 },
	specular = { 0.25, 0.75, 1.0 },
	shininess = 4
	})
	-- lines
	gl.LineWidth(2.0)
	gl.BeginEnd(GL.LINES, function()
		SphereVertex( 1,  0,  0); SphereVertex(-1,  0,  0)
		SphereVertex(0,   1,  0); SphereVertex(0,  -1,  0)
		SphereVertex(0,   0,  1); SphereVertex(0,   0, -1)
	end)
	gl.LineWidth(1.0)

	-- points
	-- FIXME ATIBUG gl.PointSize(10.0)
	--[[gl.BeginEnd(GL.POINTS, function()
		SphereVertex( 1,  0,  0)
		SphereVertex(-1,  0,  0)
		SphereVertex(0,   1,  0)
		SphereVertex(0,  -1,  0)
		SphereVertex(0,   0,  1)
		SphereVertex(0,   0, -1)
	end)--]]
	-- FIXME ATIBUG gl.PointSize(1.0)
end


--------------------------------------------------------------------------------

local function SetupMaterial()
	gl.Color(0.1, 0.2, 0.3, 0.3)
	gl.Blending(GL.SRC_ALPHA, GL.ONE)
	gl.DepthTest(true)
	gl.Lighting(true)
	gl.ShadeModel(GL.FLAT)
	gl.Fog(false)
	gl.ClipPlane(1, 0, 1, 0, 0) -- invisible in water
end


local function ResetMaterial()
	gl.ShadeModel(GL.SMOOTH)
	gl.Lighting(false)
	gl.DepthTest(false)
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.Fog(true)
	gl.ClipPlane(1, false) -- invisible in water
	gl.Color(1,1,1,1)
end

local function BackMaterial()
	gl.Material({
		ambient  = { 0, 0, 0 },
		diffuse  = { 0, 0, 0, 0.5 },
		emission = { 0.05, 0.10, 0.15 },
		specular = { 0.25, 0.75, 1.0 },
		shininess = 4
	})
end

local function FrontMaterial()
	gl.Material({
		ambient  = { 0, 0, 0 },
		diffuse  = { 0, 0, 0, 0.75 },
		emission = { 0.05, 0.10, 0.15 },
		specular = { 0.25, 0.75, 1.0 },
		shininess = 4
	})
end

local function AtiBugFixMaterial()
	gl.Material({
		ambient  = { 0, 0, 0 },
		diffuse  = { 0, 0, 0, 0 },
		emission = { 0, 0, 0 },
		specular = { 0, 0, 0 },
		shininess = 0
	})
end

local function ShieldList()
	gl.Culling(GL.FRONT)
	gl.CallList(backMatList)
	glCallList(negSphereList)

	gl.Culling(GL.BACK)
	gl.CallList(frontMatList)
	glCallList(sphereList)

	gl.Culling(false)
end


local function MiniMapXform()
	local mapX = Game.mapX * 512
	local mapY = Game.mapY * 512
	-- this will probably be a common display
	-- list for widgets that use DrawInMiniMap()
	gl.LoadIdentity()
	gl.Translate(0, 1, 0)
	gl.Scale(1 / mapX, 1 / mapY, 1)
	gl.Rotate(90, 1, 0, 0)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--[[
local function getAlpha()
	local frame = GetGameFrame() + GetFrameTimeOffset()
	local alpha = (math.abs((frame % 128) - 64) / 64)
	if (alpha < 0.5) then alpha = 0.5 end
	return alpha
end
]]--

local function DrawShield(unitID, radius, degrees)
	local x, y, z = GetUnitViewPosition(unitID, true)
	if (x == nil) then
		return
	end
	local ux, uy, uz
	if Spring.GetUnitRulesParam(unitID, "cloaker_pos_x") then
		ux, uy, uz = x, y, z
		x = Spring.GetUnitRulesParam(unitID, "cloaker_pos_x")
		y = Spring.GetUnitRulesParam(unitID, "cloaker_pos_y")
		z = Spring.GetUnitRulesParam(unitID, "cloaker_pos_z")
	end
	
	if (not Spring.IsSphereInView(x, y, z, math.abs(radius))) then
		return
	end
	
	glPushMatrix()

	glTranslate(x, y, z)
	glScale(radius, radius, radius)
	glRotate(degrees, 0, 1, 0)

	glCallList(shieldList)

	glPopMatrix()
	
	if ux then
		gl.Material({
			ambient  = { 0, 0, 0 },
			diffuse  = { 0, 0, 0, 0.5 },
			emission = { 0.15, 0.20, 0.25 },
			specular = { 0.25, 0.75, 1.0 },
			shininess = 4
		})
		gl.LineWidth(2.0)
		gl.BeginEnd(GL.LINES, function()
			gl.Vertex(ux, uy, uz)
			gl.Vertex(x, y, z)
		end)
	end
end

local GetSpectatingState  = Spring.GetSpectatingState
local GetLocalAllyTeamID  = Spring.GetLocalAllyTeamID
local IsUnitSelected      = Spring.IsUnitSelected
local GetUnitAllyTeam     = Spring.GetUnitAllyTeam
local DrawGroundCircle    = gl.DrawGroundCircle

function gadget:DrawWorld()
	if (not next(drawUnits)) then
		return
	end

	local dt = GetFrameTimeOffset()
	local frame = GetGameFrame() + GetFrameTimeOffset()
	local degrees = frame % (360 * 2 * 3 * 5)
	
	local readAllyTeam = GetLocalAllyTeamID()
	local _, fullView = GetSpectatingState()

	glCallList(setupMatList)

	for unitID, radius in pairs(drawUnits) do
		if (fullView or (GetUnitAllyTeam(unitID) == readAllyTeam)) then
			DrawShield(unitID, radius, degrees + unitID * 57)
		end
	end

	glCallList(resetMatList)
	gl.Material({
		ambient  = { 0, 0, 0 },
		diffuse  = { 0, 0, 0, 0 },
		emission = { 0, 0, 0 },
		specular = { 0, 0, 0 },
		shininess = 0
	})
	--gl.CallList(atiFixMatList)
end


function gadget:DrawInMiniMap()
	if (not next(drawUnits)) then
		return
	end

	gl.PushMatrix()
	glCallList(miniMapXformList)

	local readAllyTeam = GetLocalAllyTeamID()
	local _, fullView = GetSpectatingState()

	for unitID, radius in pairs(drawUnits) do
		if (IsUnitSelected(unitID)) then
			local x, y, z = GetUnitViewPosition(unitID, true)
			if (x ~= nil) then
				if Spring.GetUnitRulesParam(unitID, "cloaker_pos_x") then
					x = Spring.GetUnitRulesParam(unitID, "cloaker_pos_x")
					y = Spring.GetUnitRulesParam(unitID, "cloaker_pos_y")
					z = Spring.GetUnitRulesParam(unitID, "cloaker_pos_z")
				end
				if (fullView or (GetUnitAllyTeam(unitID) == readAllyTeam)) then
					DrawGroundCircle(x, y, z, radius, 64)
				end
			end
		end
	end

	gl.PopMatrix()
end

function gadget:UpdateFIXME() -- testing "cloak_shield" RulesParam
	for _,unitID in ipairs(Spring.GetSelectedUnits()) do
		print(unitID, Spring.GetUnitRulesParam(unitID, "cloak_shield"))
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UnitUpdate(cmd, unitID, radius)
	if (radius <= 0) then
		drawUnits[unitID] = nil
	else
		drawUnits[unitID] = radius
	end
end

function gadget:UnitDestroyed(unitID)
	UnitUpdate(0, unitID, 0)
end

function gadget:Taken(unitID)
	UnitUpdate(0, unitID, 0)
end

function gadget:Initialize()
	gadgetHandler:AddSyncAction(SYNCSTR, UnitUpdate)
	sphereList    = gl.CreateList(DrawSphere, sphereDivs, sphereArcs, false)
	negSphereList = gl.CreateList(DrawSphere, sphereDivs, sphereArcs, true)
	setupMatList  = gl.CreateList(SetupMaterial)
	resetMatList  = gl.CreateList(ResetMaterial)
	backMatList   = gl.CreateList(BackMaterial)
	frontMatList  = gl.CreateList(FrontMaterial)
	atiFixMatList = gl.CreateList(AtiBugFixMaterial)
	shieldList    = gl.CreateList(ShieldList)
	miniMapXformList = gl.CreateList(MiniMapXform)
end


function gadget:Shutdown()
	gl.DeleteList(sphereList)
	gl.DeleteList(negSphereList)
	gl.DeleteList(setupMatList)
	gl.DeleteList(resetMatList)
	gl.DeleteList(backMatList)
	gl.DeleteList(frontMatList)
	gl.DeleteList(shieldList)
	gl.DeleteList(miniMapXformList)
end


--------------------------------------------------------------------------------
--  UNSYNCED
--------------------------------------------------------------------------------
end
--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------
