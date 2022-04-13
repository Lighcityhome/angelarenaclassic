LinkLuaModifier("modifier_kings_guard", "items/custom/item_kings_guard.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kings_guard_aura", "items/custom/item_kings_guard.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kings_guard_aura_enemy", "items/custom/item_kings_guard.lua", LUA_MODIFIER_MOTION_NONE)

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

item_kings_guard = class(ItemBaseClass)
item_kings_guard_2 = item_kings_guard
item_kings_guard_3 = item_kings_guard
modifier_kings_guard = class(item_kings_guard)
modifier_kings_guard_aura = class(ItemBaseClassAura)
modifier_kings_guard_aura_enemy = class(ItemBaseClassAura)
-------------
function item_kings_guard:GetIntrinsicModifierName()
    return "modifier_kings_guard"
end

function item_kings_guard:GetAOERadius()
    return 1200
end
------------

function modifier_kings_guard:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,--GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
    }

    return funcs
end

function modifier_kings_guard:OnCreated()
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.allStats = self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
        self.bonusAttackSpeed = self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
        self.bonusHealth = self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
        self.bonusArmor = self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
    end

    self.caster = self:GetCaster()
    self.aura_modifier_name = "modifier_kings_guard_aura"
    self.allyAura = "modifier_kings_guard_aura"
    self.enemyAura = "modifier_kings_guard_aura_enemy"
end

function modifier_kings_guard:IsAura()
  return true
end

function modifier_kings_guard:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BUILDING)
end

function modifier_kings_guard:GetAuraSearchTeam()
  return bit.bor(DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_TEAM_ENEMY)
end

function modifier_kings_guard:GetAuraRadius()
  return 1200
end

function modifier_kings_guard:GetModifierAura()
    return self.aura_modifier_name
end

function modifier_kings_guard:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
end

function modifier_kings_guard:GetAuraEntityReject(target)
    if target:GetTeamNumber() == self.caster:GetTeamNumber() then
        self.aura_modifier_name = self.allyAura
    else
        self.aura_modifier_name = self.enemyAura
    end

    return false
end
----------
function modifier_kings_guard_aura:OnCreated()
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.armor = self:GetAbility():GetLevelSpecialValueFor("aura_bonus_armor", (self:GetAbility():GetLevel() - 1))
        self.block = self:GetAbility():GetLevelSpecialValueFor("aura_block_damage", (self:GetAbility():GetLevel() - 1))
        self.attackSpeed = self:GetAbility():GetLevelSpecialValueFor("aura_attack_speed", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_kings_guard_aura:IsDebuff()
    return false
end

function modifier_kings_guard_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK, --GetModifierPhysical_ConstantBlock
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
    }

    return funcs
end

function modifier_kings_guard_aura:GetModifierPhysical_ConstantBlock()
    return self.block or self:GetAbility():GetLevelSpecialValueFor("aura_block_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_kings_guard_aura:GetModifierAttackSpeedBonus_Constant()
    return self.attackSpeed or self:GetAbility():GetLevelSpecialValueFor("aura_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_kings_guard_aura:GetModifierPhysicalArmorBonus()
    return self.armor or self:GetAbility():GetLevelSpecialValueFor("aura_bonus_armor", (self:GetAbility():GetLevel() - 1))
end
----------
function modifier_kings_guard_aura_enemy:OnCreated()
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.armorReduction = ability:GetLevelSpecialValueFor("aura_armor_reduction", (ability:GetLevel() - 1))
    end
end

function modifier_kings_guard_aura_enemy:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
    }

    return funcs
end

function modifier_kings_guard_aura_enemy:GetModifierPhysicalArmorBonus()
    return self.armorReduction or self:GetAbility():GetSpecialValueFor("aura_armor_reduction")
end

function modifier_kings_guard_aura_enemy:IsDebuff()
    return true
end
----------

function modifier_kings_guard:GetModifierBonusStats_Strength()
    return self.allStats or self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_kings_guard:GetModifierBonusStats_Agility()
    return self.allStats or self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_kings_guard:GetModifierBonusStats_Intellect()
    return self.allStats or self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_kings_guard:GetModifierAttackSpeedBonus_Constant()
    return self.bonusAttackSpeed or self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_kings_guard:GetModifierHealthBonus()
    return self.bonusHealth or self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
end

function modifier_kings_guard:GetModifierPhysicalArmorBonus()
    return self.bonusArmor or self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end
