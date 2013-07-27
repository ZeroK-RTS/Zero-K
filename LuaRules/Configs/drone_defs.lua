-- reloadTime is in seconds

local carrierDefs = {}

local carrierDefNames = {
	armcarry = { {drone = UnitDefNames.carrydrone.id, reloadTime = 15, maxDrones = 8, spawnSize = 2, range = 1600} },
	--corcrw = { {drone = UnitDefNames.attackdrone.id, reloadTime = 15, maxDrones = 6, spawnSize = 2, range = 900} },
	funnelweb = { 
		{drone = UnitDefNames.attackdrone.id, reloadTime = 15, maxDrones = 6, spawnSize = 2, range = 600},
		{drone = UnitDefNames.battledrone.id, reloadTime = 20, maxDrones = 2, spawnSize = 1, range = 600},
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- what does this part do? it ensures compatibility with takeover, no need to edit any other part of the file or define new units

local modOptions = {}
if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()
end

if (modOptions and (modOptions.zkmode == "takeover")) then
  CopyTable = Spring.Utilities.CopyTable
  MergeTable = Spring.Utilities.MergeTable
  
  local tk_unitlist = VFS.Include("LuaRules/Configs/takeover_config.lua") or {}
  tk_unitlist = (tk_unitlist ~= nil) and tk_unitlist.Units
  for tar, data in pairs(carrierDefNames) do
    for _, target_name in pairs (tk_unitlist) do
      if tostring(tar) == target_name then
	local name = target_name
	local newname = name.."_tq"
	local new_carrier
	if (type(data) == "table") then
	  new_carrier = {
	    [newname] = {}
	  }
	  local num=1
	  for inner_name, inner_data in pairs(data) do
	    new_carrier[newname][num] = {
	      drone	= inner_data.drone,
	      reloadTime= inner_data.reloadTime,
	      maxDrones	= inner_data.maxDrones,
	      spawnSize	= inner_data.spawnSize,
	      range	= inner_data.range,
	    }
	    num=num+1
	  end
	end
	if (new_carrier ~= nil) then
	  carrierDefNames = MergeTable(carrierDefNames, new_carrier, true)
	end
      end
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local presets = {
	module_companion_drone = {drone = UnitDefNames.attackdrone.id, reloadTime = 10, maxDrones = 2, spawnSize = 1, range = 450},
	module_battle_drone = {drone = UnitDefNames.battledrone.id, reloadTime = 20, maxDrones = 1, spawnSize = 1, range = 600},
}

--[[
for name, ud in pairs(UnitDefNames) do
	if ud.customParams.sheath_preset then
		sheathDefNames[name] = Spring.Utilities.CopyTable(presets[ud.customParams.sheath_preset], true)
	end
end
]]--
for id, ud in pairs(UnitDefs) do
	if ud.customParams and ud.customParams.drones then
		local droneFunc = loadstring("return "..ud.customParams.drones)
		local drones = droneFunc()
		carrierDefs[id] = {}
		for i=1,#drones do
			carrierDefs[id][i] = Spring.Utilities.CopyTable(presets[drones[i]])
		end
	end
end

for name, data in pairs(carrierDefNames) do
	if UnitDefNames[name] then carrierDefs[UnitDefNames[name].id] = data	end
end

local thingsWhichAreDrones = {
	[UnitDefNames.carrydrone.id] = true,
	[UnitDefNames.attackdrone.id] = true,
	[UnitDefNames.battledrone.id] = true
}
	

return carrierDefs, thingsWhichAreDrones