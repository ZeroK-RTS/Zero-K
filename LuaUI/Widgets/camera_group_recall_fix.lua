--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Group Recall Fix",
    desc      = "Fix group recall camera not panning correctly for freestyle camera and allow camera to cycle thru grouped units. Options at: Settings/Camera",
    author    = "msafwan",
    version   = "1.0",
    date      = "26 November 2012",
    license   = "none",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

local spGetUnitPosition = Spring.GetUnitPosition
local spGetTimer = Spring.GetTimer 
local spDiffTimers = Spring.DiffTimers
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitGroup = Spring.GetUnitGroup
local spGetGroupList  = Spring.GetGroupList 


include("keysym.h.lua")
local previousGroup =99
local currentIteration = 1
local previousKey = 99
local previousTime = spGetTimer()
local myTeamID

options_path = 'Settings/Camera' --//for use 'with gui_epicmenu.lua'
options = {
	enableCycleView = {
		name = "Group recall cycle focus",
		type = 'bool',
		value = false,
		desc = "Cycle camera focus over available units when tapping on the group number. This option will turn on \'Receive Indicator\' widget for cluster detection.",
		OnChange = function(self) 
			if self.value==true then
				Spring.SendCommands("luaui enablewidget Receive Units Indicator")
			end
		end,
	},
}

function widget:Initialize()
	myTeamID= Spring.GetMyTeamID()
end

function widget:KeyPress(key, modifier, isRepeat)
	if ( not modifier.alt and not modifier.meta) then --check key for group. Reference: unit_auto_group.lua by Licho
		local gr
		if (key == KEYSYMS.N_0) then gr = 0 
		elseif (key == KEYSYMS.N_1) then gr = 1
		elseif (key == KEYSYMS.N_2) then gr = 2 
		elseif (key == KEYSYMS.N_3) then gr = 3
		elseif (key == KEYSYMS.N_4) then gr = 4
		elseif (key == KEYSYMS.N_5) then gr = 5
		elseif (key == KEYSYMS.N_6) then gr = 6
		elseif (key == KEYSYMS.N_7) then gr = 7
		elseif (key == KEYSYMS.N_8) then gr = 8
		elseif (key == KEYSYMS.N_9) then gr = 9
		end
		if (gr ~= nil) then
			local selectedUnit = spGetSelectedUnits()
			local groupCount = spGetGroupList()
			if groupCount[gr] ~= #selectedUnit then
				return false
			end
			for i=1,#selectedUnit do
				local unitGroup = spGetUnitGroup(selectedUnit[i])
				if unitGroup~=gr then
					return false
				end
			end
			if previousKey == key and (spDiffTimers(spGetTimer(),previousTime) > 2) then
				currentIteration = 0 --reset cycle if delay between 2 similar tap took too long.
			end
			previousKey = key
			previousTime = spGetTimer()
			
			if options.enableCycleView.value and WG.recvIndicator then 
				local slctUnitUnordered = {}
				for i=1 , #selectedUnit do
					local unitID = selectedUnit[i]
					local x,y,z = spGetUnitPosition(unitID)
					slctUnitUnordered[unitID] = {x,y,z}
				end
				selectedUnit = nil
				local cluster, lonely = WG.recvIndicator.OPTICS_cluster(slctUnitUnordered, 600,2, myTeamID,300) --//find clusters with atleast 2 unit per cluster and with at least within 300-elmo from each other with 600-elmo detection range
				if previousGroup == gr then
					currentIteration = currentIteration +1
					if currentIteration > (#cluster + #lonely) then
						currentIteration = 1
					end
				else
					currentIteration = 1
				end
				if currentIteration <= #cluster then
					local sumX, sumY,sumZ, unitCount,meanX, meanY, meanZ = 0,0 ,0 ,0 ,0,0,0
					for unitIndex=1, #cluster[currentIteration] do
						local unitID = cluster[currentIteration][unitIndex]
						local x,y,z= slctUnitUnordered[unitID][1],slctUnitUnordered[unitID][2],slctUnitUnordered[unitID][3] --// get stored unit position
						sumX= sumX+x
						sumY = sumY+y
						sumZ = sumZ+z
						unitCount=unitCount+1
					end
					meanX = sumX/unitCount --//calculate center of cluster
					meanY = sumY/unitCount
					meanZ = sumZ/unitCount
					Spring.SetCameraTarget(meanX, meanY, meanZ,0.5)
				else
					local unitID = lonely[currentIteration-#cluster]
					local x,y,z= slctUnitUnordered[unitID][1],slctUnitUnordered[unitID][2],slctUnitUnordered[unitID][3] --// get stored unit position
					Spring.SetCameraTarget(x,y,z,0.5)
				end
				cluster=nil
				slctUnitUnordered = nil
			else --conventional method:
				local sumX, sumY,sumZ, unitCount,meanX, meanY, meanZ = 0,0 ,0 ,0 ,0,0,0
				for i=1, #selectedUnit do
					local unitID = selectedUnit[i]
					local x,y,z= spGetUnitPosition(unitID)
					sumX= sumX+x
					sumY = sumY+y
					sumZ = sumZ+z
					unitCount=unitCount+1
				end
				meanX = sumX/unitCount --//calculate center
				meanY = sumY/unitCount
				meanZ = sumZ/unitCount
				Spring.SetCameraTarget(meanX, meanY, meanZ,0.5) --is overriden by Spring.SetCameraTarget() at cache.lua.
			end
			previousGroup= gr
			return true
		end
	end
end
