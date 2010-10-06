function gadget:GetInfo()
  return {
    name      = "Bank",
    desc      = "Handle Debts.",
    author    = "CarRepairer",
    date      = "2010-07-24",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
    enabled   = true -- loaded by default?
  }
end

if not tobool(Spring.GetModOptions().marketandbounty) then
	return
end 

local echo 				= Spring.Echo


-------------------------------------------------------------------------------------
local function explode(div,str)
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then 
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local spGetAllyTeamList		= Spring.GetAllyTeamList

local bank = {}
local blockspend = {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function GG.AddDebt(debtor_team, lender_team, amount)
	if not bank[debtor_team] then
		bank[debtor_team] = {}
	end
	if not bank[debtor_team][lender_team] then
		bank[debtor_team][lender_team] = 0
	end
	bank[debtor_team][lender_team] = bank[debtor_team][lender_team] + amount
end

local function Transfers( send_messages )
	for debtor_team, lenders in pairs(bank) do
		for lender_team, amount in pairs(lenders) do
		
			if amount < 0 then
				echo('<Bank> Negative debt error!', amount, debtor_team, lender_team)
			elseif amount == 0 then
				bank[debtor_team][lender_team] = nil
				
				blockspend[debtor_team] = nil
			else
				blockspend[debtor_team] = true
				
				local m = Spring.GetTeamResources(debtor_team, 'metal')
				local xfer_amount = math.min(amount, m)
				if Spring.UseTeamResource( debtor_team, "metal" , xfer_amount ) then
					
					--Spring.SendMessageToTeam(debtor_team, '<Bank> Transfering ' .. xfer_amount .. 'm from ' .. debtor_team .. ' to ' .. lender_team)
					if send_messages then
						Spring.SendMessageToTeam(debtor_team, '<Bank> Transfering metal. You still owe ' .. math.round( amount ) .. ' to Team #' .. lender_team .. '. No building can proceed until debt is paid.' )
					end
					
					Spring.AddTeamResource( lender_team, "metal" , xfer_amount )
					local amount_new = amount - xfer_amount
					bank[debtor_team][lender_team] = amount_new
				end
			end
		end
	end
end

-------------------------------------------------------------------------------------
--Callins

function gadget:AllowUnitBuildStep(builderID, teamID, unitID, unitDefID, step) 
	if step > 0 and blockspend[teamID] then
		return false
	end
	return true
end

function gadget:GameFrame(f)
	if (f%32) < 0.1 then
		local send_messages = (f %(32*15)) < 0.1 
		Transfers( send_messages )
	end
end


function gadget:Initialize()

end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else  -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
end