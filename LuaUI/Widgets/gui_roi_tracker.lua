function widget:GetInfo() return {
	name      = "RoI Tracker",
	desc      = "Shows ally RoI",
	author    = "Anarchid",
	date      = "Dec 2012",
	license   = "GPL",
	layer     = -10,
	enabled   = true,
} end

local Chili

local spectating = Spring.GetSpectatingState()
local allied_teams

local window, fake_window
local name_labels = {}
local roi_labels = {}

function widget:Initialize()
	if (Spring.GetModOptions().overdrivesharingscheme ~= "investmentreturn") then
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
			roi_labels[i]:SetCaption (string.format("%d m", Spring.GetTeamRulesParam(allied_teams[i], "OD_RoI_metalDue")))
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
		y = 50,
		clientWidth  = 220,
		minWidth = 220,
		clientHeight = 100,
		minHeight = 50,
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
		width = 220,
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
 		caption = "Payback due:",
 		fontsize = 13,
 		textColor = {1,1,1,1},
	}
	fake_window:AddChild (title_caption)

	for i = 1, #allied_teams do
		local tID = allied_teams[i]
		local r, g, b = Spring.GetTeamColor(tID)
		local name = Spring.GetPlayerInfo (select (2, Spring.GetTeamInfo(tID)))
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
			x = 150,
			y = 16*i - 10,
			width = 50,
			parent = window,
			caption = "0 m",
			fontsize = 13,
			textColor = {1, 1, 1, 1},
		}
	end
end

function DestroyWindow()
	window:Dispose()
	window = nil
end
