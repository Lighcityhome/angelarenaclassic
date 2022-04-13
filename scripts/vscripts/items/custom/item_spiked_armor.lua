LinkLuaModifier("modifier_spiked_armor", "items/custom/item_spiked_armor.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spiked_armor_active", "items/custom/item_spiked_armor.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassActive = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassActiveDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

item_spiked_armor = class(ItemBaseClass)
item_spiked_armor_2 = item_spiked_armor
item_spiked_armor_3 = item_spiked_armor
modifier_spiked_armor = class(item_spiked_armor)
modifier_spiked_armor_active = class(ItemBaseClassActive)
-------------
function item_spiked_armor:GetIntrinsicModifierName()
    return "modifier_spiked_armor"
end

function item_spiked_armor:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self

    local duration = self:GetLevelSpecialValueFor("active_duration", (self:GetLevel() - 1)) 
    local amount = self:GetLevelSpecialValueFor("active_return_pct", (self:GetLevel() - 1)) 

    CreateParticleWithTargetAndDuration("particles/econ/items/spectre/spectre_arcana/spectre_arcana_blademail.vpcf", caster, duration)

    caster:AddNewModifier(caster, ability, "modifier_spiked_armor_active", { duration = duration, amount = amount })

    EmitSoundOnLocationWithCaster(caster:GetOrigin(), "DOTA_Item.BladeMail.Activate", caster)
end

function item_spiked_armor:OnRemoved()
    ParticleManager:DestroyParticle(self.particleCaster.particle, true)
end
------------
function modifier_spiked_armor_active:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }

    return funcs
end

function modifier_spiked_armor_active:OnCreated(params)
    self.activeReturnPct = self:GetAbility():GetLevelSpecialValueFor("active_return_pct", (self:GetAbility():GetLevel() - 1)) 
    self.activeRegenDebuffDuration = self:GetAbility():GetLevelSpecialValueFor("active_regen_debuff_duration", (self:GetAbility():GetLevel() - 1)) 
end

function modifier_spiked_armor_active:OnTakeDamage(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.unit
    local attack_damage = event.original_damage -- Damage before any reductions such as armor or other resistances
    local caster = self:GetCaster()

    if (caster ~= victim) or (attacker:IsBuilding()) or (attacker:IsIllusion()) or (caster:GetTeamNumber() == attacker:GetTeamNumber()) or bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS or bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then
        return
    end

    if event.inflictor ~= nil then
        local inflictor = event.inflictor -- CDOTABaseAbility 

        if inflictor == nil then return end

        --make sure the damage in this hook doesn't come from spiked armor
        if (inflictor == caster) or (string.find(inflictor:GetAbilityName(), "item_spiked_armor")) or (string.find(inflictor:GetAbilityName(), "item_azwraith_armor")) then
            return
        end
    end

    if not attacker:IsNull() and victim:IsAlive() and victim:IsRealHero() and (attacker:IsRealHero() or attacker:IsCreature() or attacker:IsCreep() or IsBossUBA(attacker)) then
        --make a check for if attacker/victim isrealhero, isunit or whatever lol
        local damage = {
            victim = attacker,
            attacker = victim,
            damage = attack_damage * (self.activeReturnPct / 100),
            damage_type = DAMAGE_TYPE_PURE,
            ability = self:GetAbility()
        }

        ApplyDamage(damage)

        EmitSoundOnLocationWithCaster(victim:GetOrigin(), "DOTA_Item.BladeMail.Damage", victim)
    end
end
------------
function modifier_spiked_armor:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        MODIFIER_EVENT_ON_ATTACKED
    }

    return funcs
end

function modifier_spiked_armor:OnCreated()
    if not IsServer() then return end

    self.returnFlat = self:GetAbility():GetLevelSpecialValueFor("passive_return", (self:GetAbility():GetLevel() - 1)) 
    self.returnPct = self:GetAbility():GetLevelSpecialValueFor("passive_return_pct", (self:GetAbility():GetLevel() - 1)) 
end

function modifier_spiked_armor:OnAttacked(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target
    local attack_damage = event.damage
    local caster = self:GetCaster()
    local damageCategory = event.damage_category

    if (caster == attacker) or (caster ~= victim) or (damageCategory == DOTA_DAMAGE_CATEGORY_SPELL) or (event.inflictor ~= nil) then
        return false
    end

    if not attacker:IsBuilding() then
        local damage = {
            victim = attacker,
            attacker = victim,
            damage = self.returnFlat + (attack_damage * (self.returnPct / 100)),
            damage_type = event.damage_type,
            ability = self:GetAbility()
        }

        ApplyDamage(damage)
    end
end

function modifier_spiked_armor:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_spiked_armor:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_spiked_armor:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_spiked_armor:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_spiked_armor:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end