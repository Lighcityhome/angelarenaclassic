require("internal/util")

LinkLuaModifier("duel_player_modifier", "duels/duel.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("duel_player_modifier_godmode", "duels/duel.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("duel_player_modifier_inactive", "duels/duel.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("duel_player_modifier_prepare_godmode", "duels/duel.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("duel_player_modifier_true_sight", "duels/duel.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("duel_player_modifier_true_sight_aura", "duels/duel.lua", LUA_MODIFIER_MOTION_NONE)

local SafeTeleportAll = require("duels/teleport").SafeTeleportAll

local DuelClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

local DuelClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

duel = class({})
duel_player_modifier = class(DuelClass)
duel_player_modifier_godmode = class(DuelClass)
duel_player_modifier_prepare_godmode = class(DuelClass)
duel_player_modifier_inactive = class(DuelClass)
duel_player_modifier_true_sight = class(DuelClass)
duel_player_modifier_true_sight_aura = class(DuelClassAura)

DUEL_INITIAL_TIME = 360 -- 6 minutes because 60 second before game starts
DUEL_CYCLE_TIME = 300 -- 5 minutes
DUEL_DURATION = 120 -- 2 minutes
DUEL_INITIAL_GODMODE_DURATION = 2 -- seconds
DUEL_RETURN_POSITIONS = {}

DUEL_TIMER = DUEL_TIMER or nil

IS_DUEL_ACTIVE = false

function Init()
    if not IsServer() then
        return
    end

    Timers:CreateTimer(DUEL_INITIAL_TIME, function ()
        duel:Start()
    end)

    CustomNetTables:SetTableValue("duel", "game_info", { active = false }) -- Just to ensure it starts at false

    Timers:CreateTimer(1.0, function()
        -- emit with parameter isduelactive
        CustomGameEventManager:Send_ServerToAllClients("duel_timer_changed", {isDuelActive = duel:IsDuelActive(), duration = DUEL_DURATION, ended = false})
        return 1.0
    end)

    local trueSightArea = Entities:FindByName(nil, "duel_boundary_trigger")

    local trueSightUnitProvider = CreateUnitByName("outpost_placeholder_unit", trueSightArea:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NOTEAM)
    trueSightUnitProvider:AddNoDraw()
    trueSightUnitProvider:AddNewModifier(trueSightUnitProvider, nil, "duel_player_modifier_true_sight", {})
end

function duel_player_modifier_true_sight:CheckState()
    local state = {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true
    }

    return state
end

function duel_player_modifier_true_sight:IsAura()
  return true
end

function duel_player_modifier_true_sight:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function duel_player_modifier_true_sight:GetAuraSearchTeam()
  return bit.bor(DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_TEAM_ENEMY)
end

function duel_player_modifier_true_sight:GetAuraRadius()
  return 9999
end

function duel_player_modifier_true_sight:GetModifierAura()
    return "duel_player_modifier_true_sight_aura"
end

function duel_player_modifier_true_sight:GetAuraEntityReject(ent) 
    if ent:HasModifier("modifier_slark_shadow_dance") or ent:HasModifier("modifier_slark_depth_shroud") then
        return true
    end
    
    return not duel:IsDuelActive() -- Only enables during duel
end

function duel_player_modifier_true_sight:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
end

function duel_player_modifier_true_sight:OnCreated()
    if not IsServer() then return end

    self:GetCaster():AddNoDraw()
end
--------------
function duel_player_modifier_true_sight_aura:CheckState()
    local states = {
        [MODIFIER_STATE_INVISIBLE] = false,
        [MODIFIER_STATE_TRUESIGHT_IMMUNE] = false
    }

    return states
end

function duel_player_modifier_true_sight_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
    }
end

function duel_player_modifier_true_sight_aura:IsHidden() return true end

function duel_player_modifier_true_sight_aura:GetModifierInvisibilityLevel()
    return 0
end

function duel_player_modifier_true_sight_aura:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end

function duel_player_modifier_true_sight_aura:GetTexture()
    return "item_gem"
end
---------------

function duel:Start()
    if not IsServer() or self:IsDuelActive() then return end

    local spawnRadiant = Entities:FindByName(nil, "duel_radiant_tp_point")
    local spawnDire = Entities:FindByName(nil, "duel_dire_tp_point")
    local countRadiant = self:GetPlayersInTeam(DOTA_TEAM_GOODGUYS, false)
    local countDire = self:GetPlayersInTeam(DOTA_TEAM_BADGUYS, false)
    local playerDifference = 0

    -- Make up for uneven player amounts
    if countRadiant == 0 or countDire == 0 then
        Timers:CreateTimer(DUEL_CYCLE_TIME, function ()
            self:Start()
        end)

        return
    elseif countRadiant ~= countDire then
        playerDifference = math.abs(countRadiant - countDire)-- 3-2=1
        --countradiant =3
        --countdire=2

        if countRadiant > countDire then
            countRadiant = countRadiant - playerDifference--returns 3-1=2
        elseif countDire > countRadiant then
            countDire = countDire - playerDifference
        end
    end

    -- Create End Timer
    DUEL_TIMER = Timers:CreateTimer(DUEL_DURATION, function ()
        -- Prevents the duel timer from being delayed by the duel duration
        if not self:IsDuelActive() then
            return
        end

        self:End(DUEL_RETURN_POSITIONS, nil)
    end)

    GameRules:GetGameModeEntity():SetBuybackEnabled(false)

    --[[
    -- Close Doors --
    for i=1, 8 do
        local door = Entities:FindByName(nil, "duel_door_1_" .. i)
        door:SetAbsOrigin(Vector(door:GetAbsOrigin().x, door:GetAbsOrigin().y, (door:GetAbsOrigin().z+500)))
        door:SetEnabled(true, true)
    end
    --
    --]]

    local allheroes = HeroList:GetAllHeroes()
    for _,hero in ipairs(allheroes) do
        hero:AddNewModifier(hero, nil, "duel_player_modifier_prepare_godmode", { duration = 1.0 })

        Timers:CreateTimer(1.0, function()
            hero:RemoveModifierByName("duel_player_modifier_prepare_godmode")

            if (UnitIsNotMonkeyClone(hero)) and (not hero:IsIllusion()) and (not hero:HasModifier("modifier_arc_warden_tempest_double")) then
                DUEL_RETURN_POSITIONS[hero:GetPlayerID()] = hero:GetAbsOrigin()

                if not hero:IsAlive() or hero:WillReincarnate() or hero:IsReincarnating() then
                    hero:SetTimeUntilRespawn(0)
                    hero:RespawnHero(false, false)
                end

                Timers:CreateTimer(0.5, function()
                    CustomNetTables:SetTableValue("duel", "game_info", { active = true })

                    local connectionState = PlayerResource:GetConnectionState(hero:GetPlayerID())
                    -- Remove all normal debuffs and buffs (counts as hard dispell)
                    hero:Stop() -- In case they're teleporting, or channeling, etc.
                    hero:Purge(true, true, false, true, false) 
                    duel:RemoveSuperRunes(hero)
                    
                    if connectionState ~= DOTA_CONNECTION_STATE_CONNECTED then
                        hero:AddNewModifier(hero, nil, "duel_player_modifier_inactive",  {})
                    elseif hero:GetTeam() == DOTA_TEAM_GOODGUYS and countRadiant <= 0 then
                        hero:AddNewModifier(hero, nil, "duel_player_modifier_inactive",  {})
                    elseif hero:GetTeam() == DOTA_TEAM_BADGUYS and countDire <= 0 then
                        hero:AddNewModifier(hero, nil, "duel_player_modifier_inactive",  {})
                    else
                        hero:AddNewModifier(hero, nil, "duel_player_modifier",  { timerName = DUEL_TIMER })

                        hero:Heal(hero:GetMaxHealth(), nil)
                        hero:SetMana(hero:GetMaxMana())

                        if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
                            SafeTeleportAll(hero, spawnRadiant:GetAbsOrigin(), 100)
                            countRadiant = countRadiant - 1
                        else
                            SafeTeleportAll(hero, spawnDire:GetAbsOrigin(), 100)
                            countDire = countDire - 1
                        end

                        duel:ResetCooldowns(hero)

                        CenterCameraOnUnit(hero:GetPlayerOwnerID(), hero)

                        hero:SetRespawnsDisabled(true)
                    end
                end)
            end
        end)
    end

    IS_DUEL_ACTIVE = true
end
    
function duel:RemoveSuperRunes(hero)
    if hero == nil then return end

    local modifiers = {
        "modifier_rune_super_invis",
        "modifier_rune_super_regen",
        "modifier_rune_super_arcane"
    }

    for _,mod in ipairs(modifiers) do
        if hero:HasModifier(mod) then
            hero:RemoveModifierByName(mod)
        end
    end
end

function duel:IsDuelActive()
    if not IsServer() then return end

    local count = 0

    local allheroes = HeroList:GetAllHeroes()
    for _,hero in ipairs(allheroes) do
        if UnitIsNotMonkeyClone(hero) and hero:HasModifier("duel_player_modifier") and (not hero:IsIllusion()) and (not hero:HasModifier("modifier_arc_warden_tempest_double")) then
            count = count + 1
        end
    end

    return count > 0
end

function duel:End(returnPositions, timerName)
    if not self:IsDuelActive() then
        return
    end

    local allheroes = HeroList:GetAllHeroes()
    for _,hero in ipairs(allheroes) do
        if UnitIsNotMonkeyClone(hero) and hero:HasModifier("duel_player_modifier_inactive") and (not hero:IsIllusion()) and (not hero:HasModifier("modifier_arc_warden_tempest_double")) then
            Timers:CreateTimer(1.0, function() 
                hero:RemoveModifierByName("duel_player_modifier_inactive")
                hero:Purge(true, true, false, true, false) 
            end)
        elseif (UnitIsNotMonkeyClone(hero) and not hero:IsIllusion()) then
            Timers:CreateTimer(1.0, function() 
                hero:RemoveModifierByName("duel_player_modifier")
                hero:Purge(true, true, false, true, false) 
            end)
        end
    end

    GameRules:GetGameModeEntity():SetBuybackEnabled(true)

    IS_DUEL_ACTIVE = false

    CustomNetTables:SetTableValue("duel", "game_info", { active = false })

    if timerName ~= nil then
        Timers:RemoveTimer(timerName)
    end

    Timers:CreateTimer(1.0, function()
        CustomGameEventManager:Send_ServerToAllClients("duel_end", {})
    end)

    Timers:CreateTimer(DUEL_CYCLE_TIME, function ()
        self:Start()
    end)

    --[[
    -- Open Doors --
    for i=1, 8 do
        local door = Entities:FindByName(nil, "duel_door_1_" .. i)
        door:SetAbsOrigin(Vector(door:GetAbsOrigin().x, door:GetAbsOrigin().y, (door:GetAbsOrigin().z-500)))
        door:SetEnabled(false, true)
    end
    --
    --]]
end

function duel_player_modifier:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_EVENT_ON_RESPAWN,
        MODIFIER_EVENT_ON_TELEPORTING
    }

    return funcs
end

function duel_player_modifier:IsHidden()
    return true
end

function duel_player_modifier:OnCreated(params)
    if not IsServer() then
        return
    end

    local parent = self:GetParent()

    self.duelBoundary = Entities:FindByName(nil, "duel_boundary_trigger")
    self.lastPosition = parent:GetAbsOrigin() -- This is overwritten during duel and used to store the location inside of the duel
    self.timerName = params.timerName
    
    -- Save the position before they're actually teleported into the duel
    -- This is only used for when the duel is ended prematurely by one team killing the other
    -- This logic does not affect them if the duel ends by the timer running out
    self.startPosition = parent:GetAbsOrigin()

    DUEL_RETURN_POSITIONS[parent:GetPlayerID()] = self.startPosition

    parent:AddNewModifier(parent, nil, "duel_player_modifier_godmode", { duration = DUEL_INITIAL_GODMODE_DURATION })

    if parent:IsAlive() then
        Timers:CreateTimer(2, function() 
            self:StartIntervalThink(0.5) 
        end)
    end

    IS_DUEL_ACTIVE = true
end

function duel_player_modifier:OnIntervalThink()
    if not IsServer() then
        return
    end

    local parent = self:GetParent()

    if not IS_DUEL_ACTIVE then
        parent:RemoveModifierByNameAndCaster("duel_player_modifier", parent)
        self:StartIntervalThink(-1)
        return
    end

    --[[if IsInTrigger(parent, self.duelBoundary) then
        local retPos = parent:GetAbsOrigin()

        -- As long as the return position is inside the duel boundary, we set it to that,
        -- otherwise they could get stuck in an infinite loop
        if IsPositionInTrigger(retPos, self.duelBoundary) then
            self.lastPosition = parent:GetAbsOrigin()
        end
    elseif parent:IsAlive() then
        SafeTeleportAll(parent, self.lastPosition, 100)
    end]]--

    if not IsInTrigger(parent, self.duelBoundary) and parent:IsAlive() then
        if parent:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
            SafeTeleportAll(parent, Entities:FindByName(nil, "duel_radiant_tp_point"):GetAbsOrigin(), 100)
        else
            SafeTeleportAll(parent, Entities:FindByName(nil, "duel_dire_tp_point"):GetAbsOrigin(), 100)
        end
    end
end

function duel_player_modifier:OnDestroy()
    if not IsServer() then
        return
    end

    self:StartIntervalThink(-1)
    
    local parent = self:GetParent()

    parent:SetRespawnsDisabled(false)
    parent:Heal(parent:GetMaxHealth(), nil)
    parent:SetMana(parent:GetMaxMana())

    SafeTeleportAll(parent, DUEL_RETURN_POSITIONS[parent:GetPlayerID()], 100)
    CenterCameraOnUnit(parent:GetPlayerOwnerID(), parent)
    parent:Purge(true, true, false, true, false) 
end

function duel_player_modifier:OnTeleporting(event)
    if not IsServer() then
        return
    end

    if event.unit ~= self:GetParent() then
        return
    end

    -- Do not let them teleport during duel
    event.unit:Stop()
end

function duel_player_modifier:OnRespawn(event)
    if not IsServer() then
        return
    end

    if event.unit ~= self:GetParent() or not IS_DUEL_ACTIVE then
        return
    end

    event.unit:SetRespawnsDisabled(true)
end

function duel_player_modifier:OnDeath(event)
    if not IsServer() then
        return
    end

    if event.unit ~= self:GetParent() then
        return
    end

    -- Don't trigger anything if they're reincarning, e.g. WK ult, or aegis.
    if WillReincarnateUBA(event.unit) then
        event.unit:SetRespawnsDisabled(false)
        event.unit:SetTimeUntilRespawn(5.0)

        return
    end

    if duel:GetPlayersInTeam(DOTA_TEAM_GOODGUYS, true) <= 0 then
        GameRules:SendCustomMessage("<font color='lightgreen'>Demons have triumphed over the angels!</font>", 0, 0)
        Timers:CreateTimer(1, function() -- To prevent the respawn script from messing up respawning positions, or they'll respawn in base instead of old positions
            IS_DUEL_ACTIVE = false
            duel:End(DUEL_RETURN_POSITIONS, self.timerName)
        end)
    elseif duel:GetPlayersInTeam(DOTA_TEAM_BADGUYS, true) <= 0 then
        GameRules:SendCustomMessage("<font color='lightgreen'>Angels have triumphed over the demons!", 0, 0)
        Timers:CreateTimer(1, function() 
            IS_DUEL_ACTIVE = false
            duel:End(DUEL_RETURN_POSITIONS, self.timerName)
        end)
    end
end

function duel:GetIntrinsicModifierName()
    return "duel_player_modifier"
end

function duel:GetPlayersInTeam(teamId, alive)
    local count = 0

    local allheroes = HeroList:GetAllHeroes()
    for _,hero in ipairs(allheroes) do
        local connectionState = PlayerResource:GetConnectionState(hero:GetPlayerID())

        if connectionState == DOTA_CONNECTION_STATE_CONNECTED and UnitIsNotMonkeyClone(hero) and not hero:HasModifier("duel_player_modifier_inactive") and not hero:IsIllusion() and not hero:HasModifier("modifier_arc_warden_tempest_double") then
            if alive then 
                if hero:GetTeam() == teamId and (hero:IsAlive() or hero:WillReincarnate() or hero:IsReincarnating()) then
                    count = count + 1
                end
            else
                if hero:GetTeam() == teamId then
                    count = count + 1
                end
            end
        end
    end

    return count
end

function duel_player_modifier_godmode:IsHidden()
    return true
end

function duel_player_modifier_godmode:DeclareFunctions() 
    local funcs = {}

    return funcs
end

function duel_player_modifier_inactive:DeclareFunctions()
    local funcs = {
        
    }

    return funcs
end

function duel_player_modifier_inactive:OnCreated()
    if not IsServer() then
        return
    end

    local parent = self:GetParent()
    local team = parent:GetTeam()

    parent:AddNoDraw()

    parent:SetRespawnsDisabled(false)

    DUEL_RETURN_POSITIONS[parent:GetPlayerID()] = parent:GetAbsOrigin()

    local lockedOutSpawnRadiant = Entities:FindByName(nil, "duel_radiant_locked_point")
    local lockedOutSpawnDire = Entities:FindByName(nil, "duel_dire_locked_point")

    if team == DOTA_TEAM_GOODGUYS then
        SafeTeleportAll(parent, lockedOutSpawnRadiant:GetAbsOrigin(), 100)
    else
        SafeTeleportAll(parent, lockedOutSpawnDire:GetAbsOrigin(), 100)
    end

    CenterCameraOnUnit(parent:GetPlayerOwnerID(), parent)

    IS_DUEL_ACTIVE = true
end

function duel_player_modifier_inactive:OnDestroy()
    if not IsServer() then
        return
    end
    
    local parent = self:GetParent()

    parent:RemoveNoDraw()

    parent:SetRespawnsDisabled(false)

    SafeTeleportAll(parent, DUEL_RETURN_POSITIONS[parent:GetPlayerID()], 100)

    CenterCameraOnUnit(parent:GetPlayerOwnerID(), parent)
end

function duel_player_modifier_inactive:CheckState()
    local state = {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_MUTED] = true,
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_OUT_OF_GAME] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_PROVIDES_VISION] = false
    }

    return state
end

function duel_player_modifier_godmode:CheckState()
    local state = {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_MUTED] = true,
        [MODIFIER_STATE_SILENCED] = true
    }

    return state
end

function duel_player_modifier_prepare_godmode:DeclareFunctions() 
    local funcs = {}

    return funcs
end

function duel_player_modifier_prepare_godmode:CheckState() 
    local state = {
        [MODIFIER_STATE_INVULNERABLE] = true
    }

    return state
end

function duel:ResetCooldowns(unit)
    for i=0, unit:GetAbilityCount()-1 do
        local abil = unit:GetAbilityByIndex(i)
        if abil ~= nil then
            abil:EndCooldown()
            abil:SetCurrentAbilityCharges(abil:GetMaxAbilityCharges(abil:GetLevel() - 1))
        end
    end

    for i=0,8 do
        local item = unit:GetItemInSlot(i)
        if item ~= nil then
            item:EndCooldown()
        end
    end

    if unit:HasModifier("modifier_aeon_of_tarrasque_cooldown") then
        unit:RemoveModifierByNameAndCaster("modifier_aeon_of_tarrasque_cooldown", unit)
    end
end

function SetOriginalRespawnPosition(hero)
    local direFountain = Entities:FindByName(nil, "ent_dota_fountain_bad")
    local radiantFountain = Entities:FindByName(nil, "ent_dota_fountain_good")

    if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
        hero:SetRespawnPosition(radiantFountain:GetAbsOrigin())
    elseif hero:GetTeam() == DOTA_TEAM_BADGUYS then
        hero:SetRespawnPosition(direFountain:GetAbsOrigin())
    end
end