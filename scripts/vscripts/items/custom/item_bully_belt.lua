LinkLuaModifier("modifier_bully_belt", "items/custom/item_bully_belt.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_bully_belt = class(ItemBaseClass)
modifier_bully_belt = class(item_bully_belt)
-------------
function item_bully_belt:GetIntrinsicModifierName()
    return "modifier_bully_belt"
end
------------

function modifier_bully_belt:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, --GetModifierMoveSpeedBonus_Constant
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_bully_belt:OnCreated()
    if not IsServer() then return end

    self.duration = self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed_duration_tooltip", (self:GetAbility():GetLevel() - 1))
    self.cooldown = self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed_cooldown_tooltip", (self:GetAbility():GetLevel() - 1))
    self.boost = self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed_tooltip", (self:GetAbility():GetLevel() - 1)) 
    self.activeBoost = 0
end

function modifier_bully_belt:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target

    if attacker ~= self:GetParent() or (not victim:IsHero()) then
        return
    end

    if self.activeBoost == 0 and self:GetAbility():IsCooldownReady() then
        self.activeBoost = self.boost
        self:GetAbility():StartCooldown(self.cooldown)

        attacker.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_vendetta_speed.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
        ParticleManager:SetParticleControlEnt(attacker.particle, 0, attacker, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", attacker:GetAbsOrigin(), true)

        Timers:CreateTimer(self.duration, function()
            self.activeBoost = 0
            ParticleManager:DestroyParticle(attacker.particle, true)
        end)
    end
end

function modifier_bully_belt:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_bully_belt:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_magical_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_bully_belt:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_bully_belt:GetModifierMoveSpeedBonus_Constant()
    local speed = self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1))

    if IsServer() then
        if self.activeBoost ~= 0 then
            return speed + self.activeBoost
        end
    end
        
    return speed
end