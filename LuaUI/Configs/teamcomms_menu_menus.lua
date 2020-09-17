local menu_base = {
	items = {{
		-- Really important ones up top
		angle = 0,
		marker = "Attack now!",
		label = "Attacks",
		icon = "LuaUI/Images/commands/Bold/attack.png",
		items = {{
			angle = 45,
			marker =
			"Sending tactical missiles here.\n"..
			"Get ready to attack quickly!",
			icon = "LuaUI/Images/commands/Bold/missile.png"
		},{
			angle = 315,
			marker =
			"Sending a thunderbird strike here.\n"..
			"Get ready to attack quickly!",
			icon = "LuaUI/Images/defense_ranges/air.png"
		},{
			angle = 90,
			marker =
			"I'm about to attack here. Join me!",
			icon = "LuaUI/Images/commands/Bold/attack.png"
		},{
			angle = 270,
			marker =
			"I'm coming to join your attack.",
			icon = "LuaUI/Images/commands/Bold/attack.png"
		},{
			angle = 225,
			marker =
			"I'll try to flank or cut them off from this side.",
			icon = "LuaUI/Images/commands/Bold/attack.png"
		},{
			angle= 135,
			marker = "Raid here, please.",
			icon = "LuaUI/Images/commands/Bold/settarget.png",
		}}
	},{
		angle = 45,
		marker = "Get back!",
		icon = "LuaUI/Images/commands/Bold/jump.png",
		items = {{
			angle = 0,
			marker = "Stop!",
			icon = "LuaUI/Images/commands/Bold/stop.png",
		},{
			angle = 270,
			marker = "Please don't do this.",
			icon = "LuaUI/Images/commands/Bold/stop.png",
		},{
			angle = 315,
			marker = "...I immediately regret my decision.",
			icon = "LuaRules/Images/awards/trophy_friend.png",
		},{
			angle = 90,
			marker = "Wait!",
			icon = "LuaUI/Images/commands/Bold/wait_time.png",
		},{
			angle = 135,
			marker = "Run!",
			icon = "LuaUI/Images/commands/Bold/sprint.png",
		}}
	},{
		angle = 315,
		label = "Scouting",
		icon = "LuaUI/Images/defense_ranges/radar.png",
		marker = "Scout this area, please.",
		items = {{
			angle = 225,
			marker = "Can we get a cloaked unit to scout here, please?",
			icon = "LuaUI/Images/commands/states/cloak_on.png"
		},{
			angle = 270,
			marker = "Can we check to see if this is undefended?",
			icon = "LuaUI/Images/commands/Bold/attack.png"
		},{
			angle = 180,
			marker = "Can we get some radar coverage up here, please?",
			icon = "unitpics/module_fieldradar.png",
		},{
			angle = 0,
			marker = "Air, can we a get a swift sprint scout, please?",
			icon = "LuaUI/Images/commands/Bold/sprint.png"
		},{
			angle = 45,
			marker = "Air, can we get an owl to oversee the battlefield here, please?",
			icon = "LuaUI/Images/commands/Bold/patrol.png"
		}}
	},{
		-- To the sides; right
		angle = 90,
		label = "Territory acquisition",
		icon = "LuaUI/Images/commands/Bold/fight.png",
		marker = "Push out here, please.",
		items = {{
			angle = 45,
			marker = "Capture the mexes here, please.",
			icon = "LuaUI/Images/commands/Bold/mex.png",
		},{
			angle = 135,
			icon = "LuaUI/Images/commands/Bold/build_light.png",
			marker = "Expand here, please."
		}}
	},{
		angle = 135,
		label = "Battlefield",
		icon = "LuaUI/Images/commands/Bold/reclaim.png",
		marker = "Contest the reclaim!",
		items = {{
			angle = 90,
			icon = "icons/kbotraider.dds",
			tint = { r = 0, g = 1, b = 0 },
			marker = "Make raiders to run through undefended routes."
		},{
			angle = 180,
			tint = { r = 1, g = 0, b = 0 },
			icon = "icons/staticassaultriot.png",
			marker =
			"This area is too heavily fortified to be worth breaking right now.\n"..
			"It would be better to go around or attack other areas instead."
		}}
	},{
		-- To the sides; left
		angle = 270,
		label = "Defence",
		marker = "Defend here now!",
		icon = "LuaUI/Images/commands/Bold/guard.png",
		items = {{
			angle = 360,
			marker = "Intercept these raiders!",
			icon = "icons/kbotraider.dds",
			tint = { r = 0, g = 1, b = 0 },
		},{
			angle = 315,
			marker = "Air, we need fighters to chase this down!",
			icon = "LuaUI/Images/commands/Bold/sprint.png",
		},{
			angle = 225,
			marker = "Air, we need bombers to take this out!",
			icon = "LuaUI/Images/commands/Bold/bomb.png",
		},{
			-- I really hope I don't regret adding this
			angle = 180,
			marker = "Fortify here, please.",
			icon = "LuaUI/Images/defense_ranges/defense_colors.png",
		}}
	},{
		angle = 225,
		label = "Economic",
		marker = "Link our economic buildings together, please.",
		icon = "LuaUI/Images/resbar/icone.png",
		items = {{
			angle = 270,
			marker = "Make energy producing buildings, please.",
			icon = "LuaUI/Images/resbar/huge_e.png"
		},{
			angle = 180,
			icon = "unitpics/energypylon.png",
			marker = "Can we extend our grid here, please?"
		}}
	},{
		-- To the rear
		angle = 180,
		marker = "Welcome to Zero-K!",
		icon = "LuaUI/Images/friendly.png",
		items = {{
			angle = 315,
			tint = { r = 0, g = 1, b = 0 },
			icon = "icons/kbotraider.dds",
			marker = "You'll need to make units.",
		},{
			angle = 225,
			icon = "LuaUI/Images/commands/Bold/move.png",
			marker = "Use these units, please.",
		},{
			angle = 45,
			icon = "unitpics/turretheavylaser.png",
			marker =
			"Please do not make heavy defensive structures in the back.\n"..
			"If they manage to reach this far, we've already lost.\n"..
			"Metal is more effectively spent making units.\n"..
			"If you are excessing, you should be creating/using more buildpower.",
		},{
			angle = 270,
			icon = "unitpics/staticcon.png",
			marker =
			"Try to keep your buildpower roughly in line with your income.\n"..
			"A good rule of thumb is to make your first caretaker next to your\n"..
			"factory once you reach +15 metal income, as your mobile builders\n"..
			"should be active early.\n"..
			"Later on, have enough caretakers with your factories to handle\n"..
			"your income, plus any reclaim peaks.",
		},{
			angle = 135,
			icon = "unitpics/staticstorage.png",
			marker =
			"Storage is almost always useless.\n"..
			"Please do not build storage unless you have lost\n"..
			"your commander, in which case you should make\n"..
			"one, and only one."
		}}
	}}
}

local menu_use = {
	default = menu_base
}
return menu_use
