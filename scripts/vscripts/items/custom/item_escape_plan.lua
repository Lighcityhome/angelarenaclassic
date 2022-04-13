LinkLuaModifier("modifier_escape_plan", "items/custom/item_escape_plan.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_escape_plan = class(ItemBaseClass)
modifier_escape_plan = class(item_escape_plan)
-------------
function item_escape_plan:GetIntrinsicModifierName()
    return "modifier_escape_plan"
end
------------

function modifier_escape_plan:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, --GetModifierMoveSpeedBonus_Constant
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
    }

    return funcs
end

function modifier_escape_plan:OnCreated()
end

function modifier_escape_plan:GetModifierMoveSpeedBonus_Constant()
    local ability = self:GetAbility()
    local caster = self:GetCaster()

    local speed = ability:GetLevelSpecialValueFor("bonus_movement_speed", (ability:GetLevel() - 1))
    local bonus = ability:GetLevelSpecialValueFor("bonus_movement_speed_tooltip", (ability:GetLevel() - 1))
    local threshold = ability:GetLevelSpecialValueFor("bonus_hp_threshold_tooltip", (ability:GetLevel() - 1))

    local currentMana = caster:GetMana()
    if currentMana < (caster:GetMaxMana() * threshold) then
        return speed + bonus
    end

    return speed
end

function modifier_escape_plan:GetModifierConstantManaRegen()
    local ability = self:GetAbility()
    local caster = self:GetCaster()

    local regen = ability:GetLevelSpecialValueFor("bonus_mana_regen", (ability:GetLevel() - 1))
    local bonus = ability:GetLevelSpecialValueFor("bonus_mana_regen_tooltip", (ability:GetLevel() - 1))
    local threshold = ability:GetLevelSpecialValueFor("bonus_hp_threshold_tooltip", (ability:GetLevel() - 1))

    local currentMana = caster:GetMana()
    if currentMana < (caster:GetMaxMana() * threshold) then
        return regen + bonus
    end

    return regen
end

function modifier_escape_plan:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_escape_plan:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_escape_plan:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end