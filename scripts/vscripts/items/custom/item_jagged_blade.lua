LinkLuaModifier("modifier_jagged_blade", "items/custom/item_jagged_blade.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jagged_blade_debuff", "items/custom/item_jagged_blade.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jagged_blade_disarmor", "items/custom/item_jagged_blade.lua", LUA_MODIFIER_MOTION_NONE)

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

item_jagged_blade = class(ItemBaseClass)
item_jagged_blade_2 = item_jagged_blade
item_jagged_blade_3 = item_jagged_blade
modifier_jagged_blade_debuff = class(ItemBaseDebuffClass)
modifier_jagged_blade_disarmor = class(ItemBaseDebuffClass)
modifier_jagged_blade = class(item_jagged_blade)
-------------
function item_jagged_blade:GetIntrinsicModifierName()
    return "modifier_jagged_blade"
end
------------
function modifier_jagged_blade_disarmor:OnCreated()
    local ability = self:GetAbility()

    if ability and not ability:IsNull() then
        self.armor = self:GetAbility():GetLevelSpecialValueFor("corruption_armor_base", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_jagged_blade_disarmor:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus (flat)
    }

    return funcs
end

function modifier_jagged_blade_disarmor:GetModifierPhysicalArmorBonus()
    if self:GetCaster():HasModifier("modifier_item_desolator") then return end
    
    return self.armor or self:GetAbility():GetLevelSpecialValueFor("corruption_armor_base", (self:GetAbility():GetLevel() - 1)) 
end
------------
function modifier_jagged_blade_debuff:OnCreated()
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.maxPct = self:GetAbility():GetLevelSpecialValueFor("corruption_armor_pct_max", (self:GetAbility():GetLevel() - 1)) 
        self.corAmt = self:GetAbility():GetLevelSpecialValueFor("corruption_armor_pct", (self:GetAbility():GetLevel() - 1)) 
    end
end

function modifier_jagged_blade_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_jagged_blade_debuff:DeclareFunctions()
    if self:GetParent():IsIllusion() or self:GetParent():IsControllableByAnyPlayer() then
        return
    end
    
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BASE_PERCENTAGE, --GetModifierPhysicalArmorBase_Percentage (%)
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus (flat)
    }

    return funcs
end

function modifier_jagged_blade_debuff:GetModifierPhysicalArmorBase_Percentage()
    local stackCount = self:GetParent():GetModifierStackCount("modifier_jagged_blade_debuff", self:GetCaster())
    local maxReduction = stackCount

    if maxReduction >= self.maxPct then
        maxReduction = self.maxPct
    end

    if self.corAmt then
        return 100 - math.abs(maxReduction * self.corAmt)
    else
        return 100 - math.abs(maxReduction * self:GetAbility():GetLevelSpecialValueFor("corruption_armor_pct", (self:GetAbility():GetLevel() - 1)))
    end
end

function modifier_jagged_blade_debuff:GetModifierPhysicalArmorBonus()
    local stackCount = self:GetParent():GetModifierStackCount("modifier_jagged_blade_debuff", self:GetCaster())
    local maxReduction = stackCount

    if maxReduction < self.maxPct then
        maxReduction = 0
        return 0
    end

    return (maxReduction - self.maxPct) * self:GetAbility():GetLevelSpecialValueFor("corruption_armor", (self:GetAbility():GetLevel() - 1)) 
end
------------
function modifier_jagged_blade:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        --MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        --MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        --MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        --MODIFIER_PROPERTY_EVASION_CONSTANT, --GetModifierEvasion_Constant
        
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_jagged_blade:OnCreated()
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.damage = self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
        self.attackspeed = self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
        self.movespeed = self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed_pct", (self:GetAbility():GetLevel() - 1))
        self.agility = self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
        self.evasion = self:GetAbility():GetLevelSpecialValueFor("bonus_evasion", (self:GetAbility():GetLevel() - 1))
        self.duration = self:GetAbility():GetLevelSpecialValueFor("corruption_duration", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_jagged_blade:OnRemoved()
    if not IsServer() then return end
end

function modifier_jagged_blade:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target

    if self:GetCaster() ~= attacker then
        return
    end

    if not attacker:IsRealHero() or attacker:IsIllusion() or not UnitIsNotMonkeyClone(attacker) or attacker:IsMuted() then return end

    local disarm = victim:FindModifierByNameAndCaster("modifier_jagged_blade_disarmor", attacker)
    
    if not disarm then
        victim:AddNewModifier(attacker, self:GetAbility(), "modifier_jagged_blade_disarmor", { duration = self.duration })
    else
        disarm:ForceRefresh()
    end

    if victim:IsMagicImmune() or (not IsBossUBA(victim) and not victim:IsRealHero()) or victim:IsBuilding() then return end
    
    local debuff = victim:FindModifierByNameAndCaster("modifier_jagged_blade_debuff", attacker)
    local stacks = victim:GetModifierStackCount("modifier_jagged_blade_debuff", attacker)
    
    if not debuff then
        victim:AddNewModifier(attacker, self:GetAbility(), "modifier_jagged_blade_debuff", { duration = self.duration })
        victim:SetModifierStackCount("modifier_jagged_blade_debuff", attacker, 1)
    else
        debuff:ForceRefresh()
        victim:SetModifierStackCount("modifier_jagged_blade_debuff", attacker, (stacks + 1))
    end
end

function modifier_jagged_blade:GetModifierPreAttack_BonusDamage()
    return self.damage or self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_jagged_blade:GetModifierAttackSpeedBonus_Constant()
    return self.attackspeed or self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_jagged_blade:GetModifierMoveSpeedBonus_Percentage()
    return self.movespeed or self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_jagged_blade:GetModifierBonusStats_Agility()
    return self.agility or self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
end

function modifier_jagged_blade:GetModifierEvasion_Constant()
    return self.evasion or self:GetAbility():GetLevelSpecialValueFor("bonus_evasion", (self:GetAbility():GetLevel() - 1))
end