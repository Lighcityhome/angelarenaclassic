local export = {}

local function SafeTeleport(unit, location, maxDistance)
  if not unit:IsAlive() and unit:IsHero() then
    unit:SetRespawnsDisabled(false)
    unit:RespawnHero(false, false)
  end
  
  unit:Stop()
  if unit:FindModifierByName("modifier_life_stealer_infest") then
    DebugPrint("Found Lifestealer infesting")
    local ability = unit:FindAbilityByName("life_stealer_consume")
    if ability and ability:IsActivated() then
      unit:CastAbilityNoTarget(ability, unit:GetPlayerOwnerID())
    else
      print("Error: Could not find Consume ability on an Infesting unit")
      D2CustomLogging:sendPayloadForTracking(D2CustomLogging.LOG_LEVEL_INFO, "COULD NOT FIND CONSUME ABILITY", {
        ErrorMessage = "Tried to teleport an Infesting unit, but could not find Consume ability on that unit, or ability was not castable",
        ErrorTime = GetSystemDate() .. " " .. GetSystemTime(),
        GameVersion = GAME_VERSION,
        DedicatedServers = (IsDedicatedServer() and 1) or 0,
        MatchID = tostring(GameRules:GetMatchID())
      })
    end
  end
  if unit:FindModifierByName("modifier_life_stealer_assimilate_effect") then
    DebugPrint("Found Lifestealer with assimilated unit")
    local ability = unit:FindAbilityByName("life_stealer_assimilate_eject")
    if ability and ability:IsActivated() then
      unit:CastAbilityNoTarget(ability, unit:GetPlayerOwnerID())
    else
      print("Error: Could not find Eject ability on an Assimilating unit")
      D2CustomLogging:sendPayloadForTracking(D2CustomLogging.LOG_LEVEL_INFO, "COULD NOT FIND EJECT ABILITY", {
        ErrorMessage = "Tried to teleport an Assimilating unit, but could not find Eject ability on that unit, or ability was not castable",
        ErrorTime = GetSystemDate() .. " " .. GetSystemTime(),
        GameVersion = GAME_VERSION,
        DedicatedServers = (IsDedicatedServer() and 1) or 0,
        MatchID = tostring(GameRules:GetMatchID())
      })
    end
  end
  local exileModifiers = {
    "modifier_obsidian_destroyer_astral_imprisonment_prison",
    "modifier_phantomlancer_dopplewalk_phase",
    --"modifier_riki_tricks_of_the_trade_phase", -- Should be removed by stop order
    -- "modifier_sohei_flurry_self", -- Bugs out hard if it occurs during casting. TODO: Update after PR #2025
    --"modifier_puck_phase_shift", -- Should be removed by stop order
    "modifier_phoenix_supernova_hiding",
    "modifier_shadow_demon_disruption",
    -- Removing Snowball movement modifiers just seems to cause glitches instead of helping
    -- "modifier_tusk_snowball_movement",
    -- "modifier_tusk_snowball_movement_friendly",
    "modifier_tusk_snowball_visible", -- Gets applied to snowball targets; grants vision of target
    "modifier_tusk_snowball_target", -- Gets applied to snowball targets; places indicator above target(?)
    "modifier_ember_spirit_sleight_of_fist_in_progress",
    "modifier_ember_spirit_sleight_of_fist_marker",
    "modifier_ember_spirit_sleight_of_fist_caster",
    "modifier_ember_spirit_sleight_of_fist_caster_invulnerability",
  }
  for _,mdf in ipairs(exileModifiers) do
    unit:RemoveModifierByName(mdf)
  end
  --iter(exileModifiers):foreach(partial(unit.RemoveModifierByName, unit))

  location = GetGroundPosition(location, unit)
  FindClearSpaceForUnit(unit, location, true)
  Timers:CreateTimer(0.1, function()
    if not unit or unit:IsNull() then
      return
    end
    local distance = (location - unit:GetAbsOrigin()):Length2D()
    if distance > maxDistance then
      SafeTeleport(unit, location, maxDistance)
    end
  end)
end

local function SafeTeleportAll(mainUnit, location, maxDistance)
  SafeTeleport(mainUnit, location, maxDistance)
  local playerAdditionalUnits
  local playerAdditionalUnitsTemp
  playerAdditionalUnitsTemp = FindUnitsInRadius(mainUnit:GetTeam(),
                                            mainUnit:GetAbsOrigin(),
                                            nil,
                                            FIND_UNITS_EVERYWHERE,
                                            DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                                            bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
                                            DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED,
                                            FIND_ANY_ORDER,
                                            false)
  playerAdditionalUnitsTemp = playerAdditionalUnitsTemp or {} -- assign empty table instead of nil so iter can be called without errors
  playerAdditionalUnits = playerAdditionalUnits or {}
  for _,adtu in ipairs(playerAdditionalUnitsTemp) do
    if adtu:IsIllusion() then
      adtu:ForceKill(false)
    end

    if adtu:GetPlayerOwnerID() == mainUnit:GetPlayerOwnerID() and (not adtu:IsCourier()) and (not adtu:IsIllusion()) and (not adtu:HasModifier("modifier_arc_warden_tempest_double")) then
      table.insert(playerAdditionalUnits, adtu)
    end
  end

  for _,totp in ipairs(playerAdditionalUnits) do
    if totp:HasMovementCapability() and not totp:IsIllusion() and not totp:HasModifier("modifier_arc_warden_tempest_double") then
      SafeTeleport(totp, location, maxDistance)
    end
  end
end

-- Test SafeTeleport function
local function TestSafeTeleport(keys)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  SafeTeleportAll(hero, Vector(0, 0, 0), 150)
end

export.SafeTeleport = SafeTeleport
export.SafeTeleportAll = SafeTeleportAll

return export
