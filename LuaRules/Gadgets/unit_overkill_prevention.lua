--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Overkill Prevention",
    desc      = "Prevents some units from firing at units which are going to be killed by incoming missiles.",
    author    = "Google Frog, ivand",
    date      = "14 Jan 2015",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local Echo				= Spring.Echo
local spValidUnitID    = Spring.ValidUnitID
local spSetUnitTarget = Spring.SetUnitTarget
local spGetUnitHealth = Spring.GetUnitHealth
local spGetGameFrame  = Spring.GetGameFrame
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spGetUnitTeam         = Spring.GetUnitTeam
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitPosition		= Spring.GetUnitPosition
local spGetUnitsInCylinder	= Spring.GetUnitsInCylinder
local spGetUnitAllyTeam		= Spring.GetUnitAllyTeam
local spGetUnitShieldState	= Spring.GetUnitShieldState
local spGetUnitIsStunned	= Spring.GetUnitIsStunned
local spGetUnitRulesParam	= Spring.GetUnitRulesParam

local pmap = VFS.Include("LuaRules/Utilities/pmap.lua")

local DECAY_FRAMES = 1200 -- time in frames it takes to decay 100% para to 0 (taken from unit_boolean_disable.lua)

local FAST_SPEED = 5.5*30 -- Speed which is considered fast.
local fastUnitDefs = {}
for i, ud in pairs(UnitDefs) do
	if ud.speed > FAST_SPEED then
		fastUnitDefs[i] = true
	end
end

local canHandleUnit = {}
local units = {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local HandledUnitDefIDs = {
	[UnitDefNames["corrl"].id] = true,
	[UnitDefNames["armcir"].id] = true,
	[UnitDefNames["nsaclash"].id] = true,
	[UnitDefNames["missiletower"].id] = true,
	[UnitDefNames["screamer"].id] = true,
	[UnitDefNames["amphaa"].id] = true,
	[UnitDefNames["puppy"].id] = true,
	[UnitDefNames["fighter"].id] = true,
	[UnitDefNames["hoveraa"].id] = true,
	[UnitDefNames["spideraa"].id] = true,
	[UnitDefNames["vehaa"].id] = true,
	[UnitDefNames["gunshipaa"].id] = true,
	[UnitDefNames["gunshipsupport"].id] = true,
	[UnitDefNames["armsnipe"].id] = true,
	[UnitDefNames["amphraider3"].id] = true,
	[UnitDefNames["subarty"].id] = true,
	[UnitDefNames["subraider"].id] = true,
	[UnitDefNames["corcrash"].id] = true,
	[UnitDefNames["cormist"].id] = true,
	[UnitDefNames["tawf114"].id] = true, --HT's banisher	
	[UnitDefNames["shieldarty"].id] = true, --Shields's racketeer
}

include("LuaRules/Configs/customcmds.h.lua")

local preventOverkillCmdDesc = {
	id      = CMD_PREVENT_OVERKILL,
	type    = CMDTYPE.ICON_MODE,
	name    = "Prevent Overkill.",
	action  = 'preventoverkill',
	tooltip	= 'Enable to prevent units shooting at units which are already going to die.',
	params 	= {0, "Prevent Overkill", "Fire at anything"}
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local incomingDamage = {}

function GG.OverkillPrevention_IsDoomed(targetID)
	return (incomingDamage[targetID] or {}).doomed or false
end

local function Dist3D2(x0,x1,y0,y1,z0,z1)
	return (x1-x0)^2+(y1-y0)^2+(z1-z0)^2
end

local function OverkillPrevention_CheckBlockCommon(unitID, targetID, gameFrame, FullDamage, SingleDamage, DisarmDamage, DisarmTimeout, timeout)
	local incData = incomingDamage[targetID]
	local targetFrame=gameFrame+timeout
	
	local armor = select(2,Spring.GetUnitArmored(targetID)) or 1
	local adjHealth = spGetUnitHealth(targetID)/armor
	
	local disarmFrame = spGetUnitRulesParam(targetID, "disarmframe") or -1
	if disarmFrame==-1 then disarmFrame=gameFrame end --no disarm damage on targetID yet(already)

	local block=false
	
	if incData then --seen this target
		local si, ei = incData.frames:GetIdxs()
		for i=si, ei do
			local frame, data=unpack(incData.frames:GetKV(i))
			--Echo(frame)
			if frame<gameFrame then
				incData.frames:TrimFront() --frames should come in ascending order, so it's safe to trim front of array one by one
			else
				local dd=data.dd
				local fd=data.fd
				
				local disarmExtra=math.floor(dd/adjHealth*DECAY_FRAMES)				
				adjHealth=adjHealth-fd
				disarmFrame=disarmFrame+disarmExtra

				if disarmFrame>frame+DECAY_FRAMES+DisarmTimeout then disarmFrame=frame+DECAY_FRAMES+DisarmTimeout end			
			end
		end
		local doomed=(adjHealth<0) and (FullDamage>0)										--for regular projectile
		local disarmed=(disarmFrame-gameFrame-timeout>=DECAY_FRAMES) and (DisarmDamage>0)	--for disarming projectile
		
		block=doomed or disarmed --assume function is not called with both regular and disarming damage types
		
		incomingDamage[targetID].doomed=doomed
		incomingDamage[targetID].disarmed=disarmed
	else --new target
		incomingDamage[targetID]={ frames=pmap() }
		incomingDamage[targetID].frames:Insert(targetFrame, {fd=FullDamage, sd=SingleDamage, dd=DisarmDamage})
		incData = incomingDamage[targetID]
	end
	
	if not block then	
		local frameData=incData.frames:Get(targetFrame)
		if frameData then --here we have a rare case when few different projectiles (from different attack units) are arriving to the target at the same frame. Their powers must be accumulated/harmonized
			frameData.fd=frameData.fd+FullDamage
			--frameData.sd=math.min(frameData.sd, SingleDamage)
			frameData.sd=frameData.sd+SingleDamage
			frameData.dd=frameData.dd+DisarmDamage			
			incData.frames:Upsert(targetFrame, frameData)
		else --this case is much more common: such frame does not exist in incData.frames
			incData.frames:Insert(targetFrame, {fd=FullDamage, sd=SingleDamage, dd=DisarmDamage})
		end	
	end
	
	if block then
		local teamID = spGetUnitTeam(unitID)
		local unitDefID = CallAsTeam(teamID, spGetUnitDefID, targetID)
		if unitDefID then
			spSetUnitTarget(unitID, 0)
			return true
		end
	end
	
	return false
end


function GG.OverkillPrevention_CheckBlockD(unitID, targetID, damage, timeout, disarmTimer)
	if not units[unitID] then
		return false
	end
	
	if spValidUnitID(unitID) and spValidUnitID(targetID) then
		local gameFrame = spGetGameFrame()
		--OverkillPrevention_CheckBlockCommon(unitID, targetID, gameFrame, FullDamage, SingleDamage, DisarmDamage, DisarmTimeout, timeout)
		return OverkillPrevention_CheckBlockCommon(unitID, targetID, gameFrame, 0, 0, damage, disarmTimer, timeout)
	end
end

function GG.OverkillPrevention_CheckBlock(unitID, targetID, damage, timeout, troubleVsFast)
	if not units[unitID] then
		return false
	end	

	if spValidUnitID(unitID) and spValidUnitID(targetID) then
		local gameFrame = spGetGameFrame()
		if troubleVsFast then
			local unitDefID = Spring.GetUnitDefID(targetID)
			if fastUnitDefs[unitDefID] then
				damage = 0
			end
		end
		
		--OverkillPrevention_CheckBlockCommon(unitID, targetID, gameFrame, FullDamage, SingleDamage, DisarmDamage, DisarmTimeout, timeout)
		return OverkillPrevention_CheckBlockCommon(unitID, targetID, gameFrame, damage, damage, 0, 0, timeout)		
	end
end

function gadget:UnitDestroyed(unitID)
	if incomingDamage[unitID] then
		incomingDamage[unitID] = nil
	end
end

--------------------------------------------------------------------------------
-- Command Handling
local function PreventOverkillToggleCommand(unitID, cmdParams, cmdOptions)
	if canHandleUnit[unitID] then
		local state = cmdParams[1]
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_PREVENT_OVERKILL)
		
		if (cmdDescID) then
			preventOverkillCmdDesc.params[1] = state
			spEditUnitCmdDesc(unitID, cmdDescID, { params = preventOverkillCmdDesc.params})
		end
		if state == 1 then
			if not units[unitID] then
				units[unitID] = true
			end
		else
			if units[unitID] then
				units[unitID] = nil
			end
		end
	end
	
end

function gadget:AllowCommand_GetWantedCommand()	
	return {[CMD_PREVENT_OVERKILL] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()	
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID ~= CMD_PREVENT_OVERKILL) then		
		return true  -- command was not used
	end	
	PreventOverkillToggleCommand(unitID, cmdParams, cmdOptions)  
	return false  -- command was used
end

--------------------------------------------------------------------------------
-- Unit Handling

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if HandledUnitDefIDs[unitDefID] then
		spInsertUnitCmdDesc(unitID, preventOverkillCmdDesc)
		canHandleUnit[unitID] = true
		PreventOverkillToggleCommand(unitID, {1})
	end
end

function gadget:UnitDestroyed(unitID)
	if canHandleUnit[unitID] then
		if units[unitID] then
			units[unitID] = nil
		end
		canHandleUnit[unitID] = nil
	end
end

function gadget:Initialize()
	-- register command
	gadgetHandler:RegisterCMDID(CMD_PREVENT_OVERKILL)
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end