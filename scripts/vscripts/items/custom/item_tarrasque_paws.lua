LinkLuaModifier("modifier_tarrasque_paws", "items/custom/item_tarrasque_paws.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_movement_speed_uba", "modifiers/modifier_movement_speed_uba.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_tarrasque_paws = class(ItemBaseClass)
item_tarrasque_paws_2 = item_tarrasque_paws
item_tarrasque_paws_3 = item_tarrasque_paws
modifier_tarrasque_paws = class(item_tarrasque_paws)
-------------
function item_tarrasque_paws:GetIntrinsicModifierName()
    return "modifier_tarrasque_paws"
end
------------

function modifier_tarrasque_paws:DeclareFunctions()
    local funcs = {
        --MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, --GetModifierMoveSpeedBonus_Constant
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, --GetModifierHealthRegenPercentage
    }

    return funcs
end

function modifier_tarrasque_paws:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, nil, "modifier_movement_speed_uba", { speed = self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1)) })
end

function modifier_tarrasque_paws:OnRemoved()
    if not IsServer() then return end

    self:GetParent():RemoveModifierByName("modifier_movement_speed_uba")
end

function modifier_tarrasque_paws:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_tarrasque_paws:GetModifierConstantHealthRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_tarrasque_paws:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_tarrasque_paws:GetModifierHealthBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
end

function modifier_tarrasque_paws:GetModifierHealthRegenPercentage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health_regen_pct", (self:GetAbility():GetLevel() - 1))
end