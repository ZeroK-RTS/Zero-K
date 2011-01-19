-- $Id: lups_nano_spray.lua 3171 2008-11-06 09:06:29Z det $
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "LupsNanoSpray",
    desc      = "Wraps the nano spray to LUPS",
    author    = "jK",
    date      = "2008-2010",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end


local function GetCmdTag(unitID) 
    local cmdTag = 0
    local cmds = Spring.GetFactoryCommands(unitID,1)
	if (cmds) then
        local cmd = cmds[1]
        if cmd then
           cmdTag = cmd.tag
        end
    end
	if cmdTag == 0 then 
		local cmds = Spring.GetUnitCommands(unitID,1)
		if (cmds) then
			local cmd = cmds[1]
			if cmd then
				cmdTag = cmd.tag
			end
        end
	end 
	return cmdTag
end 
	


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

  local GetUnitScriptPiece = Spring.GetUnitScriptPiece
  if (not GetUnitScriptPiece) then --//75b2 compa
    GetUnitScriptPiece = function(_,i) return i+1 end
  end
  local GetUnitAllyTeam = Spring.GetUnitAllyTeam

  local bit_and  = math.bit_and
  local bit_or   = math.bit_or
  local bit_bits = math.bit_bits

  local nanoEmitters = {}
  for i=0,29 do nanoEmitters[i] = {} end
  _G.nanoEmitters  = nanoEmitters

  -------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------

  function QueryNanoPieceLua(unitID,unitDefID,teamID,piecenum)
    local cmdTag = GetCmdTag(unitID)

	
    local offset = unitID%30
    local emitter = nanoEmitters[offset][unitID]
    if (emitter) then
      emitter.strength = emitter.strength+1
      emitter.cmdTag = cmdTag
      if bit_and( emitter.nanoPieces,bit_bits(piecenum) )==0 then
        emitter.nanoPieces = bit_or( emitter.nanoPieces, bit_bits(piecenum) )
        emitter.pieceCount = emitter.pieceCount+1
        emitter[emitter.pieceCount] = piecenum
      end
    else
      nanoEmitters[offset][unitID] = {
            teamID = teamID,
            unitDefID = unitDefID,
            allyID = GetUnitAllyTeam(unitID),
            strength = 1,
            pieceCount = 1,
            nanoPieces = bit_bits(piecenum),
            cmdTag = cmdTag,
            [1] = piecenum,
	}
    end
  end


  function QueryNanoPieceCOB(unitID,unitDefID,teamID,piecenum)
    piecenum = GetUnitScriptPiece(unitID,piecenum)
    QueryNanoPieceLua(unitID,unitDefID,teamID,piecenum)
  end

  -------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------

  function gadget:GameFrame(n)
    local offset = ((n+16) % 30)
    if (next(nanoEmitters[offset])) then
      SendToUnsynced("nano_GameFrame", offset)
      nanoEmitters[offset] = {}
    end
  end

  -------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------

  function gadget:Initialize()
    GG.LUPS = GG.LUPS or {}
    GG.LUPS.QueryNanoPiece = QueryNanoPieceLua
    gadgetHandler:RegisterGlobal("QueryNanoPiece",QueryNanoPieceCOB)
  end

  function gadget:Shutdown()
    GG.LUPS = nil
    gadgetHandler:DeregisterGlobal("QueryNanoPiece")
  end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else
------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local Lups  --// Lua Particle System
local initialized = false --// if LUPS isn't started yet, we try it once a gameframe later
local tryloading  = 1     --// try to activate lups if it isn't found

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

--// Speed-ups
local GetUnitRadius        = Spring.GetUnitRadius
local GetFeatureRadius     = Spring.GetFeatureRadius
local tinsert = table.insert
local type  = type
local pairs = pairs
local SYNCED = SYNCED
local spairs = spairs

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not GetFeatureRadius) then
  GetFeatureRadius = function(featureID)
    local fDefID = Spring.GetFeatureDefID(featureID)
    return (FeatureDefs[fDefID].radius or 0)
  end
end


local function SetTable(table,arg1,arg2,arg3,arg4)
  table[1] = arg1
  table[2] = arg2
  table[3] = arg3
  table[4] = arg4
end


local function CopyTable(outtable,intable)
  for i,v in pairs(intable) do 
    if (type(v)=='table') then
      if (type(outtable[i])~='table') then outtable[i] = {} end
      CopyTable(outtable[i],v)
    else
      outtable[i] = v
    end
  end
end


local function CopyMergeTables(table1,table2)
  local ret = {}
  CopyTable(ret,table2)
  CopyTable(ret,table1)
  return ret
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  «« some basic functions »»
--

local supportedFxs = {}
local function fxSupported(fxclass)
  if (supportedFxs[fxclass]~=nil) then
    return supportedFxs[fxclass]
  else
    supportedFxs[fxclass] = Lups.HasParticleClass(fxclass)
    return supportedFxs[fxclass]
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Lua StrFunc parsing and execution
--

local loadstring = loadstring
local pcall = pcall
local function ParseLuaStrFunc(strfunc)
  local luaCode = [[
    return function(count,inversed)
      local limcount = (count/6)
            limcount = limcount/(limcount+1)
      return ]] .. strfunc .. [[
    end
  ]]

  local luaFunc = loadstring(luaCode)
  local success,ret = pcall(luaFunc)

  if (success) then
    return ret
  else
    Spring.Echo("LUPS(NanoSpray): parsing error in user function: \n" .. ret)
    return function() return 0 end
  end
end

local function ParseLuaCode(t)
  for i,v in pairs(t) do
    if (type(v)=="string")and(i~="texture")and(i~="fxtype") then
      t[i] = ParseLuaStrFunc(v)
    end
  end
end

local function ExecuteLuaCode(t)
  for i,v in pairs(t) do
    if (type(v)=="function") then
      t[i]=v(t.count,t.inversed)
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  «« NanoSpray handling »»
--

local nanoParticles = {}

local function GetFaction(udid)
  --local udef_factions = UnitDefs[udid].factions or {}
  --return ((#udef_factions~=1) and 'unknown') or udef_factions[1]
  return "default" -- default 
end

local factionsNanoFx = {
  default = {
    fxtype      = "NanoParticles",
    delaySpread = 30,
    size        = 3,
    sizeSpread  = 5,
    sizeGrowth  = 0.25,
    texture     = "bitmaps/PD/nano.tga"
  },
  ["default_high_quality"] = {
    fxtype      = "NanoParticles",
    alpha       = 0.27,
    size        = 6,
    sizeSpread  = 6,
    sizeGrowth  = 0.65,
    rotSpeed    = 0.1,
    rotSpread   = 360,
    texture     = "bitmaps/Other/Poof.png",
    particles   = 1.2,
  },
  --[[arm = {
    fxtype      = "NanoParticles",
    delaySpread = 30,
    size        = 3,
    sizeSpread  = 5,
    sizeGrowth  = 0.25,
    texture     = "bitmaps/PD/nano.tga"
  },
  ["arm_high_quality"] = {
    fxtype      = "NanoParticles",
    alpha       = 0.27,
    size        = 6,
    sizeSpread  = 6,
    sizeGrowth  = 0.65,
    rotSpeed    = 0.1,
    rotSpread   = 360,
    texture     = "bitmaps/Other/Poof.png",
    particles   = 1.2,
  },
  core = {
    fxtype          = "NanoLasers",
    alpha           = "0.2+count/30",
    corealpha       = "0.2+count/120",
    corethickness   = "limcount",
    streamThickness = "0.5+5*limcount",
    streamSpeed     = "limcount*0.05",
  },
  unknown = {
    fxtype          = "NanoLasers",
    alpha           = "0.2+count/30",
    corealpha       = "0.2+count/120",
    corethickness   = "limcount",
    streamThickness = "0.5+5*limcount",
    streamSpeed     = "limcount*0.05",
  },]]--
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

  function GameFrame(_,offset)
    for unitID,nanoInfo in spairs(SYNCED.nanoEmitters[offset]) do
      local type, target = Spring.Utilities.GetUnitIsBuilding(unitID)

      if (target) then
        local cmdTag = GetCmdTag(unitID)
		
        if (nanoInfo.cmdTag == cmdTag) then
          local radius = 30
          if (type=="restore") then
            radius = target[4]
          elseif (target>0) then
            radius = GetUnitRadius(target)*0.80
          else
            radius = GetFeatureRadius(-target) * 0.80
          end

          local terraform = false
          local inversed  = false
          if (type=="restore") then
            terraform = true
          elseif (type=="reclaim") then
            inversed  = true
          end

          local endpos
          if (type=="restore") then
            endpos = target
          end

          local strength = nanoInfo.strength
          if (type=="reclaim") then
            --// reclaim is done always at full speed
            strength = 30
          end

          local faction = GetFaction(nanoInfo.unitDefID)
          local teamColor = {Spring.GetTeamColor(nanoInfo.teamID)}

          for i=1,nanoInfo.pieceCount do
            local nanoParams = {
              targetID     = target,
              unitpiece    = nanoInfo[i],
              unitID       = unitID,
              unitDefID    = nanoInfo.unitDefID,
              teamID       = nanoInfo.teamID,
              allyID       = nanoInfo.allyID,
              nanopiece    = nanoInfo[i],
              targetpos    = endpos,
              count        = strength,
              color        = teamColor,
              type         = type,
              targetradius = radius,
              terraform    = terraform,
              inversed     = inversed,
              cmdTag       = cmdTag, --//used to end the fx when the command is finished
            }

            local nanoSettings = CopyMergeTables(factionsNanoFx[faction] or factionsNanoFx.default,nanoParams)
            ExecuteLuaCode(nanoSettings)

            local fxType  = nanoSettings.fxtype
            if (not nanoParticles[unitID]) then nanoParticles[unitID] = {} end
            local unitFxs = nanoParticles[unitID]
            unitFxs[#unitFxs+1] = Lups.AddParticles(nanoSettings.fxtype,nanoSettings)
          end
        end
      end

    end --//for
  end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:Update()
  if (Spring.GetGameFrame()<1) then 
    return
  end

  gadgetHandler:RemoveCallIn("Update")

  Lups = GG['Lups']

  if (Lups) then
    initialized=true
  else
    return
  end

  --// enable freaky arm nano fx when quality>4
  if ((Lups.Config["quality"] or 4)>=4) then
    factionsNanoFx.default = factionsNanoFx["default_high_quality"]
  end

  --// init user custom nano fxs
  for faction,fx in pairs(Lups.Config or {}) do
    if (fx and (type(fx)=='table') and fx.fxtype) then
      local fxType = fx.fxtype 
      local fxSettings = fx

      if (fxType)and
         ((fxType:lower()=="nanolasers")or
          (fxType:lower()=="nanoparticles"))and
         (fxSupported(fxType))and
         (fxSettings)
      then
        factionsNanoFx[faction] = fxSettings
      end
    end
  end

  for faction,fx in pairs(factionsNanoFx) do
    if (not fxSupported(fx.fxtype or "noneNANO")) then
      factionsNanoFx[faction] = factionsNanoFx.default
    end

    local factionNanoFx = factionsNanoFx[faction]
    factionNanoFx.delaySpread = 30
    factionNanoFx.fxtype = factionNanoFx.fxtype:lower()
    if ((Lups.Config["quality"] or 3)>=3)and((factionNanoFx.fxtype=="nanolasers")or(factionNanoFx.fxtype=="nanolasersshader")) then
      factionNanoFx.flare = true
    end

    --// parse lua code in the table, so we can execute it later
    ParseLuaCode(factionNanoFx)
  end

end

  function gadget:Initialize()
    gadgetHandler:AddSyncAction("nano_GameFrame",      GameFrame)
  end

  function gadget:Shutdown()
    gadgetHandler:RemoveSyncAction("nano_GameFrame")
  end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
end
