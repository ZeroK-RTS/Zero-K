--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Takeover Vote Display",
    desc      = "GUI for takeover votes",
    author    = "Tom Fyuri",
    date      = "Jul 2013",
    license   = "GPL v2 or later",
    layer     = -9, 
    enabled   = true  --  loaded by default?
  }
end

local version = "0.0.1 beta" -- i'm so noob in this :p

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local Button
local Label
local Window
local Panel
local StackPanel
local ScrollPanel
local TextBox
local Image
local Progressbar
local Control
local Font

local vote_window, panel_main, panel_for_stack, vote_title, stack_panel, scroll_panel, choose_unit, choose_delay, vote_button, minimize_button, panel_for_vote, delay_stack_panel, unit_stack_panel
local most_voted_panel, icon1, text1, textd, text2
local stats_window,  stats_timer, show_vote_window_button, winner_icon, unit_team
local vote_minimized = false -- im really noob in this
  
local unit_choice = {
      ['scorpion'] = {
	id = 1;
	name = "scorpion";
	type = "scorpion";
	full_name = "Scorpion";
	pic = "unitpics/scorpion.png";
	water_friendly = false;
      },
      ['dante'] = {
	id = 2;
	name = "dante";
	type = "dante";
	full_name = "Dante";
	pic = "unitpics/dante.png";
	water_friendly = false;
      },
      ['catapult'] = {
	id = 3;
	name = "catapult";
	type = "armraven";
	full_name = "Catapult";
	pic = "unitpics/armraven.png";
	water_friendly = false;
      },
      ['bantha'] = {
	id = 4;
	name = "bantha";
	type = "armbanth";
	full_name = "Bantha";
	pic = "unitpics/armbanth.png";
	water_friendly = false;
      },
      ['krow'] = {
	id = 5;
	name = "krow";
	type = "corcrw";
	full_name = "Krow";
	pic = "unitpics/corcrw.png";
	water_friendly = false;
      },
      ['detriment'] = {
	id = 6;
	name = "detriment";
	type = "armorco";
	full_name = "Detriment";
	pic = "unitpics/armorco.png";
	water_friendly = true;
      },
      ['jugglenaut'] = {
	id = 7;
	name = "jugglenaut";
	type = "gorg";
	full_name = "Jugglenaut";
	pic = "unitpics/gorg.png";
	water_friendly = false;
      },
}

local blue	= {0,0,1,1}
local green	= {0,1,0,1}
local red	= {1,0,0,1}
local orange 	= {1,0.4,0,1}
local yellow 	= {1,1,0,1}
local cyan 	= {0,1,1,1}
local white 	= {1,1,1,1}

local entries = {};
local vote_delay_button = {};
local vote_delay_text = {};
local vote_unit_button = {};

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local string_vote_for = "#takeover_vote";
local string_vote_for2 = 'takeover_vote';
local string_vote_start = "^takeover_vote_start";
local string_vote_end = "^takeover_vote_end";
local takeover_error_fallback = "Takeover: WARNING! TheUnit position is underwater, thefore unit type changed back to detriment!";
local pollActive = true
local gameActive = false
local timerInSeconds = 90

local springieName = Spring.GetModOptions().springiename or ''

local VOTE_SPAM_DELAY = 1	--seconds
local VOTE_DEFAULT_CHOICE1 = "detriment";
local VOTE_DEFAULT_CHOICE2 = 450;

local my_old_choice = {};
local my_choice = {};
my_choice[0] = VOTE_DEFAULT_CHOICE1;
my_choice[1] = VOTE_DEFAULT_CHOICE2;
my_old_choice[0] = VOTE_DEFAULT_CHOICE1;
my_old_choice[1] = VOTE_DEFAULT_CHOICE2;
local most_voted_option = {};
most_voted_option[0] = VOTE_DEFAULT_CHOICE1;
most_voted_option[1] = VOTE_DEFAULT_CHOICE2;

local spectator = false
local players = {}; -- unsorted
local player_list = {}; -- sorted
local myAllyTeam;
local myTeam;
local players_voted = 0;

local delay_options = {
      {
	id = 1;
	delay = 0;
      },
      {
	id = 2;
	delay = 5;
      },
      {
	id = 3;
	delay = 10;
      },
      {
	id = 4;
	delay = 30;
      },
      {
	id = 5;
	delay = 45;
      },
      {
	id = 6;
	delay = 60;
      },
      {
	id = 7;
	delay = 90;
      },
      {
	id = 8;
	delay = 120;
      },
      {
	id = 9;
	delay = 150;
      },
      {
	id = 10;
	delay = 240;
      },
      {
	id = 11;
	delay = 300;
      },
      {
	id = 12;
	delay = 450;
      },
      {
	id = 13;
	delay = 600;
      },
      {
	id = 14;
	delay = 900;
      },
      {
	id = 15;
	delay = 1200;
      },
      {
	id = 16;
	delay = 1500;
      },
      {
	id = 17;
	delay = 1800;
      },
      {
	id = 18;
	delay = 3600;
      },
      {
	id = 19;
	delay = 7200;
      },
      {
	id = 20;
	delay = 9000;
      },
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetColorForDelay(delay, paint_green)
	if (delay <= 5) then return red; elseif (delay < 45) then return orange; elseif (delay < 90) then return yellow; elseif (delay >= 1500) then return cyan; end;
	if (delay == 90) and (paint_green) then return green; end
	return white;
end

local lastClickTimestamp = 0
local function CheckForVoteSpam (currentTime) --// function return "true" if not a voteSpam
	local elapsedTimeFromLastClick = currentTime - lastClickTimestamp
	if elapsedTimeFromLastClick < VOTE_SPAM_DELAY then
		return false
	else
		lastClickTimestamp = currentTime;
		return true
	end
end

local function AddEntry(i)
	local color = red;
	if (player_list[i].team == myTeam) then
	  color = cyan;
	elseif (player_list[i].ally == myAllyTeam) then
	  color = green;
	end
	entries[i] = {}
	entries[i].choice = {}
	entries[i].label = Label:New{
	  autosize=false;
	  --align="center";
	  valign="center";
	  caption = player_list[i].name;
	  height = 40,
	  fontsize = 20, -- TODO change this so every name fits
	  --width = 120;
	  textColor = color,
	};
	entries[i].choice[0] = Image:New {
	  file   = unit_choice[player_list[i].choice[0]].pic;
	  height = 40;
	  width = 40;
	};
	-- TODO scrap code below and make it convert seconds into minutes if needed, so any number fits into small square
	-- i believe such things would take some extra time
	--local fontsize = 24;
	--if (tonumber(player_list[i].choice[1])>99) then fontsize = 18; end
	local delay = player_list[i].choice[1];
	local color = GetColorForDelay(delay, true)
	entries[i].choice[1] = Label:New {
	  autosize=false;
	  align="center";
	  valign="center";
	  caption = delay;
	  height = 40,
	  width = 40;
	  fontsize=18; -- so cost values are better? for now atleast...
	  textColor = color;
	};
	entries[i].entry = StackPanel:New{
		x = 8;
		y = 16+players_voted*32;
		centerItems = false,
		resizeItems = false;
		columns = 1;
		orientation   = "horizontal";
		width = "100%";
		height = 40,
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
		backgroundColor = {0, 0, 0, 0},
		children = {
		  entries[i].label,
		  entries[i].choice[0],
		  Image:New {
		    file   = "unitpics/fakeunit.png";
		    height = 40;
		    width = 40;
		      children = { 
		      entries[i].choice[1],
		    },
		  },
		},
	}
	scroll_panel:AddChild( entries[i].entry );
end

local function UpdateResults(i)
	-- someone updated his choice, redraw it
	entries[i].choice[0].file = unit_choice[player_list[i].choice[0]].pic;
	entries[i].choice[0]:Invalidate();
	local delay = player_list[i].choice[1];
	local color = GetColorForDelay(delay, true);
	entries[i].choice[1]:SetCaption(delay);
	entries[i].choice[1].font:SetColor(color);
end
local function DelayIntoID(delay)
	for _,a in ipairs(delay_options) do
	  if (a.delay == delay) then
	    return a.id
	  end
	end
end
local function UpdateVote()
	-- recalculate most popular option, quite easy, build a table of most wanted option
	-- TODO much better code is present in "takeover.lua", put it here...
	local choices = {}
	for _,unit in pairs(unit_choice) do
	  choices[unit.id] = {}
	  choices[unit.id].name = unit.name
	  choices[unit.id].votes = 0
	end
	local id
	for i=1,#player_list do
	  if player_list[i].voted then
	    id = unit_choice[player_list[i].choice[0]].id
	    choices[id].votes = choices[id].votes+1
	  end
	end
	local bestv = {}
	bestv.choice = "detriment"
	bestv.votes = 0
	for _,choice in pairs(choices) do
	  if (choice.votes > bestv.votes) then
	    bestv.votes = choice.votes
	    bestv.choice = choice.name
	  end
	end
	most_voted_option[0] = bestv.choice
	-- update 
	icon1.file = unit_choice[bestv.choice].pic;
	icon1:Invalidate();
	text1:SetCaption(bestv.votes.." votes");
	-- part 2, delay ?
	choices = {}
	for _,a in ipairs(delay_options) do
	  choices[a.id] = {}
	  choices[a.id].name = a.delay;
	  choices[a.id].votes = 0
	end
	for i=1,#player_list do
	  if player_list[i].voted then
	    id = DelayIntoID(player_list[i].choice[1])
	    choices[id].votes = choices[id].votes+1
	  end
	end
	local bestv = {}
	bestv.choice = 90
	bestv.votes = 0
	for _,choice in pairs(choices) do
	  if (choice.votes > bestv.votes) then
	    bestv.votes = choice.votes
	    bestv.choice = choice.name
	  end
	end
	most_voted_option[1] = bestv.choice
	-- update
	icon2:RemoveChild(textd)
	textd = Label:New{
		height = 36; width = 36; fontsize=16; caption=bestv.choice; align="center"; valign="center"; textColor = green;
	}
	icon2:AddChild(textd)
	text2:SetCaption(bestv.votes.." votes");
end

-- TODO really? i don't understand why i can't update text's color if it's parent is button, i have to add/remove it all the time!
local function AddTextToButton(button, i, delay, color)
	vote_delay_text[i]=Image:New {
		      file   = "unitpics/fakeunit.png";
		      height = 40;
		      width = 40;
		      children = {
			Label:New {
			  autosize=false;
			  align="center";
			  valign="center";
			  caption = delay;
			  height = 40,
			  width = 40;
			  fontsize=18;
			  textColor=color;
			  },
		      },
		    };
	button:AddChild(vote_delay_text[i]);
end

local function RecolorDelays(old, new)
	local a1 = false
	local a2 = false
	for _,a in ipairs(delay_options) do
	    delay = a.delay;
	    i = a.id;
	--for i,delay in ipairs(global_delays_options) do
	    if (a1) and (a2) then return
	    elseif (delay == old) then
		vote_delay_button[i]:RemoveChild(vote_delay_text[i])
		AddTextToButton(vote_delay_button[i], i, delay, GetColorForDelay(delay,false))
		a1 = true
	    elseif (delay == new) then
		vote_delay_button[i]:RemoveChild(vote_delay_text[i])
		AddTextToButton(vote_delay_button[i], i, delay, green)
		a2 = true
	    end
	end
end

local function GetVotes(line)
	if line==string_vote_for then return false end
	--Spring.Echo("YOU VOTED FOR SOMETHING LOL")
	words={}
	for word in line:gmatch("[^%s]+") do words[#words+1]=word end
	if (#words ~= 4) then return false end
	local name = words[1];
	name = name.sub(name,2,#name-1);
	-- find player by name... oh my
	for i=1,#player_list do
	  if (player_list[i].name == name) then
	    if (unit_choice[words[3]] ~= nil) then
		player_list[i].choice[0] = words[3]
	    end
	    if (tonumber(words[4]) ~= nil) then
		player_list[i].choice[1] = tonumber(words[4])
	    end
	    -- TODO detection if invalid choice is done above, but instead of putting defautl values, need to tell abuser to vote again
	    if not player_list[i].voted then
	      player_list[i].voted = true
	      AddEntry(i)
	      players_voted = players_voted+1;
	    else
	      UpdateResults(i)
	    end
	  end -- if player name isn't on sorted list, it's spectator or someone else? ignore anyway
	end
	UpdateVote()
	--Spring.Echo(name..words[3]..words[4])
end

local function PrepareGame(line)
	words={}
	for word in line:gmatch("[^%s]+") do words[#words+1]=word end
	gameActive = true
	timerInSeconds = tonumber(words[3])
	most_voted_option[0] = words[2]
	most_voted_option[1] = timerInSeconds-30
	winner_icon = Image:New {
	    x=10;
	    y=10;
	    file   = unit_choice[most_voted_option[0]].pic;
	    height = 60;
	    width = 60; }
	stats_window:AddChild(winner_icon)
	stats_timer = Label:New{
		width = 120,
		height = 40,
		y = 20;
		right = 7;
		autosize=false;
		--align="center";
		valign="center";
		caption = timerInSeconds.." seconds left";
	}
	stats_window:AddChild(stats_timer)
end

function widget:AddConsoleLine(line,priority)
	if gameActive then return false end -- no need to check anything if game started
	if line:sub(1,7) == "GameID:" then
		pollActive = false
		vote_minimized = true
		screen0:RemoveChild(vote_window)
	end
	if line:sub(1,springieName:len()) ~= springieName then	-- no spoofing messages
		return false
	end
	if line:find(string_vote_end) then	--terminate existing vote
		pollActive = false
		if not vote_minimized then
		  vote_minimized = true
		  screen0:RemoveChild(vote_window)
		end
		stats_window:RemoveChild(show_vote_window_button)
		PrepareGame(line)
	elseif line:find(takeover_error_fallback) then
		most_voted_option[0]="detriment"
		pollActive = false
		if not vote_minimized then
		  vote_minimized = true
		  screen0:RemoveChild(vote_window)
		end
		stats_window:RemoveChild(show_vote_window_button)
		PrepareGame()		
	elseif line:find(string_vote_start) then
		if not pollActive then
			pollActive = true
			vote_minimized = false
			screen0:AddChild(vote_window)
		end
	end
	if pollActive and line:find(string_vote_for) then
		GetVotes(line)
		line = "" --idk, is this okay? otherwise it loops
	end
	return false
end

function widget:GameStart()
  -- meh
end

function widget:GameFrame(n)
	if ((n%30)==0) then
	    if (timerInSeconds > 0) then
	      timerInSeconds = timerInSeconds - 1
	      if (stats_timer) then
		  stats_timer:SetCaption(timerInSeconds.." seconds left.")
	      end
	    elseif (timerInSeconds == 0) then
	      timerInSeconds = timerInSeconds - 1
	      if (stats_timer) then
		  stats_timer:SetCaption("unit is freed or dead.")
	      end
	    end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:Initialize()
	spectator = Spring.GetSpectatingState()
  	players = Spring.GetPlayerList()
	myAllyTeam = Spring.GetMyAllyTeamID()
	myTeam = Spring.GetMyTeamID()
	for i=1,#players do
		local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage = Spring.GetPlayerInfo(players[i])
		if not spectator and active then
		      player_list[#player_list + 1] = {id = i, name = name, team = teamID, ally = myAllyTeam==allyTeamID, voted = false, choice = {}};
		      player_list[#player_list].choice[0] = VOTE_DEFAULT_CHOICE1;
		      player_list[#player_list].choice[1] = VOTE_DEFAULT_CHOICE2;
		end
	end
    --widgetHandler:RemoveWidget()
	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Colorbars = Chili.Colorbars
	Window = Chili.Window
	Panel = Chili.Panel
	StackPanel = Chili.StackPanel
	ScrollPanel = Chili.ScrollPanel
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	Control = Chili.Control
	screen0 = Chili.Screen0
	
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	local mwidth = 600;
	local mheight = 620;
	
	local swidth = 200;
	local sheight = 80;
	
	--stats_window, stats_panel, stats_timer
	show_vote_window_button = Button:New {
		width = 120,
		height = 30,
		padding = {0, 0, 0,0},
		margin = {0, 0, 0, 0},
		y = 25;
		right = 40;
		backgroundColor = {1, 1, 1, 0.4},
		caption="Show vote menu";
		tooltip = "Unminimize voting menu";
		OnMouseDown = {function()
			if vote_minimized then
				screen0:AddChild(vote_window) end
			end}
	}
	stats_window = Window:New{
		minimizable = true,
		parent = screen0,
		name   = 'takeover_stats';
		--color = {0, 0, 0, 0},
		width = swidth;
		height = sheight;
		right = 30;
		y = 100;
		--x = screenWidth/2-swidth/2;
		--y = screenHeight/2-sheight/2-10;
		dockable = false;
		draggable = true,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minWidth = MIN_WIDTH, 
		minHeight = MIN_HEIGHT,
		padding = {0, 0, 0, 0},
		--itemMargin  = {0, 0, 0, 0},
		color = {1, 1, 1, 0.5},
		children = {
		    show_vote_window_button,
		}
	}
	
	vote_window = Window:New{
		minimizable = true,
		parent = screen0,
		name   = 'takeover_votes';
		--color = {0, 0, 0, 0},
		width = mwidth;
		height = mheight;
		x = screenWidth/2-mwidth/2;
		y = screenHeight/2-mheight/2-10;
		dockable = false;
		draggable = true,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minWidth = MIN_WIDTH, 
		minHeight = MIN_HEIGHT,
		padding = {0, 0, 0, 0},
		--itemMargin  = {0, 0, 0, 0},
		color = {0.1, 0, 0.9, 0.7},
	}
	icon1 = Image:New {
			x=240;
			file   = unit_choice["detriment"].pic;
			height = 36;
			width = 36; }
	text1 = Label:New{
		x = 280;
		autosize=false;
		align="center";
		--valign="top";
		caption = "0 votes";
		height = 36,
		width = 50;
	}
	textd = Label:New{
		height = 36; width = 36; fontsize=16; caption="90"; align="center"; valign="center"; textColor = green;
	}
	text2 = Label:New{
		x = 380;
		autosize=false;
		align="center";
		--valign="top";
		caption = "0 votes";
		height = 36,
		width = 50;
	}
	icon2 = Image:New {
			x=340;
			file   = "unitpics/fakeunit.png";
			height = 36;
			width = 36;
			children = {textd}, }
	most_voted_panel = Panel:New{
		y = vote_window.height-36;
		parent = vote_window,
		resizeItems = true;
		orientation   = "vertical";
		height = 36;
		width =  "100%";
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
		backgroundColor = {1, 1, 1, 0.5},
		children = {	Label:New{
			    autosize=false;
			    x=100;
			    --align="center";
			    valign="center";
			    caption = 'Most popular choice:';
			    height = "100%",
			    width = 150;
		    },
		    icon1,
		    text1,
		    icon2,
		    text2,
		}
	}
	panel_main = Panel:New{
		parent = vote_window,
		resizeItems = true;
		orientation   = "vertical";
		height = 16;
		width =  "100%";
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
		backgroundColor = {0.1, 0, 0.9, 1},
	}
	vote_title = Label:New{
		parent = panel_main,
		autosize=false;
		align="center";
		--valign="top";
		caption = 'Takeover Vote Display | Vote for gameplay options!';
		height = 16,
		width = "100%";
	}
	panel_for_stack = Panel:New{
		y = 16,
		parent = vote_window,
		resizeItems = true;
		orientation   = "vertical";
		width = "60%";
		height = vote_window.height-50,
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
		backgroundColor = {0, 0, 0, 0.5},
		borderColor = {1,1,1,1},
	}
	choose_unit_text = "Choose unit:";
	unit_stack_panel = StackPanel:New{
		    y = 16;
		    centerItems = false,
		    resizeItems = false;
		    orientation   = "horizontal";
		    width = "100%";
		    height = "100%",
		    padding = {5, 5, 5, 5},
		    itemMargin  = {5,0,0,0},
		  };
	choose_unit = Panel:New{
		resizeItems = true;
		orientation   = "vertical";
		width = "100%";
		height = 170,
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
		backgroundColor = {0, 0, 0, 1},
		children = {
		  Label:New{
		    autosize=false;
		    align="center";
		    --valign="top";
		    caption = choose_unit_text;
		    height = 16,
		    width = "100%";
		  },
		  unit_stack_panel,
		}
	}
	choose_delay_text = "Choose delay (in seconds):";
	delay_stack_panel = StackPanel:New{
		    y = 16;
		    centerItems = false,
		    resizeItems = false;
		    orientation   = "horizontal";
		    width = "100%";
		    height = "100%",
		    padding = {5, 5, 5, 5},
		    itemMargin  = {5,0,0,0},
		  };
	choose_delay = Panel:New{
		resizeItems = true;
		orientation   = "vertical";
		width = "100%";
		height = 170,
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
		backgroundColor = {0, 0, 0, 1},
		children = {
		  Label:New{
		    autosize=false;
		    align="center";
		    --valign="top";
		    caption = choose_delay_text;
		    height = 16,
		    width = "100%";
		    },
		  delay_stack_panel,
		}
	}
	vote_button = Button:New {
		width = 80,
		height = 30,
		padding = {0, 0, 0,0},
		margin = {0, 0, 0, 0},
		right = panel_for_stack.width/2;
		backgroundColor = {1, 1, 1, 0.4},
		caption="Vote!";
		tooltip = "Relay your choice to others!";
		OnMouseDown = {function() 
				local notSpam = CheckForVoteSpam (os.clock())
					if notSpam then
					Spring.SendCommands("say "..string_vote_for.." "..my_choice[0].." "..my_choice[1])
					Spring.SendLuaRulesMsg(string_vote_for2.." "..my_choice[0].." "..my_choice[1])
				end
			end}
	}
	minimize_button = Button:New {
		width = 80,
		height = 30,
		padding = {0, 0, 0,0},
		margin = {0, 0, 0, 0},
		right = panel_for_stack.width/2-80;
		backgroundColor = {1, 1, 1, 0.4},
		caption="minimize";
		tooltip = "Close this window";
		OnMouseDown = {function() 
				screen0:RemoveChild(vote_window); vote_minimized = true;
			end}
	}
	panel_for_vote = Panel:New{
		resizeItems = true;
		orientation   = "vertical";
		width = "100%";
		height = 32,
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
		backgroundColor = {0, 0, 0, 0},
		children = {
		  minimize_button,
		}
	}
	if not spectator then
	  panel_for_vote:AddChild(vote_button);
	end
	stack_panel = StackPanel:New {
		parent = panel_for_stack,
		centerItems = false,
		resizeItems = false;
		--resizeItems = true;
		orientation   = "vertical";
		width = "100%";
		height = vote_window.height-32,
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
		children = {
		  Label:New{
		  autosize=false;
		  align="center";
		  valign="top";
		  caption = "The rules are simple, all active players vote for desired options, before game's start.\n1) You may select 1 unit you want to spawn in the center of map.\n2) As well as time needed for this unit to wake up.\n3) Last team to do EMP damage to the unit, before timer reaches 0 - gets it!\nMost popular options voted for - are on!\nChoose unit and desired grace time, and press \"vote\".\nNote: if no team grabs the unit - unit will go bersek.\nVersion: "..version..".";
		  height = 150,
		  width = "100%";},
		  choose_unit,
		  choose_delay,
		  panel_for_vote,		  
		}
	}
	scroll_panel = ScrollPanel:New{
	        y = 16,
		x = "60%",
		parent = vote_window,
		width = "40%",
		height = vote_window.height-50,
		borderColor = {1,1,1,0},
		--backgroundColor  = {1,1,1,0.5},
		--borderColor = {1,1,1,options.backgroundOpacity.value},
		padding = {0, 0, 0, 0},
		--autosize = true,
		scrollbarSize = 6,
		horizontalScrollbar = false,
		hitTestAllowEmpty = true,
		children = {
		  Label:New{
		  autosize=false;
		  align="center";
		  --valign="top";
		  caption = 'Player voted for:';
		  height = 16,
		  width = "100%";}
		}
	}
	local color
	for _,de in ipairs(delay_options) do
	  if (de.delay == my_choice[1]) then color = green; else color = GetColorForDelay(de.delay, false); end
	  vote_delay_button[de.id] = Button:New {
		height = 40;
		width = 40;
		padding = {0, 0, 0,0},
		margin = {0, 0, 0, 0},
		caption="";
		OnMouseDown = {function()
		  if (de.delay == my_choice[1]) then return end
		  my_old_choice[1] = my_choice[1];
		  my_choice[1] = de.delay;
		  RecolorDelays(my_old_choice[1],my_choice[1]);
		end},
	  }
	  AddTextToButton(vote_delay_button[de.id], de.id, de.delay, color)
	  delay_stack_panel:AddChild(vote_delay_button[de.id]);
	end
	for _,unit in pairs(unit_choice) do
	  vote_unit_button[unit.id] = Button:New {
		height = 64;
		width = 64;
		padding = {0, 0, 0,0},
		margin = {0, 0, 0, 0},
		caption="";
		tooltip=unit.full_name;
		OnMouseDown = {function()
		  if (unit.name == my_choice[0]) then return end
		  my_old_choice[0] = my_choice[0];
		  my_choice[0] = unit.name;
		end},
		children={Image:New {
			file   = unit.pic;
			height = 64;
			width = 64;
		},},
	  }
	  unit_stack_panel:AddChild(vote_unit_button[unit.id]);
	end
	--RemoveWindow()
	--Spring.Echo("takeover vote start")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------