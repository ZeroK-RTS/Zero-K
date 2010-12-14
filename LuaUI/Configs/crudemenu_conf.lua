local confdata = {}
confdata.title = 'C.A.'
local color = {
	white = {1,1,1,1},
	yellow = {1,1,0,1},
	gray = {0.5,.5,.5,1},
	darkgray = {0.3,.3,.3,1},
	cyan = {0,1,1,1},
	red = {1,0,0,1},
	darkred = {0.5,0,0,1},
	blue = {0,0,1,1},
	black = {0,0,0,1},
	darkgreen = {0,0.5,0,1},
	green = {0,1,0,1},
	postit = {1,0.9,0.5,1},
	
	grayred = {0.5,0.4,0.4,1},
	grayblue = {0.4,0.4,0.45,1},
	transblack = {0,0,0,0.3},
	transblack2 = {0,0,0,0.7},
	transGray = {0.1,0.1,0.1,0.8},
}
color.tooltip_bg = color.transGray
color.tooltip_fg = color.white
color.tooltip_info = color.cyan
color.tooltip_help = color.green

color.main_bg = color.transblack
color.main_fg = color.white

color.menu_bg = color.grayblue
color.menu_fg = color.white

color.game_bg = color.gray
color.game_fg = color.white

color.sub_bg	= color.transblack
color.sub_fg 	= color.white
color.sub_header = color.yellow

color.sub_button_bg = color.gray
color.sub_button_fg = color.white

color.sub_back_bg = color.grayblue
color.sub_back_fg = color.white

color.sub_close_bg = color.grayblue
color.sub_close_fg = color.white

color.stats_bg = color.sub_bg
color.stats_fg = color.sub_fg
color.stats_header = color.sub_header

color.context_bg = color.transblack
color.context_fg = color.white
color.context_header = color.yellow

confdata.color = color

local spSendCommands = Spring.SendCommands

confdata.game_menu_tree = {
	{'Pause/Unpause', 'pause' },
	{},
	{'Share Dialog...', 'sharedialog' },	
	{'Factory Guard', function() spSendCommands{"luaui togglewidget FactoryGuard"} end },

	{},
	{'Screenshots|Take screenshots.',
		{
			{'Save Screenshot (PNG)|Find your screenshots under Spring/screenshots', 'screenshot' },	
			{'Save Screenshot (JPG)|Find your screenshots under Spring/screenshots', 'screenshot jpg' },	
		}
	},
	

}

confdata.help_tree = {
	{
		'Tips',
		'=Hold your meta-key (spacebar by default) while clicking on a unit or corpse for more info and options. '..
		'You can also space-click on menu elements to see context settings. '..
		'There is much more to come. Please enjoy using Crude Menu!'
	},			
	{'Tutorial', function() spSendCommands{"luaui togglewidget Nubtron"} end },
}

--[[

	--]]

confdata.menu_tree = {	
	{'Reset Settings|Reset certain settings', 
		{
			{'Reset graphic settings to minimum.'},
			{
				'Reset graphic settings|Use this if your performance is poor', 
				function()
					spSendCommands{"water 0",
						"Shadows 0",
						"maxparticles 100",
						"advshading 0",
						"grounddecals 0",
						"water 0",
						'luaui disablewidget LupsManager',
						"luaui disablewidget Display DPS",
						"luaui disablewidget SelectionHalo",
						"luaui disablewidget SelectionCircle",
						"luaui disablewidget UnitShapes",
					}
				end 
			},
			{'Reset custom settings to default.'},
			{'Reset custom settings', function() WG.crude.ResetSettings() end },
			{'Reset hotkeys.'},
			{'Reset hotkeys', function() WG.crude.ResetKeys() end },
		}
	},
	{'lh',
		{
			name = 'Show Advanced Settings',
			type = 'bool',
			value = false,
		}
	},
	{},
	{'Effects|Graphical effects.',
		{
			{'Night', 
				{	
					{'Toggles'},
					{'Night View', function() spSendCommands{'luaui togglewidget Night'} end },
					{},
					{'Night Colored Units', function() spSendCommands{'luaui night_preunit'} end },
					{'Beam', function() spSendCommands{'luaui night_beam'} end },
					{'Cycle', function() spSendCommands{'luaui night_cycle'} end },
					{'Searchlight Base Types'},
					{'None', function() spSendCommands{'luaui night_basetype 0'} end },
					{'Simple', function() spSendCommands{'luaui night_basetype 1'} end },
					{'Full', function() spSendCommands{'luaui night_basetype 2'} end },	
				}
			},
			{'Toggle Camera Shake', function() spSendCommands{'luaui togglewidget CameraShake'} end },
		}
	},
	{'Interface|Settings relating to the GUI', 
		{
			--[[
			{'Command Menu',
				{
					{'lh',
						{
							name = 'Black & White Buildpics',
							type = 'bool',
							value = (not WG.Layout.colorized),
							OnChange = function(self) WG.Layout.colorized = (not self.value); Spring.ForceLayoutUpdate() end,
						}
					},
					{'lh',
						{
							name = 'Hide Common Commands',
							type = 'bool',
							value = WG.Layout.minimal,
							OnChange = function(self) WG.Layout.minimal = self.value; Spring.ForceLayoutUpdate() end, --needed as setconfigint doesn't apply change right away
							advanced = true,
						}
					},
					{'lh',
						{
							name = 'Hide Units',
							type = 'bool',
							value = WG.Layout.hideUnits,
							OnChange = function(self) WG.Layout.hideUnits = self.value; Spring.ForceLayoutUpdate() end,
							advanced = true,
						}
					},
					
				}
			},
			--]]
			
			--{'Set An Avatar...|Requires Avatar widget, used in widgets such as Chili Chat Bubbles', function() spSendCommands{"luaui enablewidget Avatars", "setavatar"} end },
			
		}
	},
	{'Misc|Less common advanced settings', 
		{
			
			{'@Widget List...', function() WG.crude.ShowWidgetList2() end },
			{'@Local Widget Config', function() spSendCommands{"luaui localwidgetsconfig"} end},
			{'LuaUI TweakMode (Esc to exit)|LuaUI TweakMode. Move and resize parts of the user interface. (Hit Esc to exit)', 'luaui tweakgui' },
			--[[
			{'Reset all widget settings', function() 
				include("savetable.lua")
				local ORDER_FILENAME     = LUAUI_DIRNAME .. 'Config/CA_order.lua'        
				local CONFIG_FILENAME    = LUAUI_DIRNAME .. 'Config/CA_data.lua'  
				Spring.Echo ('test', ORDER_FILENAME)
				table.save({}, ORDER_FILENAME)    
				table.save({}, CONFIG_FILENAME)
				end,
			},
			--]]
		}
	},
	{'Mouse Settings|Change your cursor and other mouse settings',
		{
			{'lh',
				{
					name = 'Cursor Sets',
					type = 'list',
					OnChange = function (self) 
						if self.value == 'ca' then
							WG.crude.RestoreCursor()
						else
							WG.crude.SetCursor( self.value ); 
						end
					end,
					items = {
						{ key = 'ca', name = 'Complete Annihilation', },
						{ key = 'ca_static', name = 'CA Static', },
						{ key = 'bold', name = 'Bold', },
						{ key = 'bold_static', name = 'Bold Static', },
						{ key = 'erom', name = 'Erom', },
						{ key = 'masse', name = 'Masse', },
						{ key = 'Lathan', name = 'Lathan', },
						{ key = 'k_haos_girl', name = 'K_haos_girl', },
					},
				}
			},
			{},
			{'Toggle Grab Input|Mouse cursor won\'t be able to leave the window.', function() spSendCommands{"grabinput"} end },
		},
	},
	{'Video|These settings strongly affect the balance of quality of graphics vs. the speed of the gameplay', 
		{
			{'Lups (Lua Particle System)'},
			{'Toggle Lups', function() spSendCommands{'luaui togglewidget LupsManager'} end },	

			{'Various'},
			
			{'lh' , 
				{ 	
					name = 'Shiny Units',
					type = 'bool',
					springsetting = 'AdvUnitShading',
					OnChange=function(self) spSendCommands{"advshading " .. (self.value and 1 or 0) } end, --needed as setconfigint doesn't apply change right away
				} 
			},
			{'lh' , 
				{ 	
					name = 'Ground Decals',
					type = 'bool',
					springsetting = 'GroundDecals',
					OnChange=function(self) spSendCommands{"grounddecals " .. (self.value and 1 or 0) } end, 
				} 
			},
			
			{'lh' , 
				{ 	
					name = 'Maximum Particles (100 - 20,000)',
					type = 'number',
					valuelist = {100,500,1000,2000,5000,10000,20000},
					springsetting = 'MaxParticles',
					OnChange=function(self) Spring.SendCommands{"maxparticles " .. self.value } end, 
				} 
			},
			{'View Radius'},
			{'Increase Radius', "increaseViewRadius" },	
			{'Decrease Radius', "decreaseViewRadius" },
			
			{'Trees'},
			{'Toggle View', 'drawtrees' },	
			{'See More Trees', 'moretrees' },	
			{'See Less Trees', 'lesstrees' },	
			--{'Toggle Dynamic Sky', function(self) spSendCommands{'dynamicsky'} end },	
			
			{'Water Settings'},
			{'Basic', function() spSendCommands{"water 0"} end },
			{'Reflective', function() spSendCommands{"water 1"} end },
			{'Reflective and Refractive', function() spSendCommands{"water 2"} end },
			{'Dynamic', function() spSendCommands{"water 3"} end },
			{'Bumpmapped', function() spSendCommands{"water 4"} end },
			
			{'Shadow Settings'},
			{'Disable Shadows', function() spSendCommands{"Shadows 0"} end },
			{'Toggle Terrain Shadows', function() local curShadow=Spring.GetConfigInt("Shadows"); if (curShadow<2) then curShadow=2 else curShadow=1 end; spSendCommands{"Shadows "..curShadow} end },
			{'Low Detail Shadows', function() local curShadow=Spring.GetConfigInt("Shadows"); curShadow=math.max(1,curShadow); spSendCommands{"Shadows " .. curShadow .. " 1024"} end },
			{'Medium Detail Shadows', function() local curShadow=Spring.GetConfigInt("Shadows"); curShadow=math.max(1,curShadow); spSendCommands{"Shadows " .. curShadow .. " 2048"} end },
			{'High Detail Shadows', function() local curShadow=Spring.GetConfigInt("Shadows"); curShadow=math.max(1,curShadow); spSendCommands{"Shadows " .. curShadow .. " 4096"} end },
			--{'Extreme Detail Shadows', function() spSendCommands{"Shadows 1 8192"} end },
		}
	},
	{'View|Settings such as camera modes.',
		{
			
			
			{'Spectator View/Selection'},
			{'View Chosen Player', function() spSendCommands{"specfullview 0"} end },
			{'View All', function() spSendCommands{"specfullview 1"} end },
			{'Select Any Unit', function() spSendCommands{"specfullview 2"} end },
			{'View All & Select Any', function() spSendCommands{"specfullview 3"} end },
			
			{'Camera Type'},
			{'Total Annihilation', function() spSendCommands{"viewta"} end },
			{'FPS', function() spSendCommands{"viewfps"} end },
			{'Free', function() spSendCommands{"viewfree"} end },
			{'Rotatable Overhead', function() spSendCommands{"viewrot"} end },
			{'Total War', function() spSendCommands{"viewtw"} end },
			{'Flip the TA Camera', function() spSendCommands{"viewtaflip"} end },
			
			{'Other settings'},
			{'lh', 
				{ 
					name = 'Brightness',
					type = 'number',
					min = 0, 
					max = 1, 
					step = 0.01,
					value = 1,
					OnChange = function(self) Spring.SendCommands{"luaui enablewidget Darkening", "luaui darkening " .. 1-self.value} end, 
				} 
			},
			{'lh', 
				{
					name = 'Icon Distance',
					type = 'number',
					min = 1, 
					max = 1000,
					springsetting = 'UnitIconDist',
					OnChange = function(self) Spring.SendCommands{"disticon " .. self.value} end 
				} 
			},
			
			
			
			{},
			--{'Toggle Healthbars', function() spSendCommands{'showhealthbars'} end },	
			{'Toggle DPS Display|Shows RPG-style damage', function() spSendCommands{"luaui togglewidget Display DPS"} end },
			
			--{'Hide Interface', function(self) spSendCommands{'hideinterface'} end },	
			--{'showshadowmap', function(self) spSendCommands{'showshadowmap'} end },	
		}
	},

}

return confdata

