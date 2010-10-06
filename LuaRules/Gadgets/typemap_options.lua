

function gadget:GetInfo()
  return {
    name      = "Typemap Options",
    desc      = "Edit's the map's typemap at the start of the game.",
    author    = "Google Frog",
    date      = "Feb, 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

local spGetGroundInfo = Spring.GetGroundInfo
local spSetTerrainTypeData = Spring.SetTerrainTypeData
local spSetMapSquareTerrainType = Spring.SetMapSquareTerrainType
local spGetGameFrame = Spring.GetGameFrame

--Spring.GetGroundInfo(number x, number z) --> string "terrain-type name", ...
--Spring.SetTerrainTypeData(1,2.0,1.0,1.0,1.0)
--Spring.SetMapSquareTerrainType(xPos,zPos,1)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (not gadgetHandler:IsSyncedCode()) then
  return false  --  no unsynced code
end

local modOptions = Spring.GetModOptions()
function gadget:Initialize()
	
	--[[
	for i = 0,256,1 do
		Spring.SetMapSquareTerrainType(0,0,i)
		local name,_,_,t,b,v,s = Spring.GetGroundInfo(0,0)
		Spring.Echo(name .. " " .. i)
	end
	--]]
	
	if spGetGameFrame() > 0 then
		gadgetHandler:RemoveGadget()
		return
	end
	if modOptions.typemapsetting then
	
		if modOptions.typemapsetting == "alloff" then
			for i = 0,256,1  do
				spSetTerrainTypeData(i,1,1,1,1)
			end
		elseif modOptions.typemapsetting == "keepequal" then
		
			local override = {}
			
			for i = 0,256,1 do
				Spring.SetMapSquareTerrainType(0,0,i)
				local name,_,_,t,b,v,s = Spring.GetGroundInfo(0,0)
				if name == "default" or (t == b and b == v and v == s) then
					override[i] = false
				else
					override[i] = true
				end
			end
			
			for i = 0,256,1  do
				if override[i] then
					spSetTerrainTypeData(i,1,1,1,1)
				end
			end
		
		elseif modOptions.typemapsetting == "average" then
		
			local override = {}
			
			for i = 0,256,1 do
				Spring.SetMapSquareTerrainType(0,0,i)
				local name,_,_,t,b,v,s = Spring.GetGroundInfo(0,0)
				if name == "default" or (t == b and b == v and v == s) then
					override[i] = false
				else
					override[i] = (t+b+v+s)/4
				end
			end
			
			for i = 0,256,1  do
				if override[i] then
					spSetTerrainTypeData(i,override[i],override[i],override[i],override[i])
				end
			end
			
		elseif modOptions.typemapsetting == "onlyimpassable" then
		
			local override = {}
			
			for i = 0,256,1 do
				Spring.SetMapSquareTerrainType(0,0,i)
				local name,_,_,t,b,v,s = Spring.GetGroundInfo(0,0)
				if name == "default" or (t == 0 and b == 0 and v == 0 and s == 0) then
					override[i] = false
				else
					override[i] = true
				end
			end
			
			for i = 0,256,1  do
				if override[i] then
					spSetTerrainTypeData(i,1,1,1,1)
				end
			end
		
		end
		
	end
	
	gadgetHandler:RemoveGadget()
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------