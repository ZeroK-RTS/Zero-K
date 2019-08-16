--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "Shared Functions",
    desc      = "Declares global functions or constants",
    author    = "Licho",
    date      = "6.9.2010",
    license   = "GNU GPL, v2 or later",
    layer     = -math.huge + 1,
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
VFS.Include("LuaRules/Utilities/unitDefReplacements.lua")
VFS.Include("LuaRules/Utilities/tablefunctions.lua")
VFS.Include("LuaRules/Utilities/rulesParam.lua")

local function GetBuildIconFrame(udef)
	local cp = udef.customParams
	if udef.isMobileBuilder then
		return consTex

	elseif (udef.isBuilder or udef.isFactory) then
		return consTex

	elseif (udef.weapons[1] and udef.isBuilding) then
		return unitTex

	elseif (cp.income_energy or cp.ismex or cp.windgen) then
		return ecoTex

	elseif ((udef.weapons[1] or udef.canKamikaze) and not cp.unarmed) then
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

-- Returns an array of strings to be concatenated
local function WriteTable(concatArray, tab, tabName, params)
	params = params or {}
	local processed = {}
	concatArray = concatArray or {}
	
	params.numIndents = params.numIndents or 0
	local isDict = IsDictOrContainsDict(tab)
	local comma = params.raw and "" or ", "
	local endLine = comma .. "\n"
	local str = ""
	
	local function NewLine()
		concatArray[#concatArray + 1] = str
		str = ""
	end
	
	local function ProcessKeyValuePair(i,v, isArray, lastItem)
		if type(v) == "function" then
			return
		end
	
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
			NewLine()
			WriteTable(concatArray, v, nil, arg)
		elseif type(v) == "boolean" then
			str = str .. tostring(v) .. pairEndLine
		elseif type(v) == "string" then
			str = str .. string.format("%q", v) .. pairEndLine
		else
			if type(v) == "number" then
				if v == math.huge then
					v = "math.huge"
				elseif v == -math.huge then
					v = "-math.huge"
				end
			end
			str = str .. v .. pairEndLine
		end
		NewLine()
	end
	
	if not params.raw then
		if params.prefixReturn then
			str = "return "
		elseif tabName then
			str = tabName .. " = "
		end
		str = str .. (isDict and "{\n" or "{")
	end
	NewLine()
	
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
	NewLine()
	
	return concatArray
end

WG.WriteTable = WriteTable

function WG.SaveTable(tab, dir, fileName, tabName, params)
	Spring.CreateDir(dir)
	params = params or {}
	local file,err = io.open(dir .. fileName, "w")
	if (err) then
		Spring.Log(widget:GetInfo().name, LOG.WARNING, err)
		return
	end
	local toConcat = WriteTable({}, tab, tabName, params)
	local str = table.concat(toConcat)
	file:write(str)
	file:flush()
	file:close()
end

-- raw = print table key-value pairs straight to file (i.e. not as a table)
-- if you use it make sure your keys are valid variable names!
local function WritePythonOrJSONDict(dict, dictName, params)
	params = params or {}
	params.numIndents = params.numIndents or 0
	local isJSON = params.json
	local comma = params.raw and "" or ", "
	local endLine = comma .. "\n"
	local separator = (params.raw and (not isJSON)) and " = " or  " : "
	local str = ""
	if (not params.raw) then
		if params.endOfFile and dictName and (dictName ~= '') then
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
			local arg = (v and (isJSON and "true" or "True")) or (isJSON and "false") or "False"
			str = str .. arg .. endLine
		elseif type(v) == "string" then
			str = str .. string.format("%q", v) .. endLine
		else
			str = str .. v .. endLine
		end
	end
	
	-- get rid of trailing commma
	local strEnd  = string.sub(str,-3)
	if strEnd == endLine then -- , \n
		str = string.sub(str, 1, -4) .. "\n"
	end
	
	if not params.raw then
		str = str ..WriteIndents(params.numIndents) .. "}"
	end
	if params.endOfFile == false then
		str = str .. comma .. "\n"
	end
	
	return str
end

local function SavePythonOrJSONDict(dict, dir, fileName, dictName, params)
	Spring.CreateDir(dir)
	params = params or {}
	local file,err = io.open (dir .. fileName, "w")
	if (err) then
		Spring.Log(widget:GetInfo().name, LOG.WARNING, err)
		return
	end
	file:write(WritePythonOrJSONDict(dict, dictName, params))
	file:flush()
	file:close()
end

WG.SavePythonDict = SavePythonOrJSONDict
WG.SavePythonOrJSONDict = SavePythonOrJSONDict

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:Initialize()
  WG.GetBuildIconFrame = GetBuildIconFrame
end

local builderDefs = {}
for udid, ud in ipairs(UnitDefs) do
	for i, option in ipairs(ud.buildOptions) do
		if UnitDefNames.staticmex.id == option then
			builderDefs[udid] = true
		end
	end
end

function widget:SelectionChanged(units)
	if (not units) or #units == 0 then
		WG.selectionEntirelyCons = false
		return
	end
	for i = 1, #units do
		if not builderDefs[Spring.GetUnitDefID(units[i])] then
			WG.selectionEntirelyCons = false
			return
		end
	end
	WG.selectionEntirelyCons = true
end
