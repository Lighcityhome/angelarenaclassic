LinkLuaModifier("modifier_edible_gem", "items/custom/item_edible_gem.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_edible_gem_sight", "items/custom/item_edible_gem.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_edible_gem_sight_aura", "items/custom/item_edible_gem.lua", LUA_MODIFIER_MOTION_NONE)

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
    IsPurgeException = function(self) return false end,
}

item_edible_gem = class(ItemBaseClass)
modifier_edible_gem = class(item_edible_gem)
modifier_edible_gem_sight = class(ItemBaseBuffClass)
modifier_edible_gem_sight_aura = class(ItemBaseBuffClass)
-------------
function item_edible_gem:GetIntrinsicModifierName()
    return "modifier_edible_gem"
end

function item_edible_gem:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_edible_gem_sight", {})
    caster:RemoveItem(self)
end
------------
function modifier_edible_gem:DeclareFunctions()
    local funcs = {
    }

    return funcs
end
------------
function modifier_edible_gem_sight:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_edible_gem_sight:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.5)
end

function modifier_edible_gem_sight:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end

function modifier_edible_gem_sight:CheckState()
    local states = {
        
    }   

    return states
end

function modifier_edible_gem_sight:OnDeath(event) 
    if not IsServer() then return end

    local caster = self:GetCaster()

    if event.unit ~= caster then return end

    if caster:HasModifier("duel_player_modifier") or WillReincarnateUBA(caster) then return end

    caster:RemoveModifierByName("modifier_edible_gem_sight")

    self:StartIntervalThink(-1)
end

function modifier_edible_gem_sight:OnIntervalThink()
    local wards = FindUnitsInRadius(self:GetParent():GetTeam(), self:GetParent():GetAbsOrigin(), nil,
            1400, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_OTHER), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    print(#wards)

    for _,ward in ipairs(wards) do
        if ward:GetUnitName() then
            if ward:GetUnitName() == "item_ward_observer" or ward:GetUnitName() == "item_ward_sentry" then
                print("found ward")
                ward:AddNewModifier(ward, self:GetAbility(), "modifier_edible_gem_sight_aura", { duration = 0.5 })
            end
        end
    end
end

function modifier_edible_gem_sight:IsAura()
  return true
end

function modifier_edible_gem_sight:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_edible_gem_sight:GetAuraSearchType() return DOTA_UNIT_TARGET_ALL end
function modifier_edible_gem_sight:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_INVULNERABLE end

function modifier_edible_gem_sight:GetAuraRadius()
  return 1400
end

function modifier_edible_gem_sight:GetModifierAura()
    return "modifier_edible_gem_sight_aura"
end

function modifier_edible_gem_sight:GetAuraEntityReject(ent) 
    if ent:HasModifier("modifier_slark_shadow_dance") or ent:HasModifier("modifier_slark_depth_shroud") then
        return true
    end
    
    return false
end

function modifier_edible_gem_sight:GetTexture()
    return "item_gem"
end
-------------
function modifier_edible_gem_sight_aura:CheckState()
    local states = {
        [MODIFIER_STATE_INVISIBLE] = false,
        [MODIFIER_STATE_TRUESIGHT_IMMUNE] = false
    }

    return states
end

function modifier_edible_gem_sight_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
    }
end

function modifier_edible_gem_sight_aura:IsHidden() return true end

function modifier_edible_gem_sight_aura:GetModifierInvisibilityLevel()
    return 0
end

function modifier_edible_gem_sight_aura:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end

function modifier_edible_gem_sight_aura:GetTexture()
    return "item_gem"
end