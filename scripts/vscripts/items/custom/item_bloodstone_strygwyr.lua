LinkLuaModifier("modifier_spell_lifesteal_uba", "modifiers/modifier_spell_lifesteal_uba.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lifesteal_uba", "modifiers/modifier_lifesteal_uba.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bloodstone_strygwyr", "items/custom/item_bloodstone_strygwyr.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bloodstone_strygwyr_active", "items/custom/item_bloodstone_strygwyr.lua", LUA_MODIFIER_MOTION_NONE)

--todo: fix charges lost on upgrade, and should start with charges but make sure they dont reset when dropped/picked up again
local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end
}

local ItemBaseClassActiveEffect = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end
}

item_bloodstone_strygwyr = class({})
item_bloodstone_strygwyr_2 = item_bloodstone_strygwyr
item_bloodstone_strygwyr_3 = item_bloodstone_strygwyr
modifier_bloodstone_strygwyr = class(ItemBaseClass)
modifier_bloodstone_strygwyr_active = class(ItemBaseClassActiveEffect)

CURRENT_CHARGES = 0
-------------
function item_bloodstone_strygwyr:GetIntrinsicModifierName()
    return "modifier_bloodstone_strygwyr"
end

function item_bloodstone_strygwyr:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local amount = self:GetLevelSpecialValueFor("mana_cost_percentage", (self:GetLevel() - 1))
    local duration = self:GetLevelSpecialValueFor("restore_duration", (self:GetLevel() - 1))

    if not caster:IsAlive() or caster:GetHealth() < 1 then return end

    --- Create Bloodstone Particle ---
    caster.particle = ParticleManager:CreateParticle("particles/items_fx/bloodstone_heal.vpcf", PATTACH_OVERHEAD_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(caster.particle, 0, caster, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)

    Timers:CreateTimer(duration, function()
        ParticleManager:DestroyParticle(caster.particle, true)
    end)
    ---

    -- Set New Mana ---
    local removeAmount = caster:GetMana() - caster:GetMaxMana() * (amount / 100)
    if removeAmount > 0 then
        caster:SetMana(removeAmount)

        caster:AddNewModifier(caster, nil, "modifier_bloodstone_strygwyr_active", { duration = duration })
        EmitSoundOnLocationWithCaster(caster:GetOrigin(), "DOTA_Item.Bloodstone.Cast", caster)
    end
end

function item_bloodstone_strygwyr:OnUpgrade()
    if not IsServer() then return end

    self:SetCurrentCharges(CURRENT_CHARGES)
end
------------

function modifier_bloodstone_strygwyr:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, -- GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_HEALTH_BONUS, -- GetModifierHealthBonus
        MODIFIER_PROPERTY_MANA_BONUS, -- GetModifierManaBonus
        MODIFIER_PROPERTY_MANA_REGEN_PERCENTAGE, -- GetModifierPercentageManaRegen
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, -- GetModifierSpellLifestealRegenAmplify_Percentage
        MODIFIER_EVENT_ON_HERO_KILLED, -- OnHeroKilled
        MODIFIER_EVENT_ON_DEATH, -- OnDeath
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
    }

    return funcs
end

function modifier_bloodstone_strygwyr:OnCreated(event)
    if not IsServer() then return end
    
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local spell_lifesteal_percent_hero = ability:GetLevelSpecialValueFor("hero_lifesteal", (ability:GetLevel() - 1))
    local spell_lifesteal_percent_creep = ability:GetLevelSpecialValueFor("creep_lifesteal", (ability:GetLevel() - 1))
    local life_steal_amount = ability:GetLevelSpecialValueFor("life_steal", (ability:GetLevel() - 1))
    local initial_charges = ability:GetLevelSpecialValueFor("initial_charges_tooltip", (ability:GetLevel() - 1))

    Timers:CreateTimer(0.5, function() 
        caster:AddNewModifier(caster, ability, "modifier_spell_lifesteal_uba", { hero = spell_lifesteal_percent_hero, creep = spell_lifesteal_percent_creep })
        caster:AddNewModifier(caster, ability, "modifier_lifesteal_uba", { amount = life_steal_amount })
    end)

    if CURRENT_CHARGES > 0 then
        ability:SetCurrentCharges(CURRENT_CHARGES)
    else
        ability:SetCurrentCharges(initial_charges)
        CURRENT_CHARGES = initial_charges
    end
end

function modifier_bloodstone_strygwyr:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetCaster()
    caster.bloodstone_respawn_reduction = nil

    caster:RemoveModifierByNameAndCaster("modifier_spell_lifesteal_uba", caster)
    caster:RemoveModifierByNameAndCaster("modifier_lifesteal_uba", caster)
end

function modifier_bloodstone_strygwyr:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
end

function modifier_bloodstone_strygwyr:GetModifierHealthBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
end

function modifier_bloodstone_strygwyr:GetModifierManaBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana", (self:GetAbility():GetLevel() - 1))
end

function modifier_bloodstone_strygwyr:GetModifierPercentageManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("mana_regen_multiplier", (self:GetAbility():GetLevel() - 1))
end

function modifier_bloodstone_strygwyr:GetModifierSpellLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("spell_lifesteal_amp", (self:GetAbility():GetLevel() - 1))
end

---
-- Charges
---

--- Modifiers ---
function modifier_bloodstone_strygwyr:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("regen_per_charge", (self:GetAbility():GetLevel() - 1)) * self:GetAbility():GetCurrentCharges()
end

function modifier_bloodstone_strygwyr:GetModifierSpellAmplify_Percentage()
    local defaultValue = self:GetAbility():GetLevelSpecialValueFor("spell_amp", (self:GetAbility():GetLevel() - 1))
    local bonusValue = self:GetAbility():GetLevelSpecialValueFor("amp_per_charge", (self:GetAbility():GetLevel() - 1)) * self:GetAbility():GetCurrentCharges()
    
    return defaultValue + bonusValue
end

--- Events ---

function modifier_bloodstone_strygwyr:OnDeath(event)
    if not IsServer() then return end
    if event.unit ~= self:GetCaster() then return end

    local ability = self:GetAbility()
    local current_charges = ability:GetCurrentCharges()
    local toRemove = current_charges - ability:GetLevelSpecialValueFor("death_charges", (ability:GetLevel() - 1))
    
    if toRemove < 0 then
        toRemove = 0
    end

    CURRENT_CHARGES = toRemove
    ability:SetCurrentCharges(toRemove)
end

function modifier_bloodstone_strygwyr:OnHeroKilled(event)
    if not IsServer() then return end

    local ability = self:GetAbility()
    local caster = self:GetCaster()
    local range = self:GetAbility():GetLevelSpecialValueFor("charge_range", (self:GetAbility():GetLevel() - 1))

    if event.target:GetTeamNumber() == caster:GetTeamNumber() then return end
    if not caster:IsPositionInRange(event.target:GetAbsOrigin(), range) then return end

    local target = event.target
    local current_charges = ability:GetCurrentCharges()

    if target:GetTeam() ~= caster:GetTeam() and not target:IsIllusion() and not target:HasModifier("modifier_arc_warden_tempest_double") then
        CURRENT_CHARGES = current_charges + ability:GetLevelSpecialValueFor("kill_charges", (ability:GetLevel() - 1))
        ability:SetCurrentCharges(current_charges + ability:GetLevelSpecialValueFor("kill_charges", (ability:GetLevel() - 1)))
    end
end

---
-- Charges End
---

---
-- Active Effect
---
function modifier_bloodstone_strygwyr_active:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, -- GetModifierConstantHealthRegen
    }

    return funcs
end

function modifier_bloodstone_strygwyr_active:GetTexture()
    return "item_bloodstone"
end

function modifier_bloodstone_strygwyr_active:OnCreated(params)
end

function modifier_bloodstone_strygwyr_active:GetModifierConstantHealthRegen()
    return self:GetCaster():GetMaxMana() * 0.15
end