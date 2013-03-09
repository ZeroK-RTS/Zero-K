function widget:GetInfo()
  return {
    name      = "Shared Functions",
    desc      = "Declares global functions or constants",
    author    = "Licho",
    date      = "6.9.2010",
    license   = "GNU GPL, v2 or later",
    layer     = -math.huge,
    enabled   = true,
	api = true,
	alwaysStart = true,
  }
end

local ecoTex     = ":n:bitmaps/icons/frame_eco.png"
local consTex    = ":n:bitmaps/icons/frame_cons.png"
local unitTex    = ":n:bitmaps/icons/frame_unit.png"
local diffTex    = ":n:bitmaps/icons/frame_diff.png"
local frameTex   = ":n:bitmaps/icons/frame_slate.png"

Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/tablefunctions.lua")

local function GetBuildIconFrame(udef) 
  if (udef.builder and udef.speed>0) then
    return consTex

  elseif (udef.builder or udef.isFactory) then
    return consTex

  elseif (udef.weapons[1] and udef.isBuilding) then
    return unitTex

  elseif ((udef.totalEnergyOut>0) or (udef.customParams.ismex) or (udef.name=="armwin" or udef.name=="corwin")) then
    return ecoTex

  elseif (udef.weapons[1] or udef.canKamikaze) then
    return unitTex

  else
    return diffTex
  end
end 

--------------------------------------------------------------------------------
-- table writing funcs
--------------------------------------------------------------------------------
local function WriteIndents(num)
	local str = ""
	for i=1, num do
		str = str .. "\t"
	end
	return str
end

local keywords = {
	["repeat"] = true,
}

local function WriteTable(array, numIndents, endOfFile, concise)
	numIndents = numIndents or 0
	local str = ""	--WriteIndents(numIndents)
	str = str .. (concise and "{" or "{\n")
	for i,v in pairs(array) do
		str = str .. WriteIndents(numIndents + 1)
		if type(i) == "number" then
			if not concise then
			  str = str .. "[" .. i .. "] = "
			end
		elseif keywords[i] or (type(i) == "string") then
			str = str .. "[" .. string.format("%q", i) .. "]" .. "= "
		else
			str = str .. i .. " = "
		end
		
		if type(v) == "table" then
			str = str .. WriteTable(v, concise and 0 or numIndents + 1, false, concise, useDoubleQuote)
		elseif type(v) == "boolean" then
			str = str .. tostring(v) .. ",\n"
		elseif type(v) == "string" then
			str = str .. string.format("%q", v) .. "," .. (concise and '' or "\n")
		else
			str = str .. v .. ",\n"
		end
	end
	str = str ..WriteIndents(numIndents) .. "}"
	if not endOfFile then
		str = str .. ",\n"
	end
	
	return str
end

WG.WriteTable = WriteTable

function WG.PrintTable(f, table)
	file = io.open (f, "w")
	if (file== nil) then Spring.Log(HANDLER_BASENAME, LOG.ERROR, "could not open file for writing!") return end
	file:write(WriteTable(table, 0, true))
	file:flush()
	file:close()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:Initialize()
  WG.GetBuildIconFrame = GetBuildIconFrame
end
