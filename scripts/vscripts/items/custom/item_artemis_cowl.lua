LinkLuaModifier("modifier_artemis_cowl", "items/custom/item_artemis_cowl.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_artemis_cowl_aura", "items/custom/item_artemis_cowl.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_artemis_cowl_buff", "items/custom/item_artemis_cowl.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBuffBaseClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_artemis_cowl = class(ItemBaseClass)
item_artemis_cowl_2 = item_artemis_cowl
item_artemis_cowl_3 = item_artemis_cowl
modifier_artemis_cowl = class(item_artemis_cowl)
modifier_artemis_cowl_buff = class(ItemBuffBaseClass)
modifier_artemis_cowl_aura = class(ItemBaseClassAura)
-------------
function item_artemis_cowl:GetIntrinsicModifierName()
    return "modifier_artemis_cowl"
end

function item_artemis_cowl:GetAOERadius()
    return self:GetSpecialValueFor("aura_radius")
end

function item_artemis_cowl:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("aura_radius")
    local duration = self:GetSpecialValueFor("active_bonus_duration")

    local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,unit in ipairs(units) do
        if unit:GetOwner() ~= caster then break end

        unit:AddNewModifier(caster, self, "modifier_artemis_cowl_buff", { duration = duration })
        CreateParticleWithTargetAndDuration("particles/items_fx/drum_of_endurance_buff.vpcf", unit, 1.0)
    end

    caster:AddNewModifier(caster, self, "modifier_artemis_cowl_buff", { duration = duration })

    caster:EmitSound("DOTA_Item.DoE.Activate")
end
------------
function modifier_artemis_cowl_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE, --GetModifierAttackSpeedPercentage
    }

    return funcs
end

function modifier_artemis_cowl_buff:GetModifierMoveSpeedBonus_Percentage()
    return self.bonusSpeed
end

function modifier_artemis_cowl_buff:GetModifierAttackSpeedPercentage()
    return self.bonusSpeed
end

function modifier_artemis_cowl_buff:OnCreated(params)
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.bonusSpeed = self:GetAbility():GetLevelSpecialValueFor("active_bonus_speed_pct", (self:GetAbility():GetLevel() - 1))
    end
end
------------
function modifier_artemis_cowl:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus,
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
    }

    return funcs
end

function modifier_artemis_cowl:OnCreated()
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.allStats = self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
        self.bonusHealth = self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
        self.bonusInt = self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
        self.bonusHealthRegen = self:GetAbility():GetLevelSpecialValueFor("bonus_regen", (self:GetAbility():GetLevel() - 1))
        self.bonusArmor = self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
        self.auraRadius = self:GetAbility():GetLevelSpecialValueFor("aura_radius", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_artemis_cowl:IsAura()
  return true
end

function modifier_artemis_cowl:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_CREEP)
end

function modifier_artemis_cowl:GetAuraSearchTeam()
  return bit.bor(DOTA_UNIT_TARGET_TEAM_FRIENDLY)
end

function modifier_artemis_cowl:GetAuraRadius()
  return self.auraRadius
end

function modifier_artemis_cowl:GetModifierAura()
    return "modifier_artemis_cowl_aura"
end

function modifier_artemis_cowl:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED
end

function modifier_artemis_cowl:GetAuraEntityReject(target)
    return target:GetOwner() ~= self:GetCaster()
end

function modifier_artemis_cowl:GetModifierBonusStats_Intellect()
    return (self.bonusInt + self.allStats) or (self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1)) + self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1)))
end

function modifier_artemis_cowl:GetModifierBonusStats_Agility()
    return self.allStats or self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_artemis_cowl:GetModifierBonusStats_Strength()
    return self.allStats or self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_artemis_cowl:GetModifierConstantHealthRegen()
    return self.bonusHealthRegen or self:GetAbility():GetLevelSpecialValueFor("bonus_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_artemis_cowl:GetModifierPhysicalArmorBonus()
    return self.bonusArmor or self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_artemis_cowl:GetModifierHealthBonus()
    return self.bonusHealth or self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
end
--------------
function modifier_artemis_cowl_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE, --GetModifierDamageOutgoing_Percentage
    }

    return funcs
end

function modifier_artemis_cowl_aura:OnCreated()
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.magicResistance = self:GetAbility():GetLevelSpecialValueFor("aura_magic_resistance_pct", (self:GetAbility():GetLevel() - 1))
        self.bonusDamage = self:GetAbility():GetLevelSpecialValueFor("aura_bonus_damage_pct", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_artemis_cowl_aura:GetModifierMagicalResistanceBonus()
    return self.magicResistance or self:GetAbility():GetLevelSpecialValueFor("aura_magic_resistance_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_artemis_cowl_aura:GetModifierDamageOutgoing_Percentage()
    return self.bonusDamage or self:GetAbility():GetLevelSpecialValueFor("aura_bonus_damage_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_artemis_cowl_aura:GetEffectName()
    return "particles/items_fx/aura_endurance.vpcf"
end