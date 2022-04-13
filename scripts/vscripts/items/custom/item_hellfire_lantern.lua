LinkLuaModifier("modifier_hellfire_lantern", "items/custom/item_hellfire_lantern.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hellfire_lantern_debuff", "items/custom/item_hellfire_lantern.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lifesteal_uba", "modifiers/modifier_lifesteal_uba.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end
}

local ItemBaseDebuffClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end
}

item_hellfire_lantern = class(ItemBaseClass)
item_hellfire_lantern_2 = item_hellfire_lantern
item_hellfire_lantern_3 = item_hellfire_lantern
modifier_hellfire_lantern_debuff = class(ItemBaseDebuffClass)
modifier_hellfire_lantern = class(item_hellfire_lantern)
-------------
function item_hellfire_lantern:GetIntrinsicModifierName()
    return "modifier_hellfire_lantern"
end
------------
function modifier_hellfire_lantern_debuff:OnCreated()
    if not IsServer() then return end

    self.burnDamage = self:GetAbility():GetLevelSpecialValueFor("burn_damage", (self:GetAbility():GetLevel() - 1)) 

    self:StartIntervalThink(1.0)
end

function modifier_hellfire_lantern_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_hellfire_lantern_debuff:OnIntervalThink()
    if not IsServer() then return end

    local attacker = self:GetCaster()
    local victim = self:GetParent()

    if not victim or not attacker then return end
    if victim:IsMagicImmune() then return end

    local totalBurnDamage = self.burnDamage * victim:GetModifierStackCount("modifier_hellfire_lantern_debuff", attacker) -- returns 0

    local damage = {
        victim = victim,
        attacker = attacker,
        damage = totalBurnDamage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    }

    ApplyDamage(damage)

    if attacker:IsAlive() and attacker:GetHealth() > 0 then
        -- Calculate damage done after magic resistance
        local healAmount = (totalBurnDamage * (1.0 - (victim:GetMagicalArmorValue() / 100))) * 0.3
        attacker:Heal(healAmount, attacker)
    end
end

function modifier_hellfire_lantern_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_burn.vpcf"
end

function modifier_hellfire_lantern_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MISS_PERCENTAGE, --GetModifierMiss_Percentage
    }

    return funcs
end

function modifier_hellfire_lantern_debuff:GetModifierMiss_Percentage()
    local stackCount = self:GetParent():GetModifierStackCount("modifier_hellfire_lantern_debuff", self:GetCaster())

    return stackCount * self:GetAbility():GetLevelSpecialValueFor("burn_blind", (self:GetAbility():GetLevel() - 1)) 
end
------------
function modifier_hellfire_lantern:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        --MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_hellfire_lantern:OnCreated()
    if not IsServer() then return end

    self.burnDuration = self:GetAbility():GetLevelSpecialValueFor("burn_duration", (self:GetAbility():GetLevel() - 1))
    self.maxStacks = self:GetAbility():GetLevelSpecialValueFor("burn_stacks", (self:GetAbility():GetLevel() - 1))

    local lifesteal = self:GetAbility():GetLevelSpecialValueFor("lifesteal_percent", (self:GetAbility():GetLevel() - 1))

    if not UnitIsNotMonkeyClone(self:GetCaster()) then return end

    self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_lifesteal_uba", { amount = lifesteal })
end

function modifier_hellfire_lantern:OnRemoved()
    if not IsServer() then return end

    self:GetCaster():RemoveModifierByNameAndCaster("modifier_lifesteal_uba", self:GetCaster())
end

function modifier_hellfire_lantern:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target

    if self:GetCaster() ~= attacker then
        return
    end

    if not attacker:IsRealHero() or attacker:IsIllusion() or not UnitIsNotMonkeyClone(attacker) or attacker:IsMuted() or victim:IsMagicImmune() or victim:IsBuilding() then return end
    
    local debuff = victim:FindModifierByNameAndCaster("modifier_hellfire_lantern_debuff", attacker)
    local stacks = victim:GetModifierStackCount("modifier_hellfire_lantern_debuff", attacker)
    
    if not debuff then
        victim:AddNewModifier(attacker, self:GetAbility(), "modifier_hellfire_lantern_debuff", { duration = self.burnDuration })
    else
        debuff:ForceRefresh()
    end

    if stacks < self.maxStacks then
        victim:SetModifierStackCount("modifier_hellfire_lantern_debuff", attacker, (stacks + 1))
    end
end

function modifier_hellfire_lantern:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_hellfire_lantern:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_hellfire_lantern:GetModifierConstantHealthRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_hellfire_lantern:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end

--function modifier_hellfire_lantern:GetModifierLifestealRegenAmplify_Percentage()
    --return self:GetAbility():GetLevelSpecialValueFor("lifesteal_percent", (self:GetAbility():GetLevel() - 1))
--end
