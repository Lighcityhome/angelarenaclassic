require("internal/util")

LinkLuaModifier("modifier_curse_bearer", "items/custom/item_curse_bearer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_curse_bearer_frost_debuff", "items/custom/item_curse_bearer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_curse_bearer_debuff", "items/custom/item_curse_bearer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_curse_bearer_explosion_debuff", "items/custom/item_curse_bearer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_curse_bearer_curse", "items/custom/item_curse_bearer.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseDebuffClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

local ItemBaseHardDebuffClass = {
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
    IsPurgable = function(self) return false end,
    IsPurgeException = function(self) return true end,
}

item_curse_bearer = class(ItemBaseClass)
item_curse_bearer_2 = item_curse_bearer
item_curse_bearer_3 = item_curse_bearer
modifier_curse_bearer_debuff = class(ItemBaseHardDebuffClass)
modifier_curse_bearer_explosion_debuff = class(ItemBaseHardDebuffClass)
modifier_curse_bearer_curse = class(ItemBaseHardDebuffClass)
modifier_curse_bearer = class(item_curse_bearer)
modifier_curse_bearer_frost_debuff = class(ItemBaseDebuffClass)
-------------
function item_curse_bearer:GetIntrinsicModifierName()
    return "modifier_curse_bearer"
end

function modifier_curse_bearer:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_MANA_BONUS, --GetModifierManaBonus
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen   
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_PROJECTILE_NAME
    }

    return funcs
end

function modifier_curse_bearer:OnCreated()
    if not IsServer() then return end

    self.maxStacks = self:GetAbility():GetLevelSpecialValueFor("max_stacks", (self:GetAbility():GetLevel() - 1))
    self.reductionInterval = self:GetAbility():GetLevelSpecialValueFor("reduction_interval", (self:GetAbility():GetLevel() - 1))
    self.afflictionDuration = self:GetAbility():GetLevelSpecialValueFor("affliction_duration", (self:GetAbility():GetLevel() - 1))
    self.explosionRadius = self:GetAbility():GetLevelSpecialValueFor("explosion_radius", (self:GetAbility():GetLevel() - 1))
    self.explosionDamage = self:GetAbility():GetLevelSpecialValueFor("explosion_damage", (self:GetAbility():GetLevel() - 1))
    self.explosionDuration = self:GetAbility():GetLevelSpecialValueFor("explosion_duration", (self:GetAbility():GetLevel() - 1))
    self.frostDuration = self:GetAbility():GetLevelSpecialValueFor("frost_duration", (self:GetAbility():GetLevel() - 1))

    self.originalProjectile = self:GetParent():GetRangedProjectileName()
end

function modifier_curse_bearer:GetModifierProjectileName()
    return "particles/items2_fx/skadi_projectile.vpcf"
end

function modifier_curse_bearer:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target
    local ability = self:GetAbility()

    if ability == nil or not ability then return end

    if self:GetCaster() ~= attacker then
        return
    end

    if attacker:IsIllusion() or not attacker:IsRealHero() or not UnitIsNotMonkeyClone(attacker) or victim:IsBuilding() then return end

    -- Apply the default skadi-like frost debuff --
    local frostDebuff = victim:FindModifierByName("modifier_curse_bearer_frost_debuff")
    if not frostDebuff then
        victim:AddNewModifier(attacker, self:GetAbility(), "modifier_curse_bearer_frost_debuff", { duration = self.frostDuration })
    else
        frostDebuff:ForceRefresh()
    end

    -- Apply the decaying slow and burst damage only on heroes --
    if not ability:IsCooldownReady() or IsBossUBA(victim) or not victim:IsRealHero() or victim:IsIllusion() or attacker:IsMuted() then return end

    local debuffName = "modifier_curse_bearer_debuff"
    local debuff = victim:FindModifierByName(debuffName)
    
    if not debuff then
        victim:AddNewModifier(attacker, self:GetAbility(), debuffName, { duration = self.burnDuration, maxStacks = self.maxStacks, explosionRadius = self.explosionRadius, explosionDamage = self.explosionDamage, explosionDuration = self.explosionDuration, reductionInterval = self.reductionInterval, afflictionDuration = self.afflictionDuration })
        victim:SetModifierStackCount(debuffName, attacker, 1)
    else
        debuff:ForceRefresh()
    end

    ability:StartCooldown(ability:GetCooldown(1))
end

function modifier_curse_bearer:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_curse_bearer:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
end

function modifier_curse_bearer:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
end

function modifier_curse_bearer:GetModifierHealthBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
end

function modifier_curse_bearer:GetModifierManaBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana", (self:GetAbility():GetLevel() - 1))
end

function modifier_curse_bearer:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_curse_bearer:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end
------------
function modifier_curse_bearer_curse:OnCreated()
    -- body
end
function modifier_curse_bearer_curse:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DISABLE_HEALING, --GetDisableHealing
    }

    return funcs
end

function modifier_curse_bearer_curse:GetDisableHealing()
    return 1
end

function modifier_curse_bearer_curse:GetPriority()
    return MODIFIER_PRIORITY_SUPER_ULTRA
end

function modifier_curse_bearer_curse:GetStatusEffectName()
    return "particles/status_fx/status_effect_iceblast.vpcf"
end
------------
function modifier_curse_bearer_debuff:OnCreated(params)
    if not IsServer() then return end

    self.reduction = params.reduction
    self.maxStacks = params.maxStacks
    self.afflictionDuration = params.afflictionDuration
    self.explosionRadius = params.explosionRadius
    self.explosionDamage = params.explosionDamage
    self.explosionDuration = params.explosionDuration
    self.reductionInterval = params.reductionInterval

    self.canBuild = true

    self:StartIntervalThink(self.reductionInterval)
end

function modifier_curse_bearer_debuff:OnIntervalThink()
    local parent = self:GetParent()
    local attacker = self:GetCaster()
    local debuffName = "modifier_curse_bearer_debuff"

    local stacks = parent:GetModifierStackCount(debuffName, attacker)

    if not self.canBuild then
        parent:SetModifierStackCount(debuffName, attacker, (stacks - 1))

        if stacks <= 1 then
            parent:RemoveModifierByName(debuffName)
        end
    elseif stacks == self.maxStacks and self.canBuild then
        self.canBuild = false

        -- PARTICLE --
        local particle = ParticleManager:CreateParticle("particles/econ/items/ancient_apparition/aa_blast_ti_5/ancient_apparition_ice_blast_explode_ti5.vpcf", PATTACH_CUSTOMORIGIN, parent)
        ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetOrigin(), true)
        ParticleManager:SetParticleControl(particle, 1, Vector(self.explosionRadius, self.explosionRadius, self.explosionRadius))
        ParticleManager:ReleaseParticleIndex(particle)

        -- SOUND --
        EmitSoundOnLocationWithCaster(parent:GetOrigin(), "Ability.FrostNova", parent)
        
        -- DAMAGE --
        local units = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            self.explosionRadius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        for _,unit in ipairs(units) do
            if unit:IsMagicImmune() then break end

            local damage = {
                victim = unit,
                attacker = attacker,
                damage = self.explosionDamage,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self:GetAbility()
            }

            ApplyDamage(damage)

            unit:AddNewModifier(attacker, self:GetAbility(), "modifier_curse_bearer_explosion_debuff", { duration = self.explosionDuration })
            CreateParticleWithTargetAndDuration("particles/generic_gameplay/generic_frozen.vpcf", unit, self.explosionDuration)
        end

        -- PARENT DEBUFF --
        local frostExplosionParticle = ParticleManager:CreateParticle("particles/econ/items/lich/frozen_chains_ti6/lich_frozenchains_frostnova.vpcf", PATTACH_CUSTOMORIGIN, parent)
        ParticleManager:SetParticleControlEnt(frostExplosionParticle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetOrigin(), true)
        ParticleManager:ReleaseParticleIndex(frostExplosionParticle)

        parent:AddNewModifier(attacker, self:GetAbility(), "modifier_curse_bearer_curse", { duration = self.afflictionDuration })
    elseif stacks < self.maxStacks then
        parent:SetModifierStackCount(debuffName, attacker, (stacks + 1))
    end
end

function modifier_curse_bearer_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_curse_bearer_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_frost_lich.vpcf"
end

function modifier_curse_bearer_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, --GetModifierHealAmplify_PercentageTarget
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierSpellLifestealRegenAmplify_Percentage
    }

    return funcs
end

function modifier_curse_bearer_debuff:GetModifierAttackSpeedPercentage()
    local stackCount = self:GetParent():GetModifierStackCount("modifier_curse_bearer_debuff", self:GetCaster())

    return (stackCount * self:GetAbility():GetLevelSpecialValueFor("reduction_amount", (self:GetAbility():GetLevel() - 1)))
end

function modifier_curse_bearer_debuff:GetModifierMoveSpeedBonus_Percentage()
    local stackCount = self:GetParent():GetModifierStackCount("modifier_curse_bearer_debuff", self:GetCaster())

    return (stackCount * self:GetAbility():GetLevelSpecialValueFor("reduction_amount", (self:GetAbility():GetLevel() - 1)))
end

function modifier_curse_bearer_debuff:GetModifierHPRegenAmplify_Percentage()
    local stackCount = self:GetParent():GetModifierStackCount("modifier_curse_bearer_debuff", self:GetCaster())

    return (stackCount * self:GetAbility():GetLevelSpecialValueFor("reduction_amount", (self:GetAbility():GetLevel() - 1)))
end

function modifier_curse_bearer_debuff:GetModifierHealAmplify_PercentageTarget()
    local stackCount = self:GetParent():GetModifierStackCount("modifier_curse_bearer_debuff", self:GetCaster())

    return (stackCount * self:GetAbility():GetLevelSpecialValueFor("reduction_amount", (self:GetAbility():GetLevel() - 1)))
end

function modifier_curse_bearer_debuff:GetModifierLifestealRegenAmplify_Percentage()
    local stackCount = self:GetParent():GetModifierStackCount("modifier_curse_bearer_debuff", self:GetCaster())

    return (stackCount * self:GetAbility():GetLevelSpecialValueFor("reduction_amount", (self:GetAbility():GetLevel() - 1)))
end

function modifier_curse_bearer_debuff:GetModifierSpellLifestealRegenAmplify_Percentage()
    local stackCount = self:GetParent():GetModifierStackCount("modifier_curse_bearer_debuff", self:GetCaster())

    return (stackCount * self:GetAbility():GetLevelSpecialValueFor("reduction_amount", (self:GetAbility():GetLevel() - 1)))
end
--------
function modifier_curse_bearer_explosion_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
    }

    return funcs
end

function modifier_curse_bearer_explosion_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("explosion_slow", (self:GetAbility():GetLevel() - 1))
end
------------------------
function modifier_curse_bearer_frost_debuff:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.frostAmountAttack = self:GetAbility():GetLevelSpecialValueFor("frost_attack_speed_amount", (self:GetAbility():GetLevel() - 1))
        self.frostAmountMove = self:GetAbility():GetLevelSpecialValueFor("frost_movement_speed_amount_pct", (self:GetAbility():GetLevel() - 1))
        self.frostAmountHealing = self:GetAbility():GetLevelSpecialValueFor("frost_healing_amount_pct", (self:GetAbility():GetLevel() - 1))

        if not self:GetParent():IsRangedAttacker() then
            self.frostAmountAttack = self.frostAmountAttack / 2
            self.frostAmountMove = self.frostAmountMove / 2
        end
    end

end
function modifier_curse_bearer_frost_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, --GetModifierHealAmplify_PercentageTarget
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierSpellLifestealRegenAmplify_Percentage
    }

    return funcs
end

function modifier_curse_bearer_frost_debuff:GetModifierAttackSpeedBonus_Constant()
    if self:GetParent():IsRangedAttacker() then
        return self.frostAmountAttack or self:GetAbility():GetLevelSpecialValueFor("frost_attack_speed_amount", (self:GetAbility():GetLevel() - 1))
    else
        return self.frostAmountAttack or (self:GetAbility():GetLevelSpecialValueFor("frost_attack_speed_amount", (self:GetAbility():GetLevel() - 1)) / 2)
    end
end

function modifier_curse_bearer_frost_debuff:GetModifierMoveSpeedBonus_Percentage()
    if self:GetParent():IsRangedAttacker() then
        return self.frostAmountMove or self:GetAbility():GetLevelSpecialValueFor("frost_movement_speed_amount_pct", (self:GetAbility():GetLevel() - 1))
    else
        return self.frostAmountMove or (self:GetAbility():GetLevelSpecialValueFor("frost_movement_speed_amount_pct", (self:GetAbility():GetLevel() - 1)) / 2)
    end
end

function modifier_curse_bearer_frost_debuff:GetModifierHPRegenAmplify_Percentage()
    return self.frostAmountHealing or self:GetAbility():GetLevelSpecialValueFor("frost_healing_amount_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_curse_bearer_frost_debuff:GetModifierHealAmplify_PercentageTarget()
    return self.frostAmountHealing or self:GetAbility():GetLevelSpecialValueFor("frost_healing_amount_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_curse_bearer_frost_debuff:GetModifierLifestealRegenAmplify_Percentage()
    return self.frostAmountHealing or self:GetAbility():GetLevelSpecialValueFor("frost_healing_amount_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_curse_bearer_frost_debuff:GetModifierSpellLifestealRegenAmplify_Percentage()
    return self.frostAmountHealing or self:GetAbility():GetLevelSpecialValueFor("frost_healing_amount_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_curse_bearer_frost_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_frost_lich.vpcf"
end