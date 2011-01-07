-- $Id: cmd_retreat.lua 4138 2009-03-22 07:40:46Z carrepairer $
function widget:GetInfo()
  return {
    name      = "Retreat",
    desc      = " v0.26 Place 'retreat zones' on the map and order units to retreat to them at desired HP percentages.",
    author    = "CarRepairer",
    date      = "2008-03-17",
    license   = "GNU GPL, v2 or later",
    handler   = true,
    layer     = 0,
    enabled   = true
  }
end

-- speed-ups
local glDepthTest      = gl.DepthTest
local glAlphaTest      = gl.AlphaTest
local glTexture        = gl.Texture
local glTexRect        = gl.TexRect
local glTranslate      = gl.Translate
local glBillboard      = gl.Billboard
local glDrawFuncAtUnit = gl.DrawFuncAtUnit
local glColor          = gl.Color
local GL_GREATER       = GL.GREATER

local CMD_WAIT          = CMD.WAIT
local CMD_MOVE          = CMD.MOVE
local CMD_PATROL        = CMD.PATROL
local CMD_REPAIR        = CMD.REPAIR

local CMD_CLOAK         = CMD.CLOAK
local CMD_ONOFF         = CMD.ONOFF
local CMD_REPEAT        = CMD.REPEAT
local CMD_MOVE_STATE    = CMD.MOVE_STATE
local CMD_FIRE_STATE    = CMD.FIRE_STATE

local CMD_INSERT        = CMD.INSERT
local CMD_REMOVE        = CMD.REMOVE
local CMD_SET_WANTED_MAX_SPEED = CMD.SET_WANTED_MAX_SPEED

local CMD_RETREAT       = 10000
local CMD_SETHAVEN      = 10001
local CMD_CLOAK_SHIELD  = 32101
local CMD_STEALTH       = 32100


local GetGameFrame     = Spring.GetGameFrame
local GetLocalTeamID   = Spring.GetLocalTeamID
local GetUnitHealth    = Spring.GetUnitHealth
local GetUnitCommands  = Spring.GetUnitCommands
local GetUnitPosition  = Spring.GetUnitPosition
local GetUnitDefID     = Spring.GetUnitDefID
local GetSelectedUnits = Spring.GetSelectedUnits
local GetUnitStates    = Spring.GetUnitStates

local AreTeamsAllied   = Spring.AreTeamsAllied
local GiveOrderToUnit  = Spring.GiveOrderToUnit
local IsGuiHidden		=	Spring.IsGUIHidden

local abs, rand       = math.abs, math.random

local iconsize   = 30
local iconhsize  = iconsize * 0.5
local dist = 160
local maxDistSqr = dist * dist
local myTeamID
local tooltips = {}

local retreatingUnits, wantRetreat, alliedWantRetreat, retreatOrdersArray = {}, {}, {}, {}
local mobileUnits, cancelRetreatCommands, havens = {}, {}, {}
local havenCount = 0


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CanReallyMove(unitDefID)
  -- let factories have the retreat button, but don't check them
  -- (they do have canMove for new units, but their speed should be 0)
  local ud = UnitDefs[unitDefID]
  if (ud == nil) then
    return false
  end
  return (ud.speed > 0)
end

local function HeadingToHaven(unitID)
	if (havenCount == 0) then
		return false
	end

	local dx, dy, dz = retreatingUnits[unitID][1], retreatingUnits[unitID][2], retreatingUnits[unitID][3]

	for havenUnitID, havenPosition in pairs(havens) do
		local hx, hy, hz = havenPosition[1], havenPosition[2], havenPosition[3]
		if hx then 
			local dSquared = (hx - dx)^2 + (hz - dz)^2
			if (dSquared < maxDistSqr*1.3) then
				return true
			end
		end
	end--for
	return false
end



local function FindClosestHaven(sx, _, sz)
  local closestDistSqr = math.huge
  local cx, cy, cz  --  closest coordinates
  for havenID, havenPosition in pairs(havens) do
    local hx, hy, hz = havenPosition[1], havenPosition[2], havenPosition[3]
    if hx then 
      local dSquared = (hx - sx)^2 + (hz - sz)^2
      if (dSquared < closestDistSqr) then
        closestDistSqr = dSquared
        cx = hx; cy = hy; cz = hz
	cHavenID = havenID
      end
    end
  end
  if (not cx) then return -1, -1, -1, -1 end  -- should not happen
  return cx, cy, cz, closestDistSqr, cHavenID
end

local function FindClosestHavenToUnit(unitID)
  local ux, _, uz = GetUnitPosition(unitID)
  return FindClosestHaven(ux, _, uz)
end


local function IsRetreatMove(unitID, cmd)
	local dest = retreatingUnits[unitID]

	if not dest or not cmd then
		return false
	end

	if cmd.params[1] == dest[1] 
		and  cmd.params[2] == dest[2]
		and  cmd.params[3] == dest[3]
		then
		return true
	end
	return false
end


local function addHaven(x, y, z)
	havenCount = havenCount + 1
	havens[#havens+1] = {x, y, z}
end


local function removeHaven(havenID)
	if havens[havenID] then
		havenCount = havenCount - 1
	end
	havens[havenID] = nil
end


local function setRetreatOrder(unitID, unitDefID, retreatOrder)
	retreatOrdersArray[unitID] = retreatOrder
	mobileUnits[unitID] = CanReallyMove(unitDefID) or nil
end

function GetFirstCommand(unitID)
	local queue = GetUnitCommands(unitID)
	return queue and queue[1]
end


--Runs multiple times to finish process
function StopRetreating(unitID)
	if retreatingUnits[unitID] then
		local cmd1 = GetFirstCommand(unitID)

		if not cmd1 then
			--retreatingUnits[unitID] = nil

		elseif IsRetreatMove(unitID, cmd1) then
			GiveOrderToUnit(unitID, CMD_REMOVE, { cmd1.tag }, {} )

		elseif (cmd1.id == CMD_WAIT) then			
			GiveOrderToUnit(unitID, CMD_REMOVE, { cmd1.tag}, {})
			retreatingUnits[unitID] = nil
		else
			--retreatingUnits[unitID] = nil
		end

	else
		local cmd1 = GetFirstCommand(unitID)
		if not (cmd1 and cmd1.id == CMD_WAIT) then
			cancelRetreatCommands[unitID] = nil
		end
	end
end


local function DrawUnitFunc(yshift)
	glTranslate(10, yshift, 0)
	glBillboard()
	glTexRect(-iconhsize, 0, iconhsize, iconsize)
end


local function Retreat(unitID)
	local hx, hy, hz, dSquared = FindClosestHavenToUnit(unitID)
	hx = hx + dist - rand(10, dist*2)
	--hy = hy
	hz = hz + dist - rand(10, dist*2)

	if (dSquared > maxDistSqr) then
		-- using OPT_INTERNAL so that the CMD.MOVE order is not cycled when the unit has repeat enabled
		GiveOrderToUnit(unitID, CMD_INSERT, { 0, CMD_MOVE, CMD.OPT_INTERNAL, hx, hy, hz}, CMD.OPT_ALT) -- ALT makes the 0 positional
		GiveOrderToUnit(unitID, CMD_INSERT, { 1, CMD_WAIT, CMD.OPT_SHIFT}, CMD.OPT_ALT) --SHIFT W

		retreatingUnits[unitID] = {hx, hy, hz}
	end
end

function widget:Initialize()
	--[[
	if (not (widgetHandler.knownWidgets["CALayout"] or {}).active) then
		Spring.Echo("RetreatWidget: You have deactivated the CALayout widget, which is needed by the retreat widget!")
		widgetHandler:RemoveWidget(widget)
		return
	end
	--]]

	myTeamID = GetLocalTeamID()
	tooltips[1] = 'Orders: never retreat.'
	tooltips[2] = 'Orders: retreat at less than 30% of health (right-click to turn off).'
	tooltips[3] = 'Orders: retreat at less than 60% of health (right-click to turn off).'
	tooltips[4] = 'Orders: retreat at less than 90% of health (right-click to turn off).'

	WG['retreat'] = {}
	WG['retreat'].addRetreatCommand = function(unitID, unitDefID, retreatOrder)		
		setRetreatOrder(unitID, unitDefID, retreatOrder)
	end
end

----------------------------------------------------------------------------
----------------------------------------------------------------------------

function widget:UnitFromFactory(unitID, unitDefID, teamID, builderID, _, _)
	local ud = UnitDefs[unitDefID]
	if ud.canMove and builderID then      
		setRetreatOrder(unitID, unitDefID, retreatOrdersArray[builderID])
		wantRetreat[unitID] = nil
	end	
end

function widget:UnitDestroyed(unitID, _, teamID)
	wantRetreat[unitID] = nil
	cancelRetreatCommands[unitID] = nil
	retreatOrdersArray[unitID] = nil
	retreatingUnits[unitID] = nil
	mobileUnits[unitID] = nil
end

function widget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
	wantRetreat[unitID] = nil
	cancelRetreatCommands[unitID] = nil
	retreatOrdersArray[unitID] = nil
	retreatingUnits[unitID] = nil
	mobileUnits[unitID] = nil
end


function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_SETHAVEN then
		local x,y,z = cmdParams[1], cmdParams[2], cmdParams[3]
		local _, _, _, dSquared, closestHavenID = FindClosestHaven(x,y,z)
		if dSquared ~= -1 and dSquared < dist*dist then
			removeHaven(closestHavenID)
		else
			addHaven(x,y,z)
		end
		return true
		
	elseif cmdID == CMD_RETREAT then
		local foundValidUnit = false
		local newRetreatOrder = nil
		local selectedUnits = GetSelectedUnits()
		for _, unitID in ipairs(selectedUnits) do

			local unitDefID = GetUnitDefID(unitID)
			local ud = UnitDefs[unitDefID]

			if ud.canMove then --Check canmove for mixed selections

				wantRetreat[unitID] = nil 
				if not foundValidUnit then
					foundValidUnit = true
					
					if not cmdOptions.right then
						if retreatOrdersArray[unitID] then
							newRetreatOrder = retreatOrdersArray[unitID] % 3 + 1
						else
							newRetreatOrder = 1
						end
					end
				end

				setRetreatOrder(unitID, unitDefID, newRetreatOrder)
				if not newRetreatOrder then
					cancelRetreatCommands[unitID] = true
				end
			end --if canmove
		end --for
		return true
	end
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdOptions, cmdParams) 
	local commandOverriden = false
	
	if cmdID == CMD_MOVE then
		--if not cmdOptions.shift then
		if not (math.bit_and(cmdOptions,CMD.OPT_SHIFT) > 0) then
			commandOverriden = true
		end
	
	elseif (math.bit_and(cmdOptions,CMD.OPT_ALT) > 0) then
		--ignore these priority commands hopefully issued only by this widget
	
	--elseif (not cmdOptions.shift) then
	elseif not (math.bit_and(cmdOptions,CMD.OPT_SHIFT) > 0)
		and cmdID ~= CMD_SET_WANTED_MAX_SPEED	
		and cmdID ~= CMD_FIRE_STATE	and cmdID ~= CMD_MOVE_STATE
		and cmdID ~= CMD_ONOFF		and cmdID ~= CMD_REPEAT
		and cmdID ~= CMD_CLOAK		and cmdID ~= CMD_CLOAK_SHIELD	
		and cmdID ~= CMD_STEALTH	and cmdID ~= CMD_WAIT
		and cmdID ~= CMD_IDLEMODE
		then
		commandOverriden = true
	end

	if commandOverriden and retreatingUnits[unitID] then
		local cmd1 = GetFirstCommand(unitID)

		if not cmd1 then
			--retreatingUnits[unitID] = nil
		elseif IsRetreatMove(unitID, cmd1) then
			Retreat(unitID)	
		elseif (cmd1.id == CMD_WAIT) then			
			GiveOrderToUnit(unitID, CMD_WAIT, {}, {})
		end
		
		--local selectedUnits = GetSelectedUnits()
		--for _, unitID in ipairs(selectedUnits) do
			--retreatingUnits[unitID] = nil
		--end

	end
	
	

end

function widget:CommandsChanged()
	local selectedUnits = GetSelectedUnits()
	local foundRetreatable = false
	local customCommands = widgetHandler.customCommands

	table.insert(customCommands, {			
		id      = CMD_SETHAVEN,
		type    = CMDTYPE.ICON_MAP,
		tooltip = 'Place a retreat zone. Units will retreat there. Constructors placed in it will repair units.',
		cursor  = 'Repair',
		action  = 'sethaven',
		params  = { }, 
		texture = 'LuaUI/Images/ambulance.png',

		pos = {CMD_CLOAK,CMD_ONOFF,CMD_REPEAT,CMD_MOVE_STATE,CMD_FIRE_STATE, CMD_RETREAT}, 
	})


	for _, unitID in ipairs(selectedUnits) do

		local unitID = GetSelectedUnits()[1]

		local unitDefID = GetUnitDefID(unitID)
		local ud = UnitDefs[unitDefID]

		if not foundRetreatable and ud and ud.canMove then
			foundRetreatable = true
			local retreatOrder = retreatOrdersArray[unitID] or 0			
			--widgetHandler:AddLayoutCommand({
			table.insert(customCommands, {
				id      = CMD_RETREAT,
				type    = CMDTYPE.ICON_MODE,
				name    = 'Retreat',
				tooltip = tooltips[retreatOrder + 1],
				cursor  = 'Retreat',
				action  = 'retreat',
				params  = { retreatOrder , 'Retreat Off', 'Retreat 30%', 'Retreat 60%', 'Retreat 90%' }, 

				pos = {CMD_CLOAK,CMD_ONOFF,CMD_REPEAT,CMD_MOVE_STATE,CMD_FIRE_STATE}, 
			})
   
		end--if canmove
		
		if foundRetreatable then 
			return
		end


	end--for 
end

function widget:UnitDamaged(unitID) 
	local retreatOrder = retreatOrdersArray[unitID]
	if (retreatOrder ~= nil and retreatOrder > 0 and mobileUnits[unitID]) then 
		local health, maxHealth = GetUnitHealth(unitID)
		if (health) then

			local healthRatio = health / maxHealth
			local threshold = retreatOrder * 0.3

			if healthRatio < threshold then        
				wantRetreat[unitID] = true
			elseif (healthRatio == 1) then
				wantRetreat[unitID] = nil	
			end

			if wantRetreat[unitID] then				        
				if (havenCount > 0) and not retreatingUnits[unitID] then
					Retreat(unitID)        
				end
			end 
		end 
	end 

end 

function widget:DrawWorld()
	local gameFrame = GetGameFrame()

	local frame32 = (gameFrame+1) % 32
	local frame160 = frame32 % 5

	if (frame32 < 0.1) then

		for unitID, retreatOrders in pairs(retreatOrdersArray) do
		  repeat -- emulating continue
			if mobileUnits[unitID] and not cancelRetreatCommands[unitID] then
        
				local health, maxHealth = GetUnitHealth(unitID)
				if (not health) then
					break -- continue
				end

				local healthRatio = health / maxHealth
				local threshold = retreatOrders * 0.3

				if healthRatio < threshold then        
					wantRetreat[unitID] = true
				elseif (healthRatio == 1) then
					wantRetreat[unitID] = nil	
				end

				if wantRetreat[unitID] then				        
					if (havenCount > 0) and not retreatingUnits[unitID] then
						Retreat(unitID)        
					end
				else --not wantRetreat[unitID]
					if retreatingUnits[unitID] then
						cancelRetreatCommands[unitID] = true
					end
				end

				--Every 5 seconds, start a cancel retreat if heading nowhere
				if (frame160 < 0.1) then	
					if retreatingUnits[unitID] and not HeadingToHaven(unitID) then						
						cancelRetreatCommands[unitID] = true				
					end
				end
			end
		  until true --do not repeat
		end -- for

		for unitID, _ in pairs(cancelRetreatCommands) do
			StopRetreating(unitID)
		end -- for

	end --if frame 1/30

	local fade = abs((gameFrame % 40) - 20) / 20
  
	--Draw ambulance on havens.
	if (havens) then

		glDepthTest(true)
		gl.LineWidth(2)

		for havenID, havenPosition in pairs(havens) do
			local x, y, z = havenPosition[1], havenPosition[2], havenPosition[3]

			gl.LineWidth(4)
			glColor(1, 1, 1, 0.5)
			gl.DrawGroundCircle(x, y, z, dist, 32)

			gl.LineWidth(2)
			glColor(1, 0.1, 0.1, 0.8)
			gl.DrawGroundCircle(x, y, z, dist, 32)

		end --for
		glAlphaTest(GL_GREATER, 0)
		glColor(1,fade,fade,fade+0.1)
		glTexture('LuaUI/Images/ambulance.png')
		
		for unitID, havenPosition in pairs(havens) do
			local x, y, z = havenPosition[1], havenPosition[2], havenPosition[3]
			gl.PushMatrix()
			glTranslate(x, y, z)
			glBillboard()
			glTexRect(-10, 0, 10, 20)
			gl.PopMatrix()
		end --for
		
		glTexture(false)
		glAlphaTest(false)
		glDepthTest(false)
	end --if havens
	
	--Draw medic symbol on critical units.
	if wantRetreat and not IsGuiHidden() then --also do alliedWantRetreat table
		glDepthTest(true)
		glAlphaTest(GL_GREATER, 0)
		glColor(1,1,1,fade)
		glTexture('Anims/cursorrepair_old.png')
		
		for unitID, _ in pairs(wantRetreat) do
			local unitDefID = GetUnitDefID(unitID)
			if (unitDefID) then
				glDrawFuncAtUnit(unitID, false, DrawUnitFunc, UnitDefs[unitDefID].height + 4)
			end
		end

		glColor(1,1,1,1)
		glTexture(false)
		glAlphaTest(false)
		glDepthTest(false)
	end
  
end --DrawWorld

--Bind a hotkey to "luaui noretreat" for quick bravery
function widget:TextCommand(command)
	if (command == "noretreat") then
		widgetHandler:CommandNotify(CMD_RETREAT, {}, { right=true })
		return true
	end
	return false
end   

