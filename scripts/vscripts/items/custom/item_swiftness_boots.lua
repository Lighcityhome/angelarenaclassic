LinkLuaModifier("modifier_swiftness_boots", "items/custom/item_swiftness_boots.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_movement_speed_uba", "modifiers/modifier_movement_speed_uba.lua", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseStackDebuffClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return true end,
}

item_swiftness_boots = class(ItemBaseClass)
item_swiftness_boots_2 = item_swiftness_boots
item_swiftness_boots_3 = item_swiftness_boots
modifier_swiftness_boots = class(item_swiftness_boots)
-------------
function item_swiftness_boots:GetIntrinsicModifierName()
    return "modifier_swiftness_boots"
end

function item_swiftness_boots:OnSpellStart()
    if not IsServer() then return end

    self.target = self:GetCursorTarget()
    local point = self:GetCursorPosition()
    local caster = self:GetCaster()
    -- Find in AOE first... --
    local units = FindUnitsInRadius(caster:GetTeam(), point, nil,
            99999, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_OTHER, DOTA_UNIT_TARGET_BUILDING), DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
            FIND_CLOSEST, false)

    if #units > 0 then
        for _,unit in ipairs(units) do
            self.target = unit
            break
        end
    end

    -- No target in AOE found... single target enabled? --
    if not self.target or self.target:IsNull() then return end
    if not self.target:IsAlive() or not caster:IsAlive() then return end

    self.loc = self.target:GetAbsOrigin()

    self.particle = ParticleManager:CreateParticle("particles/econ/events/ti6/teleport_start_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    self.particle_destination = ParticleManager:CreateParticle("particles/econ/events/ti6/teleport_end_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.target)
    
    ParticleManager:SetParticleControlEnt(self.particle, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.particle_destination, 0, self.target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self.target:GetAbsOrigin(), true)

    self:UseResources(false, false, true)

    EmitSoundOn("Portal.Loop_Appear", caster)
end

function item_swiftness_boots:OnChannelThink(fInterval)
    if not IsServer() then return end

    self.loc = self.target:GetAbsOrigin()
end

function item_swiftness_boots:OnChannelFinish(interrupted)
    if not IsServer() then return end

    local caster = self:GetCaster()
    if not self.target or self.target:IsNull() then return end

    if not interrupted and self.target:IsAlive() and caster:IsAlive() then
        FindClearSpaceForUnit(caster, self.loc, true)
        EmitSoundOn("Portal.Hero_Disappear", caster)
        EmitSoundOn("Portal.Hero_Appear", self.target)
    end

    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:DestroyParticle(self.particle_destination, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
    ParticleManager:ReleaseParticleIndex(self.particle_destination)

    self.particle_end = ParticleManager:CreateParticle("particles/econ/events/ti6/teleport_end_ti6_ground_flash.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.target)
    ParticleManager:SetParticleControlEnt(self.particle_end, 0, self.target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self.target:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(self.particle_end)

    caster:StopSound("Portal.Loop_Appear")
end
------------
function modifier_swiftness_boots:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
    }

    return funcs
end

function modifier_swiftness_boots:OnCreated()
    if not IsServer() then return end

    if ability and not ability:IsNull() then
        self.intellect = self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
        self.strength = self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
        self.agility = self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
        self.speed_pct = self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed_pct", (self:GetAbility():GetLevel() - 1))
    end

    self:GetParent():AddNewModifier(self:GetParent(), nil, "modifier_movement_speed_uba", { speed = self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1)) })
end

function modifier_swiftness_boots:OnRemoved()
    if not IsServer() then return end

    self:GetParent():RemoveModifierByName("modifier_movement_speed_uba")
end

function modifier_swiftness_boots:GetModifierBonusStats_Intellect()
    return self.intellect or self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_swiftness_boots:GetModifierBonusStats_Strength()
    return self.strength or self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_swiftness_boots:GetModifierBonusStats_Agility()
    return self.agility or self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_swiftness_boots:GetModifierMoveSpeedBonus_Percentage()
    return self.speed_pct or self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed_pct", (self:GetAbility():GetLevel() - 1))
end