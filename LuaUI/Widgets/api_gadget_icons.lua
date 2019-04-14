-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Gadget Icons",
    desc      = "Shows icons from gadgets that cannot access the widget stuff by themselves.",
    author    = "CarRepairer and GoogleFrog",
    date      = "2012-01-28",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = true,
    alwaysStart = true,
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local echo = Spring.Echo


local min   = math.min
local floor = math.floor

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

local unitList = {}
local unitIndex = {}
local unitCount = 0
local unitDefIDMap = {}

local currentIndex = 0

local CMD_WAIT = CMD.WAIT

local CMD_WAITCODE_NONE   = 0
local CMD_WAITCODE_DEATH  = CMD.WAITCODE_DEATH
local CMD_WAITCODE_SQUAD  = CMD.WAITCODE_SQUAD
local CMD_WAITCODE_GATHER = CMD.WAITCODE_GATHER
local CMD_WAITCODE_TIME   = CMD.WAITCODE_TIME

local powerTexture = 'Luaui/Images/visible_energy.png'
local facplopTexture = 'Luaui/Images/factory.png'
local rearmTexture = 'LuaUI/Images/noammo.png'
local retreatTexture = 'LuaUI/Images/unit_retreat.png'

local waitTexture = {
	[CMD_WAITCODE_NONE  ] = 'LuaUI/Images/commands/Bold/wait.png',
	[CMD_WAITCODE_DEATH ] = 'LuaUI/Images/commands/Bold/wait_death.png',
	[CMD_WAITCODE_SQUAD ] = 'LuaUI/Images/commands/Bold/wait_squad.png',
	[CMD_WAITCODE_GATHER] = 'LuaUI/Images/commands/Bold/wait_gather.png',
	[CMD_WAITCODE_TIME  ] = 'LuaUI/Images/commands/Bold/wait_time.png',
}

local lastLowPower = {}
local lastFacPlop = {}
local lastRearm = {}
local lastRetreat = {}
local lastWait = {}
local everWait = {}

local lowPowerUnitDef = {}
local facPlopUnitDef = {}
local rearmUnitDef = {}
local retreatUnitDef = {}
local waitUnitDef = {}
for unitDefID = 1, #UnitDefs do
	local ud = UnitDefs[unitDefID]
	if ud.customParams.neededlink then
		lowPowerUnitDef[unitDefID] = true
	end
	if ud.customParams.level then
		facPlopUnitDef[unitDefID] = true
	end
	if ud.customParams.requireammo then
		rearmUnitDef[unitDefID] = true
	end
	if not ud.isImmobile then
		retreatUnitDef[unitDefID] = true
	end
	if not ud.customParams.removewait then
		waitUnitDef[unitDefID] = true
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function RemoveUnit(unitID)
	local index = unitIndex[unitID]
	unitList[index] = unitList[unitCount]
	unitIndex[unitList[unitCount]] = index
	unitList[unitCount] = nil
	unitCount = unitCount - 1
	unitIndex[unitID] = nil
	unitDefIDMap[unitID] = nil
	lastLowPower[unitID] = nil
	lastFacPlop[unitID] = nil
	lastRearm[unitID] = nil
	lastRetreat[unitID] = nil
	lastWait[unitID] = nil
	everWait[unitID] = nil
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local spGetUnitCurrentCommand = Spring.GetUnitCurrentCommand
local function isWaiting(unitID)
	local cmdID, _, _, cmdParam1 = spGetUnitCurrentCommand(unitID)
	if not cmdID then
		everWait[unitID] = nil
		return false
	end

	if cmdID ~= CMD_WAIT then
		return false
	end

	return cmdParam1 or CMD_WAITCODE_NONE
end

function SetIcons()
	local unitID
	local limit = math.ceil(unitCount/4)
	for i = 1, limit do
		currentIndex = currentIndex + 1
		if currentIndex > unitCount then
			currentIndex = 1
		end
		unitID = unitList[currentIndex]
		if not unitID then
			return
		end
		local unitDefID = unitDefIDMap[unitID]
		-- calculate which units can have these states and check them first
		
		local lowpower = lowPowerUnitDef[unitDefID] and Spring.GetUnitRulesParam(unitID, "lowpower") 
		if lowpower then
			local _,_,inbuild = Spring.GetUnitIsStunned(unitID)
			if inbuild then
				lowpower = 0 -- Draw as if not on low power
			end
			if (not lastLowPower[unitID]) or lastLowPower[unitID] ~= lowpower then
				lastLowPower[unitID] = lowpower
				if lowpower ~= 0 then
					WG.icons.SetUnitIcon( unitID, {name='lowpower', texture=powerTexture} )
				else
					WG.icons.SetUnitIcon( unitID, {name='lowpower', texture=nil} )
				end
			end
		end
		
		local facplop = facPlopUnitDef[unitDefID] and Spring.GetUnitRulesParam(unitID, "facplop") 
		if facplop or lastFacPlop[unitID] == 1 then
			if not facplop then
				facplop = 0
			end
			if (not lastFacPlop[unitID]) or lastFacPlop[unitID] ~= facplop then
				lastFacPlop[unitID] = facplop
				if facplop ~= 0 then
					WG.icons.SetUnitIcon( unitID, {name='facplop', texture=facplopTexture} )
					WG.icons.SetPulse( 'facplop', true )
				else
					WG.icons.SetUnitIcon( unitID, {name='facplop', texture=nil} )
				end
			end
		end
		
		local rearm = rearmUnitDef[unitDefID] and Spring.GetUnitRulesParam(unitID, "noammo") 
		if rearm then
			if (not lastRearm[unitID]) or lastRearm[unitID] ~= rearm then
				lastRearm[unitID] = rearm
				if rearm == 1 or rearm == 2 then
					WG.icons.SetUnitIcon( unitID, {name='rearm', texture=rearmTexture} )
				elseif rearm == 3 then
					WG.icons.SetUnitIcon( unitID, {name='rearm', texture=repairTexture} )
				else
					WG.icons.SetUnitIcon( unitID, {name='rearm', texture=nil} )
				end
			end
		end
		
		local retreat = retreatUnitDef[unitDefID] and Spring.GetUnitRulesParam(unitID, "retreat") 
		if retreat then
			if (not lastRetreat[unitID]) or lastRetreat[unitID] ~= retreat then
				lastRetreat[unitID] = retreat
				if retreat ~= 0 then
					WG.icons.SetUnitIcon( unitID, {name='retreat', texture=retreatTexture} )
				else
					WG.icons.SetUnitIcon( unitID, {name='retreat', texture=nil} )
				end
			end
		end

		if everWait[unitID] and waitUnitDef[unitDefID] then
			local wait = isWaiting(unitID)
			if lastWait[unitID] ~= wait then
				lastWait[unitID] = wait
				if wait then
					WG.icons.SetUnitIcon( unitID, {name='wait', texture=waitTexture[wait]} )
				else
					WG.icons.SetUnitIcon( unitID, {name='wait', texture=nil} )
				end
			end
		end
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if not (lowPowerUnitDef[unitDefID] or facPlopUnitDef[unitDefID] or rearmUnitDef[unitDefID] or retreatUnitDef[unitDefID] or waitUnitDef[unitDefID]) then
		return
	end
	if unitIndex[unitID] then
		return
	end
	
	unitCount = unitCount + 1
	unitList[unitCount] = unitID
	unitIndex[unitID] = unitCount
	unitDefIDMap[unitID] = unitDefID
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	-- There should be a better way to do this, lazy fix.
	WG.icons.SetUnitIcon( unitID, {name='lowpower', texture=nil} )
	WG.icons.SetUnitIcon( unitID, {name='facplop', texture=nil} )
	WG.icons.SetUnitIcon( unitID, {name='rearm', texture=nil} )
	WG.icons.SetUnitIcon( unitID, {name='retreat', texture=nil} )
	WG.icons.SetUnitIcon( unitID, {name='wait', texture=nil} )
	
	if unitIndex[unitID] then
		RemoveUnit(unitID)
	end
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	widget:UnitCreated(unitID, unitDefID, unitTeam)
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
	widget:UnitDestroyed(unitID, unitDefID, unitTeam)
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts)
	if cmdID == CMD_WAIT then
		everWait[unitID] = true
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GameFrame(f)
	if f%4 == 0 then
		SetIcons()
	end
end

function widget:Initialize()
	WG.icons.SetOrder('lowpower', 2)
	WG.icons.SetOrder('retreat', 5)
	WG.icons.SetDisplay('retreat', true)
	WG.icons.SetPulse('retreat', true)
	
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		widget:UnitCreated(unitID, unitDefID, myTeamID)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
