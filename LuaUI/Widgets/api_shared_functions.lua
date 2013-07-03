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

-- raw = print table key-value pairs straight to file (i.e. not as a table)
-- if you use it make sure your keys are valid variable names!
local function WriteTable(tab, tabName, numIndents, endOfFile, concise, raw, prefixReturn)
	local comma = raw and "" or ","
	local eos = comma .. ((concise and not raw) and '' or "\n")	-- end of string
	numIndents = numIndents or 0
	local str = ""	--WriteIndents(numIndents)
	if not raw then
		if prefixReturn then
			str = "return "
		elseif tabName then
			str = tabName .. " = "
		end
		str = str .. (concise and "{" or "{\n")
	end
	for i,v in pairs(tab) do
		if not concise then
			str = str .. WriteIndents(numIndents + 1)
		end
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
			str = str .. WriteTable(v, nil, (concise and 0 or numIndents + 1), false, concise)
		elseif type(v) == "boolean" then
			str = str .. tostring(v) .. eos
		elseif type(v) == "string" then
			str = str .. string.format("%q", v) .. eos
		else
			str = str .. v .. eos
		end
	end
	str = str .. WriteIndents(numIndents) .. "}"
	if not endOfFile then
		str = str .. comma .. "\n"
	end
	
	return str
end

WG.WriteTable = WriteTable

function WG.SaveTable(tab, fileName, tabName, concise, raw, prefixReturn)
	local file,err = io.open(fileName, "w")
	if (err) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, err)
		return
	end
	file:write(WriteTable(tab, tabName, 0, true, concise, raw, prefixReturn))
	file:flush()
	file:close()
end

-- raw = print table key-value pairs straight to file (i.e. not as a table)
-- if you use it make sure your keys are valid variable names!
local function WritePythonDict(dictName, dict, numIndents, endOfFile, raw, concise)
	numIndents = numIndents or 0
	local comma = raw and "" or ","
	local eos = comma .. ((concise and not raw) and '' or "\n")	-- end of string
	local separator = raw and " = " or  " : "
	local str = ""
	if not raw then
	      str = dictName .. " = "	--WriteIndents(numIndents)
	      str = str .. (concise and "{" or "{\n")
	end
	for i,v in pairs(dict) do
		if not raw then
			str = str .. WriteIndents(numIndents + 1)
		end
		if (type(i) == "string") and not raw then
			str = str .. string.format("%q", i) .. separator
		else
			str = str .. i .. separator
		end
		
		if type(v) == "table" then
			str = str .. WritePythonDict(v, concise and 0 or numIndents + 1, false, false, concise)
		elseif type(v) == "boolean" then
			str = str .. v and "True" or "False" .. eos
		elseif type(v) == "string" then
			str = str .. string.format("%q", v) .. eos
		else
			str = str .. v .. eos
		end
	end
	if not raw then
		str = str ..WriteIndents(numIndents) .. "}"
	end
	if not endOfFile then
		str = str .. comma .. "\n"
	end
	
	return str
end

WG.WritePythonDict = WritePythonDict

function WG.SavePythonDict(fileName, dictName, dict, raw)
	local file,err = io.open (fileName, "w")
	if (err) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, err)
		return
	end
	file:write(WritePythonDict(dictName, dict, 0, true, raw))
	file:flush()
	file:close()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:Initialize()
  WG.GetBuildIconFrame = GetBuildIconFrame
end