require("internal/util")

LinkLuaModifier("modifier_lantern_of_perish", "items/custom/item_lantern_of_perish.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lantern_of_perish_slow", "items/custom/item_lantern_of_perish.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lantern_of_perish_boost", "items/custom/item_lantern_of_perish.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseBuffClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseDebuffClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

item_lantern_of_perish = class(ItemBaseClass)
modifier_lantern_of_perish = class(item_lantern_of_perish)
modifier_lantern_of_perish_slow = class(ItemBaseDebuffClass)
modifier_lantern_of_perish_boost = class(ItemBaseBuffClass)
-------------
function item_lantern_of_perish:GetIntrinsicModifierName()
    return "modifier_lantern_of_perish"
end

function item_lantern_of_perish:OnSpellStart()
    if not IsServer() then return end

    local target = self:GetCursorTarget()
    local ability = self

    if not ability or ability:IsNull() then return end
    if target:IsMagicImmune() then return end
    if target:TriggerSpellAbsorb(ability) then return end

    local duration = ability:GetLevelSpecialValueFor("bonus_duration_tooltip", (ability:GetLevel() - 1))
    local endDamage = ability:GetLevelSpecialValueFor("duration_end_damage", (ability:GetLevel() - 1))
    local primaryMultiplier = ability:GetLevelSpecialValueFor("duration_end_damage_attribute_multiplier", (ability:GetLevel() - 1))

    CreateParticleWithTargetAndDuration("particles/units/heroes/hero_dark_willow/dark_willow_shadow_realm.vpcf", target, duration)
    CreateParticleWithTargetAndDuration("particles/status_fx/status_effect_dark_willow_shadow_realm.vpcf", target, duration)

    EmitSoundOnLocationWithCaster(target:GetOrigin(), "Item.BookOfShadows.Target", target)

    if target:GetTeam() ~= ability:GetCaster():GetTeam() then
        target:AddNewModifier(target, ability, "modifier_lantern_of_perish_slow", { duration = duration })
        Timers:CreateTimer(duration, function()
            if not target:IsAlive() then return end
            if not ability or ability:IsNull() then return end

            local damage = {
                victim = target,
                attacker = ability:GetCaster(),
                damage = endDamage + (ability:GetCaster():GetPrimaryStatValue() * primaryMultiplier),
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = ability
            }

            ApplyDamage(damage)
        end)
    else
        target:AddNewModifier(target, ability, "modifier_lantern_of_perish_boost", { duration = duration })
    end
end

------------------
function modifier_lantern_of_perish_slow:OnCreated() end
function modifier_lantern_of_perish_slow:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
    }

    return funcs
end

function modifier_lantern_of_perish_slow:CheckState()
    local state = {
        [MODIFIER_STATE_MUTED] = true,
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true
    }

    return state
end

function modifier_lantern_of_perish_slow:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_tooltip_slow", (self:GetAbility():GetLevel() - 1))
end

function modifier_lantern_of_perish_slow:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_magic_weakness", (self:GetAbility():GetLevel() - 1))
end
------------
function modifier_lantern_of_perish_boost:OnCreated() end
function modifier_lantern_of_perish_boost:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
    }

    return funcs
end

function modifier_lantern_of_perish_boost:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_tooltip_boost", (self:GetAbility():GetLevel() - 1))
end

function modifier_lantern_of_perish_boost:CheckState()
    local state = {
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true
    }

    return state
end
------------
--todo: also apply damage at the end of the duration like landing from waking
--do not mute or silence the caster, only enemy (still can't attack as ally tho)
function modifier_lantern_of_perish:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_BONUS_NIGHT_VISION, --GetBonusNightVision
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,--GetModifierMoveSpeedBonus_Constant
    }

    return funcs
end

function modifier_lantern_of_perish:OnCreated()
end

function modifier_lantern_of_perish:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
end

function modifier_lantern_of_perish:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
end

function modifier_lantern_of_perish:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_lantern_of_perish:GetBonusNightVision()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_night_vision", (self:GetAbility():GetLevel() - 1))
end

function modifier_lantern_of_perish:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_lantern_of_perish:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end