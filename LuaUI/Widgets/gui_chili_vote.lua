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
--//version +0.3;
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
local button_end, button_end_image

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local voteCount, voteMax = {}, {}
local pollActive = false
local votingForceStart = false

local string_success = "END:SUCCESS"
local string_fail = "END:FAILED"
local string_vote = {"!y=", "!n="}
local string_titleStart = "Poll: "
local string_endvote = " poll cancelled"
local string_titleEnd = "?"
local string_noVote = "There is no poll going on, start some first"

local springieName = Spring.GetModOptions().springiename or ''

--local voteAntiSpam = false
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
	for i=1, 2 do
		local index_init = line:find(string_vote[i])
		local index_votesHave = line:find("%d[%d/]", index_init)
		local index_votesHaveEnd = line:find("/", index_votesHave) - 1
		local index_votesNeeded = index_votesHaveEnd + 2
		local index_votesNeededEnd = ( line:find("[,]", index_votesNeeded) or line:find("\]", index_votesNeeded) ) - 1
		
		--Spring.Echo(index_votesHave, index_votesHaveEnd, index_votesNeeded, index_votesNeededEnd)
		--Spring.Echo(line:sub(index_votesHave, index_votesHaveEnd))
		--Spring.Echo(line:sub(index_votesNeeded, index_votesNeededEnd))
		
		local numVotes = tonumber(line:sub(index_votesHave, index_votesHaveEnd))
		local maxVotes = tonumber(line:sub(index_votesNeeded, index_votesNeededEnd))
		voteCount[i] = numVotes
		voteMax[i] = maxVotes
		progress_vote[i]:SetCaption(voteCount[i]..'/'..voteMax[i])
		progress_vote[i]:SetValue(voteCount[i]/voteMax[i])
	end
end

local lastClickTimestamp = 0
local function CheckForVoteSpam (currentTime) --// function return "true" if not a voteSpam
	local elapsedTimeFromLastClick = currentTime - lastClickTimestamp
	if elapsedTimeFromLastClick < VOTE_SPAM_DELAY then
		return false
	else
		lastClickTimestamp= currentTime
		return true
	end
end

local function RemoveWindow()
	pollActive = false
	screen0:RemoveChild(window)
	for i=1,2 do
		voteCount[i] = 0
		voteMax[i] = 1	-- protection against div0
		--progress_vote[i]:SetCaption('?/?')
		progress_vote[i]:SetValue(0)
	end
end

function widget:AddConsoleLine(line,priority)
	if votingForceStart and line:sub(1,7) == "GameID:" then
		RemoveWindow()
		votingForceStart = false
	end
	if line:sub(1,springieName:len()) ~= springieName then	-- no spoofing messages
		return false
	end
	if line:find(string_success) or line:find(string_fail) or line:find(string_endvote) or line:find(string_noVote) then	--terminate existing vote
		RemoveWindow()
		votingForceStart = false
	elseif line:find(string_titleStart) and line:find(string_vote[1]) and line:find(string_vote[2]) then	--start new vote
		--if pollActive then --//close previous windows in case Springie started a new vote without terminating the last one.
		--	RemoveWindow()
		--	votingForceStart = false
		--end
		if not pollActive then
			pollActive = true
			screen0:AddChild(window)
		end
		local indexStart = select(2, line:find(string_titleStart))
		local indexEnd = line:find(string_titleEnd)
		local title = line:sub(indexStart, indexEnd - 1)
		votingForceStart = ((title:find("force game"))~=nil)
		label_title:SetCaption("Poll: "..title)
	--elseif line:find(string_vote1) or line:find(string_vote2) then	--apply a vote
		GetVotes(line)
	end
	return false
end

--[[
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
--]]
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
					--if voteAntiSpam then return end
					--voteAntiSpam = true
					local notSpam = CheckForVoteSpam (os.clock())
					if notSpam then
						Spring.SendCommands({'say !vote '..i})
					end
				end},
			padding = {1,1,1,1},
			--keepAspect = true,
		}
		progress_vote[i]:SetValue(0)
		voteCount[i] = 0
		voteMax[i] = 1	-- protection against div0
	end
	button_end = Button:New {
		width = 20,
		height = 20,
		y = 0,
		right = 0,
		parent=window;
		padding = {0, 0, 0,0},
		margin = {0, 0, 0, 0},
		backgroundColor = {1, 1, 1, 0.4},
		caption="";
		tooltip = "End vote (requires server admin)";
		OnMouseDown = {function() 
				--if voteAntiSpam then return end
				--voteAntiSpam = true
				local notSpam = CheckForVoteSpam (os.clock())
					if notSpam then
					Spring.SendCommands("say !endvote")
				end
			end}
	}
	button_end_image = Image:New {
		width = 16,
		height = 16,
		x = 2,
		y = 2,
		keepAspect = false,
		file = "LuaUI/Images/closex_16.png";
		parent = button_end;
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

