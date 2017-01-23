-- $Id: unit_stealth.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  THIS ISN'T THE ORIGINAL! (it contains a bugfix by jK)
--
--  file:    unit_stealth.lua
--  brief:   adds active unit stealth capability
--  author:  Dave Rodgers (bugfixed by jK)
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function gadget:GetInfo()
  return {
    name      = "UnitStealth",
    desc      = "Adds active unit stealth capability",
    author    = "trepan (bugfixed by jK)",
    date      = "May 02, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

function gadget:UnitCloaked(unitID)
	Spring.SetUnitStealth(unitID, true)
	Spring.SetUnitSonarStealth(unitID, true)
end

function gadget:UnitDecloaked(unitID)
	Spring.SetUnitStealth(unitID, false)
	Spring.SetUnitSonarStealth(unitID, false)
end