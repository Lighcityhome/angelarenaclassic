LinkLuaModifier("modifier_lifesteal_uba", "modifiers/modifier_lifesteal_uba.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vampire_claw", "items/custom/item_vampire_claw.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_vampire_claw = class(ItemBaseClass)
item_morbid_mask_c = item_vampire_claw
modifier_vampire_claw = class(item_vampire_claw)
-------------
function item_vampire_claw:GetIntrinsicModifierName()
    return "modifier_vampire_claw"
end
------------

function modifier_vampire_claw:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
    }

    return funcs
end

function modifier_vampire_claw:OnCreated()
    if not IsServer() then return end
    
    local lifesteal = self:GetAbility():GetLevelSpecialValueFor("lifesteal_percent", (self:GetAbility():GetLevel() - 1))

    self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_lifesteal_uba", { amount = lifesteal })
end

function  modifier_vampire_claw:OnRemoved()
    if not IsServer() then return end
    
    self:GetCaster():RemoveModifierByNameAndCaster("modifier_lifesteal_uba", self:GetCaster())
end

function modifier_vampire_claw:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end