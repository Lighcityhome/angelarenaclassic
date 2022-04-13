LinkLuaModifier("modifier_quelling_fury", "items/custom/item_quelling_fury.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_quelling_fury = class(ItemBaseClass)
modifier_quelling_fury = class(item_quelling_fury)
-------------
function item_quelling_fury:GetIntrinsicModifierName()
    return "modifier_quelling_fury"
end

function item_quelling_fury:OnSpellStart()
    if not IsServer() then return end

    local target = self:GetCursorTarget()
    if not target or target:IsNull() then return end

    target:CutDown(self:GetCaster():GetTeamNumber())
end
------------

function modifier_quelling_fury:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_quelling_fury:OnCreated()
    if not IsServer() then return end

    self.quelling_damage = self:GetAbility():GetLevelSpecialValueFor("quelling_bonus", (self:GetAbility():GetLevel() - 1)) 
    self.quelling_damage_ranged = self:GetAbility():GetLevelSpecialValueFor("quelling_bonus_ranged", (self:GetAbility():GetLevel() - 1)) 
    self.cleave_creep = self:GetAbility():GetLevelSpecialValueFor("bonus_cleave_creep", (self:GetAbility():GetLevel() - 1))
    self.cleave_hero = self:GetAbility():GetLevelSpecialValueFor("bonus_cleave_hero", (self:GetAbility():GetLevel() - 1)) 
end

function modifier_quelling_fury:OnAttackLanded(event)
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
    -- Quelling
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
            360,
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
            360,
            "particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf"
        )
    end
end

function modifier_quelling_fury:GetModifierConstantHealthRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_hp_regen", (self:GetAbility():GetLevel() - 1))
end