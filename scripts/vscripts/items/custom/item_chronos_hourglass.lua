LinkLuaModifier("modifier_chronos_hourglass", "items/custom/item_chronos_hourglass.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chronos_hourglass_effect", "items/custom/item_chronos_hourglass.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chronos_hourglass_aura", "items/custom/item_chronos_hourglass.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chronos_hourglass_butterfly_effect", "items/custom/item_chronos_hourglass.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseAuraClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
    IsPurgeException = function(self) return false end,
}

local ItemBaseButterflyClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
    IsPurgeException = function(self) return false end,
}

item_chronos_hourglass = class(ItemBaseClass)
item_chronos_hourglass_2 = item_chronos_hourglass
item_chronos_hourglass_3 = item_chronos_hourglass
modifier_chronos_hourglass = class(item_chronos_hourglass)
modifier_chronos_hourglass_effect = class(item_chronos_hourglass)
modifier_chronos_hourglass_aura = class(ItemBaseAuraClass)
modifier_chronos_hourglass_butterfly_effect = class(ItemBaseButterflyClass)

local ABILITIES_COOLDOWN = ABILITIES_COOLDOWN or {}
local ABILITIES_EXCEPTION = {
    ["dark_willow_shadow_realm"] = true,
    ["shadow_shaman_shackles"] = true
}

function IsAbilityException(ability)
    return ABILITIES_EXCEPTION[ability]
end
-------------
function item_chronos_hourglass:GetIntrinsicModifierName()
    return "modifier_chronos_hourglass"
end

function item_chronos_hourglass:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local duration = self:GetLevelSpecialValueFor("anomaly_duration", (self:GetLevel() - 1))

    caster:AddNewModifier(caster, self, "modifier_chronos_hourglass_effect", { duration = duration })
end

-------------
function modifier_chronos_hourglass_effect:DeclareFunctions()
    local state = {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE, --GetModifierDamageOutgoing_Percentage
        MODIFIER_EVENT_ON_DEATH,
    }
    return state
end

function modifier_chronos_hourglass_effect:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("anomaly_damage_reduction", (self:GetAbility():GetLevel() - 1))
end

function modifier_chronos_hourglass_effect:OnCreated()
    if not IsServer() then return end

    self.radius = self:GetAbility():GetLevelSpecialValueFor("anomaly_radius", (self:GetAbility():GetLevel() - 1))

    self:PlayEffects()
end

function modifier_chronos_hourglass_effect:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetCaster() then return end

    self:GetCaster():RemoveModifierByNameAndCaster("modifier_chronos_hourglass_effect", self:GetCaster())
    ParticleManager:DestroyParticle(self.effect_cast, true)
end

function modifier_chronos_hourglass_effect:PlayEffects()
    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle("particles/arc_warden_magnetic_custom.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControl(self.effect_cast, 0, self:GetParent():GetOrigin())
    ParticleManager:SetParticleControl(self.effect_cast, 1, Vector( self.radius, self.radius, self.radius ))

    -- buff particle
    self:AddParticle(
        self.effect_cast,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        true, -- bHeroEffect
        false -- bOverheadEffect
    )

    -- Create Sound
    
    EmitSoundOnLocationWithCaster(self:GetParent():GetOrigin(), "Hero_FacelessVoid.Chronosphere.MaceOfAeons", self:GetParent())
    EmitSoundOnLocationWithCaster(self:GetParent():GetOrigin(), "Hero_ArcWarden.MagneticField", self:GetParent())
end

function modifier_chronos_hourglass_effect:OnRemoved()
    StopSoundOn("Hero_ArcWarden.MagneticField", self:GetParent())
end

function modifier_chronos_hourglass_effect:IsAura()
  return true
end

function modifier_chronos_hourglass_effect:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_chronos_hourglass_effect:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_chronos_hourglass_effect:GetAuraRadius()
  return self.radius
end

function modifier_chronos_hourglass_effect:GetModifierAura()
    return "modifier_chronos_hourglass_aura"
end
------------
function modifier_chronos_hourglass:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,--GetModifierMoveSpeedBonus_Constant
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_MANA_BONUS, -- GetModifierManaBonus
        MODIFIER_PROPERTY_MANA_REGEN_PERCENTAGE, -- GetModifierPercentageManaRegen
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_CAST_RANGE_BONUS, --GetModifierCastRangeBonus
        MODIFIER_PROPERTY_MANACOST_PERCENTAGE, --GetModifierPercentageManacost
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST
    }

    return funcs
end

function modifier_chronos_hourglass:OnCreated()
    if not IsServer() then return end

    local rewindInterval = self:GetAbility():GetLevelSpecialValueFor("rewind_interval", (self:GetAbility():GetLevel() - 1))
    local rewindReduction = self:GetAbility():GetLevelSpecialValueFor("rewind_reduction", (self:GetAbility():GetLevel() - 1))
    local caster = self:GetCaster()
    local abilities = {}
    self.rewindTimer = nil

    self.rewindTimer = Timers:CreateTimer(rewindInterval, function ()
        for i=0, caster:GetAbilityCount()-1 do
            local current_ability = caster:GetAbilityByIndex(i)
            if current_ability and current_ability:GetAbilityType() ~= ABILITY_TYPE_ULTIMATE and not current_ability:IsPassive() and not current_ability:IsAttributeBonus() and not current_ability:IsCooldownReady() then
                local pass = false
                if not IsAbilityException(current_ability:GetAbilityName()) then
                    pass = true
                end

                if pass then
                    table.insert(abilities, current_ability)
                end
            end
        end

        if #abilities < 1 then return rewindInterval end

        local randomAbility = abilities[RandomInt(1, #abilities)]
        local remainingTime = randomAbility:GetCooldownTimeRemaining()

        if remainingTime <= 1 then
            -- Do not decrease cooldown of abilities that are just about to go off cooldown
            return
        end

        local newCooldown = remainingTime - rewindReduction
        
        if newCooldown < 1 then
            newCooldown = 1
        end

        randomAbility:EndCooldown()
        randomAbility:StartCooldown(newCooldown)

        abilities = {}

        return rewindInterval
    end)

    self.unavailableAbilities = {}
end

function modifier_chronos_hourglass:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if self.rewindTimer ~= nil then
        Timers:RemoveTimer(self.rewindTimer)
    end

    caster:RemoveModifierByNameAndCaster("modifier_chronos_hourglass_effect", caster)
    caster:RemoveModifierByNameAndCaster("modifier_chronos_hourglass_aura", caster)
    caster:RemoveModifierByNameAndCaster("modifier_chronos_hourglass_butterfly_effect", caster)
end

function modifier_chronos_hourglass:OnAbilityFullyCast(event)
    if event.unit ~= self:GetParent() then return end
    if event.ability:IsItem() or event.ability:IsToggle() or event.ability:GetAbilityType() == ABILITY_TYPE_ULTIMATE or self.unavailableAbilities[event.ability:GetAbilityIndex()] ~= nil then return end

    local caster = self:GetCaster()
    local remainingTime = event.ability:GetCooldownTimeRemaining()

    local modifier = caster:FindModifierByNameAndCaster("modifier_chronos_hourglass_butterfly_effect", caster)
    if not modifier then
        caster:AddNewModifier(caster, self:GetAbility(), "modifier_chronos_hourglass_butterfly_effect", { duration = remainingTime })
        caster:SetModifierStackCount("modifier_chronos_hourglass_butterfly_effect", caster, 1)
    else
        caster:SetModifierStackCount("modifier_chronos_hourglass_butterfly_effect", caster, (caster:GetModifierStackCount("modifier_chronos_hourglass_butterfly_effect", caster)+1))
        modifier:ForceRefresh()
    end

    self.unavailableAbilities[event.ability:GetAbilityIndex()] = true or nil
    Timers:CreateTimer(remainingTime, function()
        caster:SetModifierStackCount("modifier_chronos_hourglass_butterfly_effect", caster, (caster:GetModifierStackCount("modifier_chronos_hourglass_butterfly_effect", caster)-1))
        self.unavailableAbilities[event.ability:GetAbilityIndex()] = nil
    end)
end

function modifier_chronos_hourglass:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_chronos_hourglass:GetModifierManaBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana", (self:GetAbility():GetLevel() - 1))
end

function modifier_chronos_hourglass:GetModifierPercentageManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_chronos_hourglass:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_chronos_hourglass:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_chronos_hourglass:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1)) + self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_chronos_hourglass:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("mana_regen_multiplier", (self:GetAbility():GetLevel() - 1))
end

function modifier_chronos_hourglass:GetModifierCastRangeBonus()
    return self:GetAbility():GetLevelSpecialValueFor("cast_range_bonus", (self:GetAbility():GetLevel() - 1))
end

function modifier_chronos_hourglass:GetModifierPercentageManacost()
    return self:GetAbility():GetLevelSpecialValueFor("mana_cost_reduction_pct", (self:GetAbility():GetLevel() - 1))
end
--------------
function modifier_chronos_hourglass_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_CASTTIME_PERCENTAGE, --GetModifierPercentageCasttime
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
    }

    return funcs
end

function modifier_chronos_hourglass_aura:OnAbilityFullyCast(event)
    if not IsServer() then return end 
    if event.unit ~= self:GetParent() then return end
    if event.ability:IsItem() or ABILITIES_COOLDOWN[event.ability:GetAbilityIndex()] ~= nil then return end

    local remainingTime = event.ability:GetCooldownTimeRemaining()
    local cd_increase = remainingTime * (1 + (self.cooldownIncrease / 100))
    event.ability:EndCooldown()
    event.ability:StartCooldown(cd_increase)
    ABILITIES_COOLDOWN[event.ability:GetAbilityIndex()] = true or nil

    Timers:CreateTimer(event.ability:GetCooldownTimeRemaining(), function()
        ABILITIES_COOLDOWN[event.ability:GetAbilityIndex()] = nil
    end)
end

function modifier_chronos_hourglass_aura:OnCreated()
    if not IsServer() then return end

    self.cooldownIncrease = math.abs(self:GetAbility():GetLevelSpecialValueFor("anomaly_cooldown_increase", (self:GetAbility():GetLevel() - 1)))

    self:PlayEffects()

    self:ExtendCurrentCooldowns()  
end

function modifier_chronos_hourglass_aura:OnRemoved()
    if not IsServer() then return end
end

function modifier_chronos_hourglass_aura:ExtendCurrentCooldowns()
    local parent = self:GetParent()

    -- Iterate through the enemies abilities
    for i=0, parent:GetAbilityCount()-1 do
        local current_ability = parent:GetAbilityByIndex(i)
        if current_ability and not current_ability:IsPassive() and not current_ability:IsAttributeBonus() and not current_ability:IsCooldownReady() then
            -- If the remaining time is more than the default cooldown, it means we've already increased it
            if ABILITIES_COOLDOWN[current_ability:GetAbilityIndex()] ~= nil then return end

            local remainingTime = current_ability:GetCooldownTimeRemaining()
            local cd_increase = remainingTime * (1 + (self.cooldownIncrease / 100))
            current_ability:EndCooldown()
            current_ability:StartCooldown(cd_increase)
            ABILITIES_COOLDOWN[current_ability:GetAbilityIndex()] = true or nil

            Timers:CreateTimer(current_ability:GetCooldownTimeRemaining(), function()
                ABILITIES_COOLDOWN[current_ability:GetAbilityIndex()] = nil
            end)
        end
    end
end

function modifier_chronos_hourglass_aura:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetLevelSpecialValueFor("anomaly_reduction", (self:GetAbility():GetLevel() - 1))
end

function modifier_chronos_hourglass_aura:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("anomaly_reduction", (self:GetAbility():GetLevel() - 1))
end

function modifier_chronos_hourglass_aura:GetModifierPercentageCasttime()
    return self:GetAbility():GetLevelSpecialValueFor("anomaly_reduction", (self:GetAbility():GetLevel() - 1))
end

function modifier_chronos_hourglass_aura:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_faceless_void/faceless_void_chrono_speed.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    -- ParticleManager:SetParticleControl( effect_cast, iControlPoint, vControlVector )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        self:GetParent(),
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    -- buff particle
    self:AddParticle(
        effect_cast,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        false, -- bHeroEffect
        false -- bOverheadEffect
    )
end
------------------
function modifier_chronos_hourglass_butterfly_effect:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
    }

    return funcs
end

function modifier_chronos_hourglass_butterfly_effect:OnCreated() end

function modifier_chronos_hourglass_butterfly_effect:GetModifierMoveSpeedBonus_Percentage()
    return self:GetCaster():GetModifierStackCount("modifier_chronos_hourglass_butterfly_effect", self:GetCaster()) * self:GetAbility():GetLevelSpecialValueFor("butterfly_effect_bonus_movement_speed_pct", (self:GetAbility():GetLevel() - 1))
end