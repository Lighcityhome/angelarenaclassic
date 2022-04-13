LinkLuaModifier("modifier_war_banner", "items/custom/item_war_banner.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_war_banner_aura", "items/custom/item_war_banner.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lifesteal_uba", "modifiers/modifier_lifesteal_uba.lua", LUA_MODIFIER_MOTION_NONE)

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

item_war_banner = class(ItemBaseClass)
item_war_banner_2 = item_war_banner
item_war_banner_3 = item_war_banner
modifier_war_banner = class(item_war_banner)
modifier_war_banner_aura = class(ItemBaseClassAura)
-------------
function item_war_banner:GetIntrinsicModifierName()
    return "modifier_war_banner"
end

function item_war_banner:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
------------

function modifier_war_banner:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, --GetModifierMoveSpeedBonus_Constant
    }

    return funcs
end

function modifier_war_banner:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByNameAndCaster("modifier_lifesteal_uba", caster)
end

function modifier_war_banner:OnCreated()
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.allStats = self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
        self.bonusHealthRegen = self:GetAbility():GetLevelSpecialValueFor("bonus_health_regen", (self:GetAbility():GetLevel() - 1))
        self.bonusSpeed = self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1))
        self.bonusArmor = self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
        self.auraRadius = self:GetAbility():GetLevelSpecialValueFor("radius", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_war_banner:IsAura()
  return true
end

function modifier_war_banner:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_war_banner:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_war_banner:GetAuraRadius()
  return self.auraRadius or self:GetAbility():GetLevelSpecialValueFor("radius", (self:GetAbility():GetLevel() - 1))
end

function modifier_war_banner:GetModifierAura()
    return "modifier_war_banner_aura"
end

function modifier_war_banner:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_war_banner:GetAuraEntityReject(target)
    return false
end

function modifier_war_banner:GetModifierBonusStats_Strength()
    return self.allStats or self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_war_banner:GetModifierBonusStats_Agility()
    return self.allStats or self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_war_banner:GetModifierBonusStats_Intellect()
    return self.allStats or self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_war_banner:GetModifierConstantHealthRegen()
    return self.bonusHealthRegen or self:GetAbility():GetLevelSpecialValueFor("bonus_health_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_war_banner:GetModifierHealthBonus()
    return self.bonusSpeed or self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_war_banner:GetModifierPhysicalArmorBonus()
    return self.bonusArmor or self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end
----------
function modifier_war_banner_aura:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.damage = self:GetAbility():GetLevelSpecialValueFor("aura_bonus_damage_pct", (self:GetAbility():GetLevel() - 1))
        self.manaRegen = self:GetAbility():GetLevelSpecialValueFor("aura_bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
        self.armor = self:GetAbility():GetLevelSpecialValueFor("aura_bonus_armor", (self:GetAbility():GetLevel() - 1))
        self.attackSpeed = self:GetAbility():GetLevelSpecialValueFor("armor_bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
        self.movespeed = self:GetAbility():GetLevelSpecialValueFor("aura_bonus_movement_speed_pct", (self:GetAbility():GetLevel() - 1))
        self.lifesteal = self:GetAbility():GetLevelSpecialValueFor("aura_life_steal", (self:GetAbility():GetLevel() - 1))

        local target = self:GetParent()
        local caster = self:GetCaster()

        target:AddNewModifier(caster, ability, "modifier_lifesteal_uba", { amount = self.lifesteal })
    end
end

function modifier_war_banner_aura:OnRemoved()
    if not IsServer() then return end

    local target = self:GetParent()
    local caster = self:GetCaster()

    target:RemoveModifierByNameAndCaster("modifier_lifesteal_uba", caster)
end

function modifier_war_banner_aura:IsDebuff()
    return false
end

function modifier_war_banner_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE, --GetModifierBaseDamageOutgoing_Percentage
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
    }

    return funcs
end

function modifier_war_banner_aura:GetModifierBaseDamageOutgoing_Percentage()
    return self.damage or self:GetAbility():GetLevelSpecialValueFor("aura_bonus_damage_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_war_banner_aura:GetModifierConstantManaRegen()
    return self.manaRegen or self:GetAbility():GetLevelSpecialValueFor("aura_bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_war_banner_aura:GetModifierPhysicalArmorBonus()
    return self.armor or self:GetAbility():GetLevelSpecialValueFor("aura_bonus_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_war_banner_aura:GetModifierAttackSpeedBonus_Constant()
    return self.attackSpeed or self:GetAbility():GetLevelSpecialValueFor("armor_bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_war_banner_aura:GetModifierMoveSpeedBonus_Percentage()
    return self.movespeed or self:GetAbility():GetLevelSpecialValueFor("aura_bonus_movement_speed_pct", (self:GetAbility():GetLevel() - 1))
end