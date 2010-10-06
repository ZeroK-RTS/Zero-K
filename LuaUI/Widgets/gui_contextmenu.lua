function widget:GetInfo()
  return {
    name      = "Context Menu",
    desc      = "v0.08 Chili Context Menu\nPress [Space] while clicking for a context menu.",
    author    = "CarRepairer",
    date      = "2009-06-02",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    experimental = false,
    enabled   = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("keysym.h.lua")

local spSendLuaRulesMsg			= Spring.SendLuaRulesMsg
local spGetCurrentTooltip		= Spring.GetCurrentTooltip
local spGetUnitDefID			= Spring.GetUnitDefID
local spGetUnitAllyTeam			= Spring.GetUnitAllyTeam
local spGetUnitTeam				= Spring.GetUnitTeam
local spTraceScreenRay			= Spring.TraceScreenRay
local spGetTeamInfo				= Spring.GetTeamInfo
local spGetPlayerInfo			= Spring.GetPlayerInfo
local spGetTeamColor			= Spring.GetTeamColor
local spGetModKeyState			= Spring.GetModKeyState

local abs						= math.abs
local strFormat 				= string.format

local echo = Spring.Echo

local VFSMODE      = VFS.RAW_FIRST
local ignoreweapon, iconFormat = VFS.Include(LUAUI_DIRNAME .. "Configs/chilitip_conf.lua" , nil, VFSMODE)
local confdata = VFS.Include(LUAUI_DIRNAME .. "Configs/crudemenu_conf.lua", nil, VFSMODE)
local color = confdata.color

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local Button
local Label
local Window
local ScrollPanel
local StackPanel
local Grid
local TextBox
local Image
local screen0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local B_HEIGHT 		= 30
local icon_size 	= 18

local scrH, scrW 		= 0,0
local myAlliance 		= Spring.GetLocalAllyTeamID()
local myTeamID 			= Spring.GetLocalTeamID()

local ceasefires 		= true
local marketandbounty 	= false

local window_unitcontext, window_unitstats
local statswindows = {}



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options = {

	noContextClick = {
		name = 'Disable Context Menu',
		type = 'bool',
		value = false,		
		advanced = true,
	},
	
}
options_path = 'Settings/Interface'
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function tobool(val)
  local t = type(val)
  if (t == 'nil') then return false
  elseif (t == 'boolean') then	return val
  elseif (t == 'number') then	return (val ~= 0)
  elseif (t == 'string') then	return ((val ~= '0') and (val ~= 'false'))
  end
  return false
end

if tobool(Spring.GetModOptions().noceasefire) or Spring.FixedAllies() then
  ceasefires = false
end 

if tobool(Spring.GetModOptions().marketandbounty) then
	marketandbounty = true
end 


function comma_value(amount)
	local formatted = amount .. ''
	local k
	while true do  
		formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end
  	return formatted
end

--from rooms widget by quantum
local function ToSI(num)
  if type(num) ~= 'number' then
	return 'Tooltip wacky error #55'
  end
  if (num == 0) then
    return "0"
  else
    local absNum = abs(num)
    if (absNum < 0.001) then
      return strFormat("%.1fu", 1000000 * num)
    elseif (absNum < 1) then
      return strFormat("%.1f", num)
    elseif (absNum < 1000) then
      return strFormat("%.0f", num)
    elseif (absNum < 1000000) then
      return strFormat("%.1fk", 0.001 * num)
    else
      return strFormat("%.1fM", 0.000001 * num)
    end
  end
end

local function numformat(num)
	return comma_value(ToSI(num))
end

local function AdjustWindow(x,y, width, height)
	if x + width > scrW * (.75) then
		x = x - width - 20
	else
		x = x + 20
	end
	if y + height > scrH * (.75) then
		y = y - height - 20
	else
		y = y + 20
	end
	return x,y
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CloseButtonFunc(self)
	self.parent.parent:Dispose()
end
local function CloseButtonFunc2(self)
	self.parent.parent.parent:Dispose()
end

local function CloseButton(width)
	return Button:New{ 
		caption = 'Close', 
		OnMouseUp = { CloseButtonFunc }, 
		width=width, 
		height = B_HEIGHT,
		backgroundColor=color.sub_back_bg, 
		textColor=color.sub_back_fg,
	}
end

local UnitDefByHumanName_cache = {}
local function GetUnitDefByHumanName(humanName)
	local cached_udef = UnitDefByHumanName_cache[humanName]
	if (cached_udef ~= nil) then
		return cached_udef
	end

	for _,ud in pairs(UnitDefs) do
		if (ud.humanName:find(humanName)) then
			UnitDefByHumanName_cache[humanName] = ud
			return ud
		end
	end
	UnitDefByHumanName_cache[humanName] = false
	return false
end


local function getHelpText(unitDef, lang)
	local suffix = (lang == 'en') and '' or ('_' .. lang)	
	return unitDef.customParams and unitDef.customParams['helptext' .. suffix] 
		or unitDef.customParams.helptext
		or "No help text available for this unit."
end	


local function getDescription(unitDef, lang)
	if not lang or lang == 'en' then 
		return unitDef.tooltip
	end
	local suffix  = ('_' .. lang)
	return unitDef.customParams and unitDef.customParams['description' .. suffix] or unitDef.tooltip or 'Description error'
end	


local function weapons2Table(cells, weaponStats, ws, merw, index)
	local cells = cells
	local mainweapon = merw and merw[index]
	if not ws.slaveTo then
		if mainweapon then
			for _,index2 in ipairs(mainweapon) do
				wsm = weaponStats[index2]
				ws.damw = ws.damw + wsm.bestTypeDamagew
				ws.dpsw = ws.dpsw + wsm.dpsw
				ws.dam = ws.dam + wsm.bestTypeDamage
				ws.dps = ws.dps + wsm.dps
			end
		end
		
		local dps_str, dam_str = '', ''
		if ws.dps > 0 then
			dam_str = dam_str .. numformat(ws.dam,2)
			dps_str = dps_str .. numformat(ws.dps,2)
		end
		if ws.dpsw > 0 then
			if dps_str ~= '' then
				dps_str = dps_str .. ' || '
				dam_str = dam_str .. ' || '
			end
			dam_str = dam_str .. numformat(ws.damw,2) .. ' (P)'
			dps_str = dps_str .. numformat(ws.dpsw,2) .. ' (P)'
		end

		cells[#cells+1] = ws.wname
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Damage:'
		cells[#cells+1] = dam_str
		cells[#cells+1] = ' - Reloadtime:'
		cells[#cells+1] = numformat(ws.reloadtime,2) ..'s'
		cells[#cells+1] = ' - Damage/second:'
		cells[#cells+1] = dps_str
		cells[#cells+1] = ' - Range:'
		cells[#cells+1] = numformat(ws.range,2)
		
		cells[#cells+1] = ''
		cells[#cells+1] = ''
		
	end
	return cells
end

local function printWeapons(unitDef)
	local weaponStats = {}
	local bestDamage, bestDamageIndex, bestTypeDamage = 0,0,0

	local merw = {}

	local wd = WeaponDefs
	if not wd then return false end	
	
	for i, weapon in ipairs(unitDef.weapons) do
		local weaponID = weapon.weaponDef
		local weaponDef = WeaponDefs[weaponID]
	
		local weaponName = weaponDef.description
		
		if (weaponName) then
			
			local wsTemp = {}
			wsTemp.slaveTo = (weapon.slavedTo ~= 0) and weapon.slavedTo or nil

			if wsTemp.slaveTo then
				merw[wsTemp.slaveTo] = merw[wsTemp.slaveTo] or {}
				merw[wsTemp.slaveTo][#(merw[wsTemp.slaveTo])+1] = i
			end
			wsTemp.bestTypeDamage = 0
			wsTemp.bestTypeDamagew = 0
			wsTemp.paralyzer = weaponDef.paralyzer	
			for key, val in pairs(weaponDef.damages) do
				--[[
				if (wsTemp.bestTypeDamage <= (damage+0) and not wsTemp.paralyzer)
					or (wsTemp.bestTypeDamagew <= (damage+0) and wsTemp.paralyzer)
					then

					if wsTemp.paralyzer then
						wsTemp.bestTypeDamagew = (damage+0)
					else
						wsTemp.bestTypeDamage = (damage+0)
					end
				--]]
				if key == 0 then
					if wsTemp.paralyzer then
						wsTemp.bestTypeDamagew = val 
					else
						wsTemp.bestTypeDamage = val
					end
					
					wsTemp.burst = weaponDef.burst or 1
					wsTemp.projectiles = weaponDef.projectiles or 1
					wsTemp.dam = 0
					wsTemp.damw = 0
					if wsTemp.paralyzer then
						wsTemp.damw = wsTemp.bestTypeDamagew * wsTemp.burst * wsTemp.projectiles
					else
						wsTemp.dam = wsTemp.bestTypeDamage * wsTemp.burst * wsTemp.projectiles
					end
					wsTemp.reloadtime = weaponDef.reload or ''
					wsTemp.airWeapon = weaponDef.toAirWeapon or false
					wsTemp.range = weaponDef.range or ''
					wsTemp.wname = weaponDef.description or 'NoName Weapon'
					wsTemp.dps = 0
					wsTemp.dpsw = 0
					if  wsTemp.reloadtime ~= '' and wsTemp.reloadtime > 0 then
						if wsTemp.paralyzer then
							wsTemp.dpsw = math.floor(wsTemp.damw/wsTemp.reloadtime + 0.5)
						else
							wsTemp.dps = math.floor(wsTemp.dam/wsTemp.reloadtime + 0.5)
						end
					end
					--echo('test', unitDef.unitname, wsTemp.wname, wsTemp.bestTypeDamage, i)
					if wsTemp.dam > bestDamage then
						bestDamage = wsTemp.dam	
						bestDamageIndex = i
					end
					if wsTemp.damw > bestDamage then
						bestDamage = wsTemp.damw
						bestDamageIndex = i
					end
					
				end
			end
			if not wsTemp.wname then print("BAD", unitDef.unitname) return false end -- stupid negative in corhurc is breaking me.
			weaponStats[i] = wsTemp
		end
	end
	
	local cells = {}
		
	for index,ws in pairs(weaponStats) do
		if not ignoreweapon[unitDef.name] or not ignoreweapon[unitDef.name][index] then
			cells = weapons2Table(cells, weaponStats, ws, merw, index)
		end
	end
		
	
	return cells
end

local function printunitinfo(ud, lang, buttonWidth)	
	local icons = {
		Image:New{
			file2 = (WG.GetBuildIconFrame)and(WG.GetBuildIconFrame(ud)),
			file = "#" .. ud.id,
			keepAspect = false;
			height  = 40*(4/5);
			width   = 40;
		},
	}
	if ud.iconType ~= 'default' then
		icons[#icons + 1] = 
			Image:New{
				file='icons/'.. ud.iconType ..iconFormat,
				height=40,
				width=40,
			}
	end
	
	local helptextbox = TextBox:New{ 
		text = getHelpText(ud, lang), 
		textColor = color.stats_fg, 
		width = '100%',
		height = '100%',
		padding = { 1, 1, 1, 1 }, 
		} 
	
	local statschildren = {}
	
	statschildren[#statschildren+1] = Label:New{ caption = 'STATS', textColor = color.stats_header, }
	statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header, }

	statschildren[#statschildren+1] = Label:New{ caption = 'Cost: ', textColor = color.stats_fg, }
	statschildren[#statschildren+1] = Label:New{ caption = numformat(ud.metalCost), textColor = color.stats_fg, }
	
	statschildren[#statschildren+1] = Label:New{ caption = 'Max HP: ', textColor = color.stats_fg, }
	statschildren[#statschildren+1] = Label:New{ caption = numformat(ud.health), textColor = color.stats_fg, }
		
	if ud.speed > 0 then
		statschildren[#statschildren+1] = Label:New{ caption = 'Speed: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = numformat(ud.speed,2), textColor = color.stats_fg, }
	end
	
	if ud.energyMake > 0 then
		statschildren[#statschildren+1] = Label:New{ caption = 'Energy: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = '+' .. numformat(ud.energyMake,2), textColor = color.stats_fg, }
	end
	if ud.energyUpkeep < 0 then
		statschildren[#statschildren+1] = Label:New{ caption = 'Energy: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = '+' .. numformat(ud.energyUpkeep,2):sub(2), textColor = color.stats_fg, }
	end
	
	if ud.buildSpeed > 0 then
		statschildren[#statschildren+1] = Label:New{ caption = 'Buildpower: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = numformat(ud.buildSpeed,2), textColor = color.stats_fg, }
	end
	
	
	local cells = printWeapons(ud)
	
	if cells and #cells > 0 then
		
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}
		
		statschildren[#statschildren+1] = Label:New{ caption = 'WEAPONS', textColor = color.stats_header,}
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}
		for _,v in ipairs(cells) do
			statschildren[#statschildren+1] = Label:New{ caption = v, textColor = color.stats_fg, }
		end
	end
	
	local stack_icons = StackPanel:New{
		autoArrangeV  = false,
		padding = {1,1,1,1},
		itemPadding = {1,1,1,1},
		itemMargin = {1,1,1,1},
		height = 100,
		width = 50,
		resizeItems = false,
		children = icons,
	}
	
	local stack_stats = Grid:New{
		columns=2,
		autoArrangeV  = false,
		height = (#statschildren/2)*15,
		width = '100%',
		children = statschildren,
		y = 1,
		padding = {1,1,1,1},
		itemPadding = {1,1,1,1},
		itemMargin = {1,1,1,1},
	}
	
	local helptext_stack = StackPanel:New{
		resizeItems = false,
		orientation = 'vertical',
		autoArrangeV  = false,
		autoArrangeH  = false,
		centerItems  = false,
		right = 60,
		x = 1,
		--width = 200,
		height = '100%',
		resizeItems = false,
		children = { helptextbox, stack_stats, },
	}
	return 
		{
			StackPanel:New{
				resizeItems = false,
				orientation = 'horizontal',
				autoArrangeV  = false,
				autoArrangeH  = false,
				centerItems  = false,
				padding = {1,1,1,1},
				itemPadding = {1,1,1,1},
				itemMargin = {1,1,1,1},
				height = 400 ,
				y = 1,
				width = '100%',
				children = { helptext_stack, stack_icons, },
			},
		}
	
end

local function tooltipBreakdown(tooltip)
	local unitname = nil

	if tooltip:find('Build', 1, true) == 1 then
		local start,fin = tooltip:find([[ - ]], 1, true)
		if start and fin then
			local unitHumanName
			local buildType
			if (tooltip:find('Build Unit:', 1, true) == 1) then
				buildType = 'buildunit'
				unitHumanName = tooltip:sub(13,start-1)
			else
				buildType = 'build'
				unitHumanName = tooltip:sub(8,start-1)
			end
			local udef = GetUnitDefByHumanName(unitHumanName)
			
			return udef or false
			
		end
		
	elseif tooltip:find('Morph', 1, true) == 1 then
		local unitHumanName = tooltip:gsub('Morph into a (.*)(time).*', '%1'):gsub('[^%a \-]', '')
		local udef = GetUnitDefByHumanName(unitHumanName)
		return udef or false
			
	elseif tooltip:find('Selected', 1, true) == 1 then
		local start,fin = tooltip:find([[ - ]], 1, true)
		if start and fin then
			local unitHumanName = tooltip:sub(11,start-1)
			local udef = GetUnitDefByHumanName(unitHumanName)
			return udef or false
		end
	end
	
	return false
end

----------------------------------------------------------------

local function hideWindow(window)
	if not window then return end
	window:SetPos(-1000, -1000)
	window.visible = false
end
--[[
local function showWindow(window, x, y)
	window.visible = true
	if x then
		window:SetPos(x,y)
	end
end
--]]
local function KillStatsWindow(num)
	statswindows[num]:Dispose()
	statswindows[num] = nil
end

local function MakeStatsWindow(ud, x,y)
	hideWindow(window_unitcontext)
	local y = scrH-y
	local x = x
	
	local window_width = 300
	local window_height = 300

	local num = #statswindows+1
	
	local children = {
		ScrollPanel:New{
			--horizontalScrollbar = false,
			x=0,y=15,
			width='100%',
			bottom = B_HEIGHT*2,
			padding = {2,2,2,2},
			children = printunitinfo(ud, WG.lang or 'en', window_width) ,
		},	
		Button:New{ 
			caption = 'Close', 
			OnMouseUp = { function(self) KillStatsWindow(num) end }, 
			
			x=0,
			height=B_HEIGHT,
			right=10,
			bottom=1,
			
			backgroundColor=color.sub_back_bg, 
			textColor=color.sub_back_fg,
		}
	}

	x,y = AdjustWindow(x,y, window_width, window_height)

	if window_unitstats then
		window_unitstats:Dispose()
	end

	statswindows[num] = Window:New{  
		x = x,  
		y = y,  
		clientWidth  = window_width,
		clientHeight = window_height,
		resizable = true,
		parent = screen0,
		backgroundColor = color.stats_bg, 
		
		minimumSize = {250,300},
		
		caption = ud.humanName ..' - '.. getDescription(ud, WG.lang or 'en'), 
		
		children = children,
	}
	
end

local function PriceWindow(unitID, action)
	local window_width = 250
	
	local header = 'Offer For Sale'
	local command = '$sell:'
	local cancelText = 'Cancel Sale'
	if action == 'buy' then
		header = 'Offer To Buy'
		command = '$buy :'
		cancelText = 'Cancel Offer'
	elseif action == 'bounty' then
		header = 'Place Bounty (Cannot cancel!)'
		command = '$bounty:'
	end
	
	local children = {}
	children[#children+1] = Label:New{ caption = header, width=window_width, height=B_HEIGHT, textColor = color.context_header,}
	
	local grid_children = {}
	
	local dollar_amounts = {50,100,200,500,1000,2000,5000,10000, 0}
	for _, dollar_amount in ipairs(dollar_amounts) do
		local caption, func
		if action == 'bounty' then
			if dollar_amount ~= 0 then
				caption = '$' .. dollar_amount
				func = function() spSendLuaRulesMsg(  command .. unitID .. '|' .. dollar_amount ) end
			end
		else
			caption = dollar_amount == 0 and cancelText or '$' .. dollar_amount
			func = function() spSendLuaRulesMsg(  command .. unitID .. '|' .. dollar_amount) end
		end
		if caption then
			grid_children[#grid_children+1] = Button:New{ 
				caption = caption, 
				OnMouseUp = { func, CloseButtonFunc2 }, 
				width=window_width,
				height=B_HEIGHT,
				backgroundColor=color.sub_back_bg, 
				textColor=color.sub_back_fg,
			}
		end
	end
	--local grid_height = (B_HEIGHT)* #grid_children /3
	local grid_height = (B_HEIGHT)* 3
	local price_grid = Grid:New{
		--rows = 3,
		columns = 3,
		resizeItems=true,
		width = window_width,
		height = grid_height,
		padding = {0,0,0,0},
		itemPadding = {2,2,2,2},
		itemMargin = {0,0,0,0},
		
		children = grid_children,
	}
	
	children[#children+1] = price_grid
	
	children[#children+1] = Label:New{ caption = '', width=window_width, height=B_HEIGHT, autosize=false,}

	children[#children+1] =  CloseButton(window_width)
	
	local window_height = (B_HEIGHT) * (#children-1) + grid_height
	--echo ('winheight',window_height)
		
	local stack1 = StackPanel:New{
		centerItems = false,
		resizeItems=false,
		width = window_width,
		height = window_height,
		padding = {0,0,0,0},
		itemPadding = {2,2,2,2},
		itemMargin = {0,0,0,0},
		children = children,
	}
	
	local window = Window:New{  
		x = scrW/2,  
		y = scrH/2,
		clientWidth  = window_width,
		clientHeight = window_height,
		resizable = false,
		parent = screen0,
		backgroundColor = color.context_bg, 
		children = {stack1},
	}
end

local function MakeUnitContextMenu(unitID,x,y)
	--hideWindow(window_unitstats)
					
	local udid 			= spGetUnitDefID(unitID)
	local ud 			= UnitDefs[udid]
	if not ud then return end
	local alliance 		= spGetUnitAllyTeam(unitID)
	local team			= spGetUnitTeam(unitID)
	local _, player 	= spGetTeamInfo(team)
	local playerName 	= spGetPlayerInfo(player) or 'noname'
	local teamColor 	= {spGetTeamColor(team)}
		
	local window_width = 200
	--local buttonWidth = window_width - 0
	
	
	local children = {
		Label:New{ caption =  ud.humanName ..' - '.. getDescription(ud, WG.lang or 'en'), width=window_width, textColor = color.context_header,},
		Label:New{ caption = 'Player: ' .. playerName, width=window_width, textColor=teamColor },
		Label:New{ caption = 'Alliance - ' .. alliance .. '    Team - ' .. team, width=window_width ,textColor = color.context_fg,},
		
		Button:New{ 
			caption = 'Unit Info', 
			OnMouseUp = { function() MakeStatsWindow(ud,x,y) end }, 
			width=window_width,
			backgroundColor=color.sub_back_bg, 
			textColor=color.sub_back_fg,
		},
	}
	local y = scrH-y
	local x = x
	
	if marketandbounty then
		if team == myTeamID then
			children[#children+1] =  Button:New{ 
				caption = 'Offer For Sale', 
				OnMouseUp = { function(self) PriceWindow(unitID, 'sell') end }, 
				width=window_width, 
				backgroundColor=color.sub_back_bg, 
				textColor=color.sub_back_fg,
			}
		else
			children[#children+1] =  Button:New{ 
				caption = 'Offer To Buy', 
				OnMouseUp = { function(self) PriceWindow(unitID, 'buy') end }, 
				width=window_width, 
				backgroundColor=color.sub_back_bg, 
				textColor=color.sub_back_fg,
			}
		end
		if myAlliance ~= alliance then
			children[#children+1] =  Button:New{ 
				caption = 'Place Bounty', 
				OnMouseUp = { function(self) PriceWindow(unitID, 'bounty') end }, 
				width=window_width, 
				backgroundColor=color.sub_back_bg, 
				textColor=color.sub_back_fg,
			}
		end
	end

	
	--echo(window_height)
	if ceasefires and myAlliance ~= alliance then
		window_height = window_height + B_HEIGHT*2
		children[#children+1] = Button:New{ caption = 'Vote for ceasefire', OnMouseUp = { function() spSendLuaRulesMsg('cf:y'..alliance) end }, width=window_width}
		children[#children+1] = Button:New{ caption = 'Break ceasefire/unvote', OnMouseUp = { function() spSendLuaRulesMsg('cf:n'..alliance) spSendLuaRulesMsg('cf:b'..alliance) end }, width=window_width}
	end
	children[#children+1] = CloseButton()
	
	local window_height = (B_HEIGHT)* #children
	
	x,y = AdjustWindow(x,y,window_width, window_height)
	if window_unitcontext then
		window_unitcontext:Dispose()
	end
	local stack1 = StackPanel:New{
		centerItems = false,
		--autoArrangeV = true,
		--autoArrangeH = true,
		resizeItems=true,
		width = window_width,
		height = window_height,
		padding = {0,0,0,0},
		itemPadding = {2,2,2,2},
		itemMargin = {0,0,0,0},
		children = children,
	}
	
	window_unitcontext = Window:New{  
		x = x,  
		y = y,  
		clientWidth  = window_width,
		clientHeight = window_height,
		resizable = false,
		parent = screen0,
		backgroundColor = color.context_bg, 
		children = {stack1},
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:MousePress(x,y,button)
	
	if button ~= 1 then return end
	
	local alt, ctrl, meta, shift = spGetModKeyState()
	
	if not options.noContextClick.value and meta then
		local cur_ttstr = screen0.currentTooltip or spGetCurrentTooltip()
		local ud = tooltipBreakdown(cur_ttstr)
		
		local _,cmd_id = Spring.GetActiveCommand()
		
		if cmd_id and cmd_id < 0 then
			return false
		end
		
		if ud then
			MakeStatsWindow(ud,x,y)
			return true
		end
		
		local type, data = spTraceScreenRay(x, y)
		if (type == 'unit') then
			local unitID = data
			MakeUnitContextMenu(unitID,x,y)
			return true
		elseif (type == 'feature') then
			local fdid = Spring.GetFeatureDefID(data)
			local fd = fdid and FeatureDefs[fdid]
			local feature_name = fd and fd.name
			if feature_name then
				local live_name = feature_name:gsub('([^_]*).*', '%1')
				local ud = UnitDefNames[live_name]
				if ud then
					MakeStatsWindow(ud,x,y)
					return true
				end
			end
		end
		
	end

	--[[
	if window_unitcontext and window_unitcontext.visible and (not screen0.hoveredControl or not screen0.hoveredControl:IsDescendantOf(window_unitcontext)) then
		hideWindow(window_unitcontext)
		return true
	end
	
	if window_unitstats and window_unitstats.visible and (not screen0.hoveredControl or not screen0.hoveredControl:IsDescendantOf(window_unitstats)) then
		hideWindow(window_unitstats)
		return true
	end
	--]]
end

function widget:ViewResize(vsx, vsy)
	scrW = vsx
	scrH = vsy
end


function widget:Initialize()

	if (not WG.Chili) then
		widgetHandler:RemoveWidget(widget)
		return
	end
	
	-- setup Chili
	 Chili = WG.Chili
	 Button = Chili.Button
	 Label = Chili.Label
	 Window = Chili.Window
	 ScrollPanel = Chili.ScrollPanel
	 StackPanel = Chili.StackPanel
	 Grid = Chili.Grid
	 TextBox = Chili.TextBox
	 Image = Chili.Image
	 screen0 = Chili.Screen0

	widget:ViewResize(Spring.GetViewGeometry())
	
end

function widget:Shutdown()
end
