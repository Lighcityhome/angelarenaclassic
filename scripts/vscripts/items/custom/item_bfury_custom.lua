LinkLuaModifier("modifier_bfury_custom", "items/custom/item_bfury_custom.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_bfury_custom = class(ItemBaseClass)
item_bfury_custom_2 = item_bfury_custom
item_bfury_custom_3 = item_bfury_custom
modifier_bfury_custom = class(item_bfury_custom)
-------------
function item_bfury_custom:GetIntrinsicModifierName()
    return "modifier_bfury_custom"
end

function item_bfury_custom:OnSpellStart()
    if not IsServer() then return end

    local target = self:GetCursorTarget()
    if not target or target:IsNull() then return end

    target:CutDown(self:GetCaster():GetTeamNumber())
end
------------

function modifier_bfury_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_bfury_custom:OnCreated()
    if not IsServer() then return end

    self.quelling_damage = self:GetAbility():GetLevelSpecialValueFor("quelling_bonus", (self:GetAbility():GetLevel() - 1)) 
    self.quelling_damage_ranged = self:GetAbility():GetLevelSpecialValueFor("quelling_bonus_ranged", (self:GetAbility():GetLevel() - 1)) 
    self.cleave_creep = self:GetAbility():GetLevelSpecialValueFor("bonus_cleave_creep", (self:GetAbility():GetLevel() - 1))
    self.cleave_hero = self:GetAbility():GetLevelSpecialValueFor("bonus_cleave_hero", (self:GetAbility():GetLevel() - 1)) 
end

function modifier_bfury_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target
    local attack_damage = event.damage

    if self:GetCaster() ~= attacker then
        return
    end

    if not UnitIsNotMonkeyClone(attacker) or not attacker:IsRealHero() or attacker:IsIllusion() then return end
    if event.inflictor ~= nil then return end -- Should block abilities from proccing it? 
    --- 
    -- Cleave
    ---
    if not victim:IsHero() then
        local damage_act = self.quelling_damage

        if attacker:IsRangedAttacker() then
            damage_act = self.quelling_damage_ranged
        end

        local damage = {
            victim = victim,
            attacker = attacker,
            damage = damage_act,
            damage_type = DAMAGE_TYPE_PHYSICAL,
            ability = self
        }

        ApplyDamage(damage)

        DoCleaveAttack(
            attacker,
            victim,
            self:GetAbility(),
            attack_damage * (self.cleave_creep / 100),
            150,
            360,
            650,
            "particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf"
        )
    else
        DoCleaveAttack(
            attacker,
            victim,
            self:GetAbility(),
            attack_damage * (self.cleave_hero / 100),
            150,
            360,
            650,
            "particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf"
        )
    end
end

function modifier_bfury_custom:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_bfury_custom:GetModifierConstantHealthRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_bfury_custom:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end