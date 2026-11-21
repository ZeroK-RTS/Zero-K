-- This file is part of Zero-K (GPL v2 or later), see LICENSE.
function gadget:GetInfo()
	return {name="Portal native factory regression",layer=10000,enabled=true}
end
if Spring.GetModOptions().zk_duels_test ~= "factories" then return false end
if not gadgetHandler:IsSyncedCode() then
	local accelerated = false
	function gadget:Update()
		if not accelerated and Spring.GetGameFrame() > 0 then
			accelerated = true; Spring.SendCommands("setspeed " .. (Spring.GetModOptions().zk_duels_speed or 1))
		end
		if Spring.GetGameRulesParam("portal_factory_test_done") == 1 then Spring.SendCommands("quitforce") end
	end
	return
end
local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
local portalMode = world ~= nil
if not world then
	world = {regions={{x0=0,z0=0,x1=Game.mapSizeX,z1=Game.mapSizeZ}},teams={{team=0,region=1}}}
end
local cases, checks, failures = {}, 0, 0
local function Check(name, pass)
	checks = checks + 1
	if not pass then failures = failures + 1 end
	Spring.Echo("[PORTAL_FACTORIES] ASSERT " .. name .. " pass=" .. tostring(not not pass))
end
function gadget:UnitCreated(id, def, team, builder)
	for _, case in ipairs(cases) do
		if builder == case.factory and def == case.product then case.children[#case.children+1] = id end
	end
end
function gadget:GameFrame(frame)
	if frame == 30 then
		for region, r in ipairs(world.regions) do
			local team
			for _, entry in ipairs(world.teams) do if entry.region == region then team = entry.team; break end end
			-- Controlled flat production lanes isolate queue/callback correctness.
			local x, z = (r.x0+r.x1)/2, (r.z0+r.z1)/2
			Spring.LevelHeightMap(x-500,z-500,x+500,z+500,200)
			for index, pair in ipairs({{"factorycloak","cloakraid"},{"factorygunship","gunshipraid"}}) do
				local px = x + (index-1)*400 - 200
				local factory = assert(Spring.CreateUnit(pair[1],px,200,z,0,team))
				Spring.SetUnitBuildSpeed(factory,2000)
				Spring.SetTeamResource(team,"ms",100000)
				Spring.SetTeamResource(team,"es",100000)
				Spring.SetTeamResource(team,"m",100000)
				Spring.SetTeamResource(team,"e",100000)
				local case = {factory=factory,product=UnitDefNames[pair[2]].id,region=region,children={},x=px,z=z,team=team}
				cases[#cases+1] = case
				local handler = gadgetHandler.gadgetHandler
				Check("native_queue_"..region.."_"..index, handler:AllowUnitCreation(case.product,factory,team))
				if portalMode then
					Check("foreign_position_"..region.."_"..index,
						not handler:AllowUnitCreation(case.product,factory,team,-100,200,-100,0))
				end
				Spring.GiveOrderToUnit(factory,-case.product,{},0)
			end
		end
	end
	if frame > 30 and frame < 900 and frame % 30 == 0 then
		for _, case in ipairs(cases) do
			Spring.SetTeamResource(case.team,"m",100000); Spring.SetTeamResource(case.team,"e",100000)
		end
	end
	if frame == 900 then
		for i, case in ipairs(cases) do
			Check("actual_child_"..i,#case.children > 0)
			local child = case.children[1]
			local x, _, z = Spring.GetUnitPosition(child or -1)
			Check("local_finished_child_"..i,child and Spring.ValidUnitID(child)
				and (not portalMode or world.Region(x,z)==case.region)
				and select(5,Spring.GetUnitHealth(child))==1
				and (not portalMode or GG.PortalWorlds.home[child]==case.region))
		end
		Spring.Echo("[PORTAL_FACTORIES] DONE checks="..checks.." failures="..failures)
	end
	if frame == 930 then Spring.SetGameRulesParam("portal_factory_test_done",1) end
end
