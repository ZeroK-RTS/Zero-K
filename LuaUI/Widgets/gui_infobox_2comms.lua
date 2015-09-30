function widget:GetInfo() return {
	name    = "Double Comm Infobox",
	desc    = "Pops up when someone has double comm",
	author  = "git blame",
	date    = "git log",
	license = "PD",
	layer   = 1,
	enabled = true, -- i don't always see a comment here, but when i do, it's "-- enabled by default?"
} end

local window2

function widget:Initialize()

	if Spring.GetGameFrame() > 1 then
		widgetHandler:RemoveWidget()
		return
	end

	local name, r, g, b
	local people = Spring.GetPlayerList()
	for i = 1, #people do
		local peopleperson = people[i]
		local customKeys = select(10, Spring.GetPlayerInfo(peopleperson))
		if customKeys and customKeys.extracomm then
			name = select(1, Spring.GetPlayerInfo(peopleperson))
			r, g, b = Spring.GetTeamColor(select(4, Spring.GetPlayerInfo(peopleperson)))
		end
	end

	if not name then
		widgetHandler:RemoveWidget()
		return
	end

	local vsx, vsy = widgetHandler:GetViewSizes()

	local Chili = WG.Chili
	window2 = Chili.Window:New{
		x = vsx/2-100,
		y = vsy/2-20,
		width = 200,
		padding = {5, 0, 5,5},
		textColor = {1,1,1,1}, 
		height = 50,
		parent = Chili.Screen0,
		caption = "Double Commander:",
		resizable = false,
		tweakResizable = false,

		children = {
			Chili.Button:New {
				width = 7,
				height = 7,
				y = 0,
				right = 0,
				textColor = {1,1,1,0.55}, 
				caption = "x";
				tooltip = "Close window";
				OnClick = { function()
					window2:Dispose()
					widgetHandler:RemoveWidget()
				end}
			},
			Chili.Label:New{
				x=5, right=0,
				y=23, bottom=0,
				caption = name,
				textColor = {r,g,b,1},
			},
		},
	}
end

function widget:GameStart()
	window2:Dispose()
	widgetHandler:RemoveWidget()
end