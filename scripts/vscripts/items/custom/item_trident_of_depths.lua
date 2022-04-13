require("libraries/cfinder")

LinkLuaModifier("modifier_trident_of_depths", "items/custom/item_trident_of_depths.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_trident_of_depths_crit", "items/custom/item_trident_of_depths.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_trident_of_depths = class(ItemBaseClass)
item_trident_of_depths_2 = item_trident_of_depths
item_trident_of_depths_3 = item_trident_of_depths
modifier_trident_of_depths_crit = class(ItemBaseClass)
modifier_trident_of_depths = class(item_trident_of_depths)

CRIT_IGNORE_ABILITIES = {
    "spectre_dispersion",
    "zuus_static_field",
    "death_prophet_spirit_siphon",
    "obsidian_destroyer_arcane_orb",
    "silencer_glaives_of_wisdom"
}

-------------
function item_trident_of_depths:GetIntrinsicModifierName()
    return "modifier_trident_of_depths"
end
------------
function modifier_trident_of_depths_crit:OnCreated(params)
    self.critChance = params.critChance
    self.critDmg = params.critDmg
end

function modifier_trident_of_depths_crit:DeclareFunctions()
    local funcs = {
        --MODIFIER_EVENT_ON_TAKEDAMAGE // This is handled in addon_game_mode damage filter because it deals duplicate damage otherwise
    }

    return funcs
end

function modifier_trident_of_depths_crit:OnTakeDamage(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end
    
    if (event.attacker:IsRealHero() or event.attacker:GetUnitName() == "boss_river") and not event.unit:IsBuilding() and not event.unit:IsOther() then
        if self:GetParent():FindAllModifiersByName(self:GetName())[1] == self and event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK and event.inflictor and (event.damage_type == DAMAGE_TYPE_MAGICAL or event.damage_type == DAMAGE_TYPE_PURE) then
            for _,banned in ipairs(CRIT_IGNORE_ABILITIES) do
                if event.inflictor:GetAbilityName() == banned then 
                    return
                end
            end

            if IsBossUBA(event.unit) then
                for _,banned in ipairs(DAMAGE_FILTER_BANNED_BOSS_ABILITIES) do
                    if event.inflictor:GetAbilityName() == banned then 
                        return
                    end
                end
            end
            
            --fix radiance and items not critting
            if RandomFloat(0.0, 1.0) <= (PrdCFinder:GetCForP((self.critChance / 100)) * 1) then
                local damageDone = event.damage * (self.critDmg / 100)

                local critDamage = {
                    victim = event.unit,
                    attacker = event.attacker,
                    damage = damageDone,
                    damage_type = DAMAGE_TYPE_MAGICAL,
                    ability = self:GetAbility(),
                    damage_flags = {
                        [DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION] = true
                    }
                }

                ApplyDamage(critDamage)
                SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, event.unit, damageDone, nil)
            end
        end
    end
end
------------
function modifier_trident_of_depths:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_MANA_REGEN_PERCENTAGE, -- GetModifierPercentageManaRegen
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, -- GetModifierSpellLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_STATUS_RESISTANCE, --GetModifierStatusResistance
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
    }

    return funcs
end

function modifier_trident_of_depths:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local critChance = self:GetAbility():GetLevelSpecialValueFor("spell_crit_chance", (self:GetAbility():GetLevel() - 1))
    local critDmg = self:GetAbility():GetLevelSpecialValueFor("spell_crit_damage", (self:GetAbility():GetLevel() - 1))

    Timers:CreateTimer(0.5, function()
        caster:AddNewModifier(caster, self, "modifier_trident_of_depths_crit", { critChance = critChance, critDmg = critDmg })
    end)
end

function modifier_trident_of_depths:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("modifier_trident_of_depths_crit")
end

function modifier_trident_of_depths:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_trident_of_depths:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_trident_of_depths:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_trident_of_depths:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("spell_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_trident_of_depths:GetModifierPercentageManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("mana_regen_multiplier", (self:GetAbility():GetLevel() - 1))
end

function modifier_trident_of_depths:GetModifierSpellLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("spell_lifesteal_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_trident_of_depths:GetModifierStatusResistance()
    return self:GetAbility():GetLevelSpecialValueFor("status_resistance", (self:GetAbility():GetLevel() - 1))
end

function modifier_trident_of_depths:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_trident_of_depths:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end
