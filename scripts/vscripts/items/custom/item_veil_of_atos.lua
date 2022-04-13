LinkLuaModifier("modifier_veil_of_atos", "items/custom/item_veil_of_atos.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_veil_of_atos_aura", "items/custom/item_veil_of_atos.lua", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return true end,
}

item_veil_of_atos = class(ItemBaseClass)
item_veil_of_atos_2 = item_veil_of_atos
item_veil_of_atos_3 = item_veil_of_atos
modifier_veil_of_atos = class(item_veil_of_atos)
modifier_veil_of_atos_aura = class(ItemBaseClassAura)
-------------
function item_veil_of_atos:GetIntrinsicModifierName()
    return "modifier_veil_of_atos"
end

function item_veil_of_atos:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function item_veil_of_atos:OnSpellStart()
    local point = self:GetCursorPosition()
    local ability = self
    local caster = self:GetCaster()
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
    local radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() - 1))

    local targets = FindUnitsInRadius(caster:GetTeam(), point, nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_ANY_ORDER, false)

    for _,target in ipairs(targets) do
        if target:IsAlive() and not target:IsNull() and UnitIsNotMonkeyClone(target) then
            target:AddNewModifier(target, ability, "modifier_gungnir_debuff", { duration = duration })
            EmitSoundOnLocationWithCaster(target:GetOrigin(), "Item.Gleipnir.Cast", target)
            EmitSoundOnLocationWithCaster(target:GetOrigin(), "Item.Gleipnir.Target", target)
        end
    end
end
------------
function modifier_veil_of_atos:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
    }

    return funcs
end

function modifier_veil_of_atos:IsAura()
  return true
end

function modifier_veil_of_atos:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_veil_of_atos:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_veil_of_atos:GetAuraRadius()
  return 1200
end

function modifier_veil_of_atos:GetModifierAura()
    return "modifier_veil_of_atos_aura"
end

function modifier_veil_of_atos:GetAuraEntityReject(target)
    return false
end
----------
function modifier_veil_of_atos_aura:OnCreated()
    self.spellAmp = self:GetAbility():GetLevelSpecialValueFor("amplify_spell_aura_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_veil_of_atos_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT, --GetModifierIncomingSpellDamageConstant
    }

    return funcs
end

function modifier_veil_of_atos_aura:GetModifierIncomingSpellDamageConstant()
    return self.spellAmp
end
----------
function modifier_veil_of_atos:OnCreated()
end

function modifier_veil_of_atos:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_veil_of_atos:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
end

function modifier_veil_of_atos:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
end

function modifier_veil_of_atos:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end