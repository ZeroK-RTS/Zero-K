-- FIXME: autodetect cobscript in gadget instead of defining it here

------------------------------------------------------------------------------------------------------------------------------------------------
-- Improved jumpjets def, enjoy
-- Smoth
------------------------------------------------------------------------------------------------------------------------------------------------	

local jumpers			= {} -- list of units with class stats
local jumpClassGroups	= {} -- lists of units stored within a list based on grouping
local jumpCategory		= {} -- base category for jumpjet types 
local overCategory		= {} -- override category for jumpjet types 

 -- used when checking to see if a unit was bad and should be removed.
local IsBadDef			= false
-- just present for readability
local name 

------------------------------------------------------------------------------------------------------------------------------------------------
-- this is just an error checking block, not our configuration area
-- 
--		range			-- required
--		height		-- required
--		speed			-- required
--		reload		-- optional
--		aaShootMe		-- optional
------------------------------------------------------------------------------------------------------------------------------------------------	

  
jumpCategory = { 
	baseclass = {
		range = 400, height = 200, speed = 6,  reload = 10,  aaShootMe = false, delay = 0, cobscript = true, rotateMidAir = true},	
	-- category containining only optional tags for testing error code only.
	-- iammissingstuff ={
	-- 	reload	= 10, aaShootMe	= false, },	
	commrecon1 = {
		range = 400, height = 200, speed = 6,  reload = 20,  aaShootMe = false, delay = 0, cobscript = false, rotateMidAir = true},
	commrecon2 = {
		range = 500, height = 240, speed = 6,  reload = 20,  aaShootMe = false, delay = 0, cobscript = false, rotateMidAir = true},
	commrecon3 = {
		range = 600, height = 280, speed = 6,  reload = 20,  aaShootMe = false, delay = 0, cobscript = false, rotateMidAir = true},			
}

jumpClassGroups = {

	baseclass = { 
	"corpyro",
	"corfast",
	"corsktl",
	"corcan",
	"chicken_leaper",
	"armaak",
	"corclog",
	"corsumo",
	"factoryjump",
	-- "pizzathehut",--bad unit left for testing purposes
	},
	commrecon1 = {},
	commrecon2 = {},
	commrecon3 = {},
	-- iammissingstuff = {--bad category
	-- "puffthemagic",--bad unit left for testing purposes
	-- },
	
	-- idontexist = {--nonexistant category
	-- "chillichilli",--bad unit left for testing purposes
	-- },
}

for name,data in pairs(UnitDefNames) do
	if data.customParams.jumpclass then
		local class = jumpClassGroups[data.customParams.jumpclass]
		class[#class+1] = name
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------
-- Unit overrides
-- 
--		range	
--		height
--		speed
--		reload
------------------------------------------------------------------------------------------------------------------------------------------------	
overCategory = {
 corcan = {
    speed = 4,},

 chicken_leaper = {
    range = 600, reload = 2, },
	
 armaak = {
    delay = 20, cobscript = false},	
	
 corsumo = {
    delay = 30, height = 100, range = 300, reload = 13, cobscript = false, rotateMidAir = false},	

-- corpyro = {
	-- range = 400, height = 200, speed = 6,  reload = 10, },	
}


------------------------------------------------------------------------------------------------------------------------------------------------
-- this is just an error checking block, not our configuration area
-- I know n^2, bite me... see error checking comment
------------------------------------------------------------------------------------------------------------------------------------------------
Spring.Echo("Jump Jet Defs error checking begining..")
for groupId,groupcluster in pairs(jumpClassGroups) do

	for i=1,#groupcluster do
	
		name = jumpClassGroups[groupId][i]
		
		if (UnitDefNames[name]) then -- I am half awake, hey at least someone did some kind of error checking...
			if ( not jumpCategory[groupId] ) then 
				Spring.Echo("   Jump Jet Defs error: (bad jumpjet category: " .. groupId .. " does not exist)")
				IsBadDef = true
			else
				if ( not jumpCategory[groupId].range ) then
					Spring.Echo("   Jump Jet Defs error: (Unit: " .. name .. " missing required parameter range)")
					IsBadDef = true
				end
				
				if ( not jumpCategory[groupId].height ) then
					Spring.Echo("   Jump Jet Defs error: (Unit: " .. name .. " missing required parameter height)")
					IsBadDef = true
				end
				
				if ( not jumpCategory[groupId].speed ) then
					Spring.Echo("   Jump Jet Defs error: (Unit: " .. name .. " missing required parameter speed)")	
					IsBadDef = true			
				end
				
				if ( not jumpCategory[groupId].delay ) then
					Spring.Echo("   Jump Jet Defs error: (Unit: " .. name .. " missing required parameter delay)")	
					IsBadDef = true			
				end
				if ( jumpCategory[groupId].cobscript == nil ) then
					Spring.Echo("   Jump Jet Defs error: (Unit: " .. name .. " missing required parameter cobscript)")	
					IsBadDef = true			
				end
				if ( jumpCategory[groupId].rotateMidAir == nil ) then
					Spring.Echo("   Jump Jet Defs error: (Unit: " .. name .. " missing required parameter rotateMidAir)")	
					IsBadDef = true			
				end
			end
		else -- unit exists, lets make sure he has proper values
			IsBadDef = true
			Spring.Echo("   Jump Jet Defs error: (Unit name not found: " .. name .. " )")
			Spring.Echo(i)
		end	
		
		if ( IsBadDef == false ) then
			local default = jumpCategory[groupId]
			jumpers[name] = {range=default.range, height=default.height, speed=default.speed, reload=(default.reload or nil), delay=default.delay, cobscript=default.cobscript, rotateMidAir=default.rotateMidAir}
		else
			Spring.Echo("   Jump Jet Defs error: (Unit not added: " .. name .. " )")
			IsBadDef = false 
		end
		
	end
	
end
Spring.Echo(".. Jump Jet Defs error checking complete")	
------------------------------------------------------------------------------------------------------------------------------------------------
-- This section allows for overrides, when inidvidual units need to be slightly different but don't justify their own class
-- 
------------------------------------------------------------------------------------------------------------------------------------------------
for uName,uOvers in pairs(overCategory) do
		if (UnitDefNames[uName]) then -- extra error checking because people are stupid
			if ( uOvers.speed == jumpers[uName].speed) then
				Spring.Echo("   Jump Jet Defs warning: ( " .. uName .. " has unneeded speed override )")
			end
			
			if ( uOvers.reload == jumpers[uName].reload) then
				Spring.Echo("   Jump Jet Defs warning: ( " .. uName .. " has unneeded reload override )")
			end
			
			if ( uOvers.range == jumpers[uName].range) then
				Spring.Echo("   Jump Jet Defs warning: ( " .. uName .. " has unneeded range override )")
			end
			
			if ( uOvers.height == jumpers[uName].height) then
				Spring.Echo("   Jump Jet Defs warning: ( " .. uName .. " has unneeded height override )")
			end
			
			if ( uOvers.delay == jumpers[uName].delay) then
				Spring.Echo("   Jump Jet Defs warning: ( " .. uName .. " has unneeded delay override )")
			end
			
			if ( uOvers.cobscript == jumpers[uName].cobscript) then
				Spring.Echo("   Jump Jet Defs warning: ( " .. uName .. " has unneeded warning override )")
			end
			
			if ( uOvers.rotateMidAir == jumpers[uName].rotateMidAir) then
				Spring.Echo("   Jump Jet Defs warning: ( " .. uName .. " has unneeded warning override )")
			end
			
			jumpers[uName].speed	= ( uOvers.speed or jumpers[uName].speed)

			jumpers[uName].reload	= ( uOvers.reload or jumpers[uName].reload)

			jumpers[uName].range	= ( uOvers.range or jumpers[uName].range)

			jumpers[uName].height	= ( uOvers.height or jumpers[uName].height)
			
			jumpers[uName].delay	= ( uOvers.delay or jumpers[uName].delay)
			
			if uOvers.cobscript ~= nil then
				jumpers[uName].cobscript = uOvers.cobscript
			end
			
			if uOvers.rotateMidAir ~= nil then
				jumpers[uName].rotateMidAir = uOvers.rotateMidAir
			end
		
		end
end

--for i,f in pairs(jumpers) do
--Spring.Echo("   ",i,f.range, f.height, f.speed, f.reload , f.cobscript)
--end	

-- YAY!!!!! DONE!
return jumpers
