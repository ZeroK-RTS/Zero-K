function widget:GetInfo() return {
	name      = "RoI Tracker",
	desc      = "Shows ally RoI",
	author    = "Anarchid",
	date      = "Dec 2012",
	license   = "GPL",
	layer     = -10,
	enabled   = false,
} end

local Chili

local spectating = Spring.GetSpectatingState()
local allied_teams

local is_RoI = (Spring.GetModOptions().overdrivesharingscheme ~= "0")

local window, fake_window
local name_labels = {}
local roi_labels = {}
local base_labels = {}
local base_income_labels = {}
local od_income_labels = {}

function widget:Initialize()
	if not is_RoI then
		Spring.Echo ("RoI Counter: No need to track capital under Communism, comrade!")
		widgetHandler:RemoveWidget()
		return
	end

	Chili = WG.Chili

	if not Chili then
		widgetHandler:RemoveWidget()
		return
	end

	if spectating then
		allied_teams = Spring.GetTeamList ()
		allied_teams[#allied_teams] = nil -- Gaia
	else
		allied_teams = Spring.GetTeamList (Spring.GetMyAllyTeamID())
		for i = 1, #allied_teams do -- put self first on the list
			if (allied_teams[i] == Spring.GetMyTeamID()) then
				allied_teams[i] = allied_teams[1]
				allied_teams[1] = Spring.GetMyTeamID()
				break
			end
		end
	end

	if ((#allied_teams < 2) or ((#allied_teams == 2) and spectating)) then
		Spring.Echo ('RoI Counter: Silly duelizt, RoI is for team games!')
		widgetHandler:RemoveWidget()
		return
	end

	CreateWindow()
end

function widget:Shutdown()
	if window then window:Dispose() end
end

local timer = 0
function widget:Update(s)
	timer = timer + s
	if timer > 0.5 then
		timer = 0
		window.height = fake_window.height - 45
		window.width = fake_window.width - 15
		for i = 1, #allied_teams do
			roi_labels[i]:SetCaption (string.format("%d m", Spring.GetTeamRulesParam(allied_teams[i], "OD_RoI_metalDue") or 0))
			base_labels[i]:SetCaption (string.format("%d m", Spring.GetTeamRulesParam(allied_teams[i], "OD_base_metalDue") or 0))
			base_income_labels[i]:SetCaption (string.format("+%d m", Spring.GetTeamRulesParam(allied_teams[i], "OD_metalBase") or 0))
			od_income_labels[i]:SetCaption (string.format("+%d m", Spring.GetTeamRulesParam(allied_teams[i], "OD_metalOverdrive") or 0))
		end
	end
end

function CreateWindow()	
	local screenWidth, screenHeight = Spring.GetWindowGeometry()

	fake_window = Chili.Window:New {
		color = {1,1,1,0.7},
		parent = Chili.Screen0,
		dockable = true,
		name = "RoI Tracker",
		padding = {5,5,5,5},
		right = 0,
		y = 150,
		clientWidth  = 320,
		minWidth = 320,
		clientHeight = 100,
		minHeight = 50,
		classname = "main_window_small",
		draggable = true,
		resizable = true,
		tweakDraggable = true,
		tweakResizable = true,
        minimizable = false,
		parentWidgetName = widget:GetInfo().name, -- docking
	}

	window = Chili.ScrollPanel:New {
		parent = fake_window,
		backgroundColor = {0,0,0,0},
		borderColor = {0,0,0,0},
		height = 220,
		x = 0,
		y = 20,
		width = 350,
		padding = {0, 0, 0, 0},
		scrollbarSize = 10,
		scrollPosY    = 0,
		verticalScrollbar   = true,
		horizontalScrollbar = false,
		smoothScroll     = false,
		ignoreMouseWheel = true,
	}

	title_caption = Chili.Label:New {
 		x = 5,
 		y = 5,
 		width = 10,
 		parent = window,
 		caption = "Player     Due:  OD       Base     Income:  OD      Base",
 		fontsize = 13,
 		textColor = {1,1,1,1},
	}
	fake_window:AddChild (title_caption)

	for i = 1, #allied_teams do
		local tID = allied_teams[i]
		local r, g, b = Spring.GetTeamColor(tID)
		local name = Spring.GetPlayerInfo (select (2, Spring.GetTeamInfo(tID, false)), false)
		name_labels[i] = Chili.Label:New{
			x = 5,
			y = 16*i - 10,
			width = 10,
			parent = window,
			caption = name,
			fontsize = 13,
			textColor = {r, g, b, 1},
		}
		roi_labels[i] = Chili.Label:New{
			x = 100,
			y = 16*i - 10,
			width = 50,
			parent = window,
			caption = "0 m",
			fontsize = 13,
			textColor = {1, 0.8, 0, 1},
		}
		base_labels[i] = Chili.Label:New{
			x = 170,
			y = 16*i - 10,
			width = 50,
			parent = window,
			caption = "0 m",
			fontsize = 13,
			textColor = {0.65, 0.65, 0.65, 1},
		}
		od_income_labels[i] = Chili.Label:New{
			x = 250,
			y = 16*i - 10,
			width = 50,
			parent = window,
			caption = "0 m",
			fontsize = 13,
			textColor = {0.1, 0.8, 0.1, 1},
		}
		base_income_labels[i] = Chili.Label:New{
			x = 300,
			y = 16*i - 10,
			width = 50,
			parent = window,
			caption = "0 m",
			fontsize = 13,
			textColor = {0.1, 0.8, 0.1, 1},
		}
	end
end

function DestroyWindow()
	window:Dispose()
	window = nil
end
