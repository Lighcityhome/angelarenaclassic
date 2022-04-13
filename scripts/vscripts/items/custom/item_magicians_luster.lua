LinkLuaModifier("modifier_spell_lifesteal_uba", "modifiers/modifier_spell_lifesteal_uba.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_magicians_luster", "items/custom/item_magicians_luster.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lifesteal_uba", "modifiers/modifier_lifesteal_uba.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_magicians_luster = class(ItemBaseClass)
modifier_magicians_luster = class(item_magicians_luster)
-------------
function item_magicians_luster:GetIntrinsicModifierName()
    return "modifier_magicians_luster"
end
------------

function modifier_magicians_luster:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
    }

    return funcs
end

function modifier_magicians_luster:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
        self.spell_lifesteal_percent_hero = self:GetAbility():GetLevelSpecialValueFor("hero_lifesteal", (self:GetAbility():GetLevel() - 1))
        self.spell_lifesteal_percent_creep = self:GetAbility():GetLevelSpecialValueFor("creep_lifesteal", (self:GetAbility():GetLevel() - 1))
        self.spell_amp = self:GetAbility():GetLevelSpecialValueFor("spell_amp", (self:GetAbility():GetLevel() - 1))
        self.bonus_mana_regen = self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
        self.life_steal = self:GetAbility():GetLevelSpecialValueFor("life_steal", (self:GetAbility():GetLevel() - 1))

        self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_spell_lifesteal_uba", { hero = self.spell_lifesteal_percent_hero, creep = self.spell_lifesteal_percent_creep })
        self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_lifesteal_uba", { amount = self.life_steal })
    end
end

function modifier_magicians_luster:OnRemoved()
    if not IsServer() then return end
    
    self:GetCaster():RemoveModifierByNameAndCaster("modifier_spell_lifesteal_uba", self:GetCaster())
    self:GetCaster():RemoveModifierByNameAndCaster("modifier_lifesteal_uba", self:GetCaster())
end

function modifier_magicians_luster:GetModifierSpellAmplify_Percentage()
    return self.spell_amp or self:GetAbility():GetLevelSpecialValueFor("spell_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_magicians_luster:GetModifierConstantManaRegen()
    return self.bonus_mana_regen or self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end