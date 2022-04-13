LinkLuaModifier("modifier_equalizer", "items/custom/item_equalizer.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_equalizer = class(ItemBaseClass)
item_morbid_mask_c = item_equalizer
modifier_equalizer = class(item_equalizer)
-------------
function item_equalizer:GetIntrinsicModifierName()
    return "modifier_equalizer"
end
------------

function modifier_equalizer:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
    }

    return funcs
end

function modifier_equalizer:OnCreated()
end

function modifier_equalizer:GetModifierConstantHealthRegen()
    local ability = self:GetAbility()
    local caster = self:GetCaster()

    local regen = ability:GetLevelSpecialValueFor("bonus_health_regen", (ability:GetLevel() - 1))
    local bonus = ability:GetLevelSpecialValueFor("bonus_health_regen_tooltip", (ability:GetLevel() - 1))
    local threshold = ability:GetLevelSpecialValueFor("bonus_hp_threshold_tooltip", (ability:GetLevel() - 1))

    local currentHealth = (caster:GetHealthPercent() / 100) * caster:GetMaxHealth()
    if currentHealth < (caster:GetMaxHealth() * threshold) then
        return regen + bonus
    end

    return regen
end

function modifier_equalizer:GetModifierPhysicalArmorBonus()
    local ability = self:GetAbility()
    local caster = self:GetCaster()

    local armor = ability:GetLevelSpecialValueFor("bonus_armor", (ability:GetLevel() - 1))
    local bonus = ability:GetLevelSpecialValueFor("bonus_armor_tooltip", (ability:GetLevel() - 1))
    local threshold = ability:GetLevelSpecialValueFor("bonus_hp_threshold_tooltip", (ability:GetLevel() - 1))

    local currentHealth = (caster:GetHealthPercent() / 100) * caster:GetMaxHealth()
    if currentHealth < (caster:GetMaxHealth() * threshold) then
        return armor + bonus
    end

    return armor
end

function modifier_equalizer:GetModifierHealthBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
end

function modifier_equalizer:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_equalizer:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_equalizer:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end