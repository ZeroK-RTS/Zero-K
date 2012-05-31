local playerID = Spring.GetMyPlayerID()
local customkeys = playerID and select(10, Spring.GetPlayerInfo(playerID))
local rank = (customkeys and tonumber(customkeys.level) or 0) or select(9, Spring.GetPlayerInfo(playerID))

function widget:GetInfo()
	return {
		name = "Clippy Comments",
		desc = "v0.4 Makes units give tips.",
		author = "KingRaptor",
		date = "2011.5.6",
		license = "Public Domain",
		layer = 0,
		enabled = true,	-- (rank and rank == 1) or true,
	}
end

------------------------
-- speedups
local spGetGameSeconds = Spring.GetGameSeconds
local spGetMyTeamID = Spring.GetMyTeamID
local spGetTeamUnitsByDefs = Spring.GetTeamUnitsByDefs
local spGetTeamResources = Spring.GetTeamResources
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitHealth = Spring.GetUnitHealth

------------------------
--  CONFIG
------------------------
options_path = 'Settings/Help/Clippy Comments'
options = {
	rankLimit = {
		name = "Rank Limit",
		type = 'bool',
		value = false,
		desc = 'Units make comments only to newbies.',
	},
	warnExpensiveUnits = {
		name = "Warning for Expensive Units",
		type = 'bool',
		value = true,
		desc = 'Units complain about expensive units made early game.',
	},
}

VFS.Include("LuaUI/Configs/clippy.lua",nil)

local activeTips = {}	-- [unitID] = {stuff for tip being displayed}

local units = {}
local haveFactoryDefIDs = {}
local lastFactoryTime = -100000 -- gameframe
local totalValue = 0
local defenseValue = 0

local airSpotted = false
local nukeSpotted = false
local fontSize = 12

local updateFrequency = 0.2

local myTeam = spGetMyTeamID()
local activeCommand
local currentBuilder

local gameframe = Spring.GetGameFrame()
-----------------------
-- minimum complexity of tips to display
-- 1 = new to RTS
-- 2 = a bit of experience with ZK
-- 3 = up to intermediate
local helpLevel = rank and math.min(rank, 3) or 1

-- Chili classes
local Chili
local Window
local TextBox
local Image
local Font

-- Chili instances
local screen0

local font = "LuaUI/Fonts/komtxt__.ttf"

------------------------
------------------------
if VFS.FileExists("mission.lua") then
	return
end

local function DisposeTip(unitID)
	if not unitID then return end
	
	if activeTips[unitID] and activeTips[unitID].img then
		activeTips[unitID].img:Dispose()
	end
	activeTips[unitID] = nil
end

local function GetTipDimensions(unitID, str, height, invert)
	local textHeight, _, numLines = gl.GetTextHeight(str)
	textHeight = textHeight*fontSize*numLines
	local textWidth = gl.GetTextWidth(str)*fontSize

	local ux, uy, uz = Spring.GetUnitBasePosition(unitID)
	uy = uy + height
	local x,y,z = Spring.WorldToScreenCoords(ux, uy, uz)
	if not invert then
		y = screen0.height - y
	end
	
	return textWidth, textHeight, x, y, height
end

local function MakeTip(unitID, tip)
	if (options.rankLimit.value and (rank > RANK_LIMIT)) then
		return
	end
	DisposeTip(unitID)

	local strings = tips[tip].str
	local str = strings[math.random(#strings)]
	
	local height = Spring.GetUnitHeight(unitID)
	
	local textWidth, textHeight, x, y = GetTipDimensions(unitID, str, height)

	local img = Image:New {
		width = textWidth + 4,
		height = textHeight + 4 + fontSize,
		x = x - (textWidth+8)/2;
		y = y - textHeight - 4 - fontSize;
		keepAspect = false,
		file = "LuaUI/Images/speechbubble.png";
		parent = screen0;
	}
	local textBox = TextBox:New{
		parent  = img;
		text    = str,
		height	= textHeight,
		width   = textWidth,
		x = 4,
		y = 4,
		valign  = "center";
		align   = "left";
		font    = {
			font   = font;
			size   = fontSize;
			color  = {0,0,0,1}
		},
	}
	
	activeTips[unitID] = {str = str, expire = gameframe + tips[tip].life*30, height = height, img = img, textBox = textBox}
	tips[tip].lastUsed = gameframe
end

local function ProcessCommand(unitID, command)
	if not (unitID and Spring.ValidUnitID(unitID)) then return end
	if -command == NANO_DEF_ID then
		if tips.nano_excess.lastUsed > gameframe - tips.nano_excess.cooldown*30 then
			return
		end
		local metalIncome = select(4, spGetTeamResources(myTeam, "metal"))
		local numNanos = #(Spring.GetTeamUnitsByDefs(myTeam, NANO_DEF_ID) or {})
		if numNanos > 0 and (metalIncome/numNanos < METAL_PER_NANO) then
			MakeTip(unitID, "nano_excess")
		end
	elseif factories[-command] then
		if haveFactoryDefIDs[-command] then
			MakeTip(unitID, "factory_duplicate")
			return
		elseif gameframe < lastFactoryTime + DELAY_BETWEEN_FACS then
			MakeTip(unitID, "factory_multiple")
			return
		end
	elseif superweapons[-command] and TIMER_SUPERWEAPON > gameframe/30 then
		if tips.superweapon.lastUsed > gameframe - tips.superweapon.cooldown*30 then
			return
		end
		MakeTip(unitID, "superweapon")
		return
	elseif expensive_units[-command] and options.warnExpensiveUnits.value and TIMER_EXPENSIVE_UNITS > gameframe/30 then
		if tips.expensive_unit.lastUsed > gameframe - tips.expensive_unit.cooldown*30 then
			return
		end
		local metalIncome = select(4, spGetTeamResources(myTeam, "metal"))
		if metalIncome < INCOME_TO_SPLURGE then
			MakeTip(currentBuilder, "expensive_unit")
			return
		end
	end
	if defenses[-command] then
		if tips.defense_excess.lastUsed > gameframe - tips.defense_excess.cooldown*30 then
			return
		end
		if totalValue == 0 then return end
		if defenseValue/totalValue > DEFENSE_QUOTA then
			MakeTip(unitID, "defense_excess")
			return
		end
	elseif energy[-command] then
		if tips.energy_excess.lastUsed > gameframe - tips.energy_excess.cooldown*30 then
			return
		end
		local metalIncome = select(4, spGetTeamResources(myTeam, "metal"))
		local energyCurrent,_,_,energyIncome = spGetTeamResources(myTeam, "energy")
		if energyIncome/metalIncome > ENERGY_TO_METAL_RATIO then
			MakeTip(unitID, "energy_excess")
			return
		end
	end
	if (tips.energy_deficit.lastUsed > gameframe - tips.energy_deficit.cooldown*30) or (tips.metal_excess.lastUsed > gameframe - tips.metal_excess.cooldown*30) then
		return
	end
	local metalCurrent,metalStorage,_,metalIncome,metalExpense = spGetTeamResources(myTeam, "metal")
	local energyCurrent,_,_,energyIncome = spGetTeamResources(myTeam, "energy")
	if (energyIncome/metalIncome < 1) and (energyCurrent < ENERGY_LOW_THRESHOLD) and not energy[-command] then
		MakeTip(unitID, "energy_deficit")
	elseif metalCurrent/metalStorage > 0.95 and metalIncome - metalExpense > 0 then
		MakeTip(unitID, "metal_excess")
	--elseif metalCurrent/metalStorage > 0.05 and metalIncome - metalExpense < 0 then
	--	MakeTip(unitID, "metal_deficit")		
	end
end

------------------------
------------------------

local timer = 0

function widget:Update(dt)
	timer = timer + dt
	if timer > updateFrequency then
		if (Spring.GetSpectatingState() or Spring.IsReplay()) then
			Spring.Echo("<Clippy Comments> Spectator mode or replay. Widget removed.")
			widgetHandler:RemoveWidget()
		end
		
		myTeam = spGetMyTeamID()	-- just refresh for fun
		timer = 0
		local command = select(2, Spring.GetActiveCommand())
		if command and command < 0 and (activeCommand ~= command) then
			ProcessCommand(currentBuilder, command)
			activeCommand = command
		end
	end
	
	-- chili code
	for unitID, tipData in pairs(activeTips) do
		if Spring.IsUnitInView(unitID) then
			local textWidth, textHeight, x, y = GetTipDimensions(unitID, tipData.str, tipData.height)
			
			local img = tipData.img
			if img.hidden then
				screen0:AddChild(img)
				img.hidden = false
			end
			
			img.x = x - (textWidth+8)/2
			img.y = y - textHeight - 4 - fontSize
			img:Invalidate()
		elseif not tipData.img.hidden then
			screen0:RemoveChild(tipData.img)
			tipData.img.hidden = true
		end
		if tipData.expire < gameframe then
			DisposeTip(unitID)
		end
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if units[unitID] then
		local cost = UnitDefs[unitDefID].metalCost or 0
		totalValue = totalValue - cost
		if defenses[unitDefID] then
			defenseValue = defenseValue - cost
		elseif factories[unitDefID] then
			haveFactoryDefIDs[unitDefID] = nil
			lastFactoryTime = -100000
		end
	end
	DisposeTip(unitID)
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if unitTeam == myTeam then
		units[unitID] = true
		local cost = UnitDefs[unitDefID].metalCost or 0
		totalValue = totalValue + cost
		if defenses[unitDefID] then
			defenseValue = defenseValue + cost
		elseif factories[unitDefID] then
			haveFactoryDefIDs[unitDefID] = true
			lastFactoryTime = gameframe
		end
	end
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	if newTeamID == myTeam then
		widget:UnitFinished(unitID, unitDefID, teamID)
	elseif teamID == myTeam then
		widget:UnitDestroyed(unitID, unitDefID, teamID)
	end
end

function widget:GameFrame(n)
	gameframe = n
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdOpts, cmdParams)
	if unitTeam == myTeam and cmdID < 0 then
		ProcessCommand(unitID, cmdID)
	end
end
-- obscures healthbars
--[[
function widget:UnitDamaged(unitID, unitDefID, unitTeam)
	if unitTeam == myTeam and canRetreat[unitDefID] then
		if tips.retreat_repair.lastUsed > gameframe - tips.retreat_repair.cooldown*30 then
			return
		end
		local health, maxHealth = spGetUnitHealth(unitID)
		if health/maxHealth < 0.5 then
			MakeTip(unitID, "retreat_repair")
		end
	end
end
]]--

function widget:SelectionChanged(newSelection)
	--get new selected con, if any
	for i=1,#newSelection do
		local id = newSelection[i]
		if UnitDefs[spGetUnitDefID(id)].builder then
			currentBuilder = id
			return
		end
	end
	currentBuilder = nil
end

function widget:Initialize()
	if VFS.FileExists("LuaRules/Gadgets/mission.lua") then
		widgetHandler:RemoveWidget()	-- no need for tips in mission
	end
	local selection = Spring.GetSelectedUnits()
	widget:SelectionChanged(selection)
	
	Chili = WG.Chili
	TextBox = Chili.TextBox
	Image = Chili.Image
	Font = Chili.Font
	screen0 = Chili.Screen0
	
	-- reload compatibility
	local units = Spring.GetTeamUnits(myTeam)
	for i=1,#units do
		widget:UnitFinished(units[i], Spring.GetUnitDefID(units[i]), myTeam)
	end
end

-- non-chili code
--[[
local function DrawUnitFunc(xshift, yshift, text)
	gl.Translate(xshift,yshift,0)
	gl.Billboard()
	gl.Text(text, 0,0, 14, "cs")
end

function widget:DrawScreen()
	if Spring.IsGUIHidden() then return end

	gl.DepthMask(true)
	gl.DepthTest(true)
	gl.AlphaTest(GL.GREATER, 0.001)
	gl.Texture("LuaUI/Images/speechbubble.png")
	
	for unitID, tipData in pairs(activeTips) do
		if Spring.IsUnitInView(unitID) then
			gl.PushMatrix()
			local textWidth, textHeight, x, y = GetTipDimensions(unitID, tipData.str, tipData.height, true)
			gl.Translate(x, y + textHeight + 8, 0)
			gl.Color(1,1,1,1)
			local bubbleHeight = (textHeight+4)
			local bubbleWidth = textWidth+4
			gl.TexRect(-bubbleWidth/2, -bubbleHeight, bubbleWidth/2, bubbleHeight)
			gl.Color(0,0,0,1)
			gl.Translate(0, textHeight/2, 0)
			fontHandler.UseFont("LuaUI/Fonts/KOMTXT___16")
			--fontHandler.DrawCentered(tipData.str, 0, 0)
			gl.Text(tipData.str, 0,0, fontSize, "co")

			--gl.DrawFuncAtUnit(unitID, false, DrawUnitFunc,
			--		0, tipData.height, tipData.str)
			gl.PopMatrix()
		end
		if tipData.expire < gameframe then
			activeTips[unitID] = nil
		end
	end
end
]]--
