local MergeTable=Spring.Utilities.MergeTable
return{
    moduledef={
        -- weapons
        -- note that context menu CRASHES if you don't put them here!
        
        commweapon_peashooter = {
            name = "Peashooter",
            description = "Basic self-defence weapon",
        },
    
        commweapon_assaultcannon = {
            name = "Assault Cannon",
            description = "Conventional plasma cannon with decent range",
        },
        commweapon_beamlaser = {
            name = "Beam Laser",
            description = "An effective short-range cutting tool",
        },
        commweapon_flamethrower = {
            name = "Flamethrower",
            description = "Perfect for well-done barbecues",
        },
        commweapon_gaussrifle = {
            name = "Gauss Rifle",
            description = "Precise armor-piercing weapon",
        },
        commweapon_heavymachinegun = {
            name = "Heavy Machine Gun",
            description = "Close-in automatic weapon with AoE",
        },
        commweapon_heatray = {
            name = "Heat Ray",
            description = "Rapidly melts anything at short range; loses damage over distance",
        },
        commweapon_lightninggun = {
            name = "Lightning Gun",
            description = "Paralyzes and damages annoying bugs",
        },
        commweapon_lparticlebeam = {
            name = "Light Particle Beam",
            description = "Fires rapid medium-range pulses",
        },
        commweapon_hparticlebeam = {
            name = "Heavy Particle Beam",
            description = "Ranged high-energy pulse weapon",
        },
        commweapon_massdriver = {
            name = "Mass Driver",
            description = "High-velocity hunting rifle",
        },
        commweapon_missilelauncher = {
            name = "Missile Launcher",
            description = "Fires light seeker missiles with good range",
        },
        commweapon_partillery = {
            name = "Plasma Artillery",
            description = "Long-range artillery gun",
        },
        commweapon_riotcannon = {
            name = "Riot Cannon",
            description = "The weapon of choice for crowd control",
        },
        commweapon_rocketlauncher = {
            name = "Rocket Launcher",
            description = "Medium-range low-velocity hitter",
        },
        commweapon_shotgun = {
            name = "Shotgun",
            description = "Can hammer a single large target or shred many small ones",
        },
        commweapon_shotlaser = {
            name = "Laser shotgun",
            description = "Shotgun but shoots nerd-ass lasers instead of GLOWING HOT BALLS OF STEEL",
        },
        commweapon_slowbeam = {
            name = "Slowing Beam",
            description = "Slows an enemy's movement and firing rate; non-lethal",
        },
        commweapon_sonicgun = {
            name = "Sonic Blaster",
            description = "Short-range weapon that works when dry or wet",
        },
        commweapon_torpedo = {
            name = "Torpedo",
            description = "Fires a torpedo effective against waterborne targets",
        },
        
        -- dguns
        commweapon_concussion = {
            name = "Concussion Shot",
            description = "Extended range weapon with AoE and impulse",
        },
        commweapon_clusterbomb = {
            name = "Cluster Bomb",
            description = "Hammers multiple units in a wide line",
        },
        commweapon_disintegrator = {
            name = "Disintegrator Gun",
            description = "Short-range weapon that vaporizes anything in its path",
        },
        commweapon_disruptorbomb = {
            name = "Disruptor Bomb",
            description = "Damages and slows units in a large area",
        },
        commweapon_multistunner = {
            name = "Multi-Stunner",
            description = "Briefly disables multiple targets in an area",
        },
        commweapon_napalmgrenade = {
            name = "Hellfire Grenade",
            description = "Sets a moderate area ablaze",
        },
        commweapon_slamrocket = {
            name = "S.L.A.M.",
            description = "Long-range weapon with a lethal punch",
        },
        commweapon_sunburst = {
            name = "Sunburst Cannon",
            description = "Ruins a single target's day with a medium-range high-energy burst",
        },
        
        -- conversion kits
        conversion_disruptor = {
            name = "Disruptor Beam",
            description = "Slow Beam: +33% reload time, +250 real damage",
            func = function(unitDef)
                    ReplaceWeapon(unitDef, "commweapon_slowbeam", "commweapon_disruptor")
                end,
        },
        conversion_shockrifle = {
            name = "Shock Rifle",
            description = "Light Particle Beam: Convert to a long-range sniper rifle",
            func = function(unitDef)
                    ReplaceWeapon(unitDef, "commweapon_lparticlebeam", "commweapon_shockrifle")
                end,
        },
        conversion_partillery = {
            name = "Plasma Artillery",
            description = "Assault Cannon: Convert to a light artillery gun",
            func = function(unitDef)
                    ReplaceWeapon(unitDef, "commweapon_assaultcannon", "commweapon_partillery")
                    --unitDef.hightrajectory = 1
                end,
        },
        conversion_hparticlebeam = {
            name = "Heavy Particle Beam",
            description = "Light Particle Beam: Convert to an extended range rifle weapon",
            func = function(unitDef)
                    ReplaceWeapon(unitDef, "commweapon_lparticlebeam", "commweapon_hparticlebeam")
                end,
        },
        
        -- weapon mods
        weaponmod_antiair = {
            name = "Anti-Air Kit",
            description = "Beam Laser/Riot Cannon/Missile Launcher: Convert to anti-air weapons",
            func = function(unitDef)
                    for i,v in pairs(weapons) do
                        local id = v.customparams.idstring
                        if (id == "commweapon_riotcannon") then
                            ReplaceWeapon(unitDef, "commweapon_riotcannon", "commweapon_flakcannon")
                            ReplaceWeapon(unitDef, "commweapon_riotcannon", "commweapon_flakcannon")
                        elseif (id == "commweapon_beamlaser") then
                            ReplaceWeapon(unitDef, "commweapon_beamlaser", "commweapon_aalaser")
                            ReplaceWeapon(unitDef, "commweapon_beamlaser", "commweapon_aalaser")
                        elseif (id == "commweapon_missilelauncher") then
                            ReplaceWeapon(unitDef, "commweapon_missilelauncher", "commweapon_aamissile")
                            ReplaceWeapon(unitDef, "commweapon_missilelauncher", "commweapon_aamissile")
                        end
                    end
                end
        },
        weaponmod_autoflechette = {
            name = "Autoflechette",
            description = "Shotgun: -25% projectiles, -40% reload time",
            func = function(unitDef)
                    local weapons = unitDef.weapondefs or {}
                    for i,v in pairs(weapons) do
                        if v.customparams.idstring == "commweapon_shotgun" then
                            v.customparams.misceffect = nil
                            v.projectiles = v.projectiles * 0.75
                            v.reloadtime = v.reloadtime * 0.6
                            --break
                        end
                    end
                end,
        },
        weaponmod_disruptor_ammo = {
            name = "Disruptor Ammo",
            description = "Shotgun/Heavy Machine Gun/Shock Rifle: +40% slow damage",
            func = function(unitDef)
                    local permitted = {
                        commweapon_shotgun = true,
                        commweapon_gaussrifle = true,
                        commweapon_heavymachinegun = true,
                        commweapon_shockrifle = true,
                    }
                    local weapons = unitDef.weapondefs or {}
                    for i,v in pairs(weapons) do
                        local wcp = v.customparams
                        local id = wcp.idstring
                        if permitted[id] then
                            wcp.timeslow_damagefactor = "0.4"
                            v.rgbcolor = [[0.9 0.1 0.9]]
                            if id == "commweapon_shotgun" or id == "commweapon_heavymachinegun" then
                                v.explosiongenerator = [[custom:BEAMWEAPON_HIT_PURPLE]]
                            elseif id == "commweapon_gaussrifle" then
                                v.explosiongenerator = [[custom:GAUSS_HIT_M_PURPLE]]
                            end -- no visual effect on shock rifle
                            if i == "commweapon_shotgun_green" or i == "commweapon_heavymachinegun_lime" then
                                v.rgbcolor = "0 1 0.7"
                                v.explosiongenerator = [[custom:BEAMWEAPON_HIT_TURQUOISE]]
                            end
                        end
                    end
                end,
        },
        weaponmod_high_frequency_beam = {
            name = "High Frequency Beam",
            description = " +15% damage and range to Beam Laser/Slow Beam/Disruptor Beam/Light Particle Beam/Heavy Particle Beam",
            func = function(unitDef)
                    local weapons = unitDef.weapondefs or {}
                    local permitted = {
                        commweapon_beamlaser = true,
                        commweapon_slowbeam = true,
                        commweapon_disruptor = true,
                        commweapon_lparticlebeam = true,
                        commweapon_hparticlebeam = true,
                    }
                    for i,v in pairs(weapons) do
                        if permitted[v.customparams.idstring] then
                            v.range = v.range * 1.15
                            for armorname, dmg in pairs(v.damage) do
                                v.damage[armorname] = dmg * 1.15
                            end
                        end
                    end
                end,
        },
        weaponmod_railaccel = {
            name = "Rail Accelerator",
            description = "Gauss Rifle: +10% damage, +20% range",
            func = function(unitDef)
                    local weapons = unitDef.weapondefs or {}
                    for i,v in pairs(weapons) do
                        local id = v.customparams.idstring
                        if id == "commweapon_gaussrifle" or id == "commweapon_massdriver" then
                            v.range = v.range * 1.2
                            for armorname, dmg in pairs(v.damage) do
                                v.damage[armorname] = dmg * 1.1
                            end
                        end
                    end
                end,
        },
        weaponmod_high_caliber_barrel = {
            name = "High Caliber Barrel",
            description = "Shotgun/Riot Cannon/Assault Cannon/Plasma Artillery: +150% damage, +100% reload time",
            func = function(unitDef)
                    local weapons = unitDef.weapondefs or {}
                    local permitted = {
                        commweapon_assaultcannon = true,
                        commweapon_shotgun = true,
                        commweapon_gaussrifle = true,
                        commweapon_partillery = true,
                        commweapon_partillery_napalm = true,
                        commweapon_riotcannon = true,
                    }
                    for i,v in pairs(weapons) do
                        local id = v.customparams.idstring
                        if permitted[id] then
                            if not (id == "commweapon_partillery" or id == "commweapon_partillery_napalm") then
                                v.reloadtime = v.reloadtime * 2
                                v.customparams.highcaliber = true
                                for armorname, dmg in pairs(v.damage) do
                                    v.damage[armorname] = dmg * 2.5
                                end
                            else
                                ReplaceWeapon(unitDef, "commweapon_partillery", "commweapon_hpartillery")
                                ReplaceWeapon(unitDef, "commweapon_partillery", "commweapon_hpartillery")
                                ReplaceWeapon(unitDef, "commweapon_partillery_napalm", "commweapon_hpartillery_napalm")
                                ReplaceWeapon(unitDef, "commweapon_partillery_napalm", "commweapon_hpartillery_napalm")
                            end
                        end
                    end
                end,
        },
        weaponmod_standoff_rocket = {
            name = "Standoff Rocket",
            description = "Rocket/Missile Launcher: +50% range, +25% damage, +50% reload time",
            func = function(unitDef)
                    local weapons = unitDef.weapondefs or {}
                    for i,v in pairs(weapons) do
                        local id = v.customparams.idstring
                        if id == "commweapon_rocketlauncher" then
                            v.range = v.range * 1.5
                            v.reloadtime = v.reloadtime * 1.5
                            for armorname, dmg in pairs(v.damage) do
                                v.damage[armorname] = dmg * 1.25
                            end
                            v.model = [[wep_m_dragonsfang.s3o]]
                            v.soundhitvolume = 8
                            v.soundstart = [[weapon/missile/missile2_fire_bass]]
                            v.soundstartvolume = 7
                            --break
                        elseif id == "commweapon_missilelauncher" then
                            v.range = v.range * 1.5
                            v.reloadtime = v.reloadtime * 1.5
                            for armorname, dmg in pairs(v.damage) do
                                v.damage[armorname] = dmg * 1.25
                            end
                            v.model = [[wep_m_phoenix.s3o]]
                            v.soundhitvolume = 5
                            v.soundstart = [[weapon/missile/missile_fire7]]
                            v.soundstartvolume = 3
                        end
                    end
                end,
        },
        weaponmod_stun_booster = {
            name = "Flux Amplifier",
            description = "Lightning Gun: +25% paralyze damage, +2s paralyzetime",
            func = function(unitDef)
                    local weapons = unitDef.weapondefs or {}
                    for i,v in pairs(weapons) do
                        if v.customparams.idstring == "commweapon_lightninggun" then
                            v.customparams.extra_damage = v.customparams.extra_damage * 1.25
                            v.paralyzetime = v.paralyzetime + 2
                        end
                    end
                end,
        },
        weaponmod_napalm_warhead = {
            name = "Napalm Warhead",
            description = "Riot Cannon/Plasma Artillery/Rocket Launcher: Reduced direct damage, sets target on fire",
            func = function(unitDef)
                    local weapons = unitDef.weapondefs or {}
                    local permitted = {
                        commweapon_partillery = true,
                        commweapon_hpartillery = true,
                        commweapon_rocketlauncher = true,
                        commweapon_riotcannon = true,
                    }
                    for i,v in pairs(weapons) do
                        local id = v.customparams.idstring
                        if permitted[id] then
                            if (id == "commweapon_riotcannon") then	-- -20% damage
                                for armorname, dmg in pairs(v.damage) do
                                    v.damage[armorname] = dmg * 0.8
                                end
                                v.customparams.burntime = "420"
                                v.rgbcolor = [[1 0.3 0.1]]
                            elseif (id == "commweapon_hpartillery") then	-- -90% damage, 256 AoE, firewalker effect
                                ReplaceWeapon(unitDef, "commweapon_hpartillery", "commweapon_hpartillery_napalm")
                                ReplaceWeapon(unitDef, "commweapon_hpartillery", "commweapon_hpartillery_napalm")
                            elseif (id == "commweapon_partillery") then	-- -25% damage, 128 AoE
                                ReplaceWeapon(unitDef, "commweapon_partillery", "commweapon_partillery_napalm")
                                ReplaceWeapon(unitDef, "commweapon_partillery", "commweapon_partillery_napalm")
                            else	-- -25% damage, 128 AoE
                                for armorname, dmg in pairs(v.damage) do
                                    v.damage[armorname] = dmg * 0.75
                                end
                                v.customparams.burntime = "450"
                                v.areaofeffect = 128
                            end
                            
                            if (id == "commweapon_riotcannon") or (id == "commweapon_rocketlauncher") then
                                v.explosiongenerator = [[custom:napalm_koda]]
                                v.customparams.burnchance = "1"
                                v.soundhit = [[weapon/burn_mixed]]
                            end
                            v.customparams.setunitsonfire = "1"
                        end
                    end
                end,
        },
        weaponmod_flame_enhancer = {
            name = "Long-Burn Napalm",
            description = "Flamethrower/Napalm Warhead: +40% on-fire time",
            func = function(unitDef)
                    local weapons = unitDef.weapondefs or {}
                    for i,v in pairs(weapons) do
                        if v.customparams.burntime then
                            v.customparams.burntime = v.customparams.burntime * 1.4
                        end
                        if v.customparams.idstring == "commweapon_hpartillery_napalm" then
                            v.customparams.area_damage_duration = v.customparams.area_damage_duration * 1.4
                            v.explosiongenerator = "custom:napalm_firewalker_long"
                        end
                    end
                end,
            order = 3.1,
        },
        weaponmod_plasma_containment = {
            name = "Plasma Containment Field",
            description = "Heat Ray/Riot Cannon: +30% range",
            func = function(unitDef)
                    local weapons = unitDef.weapondefs or {}
                    for i,v in pairs(weapons) do
                        local id = v.customparams.idstring
                        if id == "commweapon_heatray" then
                            v.range = v.range * 1.3
                        elseif id == "commweapon_riotcannon" then
                            v.range = v.range * 1.3
                        end
                    end
                end,
        },
        
        -- modules
        module_ablative_armor = {
            name = "Ablative Armor Plates",
            description = "Adds 600 HP",
            func = function(unitDef)
                    unitDef.health = unitDef.health + 600
                end,
        },
        module_adv_targeting = {
            name = "Advanced Targeting System",
            description = "Extends range of all weapons by 10%",
            func = function(unitDef)
                    local weapons = unitDef.weapondefs or {}
                    for i,v in pairs(weapons) do
                        v.customparams.rangemod = v.customparams.rangemod + 0.1
                    end
                end,
        },
        module_adv_nano = {
            name = "CarRepairer's Nanolathe",
            description = "Adds +5 metal/s build speed",
            func = function(unitDef)
                    if unitDef.workertime then unitDef.workertime = unitDef.workertime + 5 end
                    --if unitDef.builddistance then unitDef.builddistance = unitDef.builddistance + 60 end
                end,
        },
        module_autorepair = {
            name = "Autorepair System",
            description = "Self-repairs 10 HP/s",
            func = function(unitDef)
                    unitDef.autoheal = (unitDef.autoheal or 0) + 10
                end,
        },
        module_companion_drone = {
            name = "Companion Drone",
            description = "Spawns a pair of attack drones",
            func = function(unitDef)
                    unitDef.customparams.drones = unitDef.customparams.drones or {}
                    unitDef.customparams.drones[#unitDef.customparams.drones+1] = "module_companion_drone"
                end,
        },
        module_battle_drone = {
            name = "Battle Drone",
            description = "Spawns an advanced combat drone",
            func = function(unitDef)
                    unitDef.customparams.drones = unitDef.customparams.drones or {}
                    unitDef.customparams.drones[#unitDef.customparams.drones+1] = "module_battle_drone"
                end,
        },
        module_dmg_booster = {
            name = "Damage Booster",
            description = "Increases damage of all weapons by 10%",
            func = function(unitDef)
                    if unitDef.customparams.dynamic_comm then
                        -- Weapondefs are static
                        unitDef.customparams.damagemod = (unitDef.customparams.damagemod or 0) + 1
                    else
                        -- Weapondefs stored in unitdef
                        local weapons = unitDef.weapondefs or {}
                        for i,v in pairs(weapons) do
                            v.customparams.damagemod = (v.customparams.damagemod or 0) + 0.1
                        end
                    end
                end,
        },
        module_burst_loader = {
            name = "Burst Loader",
            description = "+1 burst, +70% reload time",
            func = function(unitDef)
                    local weapons = unitDef.weapondefs or {}
                    for i,v in pairs(weapons) do
                        local id = v.customparams.idstring
                        -- linear rather than exponential increase with stacking
                        v.reloadtime = v.reloadtime or 1
                        local previousCount = v.customparams.burstloaders or 0
                        local baseReload = v.reloadtime / (1 + 0.7*previousCount)
                        if id == "commweapon_beamlaser" or id == "commweapon_disruptor" or id == "commweapon_slowbeam" then
                            -- v.beamtime = v.beamtime + 10 -- beamlaser has 0.1, it's in seconds
                            v.corethickness = v.corethickness + v.corethickness/(previousCount + 1)
                            for armorname, dmg in pairs(v.damage) do
                                v.damage[armorname] = dmg + dmg/(previousCount + 1)
                            end
                        elseif id == "commweapon_shotgun" then
                            v.burst = (v.burst or 1) + 3
                            v.sprayangle = (v.sprayangle or 0) + 256
                            v.reloadtime = v.reloadtime + baseReload * 0.7
                        else
                            v.burstrate = (v.burstrate or 0.1 )
                            v.reloadtime = v.reloadtime + baseReload * 0.7
                            v.burst = (v.burst or 1) + 1
                            v.sprayangle = (v.sprayangle or 0) + 256
                        end
                        v.customparams.burstloaders = previousCount + 1
                    end
                end,
        },
        module_energy_cell = {
            name = "Energy Cell",
            description = "Compact fuel cells that produce +6 energy",
            func = function(unitDef)
                    unitDef.energymake = (unitDef.energymake or 0) + 6
                end,
        },
        module_fieldradar = {
            name = "Field Radar Module",
            description = "Basic radar system with 1800 range",
            func = function(unitDef)
                    unitDef.radardistance = (unitDef.radardistance or 0)
                    if unitDef.radardistance < 1800 then
                        unitDef.radardistance = 1800
                    end
                    if (not unitDef.radaremitheight) or unitDef.radaremitheight < 100 then
                        unitDef.radaremitheight = 24
                    end
                end,
        },
        module_heavy_armor = {
            name = "High Density Plating",
            description = "Adds 1600 HP, slows comm by +10%",
            func = function(unitDef, attributeMods)
                    unitDef.health = unitDef.health + 1600
                    attributeMods.speed = attributeMods.speed - 0.1
                end,
        },
        module_high_power_servos = {
            name = "High Power Servos",
            description = "More powerful leg actuators increase speed by 10% of base",
            func = function(unitDef, attributeMods)
                    attributeMods.speed = attributeMods.speed + 0.1
                end,
        },
        module_personal_cloak = {
            name = "Personal Cloak",
            description = "Cloaks the commander",
            func = function(unitDef)
                    unitDef.cancloak = true
                    unitDef.cloakcost = unitDef.cloakcost or 5
                    unitDef.mincloakdistance = math.max(150, unitDef.mincloakdistance or 0)
                    if unitDef.cloakcost > 5 then
                        unitDef.cloakcost = 5
                    end
                    unitDef.cloakcostmoving = unitDef.cloakcostmoving or 10
                    if unitDef.cloakcostmoving > 10 then
                        unitDef.cloakcostmoving = 10
                    end
                end,
        },
        module_personal_shield = {
            name = "Personal Shield",
            order = 5,
            description = "Generates a small bubble shield",
            func = function(unitDef)
                    if unitDef.customparams.dynamic_comm then
                        DynamicApplyWeapon(unitDef, "commweapon_personal_shield", #unitDef.weapons + 1)
                    else
                        ApplyWeapon(unitDef, "commweapon_personal_shield", 4)
                    end
                end,
        },
        
        module_resurrect = {
            name = "Lazarus Device",
            description = "Enables resurrection of wrecks",
            func = function(unitDef)
                    unitDef.canresurrect = true
                end,
        },
        
        module_jumpjet = {
            name = "Jumpjet",
            description = "Allows the commander to jump",
            func = function(unitDef)
                    unitDef.customparams.canjump            = 1
                    unitDef.customparams.jump_range         = 400
                    unitDef.customparams.jump_speed         = 6
                    unitDef.customparams.jump_reload        = 20
                    unitDef.customparams.jump_from_midair   = 1
                end,
        },
        
        module_areashield = {
            name = "Area Shield",
            order = 6,
            description = "A bubble shield that protects surrounding units within 350 m",
            func = function(unitDef)
                    --ApplyWeapon(unitDef, "commweapon_areashield", 2)
                    
                    if unitDef.customparams.dynamic_comm then
                        DynamicApplyWeapon(unitDef, "commweapon_areashield", #unitDef.weapons) -- not +1 so as to replace personal
                    else
                        ReplaceWeapon(unitDef, "commweapon_personal_shield", "commweapon_areashield")
                    end
    
                    unitDef.customparams.lups_unit_fxs = unitDef.customparams.lups_unit_fxs or {}
                    table.insert(unitDef.customparams.lups_unit_fxs, "commAreaShield")
                end,
        },
        module_cloak_field = {
            name = "Cloaking Field",
            description = "Cloaks all friendly units within 350 m",
            func = function(unitDef)
                    unitDef.mincloakdistance = math.max(150, unitDef.mincloakdistance or 0)
                    unitDef.onoffable = true
                    unitDef.radarDistanceJam = (unitDef.radarDistanceJam and unitDef.radarDistanceJam > 350 and unitDef.radarDistanceJam) or 350
                    unitDef.customparams.area_cloak = "1"
                    unitDef.customparams.area_cloak_upkeep = "15"
                    unitDef.customparams.area_cloak_radius = "350"
                    unitDef.customparams.area_cloak_decloak_distance = "75"
                end,
        },
        module_jammer = {
            name = "Radar Jammer",
            description = "Masks radar signals of all units within 500 m",
            func = function(unitDef)
                    unitDef.radardistancejam = 500
                    unitDef.activatewhenbuilt = true
                    unitDef.onoffable = true
                end,
        },
        
        module_jump_booster = {
            name = "Dragonfly Booster",
            description = "Increases jump range and height",
            func = function(unitDef)
                    unitDef.customparams.jumpclass = "commrecon2"
                end,
        },
        
        module_radarnet = {
            name = "Integrated Radar Network",
            description = "Reduces radar wobble for all units",
            func = function(unitDef)
                    unitDef.isTargetingUpgrade = true
                    unitDef.activatewhenbuilt = true
            end,
        },
        
        module_ultralight_hull = {
            name = "Ultralight Hull",
            description = "-1200 HP, +25% speed",
            func = function(unitDef, attributeMods)
                    unitDef.health = unitDef.health - 1200
                    attributeMods.speed = attributeMods.speed + 0.25
                end,
        },
        module_weapon_hicharge = {
            name = "Weapon Hi-Charger",
            description = "-1000 HP, +40% damage",
            func = function(unitDef, attributeMods)
                    unitDef.health = unitDef.health - 1000
                    local weapons = unitDef.weapondefs or {}
                    for i,v in pairs(weapons) do
                        v.customparams.damagemod = v.customparams.damagemod + 0.4
                    end
                end,
        },
        -- modules that use a weapon slot
        module_guardian_armor = {
            name = "Guardian Defence System",
            description = "Adds 100% HP (including other modules); self-repairs 20 HP/s",
            func = function(unitDef, attributeMods)
                    attributeMods.health = attributeMods.health + 1
                    unitDef.autoheal = (unitDef.autoheal or 0) + 20
            end,
            useWeaponSlot = true,
        },
    
        module_superspeed = {
            name = "Marathon Motion Control",
            description = "Increases speed by 50% of base",
            func = function(unitDef, attributeMods)
                    attributeMods.speed = attributeMods.speed + 0.5
            end,
            useWeaponSlot = true,
        },
        
        module_longshot = {
            name = "Longshot Fire Control",
            description = "Extends range of all weapons by 40%",
            func = function(unitDef)
                    local weapons = unitDef.weapondefs or {}
                    for i,v in pairs(weapons) do
                        v.customparams.rangemod = v.customparams.rangemod + 0.4
                    end
                end,
            useWeaponSlot = true,
        },
            
        module_super_nano = {
            name = "Engineer's Revenge",
            description = "Adds 20 metal/s build speed and 200 build range",
            func = function(unitDef)
                    if unitDef.workertime then unitDef.workertime = unitDef.workertime + 20 end
                    if unitDef.builddistance then unitDef.builddistance = unitDef.builddistance + 200 end
            end,
            useWeaponSlot = true,
        },
        
        -- deprecated
        module_improved_optics = {
            name = "Improved Optics",
            description = "Increases sight distance by 100 m",
            func = function(unitDef)
                    unitDef.sightdistance = unitDef.sightdistance + 100
                end,
        },
        module_repair_field = {
            name = "Repair Field",
            description = "Passively repairs all friendly units within 450 m",
            func = function(unitDef)
                    unitDef.customparams.repairaura_preset = "module_repairfield"
                end,
        },
        
        -- secret stuff!
        module_econ = {
            name = "Economy Package",
            description = "Produces +2 energy and metal",
            func = function(unitDef)
                    unitDef.energymake = (unitDef.energymake or 0) + 2
                    unitDef.metalmake = (unitDef.metalmake or 0) + 2
                end,
        },
        
        conversion_lazor = {
            name = "Uberlazor",
            description = "LOLOLOL",
            func = function(unitDef)
                    ReplaceWeapon(unitDef, "commweapon_beamlaser", "commweapon_hparticlebeam")
                end,
        }
    },
    dynamic_comm_def=function (shared)

        local HP_MULT=shared.HP_MULT
        local COST_MULT=shared.COST_MULT
        local moduleImagePath=shared.moduleImagePath
        local moduleDefNamesToIDs=shared.moduleDefNamesToIDs
        local disableResurrect=shared.disableResurrect
        local basicChassis={"recon", "strike", "assault", "support", "knight"}
        local moduleDefs = {
            -- Empty Module Slots
            {
                name = "nullmodule",
                humanName = "No Module",
                description = "No Module",
                image = "LuaUI/Images/dynamic_comm_menu/cross.png",
                limit = false,
                emptyModule = true,
                cost = 0,
                requireLevel = 0,
                slotType = "module",
                hardcodedID=1,
            },
            {
                name = "nullbasicweapon",
                humanName = "No Weapon",
                description = "No Weapon",
                image = "LuaUI/Images/dynamic_comm_menu/cross.png",
                limit = false,
                emptyModule = true,
                requireChassis = {"knight"},
                cost = 0,
                requireLevel = 0,
                slotType = "basic_weapon",
                hardcodedID=2,
            },
            {
                name = "nulladvweapon",
                humanName = "No Weapon",
                description = "No Weapon",
                image = "LuaUI/Images/dynamic_comm_menu/cross.png",
                limit = false,
                emptyModule = true,
                cost = 0 * COST_MULT,
                requireLevel = 0,
                slotType = "adv_weapon",
                hardcodedID=3,
            },
            {
                name = "nulldualbasicweapon",
                humanName = "No Weapon",
                description = "No Weapon",
                image = "LuaUI/Images/dynamic_comm_menu/cross.png",
                limit = false,
                emptyModule = true,
                cost = 0 * COST_MULT,
                requireLevel = 0,
                slotType = "dual_basic_weapon",
                hardcodedID=4,
            },
            
            -- Weapons
            
            
            
            --{
            --	name = "commweapon_hpartillery",
            --	humanName = "Plasma Artillery",
            --	description = "Plasma Artillery",
            --	image = moduleImagePath .. "commweapon_assaultcannon.png",
            --	limit = 2,
            --	cost = 300 * COST_MULT,
            --	requireChassis = {"assault"},
            --	requireLevel = 3,
            --	slotType = "adv_weapon",
            --	applicationFunction = function (modules, sharedData)
            --		if sharedData.noMoreWeapons then
            --			return
            --		end
            --		local weaponName = (modules[moduleDefNames.weaponmod_napalm_warhead] and "commweapon_hpartillery_napalm") or "commweapon_hpartillery"
            --		if not sharedData.weapon1 then
            --			sharedData.weapon1 = weaponName
            --		else
            --			sharedData.weapon2 = weaponName
            --		end
            --	end
            --},
            
            
            
            
            
            
            {
                name = "commweapon_hparticlebeam",
                humanName = "Heavy Particle Beam",
                description = "Heavy Particle Beam - Replaces other weapons. Short range, high-power beam weapon with moderate reload time",
                image = moduleImagePath .. "conversion_hparticlebeam.png",
                limit = 1,
                cost = 400 * COST_MULT,
                requireChassis = {"support", "knight"},
                requireLevel = 1,
                slotType = "adv_weapon",
                applicationFunction = function (modules, sharedData)
                    if sharedData.noMoreWeapons then
                        return
                    end
                    local weaponName = (modules[moduleDefNamesToIDs.conversion_disruptor[1]] and "commweapon_heavy_disruptor") or "commweapon_hparticlebeam"
                    sharedData.weapon1 = weaponName
                    sharedData.weapon2 = nil
                    sharedData.noMoreWeapons = true
                end,
                hardcodedID=15
            },
            {
                name = "commweapon_shockrifle",
                humanName = "Shock Rifle",
                description = "Shock Rifle - Replaces other weapons. Long range sniper rifle",
                image = moduleImagePath .. "conversion_shockrifle.png",
                limit = 1,
                cost = 400 * COST_MULT,
                requireChassis = {"support", "knight"},
                requireLevel = 1,
                slotType = "adv_weapon",
                applicationFunction = function (modules, sharedData)
                    if sharedData.noMoreWeapons then
                        return
                    end
                    sharedData.weapon1 = "commweapon_shockrifle"
                    sharedData.weapon2 = nil
                    sharedData.noMoreWeapons = true
                end,
                hardcodedID=16
            },
            {
                name = "commweapon_clusterbomb",
                humanName = "Cluster Bomb",
                description = "Cluster Bomb - Manually fired burst of bombs.",
                image = moduleImagePath .. "commweapon_clusterbomb.png",
                limit = 1,
                cost = 400 * COST_MULT,
                requireChassis = {"recon", "assault", "knight"},
                requireLevel = 3,
                slotType = "adv_weapon",
                applicationFunction = function (modules, sharedData)
                    if sharedData.noMoreWeapons then
                        return
                    end
                    if not sharedData.weapon1 then
                        sharedData.weapon1 = "commweapon_clusterbomb"
                    else
                        sharedData.weapon2 = "commweapon_clusterbomb"
                    end
                end,
                hardcodedID=17
            },
            {
                name = "commweapon_concussion",
                humanName = "Concussion Shell",
                description = "Concussion Shell - Manually fired high impulse projectile.",
                image = moduleImagePath .. "commweapon_concussion.png",
                limit = 1,
                cost = 400 * COST_MULT,
                requireChassis = {"recon", "knight"},
                requireLevel = 3,
                slotType = "adv_weapon",
                applicationFunction = function (modules, sharedData)
                    if sharedData.noMoreWeapons then
                        return
                    end
                    if not sharedData.weapon1 then
                        sharedData.weapon1 = "commweapon_concussion"
                    else
                        sharedData.weapon2 = "commweapon_concussion"
                    end
                end,
                hardcodedID=18
            },
            {
                name = "commweapon_disintegrator",
                humanName = "Disintegrator",
                description = "Disintegrator - Manually fired weapon that destroys almost everything it touches.",
                image = moduleImagePath .. "commweapon_disintegrator.png",
                limit = 1,
                cost = 400 * COST_MULT,
                requireChassis = {"assault", "strike", "knight"},
                requireLevel = 3,
                slotType = "adv_weapon",
                applicationFunction = function (modules, sharedData)
                    if sharedData.noMoreWeapons then
                        return
                    end
                    if not sharedData.weapon1 then
                        sharedData.weapon1 = "commweapon_disintegrator"
                    else
                        sharedData.weapon2 = "commweapon_disintegrator"
                    end
                end,
                hardcodedID=19
            },
            {
                name = "commweapon_disruptorbomb",
                humanName = "Disruptor Bomb",
                description = "Disruptor Bomb - Manually fired bomb that slows enemies in a large area.",
                image = moduleImagePath .. "commweapon_disruptorbomb.png",
                limit = 1,
                cost = 400 * COST_MULT,
                requireChassis = {"recon", "support", "strike", "knight"},
                requireLevel = 3,
                slotType = "adv_weapon",
                applicationFunction = function (modules, sharedData)
                    if sharedData.noMoreWeapons then
                        return
                    end
                    if not sharedData.weapon1 then
                        sharedData.weapon1 = "commweapon_disruptorbomb"
                    else
                        sharedData.weapon2 = "commweapon_disruptorbomb"
                    end
                end,
                hardcodedID=20
            },
            {
                name = "commweapon_multistunner",
                humanName = "Multistunner",
                description = "Multistunner - Manually fired sustained burst of lightning.",
                image = moduleImagePath .. "commweapon_multistunner.png",
                limit = 1,
                cost = 400 * COST_MULT,
                requireChassis = {"support", "recon", "strike", "knight"},
                requireLevel = 3,
                slotType = "adv_weapon",
                applicationFunction = function (modules, sharedData)
                    if sharedData.noMoreWeapons then
                        return
                    end
                    local weaponName = (modules[moduleDefNamesToIDs.weaponmod_stun_booster[1]] and "commweapon_multistunner_improved") or "commweapon_multistunner"
                    if not sharedData.weapon1 then
                        sharedData.weapon1 = weaponName
                    else
                        sharedData.weapon2 = weaponName
                    end
                end,
                hardcodedID=21
            },
            {
                name = "commweapon_napalmgrenade",
                humanName = "Hellfire Grenade",
                description = "Hellfire Grenade - Manually fired bomb that inflames a large area.",
                image = moduleImagePath .. "commweapon_napalmgrenade.png",
                limit = 1,
                cost = 400 * COST_MULT,
                requireChassis = {"assault", "recon", "knight"},
                requireLevel = 3,
                slotType = "adv_weapon",
                applicationFunction = function (modules, sharedData)
                    if sharedData.noMoreWeapons then
                        return
                    end
                    if not sharedData.weapon1 then
                        sharedData.weapon1 = "commweapon_napalmgrenade"
                    else
                        sharedData.weapon2 = "commweapon_napalmgrenade"
                    end
                end,
                hardcodedID=22
            },
            {
                name = "commweapon_slamrocket",
                humanName = "S.L.A.M. Rocket",
                description = "S.L.A.M. Rocket - Manually fired miniature tactical nuke.",
                image = moduleImagePath .. "commweapon_slamrocket.png",
                limit = 1,
                cost = 400 * COST_MULT,
                requireChassis = {"assault", "knight"},
                requireLevel = 3,
                slotType = "adv_weapon",
                applicationFunction = function (modules, sharedData)
                    if sharedData.noMoreWeapons then
                        return
                    end
                    if not sharedData.weapon1 then
                        sharedData.weapon1 = "commweapon_slamrocket"
                    else
                        sharedData.weapon2 = "commweapon_slamrocket"
                    end
                end,
                hardcodedID=23
            },
            
            -- Unique Modules
            {
                name = "econ",
                humanName = "Vanguard Economy Pack",
                description = "Vanguard Economy Pack - A vital part of establishing a beachhead, this module is equipped by all new commanders to kickstart their economy. Provides 4 metal income and 6 energy income.",
                image = moduleImagePath .. "module_energy_cell.png",
                limit = 1,
                unequipable = true,
                cost = 100 * COST_MULT,
                requireLevel = 0,
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.metalIncome = (sharedData.metalIncome or 0) + 4
                    sharedData.energyIncome = (sharedData.energyIncome or 0) + 6
                end,
                hardcodedID=24
            },
            {
                name = "commweapon_personal_shield",
                humanName = "Personal Shield",
                description = "Personal Shield - A small, protective bubble shield.",
                image = moduleImagePath .. "module_personal_shield.png",
                limit = 1,
                cost = 300 * COST_MULT,
                prohibitingModules = {"module_personal_cloak"},
                requireLevel = 2,
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    -- Do not override area shield
                    sharedData.shield = sharedData.shield or "commweapon_personal_shield"
                end,
                hardcodedID=25
            },
            {
                name = "commweapon_areashield",
                humanName = "Area Shield",
                description = "Area Shield - Projects a large shield. Replaces Personal Shield.",
                image = moduleImagePath .. "module_areashield.png",
                limit = 1,
                cost = 250 * COST_MULT,
                requireChassis = {"assault", "support", "knight"},
                requireOneOf = {"commweapon_personal_shield"},
                prohibitingModules = {"module_personal_cloak"},
                requireLevel = 3,
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.shield = "commweapon_areashield"
                end,
                hardcodedID=26
            },
            {
                name = "weaponmod_napalm_warhead",
                humanName = "Napalm Warhead",
                description = "Napalm Warhead - Riot Cannon and Rocket Launcher set targets on fire. Reduced direct damage.",
                image = moduleImagePath .. "weaponmod_napalm_warhead.png",
                limit = 1,
                cost = 350 * COST_MULT,
                requireChassis = {"assault", "knight"},
                requireOneOf = {
                    "commweapon_rocketlauncher", "commweapon_rocketlauncher_adv",
                    "commweapon_riotcannon", "commweapon_riotcannon_adv",
                    "commweapon_hpartillery"},
                requireLevel = 2,
                slotType = "module",
                hardcodedID=27
            },
            {
                name = "conversion_disruptor",
                humanName = "Disruptor Ammo",
                description = "Disruptor Ammo - Heavy Machine Gun, Shotgun and Particle Beams deal slow damage. Reduced direct damage.",
                image = moduleImagePath .. "weaponmod_disruptor_ammo.png",
                limit = 1,
                cost = 300 * COST_MULT,
                requireChassis = {"strike", "recon", "support", "knight"},
                requireOneOf = {
                    "commweapon_heavymachinegun", "commweapon_heavymachinegun_adv",
                    "commweapon_shotgun", "commweapon_shotgun_adv",
                    "commweapon_lparticlebeam", "commweapon_lparticlebeam_adv",
                    "commweapon_hparticlebeam"
                },
                requireLevel = 2,
                slotType = "module",
                hardcodedID=28
            },
            {
                name = "weaponmod_stun_booster",
                humanName = "Flux Amplifier",
                description = "Flux Amplifier - Improves EMP duration and strength of Lightning Rifle and Multistunner.",
                image = moduleImagePath .. "weaponmod_stun_booster.png",
                limit = 1,
                cost = 300 * COST_MULT,
                requireChassis = {"support", "strike", "recon", "knight"},
                requireOneOf = {
                    "commweapon_lightninggun", "commweapon_lightninggun_adv",
                    "commweapon_multistunner"
                },
                requireLevel = 2,
                slotType = "module",
                hardcodedID=29
            },
            {
                name = "module_jammer",
                humanName = "Radar Jammer",
                description = "Radar Jammer - Hide the radar signals of nearby units.",
                image = moduleImagePath .. "module_jammer.png",
                limit = 1,
                cost = 200 * COST_MULT,
                requireLevel = 2,
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    if not sharedData.cloakFieldRange then
                        sharedData.radarJammingRange = 500
                    end
                end,
                hardcodedID=30
            },
            {
                name = "module_radarnet",
                humanName = "Field Radar",
                description = "Field Radar - Attaches a basic radar system.",
                image = moduleImagePath .. "module_fieldradar.png",
                limit = 1,
                cost = 75 * COST_MULT,
                requireLevel = 1,
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.radarRange = 1800
                end,
                hardcodedID=31
            },
            {
                name = "module_personal_cloak",
                humanName = "Personal Cloak",
                description = "Personal Cloak - A personal cloaking device. Reduces total speed by 12%.",
                image = moduleImagePath .. "module_personal_cloak.png",
                limit = 1,
                cost = 400 * COST_MULT,
                prohibitingModules = {"commweapon_personal_shield", "commweapon_areashield"},
                requireLevel = 2,
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.decloakDistance = math.max(sharedData.decloakDistance or 0, 150)
                    sharedData.personalCloak = true
                    sharedData.speedMultPost = (sharedData.speedMultPost or 1) - 0.12
                end,
                hardcodedID=32
            },
            {
                name = "module_cloak_field",
                humanName = "Cloaking Field",
                description = "Cloaking Field - Cloaks all nearby units.",
                image = moduleImagePath .. "module_cloak_field.png",
                limit = 1,
                cost = 600 * COST_MULT,
                requireChassis = {"support", "strike", "knight"},
                requireOneOf = {"module_jammer"},
                requireLevel = 3,
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.areaCloak = true
                    sharedData.decloakDistance = 180
                    sharedData.cloakFieldRange = 320
                    sharedData.cloakFieldUpkeep = 15
                    sharedData.cloakFieldRecloakRate = 800 -- UI only, update in unit_commander_upgrade
                    sharedData.radarJammingRange = 320
                end,
                hardcodedID=33
            },
            {
                name = "module_resurrect",
                humanName = "Lazarus Device",
                description = "Lazarus Device - Upgrade nanolathe to allow resurrection.",
                image = moduleImagePath .. "module_resurrect.png",
                limit = 1,
                cost = 400 * COST_MULT,
                requireChassis = disableResurrect and {} or {"support", "knight"},
                requireLevel = 2,
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.canResurrect = true
                end,
                hardcodedID=34
            },
            {
                name = "module_jumpjet",
                humanName = "Jumpjets",
                description = "Jumpjets - Leap over obstacles and out of danger. Each High Powered Servos reduces jump reload by 1s.",
                image = moduleImagePath .. "module_jumpjet.png",
                limit = 1,
                cost = 400 * COST_MULT,
                requireChassis = {"knight"},
                requireLevel = 3,
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.canJump = true
                end,
                hardcodedID=35
            },
            
            -- Repeat Modules
            {
                name = "module_companion_drone",
                humanName = "Companion Drone",
                description = "Companion Drone - Commander spawns protective drones. Limit: 5",
                image = moduleImagePath .. "module_companion_drone.png",
                limit = 5,
                cost = 200 * COST_MULT,
                requireLevel = 2,
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.drones = (sharedData.drones or 0) + 1
                end,
                hardcodedID=36
            },
            {
                name = "module_battle_drone",
                humanName = "Battle Drone",
                description = "Battle Drone - Commander spawns heavy drones. Limit: 5, Requires Companion Drone",
                image = moduleImagePath .. "module_battle_drone.png",
                limit = 5,
                cost = 350 * COST_MULT,
                requireChassis = {"assault", "support", "knight"},
                requireOneOf = {"module_companion_drone"},
                requireLevel = 3,
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.droneheavyslows = (sharedData.droneheavyslows or 0) + 1
                end,
                hardcodedID=37
            },
            {
                name = "module_autorepair",
                humanName = "Autorepair",
                description = "Autorepair - Commander self-repairs at +" .. 12*HP_MULT .. " hp/s. Reduces Health by " .. 100*HP_MULT .. ". Limit: 5",
                image = moduleImagePath .. "module_autorepair.png",
                limit = 5,
                cost = 150 * COST_MULT,
                requireLevel = 1,
                requireChassis = {"strike", "knight"},
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 12*HP_MULT
                    sharedData.healthBonus = (sharedData.healthBonus or 0) - 100*HP_MULT
                end,
                hardcodedID=38
            },
            {
                name = "module_autorepair",
                humanName = "Autorepair",
                description = "Autorepair - Commander self-repairs at +" .. 10*HP_MULT .. " hp/s. Reduces Health by " .. 100*HP_MULT .. ". Limit: 5",
                image = moduleImagePath .. "module_autorepair.png",
                limit = 5,
                cost = 150 * COST_MULT,
                requireLevel = 1,
                requireChassis = {"assault", "recon", "support"},
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 10*HP_MULT
                    sharedData.healthBonus = (sharedData.healthBonus or 0) - 100*HP_MULT
                end,
                hardcodedID=39
            },
            {
                name = "module_ablative_armor",
                humanName = "Ablative Armour Plates",
                description = "Ablative Armour Plates - Provides " .. 750*HP_MULT .. " health. Limit: 5",
                image = moduleImagePath .. "module_ablative_armor.png",
                limit = 5,
                cost = 150 * COST_MULT,
                requireLevel = 1,
                requireChassis = {"assault", "knight"},
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.healthBonus = (sharedData.healthBonus or 0) + 750*HP_MULT
                end,
                hardcodedID=40
            },
            {
                name = "module_heavy_armor",
                humanName = "High Density Plating",
                description = "High Density Plating - Provides " .. 2000*HP_MULT .. " health but reduces total speed by 2%. " ..
                "Limit: 5, Requires Ablative Armour Plates",
                image = moduleImagePath .. "module_heavy_armor.png",
                limit = 5,
                cost = 400 * COST_MULT,
                requireOneOf = {"module_ablative_armor"},
                requireLevel = 2,
                requireChassis = {"assault", "knight"},
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.healthBonus = (sharedData.healthBonus or 0) + 2000*HP_MULT
                    sharedData.speedMultPost = (sharedData.speedMultPost or 1) - 0.02
                end,
                hardcodedID=41
            },
            {
                name = "module_ablative_armor",
                humanName = "Ablative Armour Plates",
                description = "Ablative Armour Plates - Provides " .. 600*HP_MULT .. " health. Limit: 5",
                image = moduleImagePath .. "module_ablative_armor.png",
                limit = 5,
                cost = 150 * COST_MULT,
                requireLevel = 1,
                requireChassis = {"strike", "recon", "support"},
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.healthBonus = (sharedData.healthBonus or 0) + 600*HP_MULT
                end,
                hardcodedID=42
            },
            {
                name = "module_heavy_armor",
                humanName = "High Density Plating",
                description = "High Density Plating - Provides " .. 1600*HP_MULT .. " health but reduces total speed by 2%. " ..
                "Limit: 5, Requires Ablative Armour Plates",
                image = moduleImagePath .. "module_heavy_armor.png",
                limit = 5,
                cost = 400 * COST_MULT,
                requireOneOf = {"module_ablative_armor"},
                requireLevel = 2,
                requireChassis = {"strike", "recon", "support"},
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.healthBonus = (sharedData.healthBonus or 0) + 1600*HP_MULT
                    sharedData.speedMultPost = (sharedData.speedMultPost or 1) - 0.02
                end,
                hardcodedID=43
            },
            {
                name = "module_dmg_booster",
                humanName = "Damage Booster",
                description = "Damage Booster - Increases damage by 15% but reduces total speed by 2%.  Limit: 5",
                image = moduleImagePath .. "module_dmg_booster.png",
                limit = 5,
                cost = 150 * COST_MULT,
                requireLevel = 1,
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.damageMult = (sharedData.damageMult or 1) + 0.15
                    sharedData.speedMultPost = (sharedData.speedMultPost or 1) - 0.02
                end,
                hardcodedID=44
            },
            {
                name = "module_high_power_servos",
                humanName = "High Power Servos",
                description = "High Power Servos - Increases speed by 4 and reduced jump cooldown by 1s. Limit: 5",
                image = moduleImagePath .. "module_high_power_servos.png",
                limit = 5,
                cost = 200 * COST_MULT,
                requireLevel = 1,
                requireChassis = {"recon", "knight"},
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.speedMod = (sharedData.speedMod or 0) + 4
                    sharedData.jumpReloadMod = (sharedData.jumpReloadMod or 0) - 1
                end,
                hardcodedID=45
            },
            {
                name = "module_high_power_servos",
                humanName = "High Power Servos",
                description = "High Power Servos - Increases speed by 3.5. Limit: 5",
                image = moduleImagePath .. "module_high_power_servos.png",
                limit = 5,
                cost = 200 * COST_MULT,
                requireLevel = 1,
                requireChassis = {"strike", "assault", "support"},
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.speedMod = (sharedData.speedMod or 0) + 3.5
                end,
                hardcodedID=46
            },
            {
                name = "module_adv_targeting",
                humanName = "Adv. Targeting System",
                description = "Advanced Targeting System - Increases range by 7.5% but reduces total speed by 3%. Limit: 5",
                image = moduleImagePath .. "module_adv_targeting.png",
                limit = 5,
                cost = 200 * COST_MULT,
                requireLevel = 1,
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.rangeMult = (sharedData.rangeMult or 1) + 0.075
                    sharedData.speedMultPost = (sharedData.speedMultPost or 1) - 0.03
                end,
                hardcodedID=47
            },
            {
                name = "module_adv_nano",
                humanName = "CarRepairer's Nanolathe",
                description = "CarRepairer's Nanolathe - Increases build power by 6. Limit: 5",
                image = moduleImagePath .. "module_adv_nano.png",
                limit = 5,
                cost = 200 * COST_MULT,
                requireLevel = 1,
                requireChassis = {"support"},
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.bonusBuildPower = (sharedData.bonusBuildPower or 0) + 6
                end,
                hardcodedID=48
            },
            {
                name = "module_adv_nano",
                humanName = "CarRepairer's Nanolathe",
                description = "CarRepairer's Nanolathe - Increases build power by 5. Limit: 5",
                image = moduleImagePath .. "module_adv_nano.png",
                limit = 5,
                cost = 200 * COST_MULT,
                requireLevel = 1,
                requireChassis = {"strike", "assault", "knight"},
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.bonusBuildPower = (sharedData.bonusBuildPower or 0) + 5
                end,
                hardcodedID=49
            },
            {
                name = "module_adv_nano",
                humanName = "CarRepairer's Nanolathe",
                description = "CarRepairer's Nanolathe - Increases build power by 4. Limit: 5",
                image = moduleImagePath .. "module_adv_nano.png",
                limit = 5,
                cost = 200 * COST_MULT,
                requireLevel = 1,
                requireChassis = {"recon"},
                slotType = "module",
                applicationFunction = function (modules, sharedData)
                    sharedData.bonusBuildPower = (sharedData.bonusBuildPower or 0) + 4
                end,
                hardcodedID=50
            },
            -- Decorative Modules
            {
                name = "banner_overhead",
                humanName = "Banner",
                description = "Banner",
                image = moduleImagePath .. "module_ablative_armor.png",
                limit = 1,
                cost = 0,
                requireLevel = 0,
                slotType = "decoration",
                applicationFunction = function (modules, sharedData)
                    sharedData.bannerOverhead = true
                end,
                hardcodedID=51
            },

        }
        for key, value in pairs(moduleDefs) do
            if not value.requireChassis then
                value.requireChassis=basicChassis
            end
        end

        return moduleDefs
    end
}