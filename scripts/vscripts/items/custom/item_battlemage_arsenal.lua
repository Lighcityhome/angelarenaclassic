LinkLuaModifier("modifier_battlemage_arsenal", "items/custom/item_battlemage_arsenal.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_battlemage_arsenal_debuff", "items/custom/item_battlemage_arsenal.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemDebuffBaseClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

item_battlemage_arsenal = class(ItemBaseClass)
item_battlemage_arsenal_2 = item_battlemage_arsenal
item_battlemage_arsenal_3 = item_battlemage_arsenal
modifier_battlemage_arsenal = class(item_battlemage_arsenal)
modifier_battlemage_arsenal_debuff = class(ItemDebuffBaseClass)
-------------
function item_battlemage_arsenal:GetIntrinsicModifierName()
    return "modifier_battlemage_arsenal"
end
------------
function modifier_battlemage_arsenal_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_EVENT_ON_ATTACK_LANDED, --OnAttackLanded
    }

    return funcs
end

function modifier_battlemage_arsenal_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self.slow
end

function modifier_battlemage_arsenal_debuff:OnCreated(params)
    if not IsServer() then return end

    self.slow = params.amount
    self.int_multi = params.multi
    self.baseInt = params.baseInt

    self:StartIntervalThink(1.0)
end

function modifier_battlemage_arsenal_debuff:OnIntervalThink(event)
    if self:GetParent() == nil then
        return
    end

    local ability = self:GetAbility()
    if not ability or ability:IsNull() then return end
    if self:GetParent():IsMagicImmune() then return end

    local damageDone = self.baseInt * self.int_multi

    local damage = {
        victim = self:GetParent(),
        attacker = ability:GetCaster(),
        damage = damageDone,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    }

    ApplyDamage(damage)
    SendOverheadEventMessage(undefined, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, self:GetParent(), damageDone, undefined);
end
------------

function modifier_battlemage_arsenal:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_MANA_REGEN_PERCENTAGE, -- GetModifierPercentageManaRegen
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, -- GetModifierSpellLifestealRegenAmplify_Percentage
        MODIFIER_EVENT_ON_ATTACK_LANDED, --OnAttackLanded
        MODIFIER_EVENT_ON_ATTACK
    }

    return funcs
end

function modifier_battlemage_arsenal:OnCreated()
    if not IsServer() then return end
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    
    self.slow_duration = self:GetAbility():GetLevelSpecialValueFor("slow_duration", (self:GetAbility():GetLevel() - 1))
    self.slow_amount = self:GetAbility():GetLevelSpecialValueFor("slow", (self:GetAbility():GetLevel() - 1))
    self.int_multiplier = self:GetAbility():GetLevelSpecialValueFor("int_damage_multiplier", (self:GetAbility():GetLevel() - 1))
    self.cooldown = self:GetAbility():GetLevelSpecialValueFor("tooltip_cooldown", (self:GetAbility():GetLevel() - 1))
    self.delay = self:GetAbility():GetLevelSpecialValueFor("delay", (self:GetAbility():GetLevel() - 1))
end

function modifier_battlemage_arsenal:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()
end

function modifier_battlemage_arsenal:OnAttack(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target
    local ability = self:GetAbility()

    if not ability or ability == nil then return end

    if self:GetCaster() ~= attacker then
        return
    end

    if not attacker:IsRangedAttacker() or not attacker:IsRealHero() then return end
    if not ability:IsCooldownReady() then return end

    if attacker:HasModifier("modifier_nyx_assassin_vendetta") then
        attacker:RemoveModifierByName("modifier_nyx_assassin_vendetta")
    end

    Timers:CreateTimer(self.delay, function()
        if not ability:IsCooldownReady() then return end

        attacker:PerformAttack(victim, false, true, true, false, true, false, true)
        ability:StartCooldown(self.cooldown)
    end)
end

function modifier_battlemage_arsenal:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target
    local ability = self:GetAbility()

    if not ability or ability == nil then return end

    if self:GetCaster() ~= attacker then
        return
    end

    if victim:IsMagicImmune() or not attacker:IsRealHero() then return end
    if not ability:IsCooldownReady() then return end

    if not victim:HasModifier("modifier_battlemage_arsenal_debuff") then
        victim:AddNewModifier(victim, ability, "modifier_battlemage_arsenal_debuff", { duration = self.slow_duration, baseInt = attacker:GetIntellect(), amount = self.slow_amount, multi = self.int_multiplier })
    else
        victim:FindModifierByName("modifier_battlemage_arsenal_debuff"):ForceRefresh()
    end
end

function modifier_battlemage_arsenal:GetModifierHealthBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
end

function modifier_battlemage_arsenal:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_battlemage_arsenal:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
end

function modifier_battlemage_arsenal:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_spell_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_battlemage_arsenal:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_battlemage_arsenal:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_battlemage_arsenal:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_battlemage_arsenal:GetModifierPercentageManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("mana_regen_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_battlemage_arsenal:GetModifierSpellLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("spell_lifesteal_amp", (self:GetAbility():GetLevel() - 1))
end