local optionData = {
  strikecomm = {
    enabled = function() return (not Spring.GetSpectatingState()) end,
    poster = "LuaUI/Images/reminder/armcom.jpg",
    tooltip = "Strike Comm",
        button = function() 
                Spring.SendLuaRulesMsg("faction:nova") 
                Close()
        end 
  },

  battlecomm = {
    enabled = function() return (not Spring.GetSpectatingState()) end,
    poster = "LuaUI/Images/reminder/corcom.jpg",
    tooltip = "Battle Comm",
        button = function() 
                Spring.SendLuaRulesMsg("faction:logos") 
                Close()
        end 
  },
  
  reconcomm = {
    enabled = function() return (not Spring.GetSpectatingState()) end,
    poster = "LuaUI/Images/reminder/commrecon.jpg",
    tooltip = "Recon Comm",
        button = function() 
                Spring.SendLuaRulesMsg("faction:reconcomm") 
                Close()
        end 
  },

  supportcomm = {
    enabled = function() return (not Spring.GetSpectatingState()) end,
    poster = "LuaUI/Images/reminder/commsupport.jpg",
    tooltip = "Support Comm",
        button = function() 
                Spring.SendLuaRulesMsg("faction:supportcomm") 
                Close()
        end 
  },

communism = {
    enabled = function()
      return false -- always enabled - so we hide it
    end,
    poster = "LuaUI/Images/reminder/communism.jpg",
    tooltip = "Communism Mode",
    sound = "LuaUI/Sounds/communism/sovnat1.wav" -- only for communism
  },
  shuffle = {
    enabled = function()
      return false -- Reminder panel now dedicated to commander selection.
    end,
    poster = "LuaUI/Images/reminder/shuffle.png",
    tooltip = "Commander Shuffle",
  },
  planetwars = {
    enabled = function()
      --if modoptions and modoptions.planetwars ~= "" then
      --  return true
      --end
      return false
    end,
    poster = "LuaUI/Images/reminder/planetwars.png",
    tooltip = "PlanetWars",
  }
}

return optionData
