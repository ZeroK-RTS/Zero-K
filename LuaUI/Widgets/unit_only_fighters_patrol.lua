--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_only_fighters_patrol.lua
--  brief:   Only fighters go on factory's patrol route after leaving airlab. Reduces lag.
--  author:  dizekat
--  based on Factory Kickstart by Owen Martindell aka TheFatController
--
--  Copyright (C) 2008
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:GetInfo()
	return {
		name	= "Only Fighters Patrol",
		desc	= "Only fighters go on factory's patrol route after leaving airlab. Reduces lag.",
		author	= "dizekat",
		date	= "2008-04-22",
		license	= "GNU GPL, v2 or later",
		layer	= 0,
		enabled	= true,
		handler   = true
	}
end

local opts={
stop_builders=true -- Whever to stop builders or not. Set to true if you dont use factory guard widget.
--,FactoryGuard_workaround=true
}

local OrderUnit = Spring.GiveOrderToUnit
local GetMyTeamID = Spring.GetMyTeamID
local GetCommandQueue = Spring.GetCommandQueue
local GetUnitBuildFacing = Spring.GetUnitBuildFacing
local GetUnitPosition = Spring.GetUnitPosition

local mustStop = {
	[UnitDefNames.armcybr.id] = true,
	[UnitDefNames.armstiletto_laser.id] = true,
	[UnitDefNames.corhurc2.id] = true,
	[UnitDefNames.corshad.id] = true,
}

--[[
local function WeaponCanTargetAir(weapon)
	local wd = WeaponDefs[ weapon.weaponDef ]
	for name,param in wd:pairs() do
		Spring.Echo("wd:",name,param)
	end
	categories=wd.onlyTargetCategories
	if categories then
		for name,value in pairs(categories) do
			Spring.Echo("wdtc:",name,value)
		end
	end
end

local function UnitCanTargetAir(unitDefID)
	local ud=UnitDefs[unitDefID]
	for i=1,table.getn(ud.weapons) do
		if WeaponCanTargetAir(ud.weapons[i]) then
			return true
		end
	end
	return false
end
]]--
local function UnitHasPatrolOrder(unitID)
	local queue=GetCommandQueue(unitID)
	for i,cmd in ipairs(queue) do
		if cmd.id==CMD.PATROL then
			return true
		end
	end
	return false
end
local function MustStop(unitID, unitDefID)
	local ud=UnitDefs[unitDefID]
	if ud and mustStop[unitDefID] and UnitHasPatrolOrder(unitID) then
		if (not opts.stop_builders)and ud and ud.builder then
			return false
		end
		--[[
		if opts.FactoryGuard_workaround then
			local factoryGuard = widgetHandler.knownWidgets["FactoryGuard"]
			if factoryGuard and factoryGuard.name and (widgetHandler.orderList[factoryGuard.name]>0) then
				if ud and ud.builder and ud.canAssist then
					return false
				end
			end			
		end	
		]]--		
		return true
	end
	return false
end
			
function widget:UnitFromFactory(unitID, unitDefID, unitTeam, factID, factDefID, userOrders)
	if (unitTeam ~= GetMyTeamID()) then
		return
	elseif (userOrders) then
		return
	end
	local bd = UnitDefs[factDefID]
	if (not (bd and bd.isFactory)) then
		return
	end
	local ud=UnitDefs[unitDefID]
	--- liche: workaround for BA (liche is fighter)
	if MustStop(unitID, unitDefID) then
		Spring.GiveOrderToUnit(unitID,CMD.STOP,{},{})
	else
	--[[	
		Spring.Echo("-----")
		for name,param in ud:pairs() do
			Spring.Echo(name,param)
		end
	]]--
	end
	
	--if ud.humanName=="Liche" then
	--	UnitCanTargetAir(unitDefID)
	--end
end