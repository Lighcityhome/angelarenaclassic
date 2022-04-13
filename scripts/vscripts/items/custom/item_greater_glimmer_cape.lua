LinkLuaModifier("modifier_greater_glimmer_cape", "items/custom/item_greater_glimmer_cape.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_greater_glimmer_cape_active", "items/custom/item_greater_glimmer_cape.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_greater_glimmer_cape_aura", "items/custom/item_greater_glimmer_cape.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spell_lifesteal_uba", "modifiers/modifier_spell_lifesteal_uba.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBuffBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

item_greater_glimmer_cape = class(ItemBaseClass)
item_greater_glimmer_cape_2 = item_greater_glimmer_cape
modifier_greater_glimmer_cape = class(item_greater_glimmer_cape)
modifier_greater_glimmer_cape_aura = class(ItemBaseClassAura)
modifier_greater_glimmer_cape_active = class(ItemBuffBaseClass)
-------------
function item_greater_glimmer_cape:GetIntrinsicModifierName()
    return "modifier_greater_glimmer_cape"
end

function item_greater_glimmer_cape:OnSpellStart()
    if not IsServer() then return end

    local point = self:GetCursorPosition()
    local ability = self
    local caster = self:GetCaster()

    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
    local radius = ability:GetLevelSpecialValueFor("selection_radius", (ability:GetLevel() - 1))
    local fadeTime = ability:GetLevelSpecialValueFor("fade_delay", (ability:GetLevel() - 1))
    local shield = ability:GetLevelSpecialValueFor("active_magical_damage_shield", (ability:GetLevel() - 1))

    local targets = FindUnitsInRadius(caster:GetTeam(), point, nil,
            radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_ANY_ORDER, false)

    for _,target in ipairs(targets) do
        if target:IsAlive() and not target:IsNull() and UnitIsNotMonkeyClone(target) then
            self.pfx = ParticleManager:CreateParticle("particles/items3_fx/glimmer_cape_initial_flash.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
            self.pfx2 = ParticleManager:CreateParticle("particles/items3_fx/glimmer_cape_embers.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
            self.pfx3 = ParticleManager:CreateParticle("particles/items3_fx/glimmer_cape_mainglow.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)

            CreateParticleWithTargetAndDuration("particles/items3_fx/glimmer_cape_initial.vpcf", target, duration)
            CreateParticleWithTargetAndDuration("particles/items3_fx/glimmer_cape_ember_trail.vpcf", target, duration)

            Timers:CreateTimer(fadeTime, function()
                local particle_invis_start = "particles/generic_hero_status/status_invisibility_start.vpcf"
                local particle_invis_start_fx = ParticleManager:CreateParticle(particle_invis_start, PATTACH_ABSORIGIN, target)
                ParticleManager:SetParticleControl(particle_invis_start_fx, 0, target:GetAbsOrigin())
                ParticleManager:ReleaseParticleIndex(particle_invis_start_fx)

                target:AddNewModifier(target, ability, "modifier_greater_glimmer_cape_active", { duration = duration })
            end)

            EmitSoundOnLocationWithCaster(target:GetOrigin(), "Item.GlimmerCape.Activate", target)
        end
    end
end

function item_greater_glimmer_cape:GetAOERadius()
    return self:GetSpecialValueFor("selection_radius")
end
------------

function modifier_greater_glimmer_cape:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
    }

    return funcs
end

function modifier_greater_glimmer_cape:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local spell_lifesteal_percent_hero = ability:GetLevelSpecialValueFor("hero_lifesteal", (ability:GetLevel() - 1))
    local spell_lifesteal_percent_creep = ability:GetLevelSpecialValueFor("creep_lifesteal", (ability:GetLevel() - 1))

    Timers:CreateTimer(0.5, function() 
        caster:AddNewModifier(caster, ability, "modifier_spell_lifesteal_uba", { hero = spell_lifesteal_percent_hero, creep = spell_lifesteal_percent_creep })
    end)

    if ability and not ability:IsNull() then
        self.regen = self:GetAbility():GetLevelSpecialValueFor("bonus_health_regen", (self:GetAbility():GetLevel() - 1))
        self.magicArmor = self:GetAbility():GetLevelSpecialValueFor("bonus_magical_armor", (self:GetAbility():GetLevel() - 1))
        self.auraRange = self:GetAbility():GetLevelSpecialValueFor("aura_radius", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_greater_glimmer_cape:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByNameAndCaster("modifier_spell_lifesteal_uba", caster)
end

function modifier_greater_glimmer_cape:IsAura()
  return true
end

function modifier_greater_glimmer_cape:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_greater_glimmer_cape:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_greater_glimmer_cape:GetAuraRadius()
  return self.auraRange or self:GetAbility():GetLevelSpecialValueFor("aura_radius", (self:GetAbility():GetLevel() - 1))
end

function modifier_greater_glimmer_cape:GetModifierAura()
    return "modifier_greater_glimmer_cape_aura"
end

function modifier_greater_glimmer_cape:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_greater_glimmer_cape:GetAuraEntityReject(target)
    return false
end

function modifier_greater_glimmer_cape:GetModifierMagicalResistanceBonus()
    return self.regen or self:GetAbility():GetLevelSpecialValueFor("bonus_health_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_greater_glimmer_cape:GetModifierConstantHealthRegen()
    return self.magicArmor or self:GetAbility():GetLevelSpecialValueFor("bonus_magical_armor", (self:GetAbility():GetLevel() - 1))
end
-------------
function modifier_greater_glimmer_cape_aura:OnCreated()
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.auraMagicArmor = self:GetAbility():GetLevelSpecialValueFor("magic_resistance_aura", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_greater_glimmer_cape_aura:IsDebuff()
    return false
end

function modifier_greater_glimmer_cape_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
    }

    return funcs
end

function modifier_greater_glimmer_cape_aura:GetModifierMagicalResistanceBonus()
    return self.magicArmorBuff or self:GetAbility():GetLevelSpecialValueFor("magic_resistance_aura", (self:GetAbility():GetLevel() - 1))
end
-----------
function modifier_greater_glimmer_cape_active:OnCreated()
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.auraMagicArmor = self:GetAbility():GetLevelSpecialValueFor("active_magical_armor", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_greater_glimmer_cape_active:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ABILITY_EXECUTED,
        MODIFIER_PROPERTY_INVISIBILITY_LEVEL
    }

    return funcs
end

function modifier_greater_glimmer_cape_active:GetModifierMagicalResistanceBonus()
    return self.magicArmorBuff or self:GetAbility():GetLevelSpecialValueFor("active_magical_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_greater_glimmer_cape_active:CheckState()
    local state = {
        [MODIFIER_STATE_INVISIBLE] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }

    return state
end

function modifier_greater_glimmer_cape_active:GetPriority()
    return MODIFIER_PRIORITY_NORMAL
end

function modifier_greater_glimmer_cape_active:GetModifierInvisibilityLevel()
    return 1
end

function modifier_greater_glimmer_cape_active:OnAttack(params)
    if IsServer() then
        if params.attacker == self:GetParent() then
            -- Remove the invis on attack
            self:Destroy()
        end
    end
end

function modifier_greater_glimmer_cape_active:OnAbilityExecuted(keys)
    if IsServer() then
        local parent =  self:GetParent()
        -- Remove the invis on cast
        if keys.unit == parent then
            self:Destroy()
        end
    end
end

function modifier_greater_glimmer_cape_active:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetParent()
    local ability = self:GetAbility()

    if not caster:IsAlive() or not ability or ability:IsNull() then return end

    EmitSoundOnLocationWithCaster(caster:GetOrigin(), "DOTA_Item.Pipe.Activate", caster)

    caster:AddNewModifier(caster, ability, "modifier_item_eternal_shroud_barrier", { duration = ability:GetLevelSpecialValueFor("barrier_duration", (ability:GetLevel() - 1)) })
end