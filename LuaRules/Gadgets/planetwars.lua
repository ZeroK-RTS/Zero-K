-- $Id: planetwars.lua 3572 2008-12-28 17:34:37Z licho $
function gadget:GetInfo()
	return {
		name = "Planet Wars Support",
		desc = "Integrates Planet Wars into Spring",
		author = "lurker",
		date = "2008-10-05",
		license = "Public Domain",
		layer = -5,
		enabled = false
	}
end

if (gadgetHandler:IsSyncedCode()) then

include("LuaRules/colors.h.lua")

local PWOptions = nil
local PWUnits = {}
local timelimits = {}
local purchaseOptions = {}
local money = {}
local commanders = {}
local hostName = nil
local purchasePositions = {}
local buildFacing = {}
local player_teamnums = {}

local Spring = Spring
local GetGroundHeight = Spring.GetGroundHeight
local TestBuildOrder = Spring.TestBuildOrder
local CreateUnit = Spring.CreateUnit
local random = math.random
local min = math.min
local max = math.max
local spawnRadSq = 500 * 500

local CMD_PURCHASE = 32601
local MAX_PURCHASE = CMD_PURCHASE - 1

local function MakeUnitGhosted(unitID) 
	for _, allyTeamID in pairs(Spring.GetAllyTeamList()) do
		Spring.SetUnitLosState(unitID, allyTeamID, { prevLos=true })
	end
end


local function SpawnMobiles(teamnum) --Do not run this from Initialize()
	local x,y,z = Spring.GetTeamStartPosition(teamnum)
	local teamOptions = PWOptions.teams[teamnum]

	if teamOptions and teamOptions.mobiles then
		local spawnTries, tryx, tryy, tryz, randRadius, unitDef
		for _,m in pairs(teamOptions.mobiles) do repeat --hack because there is no continue
			if not (type(m)=='table' and type(m.unitname)=='string') then
				Spring.Echo('Planet Wars error: broken unit table for team ' .. teamnum)
				break
			end
			if not UnitDefNames[m.unitname] then
				Spring.Echo('Planet Wars error: ' .. m.unitname .. ' not found')
				break
			end
			if m.owner~=nil and type(m.owner)~='string' then
				Spring.Echo('Planet Wars error: broken unit table for team ' .. teamnum)
				break
			end
			spawnTries = 0
			unitDef = UnitDefNames[m.unitname]
			
			if unitDef.isCommander then
				for _, uid in pairs(Spring.GetTeamUnits(teamnum)) do
					local defID = Spring.GetUnitDefID(uid)
					if (defID ~= nil and UnitDefs[defID] ~= nil and UnitDefs[defID].isCommander and UnitDefs[defID].name ~= "chickenbroodqueen") then
						-- GG.boostHandler.AddBoost(uid,2000,2000) --double boost disabled
						break
					end
				end
				break
			end
			
			randRadius = 150
			while(true) do
				tryx = random(x - randRadius, x + randRadius)
				tryz = random(z - randRadius, z + randRadius)
				tryy = GetGroundHeight(tryx, tryz)
				if TestBuildOrder(unitDef.id, tryx, tryy, tryz, 'N') or spawnTries > 20 then
					local isBuilding = (unitDef.isBuilding == true or unitDef.maxAcc == 0)
					local unitID
					if isBuilding then -- structure
						unitID = CreateUnit("armpwdeploy", tryx, tryy, tryz, 'N', teamnum) -- todo determine side name
					else
						unitID = CreateUnit(m.unitname, tryx, tryy, tryz, 'N', teamnum)
					end
					
					local PWUnit = { -- TODO: make a function for these three
						origDef = UnitDefNames[m.unitname],
						currentDef = UnitDefNames[isBuilding and "armpwdeploy" or m.unitname],
						owner = m.owner or teamOptions.name or 'Player'..teamnum,
						team = teamnum,
					}

					SendToUnsynced('PWCreate', teamnum, unitID)
					PWUnits[unitID] = PWUnit
					
					if isBuilding then
						GG.morphHandler.AddExtraUnitMorph(unitID, UnitDefNames[m.unitname], teamnum, {into = m.unitname, time = 20, metal=0, energy=0,})
					end
					
					break
				else
					spawnTries = spawnTries + 1
					randRadius = randRadius + 50
				end
			end 
		until true end
	end
end

local function IsReallyBuilding(unitDef)
  -- nanotowers are acutally immobile ground units
  return unitDef.isBuilding or unitDef.speed < 0.1
end

local function InitUnsafe()
	if type(PWOptions.hostName)~='string' then PWOptions.hostName = nil end
	if type(PWOptions.teams)~='table' then PWOptions.teams = {} end
	if type(PWOptions.allyteams)~='table' then PWOptions.allyteams = {} end
	hostName = PWOptions.hostname
	--for teamnum,team in pairs(PWOptions.teams) do
	for _,team in pairs(PWOptions.teams) do
		local teamnum = player_teamnums[team.name]
		if teamnum then
			if type(team.structures)~='table' then team.structures = {} end
			if type(team.mobiles)~='table'    then team.mobiles = {}    end
			if type(team.purchases)~='table'  then team.purchases = {}  end
			if type(team.money)~='number'     then team.money = 0       end
				team.money = math.floor(team.money)
				money[teamnum] = team.money
			
			purchaseOptions[teamnum] = {}
			for _,p in pairs(team.purchases) do repeat --hack because there is no continue
				if not (type(p)=='table' and type(p.unitname)=='string') then
					Spring.Echo('Planet Wars error: broken purchases table for team ' .. teamnum)
					break
				end
				local unitDef = UnitDefNames[p.unitname]
				if not unitDef then
					Spring.Echo('Planet Wars error: ' .. p.unitname .. ' not found')
					break
				end
				local purchaseO = {}
				MAX_PURCHASE = MAX_PURCHASE + 1
				purchaseOptions[teamnum][MAX_PURCHASE] = purchaseO
				Spring.SetCustomCommandDrawData(MAX_PURCHASE,"purchase",{0,1,0,1},false)
				
				purchaseO.unitname = p.unitname
				purchaseO.unitDef = unitDef
				purchaseO.cost = math.floor(IsReallyBuilding(unitDef) and unitDef.metalCost/2 or unitDef.metalCost)
				purchaseO.owner = p.owner or team.name or 'Player'..teamnum
				purchaseO.teamnum = teamnum
				purchaseO.order = {
					id     = MAX_PURCHASE,
					type   = CMDTYPE.ICON_MAP,
					name   = 'Purchase',
					cursor = 'purchase',
					action = 'purchase',
					texture = '#' .. unitDef.id,
					tooltip = 'Free* '..unitDef.humanName..'!\n'..(unitDef.tooltip)..GreyStr..'\n\n*details apply',
				}
			until true end
			
			for _,s in pairs(team.structures) do
				if type(s)=='table' and s.x and s.z then
					local unitID = CreateUnit(s.unitname, s.x, 0, s.z, s.orientation or 'S', teamnum)
					MakeUnitGhosted(unitID) 
					local PWUnit = {
						origDef = UnitDefNames[s.unitname],
						currentDef = UnitDefNames[s.unitname],
						owner = s.owner or team.name or 'Player'..teamnum,
						team = teamnum,
					}
					SendToUnsynced('PWCreate', teamnum, unitID)
					PWUnits[unitID] = PWUnit
				end
			end
		end
	end
	if type(PWOptions.init)=='function' then PWOptions.init() end
end



function gadget:Initialize()
	local err, success, options, optionsRaw, optionsFunc
	local modOptions = Spring.GetModOptions()
	
	if ((modOptions) and modOptions.planetwars and modOptions.planetwars ~= '') then
		optionsRaw = modOptions.planetwars
		optionsRaw = string.gsub(optionsRaw, '_', '=')
		optionsRaw = Spring.Utilities.Base64Decode(optionsRaw)
		optionsFunc, err = loadstring(optionsRaw)
		if optionsFunc then
			success,options = pcall(optionsFunc)
			if success then
				GG.PlanetWars = {}
				GG.PlanetWars.options = options
				GG.PlanetWars.units = PWUnits
			else
				err = options
				options = nil
			end
		end
		if err then 
			Spring.Echo('Planet Wars error: ' .. err)
		end
	end
	
	PWOptions = options or {}
	
end

function gadget:GameFrame(f)
	if f%30 == 9 then

		if f < 30 then
			--for teamnum,team in pairs(PWOptions.teams) do
			for _,team in pairs(PWOptions.teams) do
				local teamnum = player_teamnums[team.name]
				if teamnum then		
					local success,err = pcall(SpawnMobiles, teamnum)
					if err then 
						Spring.Echo('Planet Wars error: ' .. err)
					end
				end
			end
			for allynum,ally in pairs(PWOptions.allyteams) do
				if ally.timelimit then
					timelimits[allynum] = ally.timelimit * 60 * 30
				end
			end
		end
		for allynum, timelimit in pairs(timelimits) do
			if f > timelimit then
				Spring.Echo('AllyTeam ' .. allynum .. ' forgot to check their stove.')
				if PWOptions.hostName then
					Spring.SendCommands("w "..PWOptions.hostName.." pwtimelimit:"..allynum)
				end
			end
		end
		for unitID,PWUnit in pairs(PWUnits) do
			SendToUnsynced('PWCreate', PWUnit.team, unitID)
		end
	end
end

local function RemovePurchases(unitID)
	for number=CMD_PURCHASE,MAX_PURCHASE,1 do
		local cmdDescID = Spring.FindUnitCmdDesc(unitID, number)
		if (cmdDescID) then
			Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end
end

--Spring.EditUnitCmdDesc(unitID, cmdDescID, morphCmdDesc)
local function AddPurchases(unitID, teamID)
	for poID,po in pairs(purchaseOptions[teamID] or {}) do
		if (money[teamID] or 0) >= po.cost then
			po.order.tooltip = 'Free* '..po.unitDef.humanName..'!\n'..(po.unitDef.tooltip)..GreyStr..
			'\n\n*costs '..po.cost..' of your '..money[teamID]..' PW credits'
			Spring.InsertUnitCmdDesc(unitID, po.order)
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID) -- TODO: rez and capture
	if UnitDefs[unitDefID].isCommander then
		commanders[teamID] = commanders[teamID] or {}
		commanders[teamID][unitID] = true
		AddPurchases(unitID, teamID)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if commanders[teamID] then commanders[teamID][unitID] = nil end
	if PWUnits[unitID] and hostName then
		local PWUnit = PWUnits[unitID]
		local x,y,z = Spring.GetUnitPosition(unitID)
		local data = PWUnit.owner..","..PWUnit.origDef.name..","..PWUnit.currentDef.name..","..math.floor(x)..","..math.floor(z)
		Spring.SendCommands("w "..hostName.." pwdeath:"..data)
		PWUnits[unitID] = nil
	end
end

function gadget:RecvLuaMsg(msg, playerID)
	if (msg:find("buildfacing:",1,true)) then
		local _,_,_,teamID = Spring.GetPlayerInfo(playerID)
		buildFacing[teamID] = tonumber(msg:sub(13,13))
	elseif (msg:find("playername:",1,true)) then
		local name = msg:gsub('.*:([^=]*)=.*', '%1')
		local id = msg:gsub('.*:.*=(.*)', '%1')
		player_teamnums[name] = tonumber(id)
	elseif (msg:find("playernames",1,true)) then
		success, err = pcall(InitUnsafe)
		if err then 
			Spring.Echo('Planet Wars error: ' .. err)
		end	
		Spring.AssignMouseCursor("purchase","cursorpurchase",true,true)
		local allUnits = Spring.GetAllUnits()
		for _, unitID in pairs(allUnits) do
			local udid = Spring.GetUnitDefID(unitID)
			if udid then
				gadget:UnitCreated(unitID, udid, Spring.GetUnitTeam(unitID))
			end
		end
	end	
end

function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID < CMD_PURCHASE or cmdID > MAX_PURCHASE) then
		return false --command was not used
	end
	if not UnitDefs[unitDefID].isCommander then
		return true, true --command was used, remove it
	end
	local po = purchaseOptions[teamID] and purchaseOptions[teamID][cmdID]
	local cmdx,cmdy,cmdz = unpack(cmdParams)
	local purchasePos = cmdx * 10000 + cmdz
	if po and money[teamID] > po.cost and not purchasePositions[purchasePos] then
		purchasePositions[purchasePos] = true
		local x,y,z = Spring.GetUnitPosition(unitID)
		if ((x-cmdx)*(x-cmdx) + (z-cmdz)*(z-cmdz)) < spawnRadSq then
			money[teamID] = money[teamID] - po.cost
			local newUnit = CreateUnit(po.unitname, cmdx, cmdy, cmdz, buildFacing[teamID] or 'S', teamID)
			Spring.SetUnitMoveGoal(unitID, x, y, z, 400)
			MakeUnitGhosted(newUnit) 
			
			local PWUnit = {
				origDef = UnitDefNames[po.unitname],
				currentDef = UnitDefNames[po.unitname],
				owner = po.owner,
				team = teamID,
			}
			--Spring.SendMessage(po.owner.." is dropping "..UnitDefNames[po.unitname].name)
			SendToUnsynced('PWCreate', teamID, newUnit)
			PWUnits[newUnit] = PWUnit
			
			if hostName then
				local data = po.owner..","..po.unitname..","..math.floor(po.cost)..","..math.floor(cmdx)..","..math.floor(cmdz)
				local toSend = "w "..hostName.." pwpurchase:"..data
				SendToUnsynced("whisper", toSend, po.teamnum)
			end
			for comID,_ in pairs(commanders[teamID]) do
				RemovePurchases(comID)
				AddPurchases(comID, teamID)
			end
		else
			Spring.SetUnitMoveGoal(unitID, cmdx, cmdy, cmdz, 400)
			return true, false --command was used, do not remove it
		end
	end
	return true, true --command was used, remove it
end

function gadget:Shutdown()
	local allUnits = Spring.GetAllUnits()
	for _,unitID in pairs(Spring.GetAllUnits()) do
		RemovePurchases(unitID)
	end
end


else -- Unsynced


local GetMyAllyTeamID = Spring.GetMyAllyTeamID
local GetSpectatingState = Spring.GetSpectatingState
local buildFacing = nil
local GetBuildFacing = Spring.GetBuildFacing
local SendLuaRulesMsg = Spring.SendLuaRulesMsg

function gadget:Initialize()
  gadgetHandler:AddSyncAction('PWCreate',WrapToLuaUI)
  gadgetHandler:AddSyncAction("whisper", whisper)
  
	local playerroster = Spring.GetPlayerList()
	local playercount = #playerroster
	for i=1,playercount do
		local name,_,_,teamID = Spring.GetPlayerInfo(playerroster[i])
		SendLuaRulesMsg('playername:'..name..'='..teamID)
	end
	SendLuaRulesMsg('playernames')
end

local function whisper(_, message, teamnum)
  if teamnum == Spring.GetLocalTeamID() then
    Spring.SendCommands(message)
  end
end

function WrapToLuaUI(name, teamID, ...)
--	if teamID ~= 'all' and GetMyAllyTeamID() ~= teamID then
--		local spec, fullview = GetSpectatingState()
--		if not spec and fullview then return end
--	end
	if (Script.LuaUI(name)) then
		Script.LuaUI[name](...)
	end
end

function gadget:Update()
	if (buildFacing ~= GetBuildFacing()) then
		buildFacing = GetBuildFacing()
		SendLuaRulesMsg('buildfacing:'..buildFacing)
	end 
end

function gadget:Shutdown()
	gadgetHandler:RemoveSyncAction('PWCreate')
end

end
