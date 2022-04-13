LinkLuaModifier("modifier_gamma_orb", "items/custom/item_gamma_orb.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_gamma_orb = class(ItemBaseClass)
item_gamma_orb_2 = item_gamma_orb
item_gamma_orb_3 = item_gamma_orb
modifier_gamma_orb = class(item_gamma_orb)

BANNED_ITEMS = {
    "item_gamma_orb",
    "item_gamma_orb_2",
    "item_gamma_orb_3",
    "item_refresher"
}

BANNED_ABILITIES = {
    "tinker_rearm"
}

EXEMPT_ITEMS = {
    ["item_gamma_orb"] = true,
    ["item_gamma_orb_2"] = true,
    ["item_gamma_orb_3"] = true,
    ["item_refresher"] = true
}
-------------
function item_gamma_orb:GetIntrinsicModifierName()
    return "modifier_gamma_orb"
end

function IsItemException(item)
    return EXEMPT_ITEMS[item:GetName()]
end

function item_gamma_orb:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local particle = ParticleManager:CreateParticle("particles/items2_fx/refresher.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle)

    EmitSoundOnLocationWithCaster(caster:GetOrigin(), "DOTA_Item.Refresher.Activate", caster)

    for i=0, caster:GetAbilityCount()-1 do
        local abil = caster:GetAbilityByIndex(i)
        if abil ~= nil then
            for _,banned in ipairs(BANNED_ABILITIES) do
                if abil:GetAbilityName() == banned then return end
            end

            abil:EndCooldown()
        end
    end

    for i=0,8 do
        local item = caster:GetItemInSlot(i)
        if item ~= nil then
            local pass = false
            if item:GetPurchaser() == caster and not IsItemException(item) then
                pass = true
            end

            if pass then
                item:EndCooldown()
            end
        end
    end
end
------------

function modifier_gamma_orb:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_CASTTIME_PERCENTAGE
    }

    return funcs
end

function modifier_gamma_orb:GetModifierPercentageCasttime()
    return self:GetAbility():GetLevelSpecialValueFor("cast_point_reduction", (self:GetAbility():GetLevel() - 1))
end

function modifier_gamma_orb:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_gamma_orb:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
end

function modifier_gamma_orb:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
end

function modifier_gamma_orb:GetModifierConstantHealthRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_gamma_orb:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end