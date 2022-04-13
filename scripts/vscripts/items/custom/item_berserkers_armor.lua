LinkLuaModifier("modifier_berserkers_armor", "items/custom/item_berserkers_armor.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_berserkers_armor_toggle", "items/custom/item_berserkers_armor.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lifesteal_uba", "modifiers/modifier_lifesteal_uba.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseToggleClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_berserkers_armor = class(ItemBaseClass)
item_berserkers_armor_2 = item_berserkers_armor
item_berserkers_armor_3 = item_berserkers_armor
modifier_berserkers_armor_toggle = class(ItemBaseToggleClass)
modifier_berserkers_armor = class(item_berserkers_armor)
-------------
function item_berserkers_armor:GetIntrinsicModifierName()
    return "modifier_berserkers_armor"
end

function item_berserkers_armor:GetAbilityTextureName()
    if self:GetToggleState() then
        return "custom/berserkersarmor_toggle"
    end

    if self:GetLevel() == 1 then
        return "custom/berserkersarmor"
    elseif self:GetLevel() == 2 then
        return "custom/berserkersarmor_2"
    else
        return "custom/berserkersarmor_3"
    end
end

function item_berserkers_armor:ResetToggleOnRespawn()
    return true
end

function item_berserkers_armor:OnToggle()
    local caster = self:GetCaster()

    if self:GetToggleState() then
        EmitSoundOnLocationForPlayer("DOTA_Item.Armlet.Activate", caster:GetOrigin(), caster:GetPlayerID())
        caster:AddNewModifier(caster, self, "modifier_berserkers_armor_toggle", {})
    else
        EmitSoundOnLocationForPlayer("DOTA_Item.Armlet.DeActivate", caster:GetOrigin(), caster:GetPlayerID())
        caster:RemoveModifierByName("modifier_berserkers_armor_toggle")
    end
end
------------
function modifier_berserkers_armor_toggle:OnCreated()
    if not IsServer() then return end

    self.particleCaster = self:GetCaster()
    self.particleCaster.particle = ParticleManager:CreateParticle("particles/items_fx/armlet.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.particleCaster)
    
    ParticleManager:SetParticleControlEnt(self.particleCaster.particle, 0, self.particleCaster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self.particleCaster:GetAbsOrigin(), true)

    self:StartIntervalThink(0.5)
end

function modifier_berserkers_armor_toggle:OnRemoved()
    if not IsServer() then return end
    ParticleManager:DestroyParticle(self.particleCaster.particle, true)
end

function modifier_berserkers_armor_toggle:OnRespawn()
    if not IsServer() then return end
    ParticleManager:DestroyParticle(self.particleCaster.particle, true)
end

function modifier_berserkers_armor_toggle:GetTexture()
    return "items/berserkersarmor_toggle"
end

function modifier_berserkers_armor_toggle:OnIntervalThink()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if caster:IsIllusion() or not caster:IsHero() then
        return
    end

    local drain = ability:GetLevelSpecialValueFor("toggle_drain", (ability:GetLevel() - 1))
    local currentHealth = caster:GetHealth()
    local updatedHealth = currentHealth - (drain / 2)

    if updatedHealth < 1 or currentHealth < 1 then -- Should maybe fix berserker making you stuck at 0 hp if you kill yourself with it?
        caster:ForceKill(false)
    end

    caster:SetHealth(updatedHealth) -- Because the interval ticks every 0.5s we only drain half
end

function modifier_berserkers_armor_toggle:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,--GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, --GetModifierMoveSpeedBonus_Constant
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
    }

    return funcs
end

function modifier_berserkers_armor_toggle:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("toggle_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_berserkers_armor_toggle:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("toggle_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_berserkers_armor_toggle:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("toggle_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_berserkers_armor_toggle:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("toggle_movement_speed", (self:GetAbility():GetLevel() - 1))
end
------------

function modifier_berserkers_armor:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,--GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        --MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
    }

    return funcs
end

function modifier_berserkers_armor:OnRemoved()
    if not IsServer() then return end

    self:GetCaster():RemoveModifierByNameAndCaster("modifier_lifesteal_uba", self:GetCaster())

    if self:GetAbility():GetToggleState() then
        self:GetAbility():ToggleAbility()
    end
end

function modifier_berserkers_armor:OnCreated()
    if not IsServer() then return end

    local lifesteal = self:GetAbility():GetLevelSpecialValueFor("lifesteal_percent", (self:GetAbility():GetLevel() - 1))

    self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_lifesteal_uba", { amount = lifesteal })
end

function modifier_berserkers_armor:OnRespawn()
    if not IsServer() then return end

    if self:GetAbility():GetToggleState() then
        self:GetAbility():ToggleAbility()
    end
end

function modifier_berserkers_armor:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_berserkers_armor:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_berserkers_armor:GetModifierConstantHealthRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_berserkers_armor:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end

--function modifier_berserkers_armor:GetModifierLifestealRegenAmplify_Percentage()
    --return self:GetAbility():GetLevelSpecialValueFor("lifesteal_percent", (self:GetAbility():GetLevel() - 1))
--end