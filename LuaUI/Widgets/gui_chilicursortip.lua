--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "Chili Cursor Tip",
    desc      = "v0.25 Chili Cursor Tooltips.",
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

local spGetCurrentTooltip		= Spring.GetCurrentTooltip
local spGetUnitDefID			= Spring.GetUnitDefID
local spGetFeatureDefID			= Spring.GetFeatureDefID
local spGetFeatureTeam			= Spring.GetFeatureTeam
local spGetUnitAllyTeam			= Spring.GetUnitAllyTeam
local spGetUnitTeam				= Spring.GetUnitTeam
local spGetUnitHealth			= Spring.GetUnitHealth
local spGetUnitResources		= Spring.GetUnitResources
local spTraceScreenRay			= Spring.TraceScreenRay
local spGetTeamInfo				= Spring.GetTeamInfo
local spGetPlayerInfo			= Spring.GetPlayerInfo
local spGetTeamColor			= Spring.GetTeamColor
local spGetUnitTooltip			= Spring.GetUnitTooltip
local spGetModKeyState			= Spring.GetModKeyState
local spGetMouseState			= Spring.GetMouseState
local spSendCommands			= Spring.SendCommands
local spGetSelectedUnitsCount	= Spring.GetSelectedUnitsCount
local spGetUnitIsStunned		= Spring.GetUnitIsStunned
local spGetUnitResources		= Spring.GetUnitResources

local abs						= math.abs
local strFormat 				= string.format

local echo = Spring.Echo


local iconFormat = ''
local color = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local Button
local Label
local Window
local StackPanel
local Grid
local TextBox
local Image
local Multiprogressbar
local Progressbar
local screen0


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local B_HEIGHT = 30
local icon_size = 20
local stillCursorTime = 0

local scrH, scrW = 0,0
local cycle = 0
local old_ttstr, old_data
local old_mx, old_my = -1,-1
local mx, my = -1,-1
local showExtendedTip = false
local changeNow = false

local window_tooltip, tt_healthbar, tt_unitID, tt_ud, tt_fd

local stack_main, stack_leftmargin
local globalitems = {}

local ttFontSize = 2

local green = '\255\1\255\1'
local cyan = '\255\1\255\255'
local white = '\255\255\255\255'

local numSelectedUnits = 0
local selectedUnits = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function StaticChanged() 
	if (window_tooltip) then
		window_tooltip:Dispose()
	end
	
	Initialize()
end 

options_path = 'Settings/Interface/Tooltip'
options_order = { 'tooltip_delay',  'statictip', 'fontsize', 'staticfontsize', 'hpshort'}

options = {

	tooltip_delay = {
		name = 'Tooltip display delay (0 - 4s)',
		desc = 'Determines how long you can leave the mouse idle until the tooltip is displayed.',
		type = 'number',
		min=0,max=4,step=0.1,
		value = 0,
	},
	
	fontsize = {
		name = 'Font Size (10-20)',
		desc = 'Resizes the font of the tip',
		type = 'number',
		min=10,max=20,step=1,
		value = 10,
		OnChange = FontChanged,
	},
	
	staticfontsize = {
		name = 'Static Display Font Size (10-30)',
		desc = 'Resizes the font for the static display of group and terrain information',
		type = 'number',
		min=10,max=30,step=2,
		value = 10,
		OnChange = FontChanged,
	},
	
	statictip = {
		name = "Static Tooltip",
		type = 'bool',
		value = false,
		desc = 'Makes the tooltip static and moveable',
		OnChange = StaticChanged,
	},
	
	hpshort = {
		name = "HP Short Notation",
		type = 'bool',
		value = false,
		desc = 'Shows short number for HP.',
	},
	
	
}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function FontChanged() 
	ttFontSize = options.fontsize.value
	gFontSize = options.staticfontsize.value - ttFontSize
end


options.fontsize.OnChange = FontChanged
options.staticfontsize.OnChange = FontChanged

function comma_value(amount)
	local formatted

	-- amount is a string when ToSI is used before calling this function
	if type(amount) == "number" then
		formatted = strFormat("%.2f", amount)
	else
		formatted = amount .. ""
	end

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

local function ToSIPrec(num) -- more presise
  if type(num) ~= 'number' then
	return 'Tooltip wacky error #56'
  end
  if (num == 0) then
    return "0"
  else
    local absNum = abs(num)
    if (absNum < 0.001) then
      return strFormat("%.2fu", 1000000 * num)
    elseif (absNum < 1) then
      return strFormat("%.2f", num)
    elseif (absNum < 1000) then
      return strFormat("%.1f", num)
    elseif (absNum < 1000000) then
      return strFormat("%.2fk", 0.001 * num)
    else
      return strFormat("%.2fM", 0.000001 * num)
    end
  end
end

local function numformat(num)
	return comma_value(ToSI(num))
end


local function AdjustWindow(window)
	local nx
	if (0 > window.x) then
		nx = 0
	elseif (window.x + window.width > screen0.width) then
		nx = screen0.width - window.width
	end

	local ny
	if (0 > window.y) then
		ny = 0
	elseif (window.y + window.height > screen0.height) then
		ny = screen0.height - window.height
	end

	if (nx or ny) then
		window:SetPos(nx,ny)		
	end

	--//FIXME If we don't do this the stencil mask of stack_rightside doesn't get updated, when we move the mouse (affects only if type(stack_rightside) == StackPanel)
	stack_main:Invalidate()
	stack_leftmargin:Invalidate()
	
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- group selection
	
local function UpdateDynamicGroupInfo()

	gi_cost = 0
	gi_hp = 0
	gi_metalincome = 0
	gi_metaldrain = 0
	gi_energyincome = 0
	gi_energydrain = 0
	gi_usedbp = 0
	
	for i = 1, numSelectedUnits do
		local id = selectedUnits[i]
	
		local ud = UnitDefs[spGetUnitDefID(id) or 0]
		if ud then
			local name = ud.name 
			local hp, _, paradam, cap, build = spGetUnitHealth(id)
			local mm,mu,em,eu = spGetUnitResources(id)
		
			if name ~= "terraunit" then
				gi_cost = gi_cost + ud.metalCost*build
				gi_hp = gi_hp + hp
				
				local stunned_or_inbuld = spGetUnitIsStunned(id)
				if not stunned_or_inbuld then 
					if name == 'armmex' or name =='cormex' then -- mex case
						local tooltip = spGetUnitTooltip(id)
						
						local baseMetal = 0
						local s = tooltip:match("Makes: ([^ ]+)")
						if s ~= nil then 
							baseMetal = tonumber(s) 
						end 
										
						s = tooltip:match("Overdrive: %+([0-9]+)")
						local od = 0
						if s ~= nil then 
							od = tonumber(s) 
						end
						
						gi_metalincome = gi_metalincome + baseMetal + baseMetal * od / 100
							
						s = tooltip:match("Energy: ([^ ]+)")
						if s ~= nil then 
							gi_energydrain = gi_energydrain - tonumber(s) 
						end 
					else
						gi_metalincome = gi_metalincome + mm
						gi_metaldrain = gi_metaldrain + mu
						gi_energyincome = gi_energyincome + em
						gi_energydrain = gi_energydrain + eu
					end
					
					if ud.buildSpeed ~= 0 then
						gi_usedbp = gi_usedbp + mu
					end
				end
			end
		end
		
	end
	
	gi_cost = ToSIPrec(gi_cost)
	gi_hp = ToSIPrec(gi_hp)
	gi_metalincome = ToSIPrec(gi_metalincome)
	gi_metaldrain = ToSIPrec(gi_metaldrain)
	gi_energyincome = ToSIPrec(gi_energyincome)
	gi_energydrain = ToSIPrec(gi_energydrain)
	gi_usedbp = ToSIPrec(gi_usedbp)
	
end

local function UpdateStaticGroupInfo()

	gi_count = numSelectedUnits
	gi_finishedcost = 0
	gi_totalbp = 0
	gi_maxhp = 0
	
	for i = 1, numSelectedUnits do
		local ud = UnitDefs[spGetUnitDefID(selectedUnits[i]) or 0]
		if ud then
			local name = ud.name 
			if name ~= "terraunit" then
				gi_totalbp = gi_totalbp + ud.buildSpeed
				gi_maxhp = gi_maxhp + ud.health
				gi_finishedcost = gi_finishedcost + ud.metalCost
			end
		end
	end
	
	gi_finishedcost = ToSIPrec(gi_finishedcost)
	gi_totalbp = ToSIPrec(gi_totalbp)
	gi_maxhp = ToSIPrec(gi_maxhp)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local UnitDefByHumanName_cache = {}
local function GetUnitDefByHumanName(humanName)
	local cached_udef = UnitDefByHumanName_cache[humanName]
	if (cached_udef ~= nil) then
		return cached_udef
	end

	for _,ud in pairs(UnitDefs) do
		if ud.humanName == humanName then
			UnitDefByHumanName_cache[humanName] = ud
			return ud
		end
	end
	UnitDefByHumanName_cache[humanName] = false
	return false
end

local function tooltipBreakdown(tooltip)

	local unitname = nil

	tooltip = tooltip:gsub('\r', '\n')
	tooltip = tooltip:gsub('\n+', '\n')
	
	--echo (tooltip)
	local requires, provides, consumes, unitDef, buildType, morph_data
	if tooltip:find('Requires', 5, true) == 5 then
		requires, tooltip = tooltip:match('....Requires([^\n]*)\n....(.*)')
	end
	
	if tooltip:find('Provides', 1, true) == 1 then
		provides, tooltip = tooltip:match('Provides([^\n]*)\n(.*)')
	end
	
	if tooltip:find('Consumes', 5, true) == 5 then
		--consumes, tooltip = tooltip:match('....Consumes([^\n]*)\n....(.*)')
	end
	
	if tooltip:find('Build', 1, true) == 1 then
		local start,fin = tooltip:find([[ - ]], 1, true)
		if start and fin then
			
			local unitHumanName
			
			if (tooltip:find('Build Unit:', 1, true) == 1) then
				buildType = 'buildunit'
				unitHumanName = tooltip:sub(13,start-1)
			else
				buildType = 'build'
				unitHumanName = tooltip:sub(8,start-1)
			end
			unitDef = GetUnitDefByHumanName(unitHumanName)
			
			tooltip = tooltip:sub(fin+1)
		end
		
	elseif tooltip:find('Morph', 1, true) == 1 then
		
		local unitHumanName = tooltip:gsub('Morph into a (.*)(time).*', '%1'):gsub('[^%a \-]', '')
		unitDef = GetUnitDefByHumanName(unitHumanName)
		
		local needunit
		if tooltip:find('needs unit', 1, true) then
  			needunit = tooltip:gsub('.*needs unit: (.*)', '%1'):gsub('[^%a \-]', '')
		end
		morph_data = {
			morph_time 		= tooltip:gsub('.*time:(.*)metal.*', '%1'):gsub('[^%d]', ''),
			morph_cost 		= tooltip:gsub('.*metal: (.*)energy.*', '%1'):gsub('[^%d]', ''),
			morph_prereq 	= needunit,
		}
	end
	
	return {
		tooltip		= tooltip, 
		unitDef		= unitDef, 
		buildType	= buildType, 
		morph_data	= morph_data,
		requires	= requires,
		provides	= provides,
		consumes	= consumes,
	}
end

----------------------------------------------------------------

local function SetHealthbar()
	if not tt_ud or not tt_unitID then return 'err' end
		
	local health, maxhealth = spGetUnitHealth(tt_unitID)
	if health then
		tt_healthbar.color = {0,1,0, 1}
		
		tt_health_fraction = health/maxhealth
		tt_healthbar:SetValue(tt_health_fraction)
		if options.hpshort.value then
			tt_healthbar:SetCaption(numformat(health) .. ' / ' .. numformat(maxhealth))
		else
			tt_healthbar:SetCaption(math.ceil(health) .. ' / ' .. math.ceil(maxhealth))
		end
		
	else
		tt_healthbar.color = {0,0,0.5, 1}
		local maxhealth = tt_ud.health
		tt_healthbar:SetValue(1)
		if options.hpshort.value then
			tt_healthbar:SetCaption('??? / ' .. numformat(maxhealth))
		else
			tt_healthbar:SetCaption('??? / ' .. math.ceil(maxhealth))
		end
	end
end


local function KillTooltip()
	if options.statictip.value then
		window_tooltip:ClearChildren()
	else
		screen0:RemoveChild(window_tooltip)
		old_ttstr = ''
		tt_unitID = nil
	end
	
end

local function GetResourceStack(tooltip_type, unitID, ud, tooltip, fontSize)

	local stack_children = {}

	if tooltip_type == 'feature' then
		local rem_metal = ud.metal
		local rem_energy = ud.energy

		if unitID then
			local m, e = Spring.GetFeatureResources(unitID)
			rem_metal = m or rem_metal
			rem_energy =  e or rem_energy
		end
		local lbl_metal = Label:New{ caption = numformat(rem_metal), autosize=true, fontSize=fontSize, valign='center' }
		local lbl_energy = Label:New{ caption = numformat(rem_energy), autosize=true, fontSize=fontSize, valign='center'  }

		stack_children = {
			Image:New{file='LuaUI/images/ibeam.png',height= icon_size,width= icon_size, fontSize=ttFontSize,},
			lbl_metal,
			Image:New{file='LuaUI/images/energy.png',height= icon_size,width= icon_size, fontSize=ttFontSize,},
			lbl_energy,
		}
	else

		local metalMake, metalUse, energyMake,energyUse = Spring.GetUnitResources(unitID)
		
		local absMetal, absEnergy = 0,0
		if metalMake then
			absMetal = metalMake - metalUse
			absEnergy = energyMake - energyUse
		end
		
		-- special cases for mexes
		if ud.name == 'armmex' or ud.name=='cormex' then 
			local baseMetal = 0
			local s = tooltip:match("Makes: ([^ ]+)")
			if s ~= nil then baseMetal = tonumber(s) end 
							
			s = tooltip:match("Overdrive: %+([0-9]+)")
			local od = 0
			if s ~= nil then od = tonumber(s) end
			
			absMetal = absMetal + baseMetal + baseMetal * od / 100
			
			s = tooltip:match("Energy: ([^ ]+)")
			if s ~= nil and type(s) == number then 
				absEnergy = absEnergy +tonumber(s) 
			end 
		end 
		
		local lbl_metal = Label:New{ autosize=true, fontSize=fontSize, valign='center' }
		if abs(absMetal) <= 0.1 then
			lbl_metal.font:SetColor(0.5,0.5,0.5,1)
			lbl_metal:SetCaption("0.0")
		else
			if (absMetal<0) then
				lbl_metal.font:SetColor(1,0,0,1)
			else
				lbl_metal.font:SetColor(0,1,0,1)
			end
			lbl_metal:SetCaption( ("%0.1f"):format(absMetal) )
		end
		
		local lbl_energy = Label:New{ autosize=true, fontSize=fontSize, valign='center'  }
		if abs(absEnergy) <= 0.1 then
			lbl_energy.font:SetColor(0.5,0.5,0.5,1)
			lbl_energy:SetCaption("0.0")
		else
			if (absEnergy<0) then
				lbl_energy.font:SetColor(1,0,0,1)
			else
				lbl_energy.font:SetColor(0,1,0,1)
			end
			lbl_energy:SetCaption( ("%0.1f"):format(absEnergy) )
		end
		
		stack_children = {
			Image:New{file='LuaUI/images/ibeam.png',height= icon_size,width= icon_size, fontSize=ttFontSize,},
			lbl_metal,
			Image:New{file='LuaUI/images/energy.png',height= icon_size,width= icon_size, fontSize=ttFontSize,},
			lbl_energy,
		}
	end
	
	return StackPanel:New{
		centerItems = false,
		autoArrangeV = true,
		orientation='horizontal',
		resizeItems=false,
		width = '100%',
		height = icon_size+1,
		padding = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin = {5,0,0,0},
		children = stack_children,
	}

		
end

local function PlaceToolTipWindow(new, x,y)
	if new then
		window_tooltip:ClearChildren()

		if stack_main and stack_leftmargin then
			window_tooltip:AddChild(stack_leftmargin)
			window_tooltip:AddChild(stack_main)
		end
		
		if not window_tooltip:IsDescendantOf(screen0) then
			screen0:AddChild(window_tooltip)
		end
	end
	if not options.statictip.value then
		local x = x
		local y = scrH-y
		window_tooltip:SetPos(x,y)
		AdjustWindow(window_tooltip)
	end

	window_tooltip:BringToFront()
end

local function GetMorphControl(morph_data)
	local morph_controls = {}
	local height = 0
	if morph_data then
		local morph_time 	= morph_data.morph_time
		local morph_cost 	= morph_data.morph_cost
		local morph_prereq 	= morph_data.morph_prereq
		
		morph_controls[#morph_controls + 1] = Label:New{ caption = 'Morph: ', height= icon_size, valign='center', textColor=color.tooltip_info, autoSize=false, width=45, fontSize=ttFontSize,}
		morph_controls[#morph_controls + 1] = Image:New{file='LuaUI/images/clock.png',height= icon_size,width= icon_size, fontSize=ttFontSize,}
		morph_controls[#morph_controls + 1] = Label:New{ caption = morph_time, valign='center', textColor=color.tooltip_info, autoSize=false, width=25, fontSize=ttFontSize,}
		morph_controls[#morph_controls + 1] = Image:New{file='LuaUI/images/ibeam.png',height= icon_size,width= icon_size, fontSize=ttFontSize,}
		morph_controls[#morph_controls + 1] = Label:New{ caption = morph_cost, valign='center', textColor=color.tooltip_info, autoSize=false, width=25, fontSize=ttFontSize,}
		
		if morph_prereq then
			morph_controls[#morph_controls + 1] = Label:New{ caption = 'Need Unit: '..morph_prereq, valign='center', textColor=color.tooltip_info, autoSize=false, width=180, fontSize=ttFontSize,}
		end
		height = icon_size+1
	end
	return StackPanel:New  {
			centerItems = false,
			autoArrangeV = true,
			orientation='horizontal',
			resizeItems=false,
			width = '100%',
			height = height,
			padding = {0,0,0,0},
			itemPadding = {0,0,0,0},
			itemMargin = {0,0,0,0},
			children = morph_controls,
		}
end


local function GetHelpText(tooltip_type)
	local _,_,_,buildUnitName = Spring.GetActiveCommand()
	if buildUnitName then
		return ''
	end

	local sc_caption = ''
	if tooltip_type == 'build' then
		sc_caption = 'Space+click: Show unit stats'
	elseif tooltip_type == 'buildunit' then
			if showExtendedTip then
			
				sc_caption = 
					'Shift+click: Add 5 to queue.\n'..
					'Ctrl+click: Add 20 to queue.\n'..
					'Alt+click: Add one unit to front of queue. \n'..
					'Rightclick: remove 1 unit from queue.\n'..
					'Space+click: Show unit stats'
			else
				sc_caption = '(Hold Spacebar for help)'
			end
	
	elseif tooltip_type == 'morph' then
		sc_caption = 'Space+click: Show unit stats'
	else
		sc_caption = 'Space+click: Show options'
	end
	--return TextBox:New{ text = sc_caption, textColor=color.tooltip_help, width=250, fontSize=ttFontSize,  }
	return sc_caption
	
end

local function UnitBuildpic(ud)
	if not ud then return end
	return Image:New{
		file2 = (WG.GetBuildIconFrame)and(WG.GetBuildIconFrame(ud)),
		file = "#" .. ud.id,
		keepAspect = false,
		height  = 55*(4/5),
		width   = 55,
	}
end

local function MakeStack(ttstackdata, leftmargin)
	local children = {}
	local height = 0
	
	for i, item in ipairs( ttstackdata ) do
		local stack_children = {}
		local empty = false
		if item.directcontrol then
			local directitem = (type( item.directcontrol ) == 'string') and globalitems[item.directcontrol] or item.directcontrol			
			stack_children[#stack_children+1] = directitem
		elseif item.text or item.icon then
			local curFontSize = ttFontSize + (item.fontSize or 0)
			local itemtext =  item.text or ''
			local stackchildren = {}

			if item.icon then
				stack_children[#stack_children+1] = Image:New{file = item.icon, height= icon_size,width= icon_size, fontSize=curFontSize,}
			end
			
			if item.wrap then
				stack_children[#stack_children+1] =  TextBox:New{ 
					autosize=false,
					text = itemtext , 
					width='100%', 
					valign="ascender", 
					font={ size=curFontSize }, 
					fontShadow=true,
				}
			else
				local rightmargin = item.icon and icon_size or 0
				local width = (leftmargin and 50 or 230) - rightmargin
				stack_children[#stack_children+1] = Label:New{ caption = itemtext, fontSize=curFontSize, valign='center', height=icon_size+5, width = width }
			end
		else
			empty = true
		end
		
		if not empty then
			children[#children+1] = StackPanel:New{
				centerItems = false,
				autoArrangeV = true,
				orientation='horizontal',
				resizeItems=false,
				width = '100%',
				autosize=true,
				padding = {1,1,1,1},
				itemPadding = {0,0,0,0},
				itemMargin = {4,0,0,0},
				children = stack_children,
			}
		end
	end
	return children
end

local function MakeToolTip2(ttdata)
	
	if not ttdata.main then
		echo '<Cursortip> Missing ttdata.main'
		return
	end
	
	local children_main  = MakeStack(ttdata.main)
	local leftside = false
	if ttdata.leftmargin then
		children_leftmargin  = MakeStack(ttdata.leftmargin, true)
		
		stack_leftmargin = 
			StackPanel:New{
				orientation='vertical',
				padding = {0,0,0,0},
				itemPadding = {1,0,0,0},
				itemMargin = {0,0,0,0},
				resizeItems=false,
				autosize=true,
				width = 60,
				children = children_leftmargin,
			}
		leftside = true
	else
		stack_leftmargin = StackPanel:New{	
			width=10
		}
	end
	
	stack_main = StackPanel:New{
		autosize=true,
		x = leftside and 60 or 0,
		y = 0,
		orientation='vertical',
		centerItems = false,
		width = 240,
		padding = {0,0,0,0},
		itemPadding = {1,0,0,0},
		itemMargin = {0,0,0,0},
		resizeItems=false,
		children = children_main,
	}
	
	PlaceToolTipWindow(true, mx+20,my-20)
	

end

local function makeGroupTooltip()

	MakeToolTip2(
		{
			main = {
				{ text = "Selected Units " .. gi_count .. "\n" ..
					"Health " .. gi_hp .. " / " ..  gi_maxhp  .. "\n" ..
					"Cost " .. gi_cost .. " / " ..  gi_finishedcost .. "\n" ..
					"Metal \255\0\255\0+" .. gi_metalincome .. "\255\255\255\255 / \255\255\0\0-" ..  gi_metaldrain  .. "\255\255\255\255\n" ..
					"Energy \255\0\255\0+" .. gi_energyincome .. "\255\255\255\255 / \255\255\0\0-" .. gi_energydrain .. "\255\255\255\255\n" ..
					"Build Power " .. gi_usedbp .. " / " ..  gi_totalbp,
					fontSize = gFontSize,
				},
			},
		}
	)	

end

--Determines what type of tooltip to show
local function DetermineTooltip()
	local cur_ttstr = screen0.currentTooltip or spGetCurrentTooltip()
	local type, data = spTraceScreenRay(mx, my)
	if (not changeNow) and old_ttstr == cur_ttstr and old_data == data then
		PlaceToolTipWindow(false, mx+20,my-20)
		return
	end
	old_data = data
	old_ttstr = cur_ttstr
	
	tt_unitID = nil
	tt_ud = nil

	--chili control tooltip
	if screen0.currentTooltip ~= nil 
		and not screen0.currentTooltip:find('Build') --detect if chili control shows build option
		and not screen0.currentTooltip:find('Morph') --detect if chili control shows morph option
		then 
		if cur_ttstr ~= '' and cur_ttstr:gsub(' ',''):len() > 0 then
			MakeToolTip2({
				main = {
					{ text = cur_ttstr, wrap=true },
				}
			})
		else
			KillTooltip() 
		end
		return
	end
	
	local tt_table = tooltipBreakdown(cur_ttstr)
	local tooltip, unitDef, buildType  = tt_table.tooltip, tt_table.unitDef, tt_table.buildType
	
	if not tooltip then
		KillTooltip()
		return
	elseif unitDef then
		tt_ud = unitDef
		
		local morph_control = GetMorphControl( tt_table.morph_data )
		
		--help text
		local helptext = GetHelpText( buildType )
		
		MakeToolTip2({
			leftmargin = {
				{ directcontrol = UnitBuildpic( tt_ud ) },
				{ icon = 'LuaUI/images/ibeam.png', text = cyan .. numformat(tt_ud.metalCost), },
			},
			main = {
				{ icon = 'icons/'.. tt_ud.iconType ..iconFormat, text = tt_ud.humanName, fontSize=2 },
				{ text = tt_ud.tooltip, wrap=true },
				tt_table.requires and { text = 'REQUIRES' .. tt_table.requires, } or {},
				tt_table.provides and { text = 'PROVIDES' .. tt_table.provides, } or {},
				tt_table.consumes and { text = 'CONSUMES' .. tt_table.consumes, } or {},
				{ icon = 'LuaUI/images/health.png',  text = numformat(tt_ud.health), },
				{ directcontrol = morph_control },
				{ text = green .. helptext, wrap=true},
			},
		})
		return
	end
	
	-- empty tooltip
	if (tooltip == '') or tooltip:gsub(' ',''):len() <= 0 then
		if (showExtendedTip and (numSelectedUnits > 0)) then
			makeGroupTooltip()
			return
		end
		KillTooltip()
		return
	end	

	--unit(s) selected/pointed at 
	local unit_tooltip = tooltip:find('Experience %d+.%d+ Cost ')  --shows on your units, not enemy's
		or tooltip:find('TechLevel %d') --shows on units
		or tooltip:find('Metal.*Energy') --shows on features
	
	--unit(s) selected/pointed at
	if unit_tooltip then
		-- pointing at unit/feature
		if type == 'unit' or type == 'feature' then
			
			tt_unitID = data
			local tt_fd
			local team, fullname
			if type == 'unit' then
				team = spGetUnitTeam(tt_unitID) 
				tt_ud = UnitDefs[ spGetUnitDefID(tt_unitID) or -1]
				
				fullname = ((tt_ud and tt_ud.humanName) or "")	
			else -- type == feature
				team = spGetFeatureTeam(tt_unitID)
				local fdid = spGetFeatureDefID(tt_unitID)
				tt_fd = fdid and FeatureDefs[fdid or -1]
				local feature_name = tt_fd and tt_fd.name
				
				local desc = ''
				if feature_name:find('dead2') then
					desc = ' (debris)'
				elseif feature_name:find('dead') then
					desc = ' (wreckage)'
				end
				local live_name = feature_name:gsub('([^_]*).*', '%1')
				tt_ud = UnitDefNames[live_name]
				
				fullname = ((tt_ud and tt_ud.humanName .. desc) or "")
			end
			
			if not (tt_ud or tt_fd) then
				--fixme
				return
			end
			
			--local alliance       = spGetUnitAllyTeam(tt_unitID)
			local _, player      = spGetTeamInfo(team)
			local playerName = 'noname'
			if player then
				playerName     = spGetPlayerInfo(player) or 'noname'
			end
			local teamColor      = Chili.color2incolor(spGetTeamColor(team))
			
			local unittooltip = tt_unitID and spGetUnitTooltip(tt_unitID) or (tt_ud and tt_ud.tooltip) or ""
			
			MakeToolTip2({
				leftmargin = {
					{ directcontrol = UnitBuildpic( tt_ud ) },
					{ icon = 'LuaUI/images/ibeam.png', text = cyan .. numformat((tt_ud and tt_ud.metalCost) or '0'), },
				},
				main = {
					{ icon = 'icons/'.. ((tt_ud and tt_ud.iconType) or "") ..iconFormat, text = fullname .. ' (' .. teamColor .. playerName .. white ..')', fontSize=2, },
					{ text = unittooltip, wrap=true },
					((type == 'unit') and { directcontrol = 'healthbar', } or {}),
					{ directcontrol = GetResourceStack(type, tt_unitID, tt_ud or tt_fd, tooltip, ttFontSize ) },
					{ text = green .. 'Space+click: Show options', },
				},
			})
			
			return
		end
	
		--holding meta or static tip
		if (showExtendedTip) then
			if ((numSelectedUnits > 0)) then
				makeGroupTooltip()
				return
			end
			MakeToolTip2({
				main = {
					{ text = tooltip ,	fontSize = gFontSize,}
				},
			})
		else
			KillTooltip()
		end
		return
	end
	
	--tooltip that shows position
	local pos_tooltip = tooltip:sub(1,4) == 'Pos '
	
	-- default tooltip
	if not pos_tooltip or showExtendedTip then
	if numSelectedUnits > 0 and tooltip:find('experiance') and tooltip:find('range') then 
			makeGroupTooltip() 
			return 
		end 
		MakeToolTip2({
			main = {
				{ text = tooltip, fontSize = gFontSize, wrap=true},
			},
		})
		return
	end
	
	KillTooltip() 
	return
	
end --function DetermineTooltip

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Update(dt)
	cycle = cycle%100 + 1
	old_mx, old_my = mx,my
	alt,_,meta,_ = spGetModKeyState()
	mx,my = spGetMouseState()
	local mousemoved = (mx ~= old_mx or my ~= old_my)
	
	local show_cursortip = true
	if meta then
		if not showExtendedTip then changeNow = true end
		showExtendedTip = true
	
	else
		if options.tooltip_delay.value > 0 then
			if not mousemoved then
				stillCursorTime = stillCursorTime + dt
			else
				stillCursorTime = 0 
			end
			show_cursortip = stillCursorTime > options.tooltip_delay.value
		end
		
		if showExtendedTip then changeNow = true end
		showExtendedTip = false
	
	end

	if mousemoved or changeNow then
		if not show_cursortip then
			KillTooltip()
			return
		end
		DetermineTooltip()
		changeNow = false
	end
	
	SetHealthbar()
	
	if cycle == 1 then
		changeNow = true
		UpdateDynamicGroupInfo()
	end
	
end

function widget:SelectionChanged(newSelection)
	numSelectedUnits = spGetSelectedUnitsCount()
	selectedUnits = newSelection
	UpdateStaticGroupInfo()
	UpdateDynamicGroupInfo()
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
	
	local VFSMODE      = VFS.RAW_FIRST
	_, iconFormat = VFS.Include(LUAUI_DIRNAME .. "Configs/chilitip_conf.lua" , nil, VFSMODE)
	local confdata = VFS.Include(LUAUI_DIRNAME .. "Configs/crudemenu_conf.lua", nil, VFSMODE)
	color = confdata.color

	-- setup Chili
	 Chili = WG.Chili
	 Button = Chili.Button
	 Label = Chili.Label
	 Window = Chili.Window
	 StackPanel = Chili.StackPanel
	 Grid = Chili.Grid
	 TextBox = Chili.TextBox
	 Image = Chili.Image
	 Multiprogressbar = Chili.Multiprogressbar
	 Progressbar = Chili.Progressbar
	 screen0 = Chili.Screen0

	widget:ViewResize(Spring.GetViewGeometry())

	tt_healthbar = 
		Progressbar:New {
			width = '100%',
			height = icon_size+2,
			itemMargin    = {0,0,0,0},
			itemPadding   = {0,0,0,0},	
			padding = {0,0,0,0},
			color = {0,1,0,1},
			max=1,
			caption = 'a',

			children = {
				Image:New{file='LuaUI/images/health.png',height= icon_size,width= icon_size,  x=0,y=0},
			},
		}
		
	globalitems['healthbar'] = tt_healthbar

	stack_main = StackPanel:New{
		width=300, -- needed for initial tooltip
	}
	stack_leftmargin = StackPanel:New{
		width=10, -- needed for initial tooltip
	}
	
	if options.statictip.value then
		window_tooltip = Window:New{  
			--skinName = 'default',
			name   = 'tooltip',
			x      = 0,
			y = Chili.Screen.y - 130,
			clientHeight = 130,
			clientWidth  = 250,
			--useDList = false,
			dockable = true,
			resizable = false,
			tweakResizable = true,
			draggable = false,
			tweakDraggable = true,
			backgroundColor = color.tooltip_bg, 
			children = { stack_leftmargin, stack_main, },
		}
	
	else
		window_tooltip = Window:New{  
			--skinName = 'default',
			useDList = false,
			resizable = false,
			draggable = false,
			autosize  = true,
			backgroundColor = color.tooltip_bg, 
			children = { stack_leftmargin, stack_main, }
		}
	end

	FontChanged()
	spSendCommands({"tooltip 0"})

end

function widget:Shutdown()
	spSendCommands({"tooltip 1"})
	if (window_tooltip) then
		window_tooltip:Dispose()
	end
end
