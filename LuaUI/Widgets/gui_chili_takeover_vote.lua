--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local version = "0.0.2 beta" -- i'm so noob in this :p
-- you may find changelog in takeover.lua gadget

function widget:GetInfo()
  return {
    name      = "Chili Takeover Vote Display",
    desc      = "GUI for takeover votes "..version,
    author    = "Tom Fyuri",
    date      = "Jul 2013",
    license   = "GPL v2 or later",
    layer     = -9, 
    enabled   = true  --  loaded by default?
  }
end

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
local string_vote_start = "takeover_vote_start";
local string_vote_end = "takeover_vote_end";
local string_vote_most_popular = "takeover_vote_most_popular";
local string_vote_fallback = "takeover_vote_fallback";
local takeover_error_fallback = "Takeover: WARNING! TheUnit position is underwater, therefore unit type changed back to detriment!";
local string_takeover_owner = "takeover_new_owner";
local string_takeover_unit_died = "takeover_unit_dead"
local PollActive = false
local timerInSeconds = 90

local springieName = Spring.GetModOptions().springiename or ''

local VOTE_SPAM_DELAY = 1	--seconds
local VOTE_DEFAULT_CHOICE1 = "detriment";
local VOTE_DEFAULT_CHOICE2 = 900;

local my_old_choice = {};
local my_choice = {};
my_choice[0] = VOTE_DEFAULT_CHOICE1;
my_choice[1] = VOTE_DEFAULT_CHOICE2;
my_old_choice[0] = VOTE_DEFAULT_CHOICE1;
my_old_choice[1] = VOTE_DEFAULT_CHOICE2;
local most_voted_option = {};
most_voted_option[0] = VOTE_DEFAULT_CHOICE1;
most_voted_option[1] = VOTE_DEFAULT_CHOICE2;

local player_list = {}; -- sorted
local myAllyTeam;
local myTeam;
local players_voted = 0;

local GaiaTeamID	   	= Spring.GetGaiaTeamID()
local UnitTeamID		= GaiaTeamID
  
local unit_choice = {
      ['scorpion'] = {
	id = 1;
	name = "scorpion";
	type = "scorpion";
	full_name = "Scorpion";
	pic = "unitpics/scorpion.png";
	water_friendly = false;
	votes = 0;
      },
      ['dante'] = {
	id = 2;
	name = "dante";
	type = "dante";
	full_name = "Dante";
	pic = "unitpics/dante.png";
	water_friendly = false;
	votes = 0;
      },
      ['catapult'] = {
	id = 3;
	name = "catapult";
	type = "armraven";
	full_name = "Catapult";
	pic = "unitpics/armraven.png";
	water_friendly = false;
	votes = 0;
      },
      ['bantha'] = {
	id = 4;
	name = "bantha";
	type = "armbanth";
	full_name = "Bantha";
	pic = "unitpics/armbanth.png";
	water_friendly = false;
	votes = 0;
      },
      ['krow'] = {
	id = 5;
	name = "krow";
	type = "corcrw";
	full_name = "Krow";
	pic = "unitpics/corcrw.png";
	water_friendly = false;
	votes = 0;
      },
      ['detriment'] = {
	id = 6;
	name = "detriment";
	type = "armorco";
	full_name = "Detriment";
	pic = "unitpics/armorco.png";
	water_friendly = true;
	votes = 0;
      },
      ['jugglenaut'] = {
	id = 7;
	name = "jugglenaut";
	type = "gorg";
	full_name = "Jugglenaut";
	pic = "unitpics/gorg.png";
	water_friendly = false;
	votes = 0;
      },
}

local delay_options = {
      {
	id = 1;
	delay = 0;
	votes = 0;
      },
      {
	id = 2;
	delay = 5;
	votes = 0;
      },
      {
	id = 3;
	delay = 10;
	votes = 0;
      },
      {
	id = 4;
	delay = 30;
	votes = 0;
      },
      {
	id = 5;
	delay = 45;
	votes = 0;
      },
      {
	id = 6;
	delay = 60;
	votes = 0;
      },
      {
	id = 7;
	delay = 90;
	votes = 0;
      },
      {
	id = 8;
	delay = 120;
	votes = 0;
      },
      {
	id = 9;
	delay = 150;
	votes = 0;
      },
      {
	id = 10;
	delay = 240;
	votes = 0;
      },
      {
	id = 11;
	delay = 300;
	votes = 0;
      },
      {
	id = 12;
	delay = 450;
	votes = 0;
      },
      {
	id = 13;
	delay = 600;
	votes = 0;
      },
      {
	id = 14;
	delay = 900;
	votes = 0;
      },
      {
	id = 15;
	delay = 1200;
	votes = 0;
      },
      {
	id = 16;
	delay = 1500;
	votes = 0;
      },
      {
	id = 17;
	delay = 1800;
	votes = 0;
      },
      {
	id = 18;
	delay = 3600;
	votes = 0;
      },
      {
	id = 19;
	delay = 7200;
	votes = 0;
      },
      {
	id = 20;
	delay = 9000;
	votes = 0;
      },
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetColorForDelay(delay, paint_green)
	if (delay <= 30) then return red; elseif (delay <= 180) then return orange; elseif (delay <= 360) then return yellow; elseif (delay >= 1500) then return cyan; end;
	if (delay == VOTE_DEFAULT_CHOICE2) and (paint_green) then return green; end
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
local function UpdateMostPopularGraphics()
	icon1.file = unit_choice[most_voted_option[0]].pic;
	icon1:Invalidate();
	text1:SetCaption(most_unit_votes.." votes");
	icon2:RemoveChild(textd)
	textd = Label:New{
		height = 36; width = 36; fontsize=16; caption=most_voted_option[1]; align="center"; valign="center"; textColor = GetColorForDelay(most_voted_option[1]);
	}
	icon2:AddChild(textd)
	text2:SetCaption(most_delay_votes.." votes");
end
local function UpdateVote(line)
	words={}
	for word in line:gmatch("[^%s]+") do words[#words+1]=word end
	if (#words ~= 5) then return false end
	-- TODO do in need safety checks here? i think not
	most_voted_option[0] = words[2]
	most_unit_votes = words[3]
	most_voted_option[1] = tonumber(words[4])
	most_delay_votes = words[5]
	-- update
	UpdateMostPopularGraphics()
	--Spring.Echo(most_voted_option[0].." "..most_voted_option[1])
end
local function GetPlayerName(owner,team,isAI)
      local name = "noname"
      if isAI then
	local _,aiName,_,shortName = spGetAIInfo(team)
	-- FIXME i never tested it with AI, so i wonder what name will it get... lol
	name = aiName; --.."["..team.."]"..'('.. shortName .. ')'
      elseif owner then
	name = Spring.GetPlayerInfo(owner);--.."["..team.."]"
      end
      return name
end
local function UpdateUnitTeam(line)
      words={}
      for word in line:gmatch("[^%s]+") do words[#words+1]=word end
      if (#words ~= 2) then return false end
      local team = tonumber(words[2])
      local _,owner,_,isAI,allyTeam = Spring.GetTeamInfo(team)
      local color = red;
      if (GaiaTeamID == team) then
	color = white;
      elseif (team == myTeam) then
	color = cyan;
      elseif (myAllyTeam == allyteam) then
	coor = green;
      end
      unit_team:SetCaption("Owner: "..GetPlayerName(owner,team,isAI)..".")
      unit_team.font:SetColor(color)
      UnitTeamID = team
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

local function GetVotes(playerID, name, line)
	-- this code is almost identical to the takeover.lua's implementation, but it has also some callins to update gui
	if line==string_vote_for then return false end
	words={}
	for word in line:gmatch("[^%s]+") do words[#words+1]=word end
	if (#words ~= 3) then return false end
	local new = true
	local id = -1
	for i=1,#player_list do
	  if (player_list[i].playerID == playerID) then
	    new = false;
	    id = i;
	    break;
	  end
	end
	if new then
	  local _ ,_,_,teamID,allyTeamID,_,_ = Spring.GetPlayerInfo(playerID)
	  player_list[#player_list+1] = {
	    playerID = playerID;
	    name = name;
	    team = teamID;
	    ally = myAllyTeam==allyTeamID;
	    voted = false;
	    choice = {};
	  };
	  player_list[#player_list].choice[0] = VOTE_DEFAULT_CHOICE1;
	  player_list[#player_list].choice[1] = VOTE_DEFAULT_CHOICE2;
	  id = #player_list;
	end
	if (id > -1) then -- safety check
	  if (unit_choice[words[2]] ~= nil) then
	      if (player_list[id].voted) then
		  unit_choice[player_list[id].choice[0]].votes = unit_choice[player_list[id].choice[0]].votes-1
	      end
	      unit_choice[words[2]].votes = unit_choice[words[2]].votes+1
	      player_list[id].choice[0] = words[2]
-- 		spEcho(words[2].." "..unit_choice[words[2]].votes)
	  end
	  local delay = tonumber(words[3])
	  if (delay ~= nil) then
	      if (player_list[id].voted) then
		  delay_options[DelayIntoID(player_list[id].choice[1])].votes = delay_options[DelayIntoID(player_list[id].choice[1])].votes-1
	      end
	      delay_options[DelayIntoID(delay)].votes = delay_options[DelayIntoID(delay)].votes+1
	      player_list[id].choice[1] = delay
	  end
	  -- TODO detection if invalid choice is done above, but instead of putting default values, need to tell abuser to vote again
	  if not player_list[id].voted then
	    player_list[id].voted = true
	    AddEntry(id)
	    players_voted = players_voted+1;
	  else
	    UpdateResults(id)
	  end
	end
-- 	UpdateVote() -- no longer needed, since i can get current choice from gadget, perfectly synced :)
end

local function PrepareGame(line)
	words={}
	for word in line:gmatch("[^%s]+") do words[#words+1]=word end
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
		y = 30;
		right = 5;
		autosize=false;
		--align="center";
		valign="center";
		caption = timerInSeconds.." seconds left.";
	}
	stats_window:AddChild(stats_timer)
	unit_team = Label:New{
		width = 120,
		height = 40,
		y = 10;
		right = 5;
		autosize=false;
		--align="center";
		valign="center";
		caption = "Owner: noone.";
		textColor = white;
	}
	stats_window:AddChild(unit_team)
	if (timerInSeconds > 5) then
	  Spring.Echo("Takerover: The Unit is "..unit_choice[most_voted_option[0]].full_name.." and it will keep changing owner for "..timerInSeconds.." seconds.")
	else
	  Spring.Echo("Takerover: The Unit is "..unit_choice[most_voted_option[0]].full_name.." and it will go bersek right about... now? :)")
	end
end

function widget:RecvLuaMsg(line, playerID)
    -- FIXME figure out what can be elseif and what cannot, i'm having trouble...
    if not PollActive then
      if (line == string_vote_start) then -- i wonder if i should check whether playerid ain't equal to the one who sent the msg
	PollActive = true
	vote_minimized = false
	screen0:AddChild(vote_window)
	screen0:AddChild(stats_window)
      end
      if line:find(string_takeover_owner) then
	UpdateUnitTeam(line)
      end
      if line:find(string_takeover_unit_died) then
	stats_window:RemoveChild(unit_team)
      end
    else
      if line:find(string_vote_for2) and PollActive then
	local name, _, spectator = Spring.GetPlayerInfo(playerID)
	if not spectator then
	  GetVotes(playerID, name, line)
	end
      end
      if line:find(string_vote_most_popular) then
	UpdateVote(line)
      end
      if (line == string_vote_fallback) then
	Spring.Echo(takeover_error_fallback)
	most_voted_option[0]="detriment"
	UpdateMostPopularGraphics()
      end
      if line:find(string_vote_end) then	--terminate existing vote
	PollActive = false
	if not vote_minimized then
	  vote_minimized = true
	  screen0:RemoveChild(vote_window)
	end
	stats_window:RemoveChild(show_vote_window_button)
	PrepareGame(line)
      end
    end
end

function widget:GameFrame(n)
	if ((n%30)==0) then
	    if (timerInSeconds > 0) then
	      timerInSeconds = timerInSeconds - 1
	      if (stats_timer) then
		  stats_timer:SetCaption(timerInSeconds.." seconds left.")
	      end
	    elseif (timerInSeconds == 0) then
	      timerInSeconds = -1
	      if (stats_timer) then
		  stats_timer:SetCaption("Time's out.")
		  stats_timer.font:SetColor(orange)
	      end
	      if (unit_team) and (UnitTeamID == GaiaTeamID) then
		unit_team:SetCaption("BERSERK MODE")
		unit_team.font:SetColor(red)
	      end
	    end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:Initialize()
	myAllyTeam = Spring.GetMyAllyTeamID()
	myTeam = Spring.GetMyTeamID()
	
	if (not Spring.GetModOptions().zkmode) or (Spring.GetModOptions().zkmode ~= "takeover") then -- or Spring.GetSpectatingState() then -- ok i will allow spectators
	    widgetHandler:RemoveWidget()
	end
	
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
		--[[children = {
		    show_vote_window_button,
		}]]--
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
		height = 36; width = 36; fontsize=16; caption=VOTE_DEFAULT_CHOICE2; align="center"; valign="center"; textColor = GetColorForDelay(VOTE_DEFAULT_CHOICE2);
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
-- 				local notSpam = CheckForVoteSpam (os.clock())
-- 				    if notSpam then
-- 					Spring.SendCommands("say "..string_vote_for.." "..my_choice[0].." "..my_choice[1]) -- ok
-- 				    end -- i think it's allright to spam luarules but not spam chat :)
		  -- whatever i don't see any reason to spam chat... maybe ally chat?
					Spring.SendLuaRulesMsg(string_vote_for2.." "..my_choice[0].." "..my_choice[1]) -- lol...
					Spring.SendLuaUIMsg(string_vote_for2.." "..my_choice[0].." "..my_choice[1]) -- lol?!
-- 				end
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
		  if not vote_minimized then
				screen0:RemoveChild(vote_window); vote_minimized = true;
				stats_window:AddChild(show_vote_window_button)
		  end
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
	screen0:RemoveChild(vote_window) -- FIXME i just don't know if there is property to make window hidden from the begining
	screen0:RemoveChild(stats_window)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------