-- $Id$
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  author:  jK
--
--  Copyright (C) 2010.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local SCRIPT_DIR = Script.GetName() .. '/'
local GADGETS_DIR = SCRIPT_DIR .. 'Gadgets/'

local gh = gadgetHandler.gadgetHandler

--// export GADGET_DIR, so gadgets can easily load e.g. config.lua
--// from the same dir where the main.lua is placed
local oldNewGadget = gh.NewGadget
local curdir = ""
gh.NewGadget = function(self,dir)
    local gadget = oldNewGadget(self)
    gadget.GADGET_DIR = curdir
    return gadget
end

--// load all Gadgets/*/main.lua gadgets
local subdirs = VFS.SubDirs(GADGETS_DIR)
for i=1,#subdirs do
    curdir = subdirs[i]
    local gf = curdir .. "main.lua"
    if (VFS.FileExists(gf)) then
	local g = gh:LoadGadget(gf)
	if g then
	    gh:InsertGadget(g)
	    local name = g.ghInfo.name
	    print(string.format("Loaded gadget:  %-18s  <%s>", name, gf))
	end
    else
    
    end
end

--// reset
gh.NewGadget = oldNewGadget
