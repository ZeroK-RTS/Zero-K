local widgetName = "Automatic Tip Dispenser"

local playerID = Spring.GetMyPlayerID()
local rank = playerID and select(9, Spring.GetPlayerInfo(playerID, false))

function widget:GetInfo()
	return {
		name = widgetName,
		desc = "v0.4 Teach you to play the game, one tip at a time",
		author = "KingRaptor; original by zwzsg",
		date = "July 30th, 2009",
		license = "Public Domain",
		layer = 8,
		enabled = false,	-- (rank and rank == 1) or true,
		handler  = true,
	}
end

------------------------
-- speedups
local spGetGameSeconds = Spring.GetGameSeconds
local spGetMyTeamID = Spring.GetMyTeamID
local spGetTeamUnitsByDefs = Spring.GetTeamUnitsByDefs
local spGetTeamResources = Spring.GetTeamResources

------------------------
--  CONFIG
------------------------
VFS.Include("LuaUI/Configs/tipconfig.lua",nil)

local tipsList = {}
local unitTipsAvailable = {}
local alreadyDisplayedTips = {}
local tipPeriod = 8 -- How long each tip is displayed, in seconds
local FontSize = nil
local SoundTable = {}
local SoundToggle = true
local MouseButton = nil

local generalTipsIndex = math.random(1, #generalTips)

local airSpotted = false
local nukeSpotted = false

local updateFrequency = tipPeriod

local myTeam = spGetMyTeamID()

-----------------------
-- minimum complexity of tips to display
-- 1 = new to RTS
-- 2 = a bit of experience with ZK
-- 3 = up to intermediate
local helpLevel = rank and math.min(rank, 3) or 1

-- Chili classes
local Chili
local Button
local Label
local Window
local Panel
local TextBox
local Image
local Control

-- Chili instances
local screen0
local window
local image
local textBox
local close
local closeImage
local nextTip

local function SortCompareTables(t1,t2)
	table.sort(t1)
	table.sort(t2)
	if #t1~=#t2 then
		return false
	else
		for k=1,#t1 do
			if t1[k]~=t2[k] then
				return false
			end
		end
		return true
	end
end

-- The round2 function from http://lua-users.org/wiki/SimpleRound fails on 0.11
local function FormatNbr(x,digits)
	local _,fractional = math.modf(x)
	if fractional==0 then
		return x
	elseif fractional<0.01 then
		return math.floor(x)
	elseif fractional>0.99 then
		return math.ceil(x)
	else
		local ret=string.format("%."..(digits or 0).."f",x)
		if digits and digits>0 then
			while true do
				local last = string.sub(ret,string.len(ret))
				if last=="0" or last=="." then
					ret = string.sub(ret,1,string.len(ret)-1)
				end
				if last~="0" then
					break
				end
			end
		end
		return ret
	end
end

local function MakePlural(str)
	local ending=string.sub(str,string.len(str),string.len(str))
	if ending=="y" then
		return string.sub(str,1,string.len(str)-1).."ies"
	elseif ending==">" or ending=="s" then
		return str
	else
		return str.."s"
	end
end

local function WriteString(str, unitDef, plural)
	local def = (type(unitDef) == "number") and UnitDefs[unitDef] or UnitDefNames[unitDef]
	local name = Spring.Utilities.GetHumanName(def)
	if plural then name = MakePlural(name) end -- todo: use i18n for plurals
	return string.gsub(str, "<name>", name, 1)
end

local function AddTip(str, level, weight, sound, prereq)
	if prereq and (not alreadyDisplayedTips[prereq]) then return end
	level = level or 1
	if level < helpLevel then return end
	weight = weight or 1
	local text, sound = str or "", sound or nil
	tipsList[#tipsList + 1] = {weight = weight, text = text, sound = sound}
end

local function AddTipOnce(str, level, weight, sound, prereq)
	if alreadyDisplayedTips[str] then return end
	AddTip(str, level, weight, sound, prereq) 
end

local function CountMy(unitKind)
	local defs = {}
	for i in pairs(unitKind) do
		defs[#defs+1] = i
	end
	local got=spGetTeamUnitsByDefs(myTeam, defs)
	if got==nil then
		return 0
	else
		return #got
	end
end

local function CountTheirs(unitKind)
	local nGot=0
	local defs = {}
	for i in pairs(unitKind) do
		defs[#defs+1] = i
	end
	local teams = Spring.GetTeamList()
	for i=1,#teams do
		local team = teams[i]
		if not Spring.AreTeamsAllied(team,myTeam) then
			nGot=nGot+#(spGetTeamUnitsByDefs(team,defs) or {})
		end
	end
	return nGot
end

local function Prevalence(unitKind)
	local Total=Spring.GetTeamUnitCount(myTeam)
	if Total==0 then
		return 0
	else
		return CountMy(unitKind)/Total
	end
end

local function IsSelected(unitKind)
	local units = spGetTeamUnitsByDefs(myTeam,unitKind)
	for i=1,#units do
		if Spring.IsUnitSelected(units[i]) then
			return true
		end
	end
	return false
end

-- used to get weighted sum of units in existence and selected
local function PSC(unitKind,PrevalenceWeight,isSelectedWeight)
	PrevalenceWeight=PrevalenceWeight or 1
	isSelectedWeight=isSelectedWeight or 1
	return PrevalenceWeight*Prevalence(unitKind)+isSelectedWeight*(IsSelected(unitKind) and 1 or 0)
end

local function GetDamage(predator,prey)
	return WeaponDefs[UnitDefs[UnitDefNames[predator].id].weapons[1].weaponDef].damages[UnitDefs[UnitDefNames[prey].id].armorType]
end

local function GetTipsList()
	local t=myTeam
	tipsList={}

	-- add unit tips from available list
	for name, _ in pairs(unitTipsAvailable) do
		AddTipOnce(unpack(unitTips[name]))
	end
	
	-- Always shown tips

	-- General interface tips
	AddTipOnce("Use Ctrl+F11 to to move screen elements around.", 1)
	AddTipOnce("Press Esc to toggle the game menu, where you can alter settings.", 1)
	AddTipOnce("Use Mouse Wheel to zoom in and out. Hold down the mousewheel and drag to pan.", 1)

	-- Beginning: Getting the commander to build the starting base
	--[[
	if CountMy(energy) + CountMy(mex) <= 3 and spGetGameSeconds() < 30 then
		if Spring.GetTeamUnitCount(t)==0 then
			if Game.startPosType==2 and Spring.GetGameFrame()==0 then
				AddTip("Pick a starting position, then click ready.\nLook for areas with metal spots (press F4 to toggle the metal map). Do not spawn in a cliff!", 1, 5)
			--else
				--AddTip("Game is loading.", 3, 10000)
			end
		elseif CountMy(commander)==1 then
			if Spring.GetSelectedUnitsCount()==0 then
				AddTip("Select your commander and start building your base. You can select something to build by pressing right click and drawing a gesture, or using the buttons in the menu (bottom right)", 1)
			end
			local econStr1 = "Metal is the principal game resource. Build some Metal Extractors (mexes) on the metal spots."
			local econStr2 = "Energy is also essential for your economy to function. Build some Solar Collectors or Wind Generators."
			local econStr3 = "Buildpower, often described as the third resource, is the measure of how much you can spend at once. We'll discuss that later."
			AddTip(econStr1, 1, 3)
			AddTip(econStr2, 1, 3, nil, econStr1)
			AddTip(econStr3, 1, 3, nil, econStr2)
		end
	
	-- Beginning: Getting commander) to build the first fac
	elseif CountMy(energy) >= 3 and CountMy(mex)>= 1 and CountMy(factory) == 0 and spGetGameSeconds() < 60 then
		AddTip("Use your commander to make a factory. The Shieldbot Factory is a good choice for beginners.\nYour first factory is \255\255\64\0FREE\008.", 1, 5)

		-- Once the player has started getting stuff done
	else
	]]--	
		--[[if CountMy(factory)>=1 then
			AddTipOnce("Build some units with that factory. You'll want to start with a couple of constructors for expansion and a few raiders for early combat.", 1, 10)
		end --]]
		if CountMy(energy)>= 5 then
			AddTipOnce("Connect energy to your mexes to allow them to \255\255\64\0overdrive\008, which uses excess energy to produce more metal.", 1)
		end
		if CountMy(energy)>= 5 and (IsSelected(mex) or IsSelected(energy)) then
			local odStr1 = "The circles around your mexes and energy (when selected) indicate their pylon radius.\nTwo econ buildings are connected if their circles overlap."
			local odStr2 = "The color of a pylon grid denotes its efficiency. Blue is good, red is bad. Pink is unlinked."
			AddTipOnce(odStr1, 2, 1)
			AddTipOnce(odStr2, 2, 1, nil, odStr1)
		end
		if CountMy(raider) >= 1 then
			local raiderStr1 = "Fast but fragile, raiders are suitable for harassing the enemy's economy, as well as jumping skirmishers and the like."
			local raiderStr2 = "Raiders should avoid charging enemy defenses or riot units head-on."
			AddTipOnce(raiderStr1, 1, 3)
			AddTipOnce(raiderStr2,1, 2, nil, raiderStr1)
		end
		if CountMy(assault) >= 1 then
			AddTipOnce("Assault units are generally good all-rounders, but they particularly excel at punching through defensive lines.", 1, 3)
		end
		if CountMy(skirm) >= 1 then
			AddTipOnce("Skirmishers are medium-ranged units, ideal for picking off riot units and some defenses from afar. They are vulnerable to raider charges.", 1, 3)
		end
		if CountMy(riot) >= 1 then
			AddTipOnce("Riot units are slow, short-ranged, and extremely deadly. Use them to counter raiders, but do not attack defenses head-on with them.", 1, 3)
		end
		if CountMy(arty) >= 1 then
			AddTipOnce("Artillery excels at shelling enemy defenses from a safe distance. It is usually (though not always) relatively ineffective against mobile units.", 1, 3)
		end
		if CountMy(bomber) >= 1 then
			AddTipOnce("Bombers require air repair pads to reload after each run. The Aircraft Plant comes with one free pad, but you should build more to avoid long waiting lines.", 2, 5)
		end
		local mlevel, mstore = spGetTeamResources(myTeam, "metal")
		if mlevel/mstore >= 0.95 then
			AddTip("Your metal storage is overflowing. You should get more buildpower and spend it.", 2, 5)
		end
		local elevel, estore = spGetTeamResources(myTeam, "energy")
		if elevel < 80 and mlevel > elevel then
			AddTip("Your energy reserves are running dangerously low. You should build more energy structures.", 3, 10)
		end		
		
		--always tips
		AddTipOnce("Left click to select a unit.\nKeep button down to drag a selection box.",1)
		AddTipOnce("Left click in empty area to deselect units.",1)
		AddTipOnce("Right click to issue default order.\nKeep the button down to draw a formation line.",1)
		AddTipOnce("Left click an action on the menu in the bottom-left, then left click in the terrain to give specific orders.",1)
		AddTipOnce("Use the SHIFT key to enqueue orders.",1)
		
		AddTipOnce("Multiple constructors can build a structure together, or assist a factory.",2)
		AddTipOnce("Keep making constructors and nanotowers as needed to spend your resources.", 2)
		AddTipOnce("Avoid having large amounts of metal sitting in your storage. Spend it on combat units.", 2)
	--end
end

local function GetGeneralTip(index)
	local index = index or generalTipsIndex
	if index > #generalTips then index = 1 end
	local str = generalTips[index]
	generalTipsIndex = index + 1
	return str, nil
end

-- Pick a contextual tip
local function GetRandomTip()
	GetTipsList()-- Create tipsList according to what's going on
	if #tipsList >=2 then
		local w=0
		for t=1, #tipsList do
			w=w+tipsList[t].weight
		end
		local d = w*math.random()
		w=0
		for t=1, #tipsList do
			w=w+tipsList[t].weight
			if w>=d then
				local text, sound = tipsList[t].text,tipsList[t].sound
				--table.remove(tipsList, t)
				return text, sound
			end
		end
		return "Could not fetch tip",nil
	elseif #tipsList==1 then
		local text, sound = tipsList[1].text,tipsList[1].sound
		--tipsList[1] = nil
		return text, sound
	else
		return GetGeneralTip()
	end
end

-- need to regenerate textBox each time because TextBox:SetText() doesn't always do so
local function GenerateTextBox(str)
	if textBox then window:RemoveChild(textBox) end
	textBox = TextBox:New{
		parent  = window;
		text    = str or '',
		x       = image.width + image.x + 5,
		y       = 16;
		width   = window.width - 90 - 30,
		valign  = "ascender";
		align   = "left";
		font    = {
			size   = 12;
			shadow = true;
		},
	}	
end

local timer = 0
local function SetTip(str)
	local str = str or GetRandomTip()
	alreadyDisplayedTips[str] = true
	--Spring.Echo("Writing tip: "..str)
	GenerateTextBox(str)
	timer = 0	-- resets update timer if called by something other than Update()
end

function widget:Update(dt)
	timer = timer + dt
	if timer > updateFrequency then
		myTeam = spGetMyTeamID()	-- just refresh for fun
		SetTip()
		timer = 0
	end
end

--tells people not to build the expensive stuff early
function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if unitTeam ~= myTeam then return end
	local t = Spring.GetGameSeconds()
	local str
	if superweapon[-cmdID] and t < TIMER_SUPERWEAPON then
		str = WriteString(stringSuperweapon, -cmdID)
	elseif adv_factory[-cmdID] and t < TIMER_ADV_FACTORY then
		str = WriteString(stringAdvFactory, -cmdID)
	elseif expensive_unit[-cmdID] and t < TIMER_EXPENSIVE_UNITS then
		str = WriteString(stringExpensiveUnits, -cmdID)
	end
	if str then SetTip(str) end	-- bring up the tip NOW
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if unitTeam ~= myTeam then return end
	local name = UnitDefs[unitDefID].name
	if unitTips[name] then unitTipsAvailable[name] = true end
end

function widget:UnitEnteredLos(unitID, unitTeam)
	if not Spring.AreTeamsAllied(unitTeam, myTeam) then
		local unitDef = UnitDefs[Spring.GetUnitDefID(unitID)]
		if unitDef.canFly and not airSpotted then
			SetTip(stringAirSpotted)
			airSpotted = true
		elseif unitDef.name == "staticnuke" and not nukeSpotted then
			SetTip(stringNukeSpotted)
			nukeSpotted = true			
		end
	end
end

function widget:Initialize()
	if VFS.FileExists("mission.lua") then
		widgetHandler:RemoveWidget()	-- no need for tips in mission
	end
	
	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Window = Chili.Window
	Panel = Chili.Panel
	TextBox = Chili.TextBox
	Image = Chili.Image
	Control = Chili.Control
	screen0 = Chili.Screen0
	
	window = Window:New{
		parent = screen0,
		name   = 'tipwindow';
		width = 320,
		height = 100,
		right = 0; 
		bottom = 350;
		dockable = true;
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		minWidth = MIN_WIDTH,
		minHeight = MIN_HEIGHT,
		padding = {5, 0, 5, 0},
		--itemMargin  = {0, 0, 0, 0},
	}
	image = Image:New {
		width = 80,
		height = 80,
		bottom = 10,
		y= 10;
		x= 5;
		keepAspect = true,
		file = "LuaUI/Images/advisor2.jpg";
		parent = window;
	}

	GenerateTextBox()
	
	close = Button:New {
		width = 20,
		height = 20,
		y = 4,
		right = 3,
		parent=window;
		padding = {0, 0, 0,0},
		margin = {0, 0, 0, 0},
		backgroundColor = {1, 1, 1, 0.4},
		caption="";
		tooltip = "Close Tip Dispenser";
		OnClick = {function() Spring.SendCommands("luaui disablewidget ".. widgetName) end}
	}
	closeImage = Image:New {
		width = 16,
		height = 16,
		x = 2,
		y = 2,
		keepAspect = false,
		file = "LuaUI/Images/closex_16.png";
		parent = close;
	}	
		
	--sound code
	--[[
	local TipSoundFileList=VFS.DirList("sounds/tips")
	for _,FileName in ipairs(TipSoundFileList) do
		local ext=string.lower(string.sub(FileName,-4))
		if ext==".ogg" or ext==".wav" then
			local pref=string.match(FileName,".*%/(%d+)%.%a+")
			if pref and (ext==".ogg" or SoundTable[tonumber(pref) or pref]==nil) then
				SoundTable[tonumber(pref) or pref]=FileName
			end
		end
	end
	-- List the tips that do not contain side specific words:
	for _,t in ipairs({87,88,711,712,713,11,12,21,22,23,24,25,26,27,71,72,73,81,82,83,84,85,86}) do
		for s=1000,5000,1000 do
			if not SoundTable[s+t] then-- If they have no side specific voice file
				if not SoundTable[3000+t] then
					Spring.Echo("No sound for tip #"..s+t..", default #"..(3000+t).." not available either!")
				else
					SoundTable[s+t]=SoundTable[3000+t]-- Make them use the Network voice
					--Spring.Echo("No sound for tip #"..s+t..", defaulting to "..(3000+t))
				end
			end
		end
	end
	
	local function QS(a)
		if type(a)=="number" then
			return tostring(a)
		elseif type(a)=="string" then
			return "\""..a.."\""
		else
			return "("..tostring(type(a))..")"..a
		end
	end
	if Spring.IsDevLuaEnabled() then
		Spring.Echo("<SoundTable>")
		for key,value in pairs(SoundTable) do
			Spring.Echo("Soundtable["..QS(key).."]="..QS(value))
		end
		Spring.Echo("</SoundTable>")
	end
	--]]
	
	SetTip()
end


