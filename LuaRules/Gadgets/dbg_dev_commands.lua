
function gadget:GetInfo()
  return {
    name      = "Dev Commands",
    desc      = "Adds useful commands.",
    author    = "Google Frog",
    date      = "12 Sep 2011",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local spIsCheatingEnabled = Spring.IsCheatingEnabled

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end

-- '/luarules give'
-- '/luarules gk'
-- '/luarules clear'

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function give(cmd,line,words,player)
	if spIsCheatingEnabled() then
		local buildlist = UnitDefNames["armcom1"].buildOptions
		local INCREMENT = 128
		for i = 1, #buildlist do
			local udid = buildlist[i]
			local x, z = INCREMENT, i*INCREMENT
			local y = Spring.GetGroundHeight(x,z)
			Spring.CreateUnit(udid, x, y, z, 0, 0, false)
			local ud = UnitDefs[udid]
			if ud.buildOptions and #ud.buildOptions > 0 then
				local sublist = ud.buildOptions
				for j = 1, #sublist do
					local subUdid = sublist[j]
					local x2, z2 = (j+1)*INCREMENT, i*INCREMENT
					local y2 = Spring.GetGroundHeight(x2,z2)
					Spring.CreateUnit(subUdid, x2, y2, z2, 0, 0, false)
				end	
			end
		end
	end
end

local function gentleKill(cmd,line,words,player)
	if spIsCheatingEnabled() then
		local units = Spring.GetAllUnits()
		for i=1, #units do
			local unitID = units[i]
			Spring.SetUnitHealth(unitID,0.1)
			Spring.AddUnitDamage(unitID,1, 0, nil, -7)
		end
	end
end

local function clear(cmd,line,words,player)
	if spIsCheatingEnabled() then
		local units = Spring.GetAllUnits()
		for i=1, #units do
			local unitID = units[i]
			Spring.DestroyUnit(unitID, false, true)
		end
		local features = Spring.GetAllFeatures()
		for i=1, #features do
			local featureID = features[i]
			Spring.DestroyFeature(featureID)
		end
	end
end

function gadget:Initialize()
	gadgetHandler:AddChatAction("give",give,"Like give all but without all the crap.")
	gadgetHandler:AddChatAction("gk",gentleKill,"Gently kills everything.")
	gadgetHandler:AddChatAction("clear",clear,"Clears all units and wreckage.")
end