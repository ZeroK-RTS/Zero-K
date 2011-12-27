--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Vote Display",
    desc      = "GUI for votes",
    author    = "KingRaptor",
    date      = "May 04, 2008",
    license   = "GNU GPL, v2 or later",
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
local TextBox
local Image
local Progressbar
local Control
local Font

-- elements
local window, stack_main, label_title
local stack_vote, label_vote, button_vote, progress_vote = {}, {}, {}, {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local voteCount, voteMax = {}, {}
local pollActive = false

local string_success = " vote successful"
local string_fail = " not enough votes"
local string_vote1 = " option 1 has "
local string_vote2 = " option 2 has "
local string_votetopic = " Do you want to "
local string_endvote = " poll cancelled"
local string_titleEnd = "? !vote 1 = yes, !vote 2 = no"

local springieName = Spring.GetModOptions().springiename or ''

local voteAntiSpam = false
local VOTE_SPAM_DELAY = 1	--seconds

--[[
local index_votesHave = 14
local index_checkDoubleDigits = 17
local index_votesNeeded = 18
local index_voteTitle = 15
]]--

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function GetVotes(line)
	local voteNum = 1
	if line:find(string_vote2) then
		voteNum = 2
	end
	local index_init = line:find("%s"..voteNum.."%s")
	local index_votesHave = line:find("%s%d[%s%d]", index_init + 1)
	local index_votesNeeded = line:find("%s%d[%s%d]", index_votesHave + 1)
	--Spring.Echo(index_init, index_votesHave, index_votesNeeded)
	local numVotes = tonumber(line:sub(index_votesHave, index_votesHave + 2))
	local maxVotes = tonumber(line:sub(index_votesNeeded, index_votesNeeded + 2))
	voteCount[voteNum] = numVotes
	for i=1, 2 do
		voteMax[i] = maxVotes
		progress_vote[i]:SetCaption(voteCount[i]..'/'..voteMax[i])
		progress_vote[i]:SetValue(voteCount[i]/voteMax[i])
	end
end

function widget:AddConsoleLine(line,priority)
	if line:sub(1,springieName:len()) ~= springieName then	-- no spoofing messages
		return
	end
	if line:find(string_success) or line:find(string_fail) or line:find(string_endvote) then	--terminate existing vote
		pollActive = false
		screen0:RemoveChild(window)
		for i=1,2 do
			voteCount[i] = 0
			voteMax[i] = 1	-- protection against div0
			progress_vote[i]:SetCaption('?/?')
			progress_vote[i]:SetValue(0)
		end
	elseif line:find(string_votetopic) and line:find(string_titleEnd) then	--start new vote
		pollActive = true
		screen0:AddChild(window)
		local indexStart = select(2, line:find(string_votetopic))
		local indexEnd = line:find(string_titleEnd)
		local title = line:sub(indexStart, indexEnd - 1)
		label_title:SetCaption("Poll: "..title)
	elseif line:find(string_vote1) or line:find(string_vote2) then	--apply a vote
		GetVotes(line)
	end
end

local timer = 0
function widget:Update(dt)
	if not voteAntiSpam then
		return
	end
	timer = timer + dt
	if timer < VOTE_SPAM_DELAY then
		return
	end
	voteAntiSpam = false
	timer = 0
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Colorbars = Chili.Colorbars
	Window = Chili.Window
	StackPanel = Chili.StackPanel
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	Control = Chili.Control
	screen0 = Chili.Screen0
	
	--create main Chili elements
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	local height = tostring(math.floor(screenWidth/screenHeight*0.35*0.35*100)) .. "%"
	local y = tostring(math.floor((1-screenWidth/screenHeight*0.35*0.35)*100)) .. "%"
	
	local labelHeight = 24
	local fontSize = 16

	window = Window:New{
		--parent = screen0,
		name   = 'votes';
		color = {0, 0, 0, 0},
		width = 300;
		height = 120;
		right = 2; 
		y = "45%";
		dockable = false;
		draggable = true,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minWidth = MIN_WIDTH, 
		minHeight = MIN_HEIGHT,
		padding = {0, 0, 0, 0},
		--itemMargin  = {0, 0, 0, 0},
	}
	stack_main = StackPanel:New{
		parent = window,
		resizeItems = true;
		orientation   = "vertical";
		height = "100%";
		width =  "100%";
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
	}
	label_title = Label:New{
		parent = stack_main,
		autosize=false;
		align="center";
		valign="top";
		caption = '';
		height = 16,
		width = "100%";
	}
	for i=1,2 do
		stack_vote[i] = StackPanel:New{
			parent = stack_main,
			resizeItems = true;
			orientation   = "horizontal";
			y = (40*(i-1))+15 ..'%',
			height = "40%";
			width =  "100%";
			padding = {0, 0, 0, 0},
			itemMargin  = {0, 0, 0, 0},
		}
		--[[
		label_vote[i] = Label:New{
			parent = stack_vote[i],
			autosize=false;
			align="left";
			valign="center";
			caption = (i==1) and 'Yes' or 'No',
			height = 16,
			width = "100%";
		}
		]]--
		progress_vote[i] = Progressbar:New{
			parent = stack_vote[i],
			x		= "0%",
			width   = "80%";
			height	= "100%",
			max     = 1;
			caption = "?/?";
			color   = (i == 1 and {0.2,0.9,0.3,1}) or {0.9,0.15,0.2,1};
		}
		button_vote[i] = Button:New{
			parent = stack_vote[i],
			x = "80%",
			width = "20%",
			height = "100%",
			caption = (i==1) and 'Yes' or 'No',
			OnMouseDown = {	function () 
					if voteAntiSpam then
						return
					end
					Spring.SendCommands({'say !vote '..i})
					voteAntiSpam = true
				end},
			padding = {1,1,1,1},
			--keepAspect = true,
		}
		progress_vote[i]:SetValue(0)
		voteCount[i] = 0
		voteMax[i] = 1	-- protection against div0		
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

