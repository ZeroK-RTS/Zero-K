if (Game.version:find('91.0') == 1) then
  local SetUnitWeaponState = Spring.SetUnitWeaponState
  local GetUnitWeaponState = Spring.GetUnitWeaponState
  local GetUnitWeaponVectors = Spring.GetUnitWeaponVectors
  local SetUnitShieldState = Spring.SetUnitShieldState
  local GetUnitShieldState = Spring.GetUnitShieldState
  
  function Spring.SetUnitWeaponState(unitID, weaponNum, ...)
    SetUnitWeaponState(unitID, weaponNum - 1, ...)
  end
  
  function Spring.GetUnitWeaponState(unitID, weaponNum, tag)
    return GetUnitWeaponState(unitID, weaponNum - 1, tag)
  end
  
  function Spring.GetUnitWeaponVectors(unitID, weaponNum)
    return GetUnitWeaponVectors(unitID, weaponNum - 1)
  end
  
  function Spring.SetUnitShieldState(unitID, weaponNum, ...)
    if weaponNum then weaponNum = weaponNum - 1 end
    SetUnitShieldState(unitID, weaponNum, ...)
  end
  
  function Spring.GetUnitShieldState(unitID, weaponNum)
    if weaponNum then weaponNum = weaponNum - 1 end
    return GetUnitShieldState(unitID, weaponNum)
  end
end