local versionNumber = "v0.92 "
function widget:GetInfo()
  return {
    name     = "Resurrect Congregate",
    desc     = versionNumber .. "Automatically send resurrected unit to nearby blob of allied units. (1 Blob = 5 ground units within 300 elmo radius, Congregating range: 3000 elmo)",
    author   = "msafwan",
    date     = "3 November 2013",
    license  = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false
  }
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local waitDuration_gbl_cnst = 1
local blobRadius_gbl_cnst = 300
local blobUnits_gbl_cnst = 5
local congregateRange_gbl_cnst = 3000

local spGetGameFrame = Spring.GetGameFrame
local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spGetUnitPosition = Spring.GetUnitPosition
local spGetAllUnits = Spring.GetAllUnits
local spIsUnitAllied = Spring.IsUnitAllied
local spGetUnitDefID = Spring.GetUnitDefID
local spGiveOrderArrayToUnitArray = Spring.GiveOrderArrayToUnitArray

local iNotLagging_gbl = true --//variable: indicate if player(me) is lagging in current game. If I'm lagging then do not count any received units (because I might be in state of rejoining and those units I saw are probably just a replay).
local unitToMove_gbl = {}
local myTeamID_gbl = -1
local nearestBlob_gbl = congregateRange_gbl_cnst*congregateRange_gbl_cnst

function widget:GameProgress(serverFrameNum) --//see if me are lagging behind the server in the current game. If me is lagging then trigger a switch, (this switch will tell the widget to stop counting received units).
	local myFrameNum = spGetGameFrame()
	local frameNumDiff = serverFrameNum - myFrameNum
	if frameNumDiff > 120 then --// 120 frame means: a 4 second lag. Consider me is lagging if my frame differ from server by more than 4 second.
		iNotLagging_gbl = false
	else  --// consider me not lagging if my frame differ from server's frame for less than 4 second.
		iNotLagging_gbl = true
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeamID, builderID)
	if iNotLagging_gbl and
	(builderID) and --have builder (not created using /give, not morph)
	unitTeamID == myTeamID_gbl and not UnitDefs[unitDefID].isImmobile then --is mobile and our own unit
		local _,_,_,x,y,z = spGetUnitPosition(unitID,true)
		local _,_,inbuild = spGetUnitIsStunned(unitID)
		if not inbuild then --resurrected unit is instantly full health
			unitToMove_gbl[#unitToMove_gbl+1]={x,y,z,unitID, unitDefID}
		end
	end
end

function widget:Initialize()
	if Spring.GetSpectatingState() then widgetHandler:RemoveWidget() return false end --remove widget when spectating
	myTeamID_gbl = Spring.GetMyTeamID()
end

function widget:PlayerChanged(playerID)
	if Spring.GetSpectatingState() then widgetHandler:RemoveWidget() end
end

local elapsedTime = 0
function widget:Update(n)
	if not iNotLagging_gbl then
		return
	end
	elapsedTime= elapsedTime + n
	if elapsedTime < waitDuration_gbl_cnst then
		return
	end
	elapsedTime = 0
	if #unitToMove_gbl > 0 then
		local blobPositions = GetAllClusterPosition()
		if #blobPositions>0 then
			local orderArray = {}
			local unitArray = {}
			for unitIndex=1, #unitToMove_gbl do
				local nearestBlob = nearestBlob_gbl
				local closestCoordinate = {nil,nil,nil}
				for blobIndex=1, #blobPositions do
					local ux,uz = unitToMove_gbl[unitIndex][1],unitToMove_gbl[unitIndex][3]
					local bx,bz = blobPositions[blobIndex][1],blobPositions[blobIndex][3]
					local dx,dz = ux-bx , uz-bz
					local distSquared = dx*dx+dz*dz --note: usually we square-root this to get distance but for comparison we just use square (cheaper)
					if distSquared < nearestBlob then
						closestCoordinate[1] = bx
						closestCoordinate[2] = blobPositions[blobIndex][2]
						closestCoordinate[3] = bz
						nearestBlob = distSquared
					end
				end
				if closestCoordinate[1] then
					local x,y,z = closestCoordinate[1],closestCoordinate[2],closestCoordinate[3]
					local currentIndex = #orderArray+1
					orderArray[currentIndex]={CMD_RAW_MOVE, {x,y,z}, 0}
					unitArray[currentIndex] = unitToMove_gbl[unitIndex][4] --unitID
				end
			end
			if #orderArray > 0 then --we should not give empty command else it will delete all unit's existing queue
				spGiveOrderArrayToUnitArray (unitArray,orderArray, true) --send command to bulk of units
			end
		end
		unitToMove_gbl = {}
	end
end

function GetAllClusterPosition()
	if WG.OPTICS_cluster==nil then
		return {}
	end
	local units = spGetAllUnits()
	local listOfUnits ={}
	for i=1,#units do
		local unitID = units[i]
		if spIsUnitAllied(unitID) then
			local unitDefID = spGetUnitDefID(unitID)
			if not UnitDefs[unitDefID]["canFly"] then
				local x,y,z = spGetUnitPosition(unitID)
				listOfUnits[unitID] = {x,y,z}
			end
		end
	end
	local cluster, nonClustered = WG.OPTICS_cluster(listOfUnits, blobRadius_gbl_cnst,blobUnits_gbl_cnst, myTeamID,blobRadius_gbl_cnst) --//find clusters with atleast 5 unit per cluster and with at least within 300-elmo from each other
	local groupPositions ={}
	for index=1 , #cluster do
		local sumX, sumY,sumZ, unitCount,meanX, meanY, meanZ = 0,0 ,0 ,0 ,0,0,0
		for unitIndex=1, #cluster[index] do
			local unitID = cluster[index][unitIndex]
			local x,y,z= listOfUnits[unitID][1],listOfUnits[unitID][2],listOfUnits[unitID][3] --// get stored unit position
			sumX= sumX+x
			sumY = sumY+y
			sumZ = sumZ+z
			unitCount=unitCount+1
		end
		meanX = sumX/unitCount --//calculate center of cluster
		meanY = sumY/unitCount
		meanZ = sumZ/unitCount
		groupPositions[#groupPositions+1] = {meanX, meanY, meanZ}
	end
	return groupPositions
end
