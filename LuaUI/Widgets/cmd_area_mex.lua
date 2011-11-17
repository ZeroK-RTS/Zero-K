local versionNumber = "v2.201"

function widget:GetInfo()
  return {
    name      = "Area Mex",
    desc      = versionNumber .. " Adds a command to cap mexes in an area.",
    author    = "Google Frog, NTG (file handling)",
    date      = "Feb 5, 2009",
    license   = "GNU GPL, v2 or later",
    handler   = true,
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

local maxMetalData = 250000
local pathToSave = "LuaUI/Configs/MetalMaps/" -- where to store mexmaps

-----------------
--command notification and mex placement

local CMD_AREA_MEX  = 10100
local CMD_OPT_SHIFT = CMD.OPT_SHIFT

local spGetSelectedUnits = Spring.GetSelectedUnits
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetUnitPosition = Spring.GetUnitPosition 
local spGetTeamUnits = Spring.GetTeamUnits
local spGetMyTeamID = Spring.GetMyTeamID
local spGetUnitDefID = Spring.GetUnitDefID
local team = Spring.GetMyTeamID()
local spTestBuildOrder = Spring.TestBuildOrder

local sqrt = math.sqrt
local tasort = table.sort
local taremove = table.remove

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Analyze the mod for mexes and builders

local mexes = {}
local mexBuilder = {}

local mexIds = {}
for udid, ud in ipairs(UnitDefs) do
	if (ud.extractsMetal > 0) then
		mexIds[udid] = udid
	end
end

local mexBuilderDefs = {}
for udid, ud in ipairs(UnitDefs) do 
	for i, option in ipairs(ud.buildOptions) do 
		if mexIds[option] then
			if mexBuilderDefs[udid] then
				mexBuilderDefs[udid][#mexBuilderDefs[udid] + 1] = -mexIds[option]
			else
				mexBuilderDefs[udid] = {-mexIds[option]}
			end
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function Distance(x1,z1,x2,z2)
	local dis = (x1-x2)*(x1-x2)+(z1-z2)*(z1-z2)
	return dis
end


function widget:UnitCreated(unitID, unitDefID)
	local mbdef = mexBuilderDefs[unitDefID]
	if (mbdef) then
		mexBuilder[unitID] = mbdef
	end
end


function widget:CommandNotify(id, params, options)	
	
	if (id == CMD_AREA_MEX) then
	
		local cx, cy, cz, cr = params[1], params[2], params[3], params[4]
		
		local xmin = cx-cr
		local xmax = cx+cr
		local zmin = cz-cr
		local zmax = cz+cr
		
		local commands = {}
		local orderedCommands = {}
		local dis = {}
		
		local ux = 0
		local uz = 0
		local us = 0
		
		local aveX = 0
		local aveZ = 0
		
		local units=spGetSelectedUnits()
	
		for i, id in pairs(units) do 
			if mexBuilder[id] then
				local x,_,z = spGetUnitPosition(id)
				ux = ux+x
				uz = uz+z
				us = us+1
			end
		end
	
		if (us == 0) then
			return
		else
			aveX = ux/us
			aveZ = uz/us
		end
	
		for k, mex in pairs(mexes) do		
			--if (mex.x > xmin) and (mex.x < xmax) and (mex.z > zmin) and (mex.z < zmax) then -- square area, should be faster
			if (Distance(cx,cz,mex.x,mex.z) < cr^2) then -- circle area, slower
				commands[#commands+1] = {x = mex.x, z = mex.z, d = Distance(aveX,aveZ,mex.x,mex.z)}
			end
		end
	
		local noCommands = #commands
		while noCommands > 0 do
	  
			tasort(commands, function(a,b) return a.d < b.d end)
			orderedCommands[#orderedCommands+1] = commands[1]
			aveX = commands[1].x
			aveZ = commands[1].z
			taremove(commands, 1)
			for k, com in pairs(commands) do		
				com.d = Distance(aveX,aveZ,com.x,com.z)
			end
			noCommands = noCommands-1
		end
	
		local shift = options.shift
	
		for i, id in ipairs(units) do 
			if mexBuilder[id] then
				if not shift then 
					spGiveOrderToUnit(id, CMD.STOP, {} , CMD.OPT_RIGHT )
				end
				for i, command in ipairs(orderedCommands) do
					for j=1, #mexBuilder[id] do
						local buildable = spTestBuildOrder(-mexBuilder[id][j],command.x,0,command.z,1)
						if buildable ~= 0 then
							spGiveOrderToUnit(id, mexBuilder[id][j], {command.x,0,command.z} , {"shift"})
							break
						end
					end
				end
			end
		end
  
		return true
  
	end
  
end

--------------------
-- interface stuff needs CALayout to work properly

local CMD_CLOAK         = CMD.CLOAK
local CMD_ONOFF         = CMD.ONOFF
local CMD_REPEAT        = CMD.REPEAT
local CMD_MOVE_STATE    = CMD.MOVE_STATE
local CMD_FIRE_STATE    = CMD.FIRE_STATE

function widget:CommandsChanged()

	local units = spGetSelectedUnits()
	
	for i, id in pairs(units) do 
		if mexBuilder[id] then
		
			local customCommands = widgetHandler.customCommands
			table.insert(customCommands, {
				id      = CMD_AREA_MEX,
				type    = CMDTYPE.ICON_AREA,
				tooltip = 'Define an area to make mexes in',
				name    = 'Mex',
				cursor  = 'Repair',
				action  = 'areamex',
				params  = {}, 
				
				pos = {CMD_CLOAK,CMD_ONOFF,CMD_REPEAT,CMD_MOVE_STATE,CMD_FIRE_STATE, CMD_RETREAT},
			})
			break
		end
	end
	
end


----------------------
-- Mex detection from easymetal by carrepairer

local floor = math.floor

local spGetGroundInfo   = Spring.GetGroundInfo
local spGetGroundHeight = Spring.GetGroundHeight

local gridSize			= 4
local threshFraction	= 0.4
local metalExtraction	= 0.004

local mapWidth 			= floor(Game.mapSizeX)
local mapHeight 		= floor(Game.mapSizeZ)
local mapWidth2 		= floor(Game.mapSizeX / gridSize)
local mapHeight2 		= floor(Game.mapSizeZ / gridSize)

local metalMap 			= {}
local maxMetal 			= 0

local metalData 		= {}
local metalDataCount 	= 0

local snapDist			= 10000
local mexSize			= 25
local mexRad			= Game.extractorRadius > 125 and Game.extractorRadius or 125

local flagCount			= 0

local function NearFlag(px, pz, dist)
	if not mexes then return false end
	for k, flag in pairs(mexes) do		
		local fx, fz = flag.x, flag.z
		if (px-fx)^2 + (pz-fz)^2 < dist then
			return k
		end
	end
	return false
end

local function round(num, idp)
  local mult = 10^(idp or 0)
  return floor(num * mult + 0.5) / mult
end

local function mergeToFlag(flagNum, px, pz, pWeight)

	local fx = mexes[flagNum].x
	local fz = mexes[flagNum].z
	local fWeight = mexes[flagNum].weight
	
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
	
	mexes[flagNum].x = avgX
	mexes[flagNum].z = avgZ
	mexes[flagNum].weight = fWeight + pWeight
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
	
	--Spring.Echo("number of spots " .. #metalData)
	if #metalData > maxMetalData then -- ceases to work
		Spring.Echo("Removed Area Mex, too many spots.")
		widgetHandler:RemoveWidget()
		return
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
			mexes[flagCount] = {
				x = mx,
				z = mz,
				weight = mCur
			}
			
		end
	end

end

-- saving metalmap
local function SaveMetalMap(filename)
	--Spring.Echo("exporting mexmap to ".. filename);
	local file = assert(io.open(filename,'w'), "Unable to save mexmap to "..filename)
	
	for k, mex in pairs(mexes) do
		--file:write(k)
		--file:write("\n")
		file:write(mex.x)
		file:write("\n")
		file:write(mex.z)
		file:write("\n")
		--file:write(mex.weight)
		--file:write("\n")
		--if (Distance(cx,cz,mex.x,mex.z) < cr^2) then -- circle area, slower
		--commands[#commands+1] = {x = mex.x, z = mex.z, d = Distance(aveX,aveZ,mex.x,mex.z)}
	end
	
	file:close()
	Spring.Echo("mexmap exported to ".. filename);
end

local function LoadMetalMap(filename)
	--Spring.Echo("importing mexmap from ".. filename);
	local file = assert(io.open(filename,'r'), "Unable to load mexmap from "..filename)
	mexes = {}
	index = 1
	while true do
		l1 = file:read()
		if not l1 then 
			break 
		end
		l2 = file:read()
		if not l2 then 
			Spring.Echo("error in mexmap " .. l1)
			break 
		end
		--l3 = file:read()
		--l4 = file:read()
		mexes[index] = {
			x = l1,
			z = l2,
			--weight = l4
		}
		index = index+1
	end
	Spring.Echo("mexmap imported from ".. filename);
	
end

function widget:Initialize()
	if (not next(mexIds)) then
		Spring.Echo("Removed Area Mex - No mexes found in the mod.")
		widgetHandler:RemoveWidget()
	end

	Spring.CreateDir(pathToSave)
	--if not os.isdir(pathToSave) then
	--io.mkdir(pathToSave)-- end
	--os.execute("mkdir ".. pathToSave) -- in case directory doesn't exist
	local filename = (pathToSave.. string.lower(string.gsub(Game.mapName, ".smf", "")) .. ".springmexmap")
	file = io.open(filename,'r')
	--io.close(file)
	if file ~= nil then -- file exists?
		Spring.Echo("Mexmap detected - loading...")
		LoadMetalMap(filename)
	else
		Spring.Echo("Calculating mexmap")
		AnalyzeMetalMap()
		SaveMetalMap(filename)
	end
  
	local units = spGetTeamUnits(spGetMyTeamID())
	for i, id in ipairs(units) do 
		widget:UnitCreated(id, spGetUnitDefID(id))
	end
	
end
