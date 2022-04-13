LinkLuaModifier("modifier_last_resort", "items/custom/item_last_resort.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_last_resort_buff", "items/custom/item_last_resort.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

item_last_resort = class(ItemBaseClass)
modifier_last_resort = class(item_last_resort)
modifier_last_resort_buff = class(ItemBaseClassBuff)
-------------
function item_last_resort:GetIntrinsicModifierName()
    return "modifier_last_resort"
end

function item_last_resort:OnSpellStart()
    if not IsServer() then return end
    --for 10 sec gain 5 armor, 30 speed, 10 hp regen (20s cd)
    local duration = self:GetLevelSpecialValueFor("bonus_duration_tooltip", (self:GetLevel() - 1))
    local armor_bonus = self:GetLevelSpecialValueFor("bonus_armor_tooltip", (self:GetLevel() - 1))
    local speed_bonus = self:GetLevelSpecialValueFor("bonus_movement_speed_tooltip", (self:GetLevel() - 1))
    local regen_bonus = self:GetLevelSpecialValueFor("bonus_health_regen_tooltip", (self:GetLevel() - 1))

    if not self:GetCaster():IsAlive() or self:GetCaster():GetHealth() < 1 then return end

    if not self:GetCaster():HasModifier("modifier_last_resort_buff") then
        self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_last_resort_buff", { 
            duration = duration
        })
    end
end
------------
function modifier_last_resort_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, --GetModifierMoveSpeedBonus_Constant
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_EVENT_ON_TAKEDAMAGE 
    }

    return funcs
end

function modifier_last_resort_buff:OnTakeDamage(event)
    if not IsServer() then return end
    
    if self:GetCaster() ~= event.unit then return end
    if not event.attacker:IsRealHero() then return end

    self:GetCaster():RemoveModifierByName("modifier_last_resort_buff")
end

function modifier_last_resort_buff:OnCreated()
    self.armor = 5
    self.speed = 30
    self.regen = 70
end

function modifier_last_resort_buff:GetModifierPhysicalArmorBonus()
    return self.armor
end

function modifier_last_resort_buff:GetModifierMoveSpeedBonus_Constant()
    return self.speed
end

function modifier_last_resort_buff:GetModifierConstantHealthRegen()
    return self.regen
end
------------

function modifier_last_resort:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, --GetModifierMoveSpeedBonus_Constant
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
    }

    return funcs
end

function modifier_last_resort:OnCreated()
end

function modifier_last_resort:GetModifierConstantHealthRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_last_resort:GetModifierHealthBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
end

function modifier_last_resort:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_last_resort:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
end

function modifier_last_resort:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
end

function modifier_last_resort:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_magical_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_last_resort:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_last_resort:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_last_resort:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end