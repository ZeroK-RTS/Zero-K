--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local ecoTex     = ":n:bitmaps/icons/frame_eco.png"
local consTex    = ":n:bitmaps/icons/frame_cons.png"
local unitTex    = ":n:bitmaps/icons/frame_unit.png"
local diffTex    = ":n:bitmaps/icons/frame_diff.png"
local frameTex   = ":n:bitmaps/icons/frame_slate.png"

Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/tablefunctions.lua")

local function GetBuildIconFrame(udef) 
  if (udef.isBuilder and udef.speed>0) then
    return consTex

  elseif (udef.isBuilder or udef.isFactory) then
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

--[[
	raw = print table key-value pairs straight to file (i.e. not as a table)
	if you use it make sure your keys are valid variable names!
	
	valid params: {
		numIndents = int,
		raw = bool,
		prefixReturn = bool,
		forceLineBreakAtEnd = bool,
	}
]]
local function IsDictOrContainsDict(tab)
	for i,v in pairs(tab) do
		if type(i) ~= "number" then
			return true
		elseif i > #tab then
			return true
		elseif i <= 0 then
			return true
		elseif type(v) == "table" then
			return true
		end
	end
	return false
end

local function WriteTable(tab, tabName, params)
	params = params or {}
	local processed = {}
	
	params.numIndents = params.numIndents or 0
	local isDict = IsDictOrContainsDict(tab)
	local comma = params.raw and "" or ", "
	local endLine = comma .. "\n"
	local str = ""
	
	local function ProcessKeyValuePair(i,v, isArray, lastItem)
		local pairEndLine = (lastItem and "") or (isArray and comma) or endLine
		if isDict then
			str = str .. WriteIndents(params.numIndents + 1)
		end
		if type(i) == "number" then
			if not isArray then
				str = str .. "[" .. i .. "] = "
			end
		elseif keywords[i] or (type(i) == "string") then
			str = str .. "[" .. string.format("%q", i) .. "]" .. "= "
		else
			str = str .. i .. " = "
		end
		
		if type(v) == "table" then
			local arg = {numIndents = (params.numIndents + 1), endOfFile = false}
			str = str .. WriteTable(v, nil, arg)
		elseif type(v) == "boolean" then
			str = str .. tostring(v) .. pairEndLine
		elseif type(v) == "string" then
			str = str .. string.format("%q", v) .. pairEndLine
		else
			str = str .. v .. pairEndLine
		end
	end
	
	if not params.raw then
		if params.prefixReturn then
			str = "return "
		elseif tabName then
			str = tabName .. " = "
		end
		str = str .. (isDict and "{\n" or "{")
	end
	
	-- do array component first (ensures order is preserved)
	for i=0,#tab do
		local v = tab[i]
		if v then
			ProcessKeyValuePair(i,v, (tab[0] == nil), (not isDict) and i == #tab)
			processed[i] = true
		end
	end
	for i,v in pairs(tab) do
		if not processed[i] then
			ProcessKeyValuePair(i,v)
		end
	end
	
	if isDict then
		str = str .. WriteIndents(params.numIndents)
	end
	str = str ..  "}"
	if params.endOfFile == false then
		str = str .. endLine
	end
	
	return str
end

WG.WriteTable = WriteTable

function WG.SaveTable(tab, fileName, tabName, params)
	params = params or {}
	local file,err = io.open(fileName, "w")
	if (err) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, err)
		return
	end
	file:write(WriteTable(tab, tabName, params))
	file:flush()
	file:close()
end

-- raw = print table key-value pairs straight to file (i.e. not as a table)
-- if you use it make sure your keys are valid variable names!
local function WritePythonDict(dict, dictName, params)
	params = params or {}
	params.numIndents = params.numIndents or 0
	local comma = params.raw and "" or ", "
	local endLine = comma .. "\n"
	local separator = params.raw and " = " or  " : "
	local str = ""
	if (not params.raw) then
		if params.endOfFile then
			str = dictName .. " = "	--WriteIndents(numIndents)
		end
		str = str .. "{\n"
	end
	for i,v in pairs(dict) do
		if not params.raw then
			str = str .. WriteIndents(params.numIndents + 1)
		end
		if (type(i) == "string") and not params.raw then
			str = str .. string.format("%q", i) .. separator
		else
			str = str .. i .. separator
		end
		
		if type(v) == "table" then
			local arg = {numIndents =  params.numIndents + 1, endOfFile = false}
			str = str .. WritePythonDict(v, nil, arg)
		elseif type(v) == "boolean" then
			str = str .. ((v and "True") or "False") .. endLine
		elseif type(v) == "string" then
			str = str .. string.format("%q", v) .. endLine
		else
			str = str .. v .. endLine
		end
	end
	if not params.raw then
		str = str ..WriteIndents(params.numIndents) .. "}"
	end
	if params.endOfFile == false then
		str = str .. comma .. "\n"
	end
	
	return str
end

WG.WritePythonDict = WritePythonDict

function WG.SavePythonDict(fileName, dict, dictName, params)
	params = params or {}
	local file,err = io.open (fileName, "w")
	if (err) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, err)
		return
	end
	file:write(WritePythonDict(dict, dictName, params))
	file:flush()
	file:close()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:Initialize()
  WG.GetBuildIconFrame = GetBuildIconFrame
end