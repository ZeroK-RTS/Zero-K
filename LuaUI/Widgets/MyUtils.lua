----------------------SpeedUps----------------------
spGetMyTeamID			= Spring.GetMyTeamID
spGetGaiaTeamID			= Spring.GetGaiaTeamID
spGetTeamList			= Spring.GetTeamList
spGetMyAllyTeamID		= Spring.GetMyAllyTeamID
spGetTeamInfo			= Spring.GetTeamInfo
spGetUnitTeam			= Spring.GetUnitTeam
spGetUnitDefID			= Spring.GetUnitDefID
spGetUnitPosition		= Spring.GetUnitPosition
spGetUnitHeight			= Spring.GetUnitHeight
spGetGroundOrigHeight	= Spring.GetGroundOrigHeight
spGetUnitDefDimensions	= Spring.GetUnitDefDimensions
spGetUnitBuildFacing	= Spring.GetUnitBuildFacing
spSendLuaUIMsg			= Spring.SendLuaUIMsg
spGetGameSeconds		= Spring.GetGameSeconds
spMarkerAddPoint		= Spring.MarkerAddPoint
spMarkerAddLine			= Spring.MarkerAddLine
spIsUnitAllied			= Spring.IsUnitAllied
spGetMyPlayerID			= Spring.GetMyPlayerID
spGetPlayerInfo			= Spring.GetPlayerInfo
Echo					= Spring.Echo
spGetPlayerList			= Spring.GetPlayerList
spArePlayersAllied		= Spring.ArePlayersAllied
spGetLocalPlayerID 		= Spring.GetLocalPlayerID
spGetSideData			= Spring.GetSideData
spGetSpectatingState	= Spring.GetSpectatingState
spIsReplay				= Spring.IsReplay
spGetLastAttacker		= Spring.GetUnitLastAttacker
spIsCheatingEnabled		= Spring.IsCheatingEnabled
spGetSelectedUnits		= Spring.GetSelectedUnits
spGiveOrderToUnit		= Spring.GiveOrderToUnit
spGiveOrderToUnitArray	= Spring.GiveOrderToUnitArray
spGetTeamUnits			= Spring.GetTeamUnits
spGetTeamUnitsSorted 	= Spring.GetTeamUnitsSorted
spGetUnitsInCylinder	= Spring.GetUnitsInCylinder
spGetCommandQueue		= Spring.GetCommandQueue
spGetGameFrame			= Spring.GetGameFrame
spGetTeamResources		= Spring.GetTeamResources
spGetUnitResources		= Spring.GetUnitResources
spGetUnitHealth			= Spring.GetUnitHealth
spGetUnitEstimatedPath	= Spring.GetUnitEstimatedPath
spGetGroundHeight		= Spring.GetGroundHeight
spTestBuildOrder		= Spring.TestBuildOrder
spGetGroundInfo			= Spring.GetGroundInfo
spGetUnitRulesParam		= Spring.GetUnitRulesParam
spGetGameRulesParam		= Spring.GetGameRulesParam
spGetTeamRulesParam		= Spring.GetTeamRulesParam
spValidUnitID			= Spring.ValidUnitID
spGetAllFeatures		= Spring.GetAllFeatures
spValidFeatureID		= Spring.ValidFeatureID
spGetFeatureTeam		= Spring.GetFeatureTeam
spGetFeaturesInCylinder = Spring.GetFeaturesInCylinder
spGetFeaturePosition	= Spring.GetFeaturePosition
spGetFeatureResources	= Spring.GetFeatureResources
spGetFeatureHealth		= Spring.GetFeatureHealth
spGetUnitShieldState	= Spring.GetUnitShieldState
spGetUnitIsActive		= Spring.GetUnitIsActive
spGetUnitVelocity		= Spring.GetUnitVelocity
spGetTeamUnitsByDefs 	= Spring.GetTeamUnitsByDefs
spGetPositionLosState	= Spring.GetPositionLosState

--widgetName				=widget.GetInfo().name

--------------------Game Constants------------------
LOS_MUL=64
WindTidalThreashold=-10
WindMin=spGetGameRulesParam("WindMin") or 0
WindMax=spGetGameRulesParam("WindMax") or 0
WindGroundMin=spGetGameRulesParam("WindGroundMin") or 0
WindGroundExtreme=spGetGameRulesParam("WindGroundExtreme") or 1
WindSlope=spGetGameRulesParam("WindSlope") or 0

WaterDamage=Game.waterDamage or 0

paralyzeOnMaxHealth = ( (VFS.Include("gamedata/modrules.lua") or {}).paralyze or {}).paralyzeOnMaxHealth or true

mapSizeX=Game.mapSizeX
mapSizeZ=Game.mapSizeZ

-----------------------UntDefIds--------------------

terraunit=UnitDefNames["terraunit"] --Terraform Unit

caretaker=UnitDefNames["staticcon"] --Caretaker
cormex=UnitDefNames["staticmex"] --Metal Extractor

windGen=UnitDefNames["energywind"] --Wind Generator
solar=UnitDefNames["energysolar"] --Solar Generator
geo=UnitDefNames["energygeo"] --Geothermal Generator
geoMoho=UnitDefNames["energyheavygeo"] --Moho Geothermal Generator
fusion=UnitDefNames["energyfusion"] --Fusion generator
singu=UnitDefNames["energysingu"] --Singularity reactor

storage=UnitDefNames["staticstorage"] --Storage

pylon=UnitDefNames["energypylon"] --energy transmission pylon

llt=UnitDefNames["turretlaser"] --LLT
defender=UnitDefNames["turretmissile"] --Defender
hlt=UnitDefNames["turretheavylaser"] --HLT
gauss=UnitDefNames["turretgauss"] --gauss
faraday=UnitDefNames["turretemp"] --faraday
newton=UnitDefNames["turretimpulse"] --newton
stardust=UnitDefNames["turretriot"] --stardust
ddm=UnitDefNames["turretheavy"] --DDM
anni=UnitDefNames["turretantiheavy"] --Annihilator
razor=UnitDefNames["turretaalaser"] --Razor AA
cobra=UnitDefNames["turretaaflak"] -- Cobra AA
screamer=UnitDefNames["turretaaheavy"] --Screamer AA
chainsaw=UnitDefNames["turretaafar"] --Chainsaw

urchin=UnitDefNames["turrettorp"] --Urchin

behemoth=UnitDefNames["staticarty"] --Behemoth
silo=UnitDefNames["staticmissilesilo"] --Missile Silo
silencer=UnitDefNames["staticnuke"] --Nuclear Missile Silo
protector=UnitDefNames["staticantinuke"] --Protector

advRadar=UnitDefNames["staticheavyradar"] --Advanced Radar Tower
sonar=UnitDefNames["staticsonar"] --Sonar
aegis=UnitDefNames["staticshield"] --Aegis (static shield)

gsfac=UnitDefNames["factorygunship"] --Gunship factory
airfac=UnitDefNames["factoryplane"] --Airplane factory
spiderfac=UnitDefNames["factoryspider"] --Spider factory


-----------------------Debug------------------------
function ePrint (tbl, indent)
	if not indent then indent = 0 end
	for k, v in pairs(tbl) do
		formatting = string.rep(" ", indent) .. k .. ": "

		if type(v) == "table" then
			Echo(formatting)
			ePrint(v, indent+1)
		else
			if type(v) == "boolean" or type(v) == "function" then
				Echo(formatting .. tostring(v))
			else
				Echo(formatting .. v)
			end
		end
	end
end

function ePrintEx (val, indent)
	if val==nil then Echo("nil")
	else
		if type(val) == "table" then ePrint (val, indent)
		else
			Echo(tostring(val))
		end
	end
end

function ePrintCMDQueue(commandQueueTable)
	for _, cmd in pairs(commandQueueTable) do
		ePrintCMD(cmd)
	end
end

function ePrintCMD(cmd)
	if cmd.id>=0 then
		Echo( "id: "..(CMD[cmd.id] or tostring(cmd.id)) )
	else
		Echo( "id: BUILD "..UnitDefs[-cmd.id].name )
	end
	if cmd.tag then Echo("tag: "..cmd.tag) end
	ePrintEx({params=cmd.params})
	ePrintEx({options=cmd.options})
end

function ePrintUnitDef(unitDef)
	for name,param in unitDef:pairs() do
		ePrintEx({name=name, param=param})
	end
end

function ePrintWeaponDef(weaponDef)
	for name,param in weaponDef:pairs() do
		ePrintEx({name=name, param=param})
	end
end

function ePrintFeatureDef(featureDef)
   for name,param in featureDef:pairs() do
		ePrintEx({name=name, param=param})
	end
end


--------------------Common vars----------------------
zkConstructors = {cloakcon=true, shieldcon=true, vehcon=true, hovercon=true, planecon=true, gunshipcon=true, spidercon=true, jumpcon=true, tankcon=true, amphcon=true, shipcon=true} --conjurer, convict, mason, quill, crane, weaver, freaker, welder, conch, mariner

-------------------Graph stuff-------------------

function MinimumSpanningTreeFromPoints(points)
	local reached={}
	local unreached={}
	local MST={}

	local nPoints=#points

	if nPoints>1 then
		reached[1]=true

		for i=2, nPoints do
			unreached[i]=true
		end

		local unreachedCnt=nPoints-1

		while unreachedCnt>0 do
			local minDist=math.huge
			local ix=nil
			local jx=nil

			for i=1, nPoints do
				if reached[i] then
					for j=1, nPoints do
						if unreached[j] then
							local dist=Dist2D2(points[i].x, points[j].x, points[i].z , points[j].z)
							if dist<minDist then
								minDist=dist
								ix=i
								jx=j
							end
						end
					end
				end
			end

			if ix and jx then
				reached[jx]=true
				unreached[jx]=nil
				unreachedCnt=unreachedCnt-1
				table.insert(MST, {ix, jx})
			end
		end
		return MST
	elseif nPoints==1 then
		return {}
	else
		return nil
	end
end


-------------------Geometry stuff-------------------

function Dist2D2(x0,x1,z0,z1)
	return (x1-x0)^2+(z1-z0)^2
end

function Dist3D2(x0,x1,y0,y1,z0,z1)
	return (x1-x0)^2+(y1-y0)^2+(z1-z0)^2
end

function GetLineABC(x1,x2,z1,z2)
	local A = (z1-z2)
	local B = (x2-x1)
	local C = (x1*z2-x2*z1)

	return A,B,C
end

function GetCoordOnLine(A, B, C, x0, z0, d)

	local sign
	if C<0 then sign=-1 else sign=1 end


	local lineAngle=math.atan2(-A,B)

	local x=x0+math.cos(lineAngle)*d
	local z=z0+math.sin(lineAngle)*d

	return x,z
end


--------------------Pathfinding related stuff-------------------

local function NextFunctionFull(myPath, x0, z0, x, z)
	local y0 = spGetGroundHeight(x0, z0)
	local ix, iy, iz = x0, y0, z0
	return function ()
		ix, iy, iz=myPath:Next(ix, iy, iz)
		local finished=((ix==x) and (iz==z)) or (ix==-1)
		return finished, ix, iy, iz
    end
end

local function NextFunctionLite(myPath, x0, z0, x, z)
	local y0 = spGetGroundHeight(x0, z0)
	local ix, iy, iz
	local wpPather = myPath:GetPathWayPoints()
	--ePrintEx(wpPather)
	local wpPatherCnt=#wpPather
	local iter=1
	return function ()
		local finished=(iter==wpPatherCnt)
		if iter<=wpPatherCnt then
			ix, iy, iz=wpPather[iter][1], wpPather[iter][2], wpPather[iter][3]
			iter=iter+1
		end
		--ePrintEx({x=ix, y=iy, z=iz, f=finished})
		--Echo("")
		return finished, ix, iy, iz
    end
end

local function GetETALine(wp1, wp2, moveDef, unitDefSpeed)
	local deltaY=wp2.y-wp1.y

	local deltaXZ=math.sqrt((wp2.x-wp1.x)^2 + (wp2.z-wp1.z)^2) --sqrt(dx^2+dz^2)
	local deltaP=math.sqrt(deltaXZ^2+deltaY^2)

	local slopeValue=1.0-deltaXZ/deltaP

	local speedMod
	if deltaY>0 then speedMod = 1.0 / (1.0 + slopeValue * moveDef.slopeMod) else speedMod = 1.0 end

	local ttime=deltaP/(unitDefSpeed*speedMod)
	return ttime
end

function ETA2ArriveImpl(unitId, x, z, nextFunctionProducer)

	local unitDefId=spGetUnitDefID(unitId)
	local unitDefSpeed=UnitDefs[unitDefId].speed
	local moveDef = UnitDefs[unitDefId].moveDef

	local y = spGetGroundHeight(x, z)
	local x0, y0, z0 = spGetUnitPosition(unitId)

	local myPath=nil

	local myPath = nil

	local radius = 32
	if moveDef.id~=nil then
		myPath = Spring.RequestPath(moveDef.id, x0, y0, z0, x, y, z, radius) --16?
	end

	--ePrintEx({myPath=myPath})

	if myPath then
		--spMarkerAddPoint(x, y, z, "!")
		local wpPather, idxes = myPath:GetPathWayPoints()
		--ePrintEx({wpPather=wpPather, idxes=idxes})

		local wp1={x=x0, y=y0, z=z0}
		local wp2

		local ttime=0
		local wpEntries=0
		local myNextFunction=nextFunctionProducer(myPath, x0, z0, x, z)
		local fin=false

		while (wpEntries<500) and (not fin) do
			local ix, iy, iz
			--Echo("wpEntries="..wpEntries)
			--Echo("finished_prior="..tostring(fin))
			fin, ix, iy, iz = myNextFunction()
			--Echo("finished_after="..tostring(fin))
			--ePrintEx({f=fin, x=ix, y=iy, z=iz})

			if (ix==-1 and iz==-1) then return math.huge end --unreachable
			if (ix==nil and iz==nil) then break end --path doesn't have entries, presumably endpoint is nearby
			wp2={x=ix, y=iy, z=iz}

			--ePrintEx{{wp1=wp1, wp2=wp2}}

			--spMarkerAddLine( wp1.x, wp1.y, wp1.z, wp2.x, wp2.y, wp2.z )
			--spMarkerAddLine( wp1.x, 0, wp1.z, wp2.x, 0, wp2.z )

			wpEntries=wpEntries+1

			ttime=ttime+GetETALine(wp1, wp2, moveDef, unitDefSpeed)
			wp1=wp2
		end

		wp2={x=x, y=y, z=z}
		--spMarkerAddLine( wp1.x, 0, wp1.z, wp2.x, 0, wp2.z )

		local D=math.sqrt(Dist2D2(wp1.x, wp2.x, wp1.z, wp2.z))
		--ePrintEx({wp2=wp2})
		--Echo("D="..D)

		if D>radius+20 then --unreachable on last point
			return math.huge
		end

		ttime=ttime+GetETALine(wp1, wp2, moveDef, unitDefSpeed)

		--Spring.MarkerErasePosition(x, y, z)

		return ttime
	else --we are very close
		ttime=math.sqrt(Dist2D2(x0,x,z0,z))/unitDefSpeed
		return ttime
	end
end

function ETA2ArriveFull(unitId, x, z)
	--Echo("ETA2ArriveFull")
	return ETA2ArriveImpl(unitId, x, z, NextFunctionFull)
end

function ETA2ArriveCrude(unitId, x, z)
	--Echo("ETA2ArriveCrude")
	return ETA2ArriveImpl(unitId, x, z, NextFunctionLite)
end

--------------------Eco utils -----------------------
myTeamId=spGetMyTeamID()
gaiaTeamId = spGetGaiaTeamID()

--------------------Construction Stuff---------------

function IsBuildingbyUDef(unitDef)
	return unitDef and (unitDef.isFactory==true or unitDef.canMove==false or unitDef.isBuilding==true)
end

function IsBuildingbyUdID(udId)
	local unitDef=UnitDefs[udId]
	return IsBuildingbyUDef(unitDef)
end

function IsBuildingbyUID(uId)
	local udId=spGetUnitDefID(uId)
	return IsBuildingbyUdID(udId)
end

local biggestSize=nil
local function GetBiggestUnitSize()
	if not biggestSize then
		biggestSize=0
		for udId, unitDef in pairs(UnitDefs) do
			if IsBuildingbyUDef(unitDef) then --immobile object
				local usize=math.max(unitDef.xsize or 0, unitDef.zsize or 0)
				if biggestSize<usize then
					biggestSize=usize
				end
			end
		end
	end
	return biggestSize*4 --normalize
end

function GetBuildingDimensions(uDefID, facing)
	local bDef = UnitDefs[uDefID]
	if (facing % 2 == 1) then
		return 4 * bDef.zsize, 4 * bDef.xsize
	else
		return 4 * bDef.xsize, 4 * bDef.zsize
	end
end

local function IsBlockingUnitInCylinderEx(bx, bz, bw, bh, cylRadius, exceptions) --xsize, zsize should already be normalized
	local maxCylRadius=cylRadius+2*GetBiggestUnitSize()+10 --just in case
	local cylRadius2=cylRadius^2
	local unitsInCyl=spGetUnitsInCylinder(bx, bz, maxCylRadius)

	local rect={{x=bx-bw, z=bz-bh},
				{x=bx-bw, z=bz+bh},
				{x=bx+bw, z=bz+bh},
				{x=bx+bw, z=bz-bh}}

	for _, uId in pairs(unitsInCyl) do
		local udId=spGetUnitDefID(uId)
		if udId and IsBuildingbyUdID(udId) and (not exceptions[udId]) then
			local facing=spGetUnitBuildFacing(uId)
			local bx1, _, bz1 = spGetUnitPosition(uId)
			local bw1, bh1 = GetBuildingDimensions(udId, facing)


			local rect1={{x=bx1-bw1, z=bz1-bh1},
						 {x=bx1-bw1, z=bz1+bh1},
						 {x=bx1+bw1, z=bz1+bh1},
						 {x=bx1+bw1, z=bz1-bh1}}
			for _, pr in pairs(rect) do
				for _, pr1 in pairs(rect1) do
					local dist2d=Dist2D2(pr.x, pr1.x, pr.z, pr1.z)
					if dist2d<cylRadius2 then
						return true
					end
				end
			end
		end
	end
	return false
end

local function IsBlockingUnitInCylinder(x, z, cylRadius, exceptions)
	local unitsInCyl=spGetUnitsInCylinder(x, z, cylRadius)
	--Echo("cylRadius="..cylRadius.." #unitsInCyl=="..#unitsInCyl)
	for _, uId in pairs(unitsInCyl) do
		local udId=spGetUnitDefID(uId)
		if udId and IsBuildingbyUdID(udId) and (not exceptions[udId]) then --found a unit that cannot be moved except for exceptions
			--Echo("Unit Name "..UnitDefs[udId].humanName)
			return true
		end
	end
	--else
	return false
end

function GetSuitableBuildSiteDirectedMaximumDistant(unitDefID, x0, z0, xt, zt, desiredDistance, minDist, attempts, facing, coneAngle, exceptions)

	if not(exceptions) then exceptions={} end

	local xs, zs=4*UnitDefs[unitDefID].xsize, 4*UnitDefs[unitDefID].zsize

	local A, B, C=GetLineABC(x0, xt, z0, zt)

	local x, z=GetCoordOnLine(A, B, C, x0, z0, desiredDistance)

	local result
	result=spTestBuildOrder(unitDefID, x, 0 ,z, facing)

	if (result>0) and not IsBlockingUnitInCylinderEx(x, z, xs, zs, minDist, exceptions) then
		return x, z
	end

	x, z = nil

	local theta=math.atan2(-A,B)
	local minDist2d=math.huge

	if not coneAngle then coneAngle=90 end

	while attempts>=0 do
		local phi=math.random(-coneAngle, coneAngle)*math.pi/180
		local R=math.random(desiredDistance)

		local xr=x0+R*math.cos(phi+theta)
		local zr=z0+R*math.sin(phi+theta)

		local dist2d=Dist2D2(xr,xt,zr,zt)

		if dist2d<minDist2d then
			result=spTestBuildOrder(unitDefID, xr, 0 ,zr, facing)
			if (result>0) and not IsBlockingUnitInCylinderEx(xr, zr, xs, zs, minDist, exceptions) then
				--spMarkerAddPoint(xr, 0, zr, "", true)
				minDist2d=dist2d
				x=xr
				z=zr
			end
		end
		attempts=attempts-1
	end

	return x, z
end

function GetSuitableBuildSite(builderUnitId, unitDefID, x0, z0, searchRadius, minDist, attempts, facing, exceptions)

	local x, z=x0, z0

	if not(exceptions) then exceptions={} end

	local xs, zs=4*UnitDefs[unitDefID].xsize, 4*UnitDefs[unitDefID].zsize

	local result
	result=spTestBuildOrder(unitDefID, x, 0 ,z, facing)

	if (result>0) and not IsBlockingUnitInCylinderEx(x, z, xs, zs, minDist, exceptions) then
		return x, z
	end

	x, z = nil

	local minDist2d=math.huge

	while attempts>=0 do
		local phi=math.random(0, 360)*math.pi/180
		local R=math.random(searchRadius)

		local xr=x0+R*math.cos(phi)
		local zr=z0+R*math.sin(phi)

		local dist2d=Dist2D2(xr,x0,zr,z0)

		--if dist2d<minDist2d and dist2d>minDist^2 then
		if dist2d<minDist2d then
			result=spTestBuildOrder(unitDefID, xr, 0 ,zr, facing)
			if (result>0) and not IsBlockingUnitInCylinderEx(xr, zr, xs, zs, minDist, exceptions) then
				--spMarkerAddPoint(xr, 0, zr, "", true)
				minDist2d=dist2d
				x=xr
				z=zr
			end
		end
		attempts=attempts-1
	end

	return x, z
end

-------------------Bitwise stuff---------------------
--[[
--http://lua-users.org/lists/lua-l/2002-09/msg00134.html

local tab = {  -- tab[i][j] = xor(i-1, j-1)
  {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, },
  {1, 0, 3, 2, 5, 4, 7, 6, 9, 8, 11, 10, 13, 12, 15, 14, },
  {2, 3, 0, 1, 6, 7, 4, 5, 10, 11, 8, 9, 14, 15, 12, 13, },
  {3, 2, 1, 0, 7, 6, 5, 4, 11, 10, 9, 8, 15, 14, 13, 12, },
  {4, 5, 6, 7, 0, 1, 2, 3, 12, 13, 14, 15, 8, 9, 10, 11, },
  {5, 4, 7, 6, 1, 0, 3, 2, 13, 12, 15, 14, 9, 8, 11, 10, },
  {6, 7, 4, 5, 2, 3, 0, 1, 14, 15, 12, 13, 10, 11, 8, 9, },
  {7, 6, 5, 4, 3, 2, 1, 0, 15, 14, 13, 12, 11, 10, 9, 8, },
  {8, 9, 10, 11, 12, 13, 14, 15, 0, 1, 2, 3, 4, 5, 6, 7, },
  {9, 8, 11, 10, 13, 12, 15, 14, 1, 0, 3, 2, 5, 4, 7, 6, },
  {10, 11, 8, 9, 14, 15, 12, 13, 2, 3, 0, 1, 6, 7, 4, 5, },
  {11, 10, 9, 8, 15, 14, 13, 12, 3, 2, 1, 0, 7, 6, 5, 4, },
  {12, 13, 14, 15, 8, 9, 10, 11, 4, 5, 6, 7, 0, 1, 2, 3, },
  {13, 12, 15, 14, 9, 8, 11, 10, 5, 4, 7, 6, 1, 0, 3, 2, },
  {14, 15, 12, 13, 10, 11, 8, 9, 6, 7, 4, 5, 2, 3, 0, 1, },
  {15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, },
}


function bxor (a,b)
  local res, c = 0, 1
  while a > 0 and b > 0 do
    local a2, b2 = math.fmod (a, 16), math.fmod(b, 16)
    res = res + tab[a2+1][b2+1]*c
    a = (a-a2)/16
    b = (b-b2)/16
    c = c*16
  end
  res = res + a*c + b*c
  return res
end


local ff = 2^32 - 1
function bnot (a) return ff - a end

function band (a,b) return ((a+b) - bxor(a,b))/2 end

function bor (a,b) return ff - band(ff - a, ff - b) end
]]--

function checkbitmask(value, bitmask)
	return (math.bit_and(value, bitmask)==bitmask)
end

--------------------Common stuff---------------------


function table_concat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end


function math.round(a)
	return math.floor(a+0.5)
end

function math.floorBy(a, factor)
	return math.floor(a/factor)*factor
end

function CheckSpecState(widgetname)
	--Echo("spIsReplay="..tostring(spIsReplay()))
	 if (spGetSpectatingState() or spIsReplay()) and (not Spring.IsCheatingEnabled()) then
		Echo("<"..widgetname..">".." Spectator mode or replay. Widget removed.")
		widgetHandler:RemoveWidget()
		return true
	end
	return false
end

function IsDisabled(uId)
	return IsParalized(uId) or IsDisarmed(uId)
end

function IsParalized(uId)
	local health, maxHealth, paralyzeDamage, _, _ = spGetUnitHealth(uId) --paralyzeDamage>maxHealth
	if paralyzeOnMaxHealth then
		return paralyzeDamage>maxHealth
	else
		return paralyzeDamage>health
	end
end

function IsDisarmed(uId)
	local disarmed = spGetUnitRulesParam(uId,"disarmed") or 0
	return disarmed==1
end

function IsBuilt(uId)
	local  _, _, _, _, buildProgress=spGetUnitHealth(uId)
	return (buildProgress>=1)
end


function IsCommanderByUID(uId)
	local udId=spGetUnitDefID(uId)
	return IsCommanderByUDID(udId)
end

function IsCommanderByUDID(udId)
	--if udId and UnitDefs[udId] and UnitDefs[udId].commander then
	if udId and UnitDefs[udId] and UnitDefs[udId].customParams and UnitDefs[udId].customParams.commtype then
		return true
	else
		return false
	end
end

function FilterConstructors(unitIds)
	conses={}
	for _, uId in pairs(unitIds) do
		if spValidUnitID(uId) then --we only work with valid units, TODO check if alive?
			local uDefId=spGetUnitDefID(uId)
			if zkConstructors[UnitDefs[uDefId].name] or uDefId==caretaker.id or IsCommanderByUDID(uDefId) then
				table.insert(conses, uId)
			end
		end
	end

	return conses
end

function FilterMobileConstructors(unitIds)
	mobileConses={}
	for _, uId in pairs(unitIds) do
		if spValidUnitID(uId) then --we only work with valid units, TODO check if alive?
			local uDefId=spGetUnitDefID(uId)
			if zkConstructors[UnitDefs[uDefId].name] or IsCommanderByUDID(uDefId) then
				table.insert(mobileConses, uId)
			end
		end
	end

	return mobileConses
end

function PriorityToNumber(priority)
	local prioNum
	priority=string.lower(priority or "")
	if 	priority=="low" then
		prioNum=0
	elseif priority=="normal" then
		prioNum=1
	elseif priority=="high" then
		prioNum=2
	else
		prioNum=nil
	end
	return prioNum
end


function spairs(t, order) --sorted pairs
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function List2Hash(list)
	local hash={}
	for _, li in pairs(list) do
		hash[li]=true
	end
	return hash
end

function Hash2List(hash)
	local list={}
	for hi, hv in pairs(hash) do
		if hv and hv==true then
			table.insert(list, hi)
		end
	end
	return list
end
