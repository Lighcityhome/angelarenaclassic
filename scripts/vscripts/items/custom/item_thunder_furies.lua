LinkLuaModifier("modifier_thunder_furies", "items/custom/item_thunder_furies.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_movement_speed_uba", "modifiers/modifier_movement_speed_uba.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_thunder_furies = class(ItemBaseClass)
item_thunder_furies_2 = item_thunder_furies
item_thunder_furies_3 = item_thunder_furies
modifier_thunder_furies = class(item_thunder_furies)
-------------
function item_thunder_furies:GetIntrinsicModifierName()
    return "modifier_thunder_furies"
end

function item_thunder_furies:OnSpellStart()
    local caster = self:GetCaster()
    local static_duration = self:GetLevelSpecialValueFor("static_duration", (self:GetLevel() - 1))

    if not caster:HasModifier("modifier_item_mjollnir_static") then
        caster:AddNewModifier(caster, self, "modifier_item_mjollnir_static", { duration = static_duration })
    end
end
------------

function modifier_thunder_furies:DeclareFunctions()
    local funcs = {
        --MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,--GetModifierMoveSpeedBonus_Constant
        --MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        --MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,--GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
    }

    return funcs
end

function modifier_thunder_furies:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if not UnitIsNotMonkeyClone(caster) then return end

    caster:AddNewModifier(caster, self, "modifier_phased", {})
    caster:AddNewModifier(caster, self:GetAbility(), "modifier_item_mjollnir", {})
    caster:AddNewModifier(caster, nil, "modifier_movement_speed_uba", { speed = self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1)) })
end

function modifier_thunder_furies:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("modifier_item_mjollnir")
    caster:RemoveModifierByName("modifier_movement_speed_uba")
    caster:RemoveModifierByName("modifier_phased")
end

function modifier_thunder_furies:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1))
end

--function modifier_thunder_furies:GetModifierPreAttack_BonusDamage()
    --return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
--end

--function modifier_thunder_furies:GetModifierAttackSpeedBonus_Constant()
    --return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
--end

function modifier_thunder_furies:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end
