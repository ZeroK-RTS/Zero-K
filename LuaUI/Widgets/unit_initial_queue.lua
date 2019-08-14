local version = "v1.544"
function widget:GetInfo()
	return {
		name      = "Initial Queue ZK",
		desc      = version .. " Allows you to queue buildings before game start",
		author    = "Niobium, KingRaptor",
		date      = "7 April 2010",
		license   = "GNU GPL, v2 or later",
		layer     = -1, -- Puts it below cmd_mex_placement.lua, to catch mex placement order before the cmd_mex_placement.lua does.
		enabled   = true,
		handler   = true
	}
end
-- 12 jun 2012: "uDef.isMetalExtractor" was replaced by "uDef.extractsMetal > 0" to fix "metal" mode map switching (by [teh]decay, thx to vbs and Beherith)
-- 20 march 2013: added keyboard support with BA keybinds (Bluestone)
-- august 2013: send queue length to cmd_idle_players (BrainDamage)

--TODO: find way to detect GameStart countdown, so that we can remove button before GameStart (not after gamestart) since it will cause duplicate button error.
------------------------------------------------------------
-- Config
------------------------------------------------------------
local buildOptions = VFS.Include("gamedata/buildoptions.lua")

local MAX_QUEUE = 30
local REDCHAR = string.char(255,255,64,32)

-- Colors
local buildDistanceColor = {0.3, 1.0, 0.3, 0.7}
local buildLinesColor = {0.3, 1.0, 0.3, 0.7}
local borderNormalColor = {0.3, 1.0, 0.3, 0.5}
local borderClashColor = {0.7, 0.3, 0.3, 1.0}
local borderValidColor = {0.0, 1.0, 0.0, 1.0}
local borderInvalidColor = {1.0, 0.0, 0.0, 1.0}
local buildingQueuedAlpha = 0.5

local metalColor = '\255\196\196\255' -- Light blue
local energyColor = '\255\255\255\128' -- Light yellow
local buildColor = '\255\128\255\128' -- Light green
local whiteColor = '\255\255\255\255' -- White

local fontSize = 20

------------------------------------------------------------
-- Globals
------------------------------------------------------------
local myTeamID = Spring.GetMyTeamID()
local myPlayerID = Spring.GetMyPlayerID()

local sDefID = Spring.GetTeamRulesParam(myTeamID, "commChoice") or UnitDefNames.dyntrainer_strike_base.id-- Starting unit def ID
local sDef = UnitDefs[sDefID]
local buildDistance = sDef.buildDistance

local selDefID = nil -- Currently selected def ID
local buildQueue = {}
local buildNameToID = {}
local gameStarted = false
local othersBuildQueue = {}

local isMex = {} -- isMex[uDefID] = true / nil
local weaponRange = {} -- weaponRange[uDefID] = # / nil

local changeStartUnitRegex = '^\138(%d+)$'
local startUnitParamName = 'startUnit'

local scrW, scrH = Spring.GetViewGeometry()

local mCost, eCost, bCost, buildTime = 0, 0, 0, 0

local CMD_STOP = CMD.STOP

------------------------------------------------------------
-- Local functions
------------------------------------------------------------
local function GetBuildingDimensions(uDefID, facing)
	local bDef = UnitDefs[uDefID]
	if (facing % 2 == 1) then
		return 4 * bDef.zsize, 4 * bDef.xsize
	else
		return 4 * bDef.xsize, 4 * bDef.zsize
	end
end
local function DrawBuilding(buildData, borderColor, buildingAlpha, drawRanges,teamID,drawSelectionBox)

	local bDefID, bx, by, bz, facing = buildData[1], buildData[2], buildData[3], buildData[4], buildData[5]
	local bw, bh = GetBuildingDimensions(bDefID, facing)

	gl.DepthTest(false)
	gl.Color(borderColor)

	if drawSelectionBox then
		gl.Shape(GL.LINE_LOOP, {{v={bx - bw, by, bz - bh}},
								{v={bx + bw, by, bz - bh}},
								{v={bx + bw, by, bz + bh}},
								{v={bx - bw, by, bz + bh}}})
	end

	if drawRanges then
		--[[
		if isMex[bDefID] then
			gl.Color(1.0, 0.3, 0.3, 0.7)
			gl.DrawGroundCircle(bx, by, bz, Game.extractorRadius, 40)
		end
		]]

		local wRange = weaponRange[bDefID]
		if wRange then
			gl.Color(1.0, 0.3, 0.3, 0.7)
			gl.DrawGroundCircle(bx, by, bz, wRange, 40)
		end
	end

	gl.DepthTest(GL.LEQUAL)
	gl.DepthMask(true)
	if buildingAlpha == 1 then gl.Lighting(true) end
	gl.Color(1.0, 1.0, 1.0, buildingAlpha)

	gl.PushMatrix()
		gl.LoadIdentity()
		gl.Translate(bx, by, bz)
		gl.Rotate(90 * facing, 0, 1, 0)
		gl.Texture("%"..bDefID..":0") --.s3o texture atlas for .s3o model
		gl.UnitShape(bDefID, teamID, false, false, false)
		gl.Texture(false)
	gl.PopMatrix()

	gl.Lighting(false)
	gl.DepthTest(false)
	gl.DepthMask(false)
end
local function DrawUnitDef(uDefID, uTeam, ux, uy, uz, rot)

	gl.Color(1.0, 1.0, 1.0, 1.0)
	gl.DepthTest(GL.LEQUAL)
	gl.DepthMask(true)
	gl.Lighting(true)

	gl.PushMatrix()
		gl.LoadIdentity()
		gl.Translate(ux, uy, uz)
		gl.Rotate(rot, 0, 1, 0)
		gl.UnitShape(uDefID, uTeam, false, false, true)
	gl.PopMatrix()

	gl.Lighting(false)
	gl.DepthTest(false)
	gl.DepthMask(false)
end
local function DoBuildingsClash(buildData1, buildData2)

	local w1, h1 = GetBuildingDimensions(buildData1[1], buildData1[5])
	local w2, h2 = GetBuildingDimensions(buildData2[1], buildData2[5])

	return math.abs(buildData1[2] - buildData2[2]) < w1 + w2 and
	       math.abs(buildData1[4] - buildData2[4]) < h1 + h2
end
local function SetSelDefID(defID)
	selDefID = defID

	-- if (isMex[selDefID] ~= nil) ~= (Spring.GetMapDrawMode() == "metal") then
		-- Spring.SendCommands("ShowMetalMap")
	-- end
	-- if defID then
		-- Spring.SetActiveCommand(defID)
	-- end
end

local function GetSelDefID(defID)
	return selDefID
end

local function GetUnitCanCompleteQueue(uID)

	local uDefID = Spring.GetUnitDefID(uID)
	if uDefID == sDefID then
		return true
	end

	-- What can this unit build ?
	local uCanBuild = {}
	local uBuilds = UnitDefs[uDefID].buildOptions
	for i = 1, #uBuilds do
		uCanBuild[uBuilds[i]] = true
	end

	-- Can it build everything that was queued ?
	for i = 1, #buildQueue do
		if not uCanBuild[buildQueue[i][1]] then
			return false
		end
	end

	return true
end
local function GetQueueBuildTime()
	local t = 0
	for i = 1, #buildQueue do
		t = t + UnitDefs[buildQueue[i][1]].buildTime
	end
	return t / sDef.buildSpeed
end
local function GetQueueCosts()
	local mCost = 0
	local eCost = 0
	local bCost = 0
	for i = 1, #buildQueue do
		local uDef = UnitDefs[buildQueue[i][1]]
		mCost = mCost + uDef.metalCost
		eCost = eCost + uDef.energyCost
		bCost = bCost + uDef.buildTime
	end
	return mCost, eCost, bCost
end

local function GetBuildOptions()
	return buildOptions
end
------------------------------------------------------------
-- Initialize/shutdown
------------------------------------------------------------

local function GetUnlockedBuildOptions(fullOptions)
	local teamID = Spring.GetMyTeamID()
	local unlockedCount = Spring.GetTeamRulesParam(teamID, "unlockedUnitCount")
	if not unlockedCount then
		return fullOptions
	end
	local unlockedMap = {}
	for i = 1, unlockedCount do
		local unitDefID = Spring.GetTeamRulesParam(teamID, "unlockedUnit" .. i)
		if unitDefID then
			unlockedMap[unitDefID] = true
		end
	end
	local newOptions = {}
	for i = 1, #fullOptions do
		if unlockedMap[fullOptions[i]] then
			newOptions[#newOptions + 1] = fullOptions[i]
		end
	end
	return newOptions
end

function widget:Initialize()
	if (Spring.GetGameFrame() > 0) then		-- Don't run if game has already started
		Spring.Echo("Game already started or Start Position is randomized. Removed: Initial Queue ZK") --added this message because widget removed message might not appear (make debugging harder)
		widgetHandler:RemoveWidget(self)
		return
	end
	if Spring.GetModOptions().singleplayercampaignbattleid then -- Don't run in campaign battles.
		widgetHandler:RemoveWidget(self)
		return
	end
	for uDefID, uDef in pairs(UnitDefs) do
		if uDef.customParams.ismex then
			isMex[uDefID] = true
		end

		if uDef.maxWeaponRange > 16 then
			weaponRange[uDefID] = uDef.maxWeaponRange
		end
	end
	if UnitDefNames["staticmex"] then
		isMex[UnitDefNames["staticmex"].id] = true;
	end
	WG.InitialQueue = true
	
	buildOptions = GetUnlockedBuildOptions(buildOptions)
end

function widget:Shutdown()
	WG.InitialQueue = nil
end

------------------------------------------------------------
-- Drawing
------------------------------------------------------------
--local queueTimeFormat = whiteColor .. 'Queued: ' .. buildColor .. '%.1f sec ' .. whiteColor .. '[' .. metalColor .. '%d m' .. whiteColor .. ', ' .. energyColor .. '%d e' .. whiteColor .. ']'
local queueTimeFormat = whiteColor .. 'Queued ' .. metalColor .. '%dm ' .. buildColor .. '%.1f sec'
--local queueTimeFormat = metalColor .. '%dm ' .. whiteColor .. '/ ' .. energyColor .. '%de ' .. whiteColor .. '/ ' .. buildColor .. '%.1f sec'


-- "Queued 23.9 seconds (820m / 2012e)" (I think this one is the best. Time first emphasises point and goodness of widget)
	-- Also, it is written like english and reads well, none of this colon stuff or figures stacked together

local timer = 0
local updateFreq = 0.15

-- check if we're chosen a new comm

function widget:Update(dt)
	timer = timer + dt
	if timer > updateFreq then
		local defID = Spring.GetTeamRulesParam(myTeamID, "commChoice")
		if defID and defID ~= sDefID then
			local def = UnitDefs[defID]
			if def then
				sDefID = defID
				sDef = def
				buildDistance = sDef.buildDistance
				mCost, eCost, bCost = GetQueueCosts()
				buildTime = bCost / sDef.buildSpeed
			end
		end
		timer = 0
	end
end

function widget:DrawScreen()
	gl.PushMatrix()
	gl.Translate(scrW*0.4, scrH*0.35, 0)
	local num = #buildQueue
	if num > 0 then
		--gl.Text(string.format(queueTimeFormat, mCost, buildTime), 0, 0, fontSize, 'cdo')
		local str = "Queue: " .. num .. "/" .. MAX_QUEUE
		if num >= MAX_QUEUE then
			str = REDCHAR .. str
		end
		gl.Text(str, 0, 0, fontSize, 'cdo')
	end
	gl.PopMatrix()
end

local function DrawWorldFunc()
	--don't draw anything once the game has started; after that engine can draw queues itself
	if gameStarted then
		return
	end

	-- local clash = false
	
	-- Set up gl
	gl.LineWidth(1.49)

	-- We need data about currently selected building, for drawing clashes etc
	local selBuildData
	if selDefID then
		local mx, my = Spring.GetMouseState()
		local _, pos = Spring.TraceScreenRay(mx, my, true)
		if pos then
			local bx, by, bz = Spring.Pos2BuildPos(selDefID, pos[1], pos[2], pos[3])
			local buildFacing = Spring.GetBuildFacing()
			selBuildData = {selDefID, bx, by, bz, buildFacing}
		end
	end
	
	-- local myTeamID = Spring.GetMyTeamID()
	local sx, sy, sz = Spring.GetTeamStartPosition(myTeamID) -- Returns -100, -100, -100 when none chosen
	local startChosen = (sx > 0)
	if startChosen then
		-- Correction for start positions in the air
		sy = Spring.GetGroundHeight(sx, sz)

		-- Draw the starting unit at start position
		local rot = (math.abs(Game.mapSizeX/2 - sx) > math.abs(Game.mapSizeZ/2 - sz))
			and ((sx>Game.mapSizeX/2) and 270 or 90)
			or ((sz>Game.mapSizeZ/2) and 180 or 0)
		DrawUnitDef(sDefID, myTeamID, sx, sy, sz, rot)

		-- Draw start units build radius
		gl.Color(buildDistanceColor)
		gl.DrawGroundCircle(sx, sy, sz, buildDistance, 40)
	end

	-- Draw all the buildings
	local queueLineVerts = startChosen and {{v={sx, sy, sz}}} or {}
	for b = 1, #buildQueue do
		local buildData = buildQueue[b]
		--[[
		if selBuildData and DoBuildingsClash(selBuildData, buildData) then
			DrawBuilding(buildData, borderClashColor, buildingQueuedAlpha,false,myTeamID,true)
			clash = true
		end
		--]]
		--else
			DrawBuilding(buildData, borderNormalColor, buildingQueuedAlpha,false,myTeamID,true)
		--end
		
		queueLineVerts[#queueLineVerts + 1] = {v={buildData[2], buildData[3], buildData[4]}}
	end

	-- Draw queue lines
	gl.Color(buildLinesColor)
	gl.LineStipple("springdefault")
	gl.Shape(GL.LINE_STRIP, queueLineVerts)
	gl.LineStipple(false)

	for teamID,playerXBuildQueue in pairs(othersBuildQueue)do
		sx, sy, sz = Spring.GetTeamStartPosition(teamID) -- Returns -100, -100, -100 when none chosen
		startChosen = sx and (sx > 0)

		-- Draw all the buildings
		queueLineVerts = startChosen and {{v={sx, sy, sz}}} or {}
		for b = 1, #playerXBuildQueue do
			local buildData = playerXBuildQueue[b]
			DrawBuilding(buildData, borderNormalColor, buildingQueuedAlpha,false,teamID,false)
			queueLineVerts[#queueLineVerts + 1] = {v={buildData[2], buildData[3], buildData[4]}}
		end
		-- Draw queue lines
		gl.Color(buildLinesColor)
		gl.LineStipple("springdefault")
		gl.Shape(GL.LINE_STRIP, queueLineVerts)
		gl.LineStipple(false)
	end
	
	-- Draw selected building
	--[[
	if selBuildData then
		if (not clash) and Spring.TestBuildOrder(selDefID, selBuildData[2], selBuildData[3], selBuildData[4], selBuildData[5]) ~= 0 then
			DrawBuilding(selBuildData, borderValidColor, 1.0, true,myTeamID,true)
		else
			DrawBuilding(selBuildData, borderInvalidColor, 1.0, true,myTeamID,true)
		end
	end
	--]]

	-- Reset gl
	gl.Color(1.0, 1.0, 1.0, 1.0)
	gl.LineWidth(1.0)
end

function widget:DrawWorld()
	DrawWorldFunc()
end
function widget:DrawWorldRefraction()
	DrawWorldFunc()
end

function widget:ViewResize(vsx, vsy)
	scrW = vsx
	scrH = vsy
end

local function explode(div,str) --copied from gui_epicmenu.lua
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end

function widget:RecvLuaMsg(msg, playerID)
	if myPlayerID~=playerID and msg:sub(1,3) == "IQ|" then
		--Example: IQ|4|404|648|2|3304|1
		--Header|unitdefID|x|y|z|facing
		msg = msg:sub(4)
		local msgArray = explode('|',msg)
		local typeArg, unitDefID = tonumber(msgArray[1]), tonumber(msgArray[2])
		if typeArg == 5 then -- Cancel queue
			local teamID = select(4,Spring.GetPlayerInfo(playerID, false))
			othersBuildQueue[teamID] = {}
			return
		end
		if not UnitDefs[unitDefID] or typeArg > 5 or typeArg < 1 then
			return --invalid unitDefID and message type
		end
		local x,y,z,face = tonumber(msgArray[3]),tonumber(msgArray[4]),tonumber(msgArray[5]),tonumber(msgArray[6])
		if not (x and y and z and face) then
			return --invalid coordinate and facing
		end
		local teamID = select(4,Spring.GetPlayerInfo(playerID, false))
		othersBuildQueue[teamID] = othersBuildQueue[teamID] or {}
		local playerXBuildQueue = othersBuildQueue[teamID]
		if typeArg == 1 then
			table.insert(playerXBuildQueue, 1, {unitDefID,x,y,z,face})
		elseif typeArg == 2 then
			table.remove(playerXBuildQueue, unitDefID)
		elseif typeArg == 3 then
			playerXBuildQueue[#playerXBuildQueue+1] = {unitDefID,x,y,z,face}
		elseif typeArg == 4 then
			othersBuildQueue[teamID] = {{unitDefID,x,y,z,face}}
		end
	end
end

------------------------------------------------------------
-- Game start
------------------------------------------------------------

function widget:GameFrame(n)

	if not gameStarted then
		gameStarted = true
	end

	-- Don't run if we are a spec
	local areSpec = Spring.GetSpectatingState()
	if areSpec then
		widgetHandler:RemoveWidget(self)
		return
	end
	
	-- Don't run if we didn't queue anything
	if (#buildQueue == 0) then
		widgetHandler:RemoveWidget(self)
		return
	end

	if (n < 2) then return end -- Give the unit frames 0 and 1 to spawn
	
	--inform gadget how long is our queue
	local buildTime = GetQueueBuildTime()
	--Spring.SendCommands("luarules initialQueueTime " .. buildTime)
	
	if (n == 4) then
		--Spring.Echo("> Starting unit never spawned !")
		widgetHandler:RemoveWidget(self)
		return
	end
	
	local tasker
	-- Search for our starting unit
	local units = Spring.GetTeamUnits(Spring.GetMyTeamID())
	for u = 1, #units do
		local uID = units[u]
		if GetUnitCanCompleteQueue(uID) then --Spring.GetUnitDefID(uID) == sDefID then
			--we found our com, assigning queue to this particular unit
			tasker = uID
			break
		end
	end
	if tasker then
		--Spring.Echo("sending queue to unit")
		-- notify other widgets that we're giving orders to the commander.
		if WG.GlobalBuildCommand then WG.GlobalBuildCommand.CommandNotifyPreQue(tasker) end
		
		for b = 1, #buildQueue do
			local buildData = buildQueue[b]
			Spring.GiveOrderToUnit(tasker, -buildData[1], {buildData[2], buildData[3], buildData[4], buildData[5]}, CMD.OPT_SHIFT)
		end
		if selDefID and UnitDefs[selDefID] and UnitDefs[selDefID].name then
			WG.InitialActiveCommand = "buildunit_" .. UnitDefs[selDefID].name
		end
		widgetHandler:RemoveWidget(self)
	end
	
end

------------------------------------------------------------
-- Mouse
------------------------------------------------------------
--[[
--Task handled by CommandNotify()
function widget:MousePress(mx, my, mButton)
	if selDefID then
		if mButton == 1 then
			local mx, my = Spring.GetMouseState()
			local _, pos = Spring.TraceScreenRay(mx, my, true)
			if not pos then return end
			local bx, by, bz = Spring.Pos2BuildPos(selDefID, pos[1], pos[2], pos[3])

			if isMex[selDefID] then
				local bestSpot = WG.GetClosestMetalSpot(bx, bz)
				bx, by, bz = bestSpot.x, bestSpot.y, bestSpot.z
			end
			local buildFacing = Spring.GetBuildFacing()
	
			if Spring.TestBuildOrder(selDefID, bx, by, bz, buildFacing) ~= 0 then
	
				local buildData = {selDefID, bx, by, bz, buildFacing}
				local _, _, meta, shift = Spring.GetModKeyState()
				if meta then
					table.insert(buildQueue, 1, buildData)
	
				elseif shift then
	
					local anyClashes = false
					for i = #buildQueue, 1, -1 do
						if DoBuildingsClash(buildData, buildQueue[i]) then
							anyClashes = true
							table.remove(buildQueue, i)
						end
					end
	
					if not anyClashes then
						buildQueue[#buildQueue + 1] = buildData
					end
				else
					buildQueue = {buildData}
				end
				
				mCost, eCost, bCost = GetQueueCosts()
				buildTime = bCost / sDef.buildSpeed
	
				if not shift then
					SetSelDefID(nil)
				end
			end
	
			return true
	
		elseif mButton == 3 then
			SetSelDefID(nil)
			return true
		end
	end
end
function widget:MouseMove(mx, my, dx, dy, mButton)
	if areDragging then
		wl = wl + dx
		wt = wt + dy
	end
end
function widget:MouseRelease(mx, my, mButton)
	areDragging = false
end
--]]
------------------------------------------------------------
-- Command Button
------------------------------------------------------------
function widget:CommandsChanged()
	if (gameStarted) then
		return
	end
	for i=1, #buildOptions do
		local unitName = buildOptions[i]
		if not Spring.GetGameRulesParam("disabled_unit_" .. unitName) then
			table.insert(widgetHandler.customCommands, {
				id      = -1*UnitDefNames[unitName].id,
				type    = 20,
				tooltip = "Build: " .. UnitDefNames[unitName].humanName .. " - " .. UnitDefNames[unitName].tooltip,
				cursor  = unitName,
				action  = "buildunit_" .. unitName,
				params  = {},
				texture = "", --"#"..id,
				name = unitName,
			})
		end
	end
	table.insert(widgetHandler.customCommands, {
		id      = CMD_STOP,
		type    = CMDTYPE.ICON,
		tooltip = "Stop",
		action  = "stop",
		params  = {},
	})
end

local function GetClosestMetalSpot(x, z) --is used by single mex placement, not used by areamex
	local bestSpot
	local bestDist = math.huge
	local bestIndex
	for i = 1, #WG.metalSpots do
		local spot = WG.metalSpots[i]
		local dx, dz = x - spot.x, z - spot.z
		local dist = dx*dx + dz*dz
		if dist < bestDist then
			bestSpot = spot
			bestDist = dist
			bestIndex = i
		end
	end
	return bestSpot
end

local function CancelQueue()
	buildQueue = {}
	Spring.SendLuaUIMsg("IQ|5",'a')
	Spring.SendLuaUIMsg("IQ|5",'s')
	mCost, eCost, bCost = GetQueueCosts()
	buildTime = bCost / sDef.buildSpeed
end


function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	local areSpec = Spring.GetSpectatingState()
	if areSpec then
		return false
	end
	if cmdID == CMD_STOP then
		-- This only handles pressing the stop button in integral menu.
		CancelQueue()
		return true
	end
	if cmdID >= 0 or not(cmdParams[1] and cmdParams[2] and cmdParams[3]) then --can't handle other command.
		return false
	end
	SetSelDefID(-1*cmdID)
	local bx,by,bz = cmdParams[1],cmdParams[2],cmdParams[3]
	local buildFacing = Spring.GetBuildFacing()
	local msg, msg2
	
	local function CheckClash(buildData)
		for i = #buildQueue, 1, -1 do
			if DoBuildingsClash(buildData, buildQueue[i]) then
				table.remove(buildQueue, i)
				msg = "IQ|2|"..i
				return true
			end
		end
	end
	
	if Spring.TestBuildOrder(selDefID, bx, by, bz, buildFacing) ~= 0 then
		if isMex[selDefID] and WG.metalSpots then
			local bestSpot = GetClosestMetalSpot(bx, bz)
			bx, bz = bestSpot.x, bestSpot.z
			by = math.max(0, Spring.GetGroundHeight(bx, bz))
		end
		local buildData = {selDefID, bx, by, bz, buildFacing}
		
		if cmdOptions.meta then	-- space insert at front
			local anyClashes = CheckClash(buildData)
			if not anyClashes then
				table.insert(buildQueue, 1, buildData)
				msg = "IQ|1|"..selDefID.."|"..math.modf(bx).."|"..math.modf(by).."|"..math.modf(bz).."|"..buildFacing
				if (buildQueue[MAX_QUEUE + 1] ~= nil) then	-- exceeded max queue, remove the one at the end
					table.remove(buildQueue, MAX_QUEUE + 1)
					msg2 = msg
					msg = "IQ|2|".. (MAX_QUEUE + 1)
				end
			end
		elseif cmdOptions.shift then	-- shift-queue
			local anyClashes = CheckClash(buildData)
			if not anyClashes then
				if #buildQueue < MAX_QUEUE then	-- disallow if already reached max queue
					buildQueue[#buildQueue + 1] = buildData
					msg = "IQ|3|"..selDefID.."|"..math.modf(bx).."|"..math.modf(by).."|"..math.modf(bz).."|"..buildFacing
				end
			end
		else	-- normal build
			buildQueue = {buildData}
			msg = "IQ|4|"..selDefID.."|"..math.modf(bx).."|"..math.modf(by).."|"..math.modf(bz).."|"..buildFacing
			--msg = "IQ|4|404|648|2|3304|1" --example spoof. This will not work
		end
		if msg then
			Spring.SendLuaUIMsg(msg,'a')
			Spring.SendLuaUIMsg(msg,'s') --need 2 msg because since Spring 97 LuaUIMsg without parameter is send info to EVERYONE (including enemy)
		end
		if msg2 then
			Spring.SendLuaUIMsg(msg2,'a')
			Spring.SendLuaUIMsg(msg2,'s')
		end
		
		mCost, eCost, bCost = GetQueueCosts()
		buildTime = bCost / sDef.buildSpeed

		SetSelDefID(nil)
		return true
	end
	return false
end

------------------------------------------------------------
-- Misc
------------------------------------------------------------
function widget:TextCommand(cmd)
	-- Facing commands are only handled by spring if we have a building selected, which isn't possible pre-game
	local m = cmd:match("^buildfacing (.+)$")
	if m then

		local oldFacing = Spring.GetBuildFacing()
		local newFacing
		if (m == "inc") then
			newFacing = (oldFacing + 1) % 4
		elseif (m == "dec") then
			newFacing = (oldFacing + 3) % 4
		else
			return false
		end

		Spring.SetBuildFacing(newFacing)
		Spring.Echo("Buildings set to face " .. ({"South", "East", "North", "West"})[1 + newFacing])
		return true
	end
	local buildName = cmd:match("^buildunit_([^%s]+)$")
	if buildName then
		local bDefID = buildNameToID[buildName]
		if bDefID then
			SetSelDefID(bDefID)
			return true
		end
	end
	if cmd == "stop" then
		-- This only handles the stop hotkey
		CancelQueue()
	end
end
