--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local version = "0.1.0" -- you may find changelog in takeover.lua gadget

function widget:GetInfo()
  return {
    name      = "Chili Takeover Vote Display",
    desc      = "GUI for takeover game mode "..version,
    author    = "Tom Fyuri", -- also kudos to Sprung, KingRaptor and jK
    date      = "Jul 2013",
    license   = "GPL v2 or later",
    layer     = -1, 
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

local blue	= {0,0,1,1}
local green	= {0,1,0,1}
local red	= {1,0,0,1}
local orange 	= {1,0.4,0,1}
local yellow 	= {1,1,0,1}
local cyan 	= {0,1,1,1}
local white 	= {1,1,1,1}

local GL_LINE_STRIP         = GL.LINE_STRIP

local glVertex		= gl.Vertex
local glDepthTest	= gl.DepthTest
local glColor		= gl.Color
local glBeginEnd	= gl.BeginEnd
local glLineWidth	= gl.LineWidth
local glDrawFuncAtUnit  = gl.DrawFuncAtUnit
local glRotate		= gl.Rotate
local glTranslate	= gl.Translate
local glBillboard	= gl.Billboard

local overheadFont	= "LuaUI/Fonts/FreeSansBold_16"

local random	= math.random
local floor	= math.floor
local abs	= math.abs
local sqrt	= math.sqrt
local PI	= math.pi
local cos	= math.cos
local sin	= math.sin
local max	= math.max

-- everything regarding status panel
local help_button
-- before vote is settled
local vote_menu_button
local status_window
local welcome_text
local results_label
local results_stack
local results_elements = {}
-- after vote relation
local status_timeleft
local status_ally
local status_enemy
local status_units = {}
local status_stage = 1

-- everything regarding help menu
local help_window
local help_text = "Read carefully:\n- Before game starts, you can decide, which unit type will be objective.\n- It is always possible to capture objective, fully emp it and surround with allied units.\n- \"Timeleft\" timer shows how much time left for unit to be asleep.\n- While timer is non zero, it is good idea to try capturing it.\n- If objective is valuable, and invincible, keep friendly army near by at all times!\n- The circle around objective shows capture range, your units should be inside.\n- Blinking circle indicates capture progress, you only need 3 seconds to capture any objective.\n- There can be multiple objectives, refer to status panel.\nIf you have any suggestions or advices, please join Zero-K forum (development section) or find \"Ivica\" in #zk/#zkdev room.\nHave fun!\nVersion: "..version.."."
local help_title

-- everything regarding vote menu
local vote_scroll
local nominate_stack
local default_nomination = true

-- everything regarding nominating a new vote
local nominate_window
local nominate_advice
local nominate_location
local nominate_unit
local nominate_unit_button = {}
local nominate_gracetime
local nominate_grace_button = {}
local nominate_godmode

-- other stuff
local nominations = {}
local nomination_count = 0
local loc_tooltip_array = {
  "Only one unit, in the center of the map.",
  "Multiple units, same type, each for each spawn box.",
  "Multiple units, same type, across map between spawn boxes.",
}
local god_tooltip_array = {
  "TheUnit(s) can die at any time. Reclaim the bastard(s)!",
  "TheUnit(s) will stay immune to any physical damage, if it's fully emped or grace timer > 0.",
  "TheUnit(s) will never die, yet they can still recieve emp/slow/cap damage.",
}

local fu = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local UnitList = { "scorpion", "dante", "armraven", "armbanth", "corcrw", "armorco", "funnelweb",
    "corgol", "corsumo", "armmanni", "armzeus", "armcrabe", "armcarry", "corbats", "armcomdgun", "armcybr", "corroy", "amphassault",
    "armamd", "corsilo", "armcir", "screamer", "missilesilo",
    "corhlt", "armanni", "cordoom", "cafus", "armbrtha", "corbhmth",
    "zenith", "mahlazer", "raveparty", "armcsa" }
local GraceList = { 0, 15, 45, 90, 120, 180, 240, 300, 450, 600, 750, 817, 900 }

local my_choice = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local UpdateTimer = 0
local UPDATE_FREQUENCY = 0.8	-- seconds
local UPDATE_FREQUENCY_2 = 0.5	-- seconds
local timer = 0
local timer_2 = 0

local myAllyTeam;
local myTeam;
local myPlayerID;

local GaiaTeamID	= Spring.GetGaiaTeamID() -- TODO probably I should local all Spring. stuff here
local GaiaAllyTeamID	= select(6,Spring.GetTeamInfo(GaiaTeamID))

local PollActive = -1
local GameStarted = false

local DEFAULT_CHOICE = {0, UnitDefNames["armzeus"].id, 240, 2} -- mortal dante (armorco) should probably fit better, but this zeus is immortal :)
local CAPTURE_RANGE = 256 -- capture range, you need to stand this close to begin unit capture process

local TheUnitCount = 0

local visible = {}
local under_siege = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetColorForDelay(delay)
  if (delay <= 30) then return red; elseif (delay <= 120) then return orange; elseif (delay <= 360) then return yellow; elseif (delay >= 1500) then return cyan; end;
  return white;
end

local function GetTimeFormatted2(time)
  local delay_minutes = floor(time/60) -- TODO optimise this, this can be done lot better and faster
  local delay_seconds = time-delay_minutes*60
  local time_text = "no delay"
  if (time > 0) then
    if (0 == delay_seconds) and (delay_minutes > 0) then
      time_text = delay_minutes.."m"
    elseif (delay_minutes == 0) then
      time_text = delay_seconds.."s"
    else
      time_text = delay_minutes.."m "..delay_seconds.."s"
    end -- should be possible to do this much faster
  end
  return time_text
end

local function GetTimeFormatted(time, addzeros)
  local delay_minutes = floor(time/60) -- TODO optimise this, this can be done lot better and faster
  local delay_seconds = time-delay_minutes*60
  local time_text = "   no\ndelay"
  if (time > 0) then
    if (0 == delay_seconds) and (delay_minutes > 0) then
      time_text = delay_minutes.."m"
    elseif (delay_minutes == 0) then
      time_text = delay_seconds.."s"
    else
      time_text = delay_minutes.."m\n"..delay_seconds.."s"
    end -- should be possible to do this much faster
  end
  if addzeros then
    if (delay_minutes < 10) then 
      delay_minutes = "0"..delay_minutes
    end
    if (delay_seconds < 10) then
      delay_seconds = "0"..delay_seconds
    end
  end
  return delay_minutes, delay_seconds, time_text
end

local function AnnounceMyChoice(choice)
  Spring.SendLuaRulesMsg("takeover_nominate "..choice[1].." "..choice[2].." "..choice[3].." "..choice[4])
  -- announce choice in chat
  local loc_text = "at center";
  if (choice[1] == 1) then
    loc_text = "in spawn boxes";
  elseif (choice[1] == 2) then
    loc_text = "across map";
  end
  local time_text = GetTimeFormatted2(choice[3])
  local god_text = "mortal";
  if (choice[4] == 1) then
    god_text = "semi-mortal";
  elseif (choice[4] == 2) then
    god_text = "immortal";
  end
  Spring.SendCommands("say I nominate: "..god_text.." "..UnitDefs[choice[2]].humanName.." being spawned "..loc_text.." and dormant for "..time_text.."!");
end

local function SetupNominationStack(nomi, name, name_color, owner, nom)
  local loc_text = "center";
  if (nomi.location == 1) then
    loc_text = "spawn\n box";
  elseif (nomi.location == 2) then
    loc_text = "across\n  map";
  end
  local delay_minutes, delay_seconds, time_text = GetTimeFormatted(nomi.grace, false)
  local god_text = "mortal";
  local god_color = white;
  if (nomi.godmode == 1) then
    god_text = " semi-\nmortal";
    god_color = yellow;
  elseif (nomi.godmode == 2) then
    god_text = "god-\nlike";
    god_color = red
  end
  if (owner > -1) then -- TODO make less clutter, i know this can be merged somehow
    local also_agree = "";
    if (nomi.vote_count > 1) then
      -- find anyone who agrees
      local players = Spring.GetTeamList()
      for i=0,#players do
	local agree = Spring.GetGameRulesParam("takeover_player_agree"..i)
	if (agree == nom) and (i ~= myPlayerID) then
	  if (also_agree == "") then
	    also_agree = also_agree.."\nPlayers who also agree: "..select(1,Spring.GetPlayerInfo(i))
	  else
	    also_agree = also_agree..", "..select(1,Spring.GetPlayerInfo(i))
	  end
	end
      end
      also_agree = also_agree.."."
    end
    nomi.playername = StackPanel:New {
      centerItems = false,
      resizeItems = false;
      orientation = "horizontal";
      width = 200;
      height = 40;
      padding = {0, 0, 0, 0},
      itemMargin  = {5, 0, 0, 0},
      children = {
	Button:New {
	  width = "100%",
	  height = 40,
	  padding = {0, 0, 0, 0},
	  margin = {0, 0, 0, 0},
	  backgroundColor = {1, 1, 1, 0.4},
	  caption = name;
	  tooltip = "Press, if you agree with listed rules by "..name.."!"..also_agree;
	  textColor = name_color;
	  OnMouseDown = {function()
	      if (not Spring.GetSpectatingState()) then
		Spring.SendLuaRulesMsg("takeover_agree_with "..owner)
	      end
	    end
	  },
	  fontsize = 16;
	},
      }
    }
  else
    nomi.playername = StackPanel:New {
      centerItems = false,
      resizeItems = false;
      orientation = "horizontal";
      width = 200;
      height = 40;
      padding = {0, 0, 0, 0},
      itemMargin  = {5, 0, 0, 0},
      children = {
	Button:New {
	  width = "100%",
	  height = 40,
	  padding = {0, 0, 0, 0},
	  margin = {0, 0, 0, 0},
	  backgroundColor = {1, 1, 1, 0.4},
	  caption = name;
	  tooltip = "Press, if you agree with listed rules by "..name.."!";
	  textColor = name_color;
	  OnMouseDown = {function()
	    AnnounceMyChoice(DEFAULT_CHOICE)
	    end
	  },
	  fontsize = 16;
	},
      }
    }
  end
  nomi.votes = StackPanel:New {
    centerItems = false,
    resizeItems = false;
    orientation = "horizontal";
    width = 70;
    height = 40;
    padding = {0, 0, 0, 0},
    itemMargin  = {5, 0, 0, 0},
    children = {
      Label:New {
	autosize = false;
	align = "center";
	valign = "center";
	caption = nomi.vote_count.." vote"..((nomi.vote_count==1) and "" or "s");
	height = "100%",
	width = "100%";
	fontsize = 15;
      },
    }
  }
  nomi.pics[1] = Button:New {
    height = 40;
    width = 40;
    padding = {0, 0, 0, 0},
    margin = {0, 0, 0, 0},
    caption = "";
    tooltip = loc_tooltip_array[nomi.location+1];
    children = {
      Image:New {
	file = "unitpics/fakeunit.png";
	height = 40;
	width = 40;
	children = {
	  Label:New {
	    autosize = false;
	    align = "center";
	    valign = "center";
	    caption = loc_text;
	    height = 40,
	    width = 40;
	    fontsize = 11; -- so cost values are better? for now atleast...
	  };
	}
      }
    }
  };
  nomi.pics[2] = Button:New {
    height = 40;
    width = 40;
    padding = {0, 0, 0, 0},
    margin = {0, 0, 0, 0},
    caption = "";
    tooltip = UnitDefs[nomi.unit].humanName..".";
    children = {
      Image:New {
	file = "unitpics/"..UnitDefs[nomi.unit].name..".png";
	height = 40;
	width = 40;
      }
    }
  };
  nomi.pics[3] = Button:New {
    height = 40;
    width = 40;
    padding = {0, 0, 0, 0},
    margin = {0, 0, 0, 0},
    caption = "";
    tooltip = nomi.grace.." seconds.";
    children = {
      Image:New {
	file = "unitpics/fakeunit.png";
	height = 40;
	width = 40;
	children = {
	  Label:New {
	    autosize = false;
	    align = "center";
	    valign = "center";
	    caption = time_text;
	    height = 40,
	    width = 40;
	    fontsize = 14;
	    textColor = GetColorForDelay(nomi.grace);
	  }
	}
      }
    }
  };
  nomi.pics[4] = Button:New {
    height = 40;
    width = 40;
    padding = {0, 0, 0, 0},
    margin = {0, 0, 0, 0},
    caption = "";
    tooltip = god_tooltip_array[nomi.godmode+1];
    children = {
      Image:New {
	file = "unitpics/fakeunit.png";
	height = 40;
	width = 40;
	children = {
	  Label:New {
	    autosize = false;
	    align = "center";
	    valign = "center";
	    caption = god_text;
	    height = 40,
	    width = 40;
	    fontsize = 11; -- so cost values are better? for now atleast...
	    textColor = god_color;
	  }
	}
      }
    }
  };
  nomi.stack = StackPanel:New {
    y = 43*(nom-1);
    centerItems = false,
    resizeItems = false;
    orientation = "horizontal";
    width = "100%";
    height = 40;
    padding = {0, 0, 0, 0},
    itemMargin  = {5, 0, 0, 0},
    children = {
      nomi.playername, nomi.pics[1], nomi.pics[2], nomi.pics[3], nomi.pics[4], nomi.votes,
    }
  }
  if (owner == -1) then
    default_nomination = nomi.stack
    vote_scroll:AddChild(default_nomination);
  else
    if (default_nomination ~= nil) then
      vote_scroll:RemoveChild(default_nomination)
      default_nomination = nil
    end
    vote_scroll:AddChild(nomi.stack);
  end
end

local function UpdateMostPopularStack()
  local location, unit, grace, godmode, vote_count
  if (Spring.GetGameRulesParam("takeover_winner_votes") == nil) or (Spring.GetGameRulesParam("takeover_winner_owner") == -1) then
    location = DEFAULT_CHOICE[1]
    unit = DEFAULT_CHOICE[2]
    grace = DEFAULT_CHOICE[3]
    godmode = DEFAULT_CHOICE[4]
    vote_count = 0
  else
    location = Spring.GetGameRulesParam("takeover_winner_opts1")
    unit = Spring.GetGameRulesParam("takeover_winner_opts2")
    grace = Spring.GetGameRulesParam("takeover_winner_opts3")
    godmode = Spring.GetGameRulesParam("takeover_winner_opts4")
    vote_count = Spring.GetGameRulesParam("takeover_winner_votes")
  end
  results_label:SetCaption(vote_count.." votes:")
  for i=1,4 do
    results_stack:RemoveChild(results_elements[i])
  end
  if (Spring.GetGameRulesParam("takeover_winner_owner") ~= -2) then
    local loc_text = "center";
    if (location == 1) then
      loc_text = "spawn\n box";
    elseif (location == 2) then
      loc_text = "across\n  map";
    end
    local delay_minutes, delay_seconds, time_text = GetTimeFormatted(grace, false)
    local god_text = "mortal";
    local god_color = white;
    if (godmode == 1) then
      god_text = " semi-\nmortal";
      god_color = yellow;
    elseif (godmode == 2) then
      god_text = "god-\nlike";
      god_color = red
    end
    results_elements[1] = Button:New {
      height = 40;
      width = 40;
      padding = {0, 0, 0, 0},
      margin = {0, 0, 0, 0},
      caption = "";
      tooltip = loc_tooltip_array[location+1];
      children = {
	Image:New {
	  file = "unitpics/fakeunit.png";
	  height = 40;
	  width = 40;
	  children = {
	    Label:New {
	      autosize = false;
	      align = "center";
	      valign = "center";
	      caption = loc_text;
	      height = 40,
	      width = 40;
	      fontsize = 11; -- so cost values are better? for now atleast...
	    };
	  }
	}
      }
    };
    results_elements[2] = Button:New {
      height = 40;
      width = 40;
      padding = {0, 0, 0, 0},
      margin = {0, 0, 0, 0},
      caption = "";
      tooltip = UnitDefs[unit].humanName..".";
      children = {
	Image:New {
	  file = "unitpics/"..UnitDefs[unit].name..".png";
	  height = 40;
	  width = 40;
	}
      }
    };
    results_elements[3] = Button:New {
      height = 40;
      width = 40;
      padding = {0, 0, 0, 0},
      margin = {0, 0, 0, 0},
      caption = "";
      tooltip = grace.." seconds.";
      children = {
	Image:New {
	  file = "unitpics/fakeunit.png";
	  height = 40;
	  width = 40;	
	  children = {
	    Label:New {
	      autosize = false;
	      align = "center";
	      valign = "center";
	      caption = time_text;
	      height = 40,
	      width = 40;
	      fontsize = 14;
	      textColor = GetColorForDelay(grace);
	    }
	  }
	}
      }
    };
    results_elements[4] = Button:New {
      height = 40;
      width = 40;
      padding = {0, 0, 0, 0},
      margin = {0, 0, 0, 0},
      caption = "";
      tooltip = god_tooltip_array[godmode+1];
      children = {
	Image:New {
	  file = "unitpics/fakeunit.png";
	  height = 40;
	  width = 40;
	  children = {
	    Label:New {
	      autosize = false;
	      align = "center";
	      valign = "center";
	      caption = god_text;
	      height = 40,
	      width = 40;
	      fontsize = 11; -- so cost values are better? for now atleast...
	      textColor = god_color;
	    };
	  }
	}
      }
    };
  else
    for i=1,4 do
      results_elements[i] = Button:New {
	height = 40;
	width = 40;
	padding = {0, 0, 0, 0},
	margin = {0, 0, 0, 0},
	caption = "";
	tooltip = "Multiple nominations have same number of votes. Final decision is random among most voted ones.";
	children = {
	  Image:New {
	    file = "unitpics/fakeunit.png";
	    height = 40;
	    width = 40;
	    children = {
	      Label:New {
		autosize = false;
		align = "center";
		valign = "center";
		caption = "???";
		height = 40,
		width = 40;
		fontsize = 14;
	      }
	    }
	  }
	}
      };
    end
  end
  for i=1,4 do
    results_stack:AddChild(results_elements[i])
  end
end

local function ShowDefaultNomination()
  local location = DEFAULT_CHOICE[1]
  local unit = DEFAULT_CHOICE[2]
  local grace = DEFAULT_CHOICE[3]
  local godmode = DEFAULT_CHOICE[4]
  local vote_count = 0
  local nomi = { location = location, unit = unit, grace = grace, godmode = godmode, vote_count = vote_count, stack, playername, pics = {}, votes }
  local name = "DEFAULT_CHOICE"
  local name_color = white
  SetupNominationStack(nomi, name, name_color, -1, 1)
end

local function ParseNomination(nom) -- TODO need rewrite to make this perfect, not redraw all the entries all the time
  local owner = Spring.GetGameRulesParam("takeover_owner_nomination"..nom)
--   if (nominations[owner] ~= nil) then
--     vote_scroll:RemoveChild(nominations[owner].stack)
--   end
  local location = Spring.GetGameRulesParam("takeover_location_nomination"..nom)
  local unit = Spring.GetGameRulesParam("takeover_unit_nomination"..nom)
  local grace = Spring.GetGameRulesParam("takeover_grace_nomination"..nom)
  local godmode = Spring.GetGameRulesParam("takeover_godmode_nomination"..nom)
  local vote_count = Spring.GetGameRulesParam("takeover_votes_nomination"..nom)
  nominations[owner] = { location = location, unit = unit, grace = grace, godmode = godmode, vote_count = vote_count, stack, playername, pics = {}, votes }
  local name, _, _, teamID, allyTeam = Spring.GetPlayerInfo(owner)
  local name_color = cyan
  if (allyTeam ~= myAllyTeam) then
    name_color = red
  elseif (teamID ~= myTeam) then
    name_color = green
  end
  SetupNominationStack(nominations[owner], name, name_color, owner, nom)
end

local function UpdateNomListNOW()
  local noms = Spring.GetGameRulesParam("takeover_nominations")
  noms = noms and noms or 0
  if (noms == 0) and (default_nomination == true) then
    ShowDefaultNomination()
  end
--   for i=1, #nominations do
--     if (nominations[i]) then
--       vote_scroll:RemoveChild(nominations[i].stack)
--     end
--   end
  for i,d in pairs (nominations) do
    vote_scroll:RemoveChild(d.stack) -- TODO rewrite so it works without pairs
  end
  for i=1, noms do
    ParseNomination(i)
  end
end

local function SetupUnitStack(choice)
  my_choice[1] = choice;
  nominate_advice:SetCaption("2) Select TheUnit(s) type:");
  nominate_stack:RemoveChild(nominate_location);
  nominate_stack:AddChild(nominate_unit);
end

local function SetupGraceTime(choice)
  my_choice[2] = UnitDefNames[choice].id
  nominate_advice:SetCaption("3) Select TheUnit(s) grace timer:");
  nominate_stack:RemoveChild(nominate_unit);
  nominate_stack:AddChild(nominate_gracetime);  
end

local function SetupGodmode(choice)
  my_choice[3] = choice
  nominate_advice:SetCaption("4) Select TheUnit(s) immortality:");
  nominate_stack:RemoveChild(nominate_gracetime);
  nominate_stack:AddChild(nominate_godmode);  
end

local function NominateMyChoice(choice)
  my_choice[4] = choice
  nominate_stack:RemoveChild(nominate_godmode);
  nominate_stack:AddChild(nominate_location);
  screen0:RemoveChild(nominate_window);
  nominate_window = nil;
  -- NOTE if you abuse this widget and try to nominate something being a spectator, it will not work, also you can't nominate something again, while your option is being voted on
  AnnounceMyChoice(my_choice)
  screen0:AddChild(vote_window);
  UpdateNomListNOW()
end

local function SetupIngameStatusBar()
  status_window:RemoveChild(vote_menu_button)
  status_window:RemoveChild(welcome_text)
  status_window:RemoveChild(results_stack)
  status_window:RemoveChild(results_label)
  if (vote_window) then
    screen0:RemoveChild(vote_window)
    vote_window = nil
  end
  if (nominate_window) then
    screen0:RemoveChild(nominate_window)
    nominate_window = nil
    vote_window = nil
  end
  -- now lets make awesome stuff!
  help_button.right = nil;
  help_button.width = 60;
  help_button:SetPos(0,0)
  status_window:RemoveChild(help_button)
  -- lets draw!
  local timer_label = Label:New {
    autosize = false;
    width = 65;
    align = "center";
    height = 20;
    caption = "Timeleft:";
  }
  status_timeleft = Label:New {
    autosize = false;
    align = "center",
    width = 60;
    align = "center";
    height = 20;
    caption = "00:00";
    fontsize = 16;
  }
  status_ally = StackPanel:New {
    width = floor(status_window.width-90)/2;
    height = "100%";
    centerItems = false,
    resizeItems = false;
    orientation = "horizontal";
    padding = {0, 15, 0, 0},
    itemMargin  = {5, 0, 0, 0},
  }
  local timer_panel = StackPanel:New {
    width = 60;
    height = "100%";
    centerItems = false,
    resizeItems = false;
    orientation = "vertical";
    padding = {0, 5, 0, 0},
    itemMargin  = {0, 0, 0, 2},
    children = {
      timer_label,
      status_timeleft,
      help_button,
    }
  }
  status_enemy = StackPanel:New {
    width = floor(status_window.width-90)/2;
    height = "100%";
    centerItems = false,
    resizeItems = false;
    orientation = "horizontal";
    padding = {0, 15, 0, 0},
    itemMargin  = {5, 0, 0, 0},
  }
  local stack = StackPanel:New {
    width = "100%";
    height = "100%";
    centerItems = false,
    resizeItems = false;
    orientation = "horizontal";
    padding = {2, 5, 2, 5},
    itemMargin  = {5, 0, 0, 0},
    children = {
      status_ally,
      timer_panel,
      status_enemy,
    }
  }
  local label1 = Label:New {
    y = 4;
    autosize = false;
    width = 60;
    align = "center";
    height = 15;
    caption = "Allies:";
    right = "70%";
    textColor = green;
    fontsize = 10;
    --x = floor(status_ally.width/2);
  }
  local label2 = Label:New {
    y = 4;
    autosize = false;
    width = 60;
    align = "center";
    height = 15;
    caption = "Enemies:";
    right = "15%";
    textColor = red;
    fontsize = 10;
    --x = floor(status_ally.width/2+status_window.width/2);
  }
  status_window:AddChild(stack)
  status_window:AddChild(label1)
  status_window:AddChild(label2)
  TheUnitCount = Spring.GetGameRulesParam("takeover_units")
  TheUnitCount = TheUnitCount and TheUnitCount or 0
  local unit_type = Spring.GetGameRulesParam("takeover_winner_opts2")
  for i=1,TheUnitCount do
    status_units[i] = {
      alive = true,
      enemy = true,
      image = Image:New {
	file = "unitpics/"..UnitDefs[unit_type].name..".png";
	height = 40;
	width = 40;
      },
      button = Button:New {
	height = 40;
	width = 40;
	padding = {0, 0, 0, 0},
	margin = {0, 0, 0, 0},
	caption = "";
	tooltip = "Owner: noone.";
      },
      health = Progressbar:New {
	name    = "health"..i;
	width   = 40;
	height  = 7;
	max     = 25;
	value	= 25;
	itemMargin    = {0,0,0,0},
	itemPadding   = {0,0,0,0},	
	padding = {0,0,0,0},
	color   = {0.0,0.99,0.0,1};
      },
      emp = Progressbar:New {
	name    = "emp"..i;
	width   = 40;
	height  = 7;
	max     = 25;
	value   = 0;
	itemMargin    = {0,0,0,0},
	itemPadding   = {0,0,0,0},	
	padding = {0,0,0,0},
	color   = {0.60,0.60,0.90,1};
      },
      stack = StackPanel:New {
	width = 40;
	height = "100%";
	centerItems = false,
	resizeItems = false;
	orientation = "vertical";
	padding = {0, 0, 0, 0},
	itemMargin  = {0, 0, 0, 2},
      },
      dead = Label:New {
	autosize = false;
	width = 40;
	align = "center";
	valign = "center";
	height = 20;
	caption = "Lost";
	fontsize = 12;
	textColor = orange,
      },
    }
    status_units[i].button:AddChild(status_units[i].image)
    status_units[i].stack:AddChild(status_units[i].button)
    status_units[i].stack:AddChild(status_units[i].health)
    status_units[i].stack:AddChild(status_units[i].emp)
    status_enemy:AddChild(status_units[i].stack)
    under_siege[i] = 0
  end
  status_stage = 2
  
  -- what if widget was reload in game?
  for i=1,TheUnitCount do
    local unit = Spring.GetGameRulesParam("takeover_id_unit"..i)
    if ((unit > -1) and Spring.ValidUnitID(unit) and Spring.GetUnitPosition(unit)) then
      visible[unit] = true
    end
  end
end

local function GetPlayerName(owner,team,isAI)
  if team == GaiaTeamID then
    return "noone"
  elseif isAI then
    local _,aiName,_,shortName = Spring.GetAIInfo(team)
    -- FIXME i never tested it with AI, so i wonder what name will it get... lol
    return aiName; --.."["..team.."]"..'('.. shortName .. ')'
  else
    return select(1,Spring.GetPlayerInfo(owner));--.."["..team.."]"
  end
end

function widget:Update(s)
  timer = timer + s
  if timer > UPDATE_FREQUENCY then
    timer = 0
    local poll = Spring.GetGameRulesParam("takeover_vote")
    poll = poll and poll==1 or false
    if (poll ~= PollActive) then
      if (poll) then
	status_window:AddChild(vote_menu_button)
      elseif not GameStarted then
	SetupIngameStatusBar()
	GameStarted = true
      end
      PollActive = poll -- UNCOMMENT ME
--       PollActive = true -- DO NOT UNCOMMENT ME
    end
    if (poll) then
      if (vote_window) then
	--- TODO this needs small rewrite...
	local height = vote_window.height - 40;
	height = height>0 and height or 100
	vote_scroll.height = height
	vote_scroll:Invalidate();
	---
	UpdateMostPopularStack()
	UpdateNomListNOW()
      elseif (#nominations > 0) then
	nominations = {} -- empty the list because player closed window
      end
    end
  end
  timer_2 = timer_2 + s
  if timer_2 > UPDATE_FREQUENCY_2 then
    timer_2 = 0
    if (status_stage == 2) then -- TODO make it so if gadget is not active, the window quits ?
      status_ally.width = floor(status_window.width-90)/2
      status_ally:Invalidate();
      status_enemy.width = floor(status_window.width-90)/2
      status_enemy:Invalidate();
      local grace = Spring.GetGameRulesParam("takeover_timeleft")
      grace = grace and grace or 0
      local delay_minutes, delay_seconds, time_text = GetTimeFormatted(grace, true)
      status_timeleft:SetCaption(delay_minutes..":"..delay_seconds)
      if (grace > 0) then
	status_timeleft.font:SetColor(GetColorForDelay(grace))
      else
	status_timeleft.font:SetColor(green)
      end
      for i=1,TheUnitCount do
	local unit = Spring.GetGameRulesParam("takeover_id_unit"..i)
	local hp = Spring.GetGameRulesParam("takeover_hp_unit"..i, 0)
	if (unit > -1) and (hp > 0) then
	  local team = Spring.GetGameRulesParam("takeover_team_unit"..i, -1) -- could also rely on allyteam instead
	  local maxhp = Spring.GetGameRulesParam("takeover_maxhp_unit"..i, 1)
	  local emphp = Spring.GetGameRulesParam("takeover_emphp_unit"..i, 1)
	  local emp = Spring.GetGameRulesParam("takeover_emp_unit"..i, 0)
	  hp = math.round(hp/maxhp*25)
	  emp = math.round(emp/emphp*25) -- probably can be done better
	  local _,owner,_,isAI,_,allyTeam = Spring.GetTeamInfo(team)
	  local name = GetPlayerName(owner,team,isAI)
	  status_units[i].button.tooltip = "Owner "..name..".";
	  if (allyTeam == myAllyTeam) and (status_units[i].enemy) then
	    status_enemy:RemoveChild(status_units[i].stack);
	    status_ally:AddChild(status_units[i].stack);
	    status_units[i].enemy = false
	  elseif (allyTeam ~= myAllyTeam) and (not status_units[i].enemy) then
	    status_ally:RemoveChild(status_units[i].stack);
	    status_enemy:AddChild(status_units[i].stack);
	    status_units[i].enemy = true
	  end
	  status_units[i].health:SetValue(hp)
	  status_units[i].emp:SetValue(emp)
	  local siege = Spring.GetGameRulesParam("takeover_siege_unit"..i)
	  if (siege == 1) then
	    under_siege[i] = under_siege[i]+1;
	    if (under_siege[i] > 2) then
	      under_siege[i] = 1
	    end
	  else
	    under_siege[i] = 0;
	  end
	elseif (status_units[i].alive) then
	  --status_units[i].button:SetCaption("DEAD");
	  status_units[i].button.tooltip = "DEAD.";
	  status_units[i].stack:RemoveChild(status_units[i].health)
	  status_units[i].stack:RemoveChild(status_units[i].emp)
	  status_units[i].stack:AddChild(status_units[i].dead)
	  status_units[i].alive = false
	  visible[i] = false;
	  under_siege[i] = 0;
	end
      end
    end
  end
end

function widget:UnitEnteredLos(uID, tID)
  for i=1,TheUnitCount do
    local unit = Spring.GetGameRulesParam("takeover_id_unit"..i)
    if (unit > -1) and (unit == uID) then
      visible[uID] = true;
    end
  end
end

function widget:UnitLeftLos(uID)
  visible[uID] = false;
end

local function BuildVertexList(verts) -- this code was stolen from defence range widget
  local count =  #verts
  for i = 1, count do
    glVertex(verts[i])
  end
  if count > 0 then
    glVertex(verts[1])
  end
end

function GetRange2D( range, yDiff) -- this code was stolen from defence range widget
  local root1 = range * range - yDiff * yDiff
  if ( root1 < 0 ) then
    return 0
  else
    return sqrt( root1 )
  end
end

function FigureOutHowToDrawACyrcleYeahNiceIdea( x, y, z, range) -- this code was stolen from defence range widget
  local rangeLineStrip = {}
  local yGround = Spring.GetGroundHeight(x,z)
  for i = 1,40 do
    local radians = 2.0 * PI * i / 40
    local rad = range

    local sinR = sin( radians )
    local cosR = cos( radians )

    local posx = x + sinR * rad
    local posz = z + cosR * rad
    local posy = Spring.GetGroundHeight( posx, posz )

    local heightDiff = ( posy - yGround) / 2.0	-- maybe y has to be getGroundHeight(x,z) cause y is unit center and not aligned to ground

--     rad = rad - heightDiff * slope
    local adjRadius = GetRange2D( range, 0) --heightDiff * 0.0)
    local adjustment = rad / 2.0
    local yDiff = 0.0

    for j = 0, 49 do
      if ( abs( adjRadius - rad ) + yDiff <= 0.01 * rad ) then
	break
      end

      if ( adjRadius > rad ) then
	rad = rad + adjustment
      else
	rad = rad - adjustment
	adjustment = adjustment / 2.0
      end
      posx = x + ( sinR * rad )
      posz = z + ( cosR * rad )
      local newY = Spring.GetGroundHeight( posx, posz )
      yDiff = abs( posy - newY )
      posy = newY
      posy = max( posy, 0.0 )  --hack
      heightDiff = ( posy - yGround )	--maybe y has to be Ground(x,z)
      adjRadius = GetRange2D( range, heightDiff * 0.0)
    end

    posx = x + ( sinR * adjRadius )
    posz = z + ( cosR * adjRadius )
    posy = Spring.GetGroundHeight( posx, posz ) + 5.0
    posy = max( posy, 0.0 )   --hack
    
    table.insert( rangeLineStrip, { posx, posy, posz } )
  end
  return rangeLineStrip
end

local function DrawUnitOwner(unitID, color, name, rotation)
  glTranslate(0,UnitDefs[Spring.GetUnitDefID(unitID)].height + 26,0)
  glBillboard()
  glColor(color[1], color[2], color[3], 0.7)
  fontHandler.UseFont(overheadFont)
  fontHandler.DrawCentered(name, 0, 0)
  glColor(1,1,1,1)
end

function widget:DrawWorld()
  if not Spring.IsGUIHidden() then
    for i=1,TheUnitCount do
      local unit = Spring.GetGameRulesParam("takeover_id_unit"..i)
      if (unit > -1) and (visible[unit]) then
	local team = Spring.GetGameRulesParam("takeover_team_unit"..i)
	local allyteam = Spring.GetGameRulesParam("takeover_allyteam_unit"..i)
	if (Spring.ValidUnitID(unit)) then
	  local x,y,z = Spring.GetUnitPosition(unit)
	  local color = red
	  if (allyteam == myAllyTeam) then
	    if (team ~= myTeam) then
	      color = green
	    else
	      color = cyan
	    end
	  elseif (allyteam == GaiaAllyTeamID) then
	    color = white
	  end
	  if (under_siege[i] == 1) then
	    if (allyteam == myAllyTeam) then
	      color = yellow;
	    elseif (allyteam == GaiaAllyTeamID) then
	      color = green;
	    else
	      color = orange;
	    end
	  end
	  glDepthTest(true)
	  
	  glColor(color[1], color[2], color[3], 0.7)
	  glLineWidth(2.5)
	  glBeginEnd(GL_LINE_STRIP, BuildVertexList, FigureOutHowToDrawACyrcleYeahNiceIdea(x,y,z, CAPTURE_RANGE))
	  
	  local heading = Spring.GetUnitHeading(unit)
	  if heading then
	    local rot = (heading / 32768) * 180
	    local _,owner,_,isAI,_,allyTeam = Spring.GetTeamInfo(team)
	    local name = GetPlayerName(owner,team,isAI)
	    glDrawFuncAtUnit(unit, false, DrawUnitOwner, unit, color, name, rot)
	  end
	  
	  glDepthTest(false)
	end
      end
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  local takeovermode = (Spring.GetModOptions().zkmode) == "takeover"
  
  if (takeovermode == false) then
    widgetHandler:RemoveWidget()
    return
  end
  
  myAllyTeam = Spring.GetMyAllyTeamID()
  myTeam = Spring.GetMyTeamID()
  myPlayerID = Spring.GetMyPlayerID()
  
  -- setup Chili
  Chili = WG.Chili
  Button = Chili.Button
  Label = Chili.Label
  TextBox = Chili.TextBox
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
  local minWidth = 420;
  local minHeight = 90;
  local help_minWidth = 310;
  local help_minHeight = 360;
  local vote_minWidth = 500;
  local vote_minHeight = 380;
  local nominate_minWidth = 355;
  local nominate_minHeight = 410;
  
  help_title = Label:New {
    y = 10;
    autosize = false;
    width = "80%";
    align = "center";
    height = 30;
  }
  help_button = Button:New {
    width = 70,
    height = 30,
    padding = {0, 0, 0, 0},
    margin = {0, 0, 0, 0},
    y = "60%";
    right = "3%";
    backgroundColor = {1, 1, 1, 0.4},
    caption = "Help";
    tooltip = "General help.";
    OnMouseDown = {function()
      if not help_window then
	help_window = Window:New {
	  name = 'takeover_help_window';
	  color = {nil, nil, nil, 0.5},
	  width = help_minWidth;
	  height = help_minHeight;
	  x = screenWidth*0.6+help_minWidth/2;
	  y = screenHeight/4-help_minHeight/2;
	  dockable = true;
	  minimizable = false,
	  draggable = true,
	  resizable = false,
	  tweakDraggable = true,
	  tweakResizable = true,
	  padding = {0, 0, 0, 0},
	  minWidth = help_minWidth, 
	  minHeight = help_minHeight,
	  minimizable = false,
	  children = {
	    Button:New {
	      width = 70,
	      height = 30,
	      padding = {0, 0, 0, 0},
	      margin = {0, 0, 0, 0},
	      y = 10;
	      right = "5%";
	      backgroundColor = {1, 1, 1, 0.4},
	      caption = "Close";
	      OnMouseDown = {function()
		if help_window then
		  screen0:RemoveChild(help_window);
		  help_window = nil;
		end
	      end
	      }
	    },
	    help_title,
	    TextBox:New {
	      y = 35,
	      valign = "ascender",
	      lineSpacing = 0,
	      padding = { 15, 15, 15, 0 },
	      text = help_text;
	      height = 100;
	      width = "100%";
	      --fontsize = 13;
	    },
	  }
	}
	local r = random(0,3)
	if (r == 0) then
	  help_title:SetCaption("Knowledge is power!")
	  help_title.font:SetColor(red);
	elseif (r == 1) then
	  help_title:SetCaption("Guides are powerful!")
	  help_title.font:SetColor(green);
	elseif (r == 2) then
	  help_title:SetCaption("I appreciate reading!")
	  help_title.font:SetColor(yellow);
	else
	  help_title:SetCaption("Thanks for reading!")
	  help_title.font:SetColor(cyan);
	end
	screen0:AddChild(help_window);
      elseif help_window then
	screen0:RemoveChild(help_window);
	help_window = nil;
      end
    end
    }
  }
  results_label = Label:New {
    y = "40%";
    autosize = false;
    width = "55%";
    align = "center";
    height = 20;
    caption = "0 votes:";
    fontsize = 10;
    textColor = green;
  }
  results_stack = StackPanel:New {
    y = "52%";
    centerItems = true,
    resizeItems = false;
    orientation = "horizontal";
    width = "55%";
    height = 40;
    padding = {0, 0, 0, 0},
    itemMargin  = {5, 0, 0, 0},
  }
  for i=1,4 do
    results_elements[i] = Image:New {
      file   = "unitpics/fakeunit.png"; -- lol?
      height = 40;
      width = 40;
    }
  end
  UpdateMostPopularStack()
  vote_scroll = ScrollPanel:New{
    y = 40,
    width = "100%",
    height = 100,
    --height = "100%",
    borderColor = {1, 1, 1, 0},
    backgroundColor  = {0, 0, 0, 0},
    padding = {8, 15, 8, 10},
    --autosize = true,
    scrollbarSize = 6,
    horizontalScrollbar = false,
    hitTestAllowEmpty = true,
  }
  nominate_advice = Label:New {
    autosize = false;
    width = "100%";
    --align = "center";
    height = 20;
    caption = "Kudos to everyone!";
  }
  nominate_location = StackPanel:New {
    centerItems = false,
    resizeItems = false;
    orientation = "vertical";
    width = "100%";
    height = 100;
    padding = {0, 0, 0, 0},
    itemMargin  = {5, 0, 0, 0},
  }
  Button:New {
    parent = nominate_location;
    width = 250;
    height = 30;
    padding = {0, 0, 0, 0},
    margin = {0, 0, 0, 0},
    backgroundColor = {1, 1, 1, 0.4},
    caption = "Center of the map";
    tooltip = loc_tooltip_array[1];
    OnMouseDown = {function()
      SetupUnitStack(0);
    end
    }
  }
  Button:New {
    parent = nominate_location;
    width = 250;
    height = 30;
    padding = {0, 0, 0, 0},
    margin = {0, 0, 0, 0},
    backgroundColor = {1, 1, 1, 0.4},
    caption = "Player boxes";
    tooltip = loc_tooltip_array[2];
    OnMouseDown = {function()
      SetupUnitStack(1);
    end
    }
  }
  Button:New {
    parent = nominate_location;
    width = 250;
    height = 30;
    padding = {0, 0, 0, 0},
    margin = {0, 0, 0, 0},
    backgroundColor = {1, 1, 1, 0.4},
    caption = "3 points across the map";
    tooltip = loc_tooltip_array[3];
    OnMouseDown = {function()
      SetupUnitStack(2);
    end
    }
  }
  nominate_unit = StackPanel:New {
    centerItems = false,
    resizeItems = false;
    orientation = "horizontal";
    width = "100%";
    height = "100%";
    padding = {0, 0, 0, 0},
    itemMargin  = {5, 0, 0, 0},
  }
  for id,unit in pairs(UnitList) do
    nominate_unit_button[id] = Button:New {
      height = 56;
      width = 56;
      padding = {0, 0, 0, 0},
      margin = {0, 0, 0, 0},
      caption = "";
      tooltip = "Select "..UnitDefNames[unit].humanName.." as the unit(s) of choice.";
      OnMouseDown = {function()
	SetupGraceTime(unit)
      end},
      children={
	Image:New {
	file   = "unitpics/"..unit..".png"; -- lol?
	height = 56;
	width = 56;
	},
      },
    }
    nominate_unit:AddChild(nominate_unit_button[id]);
  end
  nominate_gracetime = StackPanel:New {
    centerItems = false,
    resizeItems = false;
    orientation = "horizontal";
    width = "100%";
    height = "100%";
    padding = {0, 0, 0, 0},
    itemMargin  = {5, 0, 0, 0},
  }
  for id,time in pairs(GraceList) do
    local delay_minutes = floor(time/60) -- TODO optimise this, this can be done lot better and faster
    local delay_seconds = time-delay_minutes*60
    local time_text = "   no\ndelay"
    if (time > 0) then
      if (0 == delay_seconds) and (delay_minutes > 0) then
	time_text = delay_minutes.."m"
      elseif (delay_minutes == 0) then
	time_text = delay_seconds.."s"
      else
	time_text = delay_minutes.."m\n"..delay_seconds.."s"
      end -- should be possible to do this much faster
    end
    nominate_grace_button[id] = Button:New {
      height = 56;
      width = 56;
      padding = {0, 0, 0, 0},
      margin = {0, 0, 0, 0},
      caption = "";
      tooltip = time.." seconds.";
      OnMouseDown = {function()
	SetupGodmode(time)
      end},
      children = {
	Image:New {
	  file   = "unitpics/fakeunit.png"; -- lol?
	  height = 56;
	  width = 56;
	  children = {
	    Label:New {
	      autosize = false;
	      align = "center";
	      valign = "center";
	      caption = time_text;
	      height = 56,
	      width = 56;
	      fontsize=18;
	      textColor = GetColorForDelay(time);
	    };
	  },
	}
      },
    }
    nominate_gracetime:AddChild(nominate_grace_button[id]);
  end
  nominate_godmode = StackPanel:New {
    centerItems = false,
    resizeItems = false;
    orientation = "vertical";
    width = "100%";
    height = "100%";
    padding = {0, 0, 0, 0},
    itemMargin  = {5, 0, 0, 0},
  }
  Button:New {
    parent = nominate_godmode;
    width = 250;
    height = 30;
    padding = {0, 0, 0, 0},
    margin = {0, 0, 0, 0},
    backgroundColor = {1, 1, 1, 0.4},
    caption = "Mortal";
    tooltip = god_tooltip_array[1];
    OnMouseDown = {function()
      NominateMyChoice(0);
    end
    }
  }
  Button:New {
    parent = nominate_godmode;
    width = 250;
    height = 30;
    padding = {0, 0, 0, 0},
    margin = {0, 0, 0, 0},
    backgroundColor = {1, 1, 1, 0.4},
    caption = "Immortal while emped or grace period";
    tooltip = god_tooltip_array[2];
    OnMouseDown = {function()
      NominateMyChoice(1);
    end
    }
  }
  Button:New {
    parent = nominate_godmode;
    width = 250;
    height = 30;
    padding = {0, 0, 0, 0},
    margin = {0, 0, 0, 0},
    backgroundColor = {1, 1, 1, 0.4},
    caption = "Full immortality, when hp <= 10%";
    tooltip = god_tooltip_array[3];
    OnMouseDown = {function()
      NominateMyChoice(2);
    end
    }
  }
  nominate_stack = StackPanel:New {
    x=0; y=40;
    centerItems = false,
    resizeItems = false;
    orientation = "vertical";
    width = "100%";
    height = "100%";
--     backgroundColor = {1, 0, 0, 0.5},
    padding = {5, 5, 5, 5},
    itemMargin  = {5, 0, 0, 0},
    children = {
      nominate_advice,
      nominate_location,
    }
  }
  vote_menu_button = Button:New {
    width = 90,
    height = 30,
    padding = {0, 0, 0, 0},
    margin = {0, 0, 0, 0},
    y = "60%";
    right = "22%";
    backgroundColor = {1, 1, 1, 0.4},
    caption = "Vote menu";
    tooltip = "Click to bring up the vote menu, you may change the game mode's rules, before the match began.";
    OnMouseDown = {function()
      if not nominate_window then -- NOTE if nominate window is open, i can't reopen vote window, will probably change this is future.
	if not vote_window then
	  vote_window = Window:New {
	    name = 'takeover_vote_window';
	    color = {nil, nil, nil, 0.5},
	    width = vote_minWidth;
	    height = vote_minHeight;
	    x = screenWidth/2-vote_minWidth/2;
	    y = screenHeight/2-vote_minHeight/2;
	    dockable = true;
	    minimizable = false,
	    draggable = true,
	    resizable = false,
	    tweakDraggable = true,
	    tweakResizable = true,
	    padding = {0, 0, 0, 0},
	    minWidth = vote_minWidth, 
	    minHeight = vote_minHeight,
	    minimizable = false,
	    children = {
	      Button:New {
		width = 70,
		height = 30,
		padding = {0, 0, 0, 0},
		margin = {0, 0, 0, 0},
		y = 10;
		right = "5%";
		backgroundColor = {1, 1, 1, 0.4},
		caption = "Close";
		OnMouseDown = {function()
		  if vote_window then
		    screen0:RemoveChild(vote_window);
		    vote_window = nil;
		  end
		end
		}
	      },
	      Button:New {
		width = 75,
		height = 30,
		padding = {0, 0, 0, 0},
		margin = {0, 0, 0, 0},
		y = 10;
		x = "5%";
		backgroundColor = {1, 1, 1, 0.4},
		caption = "Nominate";
		tooltip = "Nominate a new set of rules, if you don't agree with any of listed ones. Spectators can't nominate rules!";
		-- NOTE the basic idea is that this menu minimises the nomination menu, yet it doesn't dispose of it!
		OnMouseDown = {function()
		  if (not nominate_window) and (not Spring.GetSpectatingState()) then
		    nominate_window = Window:New {
		      name = 'takeover_nominate_window';
		      color = {nil, nil, nil, 0.5},
		      width = nominate_minWidth;
		      height = nominate_minHeight;
		      x = screenWidth*0.25-nominate_minWidth/2;
		      y = screenHeight/2-nominate_minHeight/2;
		      dockable = true;
		      minimizable = false,
		      draggable = true,
		      resizable = false,
		      tweakDraggable = true,
		      tweakResizable = true,
		      padding = {0, 0, 0, 0},
		      minWidth = nominate_minWidth, 
		      minHeight = nominate_minHeight,
		      minimizable = false,
		      children = {
			Button:New {
			  width = 70,
			  height = 30,
			  padding = {0, 0, 0, 0},
			  margin = {0, 0, 0, 0},
			  y = 10;
			  right = "5%";
			  backgroundColor = {1, 1, 1, 0.4},
			  caption = "Close";
			  tooltip = "Close and go back to nominate window,";
			  OnMouseDown = {function()
			    if nominate_window then
			      screen0:AddChild(vote_window);
			      UpdateNomListNOW();
			      screen0:RemoveChild(nominate_window);
			      nominate_window = nil;
			    end
			  end
			  }
			},
			Label:New {
			  y = 5;
			  autosize = false;
			  width = "70%";
			  align = "center";
			  height = 30;
			  caption = "Click on the buttons, only 4 steps.\nPay attention what you choose.";
			},
			nominate_stack,
		      }
		    }
		    nominate_advice:SetCaption("1) Choose TheUnit(s) starting location:")
		    screen0:AddChild(nominate_window);
		    if vote_window then
		      screen0:RemoveChild(vote_window);
		    end
		  elseif nominate_window then
		    screen0:RemoveChild(nominate_window);
		    nominate_window = nil;
		  end
		end
		}
	      },
	      Label:New {
		y = 15;
		autosize = false;
		width = "100%";
		align = "center";
		height = 20;
		caption = "Vote for options or nominate a new rules set!";
	      },
	      Label:New {
		y = 35;
		autosize = false;
		width = "100%";
		align = "center";
		height = 20;
		caption = "Hover over icons to get their description, click on the player name with the most satisfying rules.";
		fontsize = 10;
	      },
	      vote_scroll,
	    },
	  }	  
	  screen0:AddChild(vote_window);
	  UpdateNomListNOW();
	elseif vote_window then
	  screen0:RemoveChild(vote_window);
	  vote_window = nil;
	end
      end
    end
    }
  }
  if not Spring.GetSpectatingState() then
  end
  welcome_text = Label:New {
    autosize = false;
    width = "100%";
    align = "center";
    height = 40;
    caption = "We welcome you to our new game mode! The Takeover "..version.."!\nPress \"Vote menu\" to vote for game mode rules.";
  }
  status_window = Window:New {
    name = 'takeover_status_window';
    color = {nil, nil, nil, 0.5},
    width = minWidth;
    height = minHeight;
    x = screenWidth/2-minWidth/2;
    y = screenHeight/5-minHeight/2;
    dockable = true;
    minimizable = true,
    draggable = true,
    resizable = false,
    tweakDraggable = true,
    tweakResizable = true,
    padding = {0, 0, 0, 0},
    minWidth = minWidth, 
    minHeight = minHeight,
    children = {
      welcome_text,
      results_label,
      results_stack,
      help_button,
    }
  }
  screen0:AddChild(status_window)
end

function widget:Shutdown()
  if (status_window) then
    status_window:Dispose()
  end
  if (vote_window) then
    vote_window:Dispose()
  end
  if (nominate_window) then
    nominate_window:Dispose()
  end
  if (help_window) then
    help_window:Dispose()
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------