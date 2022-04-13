LinkLuaModifier("modifier_bfury_boots", "items/custom/item_bfury_boots.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_movement_speed_uba", "modifiers/modifier_movement_speed_uba.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_bfury_boots = class(ItemBaseClass)
item_bfury_boots_2 = item_bfury_boots
item_bfury_boots_3 = item_bfury_boots
modifier_bfury_boots = class(item_bfury_boots)
-------------
function item_bfury_boots:GetIntrinsicModifierName()
    return "modifier_bfury_boots"
end

function item_bfury_boots:OnSpellStart()
    if not IsServer() then return end

    local target = self:GetCursorTarget()
    if not target or target:IsNull() then return end

    target:CutDown(self:GetCaster():GetTeamNumber())
end
------------

function modifier_bfury_boots:DeclareFunctions()
    local funcs = {
        --MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,--GetModifierMoveSpeedBonus_Constant
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,--GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_bfury_boots:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()

    self.quelling_damage = self:GetAbility():GetLevelSpecialValueFor("quelling_bonus", (self:GetAbility():GetLevel() - 1)) 
    self.quelling_damage_ranged = self:GetAbility():GetLevelSpecialValueFor("quelling_bonus_ranged", (self:GetAbility():GetLevel() - 1)) 
    self.cleave_creep = self:GetAbility():GetLevelSpecialValueFor("bonus_cleave_creep", (self:GetAbility():GetLevel() - 1))
    self.cleave_hero = self:GetAbility():GetLevelSpecialValueFor("bonus_cleave_hero", (self:GetAbility():GetLevel() - 1)) 

    caster:AddNewModifier(caster, nil, "modifier_movement_speed_uba", { speed = self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1)) })
end

function modifier_bfury_boots:OnRemoved()
    if not IsServer() then return end

    self:GetParent():RemoveModifierByName("modifier_movement_speed_uba")
end

function modifier_bfury_boots:OnAttackLanded(event)
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

function modifier_bfury_boots:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_bfury_boots:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_bfury_boots:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_bfury_boots:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_bfury_boots:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_bfury_boots:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_bfury_boots:GetModifierConstantHealthRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_bfury_boots:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end