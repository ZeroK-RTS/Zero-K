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

local displayExceptions = {
	mutespec = true,
	mutelobby = true,
	minspeed = true,
	maxspeed = true,
}

local forceHideModoptions = {
	hidemodoptionswindow = true
}

-- gui elements
local window2, window3

function widget:Initialize()
	-- ZK Mission Editor mission
	if VFS.FileExists("mission.lua") then
		widgetHandler:RemoveWidget()
		return
	end
	
	-- Chobby campaign mission
	if Spring.GetModOptions().singleplayercampaignbattleid then
		widgetHandler:RemoveWidget()
		return
	end

	if Spring.GetGameFrame() > 1800 then
		widgetHandler:RemoveWidget() --auto-close in case user do /luaui reload
		return
	end
	
	displayWindow = false
	forceHideWindow = false

	local optionsNotes = false
	local customizedModOptions = {}
	for i = 1, #options do
		local optType = options[i].type
		if optType == 'bool' or optType == 'number' or optType == 'string' or optType == 'list' then
			local keyName = options[i].key
			local defValue = options[i].def
			local value = Spring.GetModOptions()[keyName]
			if keyName == "option_notes" then
				optionsNotes = value
			end
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
				if not displayExceptions[keyName] then
					displayWindow = true
				end
				if forceHideModoptions[keyName] then
					forceHideWindow = true
				end
				local index = #customizedModOptions
				customizedModOptions[index+1] = options[i].name
				customizedModOptions[index+2] = {"value: "..value,{options[i].desc}}
			end
		end
	end

	local autoHandicapValue = Spring.GetGameRulesParam("econ_mult_auto_value")
	--Spring.Echo("Widget_autoHandicapValue", autoHandicapValue)
	if autoHandicapValue then
		local index = #customizedModOptions
		customizedModOptions[index+1] = "Handicap Value: " .. math.round(autoHandicapValue * 100) .. "%"
		customizedModOptions[index+2] = {"value: " .. math.round(autoHandicapValue, 3), {"The income multipler for the lower rated player."}}
	end

	if forceHideWindow or (not displayWindow) then
		widgetHandler:RemoveWidget()
		return
	end
	local vsx, vsy = widgetHandler:GetViewSizes()

	local Chili = WG.Chili
	window2 = Chili.Window:New{
		name = "active_modoptions_window",
		x = 50,
		y = vsy - 480,
		width  = 220,
		classname = "main_window_small_tall",
		textColor = {1,1,1,0.55},
		height = math.min(180,vsy/2),
		parent = Chili.Screen0,
		dockable  = true,
		dockableSavePositionOnly = true,
		caption = "Active modoptions:",

		children = {
			Chili.Button:New { --from gui_chili_vote.lua by KingRaptor
				width = 7,
				height = 7,
				y = 4,
				right = 4,
				textColor = {1,1,1,0.55},
				caption="x";
				tooltip = "Close window";
				OnClick = {function()
							window2:Dispose()
							window2 = false
						end}
			},
			Chili.ScrollPanel:New{
				x=4, right=4,
				y=20, bottom=4,
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
	
	if optionsNotes then
		optionsNotes = optionsNotes:gsub("\\n", "\n")
		window3 = Chili.Window:New{
			name = "modoptions_notes_window",
			x = 50,
			y = vsy - 480 - math.min(180,vsy/2)*1.1,
			width  = 220,
			classname = "main_window_small_tall",
			textColor = {1,1,1,0.55},
			height = math.min(180,vsy/2),
			parent = Chili.Screen0,
			dockable  = true,
			dockableSavePositionOnly = true,
			caption = "Modoption notes:",
			children = {
				Chili.Button:New { --from gui_chili_vote.lua by KingRaptor
					width = 7,
					height = 7,
					y = 4,
					right = 4,
					textColor = {1,1,1,0.55},
					caption="x";
					tooltip = "Close window";
					OnClick = {function()
						window3:Dispose()
						window3 = false
					end}
				},
				Chili.TextBox:New{
					x=4, right=4,
					y=18, height = 20,
					align = "left",
					lineSpacing = 0,
					padding = { 4, 4, 4, 4 },
					text = optionsNotes,
				}
			}
		}
	end
end

function widget:GameStart()
	if window2 then
		window2:Dispose()
	end
	if window3 then
		window3:Dispose()
	end
	widgetHandler:RemoveWidget()
end
