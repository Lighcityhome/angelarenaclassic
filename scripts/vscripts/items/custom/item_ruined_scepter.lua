LinkLuaModifier("modifier_ruined_scepter", "items/custom/item_ruined_scepter.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ruined_scepter_buff", "items/custom/item_ruined_scepter.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return true end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
    IsPermanent = function(self) return true end,
    IsPurgeException = function(self) return false end,
}

item_ruined_scepter = class(ItemBaseClass)
modifier_ruined_scepter = class(item_ruined_scepter)
modifier_ruined_scepter_buff = class(ItemBaseClassBuff)
-------------
function item_ruined_scepter:GetIntrinsicModifierName()
    return "modifier_ruined_scepter"
end

function item_ruined_scepter:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    
    if not caster:IsAlive() or caster:GetHealthPercent() < 1 then return end

    if not caster:HasModifier("modifier_ruined_scepter_buff") then
        caster:AddNewModifier(caster, self, "modifier_ruined_scepter_buff", {});
    end

    if not caster:HasModifier("modifier_item_ultimate_scepter_consumed") then
        caster:AddNewModifier(caster, self, "modifier_item_ultimate_scepter_consumed", {});
    end
end
------------
function modifier_ruined_scepter_buff:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local unitName = caster:GetUnitName()

    if unitName == "npc_dota_hero_snapfire" then
        local mortimerKisses = caster:FindAbilityByName("snapfire_mortimer_kisses")
        if mortimerKisses:GetLevel() < 1 then
            FireGameEvent("dota_hud_error_message", { reason = 80, message = "#dota_hud_error_mortimer_kisses_missing" })
            caster:RemoveModifierByName("modifier_ruined_scepter_buff")
            return
        end

        local ability = caster:FindAbilityByName("snapfire_kisses_custom")
        ability:SetLevel(1)
        ability:SetHidden(false)
    end 

    if unitName == "npc_dota_hero_bane" then
        local ability = caster:FindAbilityByName("bane_totem_of_terror")
        ability:SetLevel(1)
        ability:SetHidden(false)
    end 

    if unitName == "npc_dota_hero_abaddon" then
        local ability = caster:FindAbilityByName("abbadon_font_overwhelming")
        ability:SetLevel(1)
        ability:SetHidden(false)
    end 

    if unitName == "npc_dota_hero_venomancer" then
        local ability = caster:FindAbilityByName("venomancer_plague_pool")
        ability:SetLevel(1)
        ability:SetHidden(false)
    end 

    if unitName == "npc_dota_hero_dazzle" then
        local ability = caster:FindAbilityByName("dazzle_shadow_step")
        ability:SetLevel(1)
        ability:SetHidden(false)
    end 

    if unitName == "npc_dota_hero_phantom_assassin" then
        local ability = caster:FindAbilityByName("phantom_evasive_strike")
        ability:SetLevel(1)
        ability:SetHidden(false)
    end 

    if unitName == "npc_dota_hero_rubick" then
        local ability = caster:FindAbilityByName("rubick_spell_steal")
        local abilityLevel = ability:GetLevel()
        local abilityRuined = caster:AddAbility("rubick_spell_steal_ruined")

        abilityRuined:SetHidden(false)
        abilityRuined:SetLevel(abilityLevel)

        ability:SetHidden(true)
        ability:SetLevel(0)

        caster:SwapAbilities("rubick_spell_steal", "rubick_spell_steal_ruined", false, true)

        if not caster:HasModifier("modifier_item_ultimate_scepter_consumed") then
            caster:AddNewModifier(caster, abilityRuined, "modifier_item_ultimate_scepter_consumed", {})
        end
    end 

    caster:RemoveItem(self:GetAbility())
end
------------
function modifier_ruined_scepter:DeclareFunctions()
    local funcs = {}

    return funcs
end