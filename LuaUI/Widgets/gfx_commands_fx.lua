function widget:GetInfo()
   return {
      name      = "Commands FX",
      desc      = "Adds glow-pulses wherever commands are queued. Including mapmarks.",
      author    = "Floris",
      date      = "14.04.2014",
      license   = "GNU GPL, v2 or later",
      layer     = 2,
      enabled   = true,
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- NOTE:  STILL IN DEVELOPMENT!
-- dont change without asking/permission please

VFS.Include("LuaRules/Configs/customcmds.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local commandHistory			= {}	
local commandHistoryCoords		= {}	-- this table is used to count cmd´s with same coordinates
local commandCoordsRendered		= {}	-- this table is used to skip cmd´s that have the same coordinates
local mapDrawNicknameTime		= {}	-- this table is used to filter out previous map drawing nicknames if user has drawn something new
local mapEraseNicknameTime		= {}	-- 
local ownPlayerID				= Spring.GetMyPlayerID()

local commandCount = 0
local commandList = {}

local spGetUnitPosition			= Spring.GetUnitPosition
local spGetCameraPosition		= Spring.GetCameraPosition
local spGetPlayerInfo			= Spring.GetPlayerInfo
local spTraceScreenRay			= Spring.TraceScreenRay
local spLoadCmdColorsConfig		= Spring.LoadCmdColorsConfig
local spGetTeamColor			= Spring.GetTeamColor

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Interface/Command Visibility'--/Formations'
options_order = { 'lblformations', 'indicate_cf_v2', 'onClick'}
options = {
	lblformations = { name = 'Formations', type = 'label'},
	indicate_cf_v2 = {
		name = "Indicate for custom formations", 
		desc = "Draw the command indication for commands given with custom formations.",
		type = 'bool', 
		noHotkey = true,
		value = true
	},
	onClick = {
		name = "Indicate for clicks", 
		desc = "Draw the command indication for every click.",
		type = 'bool', 
		noHotkey = true,
		value = false
	}
}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local OPTIONS = {
	showMapmarkFx 				= true,
	showMapmarkSpecNames		= true,
	showMapmarkSpecIcons		= false,	-- showMapmarkFx must be true for this to work
	nicknameOpacityMultiplier	= 6,		-- multiplier applied to the given color opacity of the type: 'map_draw'
	scaleWithCamera				= true,
	
	size 						= 28,
	opacity 					= 1,
	duration					= 0.7,		-- each type has its own duration, but this settings applies to all
	
	baseParts					= 14,		-- (note that if camera is distant the number of parts will be reduced, up to 6 as minimum)
	ringParts					= 24,		-- (note that if camera is distant the number of parts will be reduced, up to 6 as minimum)
	ringWidth					= 2,
	ringStartSize				= 4,
	ringScale					= 0.75,
	reduceOverlapEffect			= 0.08,		-- when spotters have the same coordinates: reduce the opacity: 1 is no reducing while 0 is no adding
	
	types = {
		leftclick = {
			size			= 0.58,
			duration		= 1,
			baseColor 		= {1.00 ,0.50 ,0.00 ,0.28},
			ringColor		= {1.00 ,0.50 ,0.00 ,0.12}
		},
		rightclick = {
			size			= 0.58,
			duration		= 1,
			baseColor		= {1.00 ,0.75 ,0.00 ,0.25},
			ringColor		= {1.00 ,0.75 ,0.00 ,0.11}
		},
		map_mark = {
			size			= 2,
			duration		= 4.5,
			baseColor		= {1.00 ,1.00 ,1.00 ,0.40},
			ringColor		= {1.00 ,1.00 ,1.00 ,0.75}
		},
		map_draw = {
			size			= 0.63,
			duration		= 1.4,
			baseColor		= {1.00 ,1.00 ,1.00 ,0.15},
			ringColor		= {1.00 ,1.00 ,1.00 ,0.00}
		},
		map_erase = {
			size			= 2,
			duration		= 3,
			baseColor		= {1.00 ,1.00 ,1.00 ,0.13},
			ringColor		= {1.00 ,1.00 ,1.00 ,0.00}
		},
		[CMD.MOVE] = {
			size			= 1,
			duration		= 1,
			baseColor		= {0.00 ,1.00 ,0.00 ,0.25},
			ringColor		= {0.00 ,1.00 ,0.00 ,0.25}
		},
		[CMD_RAW_MOVE] = {
			size			= 1,
			duration		= 1,
			baseColor		= {0.00 ,1.00 ,0.00 ,0.25},
			ringColor		= {0.00 ,1.00 ,0.00 ,0.25}
		},
		[CMD.FIGHT] = {
			size			= 1.2,
			duration		= 1,
			baseColor		= {0.20 ,0.60 ,1.00 ,0.30},
			ringColor		= {0.20 ,0.60 ,1.00 ,0.40}
		},
		[CMD.DGUN] = {
			size			= 1.4,
			duration		= 1,
			baseColor		= {1.00 ,0.00 ,0.00 ,0.30},
			ringColor		= {1.00 ,0.00 ,0.00 ,0.40}
		},
		[CMD.ATTACK] = {
			size			= 1.4,
			duration		= 1,
			baseColor		= {1.00 ,0.00 ,0.00 ,0.30},
			ringColor		= {1.00 ,0.00 ,0.00 ,0.40}
		},
		[CMD.PATROL] = {
			size			= 1.4,
			duration		= 1,
			baseColor		= {0.40 ,0.40 ,1.00 ,0.30},
			ringColor		= {0.40 ,0.40 ,1.00 ,0.40}
		},
		[CMD_JUMP] = {
			size			= 1.2,
			duration		= 1,
			baseColor		= {0.00 ,1.00 ,1.00 ,0.25},
			ringColor		= {0.00 ,1.00 ,1.00 ,0.25}
		},
		[CMD_PLACE_BEACON] = {
			size			= 1.2,
			duration		= 1,
			baseColor		= {0.10 ,0.80 ,0.80 ,0.25},
			ringColor		= {0.10 ,0.80 ,0.80 ,0.25}
		},
		[CMD_WAIT_AT_BEACON] = {
			size			= 1.2,
			duration		= 1,
			baseColor		= {0.10 ,0.10 ,0.90 ,0.25},
			ringColor		= {0.10 ,0.10 ,0.90 ,0.25}
		},
		[CMD_UNIT_SET_TARGET] = {
			size			= 1.2,
			duration		= 1,
			baseColor		= {0.80 ,0.80 ,0.10 ,0.25},
			ringColor		= {0.80 ,0.80 ,0.10 ,0.25}
		},
		[CMD_UNIT_SET_TARGET_CIRCLE] = {
			size			= 1.2,
			duration		= 1,
			baseColor		= {0.80 ,0.80 ,0.10 ,0.25},
			ringColor		= {0.80 ,0.80 ,0.10 ,0.25}
		},
	}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function Round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end


local function DrawBaseGlow(parts, size, r,g,b,a)
	gl.Color(r,g,b,a)
	gl.Vertex(0, 0, 0)
	gl.Color(r,g,b,0)
	local radstep = (2.0 * math.pi) / parts
	for i = 0, parts do
		local a1 = (i * radstep)
		gl.Vertex(math.sin(a1)*size, 0, math.cos(a1)*size)
	end
end


local function DrawRingCircle(parts, ringSize, ringInnerSize, ringOuterSize, rRing,gRing,bRing,aRing)
	local radstep = (2.0 * math.pi) / parts
	for i = 1, parts do
		local a1 = (i * radstep)
		local a2 = ((i+1) * radstep)
		
		local a1Sin = math.sin(a1)
		local a2Sin = math.sin(a2)
		
		a1 = math.cos(a1)
		a2 = math.cos(a2)
		
		--(fadefrom)
		gl.Color(rRing,gRing,bRing,0)
		gl.Vertex(a2Sin*ringInnerSize, 0, a2*ringInnerSize)
		gl.Vertex(a1Sin*ringInnerSize, 0, a1*ringInnerSize)
		--(fadeto)
		gl.Color(rRing,gRing,bRing,aRing)
		gl.Vertex(a1Sin*ringSize, 0, a1*ringSize)
		gl.Vertex(a2Sin*ringSize, 0, a2*ringSize)
		
		--(fadefrom)
		gl.Color(rRing,gRing,bRing,aRing)
		gl.Vertex(a1Sin*ringSize, 0, a1*ringSize)
		gl.Vertex(a2Sin*ringSize, 0, a2*ringSize)
		--(fadeto)
		gl.Color(rRing,gRing,bRing,0)
		gl.Vertex(a2Sin*ringOuterSize, 0, a2*ringOuterSize)
		gl.Vertex(a1Sin*ringOuterSize, 0, a1*ringOuterSize)
	end
end

local function CircleVerticies(circleDivs)
	for i = 1, circleDivs do
		local theta = 2 * math.pi * i / circleDivs
		gl.Vertex(math.cos(theta), 0, math.sin(theta))
	end
end

local function DrawGroundquad(wx,gy,wz,size)
	gl.TexCoord(0,0)
	gl.Vertex(wx-size,gy+size,wz-size)
	gl.TexCoord(0,1)
	gl.Vertex(wx-size,gy+size,wz+size)
	gl.TexCoord(1,1)
	gl.Vertex(wx+size,gy+size,wz+size)
	gl.TexCoord(1,0)
	gl.Vertex(wx+size,gy+size,wz-size)
end

local function AddCommandSpotter(cmdType, x, y, z, osClock, unitID, playerID)
	if not unitID then
		unitID = 0
	end
	if not playerID then
		playerID = false
	end
	--local uniqueNumber = unitID..'_'..osClock .. math.random()
	--commandHistory[uniqueNumber] = {
	--	cmdType		= cmdType,
	--	x			= x,
	--	y			= y,
	--	z			= z,
	--	osClock		= osClock,
	--	playerID	= playerID
	--}
	
	commandCount = commandCount + 1
	commandList[commandCount] = {
		cmdType		= cmdType,
		x			= x,
		y			= y,
		z			= z,
		osClock		= osClock,
		playerID	= playerID
	}
	
	if commandHistoryCoords[cmdType..x..y..z] then
		commandHistoryCoords[cmdType..x..y..z] = commandHistoryCoords[cmdType..x..y..z] + 1
	else
		commandHistoryCoords[cmdType..x..y..z] = 1
	end
end

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

--	Engine Triggers

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

local circleDrawList

function widget:Initialize()
	circleDrawList = gl.CreateList(gl.BeginEnd, GL.LINE_LOOP, CircleVerticies, 18)
end

function widget:MapDrawCmd(playerID, cmdType, x, y, z, a, b, c)
	local osClock = os.clock()
	if OPTIONS.showMapmarkFx then
		if cmdType == 'point' then
			AddCommandSpotter('map_mark', x, y, z, osClock, false, playerID)
		elseif cmdType == 'line' then
			mapDrawNicknameTime[playerID] = osClock
			AddCommandSpotter('map_draw', x, y, z, osClock, false, playerID)
		elseif cmdType == 'erase' then
			mapEraseNicknameTime[playerID] = osClock
			AddCommandSpotter('map_erase', x, y, z, osClock, false, playerID)
		end
	end
end

function widget:MousePress(x, y, button)
	if options.onClick.value then
		local traceType, tracedScreenRay = spTraceScreenRay(x, y, true)
		if button == 1 and tracedScreenRay  and tracedScreenRay[3] then
			AddCommandSpotter('leftclick', tracedScreenRay[1], tracedScreenRay[2], tracedScreenRay[3], os.clock())
		end
		if button == 3 and tracedScreenRay  and tracedScreenRay[3] then
			AddCommandSpotter('rightclick', tracedScreenRay[1], tracedScreenRay[2], tracedScreenRay[3], os.clock())
		end
	end
end

function widget:CommandNotify(cmdID, cmdParams, options)
	if type(cmdParams) == 'table' and #cmdParams >= 3 and OPTIONS.types[cmdID] then
		AddCommandSpotter(cmdID, cmdParams[1], cmdParams[2], cmdParams[3], os.clock())
	end
end

function widget:UnitCommandNotify(unitID, cmdID, cmdParams, cmdOptions)
	if options.indicate_cf_v2.value then
		if type(cmdParams) == 'table' and #cmdParams >= 3 and OPTIONS.types[cmdID] then
			AddCommandSpotter(cmdID, cmdParams[1], cmdParams[2], cmdParams[3], os.clock(), unitID)
		end
	end
end

--function widget:GameFrame(f)
--	AddCommandSpotter(CMD.MOVE, (f%25)*40+40, 48, (math.floor(f/25)%25)*40+40, os.clock())
--end

function widget:DrawWorldPreUnit()
	
	local osClock = os.clock()
	--local camX, camY, camZ = spGetCameraPosition()
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.DepthTest(false)
	
	commandCoordsRendered = {}
	
	local index = 1
	while index <= commandCount do
		local cmdValue = commandList[index]
	--for cmdKey, cmdValue in pairs(commandHistory) do
	
		local clickOsClock	= cmdValue.osClock
		local cmdType		= cmdValue.cmdType
		local playerID		= cmdValue.playerID
		local duration		= OPTIONS.types[cmdType].duration * OPTIONS.duration
		
		-- remove when duration has passed
		if osClock - clickOsClock > duration  then
			if commandHistoryCoords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] <= 1 then
				commandHistoryCoords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] = nil
			else
				commandHistoryCoords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] = commandHistoryCoords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] - 1
			end
			--commandHistory[cmdKey] = nil
			
			commandList[index] = commandList[commandCount]
			commandList[commandCount] = nil
			commandCount = commandCount - 1
			
		-- remove nicknames when user has drawn something new
		elseif  OPTIONS.showMapmarkSpecNames  and  cmdType == 'map_draw'  and  mapDrawNicknameTime[playerID] ~= nil  and  clickOsClock < mapDrawNicknameTime[playerID] then
			
			--commandHistory[cmdKey] = nil
			commandList[index] = commandList[commandCount]
			commandList[commandCount] = nil
			commandCount = commandCount - 1
			
		-- draw all
		elseif  OPTIONS.types[cmdType].baseColor[4] > 0  or  OPTIONS.types[cmdType].ringColor[4] > 0  then
			index = index + 1
			
			if commandCoordsRendered[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] == nil then
				commandCoordsRendered[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] = true
				local alphaMultiplier = 1 + (OPTIONS.reduceOverlapEffect * (commandHistoryCoords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] - 1))	 -- add a bit to the multiplier for each cmd issued on the same coords
				
				local size	= OPTIONS.size * OPTIONS.types[cmdType].size
				local a		= (1 - ((osClock - clickOsClock) / duration)) * OPTIONS.opacity * alphaMultiplier
				
				local baseColor = OPTIONS.types[cmdType].baseColor
				local ringColor = OPTIONS.types[cmdType].ringColor
				
				-- use player colors
				if  cmdType == 'map_mark'   or   cmdType == 'map_draw'  or  cmdType == 'map_erase'  then
					local _,_,spec,teamID = spGetPlayerInfo(playerID, false)
					local r,g,b = 1,1,1
					if not spec then
						r,g,b = spGetTeamColor(teamID)
					end
					baseColor = {1,1,1,baseColor[4]}
					ringColor = {r,g,b,ringColor[4]}
				end
				
				local rRing	= ringColor[1]
				local gRing	= ringColor[2]
				local bRing	= ringColor[3]
				local aRing	= a * ringColor[4]
				local r		= baseColor[1]
				local g		= baseColor[2]
				local b		= baseColor[3]
				a			= a * baseColor[4]
					
				local ringSize = OPTIONS.ringStartSize + (size * OPTIONS.ringScale) * ((osClock - clickOsClock) / duration)
				--local ringInnerSize = ringSize - OPTIONS.ringWidth
				--local ringOuterSize = ringSize + OPTIONS.ringWidth
				
				gl.PushMatrix()
				gl.Translate(cmdValue.x, cmdValue.y, cmdValue.z)
				
				--local xDifference = camX - cmdValue.x
				--local yDifference = camY - cmdValue.y
				--local zDifference = camZ - cmdValue.z
				--local camDistance = math.sqrt(xDifference*xDifference + yDifference*yDifference + zDifference*zDifference)
				local camDistance = 4000
				
				-- set scale (based on camera distance)
				local scale = 1
				if OPTIONS.scaleWithCamera and camZ then
					scale = 0.82 + camDistance / 7500
					gl.Scale(scale,scale,scale)
				end
				local parts = 8
						
				-- base glow
				if baseColor[4] > 0 then
					--local parts = Round(((OPTIONS.baseParts - (camDistance / 800)) + (size / 20)) * scale)
					--if parts < 6 then parts = 6 end
					gl.BeginEnd(GL.TRIANGLE_FAN, DrawBaseGlow, parts, size, r,g,b,a)
				end
				
				-- ring circle:
				if aRing > 0 then
					--local parts = Round(((OPTIONS.ringParts - (camDistance / 800)) + (ringSize / 10)) * scale)
					----parts = parts * (ringSize / (size*OPTIONS.ringScale))		-- this reduces parts when ring is little, but introduces temporary gaps when a part is added
					--if parts < 6 then parts = 6 end
					gl.Color(rRing,gRing,bRing,aRing)
					gl.Scale(ringSize,ringSize,ringSize)
					gl.LineWidth(OPTIONS.ringWidth)
					gl.CallList(circleDrawList)
					--gl.BeginEnd(GL.QUADS, DrawRingCircle, parts, ringSize, ringInnerSize, ringOuterSize, rRing,gRing,bRing,aRing)
				end
				
				-- draw + erase:   nickname / draw icon
				if  playerID  and  playerID ~= ownPlayerID  and  OPTIONS.showMapmarkSpecNames  and   (cmdType == 'map_draw'  or    cmdType == 'map_erase' and  clickOsClock >= mapEraseNicknameTime[playerID]) then
					
					local nickname,_,spec = spGetPlayerInfo(playerID, false)
					if (spec) then
						gl.Color(r,g,b, a * OPTIONS.nicknameOpacityMultiplier)
							
						if OPTIONS.showMapmarkSpecIcons then
							if cmdType == 'map_draw' then
								gl.Texture('LuaUI/Images/commandsfx/pencil.png')
							else
								gl.Texture('LuaUI/Images/commandsfx/eraser.png')
							end
							local iconSize = 11
							gl.BeginEnd(GL.QUADS,DrawGroundquad,iconSize,-iconSize,-iconSize,iconSize)
							gl.Texture(false)
						end
						
						gl.Billboard()
						gl.Text(nickname, 0, -28, 20, "cn")
						
					end
				end
				gl.PopMatrix()
				
			end
		end
	end
	
	gl.LineWidth(1)
	gl.Scale(1,1,1)
	gl.Color(1,1,1,1)
end

