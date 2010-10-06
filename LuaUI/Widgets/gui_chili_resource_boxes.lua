--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Resource Boxes",
    desc      = "v0.1 Chili Res bars in a little box.",
    author    = "CarRepairer/Licho",
    date      = "2009-01-04",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    experimental = false,
    enabled   = false
  }
end

--------------------------------------------------------------------------------
WG.energyWasted = 0
WG.energyForOverdrive = 0
WG.windEnergy = 0 
WG.highPriorityBP = 0
WG.lowPriorityBP = 0

--------------------------------------------------------------------------------
local spSendCommands			= Spring.SendCommands

local abs						= math.abs

local cycle = 1

local echo = Spring.Echo

local Chili
local Button
local Label
local Colorbars
local Checkbox
local Window
local ScrollPanel
local StackPanel
local Grid
local screen0


local e_window
local m_window

local strFormat = string.format
---------------------------------
-----------------------------------------------
--------------------------------------------------------------------------------
local function colShade(color, value)
	if value == nil then value = 0.7 end
	return {color[1]*value, color[2]*value, color[3]*value, color[4]}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local scaleFunction = function (x) return (math.log(1+x*140 ) / math.log(141)) end -- this is used for logarithmic scale graphs

local col_metal = {136/255,214/255,251/255,1}
local col_metal_shad = colShade(col_metal)
local col_energy = {1,1,0,1}
local col_energy_shad = {0.7,0.7,0,1}
local col_plus = {0,1,0,1}
local col_plus_shad = {0,0.7,0,1}
local col_minus = {1,0,0,1}
--local col_net = {1,1,1,1}
local col_minus_shad = {0.7,0,0,1}
local col_share = {1, 136/255, 174/255,1}
local col_construction = {163/255, 73/255, 164/255,1}
local col_overdrive = {1, 127/255, 39/255,1}
local col_overdrive_m = {112/255, 146/255, 90/255,1}
local col_reclaim = {0/255, 162/255, 232/255, 1}



local def_settings = {
	minversion = 2,
	e = {
		pos_x = 1800,
		pos_y = 0,
		--c_width = 400,
		--c_height = 40,
	},
	m = {
		pos_x = 1800,
		pos_y = 80,
		--c_width = 400,
		--c_height = 40,
	}
}
local settings = def_settings

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ToSI(num)
  if (num == 0) then
    return "0"
  else
    local absNum = abs(num)
    if (absNum < 10) then
      return strFormat("%.2f", num)
    elseif (absNum < 100) then
	  return strFormat("%.1f", num)
	elseif (absNum < 10000) then
	  return strFormat("%.0f", num)	
	else
      return strFormat("%.2fK", 0.001 * num)
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:Shutdown()
	screen0:RemoveChild(e_window)
	screen0:RemoveChild(m_window)
	spSendCommands({"resbar 1"})
end


-----------------------------------------------------------------------

local GetMyTeamID = Spring.GetMyTeamID
local GetTeamResources = Spring.GetTeamResources
local e_store_bar
local e_store_label
local e_storecap_label
local e_inc_label
local e_net_label
local e_pull_label
local e_bar_in
local e_bar_out
local e_bar_plus
local e_bar_minus
local e_missing
local e_icon
local e_icon_label
local e_bar_in_bars
local e_bar_in_bars_br
local e_bar_out_bars
local e_bar_out_bars_br

local last_e = 0
local last_eInco = 0
local last_ePull = 0


local m_store_bar
local m_store_label
local m_storecap_label
local m_inc_label
local m_net_label
local m_pull_label
local m_bar_in
local m_bar_out
local m_bar_plus
local m_bar_minus
local m_missing
local m_icon
local m_icon_label
local m_bar_in_bars
local m_bar_in_bars_br
local m_bar_out_bars
local m_bar_out_bars_br


local last_e = 0
local last_eInco = 0
local last_ePull = 0
local last_m = 0
local last_mInco = 0
local last_mPull = 0


--function widget:GameFrame(f) 
function widget:Update()
	cycle = cycle % 64 + 1
	
	if cycle%16 > 0 then return end
	
	local myTeamID = GetMyTeamID()

	local eCurr, eStor, ePull, eInco, eExpe, eShar, eSent, eReci = GetTeamResources(myTeamID, "energy")
	local mCurr, mStor, mPull, mInco, mExpe, mShar, mSent, mReci = GetTeamResources(myTeamID, "metal")
	
	eStor = eStor - 10000 -- reduce by hidden storage
	if eCurr > eStor then eCurr = eStor end -- cap by storage
	ePull = ePull - WG.energyWasted -- if there is energy wastage, dont show it as used pull energy
	
	if eCurr == last_e and eInco == last_eInco and ePull == last_ePull and mCurr == last_m and mInco == last_mInco and mPull == last_mPull then return end -- dont do anything if nothing changed
	
	e_store_bar.tooltip = "This shows your current energy reserves.\n Anything above 100% will be burned by 'mex overdrive'\n which increases production of your mines"
	m_store_bar.tooltip = "This shows your current metal reserves"
	

	local escale = e_scale.max
	--[[local bl = escale * 0.45  -- automatic rescale disabled atm
	if (escale < ePull or escale < eInco or escale < mPull or escale < mInco) then 
			e_scale.max = escale * 2 
			e_scale.min = escale * -2
			e_scale:Invalidate()
			m_scale.min = e_scale.min
			m_scale.max = e_scale.max
			m_scale:Invalidate()
			escale = e_scale.max
	elseif (escale > 1000 and ePull < bl and eInco < bl and  mPull < bl and mInco < bl) then 
			e_scale.max = escale * 0.5
			e_scale.min = escale * -0.5
			e_scale:Invalidate()
			m_scale.min = e_scale.min
			m_scale.max = e_scale.max
			m_scale:Invalidate()
			escale = e_scale.max
	end ]]-- 
	local mscale = escale

	
	local ed = 2 * (eCurr - last_e) / eStor
	if (ed >= 0) then 
	    if (ed > 1) then ed = 1 end 
		e_store_bar.bars[1].percent = eCurr / eStor	 -ed
		e_store_bar.bars[2].percent = 0
		e_store_bar.bars[3].percent = ed 
		e_store_bar:Invalidate()
	elseif (ed < 0) then 
	    if (ed < -1) then ed = -1 end 
		e_store_bar.bars[1].percent = eCurr / eStor + ed
		e_store_bar.bars[2].percent = -ed 
		e_store_bar.bars[3].percent = 0 
		e_store_bar:Invalidate()
	end 

	local md = 2 * (mCurr - last_m) / mStor 
	if (md >= 0) then 
		if (md > 1) then md = 1 end 
		m_store_bar.bars[1].percent = mCurr / mStor	 -md
		m_store_bar.bars[2].percent = 0
		m_store_bar.bars[3].percent = md 
		m_store_bar:Invalidate()
	elseif (md < 0) then 
		if (md < -1) then md = -1 end 
		m_store_bar.bars[1].percent = mCurr / mStor + md
		m_store_bar.bars[2].percent = -md 
		m_store_bar.bars[3].percent = 0 
		m_store_bar:Invalidate()
	end 
	
		
	local epd = eInco + eReci - eExpe - eSent
	if epd > 0 then 
		e_bar_plus.bars[1].percent = epd / escale
		e_bar_minus.bars[1].percent = 0
		e_bar_minus.tooltip = nil
		e_bar_plus.tooltip = "You are gaining "..ToSI(epd).."e/s"		
	else 
		e_bar_plus.bars[1].percent = 0
		e_bar_minus.bars[1].percent = (-epd) / escale
		e_bar_plus.tooltip = nil
		e_bar_minus.tooltip = "You are losing "..ToSI(epd).."e/s"		
	end 
	e_bar_plus:Invalidate()
	e_bar_minus:Invalidate()


	local mpd = mInco + mReci - mExpe - mSent
	if mpd > 0 then 
		m_bar_plus.bars[1].percent = mpd / mscale
		m_bar_minus.bars[1].percent = 0
		m_bar_minus.tooltip = nil
		m_bar_plus.tooltip = "You are gaining "..ToSI(mpd).."m/s"		
	else 
		m_bar_plus.bars[1].percent = 0
		m_bar_minus.bars[1].percent = (-mpd) / mscale
		m_bar_plus.tooltip = nil
		m_bar_minus.tooltip = "You are losing "..ToSI(mpd).."m/s"		
	end 
	m_bar_plus:Invalidate()
	m_bar_minus:Invalidate()

	--[[
	if options.breakdown.value then
		
		e_missing.percent = (ePull - eExpe)/escale
		e_bar_out.bars[1].percent = mExpe / escale -- construction is equal to metal
		e_bar_out.bars[2].percent = (eExpe - mExpe - WG.overdriveEnergy) / escale
		e_bar_out.bars[3].percent = WG.overdriveEnergy / escale 
		e_bar_out.bars[4].percent = eSent / escale
		
		m_missing.percent = (mPull - mExpe)/mscale
		local highPrio = math.min(mExpe, WG.highPriorityBP)
		m_bar_out.bars[1].percent = highPrio / mscale
		local normalPrio = math.min(mPull - WG.highPriorityBP  - WG.lowPriorityBP, mExpe - highPrio)
		m_bar_out.bars[2].percent = normalPrio  / mscale 
		m_bar_out.bars[3].percent = math.max(mExpe - highPrio - normalPrio, 0) / mscale
		m_bar_out.bars[4].percent = mSent / mscale
		
		e_bar_in.bars[1].percent = (eInco - WG.windEnergy - eReci) / escale
		e_bar_in.bars[2].percent = WG.windEnergy / escale
		e_bar_in.bars[3].percent = eReci / escale
		
		m_bar_in.bars[1].percent = WG.overdriveMexMetal / mscale
		m_bar_in.bars[2].percent = (mInco + mReci - WG.overdriveMetal - WG.overdriveMexMetal) / mscale
		m_bar_in.bars[3].percent = WG.overdriveMetal / mscale
		m_bar_in.bars[4].percent = mReci / mscale
		
	else
	--]]
		e_bar_out.bars[1].percent = ePull / mscale
		
		m_bar_out.bars[1].percent = mPull / mscale
		
		e_bar_in.bars[1].percent = eInco / escale
		
		m_bar_in.bars[1].percent = (mInco) / mscale
	--end
	e_bar_out:Invalidate()
	m_bar_out:Invalidate()
	e_bar_in:Invalidate()
	m_bar_in:Invalidate()


	e_store_label:SetCaption(ToSI(eCurr))
	e_storecap_label:SetCaption('['..ToSI(eStor)..']')
	e_inc_label:SetCaption("+"..ToSI(eInco + eReci))
	e_pull_label:SetCaption("-"..ToSI(ePull))
	local net = eInco + eReci - ePull
	local equal = (net < 0) and '\255\255\0\0' or '\255\0\255\0'
	e_net_label:SetCaption(equal .. ToSI(net))
	
	m_store_label:SetCaption(ToSI(mCurr))
	m_storecap_label:SetCaption('['..ToSI(mStor)..']')
	m_inc_label:SetCaption("+"..ToSI(mInco + mReci))
	m_pull_label:SetCaption("-"..ToSI(mPull))
	local net = mInco + mReci - mPull
	local equal = (net < 0) and '\255\255\0\0' or '\255\0\255\0'
	m_net_label:SetCaption(equal .. ToSI(net))
	
	
	-- energy warning icons
	if (eInco < mInco and eCurr < 0.7*eStor) or (eCurr < 0.7*eStor and eInco < eExpe)  then 
		e_icon.file = "luaui/images/resbar/atom.png"
		e_icon_label.textColor = col_minus
		e_icon_label:SetCaption("+E!")
	elseif eInco + eCurr > eStor then 
		e_icon.file = "luaui/images/resbar/estore.png"
		e_icon_label.textColor = col_minus
		e_icon_label:SetCaption("store!")
	elseif (WG.energyWasted > 0) then 
		--[[local rat = WG.overdriveEnergy / WG.overdriveMetal
		local cred = rat * 0.06666666
		if cred < 0 then cred = 0 end 
		if cred > 1 then cred = 1 end
		local cgreen = 1 - cred	
		e_icon_label.textColor = {cred, cgreen, 0, 1}
		e_icon_label:SetCaption(string.format("%d:1",rat))
		if rat > 10 then e_icon.file= "luaui/images/resbar/overdrive.png" else 
			e_icon.file = nil
		end ]]--
	else 
		e_icon.file = nil
		e_icon_label:SetCaption("")
	end 
	e_icon:Invalidate()	

	-- metal/bp warning icons
	if mCurr > mStor*0.3 and mInco > mExpe then 
		m_icon.file = "luaui/images/resbar/work.png"
		m_icon_label.textColor = col_minus
		m_icon_label:SetCaption("build!")	
	elseif mPull / (mExpe or 0.1) > 1.5 and  ePull / (eExpe or 0.1) < 1.5 then 
		m_icon.file = "luaui/images/resbar/mex.png"
		m_icon_label.textColor = col_minus
		m_icon_label:SetCaption("+M!")	
	else 
		m_icon.file = nil
		m_icon_label:SetCaption("")
	end 
	m_icon:Invalidate()

	
	last_e =  eCurr
	last_eInco = eInco
	last_ePull = ePull
	last_m =  mCurr
	last_mInco = mInco
	last_mPull = mPull
end


function widget:Initialize()
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Colorbars = Chili.Colorbars
	Checkbox = Chili.Checkbox
	Window = Chili.Window
	ScrollPanel = Chili.ScrollPanel
	StackPanel = Chili.StackPanel
	Grid = Chili.Grid
	screen0 = Chili.Screen0
	
	widgetHandler:RegisterGlobal("MexEnergyEvent", MexEnergyEvent)
	widgetHandler:RegisterGlobal("SendWindProduction", SendWindProduction)
	widgetHandler:RegisterGlobal("PriorityStats", PriorityStats)

	
	local xs,ys = Spring.GetViewGeometry()
	
	if e_window ~= nil then 
		e_window:Dispose()
	end 
	if m_window ~= nil then
		m_window:Dispose()
	end
	

	
	local flowbar_width = 15
	
	local vbar_width = 50
	local vbar_height = 50
	local scale_width = 280
	local scale_height = 10
	local text_width = 40
	local bar_height = 8
	local plusbar_height = 8
	
	
	e_store_label = Label:New {
		x=2,
		bottom='40%',
		width = vbar_width-10,
		height = 10,
		
		textColor = {1,0.7,0,1},
		caption = "0",
		valign="bottom",
		align="center",
		fontOutline = true,
		autosize = false,
		fontsize = 15,
	}
	m_store_label = Label:New {
		x=2,
		bottom='40%',
		width = vbar_width-10,
		height = 10,
		
		textColor = {0,0.7,1,1},
		caption = "0",
		valign="center",
		align="center",
		fontOutline = true,
		fontsize = 14,
		autosize = false,
	}
	e_storecap_label = Label:New {
		top=0,
		right=2,
		width = vbar_width-10,
		height = 8,
		
		textColor = {1,0.7,0,1},
		caption = "0",
		valign="top",
		align="right",
		fontOutline = true,
		autosize = false,
		fontsize = 12,
	}
	m_storecap_label = Label:New {
		top=0,
		right=2,
		width = vbar_width-10,
		height = 8,
		
		textColor = {0,0.7,1,1},
		caption = "0",
		valign="top",
		align="right",
		fontOutline = true,
		fontsize = 12,
		autosize = false,
	}
	
	
	
	e_store_bar = Chili.Multiprogressbar:New {
				x =vbar_width,
				y= 0,
				width = vbar_width,
				height = vbar_height,
				drawBorder =true,
				borderColor = {1,0.7,0,1},
				orientation = "vertical",
				reverse = true,
				tooltip = "This shows your current energy reserves.\n Anything above 80% will be burned by 'mex overdrive'\n which increases production of your mines",
				
				bars = {
					{ -- energy level
						color1 = col_energy,
						color2 = col_energy_shad,
						percent = 0,
					},
					{  -- drain
						color1 = col_minus,
						color2 = col_minus_shad,
						percent = 0,
					},
					{ -- income
						color1 = col_plus,
						color2 = col_plus_shad,
						percent = 0,
					},
					
				},
				--]]
				children = {
					
					e_store_label,
					e_storecap_label,
				}
			}
	m_store_bar = Chili.Multiprogressbar:New {
				x =vbar_width,
				y= 0,
				width = vbar_width,
				height = vbar_height,
				drawBorder =true,
				borderColor= {0,0.7,1,1},
				orientation = "vertical",
				reverse = true,
				tooltip = "This shows your current metal reserves",
				bars = {
					{ -- energy level
						color1 = col_metal,
						color2 = col_metal_shad,
						percent = 0,
					},
					{  -- drain
						color1 = col_minus,
						color2 = col_minus_shad,
						percent = 0,
					},
					{ -- income
						color1 = col_plus,
						color2 = col_plus_shad,
						percent = 0,
					},
					
				},
				children = {
					m_store_label,
					m_storecap_label,
				}
			}
	
	
	e_inc_label = Label:New {
		textColor = col_plus,
		caption = "+0",
		--autosize = false,
		right=1,
		y= 1,
		align = "right",
		valign ="top",
		fontOutline = true,
		width = text_width,
		height =vbar_height-2,
		fontsize = 14,
		
	}
	e_pull_label = Label:New {
		textColor = col_minus,
		align = "right",
		--autosize = false,
		caption = "0",
		valign = "bottom",
		right=1,
		y= 1,
		width = text_width,
		height = vbar_height-2,
		fontOutline = true,
		
		fontsize = 14,
	}
	e_net_label = Label:New {
		textColor = col_net,
		padding = {2,2,2,2},
		align = "left",
		--autosize = false,
		caption = "0",
		valign = "bottom",
		x= 0,
		y= 0,
		width = text_width,
		height = vbar_height-2,
		fontOutline = true,
		fontSize = 16,
		
	}

	m_inc_label = Label:New {
		textColor = col_plus,
		caption = "+0",
		autosize = false,
		right=1,
		y= 1,
		align = "right",
		valign ="top",
		fontOutline = true,
		width = text_width,
		height =vbar_height-2,
		fontsize = 14,
	}
	m_pull_label = Label:New {
		textColor = col_minus,
		align = "right",
		--autosize = false,
		caption = "0",
		valign = "bottom",
		right=1,
		y= 1,
		width = text_width,
		height = vbar_height-2,
		fontOutline = true,
		fontsize = 14,
	}
	m_net_label = Label:New {
		textColor = col_net,
		padding = {2,2,2,2},
		align = "left",
		--autosize = false,
		caption = "0",
		valign = "bottom",
		x= 0,
		y= 0,
		width = text_width,
		height = vbar_height-2,
		fontOutline = true,
		fontSize = 16,
		
	}

	
	e_scale = Chili.Scale:New {
		x = vbar_width + text_width,
		y = 0,
		width = scale_width,
		height = scale_height,
		fontsize = 8,
		scaleFunction	= scaleFunction,
		min = -1000,
		max = 1000,
		step = 10,
	}
	m_scale = Chili.Scale:New {
		x = vbar_width + text_width,
		y = 0,
		width = scale_width,
		height = scale_height,
		scaleFunction	= scaleFunction,
		fontsize = 8,
		min = -1000,
		max = 1000,
		step = 10,
	}

	
	e_missing =  {
		color1 = {236/255,0,6/255,1},
		color2 = colShade({236/255,0,6/255,1}),
		texture = "luaui/images/resbar/pull.png",
		s = 1,
		t = 1,
		tileSize = 12,
		percent = 0.1,
	}
	m_missing =  {
		color1 = {236/255,0,6/255,1},
		color2 = colShade({236/255,0,6/255,1}),
		texture = "luaui/images/resbar/pull.png",
		s = 1,
		t = 1,
		tileSize = 12,
		percent = 0.1,
	}
	
	m_bar_in_bars = {
		{ -- all metal
			color1 = {0,1,0,1},
			color2 = {0,1,0,0.1},
			percent = 0.1,
		},
	}
	--[[
	m_bar_in_bars_br = {
		{ -- mexes
			color1 = col_metal,
			color2 = col_metal_shad,
			percent = 0.1,
			texture = "luaui/images/resbar/mex.png",
			s = 1, -- tex coords
			t = 1,
			tileSize = 12, 
		},
		{ -- other 
			color1 = col_reclaim,
			color2 = colShade(col_reclaim),
			percent = 0.1,
			texture = "luaui/images/resbar/reclaim.png",
			s = 1, -- tex coords
			t = 1,
			tileSize = 16, 
		},	
		{ -- overdrive 
			color1 = col_overdrive_m,
			color2 = colShade(col_overdrive_m),
			percent = 0.1,
			texture = "luaui/images/resbar/overdrive.png",
			s = 1, -- tex coords
			t = 1,
			tileSize = 12, 
		},

		{ -- share
			color1 = col_share,
			color2 = colShade(col_share),
			percent = 0.1,
			texture = "luaui/images/resbar/share.png",
			s = 1, -- tex coords
			t = 1,
			tileSize = 12, 
		},
	}
	--]]
	e_bar_in_bars = {
		{ -- all electricity
			color1 = {0,1,0,1},
			color2 = {0,1,0,0.1},
			percent = 0.1,
		},
	}
	--[[
	e_bar_in_bars_br = {
		{ -- baseline electricity
			color1 = {1,1,0,1},
			color2 = {0.7,0.7,0,1},
			percent = 0.1,
			texture = "luaui/images/resbar/atom.png",
			s = 1, -- tex coords
			t = 1,
			tileSize = 12, 
		},
		{ -- wind
			color1 = {210/255,200/255,150/255,1},
			color2 = colShade({210/255,200/255,150/255,1}),
			percent = 0.1,
			texture = "luaui/images/resbar/wind.png",
			s = 1, -- tex coords
			t = 1,
			tileSize = 16, 
		},
		{ -- share
			color1 = col_share,
			color2 = colShade(col_share),
			percent = 0.1,
			texture = "luaui/images/resbar/share.png",
			s = 1, -- tex coords
			t = 1,
			tileSize = 12, 
		},
	}
	--]]
	e_bar_in = 	Chili.Multiprogressbar:New {
					orientation = 'vertical',
					reverse = true,
					--drawBorder = true,
					borderColor = {0,1,0,1},
					scaleFunction	= scaleFunction,
					tooltip = "This is your energy income.\n You gain energy from powerplants",
					bars = e_bar_in_bars,
			}
	m_bar_in = 	Chili.Multiprogressbar:New {
					orientation = 'vertical',
					reverse = true,
					--drawBorder = true,
					borderColor = {0,1,0,1},
					scaleFunction	= scaleFunction,
					tooltip = "This is your metal income. \nYou gain metal from metal extractors (and overdrive - boosted mex output using excess energy), commander and reclaiming.",
					bars = m_bar_in_bars,
			}

	e_bar_out_bars = {
		{ -- all energy
			color1 = {1,0,0,1},
			color2 = {1,0,0,0.1},
			percent = 0.1,
		},		
	}
	--[[
	e_bar_out_bars_br = {
		{ -- construction
			color1 = col_construction,
			color2 = colShade(col_construction),
			percent = 0.1,
			texture = "luaui/images/resbar/work.png",
			s = 1, -- tex coords
			t = 1,
			tileSize = 12, 
		},
		{ -- other 
			color1 = {136/255, 0, 21/255,1},
			color2 = colShade({136/255, 0, 21/255,1}),
			percent = 0.1,
			texture = "luaui/images/resbar/jammer.png",
			s = 1, -- tex coords
			t = 1,
			tileSize = 12, 
		},
		{ -- overdrive
			color1 = col_overdrive,
			color2 = colShade(col_overdrive),
			percent = 0.1,
			texture = "luaui/images/resbar/overdrive.png",
			s = 1, -- tex coords
			t = 1,
			tileSize = 12, 
		},
		{ -- share
			color1 = col_share,
			color2 = colShade(col_share),
			percent = 0.1,
			texture = "luaui/images/resbar/share.png",
			s = 1, -- tex coords
			t = 1,
			tileSize = 12, 
		},
		e_missing,
	}
	--]]
	m_bar_out_bars = {
		{ -- all metal
			color1 = {1,0,0,1},
			color2 = {1,0,0,0.1},
			percent = 0.1,
		},
	}
	--[[
	m_bar_out_bars_br = {
		{ -- high prio
			color1 = colShade(col_construction,1.2),
			color2 = colShade(colShade(col_construction),1.2),
			percent = 0.1,
			texture = "luaui/images/resbar/work_high.png",
			s = 1, -- tex coords
			t = 1,
			tileSize = 12, 
		},
		{ -- normal
			color1 = col_construction,
			color2 = colShade(col_construction),
			percent = 0.1,
			texture = "luaui/images/resbar/work.png",
			s = 1, -- tex coords
			t = 1,
			tileSize = 12, 
		},
		{ -- low prio
			color1 = colShade(col_construction, 0.5),
			color2 = colShade(col_construction, 0.35),
			percent = 0.1,
			texture = "luaui/images/resbar/work_low.png",
			s = 1, -- tex coords
			t = 1,
			tileSize = 12, 
		},
		{ -- share
			color1 = col_share,
			color2 = colShade(col_share),
			percent = 0.1,
			texture = "luaui/images/resbar/share.png",
			s = 1, -- tex coords
			t = 1,
			tileSize = 12, 
		},
		m_missing,
	}
	--]]
	e_bar_out = Chili.Multiprogressbar:New {
					orientation = 'vertical',
					--drawBorder = true,
					borderColor = {1,0,0,1},
					scaleFunction	= scaleFunction,
					tooltip = "This is your metal spending.\n Split into construction projects, other uses\n and mex overdrive - energy burned to improve metal production.",
					bars = e_bar_out_bars,
			}
	m_bar_out = Chili.Multiprogressbar:New {
					orientation = 'vertical',
					--drawBorder = true,
					borderColor = {1,0,0,1},
					scaleFunction	= scaleFunction,
					tooltip = "This is your metal spending - split\n into construction projects of various priorities.\n To change priority select project or worker and click 'normal' button",
					bars = m_bar_out_bars,
								
			}
	

	e_bar_plus =	Chili.Multiprogressbar:New {
					reverse = false,
					scaleFunction	= scaleFunction,
					bars = {
						{
							color1 = col_plus,
							color2 = col_plus_shad,
							percent = 0.1,
						},
					},
			}
	m_bar_plus =	Chili.Multiprogressbar:New {
					scaleFunction	= scaleFunction,
					reverse = false,
					bars = {
						{
							color1 = col_plus,
							color2 = col_plus_shad,
							percent = 0.1,
						},
					},
			}
			
			
			
	e_bar_minus =	Chili.Multiprogressbar:New {
					scaleFunction	= scaleFunction,
					reverse = true,
					bars = {
						{
							color1 = col_minus,
							color2 = col_minus_shad,
							percent = 0.1,
						},
					},
			}
	m_bar_minus =	Chili.Multiprogressbar:New {
					scaleFunction	= scaleFunction,
					reverse = true,
					bars = {
						{
							color1 = col_minus,
							color2 = col_minus_shad,
							percent = 0.1,
						},
					},
			}
		
		
	e_icon_label = Chili.Label:New {
		width = 40,
		height = 40,
		caption = "",
		align = "center",
		valign ="center",
		textColor = {0,0,0,1},
		fontOutline = true,
		fontsize = 12,
	}
	e_icon = Chili.Image:New {
		x = vbar_width +text_width + scale_width,
		width = 40,
		height = 40,
		file = nil,
		children = {e_icon_label},
	}
	m_icon_label = Chili.Label:New {
		width = 40,
		height = 40,
		autosize = false,
		caption = "",
		align = "center",
		valign ="center",
		textColor = {0,0,0,1},
		fontOutline = true,
		fontsize = 12,
	}
	m_icon = Chili.Image:New {
		x = vbar_width +text_width + scale_width,
		width = 40,
		height = 40,
		file =  nil,
		children = {m_icon_label},
	}

	
	
	e_window = Window:New {
		dockable = true,
		name="resbar_e",
		--skinName = 'default',
		x = settings.e.pos_x,
		y = settings.e.pos_y,
		clientWidth = vbar_width * 2 + flowbar_width + text_width + 5,
		clientHeight = vbar_height+5,
		parent = screen0,
		draggable = true,
		resizable = false,
		--dragUseGrip = true,
		children = {
			
			Chili.Image:New {
				x= 0,
				y= 0,
				width = 30,
				height = 30,
				file = 'LuaUI/images/energy.png', --"luaui/images/resbar/huge_e.png",
			},
			e_net_label,
			
			e_store_bar,
			
			--e_scale,
			
			Chili.StackPanel:New {
					x = vbar_width * 2,
					y = 0,
					width = flowbar_width,
					height = vbar_height,
					orientation = "vertical",
					itemMargin = {0, 0, 0, 0},
					padding = {0, 0, 0, 0},
					children = {
						e_bar_in,
						e_bar_out,
					},
			},
			e_inc_label,
			
			e_pull_label,
			--[[
			Chili.StackPanel:New {
					x = vbar_width + text_width ,
					y = e_scale.height+1 + bar_height,
					width = e_scale.width,
					height = plusbar_height,
					orientation = "horizontal",
					itemMargin = {0, 0, 0, 0},
					padding = {0, 0, 0, 0},
					children = {
						e_bar_minus,
						e_bar_plus,
					},
			},
			e_icon,
			--]]
		}
	}
	m_window = Window:New {
		dockable = true,
		name="resbar_m",

		--skinName = 'default',
		x = settings.m.pos_x,
		y = settings.m.pos_y,
		clientWidth = vbar_width * 2 + flowbar_width + text_width + 5,
		clientHeight = vbar_height+5,
		parent = screen0,
		draggable = true,
		resizable = false,
		--dragUseGrip = true,
		children = {
			Chili.Image:New {
				x= 0,
				y= 0,
				width = 30,
				height = 30,
				file = 'LuaUI/images/ibeam.png', --"luaui/images/resbar/huge_m.png",
			},
			m_net_label,

			m_store_bar,
			
			--m_scale,
			
			Chili.StackPanel:New {
					x = vbar_width * 2,
					y = 0,
					width = flowbar_width,
					height = vbar_height,
					orientation = "vertical",
					itemMargin = {0, 0, 0, 0},
					padding = {0, 0, 0, 0},
					children = {
						m_bar_in,
						m_bar_out,
					},
			},
			
			m_inc_label,
			
			m_pull_label,
			--[[
			Chili.StackPanel:New {
					x = vbar_width + text_width ,
					y = scale_height+1 + bar_height,
					width = scale_width,
					height = plusbar_height,
					orientation = "horizontal",
					itemMargin = {0, 0, 0, 0},
					padding = {0, 0, 0, 0},
					children = {
						m_bar_minus,
						m_bar_plus,
					},
			},
			m_icon,
			--]]
		}
	}
	
	--e_window:Resize(settings.e.c_width, settings.e.c_height)
	--m_window:Resize(settings.m.c_width, settings.m.c_height)

	spSendCommands({"resbar 0"})

end

function MexEnergyEvent(teamID, energyWasted, energyForOverdrive, totalIncome, metalFromOverdrive)
  if (Spring.GetLocalTeamID() == teamID) then 
  	WG.energyWasted = energyWasted
	WG.energyForOverdrive = energyForOverdrive
  end
end


function SendWindProduction(teamID, value)
	WG.windEnergy = value
end

function PriorityStats(teamID, highPriorityBP, lowPriorityBP)
	WG.highPriorityBP = highPriorityBP
	WG.lowPriorityBP = lowPriorityBP
end
