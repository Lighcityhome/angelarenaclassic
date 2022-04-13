LinkLuaModifier("modifier_linkens_orb", "items/custom/item_linkens_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_linkens_orb_passive", "items/custom/item_linkens_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_linkens_orb_active", "items/custom/item_linkens_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_linkens_orb_passive_cooldown", "items/custom/item_linkens_orb.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseBuffClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseDeBuffClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

item_linkens_orb = class(ItemBaseClass)
item_linkens_orb_2 = item_linkens_orb
item_linkens_orb_3 = item_linkens_orb
modifier_linkens_orb = class(item_linkens_orb)
modifier_linkens_orb_active = class(ItemBaseBuffClass)
modifier_linkens_orb_passive = class(ItemBaseClass)
modifier_linkens_orb_passive_cooldown = class(ItemBaseDeBuffClass)
-------------
function item_linkens_orb:GetIntrinsicModifierName()
    return "modifier_linkens_orb"
end

function item_linkens_orb:OnSpellStart()
    if not IsServer() then return end

    local target = self:GetCursorTarget()

    target:EmitSound("Item.LotusOrb.Target")
    target:AddNewModifier(target, self, "modifier_linkens_orb_active", { duration = self:GetSpecialValueFor("active_duration") })
end
------------
function modifier_linkens_orb:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_MANA_BONUS, -- GetModifierManaBonus
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
    }

    return funcs
end

function modifier_linkens_orb:OnCreated()
    if not IsServer() then return end
    local caster = self:GetCaster()
    local ability = self:GetAbility()


    caster:AddNewModifier(caster, ability, "modifier_linkens_orb_passive", {})
end

function modifier_linkens_orb:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    caster:RemoveModifierByName("modifier_linkens_orb_active")
    caster:RemoveModifierByName("modifier_linkens_orb_passive")
end

function modifier_linkens_orb:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_linkens_orb:GetModifierManaBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana", (self:GetAbility():GetLevel() - 1))
end

function modifier_linkens_orb:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_linkens_orb:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_linkens_orb:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_linkens_orb:GetModifierConstantHealthRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_linkens_orb:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end
---------------
function modifier_linkens_orb_active:IsPurgable() return false end
function modifier_linkens_orb_active:IsPurgeException() return false end

function modifier_linkens_orb_active:DeclareFunctions() return {
    MODIFIER_PROPERTY_ABSORB_SPELL,
    MODIFIER_PROPERTY_REFLECT_SPELL,
} end

function modifier_linkens_orb_active:OnCreated(params)
    if not IsServer() then return end

    self:GetParent().tOldSpells = {}

    self:StartIntervalThink(FrameTime())

    self.reflect_pfx = "particles/items3_fx/lotus_orb_reflect.vpcf"
    self.reflect_sound = ""

    if params.reflect_pfx then self.reflect_pfx = params.reflect_pfx end
end

function modifier_linkens_orb_active:OnIntervalThink()
    for i = #self:GetParent().tOldSpells, 1, -1 do
        local hSpell = self:GetParent().tOldSpells[i]

        if hSpell:NumModifiersUsingAbility() == 0 and not hSpell:IsChanneling() then
            hSpell:RemoveSelf()
            table.remove(self:GetParent().tOldSpells,i)
        end
    end
end

function modifier_linkens_orb_active:GetAbsorbSpell(params)
    if params.ability:GetCaster():GetTeamNumber() == self:GetParent():GetTeamNumber() then
        return nil
    end

    self:GetCaster():EmitSound("DOTA_Item.LinkensSphere.Activate")

    return 1
end

function modifier_linkens_orb_active:GetReflectSpell(params)
    -- If some spells shouldn't be reflected, enter it into this spell-list
    local exception_spell = {
        ["rubick_spell_steal"] = true,
        ["legion_commander_duel"] = true,
        ["phantom_assassin_phantom_strike"] = true,
        ["riki_blink_strike"] = true,
        ["rubick_spellsteal"] = true,
        ["morphling_replicate"] = true
    }

    local reflected_spell_name = params.ability:GetAbilityName()
    local target = params.ability:GetCaster()

    -- Does not reflect allies' projectiles for any reason
    -- if AM (or rubick) has his E up and the caster has lotus active then it reflects an inf amount of times and crashes the game
    if (target:GetTeamNumber() == self:GetParent():GetTeamNumber()) or (target:HasModifier("modifier_antimage_counterspell")) or (self:GetParent():HasModifier("modifier_antimage_counterspell")) then
        return nil
    end

    if (not exception_spell[reflected_spell_name]) then
        -- If this is a reflected ability, do nothing
        if params.ability.spell_shield_reflect then
            return nil
        end

        local pfx = ParticleManager:CreateParticle(self.reflect_pfx, PATTACH_POINT_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControlEnt(pfx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
        ParticleManager:ReleaseParticleIndex(pfx)

        local old_spell = false

        for _,hSpell in pairs(self:GetParent().tOldSpells) do
            if hSpell ~= nil and hSpell:GetAbilityName() == reflected_spell_name then
                old_spell = true
                break
            end
        end

        if old_spell then
            ability = self:GetParent():FindAbilityByName(reflected_spell_name)
        else
            ability = self:GetParent():AddAbility(reflected_spell_name)
            ability:SetStolen(true)
            ability:SetHidden(true)

            -- Tag ability as a reflection ability
            ability.spell_shield_reflect = true

            -- Modifier counter, and add it into the old-spell list
            ability:SetRefCountsModifiers(true)
            table.insert(self:GetParent().tOldSpells, ability)
        end

        ability:SetLevel(params.ability:GetLevel())
        -- Set target & fire spell
        self:GetParent():SetCursorCastTarget(target)

        if ability:GetToggleState() then
            ability:ToggleAbility()
        end

        ability:OnSpellStart()
        
        -- This isn't considered vanilla behavior, but at minimum it should resolve any lingering channeled abilities...
        if ability.OnChannelFinish then
            ability:OnChannelFinish(false)
        end 
    end

    return false
end

function modifier_linkens_orb_active:OnRemoved()
    if not IsServer() then return end

    self:GetParent():EmitSound("Item.LotusOrb.Destroy")
end

function modifier_linkens_orb_active:GetEffectName()
    return "particles/items3_fx/lotus_orb_shell.vpcf"
end
-------------------
function modifier_linkens_orb_passive:DeclareFunctions() return {
    MODIFIER_PROPERTY_ABSORB_SPELL,
} end

function modifier_linkens_orb_passive:OnCreated(params)
    if not IsServer() then return end

    self.reflect_pfx = "particles/items3_fx/lotus_orb_reflect.vpcf"
end

function modifier_linkens_orb_passive:GetAbsorbSpell(params)
    if params.ability:GetCaster():GetTeamNumber() == self:GetParent():GetTeamNumber() then
        return nil
    end

    if self:GetCaster():HasModifier("modifier_linkens_orb_passive_cooldown") then 
        return nil 
    end

    local pfx = ParticleManager:CreateParticle(self.reflect_pfx, PATTACH_POINT_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControlEnt(pfx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(pfx)

    self:GetCaster():EmitSound("DOTA_Item.LinkensSphere.Activate")

    self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_linkens_orb_passive_cooldown", { duration = self:GetAbility():GetSpecialValueFor("block_cooldown") })

    return 1
end