LinkLuaModifier("modifier_readers_guide", "items/custom/item_readers_guide.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_readers_guide = class(ItemBaseClass)
modifier_readers_guide = class(item_readers_guide)
-------------
function item_readers_guide:GetIntrinsicModifierName()
    return "modifier_readers_guide"
end
------------

function modifier_readers_guide:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_EVENT_ON_TAKEDAMAGE, --OnTakeDamage
        MODIFIER_EVENT_ON_DEATH,
    }

    return funcs
end

function modifier_readers_guide:OnRunePickup(event)
    if not IsServer() then return end

    if (event.PlayerID ~= self:GetCaster():GetPlayerID()) or (event.rune ~= 5) or (self:GetAbility():GetCurrentCharges() >= 10) then return end

    self:GetAbility():SetCurrentCharges(self:GetAbility():GetCurrentCharges() + 1)
end

function modifier_readers_guide:OnCreated()
    if not IsServer() then return end

    ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(modifier_readers_guide, 'OnRunePickup'), self)

    self.maxXP = 100
    self.minXP = 25

    self:GetAbility():SetCurrentCharges(0)
end

function modifier_readers_guide:OnRemoved()
    if not IsServer() then return end

    self:GetAbility():SetCurrentCharges(0)
end

function modifier_readers_guide:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetCaster() then
        return
    end

    if self:GetAbility():GetCurrentCharges() <= 0 then 
        return
    end

    self:GetAbility():SetCurrentCharges(self:GetAbility():GetCurrentCharges() - 1)
end

function modifier_readers_guide:OnTakeDamage(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.unit
    local attack_damage = event.damage

    if not self:GetAbility():IsCooldownReady() or self:GetCaster() ~= attacker or not victim:IsHero() or victim == self:GetCaster() then
        return
    end

    local xpToAdd = (event.damage * 0.15) + (10 * self:GetAbility():GetCurrentCharges())

    if xpToAdd > self.maxXP then
        xpToAdd = self.maxXP
    elseif xpToAdd < self.minXP then
        xpToAdd = self.minXP
    end

    attacker:AddExperience(xpToAdd, DOTA_ModifyXP_Unspecified, false, false)
    self:GetAbility():StartCooldown(5)
end

function modifier_readers_guide:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_readers_guide:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_readers_guide:GetModifierConstantHealthRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health_regen", (self:GetAbility():GetLevel() - 1))
end