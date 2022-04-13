LinkLuaModifier("modifier_roaming_wand", "items/custom/item_roaming_wand.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

BANNED_ABILITIES = {
    "medusa_mana_shield",
    "medusa_split_shot",
    "troll_warlord_berserkers_rage",
    "greevil_rot",
    "bane_nightmare_end",
    "pudge_rot",
    "witch_doctor_voodoo_restoration",
    "leshrac_pulse_nova",
    "wisp_spirits_in",
    "wisp_spirits_out",
    "item_power_treads",
    "invoker_exort",
    "invoker_quas",
    "invoker_wex"
}

item_roaming_wand = class(ItemBaseClass)
modifier_roaming_wand = class(item_roaming_wand)
-------------
function item_roaming_wand:GetIntrinsicModifierName()
    return "modifier_roaming_wand"
end

function item_roaming_wand:OnSpellStart()
    if not IsServer() then return end

    if not self:GetCaster():IsAlive() or self:GetCaster():GetHealth() < 1 then return end

    local charges = self:GetCurrentCharges()

    self:GetCaster():Heal(charges * 15, self:GetCaster())
    self:GetCaster():GiveMana(charges * 15)

    EmitSoundOnLocationWithCaster(self:GetCaster():GetOrigin(), "DOTA_Item.MagicWand.Activate", self:GetCaster())

    self:SetCurrentCharges(0)
end
------------

function modifier_roaming_wand:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_EVENT_ON_ABILITY_EXECUTED, --OnAbilityExecuted
    }

    return funcs
end

function modifier_roaming_wand:OnCreated()
    if not IsServer() then return end

    self:GetAbility():SetCurrentCharges(0)
end

function modifier_roaming_wand:OnRemoved()
    if not IsServer() then return end

    self:GetAbility():SetCurrentCharges(0)
end

function modifier_roaming_wand:OnAbilityExecuted(event)
    if not IsServer() then return end

    local caster = event.ability:GetCaster()

    -- Do not trigger on wand use
    if event.ability == self:GetAbility() then
        return 
    end

    if (caster:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Length2D() > 1200 then
        return
    end

    for _,banned in ipairs(BANNED_ABILITIES) do
        if event.ability:GetAbilityName() == banned then
            return
        end
    end

    if event.ability:IsItem() then return end

    if self:GetAbility():GetCurrentCharges() >= 20 then
        return
    end

    self:GetAbility():SetCurrentCharges(self:GetAbility():GetCurrentCharges() + 1)
end

function modifier_roaming_wand:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_roaming_wand:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_roaming_wand:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end
