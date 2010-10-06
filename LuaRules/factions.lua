-- $Id: factions.lua 3481 2008-12-19 16:37:33Z jk $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    factions.lua
--  brief:   determines the faction of an unit
--  author:  jK
--
--  Copyright (C) 2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

for udid,udef in ipairs(UnitDefs) do
  udef.factions = {}
end


local function AddFaction(ud,faction,scaned)
  for i=1,#scaned do
    if (scaned[i]==ud.id) then return end
  end
  scaned[#scaned+1] = ud.id

  if (ud.factions) then
    if (not ud.factions[faction]) then
      ud.factions[faction] = true
      ud.factions[#(ud.factions)+1] = faction
      for i=1,#ud.buildOptions do
        AddFaction(UnitDefs[ud.buildOptions[i]],faction,scaned)
      end
    end
  end
end


--[[
for i,sideData in ipairs(sides) do
  AddFaction(UnitDefNames[sideData.startUnit],sideData.sideName,{})
end
--]]


AddFaction(UnitDefNames['armcom'],'arm',{})
AddFaction(UnitDefNames['corcom'],'core',{})
AddFaction(UnitDefNames['nest'],'chicken',{})
AddFaction(UnitDefNames['roostfac'],'chicken',{})
AddFaction(UnitDefNames['roost'],'chicken',{})
AddFaction(UnitDefNames['thicket'],'chicken',{})

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

for udid,udef in ipairs(UnitDefs) do
  if ((#udef.factions)==0) then
    local lowname = udef.name:lower()
    if (lowname:sub(1,3)=='cor') then
      AddFaction(udef,'core',{})
    elseif (lowname:sub(1,3)=='arm') then
      AddFaction(udef,'arm',{})
    elseif (lowname:sub(1,5)=='chick') then
      AddFaction(udef,'chicken',{})
    end
  end
end
