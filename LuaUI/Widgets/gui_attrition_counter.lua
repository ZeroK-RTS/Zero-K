local version = 1.001
function widget:GetInfo()
  return {
    name      = "1v1 Attrition Scoreboard",
    desc      = "Shows a counter that keeps track of units you lost and killed (only for 1v1)",
    author    = "Anarchid",
    date      = "Dec 2012",
    license   = "GPL",
    layer     = -10,
    enabled   = false  --  loaded by default?
  }
end

local abs = math.abs
local echo = Spring.Echo
local GetMyTeamID = Spring.GetMyTeamID
local GetUnitRulesParam = Spring.GetUnitRulesParam
local GetUnitHealth = Spring.GetUnitHealth;
local floor = math.floor;
local Chili
local myTeam

local visible = {}
local nanoframes = {}
local spectating = Spring.GetSpectatingState();
local killedUnits = 0
local killedMetal = 0
local lostUnits = 0
local lostMetal = 0

local window;
local killed_units;
local lost_units;
local attrition;

function widget:Initialize()
	Chili = WG.Chili
	
	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	
	
	local allyTeam = Spring.GetMyAllyTeamID()
	local teams = Spring.GetTeamList()
	local allies = 0
	
	myTeam = GetMyTeamID();
	
	for i = 1, #teams do
		local teamId,_,_,_,_,ally = Spring.GetTeamInfo(teams[i])
		if teamId~=myTeam and ally == allyTeam then
			echo('<Attrition>: You are strictly prohibited by Authority from using Attrition Scoreboard in team games, and will be punished by strict spanking.');
			widgetHandler:RemoveWidget();
			return;
		end
	end
	
	if spectating then
		echo('<Attrition>:Running in spectator state.');
	end
	
	CreateWindow()
end

function widget:Shutdown()
	if window then window:Dispose() end
end

function updateCounters()
	killed_units:SetCaption(killedUnits..' ('..floor(killedMetal)..'m)');
	lost_units:SetCaption(lostUnits..' ('..floor(lostMetal)..'m)');
	
	if lostMetal==0 then
		if killedMetal>0 then
			attrition_counter:SetCaption('PWN!');
			attrition_counter.font.color={0,0,1,1}
		else
			attrition_counter:SetCaption('NAN%')
			attrition_counter.font.color={1,1,1,0.5}
		end
	else
		rate = killedMetal/lostMetal;
		
		if(rate>=1) then
			rateCaption = tostring(floor(rate*100))..'%';
			attrition_counter.font.color={0,1,0,1}
		else
			if rate>0.75 then
				attrition_counter.font.color={1,1,0,1}
			elseif rate>0.5 then
				attrition_counter.font.color={1,0.5,0,1}
			else
				attrition_counter.font.color={1,0,0,1}
			end
			rateCaption = tostring(floor(rate*100))..'%';
		end
		attrition_counter:SetCaption(rateCaption);
	end
end


function widget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
	local ud = UnitDefs[unitDefID];
	if not ud.customParams.dontcount then
		if teamID == myTeam then			
			if GetUnitRulesParam(unitID, 'wasMorphedTo') then	
				visible[unitID] = nil;
			else 
				local _,_,_,_,built = GetUnitHealth(unitID);
				lostUnits=lostUnits+1;
				lostMetal=lostMetal+UnitDefs[unitDefID].metalCost*built;
				updateCounters()
			end
		elseif spectating then
			if GetUnitRulesParam(unitID, 'wasMorphedTo') then	
				visible[unitID] = nil;
			else 
				local _,_,_,_,built = GetUnitHealth(unitID);
				killedUnits = killedUnits + 1;
				killedMetal = killedMetal + UnitDefs[unitDefID].metalCost*built;
				visible[unitID] = nil
				updateCounters()
			end
		end
	end
end

function widget:UnitEnteredLos(uID, tID)
	local udid = Spring.GetUnitDefID(uID);
	local ud = UnitDefs[udid];
	
	if ud.customParams.dontcount ~= 1 and tID ~= myTeam then
		visible[uID] = {
			cost=ud.metalCost,
			team=tID
		}
		
		local _,_,_,_,built = GetUnitHealth(uID);
		
		if built < 1  then
			nanoframes[uID] = built;
		end
	end
end

function widget:UnitLeftLos(uID)
	visible[uID] = nil;
	nanoframes[uID] = nil;
end

function widget:GameFrame(n)
    for uID, kill in pairs(visible) do
        if not Spring.GetUnitDefID(uID) then
			if(kill.team ~= myTeam ) then
					if nanoframes[uID] then kill.cost = kill.cost * nanoframes[uID] end
					killedUnits = killedUnits + 1;
					killedMetal = killedMetal + kill.cost;
					visible[uID] = nil;
					nanoframes[uID] = nil;
					updateCounters()
			end
		elseif nanoframes[uID] then
			local _,_,_,_,built = GetUnitHealth(uID);
			if built < 1 then
				nanoframes[uID] = built;
			else
				nanoframes[uID] = nil;
			end
        end
    end
end

function CreateWindow()	
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	
	--// WINDOW
	window = Chili.Window:New{
		color = {1,1,1,0.8},
		parent = Chili.Screen0,
		dockable = true,
		name="AttritionCounter",
		padding = {5,5,5,5},
		right = 0,
		y = 20,
		clientWidth  = 500,
		clientHeight = 35,
		minHeight = 35,
		minWidth = 150,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
        minimizable = true,
		parentWidgetName = widget:GetInfo().name, --for gui_chili_docking.lua (minimize function)
	}
	
 	killed_caption = Chili.Label:New{
 		x = '0%',
 		y = '5%',
 		width = 12,
 		parent = window,
 		caption = "CK:",
 		fontsize = 13,
 		textColor = {0.5,1,0.5,1},
 	}
 	
 	killed_units = Chili.Label:New{
 		y = '0%',
 		right = '50%',
 		width = 12,
 		parent = window,
 		caption = "0 (0m)",
 		fontsize = 15,
 		textColor = {1,1,1,1},
 	}

 	lost_caption = Chili.Label:New{
 		x = '0%',
 		y = '55%',
 		width = 12,
 		parent = window,
 		caption = "KIA:",
 		fontsize = 13,
 		textColor = {1,0.5,0.5,1},
 	}
 	
 	lost_units = Chili.Label:New{
 		y = '50%',
 		right = '50%',
 		width = 12,
 		parent = window,
 		caption = "0 (0m)",
 		fontsize = 15,
 		textColor = {1,1,1,1},
 	}
 	
 	attrition_counter = Chili.Label:New{
 		y = '5%',
 		right = '0%',
 		width = 24,
 		parent = window,
 		caption = "N/A",
 		fontsize = 40,
 		textColor = {1,1,1,0.5},
 	}
	
	return
end

function DestroyWindow()
	window:Dispose()
	window = nil
end
