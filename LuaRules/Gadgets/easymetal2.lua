function gadget:GetInfo()
  return {
    name      = "Easy Metal 2",
    desc      = "Right click or right-drag on mex spots to make mex.",
    author    = "CarRepairer",
    date      = "2009-12-28",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
  }
end


if not tobool(Spring.GetModOptions().easymetal)  then
  return
end 

local spGetUnitDefID 			= Spring.GetUnitDefID
local echo 			= Spring.Echo

include("LuaRules/Configs/customcmds.h.lua")
local CMD_INSERT = CMD.INSERT

local mexBuilder = {}

-------------------------------------
if gadgetHandler:IsSyncedCode()then
-------------------------------------
----- SYNCED -----

local spGetGameFrame 			= Spring.GetGameFrame
local spGetUnitPosition 		= Spring.GetUnitPosition
local spGetUnitsInCylinder 		= Spring.GetUnitsInCylinder
local spGetFeaturePosition 		= Spring.GetFeaturePosition
local spValidFeatureID 			= Spring.ValidFeatureID
local spValidUnitID 			= Spring.ValidUnitID
local spGetFeatureDefID 		= Spring.GetFeatureDefID
local spSetUnitBuildSpeed 		= Spring.SetUnitBuildSpeed
local spGetUnitTeam 			= Spring.GetUnitTeam
local spGetGroundHeight			= Spring.GetGroundHeight
local spGetGroundInfo			= Spring.GetGroundInfo
local spGiveOrderToUnit 		= Spring.GiveOrderToUnit
local spGetUnitAllyTeam			= Spring.GetUnitAllyTeam
local spValidUnitID 			= Spring.ValidUnitID
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local floor					= math.floor

local snapDist			= 50
local mexSize			= 25
local mexRad			= Game.extractorRadius > 125 and Game.extractorRadius or 125

local gridSize			= 4
local threshFraction	= 0.4
local metalExtraction	= 0.004

local mapWidth 			= floor(Game.mapSizeX)
local mapHeight 		= floor(Game.mapSizeZ)
local mapWidth2 		= floor(Game.mapSizeX / gridSize)
local mapHeight2 		= floor(Game.mapSizeZ / gridSize)

local metalMap 			= {}
local maxMetal 			= 0
local flagCount			= 0
local metalData 		= {}
local metalDataCount 	= 0

local flags = {}

local mine_ids = {}


local cmds = {}

local mineCmdDesc = {
	id      = CMD_MINE,
	type    = CMDTYPE.ICON_AREA,
	--type    = CMDTYPE.ICON_UNIT_OR_RECTANGLE,
	
	name    = 'Mine',
	action  = 'mine',
	tooltip = 'Build mexes in this area.',
}


local function round(num, idp)
  local mult = 10^(idp or 0)
  return floor(num * mult + 0.5) / mult
end


local function explode(div,str)
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

local function mergeToFlag(flagNum, px, pz, pWeight)
	local fx = flags[flagNum].x
	local fz = flags[flagNum].z
	local fWeight = flags[flagNum].weight
	
	local avgX, avgZ
	
	if fWeight > pWeight then
		local fStrength = round(fWeight / pWeight)
		avgX = (fx*fStrength + px) / (fStrength +1)
		avgZ = (fz*fStrength + pz) / (fStrength +1)
	else
		local pStrength = (pWeight / fWeight)
		avgX = (px*pStrength + fx) / (pStrength +1)
		avgZ = (pz*pStrength + fz) / (pStrength +1)		
	end
	
	flags[flagNum].x = avgX
	flags[flagNum].z = avgZ
	flags[flagNum].weight = fWeight + pWeight
end


local function NearFlag(px, pz, dist)
	for k, flag in pairs(flags) do
		local fx, fz = flag.x, flag.z
		if (px-fx)^2 + (pz-fz)^2 < dist then
			return k
		end
	end
	return false
end


local function AnalyzeMetalMap()	
	for mx_i = 1, mapWidth2 do
		metalMap[mx_i] = {}
		for mz_i = 1, mapHeight2 do
			local mx = mx_i * gridSize
			local mz = mz_i * gridSize
			local _, curMetal = spGetGroundInfo(mx, mz)
			curMetal = floor(curMetal * 100)
			metalMap[mx_i][mz_i] = curMetal
			if (curMetal > maxMetal) then
				maxMetal = curMetal
			end	
		end
	end
	
	local lowMetalThresh = floor(maxMetal * threshFraction)
	
	for mx_i = 1, mapWidth2 do
		for mz_i = 1, mapHeight2 do
			local mCur = metalMap[mx_i][mz_i]
			if mCur > lowMetalThresh then
				metalDataCount = metalDataCount +1
				
				metalData[metalDataCount] = {
					x = mx_i * gridSize,
					z = mz_i * gridSize,
					metal = mCur
				}
				
			end
		end
	end
	
	table.sort(metalData, function(a,b) return a.metal > b.metal end)
	
	for index = 1, metalDataCount do
		
		local mx = metalData[index].x
		local mz = metalData[index].z
		local mCur = metalData[index].metal
		
		local nearFlagNum = NearFlag(mx, mz, mexRad*mexRad)
	
		if nearFlagNum then
			mergeToFlag(nearFlagNum, mx, mz, mCur)
		else
			flagCount = flagCount + 1
			flags[flagCount] = {
				x = mx,
				z = mz,
				weight = mCur
			}
			
		end
	end

end

local function GetFlagsInRadius(x,z,rad)
	local nearflag_ids = {}
	
	for k, flag in pairs(flags) do		
		local fx, fz = flag.x, flag.z
		if (x-fx)^2 + (z-fz)^2 < rad*rad then
			nearflag_ids[#nearflag_ids+1] = k
		end
	end
	return nearflag_ids
end

local function GetFlagsInRect(x1,z1,x2,z2)
	local nearflag_ids = {}
	
	for k, flag in pairs(flags) do		
		local fx, fz = flag.x, flag.z
		if fx > x1 and fx < x2 and fz > z1 and fz < z2 then
			nearflag_ids[#nearflag_ids+1] = k
		end
	end
	return nearflag_ids
end

local function GetOrderedFlagsList( minerID, x,z,rad )
--local function GetOrderedFlagsList( minerID, x1,z1,x2,z2 )
	if not flags then return false end
	
	local nearflag_ids = GetFlagsInRadius(x,z,rad)
	--local nearflag_ids = GetFlagsInRect(x1,z1,x2,z2)
	
	local mx, my, mz = Spring.GetUnitPosition(minerID)
	
	local mines = {}
	local mines_i = {}

	local shortestDist = math.huge
	local shortestID = -1
	
	for _,flagID in ipairs(nearflag_ids) do
		local flag = flags[flagID]
		local dist = (mx - flag.x)^2 + (mz - flag.z)^2 
		
		if dist < shortestDist then
			shortestID = flagID
			shortestDist = dist
		end
	end
	if shortestID == -1 then
		return {}
	end
	mines[shortestID] = true
	mines_i[1] = shortestID
	
	
	local lastID = shortestID
	for i = 1, #nearflag_ids-1 do
		shortestDist = math.huge
		for _,flagID in ipairs(nearflag_ids) do
			if not mines[flagID] then
				local flag = flags[flagID]
				local lflag = flags[lastID]
				local dist = (lflag.x - flag.x)^2 + (lflag.z - flag.z)^2
				if dist < shortestDist then
					shortestID = flagID
					shortestDist = dist
				end
			end
		end
		lastID = shortestID
		mines[shortestID] = true
		mines_i[#mines_i+1] = shortestID
	end
	
	return mines_i
end

function gadget:UnitCreated(unitID, udid, unitTeam)
	if UnitDefs[udid] and UnitDefs[udid].builder and UnitDefs[udid].speed > 0 then
		Spring.InsertUnitCmdDesc(unitID, 12345, mineCmdDesc)
	end
end

function gadget:Initialize()
	
	AnalyzeMetalMap()
	local allUnits = Spring.GetAllUnits()
	for _, unitID in pairs(allUnits) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
	end
	
	
	_G.flags = flags
	
end

function gadget:AllowCommand(unitID,udid,team,cmd,param,opt)
	if cmd == CMD_MINE then
		if #param == 3 or #param == 4 then
		--if #param == 3 or #param == 6 then
		
		
			local opts = {}
			if (opt.shift) then table.insert(opts, "shift")   end
			if (opt.alt)   then table.insert(opts, "alt")   end
			if (opt.ctrl)  then table.insert(opts, "ctrl")  end
			if (opt.right) then table.insert(opts, "right") end
			
			
			--local rad = param[4] or 200
			local rad = param[4]
			
			for i, option in ipairs(UnitDefs[udid].buildOptions) do 
				if option == UnitDefNames['armmex'].id then
					mex_cmd = 0 - UnitDefNames['armmex'].id
				elseif option == UnitDefNames['cormex'].id then
					mex_cmd = 0 - UnitDefNames['cormex'].id
				end
			end
		
			--
			local nearflag_ids = GetOrderedFlagsList( unitID, param[1], param[3], rad )
			--[[
			local x1, z1, x2, z2
			
			if #param == 3 then
				x1=param[1]
				z1=param[3]
				
				x2=param[1]
				z2=param[3]
				echo 'aaaa'
			else
				if param[1] < param[4] then
					x1 = param[1]
					x2 = param[4]
				else
					x1 = param[4]
					x2 = param[1]
				end
				if param[3] < param[6] then
					z1 = param[3]
					z2 = param[6]
				else
					z1 = param[6]
					z2 = param[3]
				end
			end
			
			local nearflag_ids = GetOrderedFlagsList( unitID, x1-snapDist,z1-snapDist, x2+snapDist,z2+snapDist)
			--]]
			local first, queued = true, false
			for _,nearflag_id in ipairs(nearflag_ids) do
				local nearflag = flags[nearflag_id]
				if not (first or queued) then
					table.insert(opts, "shift")
					queued = true
				end
				first = false
				
				--spGiveOrderToUnit(unitID, mex_cmd, {nearflag.x,0,nearflag.z}, opts)
				cmds[#cmds+1] = {unitID, mex_cmd, {nearflag.x,0,nearflag.z}, opts}
			end
		end
		return false
	end
	
	return true
end
-- [[
function gadget:RecvLuaMsg(msg, playerID)
	if msg:find("mine:",1,true) then
		
		local flagID = msg:match('.*:(.*)$.*')+0
		local optsstr = msg:match('.*$(.*)|.*')
		local unitIDs_str = msg:match('.*|(.*)')
		
		local unitIDs = explode('^', unitIDs_str)
		
		local _,_,spec,teamID = Spring.GetPlayerInfo(playerID)
		
		if spec then return end
		
		for _,unitID in ipairs(unitIDs) do
			local unitTeam = Spring.GetUnitTeam(unitID)
			if teamID ~= unitTeam then
				echo('Player ' .. playerID .. ' sent a spoof.')
				return
			end
		end
		
		local opts = {}
		if (optsstr:find('s')) then table.insert(opts, "shift") end
		if (optsstr:find('a')) then table.insert(opts, "alt")   end
		if (optsstr:find('c')) then table.insert(opts, "ctrl")  end
		if (optsstr:find('m')) then table.insert(opts, "meta") end
		
		local flag = flags[flagID]
		--spGiveOrderToUnit(unitID, CMD_MINE, {flag.x,0,flag.z, 400}, opts)
		
		for _,unitID in ipairs(unitIDs) do
			if spValidUnitID(unitID) then
				cmds[#cmds+1] = {unitID, CMD_MINE, {flag.x,0,flag.z, 100}, opts}
			end
		end
	end
end
--]]
function gadget:GameFrame(f)
	for _, cmd in ipairs(cmds) do
		spGiveOrderToUnit(cmd[1], cmd[2], cmd[3], cmd[4])
	end
	cmds = {}
end

----- SYNCED -----
-------------------------------------
else
-------------------------------------
----- UNSYNCED -----

local spTraceScreenRay 	= Spring.TraceScreenRay
local spGetMouseState 	= Spring.GetMouseState
local spGetModKeyState 	= Spring.GetModKeyState

local flags, hoverFlagNum, clickcheck
local cycle = 1
local icon_size = 20
local icon_offset = 30

local function NearFlag(px, pz, dist)
	if not flags then return false end
	for k, flag in spairs(flags) do		
		local fx, fz = flag.x, flag.z
		if (px-fx)^2 + (pz-fz)^2 < dist then
			return k
		end
	end
	return false
end

function gadget:DefaultCommand(type,id)
	if not type and hoverFlagNum then
		return CMD_MINE
	end
end

function gadget:Update()
	cycle = cycle % 16 + 1
	if cycle == 1 then
	
		local selUnits = Spring.GetSelectedUnits()
		if selUnits and #selUnits > 0 then
		
			local builderSelected = false		
			for i = 1, #selUnits do
				local udid = Spring.GetUnitDefID(selUnits[i])
				if UnitDefs[udid] and UnitDefs[udid].builder and UnitDefs[udid].speed then
					builderSelected = true
					break
				end
			end
			
			if builderSelected == false then
				return
			end
			
			if not flags then
				flags = SYNCED.flags
			end
			local mx,my, lb, mb, rb = spGetMouseState()
			local _, pos = spTraceScreenRay(mx, my, true)
			hoverFlagNum = pos and NearFlag(pos[1],pos[3], 5000)
			
			
			-- [[
			if clickcheck and not rb then
				if clickcheck == hoverFlagNum then
					local alt,ctrl,meta,shift = spGetModKeyState()
					
					local selUnitsStr = ''
						
					for _,unitID in ipairs(selUnits) do
						selUnitsStr = selUnitsStr .. unitID .. '^'
					end
						
					local optsstr = ''
					
					if (shift) then optsstr = optsstr .. 's' end
					if (alt)   then optsstr = optsstr .. 'a' end
					if (ctrl)  then optsstr = optsstr .. 'c' end
					if (meta) then optsstr = optsstr .. 'm' end
					Spring.SendLuaRulesMsg('mine:' .. hoverFlagNum .. '$' .. optsstr .. '|' .. selUnitsStr:sub(1,-2))
				end
			end
			clickcheck = false
		end
		--]]
	end
end

-- [[
function gadget:MousePress(x,y,button)
	if hoverFlagNum and button == 3 then
		clickcheck = hoverFlagNum
	else
		clickcheck = false
	end
	
end
--]]
LUAUI_DIRNAME = 'LuaUI/'
function gadget:DrawScreen()
	if hoverFlagNum then
		local mx,my  = spGetMouseState()
		local filefound = gl.Texture(LUAUI_DIRNAME .. 'Images/ibeam.png')
		if filefound then
			gl.TexRect(mx-icon_size + icon_offset, my-icon_size- icon_offset, mx+icon_size + icon_offset, my+icon_size - icon_offset)
		end
		gl.Texture(false)	
	end
end
----- UNSYNCED -----
-------------------------------------
end
