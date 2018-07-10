--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili SpecPanel - Next Gen",
    desc      = "Displays team information while spectating.",
    author    = "GoogleFrog, KingRaptor, Anarchid, Shadowfury333, CrazyEddie",
    date      = "3 June 2017",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- TODO:
--
-- Layout:
--	- Tweak the layout - reduce space usage, ensure labels are wide enough,
--		reposition labels, etc
--	- Deal with padding in all the objects (??)
--	- Experiment with making the balance bars multibars
--		- Stack the two sides on top of each other
--		- Set the leader to 100%
--		- Set the lagger whatever percentage they are of the leader
--
-- Appearance:
--	- Reskin the panels so they look more like Evolved panels (but transparent) and less like buttons
--	- Add an interesting glowy thing behind the wins counter for the winner of the last game
--	- Make more bg screenshots
--	- Add flashing to resbars, including:
--		- Grey on metal excess - see #1960
--			- Fast if excessing, slow if close to excessing
--			- Match implementation in gui_chili_economy_panel2.lua
--			- ... and also if wasting E? (but not if close to wasting)
--		- Red on energy stalling
--		- ... and some kind of indication for zero storage (but what?)
--
-- UI:
--	- Colourblind option
--	- Fancy skinning option? Learn about skins and fancyskins
--	- Add tooltips to everything.
--		"What do you mean, everything?"
--		"EEEEEVVVERYTHIIIING!!!!!!"
--	- Add context menu / ShowOptions on meta-click
--	- Consider making small / medium / large versions
--	- When PR is merged, decide on a enable/disable hotkey and put it in zk_keys
--
-- Data:
--	- Find out what the right magic formula is for the energy stats
--	- Add an iteration on initialization to get current unit data, even if
--		the widget was restarted midway through a game
--	- Stop collecting stats at game over, prior to the losing side self-destroying,
--		so you can see what the stats were just before they resigned.
--	- Revise wins logic to update at end of game instead of all throughout the game
--	- Properly account for units not destroyed by the enemy in attrition (maybe?)
--
-- Code clean-up:
--	- Alias overlong table chains
--	- Rearrange bounds in this order: x,r,w,y,b,h
--	- Rewrite the bounds to be the simplest possible
--		- ... and make sure that there's explicitly exactly two in each dimension
--	- Rearrange all other object parameters into a consistent and pleasing order
--	- Consistentize capitalization of parameters
--	- Look for any other text that needs autosize = false (all of it?)
--	- Add nil guards where needed, remove them where unnecessary
--	- Make the unitpic frames and labels children of the pic, to make it simpler
--		- Look for other objects that can be nested that way that aren't already
--	- Wait, I can specify the buildpic filename as "#" .. udid ??? - Go change the others, too.
--
--	- Lots more code general clean-up, organization, and prettification
--
-- See also other assorted TODO items annotated throughout the code
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("colors.h.lua")
VFS.Include("LuaRules/Configs/constants.lua")
local GetRawBoxes = VFS.Include("LuaUI/Headers/startbox_utilities.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local echo = Spring.Echo
local spGetTeamResources = Spring.GetTeamResources
local spGetTeamRulesParam = Spring.GetTeamRulesParam

local Chili
local screen0

local specPanel
local panelSetupParams
local panelSetupData
local allyTeams
local panel_is_on
local restore_ecopanelhs
local gaiaTeam
local deadUnits = {}
local teamSides = {}
local timer_updateclock = 0
local timer_updatestats = 0
local smoothTables = {}
local smoothedTables = {
	resources_left = {0,0,0,0,0,0,0,0,0,0,0,0,},
	resources_right = {0,0,0,0,0,0,0,0,0,0,0,0,},
}

local SpecPanelStartStop
local didonce

-- This is probably getting refactored away
local unitStats = {
	{
		total = 0,
		lost = 0,
		offense = 0,
		defense = 0,
		eco = 0,
		units = {},
		cons = {
			count = 0,
			udids = {},
		},
		comms = {},
		factory = "default",
	},
	{
		total = 0,
		lost = 0,
		offense = 0,
		defense = 0,
		eco = 0,
		units = {},
		cons = {
			count = 0,
			udids = {},
		},
		comms = {},
		factory = "default",
	},
}

local unitCategoryExceptions = {}
local uce_names = {
	offense = {
		-- Superweapons are not mobile but are considered offense
		-- Antinuke is a super but it's not included here
		"staticmissilesilo",
		"staticarty",
		"staticheavyarty",
		"staticnuke",
		"zenith",
		"raveparty",
		"mahlazer",
		
		-- Some unarmed units are typically part of an offensive force
		-- so we'll go ahead and include them in the offense totals
		"cloakjammer",
		"shieldshield",
		"gunshiptrans",
		"amphtele",
		
		-- TODO - Not sure if the crawling bombs are armed. If not, add them here.
	},
	defense = {
	},
	eco = {
	},
	other = {
		-- Freaker and Welder are armed and mobile but are not considered offense
		"jumpcon",
		"tankcon",
	},
}
for cat_name,cat in pairs (uce_names) do
	unitCategoryExceptions[cat_name] = {}
	for i = 1, #cat do
		local ud = UnitDefNames[cat[i]]
		if ud and ud.id then
			unitCategoryExceptions[cat_name][ud.id] = true
		end
	end
end

-- From LuaRules/Configs/start_setup.lua
local ploppableDefs = {}
local ploppables = {
	"factoryhover",
	"factoryveh",
	"factorytank",
	"factoryshield",
	"factorycloak",
	"factoryamph",
	"factoryjump",
	"factoryspider",
	"factoryship",
	"factoryplane",
	"factorygunship",
}
for i = 1, #ploppables do
	local ud = UnitDefNames[ploppables[i]]
	if ud and ud.id then
		ploppableDefs[ud.id ] = true
	end
end

local col_metal = {136/255,214/255,251/255,1}
local col_energy = {.93,.93,0,1}
local default_playercolors = { cold = {0.5,0.5,1,1}, hot = {1,0.2,0.2,1}, }
local smooth_count = 3
local unitpic_slots = 5
local compic_slots = 3

-- hardcoding these for now, will add colourblind options later
local positiveColourStr = GreenStr
local negativeColourStr = RedStr


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Options Functions


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Options

options_path = 'Settings/HUD Panels/Spectator Panel NG'

options_order = {
	'enableSpecNG',
}
 
options = {
	enableSpecNG = {
		name  = "Enable as Spec NG",
		type  = "bool",
		value = true,
		OnChange = function(self)
			SpecPanelStartStop()
		end,
		desc = "Enables the spectator resource bars when spectating a game with two teams."
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function pack(...)
	return { n = select("#", ...), ... }
end

local function Smooth(tablename, data)
	local output_table = {}
	smoothTables[tablename] = smoothTables[tablename] or {}
	for i,v in ipairs(data) do
		smoothTables[tablename][i] = smoothTables[tablename][i] or {}
		table.insert(smoothTables[tablename][i], v)
		if #smoothTables[tablename][i] > smooth_count then
			table.remove(smoothTables[tablename][i], 1)
		end
		local sum = 0
		for j,w in ipairs(smoothTables[tablename][i]) do
			sum = sum + w
		end
		output_table[i] = sum / #smoothTables[tablename][i]
	end
	return unpack(output_table)
end

local function Format(input, override)

	-- Leaving out the sign to save space.
	-- For this panel, the direction is always implied
	-- and will still be colorcoded when needed.
	--
	-- local leadingString = positiveColourStr .. "+"
	local leadingString = positiveColourStr
	if input < 0 then
		-- leadingString = negativeColourStr .. "-"
		leadingString = negativeColourStr
	end
	leadingString = override or leadingString
	input = math.abs(input)
	
	if input < 0.05 then
		if override then
			-- Nope. Don't want a decimal point.
			-- return override .. "0.0"
			return override .. "0"
		end
		return WhiteStr .. "0"
	elseif input < 10 - 0.05 then
		-- Nope. Don't want a decimal point.
		-- return leadingString .. ("%.1f"):format(input) .. WhiteStr
		return leadingString .. ("%.0f"):format(input) .. WhiteStr
	elseif input < 10^3 - 0.5 then
		return leadingString .. ("%.0f"):format(input) .. WhiteStr
	elseif input < 10^4 then
		return leadingString .. ("%.1f"):format(input/1000) .. "k" .. WhiteStr
	elseif input < 10^5 then
		return leadingString .. ("%.0f"):format(input/1000) .. "k" .. WhiteStr
	else
		return leadingString .. ("%.0f"):format(input/1000) .. "k" .. WhiteStr
	end
end

local function GetTimeString()
  local secs = math.floor(Spring.GetGameSeconds())
  if (timeSecs ~= secs) then
    timeSecs = secs
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = math.floor(secs % 60)
    if (h > 0) then
      timeString = string.format('%02i:%02i:%02i', h, m, s)
    else
      timeString = string.format('%02i:%02i', m, s)
    end
  end
  return timeString
end

function GetWinString(name)
	local winTable = WG.WinCounter_currentWinTable
	if winTable and winTable[name] and winTable[name].wins then
		-- TODO - Do something else to mark the winner of the previous game, not this
		-- return (winTable[name].wonLastGame and "*" or "") .. winTable[name].wins
		return winTable[name].wins
	end
	return
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Update Panel Data

local function UpdateClock(t)
	t.clocklabel:SetCaption(GetTimeString())
end

local function UpdateWins(t)
	for i,side in ipairs({'left', 'right'}) do
		local wins = GetWinString(allyTeams[i].name) or 0
		t[side].winslabel_bottom:SetCaption(wins)
	end
end

local function DisplayPlayerData(t)
	for i,side in ipairs({'left', 'right'}) do
		t[side].playerlabel:SetCaption(allyTeams[i].name)
	end
end

local function FetchUpdatedResources()
	-- The energy stats seem wrong.
	-- They were taken from the current spec panels. I've probably translated them
	-- incorrectly, but what I have here gives results that seem very wrong.
	--
	-- For example: Generation 62, Reclaim 0, OD 9 => Income 71.
	-- 	Surely in this case Income should be 53, yes? Showing that
	--	9 of the 62 energy generated was used to produce metal and
	--	therefore was not available to use as energy.
	--
	-- This warrants further investigation.
	
	for i,side in ipairs({'left', 'right'}) do
		local smCurr, smStor, smInco, smOvdr, smRecl, smBase, seCurr, seStor, seInco, seOvdr, seRecl, seBase = 0,0,0,0,0,0,0,0,0,0,0,0
		local allyTeamID = allyTeams[i].allyTeamID
		local teams = Spring.GetTeamList(allyTeamID)
	
		for j = 1, #teams do
			local mCurr, mStor, _, mInco = spGetTeamResources(teams[j], "metal")
			local eCurr, eStor, _, eInco = spGetTeamResources(teams[j], "energy")
		
			smInco = smInco + (mInco or 0)
			smBase = smBase + (spGetTeamRulesParam(teams[j], "OD_metalBase") or 0)
		
			-- Strange magic
			smCurr = smCurr + (mCurr or 0)
			smStor = smStor + (mStor or 0) - HIDDEN_STORAGE
			seCurr = seCurr + math.min((eCurr or 0), (eStor or 0) - HIDDEN_STORAGE)
			seStor = seStor + (eStor or 0) - HIDDEN_STORAGE 
		
			-- WITCHCRAFT!!
			local energyChange = spGetTeamRulesParam(teams[j], "OD_energyChange") or 0
			seRecl = seRecl + (eInco or 0) - math.max(0, energyChange)
			seBase = seBase + (eInco or 0)
		end

		smOvdr = spGetTeamRulesParam(teams[1], "OD_team_metalOverdrive") or 0
		seOvdr = spGetTeamRulesParam(teams[1], "OD_team_energyOverdrive") or 0

		local smRecl = smInco
				- (spGetTeamRulesParam(teams[1], "OD_team_metalOverdrive") or 0)
				- (spGetTeamRulesParam(teams[1], "OD_team_metalBase") or 0) 
				- (spGetTeamRulesParam(teams[1], "OD_team_metalMisc") or 0)
	
		-- The other half of the incantation
		seRecl = math.max(0, seRecl)
		seInco = (spGetTeamRulesParam(teams[1], "OD_team_energyIncome") or 0) + seRecl
		
		smoothedTables['resources_'..side] = pack(
			Smooth(
				'resources_'..side,
				pack(smCurr, smStor, smInco, smOvdr, smRecl, smBase, seCurr, seStor, seInco, seOvdr, seRecl, seBase)
			)
		)
	end
end

local function DisplayResources(t)
	local mInco_bb = {}
	local mBase_bb = {}
	for i,side in ipairs({'left', 'right'}) do
		local smCurr, smStor, smInco, smOvdr, smRecl, smBase, seCurr, seStor, seInco, seOvdr, seRecl, seBase = unpack(smoothedTables['resources_'..side])
		t[side].resource_stats.metal.total:SetCaption(Format(smInco, ""))
		t[side].resource_stats.metal.labels[1]:SetCaption("E:" .. Format(smBase, ""))
		t[side].resource_stats.metal.labels[2]:SetCaption("R:" .. Format(smRecl, ""))
		t[side].resource_stats.metal.labels[3]:SetCaption("O:" .. Format(smOvdr, ""))
		t[side].resource_stats.metal.bar:SetValue(100 * smCurr / smStor)
		t[side].resource_stats.energy.total:SetCaption(Format(seInco, ""))
		t[side].resource_stats.energy.labels[1]:SetCaption("G:" .. Format(seBase, ""))
		t[side].resource_stats.energy.labels[2]:SetCaption("R:" .. Format(seRecl, ""))
		t[side].resource_stats.energy.labels[3]:SetCaption("O:" .. Format(seOvdr, ""))
		t[side].resource_stats.energy.bar:SetValue(100 * seCurr / seStor)
		-- TODO - Deal with the case of zero storage
		mInco_bb[side] = smInco
		mBase_bb[side] = smBase
	end
	local income = (mInco_bb.left == mInco_bb.right) and 50 or 100 * mInco_bb.left / (mInco_bb.left + mInco_bb.right)
	local base   = (mBase_bb.left == mBase_bb.right) and 50 or 100 * mBase_bb.left / (mBase_bb.left + mBase_bb.right)
	t.balancebars[1].bar:SetValue(income)
	t.balancebars[2].bar:SetValue(base)
end

local function DisplayUnitStats(t)
	local military_bb = {}
	for i,side in ipairs({'left', 'right'}) do
		t[side].unit_stats.total:SetCaption("Unit Value: " .. Format(unitStats[i].total, ""))
		t[side].unit_stats[1].label:SetCaption(Format(unitStats[i].offense, ""))
		t[side].unit_stats[2].label:SetCaption(Format(unitStats[i].defense, ""))
		t[side].unit_stats[3].label:SetCaption(Format(unitStats[i].eco, ""))
		military_bb[side] = unitStats[i].offense + unitStats[i].defense
		
		local filename = 'LuaUI/Images/specpanel_ng/' .. unitStats[i].factory .. '_' .. side .. '.png'
		t[side].bg_image.file = filename
		t[side].bg_image:Show()
		t[side].bg_image:SendToBack()
		t[side].bg_image:Invalidate()
		
		-- These two are parallel enough that I might want to refactor them,
		--	possibly using a generic iterator function that takes sort functions
		--
		local sorted_udids = {}
		for n in pairs(unitStats[i].units) do table.insert(sorted_udids, n) end
		if #sorted_udids > 0 then
			table.sort(sorted_udids, function (a,b) return unitStats[i].units[a].metal > unitStats[i].units[b].metal end)
			for pic = 1, unitpic_slots - 1 do
				local text = sorted_udids[pic] and unitStats[i].units[sorted_udids[pic]].count or ''
				local filename = sorted_udids[pic] and UnitDefs[sorted_udids[pic]].name or 'fakeunit'
				t[side].unitpics[unitpic_slots - pic + 1].text:SetCaption(text)
				t[side].unitpics[unitpic_slots - pic + 1].unitpic.file = 'unitpics/' .. filename .. '.png'
				t[side].unitpics[unitpic_slots - pic + 1].unitpic:Invalidate()
			end
		end
		
		-- Nearly the same as the one above
		--
		local sorted_con_udids = {}
		for n in pairs(unitStats[i].cons.udids) do table.insert(sorted_con_udids, n) end
		if #sorted_con_udids > 0 then
			table.sort(sorted_con_udids, function (a,b) return unitStats[i].cons.udids[a].metal > unitStats[i].cons.udids[b].metal end)
			for pic = 1,1 do
				local text = unitStats[i].cons.count or ''
				local filename = sorted_con_udids[pic] and UnitDefs[sorted_con_udids[pic]].name or 'fakeunit'
				t[side].unitpics[pic].text:SetCaption(text)
				t[side].unitpics[pic].unitpic.file = 'unitpics/' .. filename .. '.png'
				t[side].unitpics[pic].unitpic:Invalidate()
			end
		end

		-- Ditto?
		--
		local sorted_comm_ids = {}
		for n in pairs(unitStats[i].comms) do table.insert(sorted_comm_ids, n) end
		if #sorted_comm_ids > 0 then
			table.sort(sorted_comm_ids, function (a,b) return unitStats[i].comms[a].level > unitStats[i].comms[b].level end)
		end
		for pic = 1,compic_slots do
			-- TODO - OMG CLEAN THIS GARBAGE UP
			if pic == 1 then
				if #sorted_comm_ids > 0 then
					if #sorted_comm_ids > compic_slots then
						local text = ("Lvl " .. unitStats[i].comms[sorted_comm_ids[compic_slots]].level) or ''
						local filename = ("#" .. unitStats[i].comms[sorted_comm_ids[compic_slots]].udid) or 'unitpics/fakeunit.png'
						local moretext = (#sorted_comm_ids - compic_slots) .. " more"
						t[side].compics[pic].unitpicframe:Show()
						t[side].compics[pic].unitpicframe:BringToFront()
						t[side].compics[pic].unitpic.file = filename
						t[side].compics[pic].unitpic:Show()
						t[side].compics[pic].unitpic:BringToFront()
						t[side].compics[pic].unitpic:Invalidate()
						t[side].compics[pic].text:SetCaption(text)
						t[side].compics[pic].text:Show()
						t[side].compics[pic].text:BringToFront()
						t[side].compics[pic].moretext:SetCaption(moretext)
						t[side].compics[pic].moretext:Show()
						t[side].compics[pic].moretext:BringToFront()
					else
						local text = ("Lvl " .. unitStats[i].comms[sorted_comm_ids[#sorted_comm_ids]].level) or ''
						local filename = ("#" .. unitStats[i].comms[sorted_comm_ids[#sorted_comm_ids]].udid) or 'unitpics/fakeunit.png'
						t[side].compics[pic].unitpicframe:Show()
						t[side].compics[pic].unitpicframe:BringToFront()
						t[side].compics[pic].unitpic.file = filename
						t[side].compics[pic].unitpic:Show()
						t[side].compics[pic].unitpic:BringToFront()
						t[side].compics[pic].unitpic:Invalidate()
						t[side].compics[pic].text:SetCaption(text)
						t[side].compics[pic].text:Show()
						t[side].compics[pic].text:BringToFront()
					end
				else
					local text = ''
					local filename = 'unitpics/fakeunit.png'
					t[side].compics[pic].unitpicframe:Hide()
					t[side].compics[pic].unitpic.file = filename
					t[side].compics[pic].unitpic:Invalidate()
					t[side].compics[pic].unitpic:Hide()
					t[side].compics[pic].text:SetCaption(text)
					t[side].compics[pic].text:Hide()
					t[side].compics[pic].moretext:SetCaption(text)
					t[side].compics[pic].moretext:Hide()
				end
			else
				if pic <= #sorted_comm_ids then
					local text = ("Lvl " .. unitStats[i].comms[sorted_comm_ids[math.min(compic_slots, #sorted_comm_ids) - pic + 1]].level) or ''
					local filename = ("#" .. unitStats[i].comms[sorted_comm_ids[math.min(compic_slots, #sorted_comm_ids) - pic + 1]].udid) or 'unitpics/fakeunit.png'
					t[side].compics[pic].unitpicframe:Show()
					t[side].compics[pic].unitpicframe:BringToFront()
					t[side].compics[pic].unitpic.file = filename
					t[side].compics[pic].unitpic:Show()
					t[side].compics[pic].unitpic:BringToFront()
					t[side].compics[pic].unitpic:Invalidate()
					t[side].compics[pic].text:SetCaption(text)
					t[side].compics[pic].text:Show()
					t[side].compics[pic].text:BringToFront()
				else
					local text = ''
					local filename = 'unitpics/fakeunit.png'
					t[side].compics[pic].unitpicframe:Hide()
					t[side].compics[pic].unitpic.file = filename
					t[side].compics[pic].unitpic:Invalidate()
					t[side].compics[pic].unitpic:Hide()
					t[side].compics[pic].text:SetCaption(text)
					t[side].compics[pic].text:Hide()
				end
			end
		end
	end
	local military  = (military_bb.left  == military_bb.right) and 50 or 100 * military_bb.left / (military_bb.left + military_bb.right)
	local attrition = (unitStats[1].lost == unitStats[2].lost) and 50 or 100 * unitStats[2].lost / (unitStats[1].lost + unitStats[2].lost)
	t.balancebars[3].bar:SetValue(military)
	t.balancebars[4].bar:SetValue(attrition)
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Stats Call-ins and Processor

local function ProcessUnit(unitID, unitDefID, unitTeam, remove)
	if not panel_is_on then return end
	
	local side = teamSides[unitTeam]
	local id = unitID
	local udid = unitDefID
	local ud = UnitDefs[unitDefID]
	local cp = ud.customParams
	local e = unitCategoryExceptions

	if ud and not (cp.dontcount or cp.is_drone) then

		-- TODO - Not certain these are the right ways to get this information
		--
		local metal = Spring.Utilities.GetUnitCost(unitID, unitDefID)
		local level = (Spring.GetUnitRulesParam(unitID, "comm_level") or 0) + 1
		local mobile = ud.speed and ud.speed ~= 0
		local armed = not ud.springCategories.unarmed
		local generator = cp.income_energy or cp.ismex or cp.windgen
		local comm = ud.customParams.commtype
		local con = ud.isMobileBuilder and not comm
		local startfac = ploppableDefs[udid]

		local offense
		local defense
		local eco
		local other
		
		local inc = 1
		if remove then
			metal = -metal
			inc = -inc
		end
		
		unitStats[side].total = unitStats[side].total + metal
		if e.offense[udid] or (armed and mobile and not e.defense[udid] and not e.eco[udid] and not e.other[udid]) then
			offense = true
			unitStats[side].offense = unitStats[side].offense + metal
		elseif e.defense[udid] or (armed and not mobile and not e.eco[udid] and not e.other[udid]) then
			defense = true
			unitStats[side].defense = unitStats[side].defense + metal
		elseif e.eco[udid] or (not mobile and generator and not e.other[udid]) then
			eco = true
			unitStats[side].eco = unitStats[side].eco + metal
		else
			other = true
		end
		
		if offense and not (con or comm) then
			unitStats[side].units[udid] = unitStats[side].units[udid] or {}
			unitStats[side].units[udid].count = (unitStats[side].units[udid].count or 0) + inc
			unitStats[side].units[udid].metal = (unitStats[side].units[udid].metal or 0) + metal
			if unitStats[side].units[udid].count == 0 then
				unitStats[side].units[udid] = nil
			end
		end
		
		if con then
			unitStats[side].cons.count = unitStats[side].cons.count + inc
			unitStats[side].cons.udids[udid] = unitStats[side].cons.udids[udid] or {}
			unitStats[side].cons.udids[udid].count = (unitStats[side].cons.udids[udid].count or 0) + inc
			unitStats[side].cons.udids[udid].metal = (unitStats[side].cons.udids[udid].metal or 0) + metal
			if unitStats[side].cons.udids[udid].count == 0 then
				unitStats[side].cons.udids[udid] = nil
			end
		end
		
		if comm then
			if remove then
				unitStats[side].comms[id] = nil
			else
				unitStats[side].comms[id] = unitStats[side].comms[id] or {}
				unitStats[side].comms[id].udid = udid or 0
				unitStats[side].comms[id].level = level or 0
			end
		end
		
		if startfac and allyTeams[side].playercount == 1 and unitStats[side].factory == "default" then
			unitStats[side].factory = ud.name
		end
	end
end


function widget:UnitFinished(unitID, unitDefID, unitTeam)
	ProcessUnit(unitID, unitDefID, unitTeam)
end

function widget:UnitReverseBuilt(unitID, unitDefID, unitTeam)
	ProcessUnit(unitID, unitDefID, unitTeam, true)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam, attUnitID, attDefID, attTeamID)	
	
	-- TODO - What about units destroyed by environmental damage, or by Gaia?
	--        As it stands, that will be credited as attrition by the enemy.
	--        That may, in fact, be the right thing to do.
	
	if not panel_is_on then return end
	
	if unitTeam == gaiaTeam or Spring.GetUnitHealth(unitID) > 0 then return end

	-- in spec mode UnitDestroyed would sometimes be called twice for the same unit, so we need to prevent it from counting twice
	-- if its also the same kind of unit, its safe to assume that it is the very same unit
	-- else it is most likely not the same unit but an old table entry and a re-used unitID. we just keep the entry
	-- small margin of error remains
	if deadUnits[unitID] and deadUnits[unitID] == unitDefID then
		deadUnits[unitID] = nil
		return 		
	end
	deadUnits[unitID] = unitDefID

	local ud = UnitDefs[unitDefID]
	if ud.customParams.dontcount or ud.customParams.is_drone then return end

	-- besides processing the unit to update unit counts etc,
	-- we also need to update the lost totals for the attrition counter
	-- but only credit it with a partial kill if it was a partially-built unit
	local buildProgress = select(5, Spring.GetUnitHealth(unitID))
	local worth = Spring.Utilities.GetUnitCost(unitID, unitDefID) * buildProgress
	local side = teamSides[unitTeam]
	unitStats[side].lost = unitStats[side].lost + worth
	
	-- don't process the unit (i.e. decrement its unit count and metal value) if it wasn't finished being built
	-- because if it wasn't finished being built then its unit count and metal value were never incremented
	if buildProgress < 1 then return end

	-- once we've passed the double-destroy check, the dontcount check, the drone check,
	-- and the not-partial-unit check, THEN we can call ProcessUnit
	ProcessUnit(unitID, unitDefID, unitTeam, true)
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	ProcessUnit(unitID, unitDefID, teamID, true)
	ProcessUnit(unitID, unitDefID, newTeamID)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Setup Data

local function GetOpposingAllyTeams()
	-- TODO - Consider whether this should set up the file-scoped allyTeams directly
	--        rather than returning the data it as a value to be stored by the caller

	local allyteams = {}
	local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID()))
	local allyTeamList = Spring.GetAllyTeamList()

	for i = 1, #allyTeamList do
		local allyTeamID = allyTeamList[i]
		local teamList = Spring.GetTeamList(allyTeamID)
		if allyTeamID ~= gaiaAllyTeamID and #teamList > 0 then

			local winString
			local playerName
			for j = 1, #teamList do
				local _, playerID, _, isAI = Spring.GetTeamInfo(teamList[j])
				if not isAI then
					playerName = Spring.GetPlayerInfo(playerID)
					winString = GetWinString(playerName)
					break
				end
			end
			
			-- TODO - This is not a good way to do this
			--        Merge this with the loop immediately above, and handle them both better
			for j = 1, #teamList do
				teamSides[teamList[j]] = #allyteams+1
			end

			local name = Spring.GetGameRulesParam("allyteam_long_name_" .. allyTeamID) or "Unknown"
			-- Hardcode the long_name length limit, don't make it an option
			-- TODO - Figure out what the limit should be
			-- if name and string.len(name) > options.clanNameLengthCutoff.value then
			-- 	name = Spring.GetGameRulesParam("allyteam_short_name_" .. allyTeamID) or name
			-- end
			
			local startboxid, rawBoxes, startbox
			local xpos, ypos = 0, 0
			startboxid = Spring.GetTeamRulesParam(teamList[1], "start_box_id") or 0			
			rawBoxes = GetRawBoxes()
			if rawBoxes then
				startbox = rawBoxes[startboxid]
				if startbox then
					xpos = startbox.startpoints[1][1]
					ypos = startbox.startpoints[1][2]
				end
			end
			
			allyteams[#allyteams + 1] = {
				allyTeamID = allyTeamID, -- allyTeamID for the team
				name = name, -- Large display name of the team
				color = {Spring.GetTeamColor(teamList[1])} or {1,1,1,1}, -- color of the teams text (color of first player)
				playerName = playerName or "AI", -- representitive player name (for win counter)
				winString = winString or "0", -- Win string from win counter
				playercount = #teamList,
				startboxid = startboxid,
				xpos = xpos,
				ypos = ypos,
			}
		end
	end

	if #allyteams ~= 2 then
		return
	end
	
	if (allyteams[1].xpos - allyteams[2].xpos) + ((allyteams[1].ypos - allyteams[2].ypos) * 0.2) > 0 then
		allyteams[1], allyteams[2] = allyteams[2], allyteams[1]
		for k,v in pairs(teamSides) do
			teamSides[k] = 3 - v
		end
	end
	
	if allyteams[1].playercount > 1 or allyteams[2].playercount > 1 then
		local myAlly = Spring.GetMyAllyTeamID()
		if myAlly == allyteams[1].allyTeamID then
			allyteams[1].color = default_playercolors.cold
			allyteams[2].color = default_playercolors.hot
		else
			allyteams[1].color = default_playercolors.hot
			allyteams[2].color = default_playercolors.cold
		end
	end
	
	-- TODO - This doesn't belong here
	for i, side in ipairs({'left', 'right'}) do
		if allyteams[i].playercount > 4 then
			unitStats[i].factory = "largeteams"
		elseif allyteams[i].playercount > 1 then
			unitStats[i].factory = "default"
		else
			unitStats[i].factory = "default"
		end
	end
	
	return allyteams
end

local function GetPanelSetupData()
	local d = {}
	d.playercolors = { left = allyTeams[1].color, right = allyTeams[2].color, }
	d.resources = {
		{
			type = 'metal',
			icon = 'LuaUI/Images/ibeam.png',
			color = col_metal,
			{ name = "Extraction", label = "E", label_x = 65, },
			{ name = "Reclaim", label = "R", label_x = 110, },
			{ name = "Overdrive", label = "O", label_x = 150, },
		},
		{
			type = 'energy',
			icon = 'LuaUI/Images/energy.png',
			color = col_energy,
			{ name = "Generation", label = "G", label_x = 65, },
			{ name = "Reclaim", label = "R", label_x = 110, },
			{ name = "Overdrive", label = "O", label_x = 150, },
		},
	}
	d.unit_stats = {
		{ name = "Offense", icon = 'LuaUI/Images/commands/Bold/attack.png', icon_x = 0, },
		{ name = "Defense", icon = 'LuaUI/Images/commands/Bold/guard.png', icon_x = 50, },
		{ name = "Economy", icon = 'LuaUI/Images/energy.png', icon_x = 100, },
	}
	d.balancebars = {
		{ name = "Income", },
		{ name = "Extraction", },
		{ name = "Military", },
		{ name = "Attrition", },
	}
	return d
end

local function GetPanelSetupParams()
	local p = {}

	p.topcenterwidth = 200
	p.balancepanelwidth = 80
	
	p.balancelabelheight = 20
	p.balancebarheight = 10
	p.balanceheight = p.balancelabelheight + p.balancebarheight
	p.balancepanelheight = p.balanceheight * 4 + 5
	
	p.rowheight = 30
	p.topheight = p.rowheight * 1.5
	p.picsize = p.rowheight * 1.8
	
	p.unitpanelwidth = 150
	p.resourcebarwidth = 100
	p.resourcestatpanelwidth = 200
	p.resourcepanelwidth = p.resourcestatpanelwidth + p.resourcebarwidth
	
	p.screenWidth,p.screenHeight = Spring.GetWindowGeometry()
	p.screenHorizCentre = p.screenWidth / 2
	p.windowWidth = (p.resourcepanelwidth + p.unitpanelwidth) * 2 + p.balancepanelwidth + 24
	p.windowheight = p.topheight + p.balancepanelheight
	p.playerlabelwidth = (p.windowWidth - p.topcenterwidth) / 2
	
	return p
end

local function InitializeUnitStats()
	-- TODO - Iterate through the units to populate unit counts.
	--	This is needed when the spec panel is started midway
	--	through the game, either because a player resigned and
	--	started spectating or the panel was toggled off and on
	--	or luaui was reloaded.
	--
	--	Alas, the attrition counter will still have to start from
	--	scratch, at least until I incorporate Sprunk's new gadget-based
	--	attrition tracking.
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Create Panels

local function AddCenterPanels(t, p, d)
	-- 	t == table of panels; new panels will be added
	-- 	p == parameters to build layout
	-- 	d == data to populate panels
	
	t.window = Chili.Panel:New{
		classname = 'main_window',
		name = "SpecPanel",
		preserveChildrenOrder = true,
		padding = {0,0,0,0},
		x = p.screenHorizCentre - p.windowWidth/2,
		y = 0,
		clientWidth  = p.windowWidth,
		clientHeight = p.windowheight,
	}

	t.topcenterpanel = Chili.Panel:New{
		parent = t.window,
		classname = 'main_window_small',
		padding = {5,5,5,5},
		x = (p.windowWidth - p.topcenterwidth)/2,
		width = p.topcenterwidth,
		height = p.topheight,
		dockable = false;
		draggable = false,
		resizable = false,
	}
	t.clocklabel = Chili.Label:New{
		parent = t.topcenterpanel,
		padding = {0,0,0,0},
		width = '100%',
		height = '100%',
		align = 'center',
		valign = 'center',
		autosize = false,
		fontsize = 24,
		textColor = {0.95, 1.0, 1.0, 1},
		caption = GetTimeString(),
	}
	
	t.balancepanel = Chili.Panel:New{
		parent = t.window,
		classname = 'main_window_small',
		padding = {0,0,0,0},
		x = (p.windowWidth - p.balancepanelwidth)/2,
		y = p.topheight,
		width = p.balancepanelwidth,
		height = p.balancepanelheight,
	}
	t.balancebars = {}
	for i,bar in ipairs(d.balancebars) do
		t.balancebars[i] = {}
		t.balancebars[i].label = Chili.Label:New{
			parent = t.balancepanel,
			y = p.balanceheight * (i-1) + 4,
			width = '100%',
			height = 15,
			autosize = false,
			caption = bar.name,
			align = 'center',
		}
		t.balancebars[i].bar = Chili.Progressbar:New{
			parent = t.balancepanel,
			orientation = 'horizontal',
			x = '15%',
			y = p.balanceheight * (i-1) + p.balancelabelheight,
			width = '70%',
			height = p.balancebarheight,
			color = d.playercolors['left'],
			backgroundColor = {1,0,0,0},
		}
		t.balancebars[i].bar_bg = Chili.Progressbar:New{
			parent = t.balancepanel,
			orientation = 'horizontal',
			value = 100,
			x = '15%',
			y = p.balanceheight * (i-1) + p.balancelabelheight,
			width = '70%',
			height = p.balancebarheight,
			color = d.playercolors['right'],
		}
	end
	
end

local function AddSidePanels(t, p, d, side)
	-- 	t == table of panels; new panels will be added
	-- 	p == parameters to build layout
	-- 	d == data to populate panels

	local x, right
	if side == 'left' then
		x = "x"
		right = "right"
	elseif side == 'right' then
		x = "right"
		right = "x"
	else
		return
	end
	
	t[side] = t[side] or {}
	local ts = t[side]
	
	ts.winslabel_top = Chili.Label:New{
		parent = t.topcenterpanel,
		padding = {0,0,0,0},
		[x] = 0,
		y = '5%',
		width = 50,
		height = '30%',
		autosize = false,
		align = 'center',
		valign = 'center',
		textColor = d.playercolors[side],
		caption = "Wins:",
	}
	ts.winslabel_bottom = Chili.Label:New{
		parent = t.topcenterpanel,
		padding = {0,0,0,0},
		[x] = 0,
		y = '30%',
		width = 50,
		height = '70%',
		autosize = false,
		align = 'center',
		valign = 'center',
		fontsize = 20,
		textColor = d.playercolors[side],
	}

	ts.playerlabel = Chili.Label:New{
		parent = t.window,
		padding = {0,0,0,0},
		[right] = (p.windowWidth + p.topcenterwidth)/2,
		width = p.playerlabelwidth,
		height = p.topheight,
		align = 'center',
		valign = 'center',
		autosize = false,
		textColor = d.playercolors[side],
		fontsize = 28,
		fontShadow = true,
		fontOutline = false,
	}
	
	ts.resource_stats = {}
	for i,resource in ipairs(d.resources) do
		local restype = resource.type
		ts.resource_stats[restype] = {}
		local r = ts.resource_stats[restype]
		r.panel = Chili.Panel:New{
			parent = t.window,
			y = p.topheight + p.rowheight * (i-1),
			[right] = (p.windowWidth + p.balancepanelwidth)/2 + p.unitpanelwidth,
			width = p.resourcepanelwidth,
			height = p.rowheight,
			skin = nil,
			skinName = 'default',
			backgroundColor = {0,0,0,0},
			borderColor = {1,1,1,1},
			borderThickness = 1,
		}
		r.barpanel = Chili.Control:New{
			parent = r.panel,
			padding = {0,0,0,0},
			y = 0,
			right = 0,
			width = p.resourcebarwidth,
			height = '100%',
		}
		r.bar = Chili.Progressbar:New{
			parent = r.barpanel,
			padding = {0,0,0,0},
			x = '5%',
			y = '10%',
			height = '80%',
			right = '0%',
			color = resource.color,
		}
		r.statpanel = Chili.Control:New{
			parent = r.panel,
			padding = {0,0,0,0},
			x = 0,
			y = 0,
			width = p.resourcestatpanelwidth,
			height = '100%',
		}
		r.total = Chili.Label:New{
			parent = r.statpanel,
			x = 18,
			height = '100%',
			width = 35,
			autosize = false,
			valign = 'center',
			fontsize = 20,
			textColor = resource.color,
		}
		r.icon = Chili.Image:New{
			parent = r.statpanel,
			x = 0,
			height = 18,
			width = 18,
			file = resource.icon,
		}
		r.labels = {}
		for j,stat in ipairs(resource) do
			local color, shadow, outline
			if i == 2 and j == 3 then
				color = {1,0.3,0.3,1}
				shadow = false
				outline = true
			else
				color = resource.color
				shadow = true
				outline = false
			end
			r.labels[j] = Chili.Label:New{
				parent = r.statpanel,
				x = stat.label_x,
				height = '100%',
				width = 50,
				valign = 'center',
				autosize = false,
				textColor = color,
				fontShadow = shadow,
				fontOutline = outline,
			}
		end
	end
	
	ts.unitpanel = Chili.Panel:New{
		parent = t.window,
		y = p.topheight,
		[right] = (p.windowWidth + p.balancepanelwidth)/2,
		height = p.rowheight * 2,
		width = p.unitpanelwidth,
		skin = nil,
		skinName = 'default',
		backgroundColor = {0,0,0,0},
		borderColor = {1,1,1,1},
		borderThickness = 1,
	}
	ts.unit_stats = {}
	ts.unit_stats.total = Chili.Label:New{
		parent = ts.unitpanel,
		[x] = 0,
		height = '50%',
		width = '100%',
		align = 'center',
		valign = 'center',
		autosize = false,
		fontsize = 16,
		textColor = { 0.85, 0.85, 0.85, 1.0 },
	}
	for i,stat in ipairs(d.unit_stats) do
		ts.unit_stats[i] = {}
		ts.unit_stats[i].icon = Chili.Image:New{
			parent = ts.unitpanel,
			x = stat.icon_x,
			y = '60%',
			height = 18,
			width = 18,
			file = stat.icon,
		}
		ts.unit_stats[i].label = Chili.Label:New{
			parent = ts.unitpanel,
			x = stat.icon_x + 18,
			y = '50%',
			height = '50%',
			width = 20,
			valign = 'center',
			textColor = { 0.7, 0.7, 0.7, 1.0 },
		}
	end
	
	ts.unitpics = {}
	for i = 1,unitpic_slots do
		ts.unitpics[i] = {}
		ts.unitpics[i].text = Chili.Label:New{
			parent = t.window,
			y = p.topheight + p.rowheight * 2 + 5,
			[right] = (p.windowWidth + p.balancepanelwidth)/2 + p.picsize * (i-1) + 5,
			height = p.picsize - 10,
			width = p.picsize - 10,
			autosize = false,
			align = 'right',
			valign = 'bottom',
			fontsize = 16,
			caption = '',
		}
		ts.unitpics[i].unitpic = Chili.Image:New{
			parent = t.window,
			y = p.topheight + p.rowheight * 2,
			[right] = (p.windowWidth + p.balancepanelwidth)/2 + p.picsize * (i-1),
			height = p.picsize,
			width = p.picsize,
			file = 'unitpics/fakeunit.png',
		}
		local framepic
		if i == 1 then
			framepic = 'bitmaps/icons/frame_cons.png'
		else
			framepic = 'bitmaps/icons/frame_unit.png'
		end
		ts.unitpics[i].unitpicframe = Chili.Image:New{
			parent = t.window,
			y = p.topheight + p.rowheight * 2,
			[right] = (p.windowWidth + p.balancepanelwidth)/2 + p.picsize * (i-1),
			height = p.picsize,
			width = p.picsize,
			keepAspect = false,
			file = framepic,
		}
	end
	
	ts.compics = {}
	for i = 1,compic_slots do
		ts.compics[i] = {}
		if i == 1 then
			ts.compics[i].moretext = Chili.Label:New{
				parent = t.window,
				y = p.topheight + p.rowheight * 2 + 5,
				[right] = (p.windowWidth + p.balancepanelwidth)/2 + p.picsize * (i-1) + p.picsize * unitpic_slots,
				height = p.picsize - 10,
				width = p.picsize - 10,
				autosize = false,
				align = 'center',
				valign = 'center',
				textColor = col_energy,
				caption = '',
			}
			ts.compics[i].moretext:Hide()
		end
		ts.compics[i].text = Chili.Label:New{
			parent = t.window,
			y = p.topheight + p.rowheight * 2 + 5,
			[right] = (p.windowWidth + p.balancepanelwidth)/2 + p.picsize * (i-1) + p.picsize * unitpic_slots,
			height = p.picsize - 10,
			width = p.picsize - 10,
			autosize = false,
			align = 'right',
			valign = 'bottom',
			caption = '',
		}
		ts.compics[i].unitpic = Chili.Image:New{
			parent = t.window,
			y = p.topheight + p.rowheight * 2,
			[right] = (p.windowWidth + p.balancepanelwidth)/2 + p.picsize * (i-1) + p.picsize * unitpic_slots,
			height = p.picsize,
			width = p.picsize,
			file = 'unitpics/fakeunit.png',
		}
		local framepic = 'bitmaps/icons/frame_unit.png'
		ts.compics[i].unitpicframe = Chili.Image:New{
			parent = t.window,
			y = p.topheight + p.rowheight * 2,
			[right] = (p.windowWidth + p.balancepanelwidth)/2 + p.picsize * (i-1) + p.picsize * unitpic_slots,
			height = p.picsize,
			width = p.picsize,
			keepAspect = false,
			file = framepic,
		}
		ts.compics[i].text:Hide()
		ts.compics[i].unitpic:Hide()
		ts.compics[i].unitpicframe:Hide()
	end
	
	ts.bg_top = Chili.Panel:New{
		parent = t.window,
		[x] = 12,
		y = 0,
		width  = (p.windowWidth - 24) / 2,
		height = p.topheight,
		skin = nil,
		skinName = 'default',
		backgroundColor = {0,0,0,0.2},
		borderColor = {0,0,0,0},
	}
	ts.bg_bottom = Chili.Panel:New{
		parent = t.window,
		[x] = 12,
		y = p.topheight,
		width  = (p.windowWidth - 24) / 2,
		height = p.windowheight - p.topheight,
		skin = nil,
		skinName = 'default',
		backgroundColor = {0,0,0,0.6},
		borderColor = {0,0,0,0},
	}
	ts.bg_image = Chili.Image:New{
		parent = t.window,
		[x] = 12,
		y = 7,
		width  = (p.windowWidth - 24) / 2,
		height = p.windowheight - 14,
		keepAspect = false,
	}
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Startup and Shutdown

function SpecPanelStartStop(force)
	-- TODO - Consider whether it would be better instead to unregister
	--	the call-ins when the panel is turned off and re-register them
	--	when turned back on than to use the flag to short-circuit the
	--	call-ins and in ProcessUnit()
	
	-- TODO - Consider whether it would be better to have the option setting
	--	here to enable/disable the widget's functionality, or just have
	--	a menu button to enable/disable (i.e. load/unload) the widget
	--	entirely.
	--
	--	Also - is what's desired just a visibility toggle while the stats
	--	collection continues, or a halt to the stats collection while
	--	the panel is disabled?
	
	local spectating = select(1, Spring.GetSpectatingState())
	local econName, econPath = "Chili Economy Panel Default", "Settings/HUD Panels/Economy Panel"
	
	if force == 'start' or (force ~= 'stop' and (options.enableSpecNG.value and spectating)) then
		if not panel_is_on then
			-- TODO - Don't forget to re-initialize things like smoothedTables and unitStats
			-- while bearing in mind that we could be re-initializing in the middle of the game
			specPanel = {}
			allyTeams = GetOpposingAllyTeams()
			panelSetupData = GetPanelSetupData()
			panelSetupParams = GetPanelSetupParams()
			AddCenterPanels(specPanel, panelSetupParams, panelSetupData)
			AddSidePanels(specPanel, panelSetupParams, panelSetupData, 'left')
			AddSidePanels(specPanel, panelSetupParams, panelSetupData, 'right')
			
			local ecopanelhs = WG.GetWidgetOption(econName, econPath, "ecoPanelHideSpec")
			restore_ecopanelhs = ecopanelhs.value
			WG.SetWidgetOption(econName, econPath, "ecoPanelHideSpec", true)
			
			InitializeUnitStats()
			FetchUpdatedResources()
			UpdateWins(specPanel)
			DisplayPlayerData(specPanel)
			DisplayResources(specPanel)
			DisplayUnitStats(specPanel)

			screen0:AddChild(specPanel.window)
			panel_is_on = true
		end
	elseif force == 'stop' or (force ~= 'start' and not (options.enableSpecNG.value and spectating)) then
		if panel_is_on then
			WG.SetWidgetOption(econName, econPath, "ecoPanelHideSpec", restore_ecopanelhs)
			restore_ecopanelhs = nil
			specPanel.window:Dispose()
			specPanel = nil
			panel_is_on = false
		end
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- General Call-ins

function widget:Shutdown()
end

function widget:PlayerChanged(pID)
	if pID == Spring.GetMyPlayerID() then
		SpecPanelStartStop()
	end
end

function widget:Initialize()
	Chili = WG.Chili
	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	screen0 = Chili.Screen0
	gaiaTeam = Spring.GetGaiaTeamID()
end

function widget:Update(dt)

	-- Start the spec panel in the first userframe. Can't do this during widget:Initialize
	-- because the option values aren't set yet by epicmenu and they may be wrong.
	if not didonce then
		SpecPanelStartStop()
		didonce = true
	end

	if panel_is_on then
		timer_updateclock = timer_updateclock + dt
		timer_updatestats = timer_updatestats + dt
		-- TBD: Update the resource bar flashing status and graphics
		if timer_updateclock >= 1 then
			UpdateClock(specPanel)
			-- TBD: revise Wins logic so it only updates at game end, not every userframe during play
			UpdateWins(specPanel)
			_,timer_updateclock = math.modf(Spring.GetGameSeconds())
		end
		if timer_updatestats >= 2 then
			DisplayResources(specPanel)
			DisplayUnitStats(specPanel)
			_,timer_updatestats = math.modf(Spring.GetGameSeconds())
		end
	end
end

function widget:GameFrame(n)
	if panel_is_on then
		if n%TEAM_SLOWUPDATE_RATE == 0 then
			FetchUpdatedResources()
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
