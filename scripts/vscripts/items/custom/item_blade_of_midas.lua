LinkLuaModifier("modifier_blade_of_midas", "items/custom/item_blade_of_midas.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_blade_of_midas_disabled", "items/custom/item_blade_of_midas.lua", LUA_MODIFIER_MOTION_NONE)

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

item_blade_of_midas = class(ItemBaseClass)
modifier_blade_of_midas_disabled = class(ItemBaseDisabledClass)
modifier_blade_of_midas = class(item_blade_of_midas)
-------------
function item_blade_of_midas:GetIntrinsicModifierName()
    return "modifier_blade_of_midas"
end

function item_blade_of_midas:OnSpellStart()
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

function modifier_blade_of_midas:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,--GetModifierAttackSpeedBonus_Constant
        MODIFIER_EVENT_ON_TAKEDAMAGE 
    }

    return funcs
end

function modifier_blade_of_midas:OnTakeDamage(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.unit
    local ability = self:GetAbility()

    if ability == nil or not ability then return end

    if self:GetCaster() ~= attacker then
        return
    end

    if not UnitIsNotMonkeyClone(attacker) then return end

    if attacker:HasModifier("modifier_blade_of_midas_disabled") or not victim:IsHero() or victim:IsIllusion() or not attacker:IsHero() or attacker:IsIllusion() then return end
    
    local multiplier = ability:GetLevelSpecialValueFor("gold_from_damage_multiplier", (ability:GetLevel() - 1)) / 100
    local maxGold = ability:GetLevelSpecialValueFor("gold_from_damage_max", (ability:GetLevel() - 1))
    local cooldown = ability:GetLevelSpecialValueFor("gold_from_damage_cd", (ability:GetLevel() - 1))

    local damage = event.damage
    local bonusGold = damage * multiplier

    if bonusGold > maxGold then
        bonusGold = maxGold
    end

    attacker:ModifyGold(bonusGold, false, DOTA_ModifyGold_CreepKill)

    EmitSoundOnLocationWithCaster(attacker:GetOrigin(), "DOTA_Item.Hand_Of_Midas", attacker)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, attacker, bonusGold, nil)

    -- Display gold particle --
    local particle = ParticleManager:CreateParticle("particles/econ/items/alchemist/alchemist_midas_knuckles/alch_hand_of_midas.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
    ParticleManager:ReleaseParticleIndex(particle)
    -- End --

    attacker:AddNewModifier(attacker, ability, "modifier_blade_of_midas_disabled", { duration = cooldown })
end

function modifier_blade_of_midas:OnCreated()
    if not IsServer() then return end
end

function modifier_blade_of_midas:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_blade_of_midas:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end
-----------
function modifier_blade_of_midas_disabled:DeclareFunctions()
    local funcs = {}
    return funcs
end

function modifier_blade_of_midas_disabled:OnCreated()
end