LinkLuaModifier("modifier_refusal_blade", "items/custom/item_refusal_blade.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_refusal_blade_debuff", "items/custom/item_refusal_blade.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsPurgeException = function(self) return false end,
}

local ItemBaseDebuffClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
    IsPurgable = function(self) return false end,
}

item_refusal_blade = class(ItemBaseClass)
item_refusal_blade_2 = item_refusal_blade
item_refusal_blade_3 = item_refusal_blade
modifier_refusal_blade = class(item_refusal_blade)
modifier_refusal_blade_debuff = class(ItemBaseDebuffClass)
-------------
function item_refusal_blade:GetIntrinsicModifierName()
    return "modifier_refusal_blade"
end

function item_refusal_blade:OnSpellStart()
    local target = self:GetCursorTarget()
    local ability = self

    if not ability or ability:IsNull() then return end

    if target:TriggerSpellAbsorb(ability) then return end

    EmitSoundOnLocationWithCaster(target:GetOrigin(), "DOTA_Item.Nullifier.Cast", target)

    target:AddNewModifier(self:GetCaster(), ability, "modifier_refusal_blade_debuff", { duration = 5 })

    EmitSoundOnLocationWithCaster(target:GetOrigin(), "DOTA_Item.Nullifier.Target", target)
    EmitSoundOnLocationWithCaster(target:GetOrigin(), "DOTA_Item.Nullifier.Slow", target)
end
------------
function modifier_refusal_blade_debuff:OnCreated()
    if not IsServer() then return end

    local interval = self:GetAbility():GetLevelSpecialValueFor("slow_interval_duration", (self:GetAbility():GetLevel() - 1))

    self:StartIntervalThink(interval)
end

function modifier_refusal_blade_debuff:OnIntervalThink()
    self:GetParent():Purge(true, false, false, false, true)
end

function modifier_refusal_blade_debuff:GetEffectName()
    return "particles/items4_fx/nullifier_mute.vpcf"
end

function modifier_refusal_blade_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_refusal_blade_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("slow_pct", (self:GetAbility():GetLevel() - 1))
end
------------
function modifier_refusal_blade:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }

    return funcs
end

function modifier_refusal_blade:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target

    if self:GetCaster() == attacker or (attacker:GetPlayerOwner() == self:GetCaster() and attacker:IsIllusion()) then
        if not attacker:IsHero() or not UnitIsNotMonkeyClone(attacker) then return end

        local ability = self:GetAbility()

        local burn = ability:GetSpecialValueFor("mana_per_hit")
        local burnPerc = ability:GetSpecialValueFor("percent_damage_per_burn") / 100
        local illusionBurn = ability:GetSpecialValueFor("illusion_percentage") / 100

        if attacker:IsIllusion() then
            burn = burn * illusionBurn
        end

        local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_manaburn.vpcf", PATTACH_ABSORIGIN_FOLLOW, event.attacker)
        ParticleManager:ReleaseParticleIndex(particle)

        victim:SetMana(victim:GetMana() - burn)

        ApplyDamage({
            victim = victim, 
            attacker = attacker, 
            damage = burn * burnPerc, 
            damage_type = DAMAGE_TYPE_MAGICAL
        })
    end
end

function modifier_refusal_blade:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_refusal_blade:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
end

function modifier_refusal_blade:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
end

function modifier_refusal_blade:GetModifierConstantHealthRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_refusal_blade:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end
