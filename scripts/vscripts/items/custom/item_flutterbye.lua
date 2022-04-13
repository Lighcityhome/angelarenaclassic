LinkLuaModifier("modifier_flutterbye", "items/custom/item_flutterbye.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_flutterbye = class(ItemBaseClass)
item_flutterbye_2 = item_flutterbye
item_flutterbye_3 = item_flutterbye
modifier_flutterbye = class(item_flutterbye)
-------------
function item_flutterbye:GetIntrinsicModifierName()
    return "modifier_flutterbye"
end
------------

function modifier_flutterbye:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_EVASION_CONSTANT, --GetModifierEvasion_Constant
    }

    return funcs
end

function modifier_flutterbye:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_flutterbye:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_flutterbye:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_flutterbye:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
end

function modifier_flutterbye:GetModifierEvasion_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_evasion", (self:GetAbility():GetLevel() - 1))
end