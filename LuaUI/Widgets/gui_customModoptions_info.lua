--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Custom Modoptions Info",
    desc      = "v0.001 Display list of customized modoptions if available",
    author    = "xponen",
    date      = "15 March 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
    enabled   = true  --  loaded by default?
  }
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local options = VFS.Include("ModOptions.lua")

-- gui elements
local window2
	
function widget:Initialize()
	if Spring.GetGameFrame() > 1800 then
		widgetHandler:RemoveWidget() --auto-close in case user do /luaui reload
	end

	local customizedModOptions = {}
	for i=1, #options do
		local optType = options[i].type
		if optType == 'bool' or optType == 'number' or optType == 'string' or optType == 'list' then
			local keyName = options[i].key
			local defValue = options[i].def
			local value = Spring.GetModOptions()[keyName]
			if optType == 'bool' then
				defValue = (defValue and 1) or 0
				value = tonumber(value) or defValue
			elseif optType == 'number' then
				value = tonumber(value) or defValue
			elseif optType == 'string' or optType == 'list' then
				defValue = defValue or ''
				value = value or defValue
			end
			if value and value ~= defValue then
				local index = #customizedModOptions
				customizedModOptions[index+1] = options[i].name
				customizedModOptions[index+2] = {"value: "..value,{options[i].desc}}
			end
		end
	end

	if #customizedModOptions == 0 then
		widgetHandler:RemoveWidget()
		return
	end
	local vsx, vsy = widgetHandler:GetViewSizes()

	local Chili = WG.Chili
	window2 = Chili.Window:New{
		x = vsx/2-100,
		y = 3*vsy/4-20,
		width  = 200,
		padding = {5, 0, 5,5},
		textColor = {1,1,1,0.55}, 
		height = math.min(112,vsy/2),
		parent = Chili.Screen0,
		caption = "Active modoptions:",

		children = {
			Chili.Button:New { --from gui_chili_vote.lua by KingRaptor
				width = 7,
				height = 7,
				y = 0,
				right = 0,
				textColor = {1,1,1,0.55}, 
				caption="x";
				tooltip = "Close window";
				OnClick = {function()
							window2:Dispose()
							widgetHandler:RemoveWidget()
						end}
			},
			Chili.ScrollPanel:New{
				x=0, right=0,
				y=20, bottom=0,
				children = {
					Chili.TreeView:New{ --from gui_chilidemo.lua by quantum
						x=0, right=0,
						y=0, bottom=0,
						defaultExpanded = false,
						nodes = { unpack(customizedModOptions) },
					},
				},
			},
		},
	}
end

function widget:GameStart()
	window2:Dispose()
	widgetHandler:RemoveWidget()
end