LinkLuaModifier("modifier_first_arcanists_frozen_heart", "items/custom/item_first_arcanists_frozen_heart.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_first_arcanists_frozen_heart_pulse", "items/custom/item_first_arcanists_frozen_heart.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_first_arcanists_frozen_heart = class(ItemBaseClass)
modifier_first_arcanists_frozen_heart = class(item_first_arcanists_frozen_heart)
modifier_first_arcanists_frozen_heart_pulse = class(item_first_arcanists_frozen_heart)
-------------
function item_first_arcanists_frozen_heart:GetIntrinsicModifierName()
    return "modifier_first_arcanists_frozen_heart"
end
------------

function modifier_first_arcanists_frozen_heart:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
    }

    return funcs
end

function modifier_first_arcanists_frozen_heart:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self:GetAbility(), "modifier_first_arcanists_frozen_heart_pulse", {})
end

function modifier_first_arcanists_frozen_heart:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_first_arcanists_frozen_heart:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_first_arcanists_frozen_heart:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
end

function modifier_first_arcanists_frozen_heart:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
end
-----------
function modifier_first_arcanists_frozen_heart_pulse:OnCreated()
    if not IsServer() then return end

    self.interval = self:GetAbility():GetLevelSpecialValueFor("pulse_interval", (self:GetAbility():GetLevel() - 1))
    self.damage = self:GetAbility():GetLevelSpecialValueFor("pulse_damage", (self:GetAbility():GetLevel() - 1))
    self.radius = self:GetAbility():GetLevelSpecialValueFor("pulse_radius", (self:GetAbility():GetLevel() - 1))
    self.caster = self:GetCaster()

    self:StartIntervalThink(self.interval)
end

function modifier_first_arcanists_frozen_heart_pulse:OnIntervalThink()
    modifier_first_arcanists_frozen_heart_pulse:FirePulse(self:GetAbility(), self.caster, self.radius)
end

function modifier_first_arcanists_frozen_heart_pulse:FirePulse(ability, caster, radius)
    local info = {
        Ability = ability,
        EffectName = "particles/frozen_heart_pulse.vpcf",
        vSpawnOrigin = caster:GetOrigin(),
        fDistance = radius,
        fStartRadius = radius,
        fEndRadius = radius,
        Source = caster,
        bHasFrontalCone = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,                            
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,                            
        bDeleteOnHit = false,
        vVelocity = 100,
        bProvidesVision = false
    }

    ProjectileManager:CreateLinearProjectile(info)
end

function modifier_first_arcanists_frozen_heart_pulse:OnProjectileHit(target, location)
    if not IsServer() then return end

    if target == nil then return end
    --if target:GetTeamNumber() == self:GetCaster():GetTeamNumber() then return end

    local damage = {
        victim = target,
        attacker = self:GetCaster(),
        damage = self.damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    }

    ApplyDamage(damage)

    local particle = "particles/items2_fx/shivas_guard_impact.vpcf"

    CreateParticleWithTargetAndDuration(particle, target, 1.0)

    EmitSoundOnLocationWithCaster(target:GetOrigin(), "Hero_Ancient_Apparition.ColdFeetFreeze", target)
end