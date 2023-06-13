
function widget:GetInfo()
	return {
		name      = "Bomber Fog Chase",
		desc      = "Adds several features to Likho, Raven, Phoenix and Thunderbird:\n1. If an attacked unit becomes cloaked, bombers will hit its presumptive location (accounting for last seen position and velocity)\n2. Submerged units can be targeted, the water surface above the target will be hit, accounting for units speed. Raven may hit fast submerged units like Seawolf.\n3. If a targeted unit got destroyed by something else, and there was not a queued command, the bomber will return to air factory or airpad, to avoid dangerous circling at the frontline.\n4. In contrast to 'Smart Bombers' widget (which should be disabled to use this one), this widget not only temporarily turns on the 'Free Fire' state when Attack Move is issued, but also discards the Attack Move command after firing. Thus the Attack Move becomes one-time action rather than a kind of a state.",
		author    = "rollmops",
		date      = "2022",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = false  --  loaded by default
	}
end

--------------------------------------------------------------------------------
-- Speedups
--------------------------------------------------------------------------------

local sqrt = math.sqrt

local spGetUnitPosition         = Spring.GetUnitPosition
local spGiveOrderToUnit         = Spring.GiveOrderToUnit
local spGetTeamUnits            = Spring.GetTeamUnits
local spGetUnitDefID            = Spring.GetUnitDefID
local spEcho                    = Spring.Echo
local spGetUnitCommands         = Spring.GetUnitCommands
local spGetUnitVelocity         = Spring.GetUnitVelocity
local spGetUnitHealth           = Spring.GetUnitHealth
local spGetSpecState            = Spring.GetSpectatingState
local spIsUnitInLos             = Spring.IsUnitInLos
local spGetUnitTeam             = Spring.GetUnitTeam
local spValidUnitID				= Spring.ValidUnitID
local spGetGameFrame			= Spring.GetGameFrame

local CMD_FORCE_FIRE            = CMD.ATTACK -- same number (20) as LOOPBACKATTACK
local CMD_REMOVE                = CMD.REMOVE
local CMD_INSERT                = CMD.INSERT
local CMD_OPT_ALT               = CMD.OPT_ALT
local CMD_STOP                  = CMD.STOP
local CMD_OPT_INTERNAL          = CMD.OPT_INTERNAL
local CMD_OPT_SHIFT             = CMD.OPT_SHIFT
local CMD_ATTACK_MOVE           = CMD.FIGHT
local CMD_FIRE_STATE            = CMD.FIRE_STATE
local CMD_FIRESTATE_HOLDFIRE    = CMD.FIRESTATE_HOLDFIRE
local CMD_FIRESTATE_FIREATWILL  = CMD.FIRESTATE_FIREATWILL

local customCmds                = VFS.Include("LuaRules/Configs/customcmds.lua")
local CMD_REARM                 = customCmds.REARM    -- 33410
local CMD_RAW_MOVE              = customCmds.RAW_MOVE -- 31109

--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

local gameFramesInterval = 8

local debug = false     -- see Echo()

local bombersDefID = { -- The four managed bombers types. Projectile speed adjusted manually.
	[UnitDefNames.bomberheavy.id ] = {name = UnitDefNames.bomberheavy.humanName,  projectileSpeed = 12.5, },
	[UnitDefNames.bomberdisarm.id] = {name = UnitDefNames.bomberdisarm.humanName, projectileSpeed = 100,},
	[UnitDefNames.bomberriot.id  ] = {name = UnitDefNames.bomberriot.humanName,   projectileSpeed = 9,  },
	[UnitDefNames.bomberprec.id  ] = {name = UnitDefNames.bomberprec.humanName,   projectileSpeed = 5.5,},
}

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

local myTeamID          = Spring.GetMyTeamID()
local myAllyTeamID      = Spring.GetMyAllyTeamID()

local airpadDefID       = UnitDefNames.staticrearm.id
local airFactoryDefID   = UnitDefNames.factoryplane.id
local airPalteDefID     = UnitDefNames.plateplane.id

--------------------------------------------------------------------------------
-- Globals
--------------------------------------------------------------------------------

local bombers = {}  -- Bomber Class Objects, per bomber

local targets = {}
-- Targeted units. Several bombers could have the same target, so targets' data resides in this table:
-- [unitID] -> { inLos=bool, inRadar=bool, inWater=bool, lastKnownPos={x,y,z}, vel={x,y,z,speed}, lastSeen=gameFrame }
-- inLos updated by UnitEnteredLos/UnitLeftLos
-- inRadar updated by UnitEnteredRadar/UnitLeftRadar
-- inWater, lastKnownPos, vel(ocity), and lastSeen updated repeatedly in GameFrame() while target is in LoS,
-- that's because, while position can be obtained in UnitLeftLos(), velocity cannot, so
-- for data consistency, all are obtained in GameFrame().

-- following are own only, not allied; used as a destination to return if the target gone and there are no queued commands.
local airpads   = {}    -- [unitID] -> {x,y,z} (position)
local airFacs   = {}    -- [unitID] -> {x,y,z}
local airPlates = {}    -- [unitID] -> {x,y,z}

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

local function Echo(...)
	-- if 'debug' (defined in Config section) is true,
	-- accepts any number of arguments, concatenates them to a space-delimited string, then spEcho() it.
	if not debug then
		return
	end

	local msg = "NGB:"	-- original widget name is too long
	--local msg = widgetName..":"

	for _, s in pairs{...} do
		msg = msg .. " " .. tostring(s)
	end
	spEcho(msg)
end

local function GetHumanName(unitID)
	return spGetUnitDefID(unitID) and UnitDefs[spGetUnitDefID(unitID)] and UnitDefs[spGetUnitDefID(unitID)].humanName or "noname"
end

local function GetAimPosition(unitID)
	local _,_,_, x, y, z = spGetUnitPosition(unitID, false, true) -- last 2 args: bool return midPos , bool return aimPos
	return {x = x, y = y, z = z}
end

local function DiscardOrphanedTargets()
	-- remove target objects which no bomber has them anymore as the target (current or queued)
	for targetID in pairs(targets) do
		local orphaned = true
		for _, bomber in pairs(bombers) do
			if bomber.target == targetID then
				orphaned = false
				break
			end
			for _, cmd in pairs(bomber.queue) do
				if cmd.target == targetID then
					orphaned = false
					break
				end
			end
		end
		if orphaned then
			targets[targetID] = nil
			--Echo("orphaned target discarded")
		end
	end
end

local function BombersHitTargetPosition(targetID, targetPos)
	for _, bomber in pairs(bombers) do
		if bomber.target == targetID then
			bomber:HitTargetPosition({x=targetPos.x, y=targetPos.y, z=targetPos.z})
		end
	end
end

local function BombersHitTargetID(targetID)
	for _, bomber in pairs(bombers) do
		if bomber.target == targetID then
			spGiveOrderToUnit(bomber.id, CMD_FORCE_FIRE, targetID, CMD_OPT_INTERNAL)
		end
	end
end

local function TargetIsGone(targetID)
	-- called when target is destroyed by something else, or never been in LoS and left radar
	--Echo("Target is gone", targetID)
	for _, bomber in pairs(bombers) do
		if bomber.target == targetID then
			bomber.target = nil
			spGiveOrderToUnit(bomber.id, CMD_REMOVE, CMD_FORCE_FIRE, CMD_OPT_ALT)
			bomber:RestoreQueuedCmds(false) -- arg is needRearm
		else
			for k, cmd in pairs(bomber.queue) do
				if cmd.target == targetID then
					table.remove(bomber.queue, k)
					-- shifts the queue up, in contrast to 'bomber.queue[k]=nil' which makes a hole.
				end
			end
		end
	end
	targets[targetID] = nil
end

-- to debug "Bad command from..." messages in log; see AllowCommandParams in gadgets.lua which issues these msgs.
--local SIZE_LIMIT = 10^8
--local function CheckCommandParams(cmdParams)
--	for i = 1, #cmdParams do
--		if (not cmdParams[i]) or cmdParams[i] ~= cmdParams[i] or cmdParams[i] < -SIZE_LIMIT or cmdParams[i] > SIZE_LIMIT then
--			Echo("Bad command: i=",i,"param=",cmdParams[i])
--		end
--	end
--end
--local function DebugGiveOrder(...)
--	CheckCommandParams(select(3, ...))
--	spGiveOrderToUnit(...)
--end

--------------------------------------------------------------------------------
-- Bomber Class and its Methods
--------------------------------------------------------------------------------

local bomberClass = {id, defid, name, weaponSpeed, attackMove, pos = {}, queue = {}, target}

function bomberClass:New(unitID, unitDefID)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.id            = unitID
	o.defid         = unitDefID or spGetUnitDefID(unitID)
	o.name          = bombersDefID[o.defid].name
	o.weaponSpeed   = bombersDefID[o.defid].projectileSpeed
	o.attackMove    = false
	o.pos = {}
	o.queue = {}    -- Keeps commands added with SHIFT. [n] -> {cmdID, params={}, target=unitID/nil}
	                -- Commands added by UnitCommand, removed (restored) by RestoreQueuedCmds
	--Echo("added:", o.id, o.name)
	return o
end

function bomberClass:HitTargetPosition(targetPos)
	-- For cloaked and submerged targets, hit their position with "Force Fire Point".
	-- Approximating ballistic trajectory with constant speed trajectory, see:
	-- https://playtechs.blogspot.com/2007/04/aiming-at-moving-target.html

	if not (targetPos and targets[self.target].vel) then
		return
	end

	x, y, z = spGetUnitPosition(self.id)

	-- relative position of the target (in relation to bomber's position)
	local px = targetPos.x - x
	local py = targetPos.y - y
	local pz = targetPos.z - z

	-- original algorithm uses relative velocity,
	-- but it seems bombers' weapons speed doesn't depend on bomber's speed,
	-- hence using target's absolute velocity.
	local vx = targets[self.target].vel.x
	local vy = targets[self.target].vel.y
	local vz = targets[self.target].vel.z

	local a = self.weaponSpeed * self.weaponSpeed - targets[self.target].vel.speed * targets[self.target].vel.speed
	if a < 0.01 then
		-- should not happen as weapon speed > target speed
		return
	end
	local b = px * vx + py * vy + pz * vz
	local c = px * px + py * py + pz * pz
	local d = b * b + a * c
	if d >= 0 then
		local t = (b + sqrt(d)) / a
		--local t2 = (b - sqrt(d)) / a
		--if t2 > 0 then Echo("T2 POSITIVE: t=", t, "t2 = ", t2) end    -- should not happen
		local aimX = targetPos.x + vx * t
		local aimY = targetPos.y + vy * t
		local aimZ = targetPos.z + vz * t
		spGiveOrderToUnit(self.id, CMD_FORCE_FIRE, {aimX, aimY, aimZ }, CMD_OPT_INTERNAL)
	else
		--Echo ("d is negative")  -- should not happen
	end
end

function bomberClass:RestoreQueuedCmds(needRearm)
	-- Since for submerged and cloaked units the widget repeatedly issues Force Fire To Point command,
	-- the player's commands added with SHIFT are kept in bomber.queue and are restored when the target is hit or destroyed.
	-- Queue is FIFO (commands are pushed to the end of it in UnitCommand, here they are popped from the beginning).
	-- Arg needRearm is bool, to know whether rearm is needed, so to restore only move commands or fight commands too.
	
	--Echo("Restoring queue for",self.id)
	local cmd = table.remove(self.queue, 1)

	if not cmd then
		--Echo("no cmd in queue")
		if not needRearm then	-- if needs rearm, it will get rearm command in GameFrame
			--Echo("Fly to Base", self.id)
			local padPos = airpads[next(airpads)] or airFacs[next(airFacs)] or airPlates[next(airPlates)]
			if padPos then
				spGiveOrderToUnit(self.id, CMD_RAW_MOVE, padPos, CMD_OPT_INTERNAL)
			end
		end
		return
	end

	if cmd.target then
		if needRearm then
			-- can't fire, need rearm; try to find non-FFU cmd such as Move
			DiscardOrphanedTargets()	-- may be only this bomber has cmd.target
			self:RestoreQueuedCmds(needRearm) -- try next command as first (recursion!)
			return
		end
		self.target = cmd.target
		--Echo("queued target restored:", GetHumanName(cmd.target), cmd.target, "for", self.id)
		if targets[cmd.target].inRadar then
			local pos = GetAimPosition(cmd.target)
			if pos and pos.y and pos.y >= 0 then  -- if y<0 (submerged), will get commands from GameFrame
				spGiveOrderToUnit(self.id, CMD_FORCE_FIRE, cmd.target, CMD_OPT_INTERNAL)
			end
		elseif targets[cmd.target].lastKnownPos then
			self:HitTargetPosition(targets[cmd.target].lastKnownPos) -- will continue to get adjusted commands from GameFrame()
		else
			TargetIsGone(unitID)	-- not in radar and we have no data about it
			self:RestoreQueuedCmds(needRearm) -- try next command as first (recursion!)
		end
		return -- if queued cmds are MOVE, can continue to give orders, but for Force Fire Unit need to break, keeping the rest of the queue
	else
		--Echo("First cmd in queue restored",cmd.cmdID,"for",self.id)
		spGiveOrderToUnit(self.id, cmd.cmdID, cmd.params, CMD_OPT_INTERNAL)
	end

	while #self.queue > 0 do    -- rest of the commands are added with shift
		local cmd = table.remove(self.queue, 1)
		if cmd.target then
			self.queue = nil    -- Force Fire Unit should not be queued after Move command(s)
			return
		else
			--Echo("Next cmd in queue restored",cmd.cmdID,"for",self.id)
			spGiveOrderToUnit(self.id, cmd.cmdID, cmd.params, CMD_OPT_SHIFT+CMD_OPT_INTERNAL)
		end
	end
end


--------------------------------------------------------------------------------
-- Callins
--------------------------------------------------------------------------------

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag)
	if not bombers[unitID] then
		return
	end
	--Echo("UC:",CMD[cmdID],cmdID,"p1=",cmdParams[1],"p2=",cmdParams[2],"p3=",cmdParams[3],"p4=",cmdParams[4],"shift=",cmdOpts.shift,"internal=",cmdOpts.internal,"alt=",cmdOpts.alt)

	-- Catching player-issued commands.
	-- Placed here and not in CommandNotify as to also catch commands issued as a result of ForceFire+drag
	if not (cmdID==CMD_INSERT or cmdID==CMD_REMOVE or cmdID==CMD_FIRE_STATE or cmdOpts.internal) then

		-- if targetID is not nil, then targetID is unitID targeted by the bomber (may be a radar point as well)
		local targetID = cmdID==CMD_FORCE_FIRE and cmdParams and #cmdParams==1 and spValidUnitID(cmdParams[1]) and cmdParams[1]

		if targetID and not targets[targetID] then
			targets[targetID] = {inRadar = true, inLos = spIsUnitInLos(targetID, myAllyTeamID)}
			--Echo(cmdOpts.shift and "queued" or "", "target added:", GetHumanName(targetID), cmdParams[1], "for", unitID)
		end

		if not cmdOpts.shift then
			if cmdID~=CMD_FORCE_FIRE then
				spGiveOrderToUnit(unitID, CMD_REMOVE, CMD_FORCE_FIRE, CMD_OPT_ALT)
				--CMD_OPT_ALT means "use the parameters as commandIDs, not as tags"
			end
			bombers[unitID].target = targetID
			bombers[unitID].queue = {}
			DiscardOrphanedTargets()
		else
			--Echo("Queued cmd",cmdID,"added for",unitID)
			bombers[unitID].queue[#bombers[unitID].queue+1] = {cmdID = cmdID, params = cmdParams, target = targetID}
		end

		-- similar functionality to "Smart Bombers" widget,
		-- but also discards the Attack command after firing (see elseif REARM clause below)
		if cmdID == CMD_ATTACK_MOVE then
			--Echo("Set Fire At Will")
			spGiveOrderToUnit(unitID, CMD_FIRE_STATE, CMD_FIRESTATE_FIREATWILL, CMD_OPT_INTERNAL)
			bombers[unitID].attackMove = true
		elseif bombers[unitID].attackMove then
			spGiveOrderToUnit(unitID, CMD_FIRE_STATE, CMD_FIRESTATE_HOLDFIRE, CMD_OPT_INTERNAL)
			spGiveOrderToUnit(unitID, CMD_REMOVE, CMD_ATTACK_MOVE, CMD_OPT_ALT)
			bombers[unitID].attackMove = false
		end

		-- LuaRules/Gadgets/unit_bomber_command.lua inserts REARM command after a bomber fired, where:
		-- cmdParams[3] is REARM options = CMD_OPT_SHIFT + CMD_OPT_INTERNAL;
		-- cmdParams[4] is REARM params[1] = auto-chosen airpad (own or allied closest and having free slot AirPad/Factory or Reef).
		-- REARM options are tested to distinguish gadget-inserted REARM from one that this block inserts, to avoid endless loop.
	elseif  cmdID == CMD_INSERT and cmdParams[4]	and
		cmdParams[2] and cmdParams[2] == CMD_REARM	and
		cmdParams[3] and cmdParams[3] == CMD_OPT_SHIFT + CMD_OPT_INTERNAL   then

		--Echo("AUTO-REARM INSERTED")
		spGiveOrderToUnit(unitID, CMD_REMOVE, CMD_FORCE_FIRE, CMD_OPT_ALT)
		bombers[unitID].target = nil
		DiscardOrphanedTargets()

		spGiveOrderToUnit(unitID, CMD_FIRE_STATE, CMD_FIRESTATE_HOLDFIRE, CMD_OPT_INTERNAL)
		spGiveOrderToUnit(unitID, CMD_REMOVE, CMD_ATTACK_MOVE, CMD_OPT_ALT)

		if bombers[unitID].queue[1] then
			bombers[unitID]:RestoreQueuedCmds(true) -- arg is needRearm

			--  move rearm command after restored commands
			spGiveOrderToUnit(unitID, CMD_REMOVE, CMD_REARM, CMD_OPT_ALT)
			spGiveOrderToUnit(unitID, CMD_INSERT, {-1, CMD_REARM, CMD_OPT_SHIFT, cmdParams[4]}, CMD_OPT_ALT)
		end
	end
end

function widget:UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
	-- For widgets, this one is called just before the unit leaves los,
	-- so you can still get the position of a unit that left los,
	-- but not the velocity. Hence, target's data obtained in GameFrame()
	-- Btw, seems that it doesn't provide unitDefID, doesn't matter here.
	if targets[unitID] then
		--Echo("Target Left Los:", GetHumanName(unitID), unitID)
		targets[unitID].inLos = false
	end
end

function widget:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
	if targets[unitID] then
		--Echo("Target Entered Los:", GetHumanName(unitID), unitID)
		targets[unitID].inLos = true
	end
end

function widget:UnitLeftRadar(unitID)
	-- Also called when a unit leaves LOS without any radar coverage.
	-- For widgets, this is called just after a unit leaves radar coverage,
	-- so widgets cannot get the position of units that left their radar.
	if targets[unitID] then
		--Echo("Target Left Radar:", GetHumanName(unitID), unitID)
		if targets[unitID].lastKnownPos then
			targets[unitID].inRadar = false
			BombersHitTargetPosition(unitID, targets[unitID].lastKnownPos) -- will continue to get adjusted commands from GameFrame()
		else
			TargetIsGone(unitID)
		end
	end
end

function widget:UnitEnteredRadar(unitID, unitTeam, allyTeam, unitDefID)
-- Also called when a unit enters LOS without any radar coverage.

	if targets[unitID] then
		--Echo("Target Entered Radar:", GetHumanName(unitID), unitID)
		targets[unitID].inRadar = true
		local pos = GetAimPosition(unitID)
		if pos and pos.y and pos.y >= 0 then -- if y<0 (submerged), will get commands from GameFrame
			BombersHitTargetID(unitID)
		end
	end
end

function widget:GameFrame(gameFrame)
	if gameFrame % gameFramesInterval ~= gameFramesInterval - 1 then
		return
	end
	if next(targets) == nil then
		return
	end

	for targetID, target in pairs(targets) do
		if target.inLos then
			local vx,vy,vz,v = spGetUnitVelocity(targetID)
			local pos        = GetAimPosition(targetID)

			if pos and pos.x and pos.y and pos.z and vx and vy and vz and v then
				target.vel          = {x=vx, y=vy, z=vz, speed=v}
				target.lastKnownPos = pos
				target.lastSeen     = gameFrame
				--Echo("target data updated")
				if pos.y < 0 then
					target.inWater = true
					BombersHitTargetPosition(targetID, pos)
				elseif target.inWater then -- was submerged but not now
					target.inWater = false
					BombersHitTargetID(targetID)
				end
			else
				--Echo("target data missing")
			end
		elseif not target.inRadar then -- if its in Radar, continue with the regular Force Fire
			if target.lastSeen then

				local framesPassedSinceSeen = gameFrame - target.lastSeen

				-- predict target's position by last known position and velocity
				BombersHitTargetPosition(targetID, {
						x = target.lastKnownPos.x + target.vel.x * framesPassedSinceSeen,
						y = target.lastKnownPos.y + target.vel.y * framesPassedSinceSeen,
						z = target.lastKnownPos.z + target.vel.z * framesPassedSinceSeen
					}
				)
			else
				TargetIsGone(targetID)
			end
		end
	end
end

--function widget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag)
	--Echo("UnitCmdDone:", unitID, cmdID, cmdParams[1], cmdOpts)
--end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if unitTeam == myTeamID then
		if bombersDefID[unitDefID] and not bombers[unitID] then
			bombers[unitID] = bomberClass:New(unitID, unitDefID)
		elseif unitDefID == airpadDefID then
			local x,y,z = spGetUnitPosition(unitID)
			airpads[unitID] = {x,y,z}
		elseif unitDefID == airFactoryDefID then
			local x,y,z = spGetUnitPosition(unitID)
			airFacs[unitID] = {x,y,z}
		elseif unitDefID == airPalteDefID then
			local x,y,z = spGetUnitPosition(unitID)
			airPlates[unitID] = {x,y,z}
		end
	end
end

function widget:UnitGiven(unitID, unitDefID, unitTeam)
	local _,_,_,_,buildProgress = spGetUnitHealth (unitID)
	if buildProgress and buildProgress == 1 then
		widget:UnitFinished(unitID, unitDefID, unitTeam)
	end
end

function widget:UnitDestroyed(unitID)
	--Echo("unit destroyed")  -- takes long time to arrive? (after destroying cloaked target)
	if targets[unitID] then
		--Echo("target destroyed", GetHumanName(unitID))
		TargetIsGone(unitID)
	elseif bombers[unitID] then
		--Echo("bomber destroyed")
		bombers[unitID] = nil
		DiscardOrphanedTargets()
	elseif airpads[unitID] then
		airpads[unitID] = nil
	elseif airFacs[unitID] then
		airFacs[unitID] = nil
	elseif airPlates[unitID] then
		airPlates[unitID] = nil
	end
end

function widget:UnitTaken(unitID)
	widget:UnitDestroyed(unitID)
end

function widget:Initialize()
	if (Spring.GetSpectatingState() or Spring.IsReplay()) then
		widgetHandler:RemoveWidget(widget)
	end
	local myUnits = spGetTeamUnits(myTeamID)
	if myUnits then
		for _, unitID in pairs(myUnits) do
			widget:UnitGiven(unitID, spGetUnitDefID(unitID), myTeamID)
		end
	end
end

function widget:PlayerChanged(playerID)
	if spGetSpecState() then
		widgetHandler:RemoveWidget(widget)
	end
end
