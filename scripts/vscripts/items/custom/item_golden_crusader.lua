LinkLuaModifier("modifier_golden_crusader", "items/custom/item_golden_crusader.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_golden_crusader_disabled", "items/custom/item_golden_crusader.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseDisabledClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end
}

item_golden_crusader = class(ItemBaseClass)
modifier_golden_crusader_disabled = class(ItemBaseDisabledClass)
modifier_golden_crusader = class(item_golden_crusader)
-------------
function item_golden_crusader:GetIntrinsicModifierName()
    return "modifier_golden_crusader"
end

function item_golden_crusader:OnSpellStart()
    if not IsServer() then return end

    local target = self:GetCursorTarget()
    local caster = self:GetCaster()
    local bonusGold = self:GetLevelSpecialValueFor("transmute_gold", (self:GetLevel() - 1))
    local XPMultiplier = self:GetLevelSpecialValueFor("transmute_multiplier", (self:GetLevel() - 1))
    local bonusXP = target:GetDeathXP() * XPMultiplier

    target:ForceKill(false)
    EmitSoundOnLocationWithCaster(target:GetOrigin(), "DOTA_Item.Hand_Of_Midas", target)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, target, bonusGold, nil)

    -- Display gold particle --
    local particle = ParticleManager:CreateParticle("particles/econ/items/alchemist/alchemist_midas_knuckles/alch_hand_of_midas.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:ReleaseParticleIndex(particle)
    -- End --

    caster:ModifyGold(bonusGold, false, DOTA_ModifyGold_CreepKill)
    caster:AddExperience(bonusXP, DOTA_ModifyXP_CreepKill, false, false)
end
------------

function modifier_golden_crusader:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,--GetModifierAttackSpeedBonus_Constant
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_golden_crusader:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target

    if self:GetCaster() ~= attacker then
        return
    end

    if not UnitIsNotMonkeyClone(attacker) then return end

    if attacker:HasModifier("modifier_golden_crusader_disabled") or not victim:IsHero() or victim:IsIllusion() or not attacker:IsHero() or attacker:IsIllusion() then return end
    
    local damage = {
        victim = victim,
        attacker = attacker,
        damage = self.bonusDamage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self
    }

    ApplyDamage(damage)

    attacker:ModifyGold(self.bonusDamage, false, DOTA_ModifyGold_CreepKill)

    EmitSoundOnLocationWithCaster(attacker:GetOrigin(), "DOTA_Item.Hand_Of_Midas", attacker)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, attacker, self.bonusDamage, nil)

    -- Display gold particle --
    local particle = ParticleManager:CreateParticle("particles/econ/items/alchemist/alchemist_midas_knuckles/alch_hand_of_midas.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
    ParticleManager:ReleaseParticleIndex(particle)
    -- End --

    attacker:AddNewModifier(attacker, self, "modifier_golden_crusader_disabled", { duration = self.cooldown })
end

function modifier_golden_crusader:OnCreated()
    if not IsServer() then return end

    self.bonusDamage = self:GetAbility():GetLevelSpecialValueFor("philosopher_slash_damage", (self:GetAbility():GetLevel() - 1))
    self.cooldown = self:GetAbility():GetLevelSpecialValueFor("philosopher_slash_cooldown", (self:GetAbility():GetLevel() - 1))
end

function modifier_golden_crusader:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_golden_crusader:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end
-----------
function modifier_golden_crusader_disabled:DeclareFunctions()
    local funcs = {}
    return funcs
end

function modifier_golden_crusader_disabled:OnCreated()
end