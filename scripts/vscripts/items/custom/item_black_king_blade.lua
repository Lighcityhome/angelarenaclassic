LinkLuaModifier("modifier_black_king_blade", "items/custom/item_black_king_blade.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_black_king_blade_active", "items/custom/item_black_king_blade.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_black_king_blade_debuff", "items/custom/item_black_king_blade.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseDebuffClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseActiveClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
}

item_black_king_blade = class(ItemBaseClass)
item_black_king_blade_2 = item_black_king_blade
item_black_king_blade_3 = item_black_king_blade
modifier_black_king_blade = class(item_black_king_blade)
modifier_black_king_blade_debuff = class(ItemBaseDebuffClass)
modifier_black_king_blade_active = class(ItemBaseActiveClass)
-------------
function item_black_king_blade:GetIntrinsicModifierName()
    return "modifier_black_king_blade"
end

function item_black_king_blade:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self

    local duration = self:GetLevelSpecialValueFor("magic_immunity_duration", (self:GetLevel() - 1)) 

    CreateParticleWithTargetAndDuration("particles/items_fx/black_king_bar_avatar.vpcf", caster, duration)

    caster:Purge(false, true, false, true, true)
    caster:AddNewModifier(caster, ability, "modifier_black_king_blade_active", { duration = duration, amount = amount })

    EmitSoundOnLocationWithCaster(caster:GetOrigin(), "DOTA_Item.BlackKingBar.Activate", caster)
end
------------

function modifier_black_king_blade:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,--GetModifierAttackSpeedBonus_Constant
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_black_king_blade:OnCreated()
    if not IsServer() then return end

    self.duration = self:GetAbility():GetLevelSpecialValueFor("magical_damage_reduction_duration", (self:GetAbility():GetLevel() - 1)) 
    self.amount = self:GetAbility():GetLevelSpecialValueFor("magical_damage_reduction_amount", (self:GetAbility():GetLevel() - 1)) 
end

function modifier_black_king_blade:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target

    if self:GetCaster() ~= attacker or not victim:IsHero() or victim:IsIllusion() or not UnitIsNotMonkeyClone(attacker) then return end

    local debuff = victim:FindModifierByNameAndCaster("modifier_black_king_blade_debuff", attacker)

    if not debuff then
        victim:AddNewModifier(attacker, self:GetAbility(), "modifier_black_king_blade_debuff", { duration = self.duration, amount = self.amount })
    else
        debuff:ForceRefresh()
    end
end

function modifier_black_king_blade:GetModifierHealthBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
end

function modifier_black_king_blade:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
end

function modifier_black_king_blade:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_black_king_blade:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_black_king_blade:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end
------------
function modifier_black_king_blade_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
    }
    return funcs
end

function modifier_black_king_blade_debuff:OnCreated(params)
    self.amount = params.amount
end

function modifier_black_king_blade_debuff:GetModifierSpellAmplify_Percentage()
    return self.amount
end
------------
function modifier_black_king_blade_active:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MODEL_SCALE, --GetModifierModelScale
    }
    return funcs
end

function modifier_black_king_blade_active:GetModifierModelScale()
    return 30.0
end

function modifier_black_king_blade_active:CheckState()
    local states = {
        [MODIFIER_STATE_MAGIC_IMMUNE] = true
    }

    return states
end