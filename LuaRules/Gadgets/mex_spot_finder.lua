----------------------
-- Mex detection from easymetal by carrepairer

local maxMetalData = 2500000
local pathToSave = "LuaUI/Widgets/MetalMaps/"

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

local mexSpot			 = {count = 0,}
local metalMapAnalysed	= false

local function NearFlag(px, pz, dist)
	if mexSpot.count == 0 then 
		return false 
	end
	for i = 1, mexSpot.count do		
		local fx, fz = mexSpot[i].x, mexSpot[i].z
		if (px-fx)^2 + (pz-fz)^2 < dist then
			return i
		end
	end
	return false
end

local function round(num, idp)
  local mult = 10^(idp or 0)
  return floor(num * mult + 0.5) / mult
end

local function mergeToFlag(flagNum, px, pz, pWeight)

	local fx = mexSpot[flagNum].x
	local fz = mexSpot[flagNum].z
	local fWeight = mexSpot[flagNum].weight
	
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
	
	mexSpot[flagNum].x = avgX
	mexSpot[flagNum].z = avgZ
	mexSpot[flagNum].weight = fWeight + pWeight
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
		mexSpot = false
		return false
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
			mexSpot.count = mexSpot.count + 1
			mexSpot[mexSpot.count] = {
				x = mx,
				z = mz,
				weight = mCur
			}
			
		end
	end
	
	return true

end

-- save and load not working, probably needs entirely different implmentation
-- saving metalmap
local function SaveMetalMap(filename)
	--Spring.Echo("exporting mexmap to ".. filename);
	local file = assert(io.open(filename,'w'), "Unable to save mexmap to "..filename)
	
	for k, mex in pairs(mexSpot) do
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
	while true do
		l1 = file:read()
		if not l1 then break end
		l2 = file:read()
		--l3 = file:read()
		--l4 = file:read()
		mexSpot.count = mexSpot.count+1
		mexSpot[mexSpot.count] = {
			x = l1,
			z = l2 --,
			--weight = l4
		}
	end
	Spring.Echo("mexmap imported from ".. filename);
	
end

function GetMetalMap()

	if metalMapAnalysed then
		return mexSpot
	end

	--Spring.CreateDir(pathToSave)
	--if not os.isdir(pathToSave) then
	--io.mkdir(pathToSave)-- end
	--os.execute("mkdir ".. pathToSave) -- in case directory doesn't exist
	--local filename = (pathToSave.. string.lower(string.gsub(Game.mapName, ".smf", "")) .. ".springmexmap")
	--file = io.open(filename,'r')
	--io.close(file)
	if file ~= nil then -- file exists?
		--Spring.Echo("Mexmap detected - loading...")
		--LoadMetalMap(filename)
	else
		AnalyzeMetalMap()
		metalMapAnalysed = true
		return mexSpot
		--SaveMetalMap(filename)
	end
	
end