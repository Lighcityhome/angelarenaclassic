LinkLuaModifier("modifier_azwraith_armor", "items/custom/item_azwraith_armor.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_azwraith_armor_toggle", "items/custom/item_azwraith_armor.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_azwraith_armor_aura", "items/custom/item_azwraith_armor.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_azwraith_armor_debuff", "items/custom/item_azwraith_armor.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseToggleClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_azwraith_armor = class(ItemBaseClass)
item_azwraith_armor_2 = item_azwraith_armor
item_azwraith_armor_3 = item_azwraith_armor
modifier_azwraith_armor = class(item_azwraith_armor)
modifier_azwraith_armor_aura = class(ItemBaseClassAura)
modifier_azwraith_armor_toggle = class(ItemBaseToggleClass)
modifier_azwraith_armor_debuff = class(ItemBaseClassDebuff)
-------------
function item_azwraith_armor:GetIntrinsicModifierName()
    return "modifier_azwraith_armor"
end

function item_azwraith_armor:GetAOERadius()
    return self:GetSpecialValueFor("aura_radius")
end

function item_azwraith_armor:GetAbilityTextureName()
    if self:GetToggleState() then
        return "custom/azwraith_armor_toggle"
    end

    if self:GetLevel() == 1 then
        return "custom/azwraith_armor"
    elseif self:GetLevel() == 2 then
        return "custom/azwraith_armor_2"
    else
        return "custom/azwraith_armor_3"
    end
end

function item_azwraith_armor:ResetToggleOnRespawn()
    return true
end

function item_azwraith_armor:OnToggle()
    local caster = self:GetCaster()

    if self:GetToggleState() then
        caster:AddNewModifier(caster, self, "modifier_azwraith_armor_toggle", {})
    else
        caster:RemoveModifierByName("modifier_azwraith_armor_toggle")
    end
end
------------
function modifier_azwraith_armor_toggle:OnCreated()
    if self:GetCaster():IsIllusion() then return end
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.bonusMagicDamage = self:GetAbility():GetLevelSpecialValueFor("bonus_magical_attack_damage", (self:GetAbility():GetLevel() - 1))
        self.bonusMagicShredCost = self:GetAbility():GetLevelSpecialValueFor("bonus_magical_resistance_shred_cost_pct", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_azwraith_armor_toggle:DeclareFunctions()
    if self:GetCaster():IsIllusion() then return end

    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED, --OnAttackLanded
        MODIFIER_EVENT_ON_ATTACK,
    }

    return funcs
end

function modifier_azwraith_armor_toggle:OnAttack(event)
    if not IsServer() then return end

    local caster = self:GetCaster()

    if caster ~= event.attacker then return end
    if event.attacker:IsIllusion() then return end

    local ability = self:GetAbility()

    local manaCost = caster:GetMaxMana() * (self.bonusMagicShredCost / 100)
    if manaCost > caster:GetMana() then
        caster:RemoveModifierByName("modifier_azwraith_armor_toggle")
        return
    end

    caster:SpendMana(manaCost, ability)
end

function modifier_azwraith_armor_toggle:OnAttackLanded(event)
    if not IsServer() then return end

    local target = event.target
    local caster = self:GetCaster()

    if caster ~= event.attacker then return end
    if event.attacker:IsIllusion() then return end

    local ability = self:GetAbility()

    local manaCost = caster:GetMaxMana() * (self.bonusMagicShredCost / 100)
    if manaCost > caster:GetMana() then
        caster:RemoveModifierByName("modifier_azwraith_armor_toggle")
        return
    end

    local debuff = target:FindModifierByNameAndCaster("modifier_azwraith_armor_debuff", caster)
    
    if not debuff then
        target:AddNewModifier(caster, ability, "modifier_azwraith_armor_debuff", { duration = ability:GetSpecialValueFor("bonus_magical_resistance_shred_duration" ) })
    else
        debuff:ForceRefresh()
    end

    local bonusDamage = (event.damage * (ability:GetSpecialValueFor("bonus_magical_attack_damage") / 100))

    local damage = {
        victim = target,
        attacker = caster,
        damage = bonusDamage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    }

    ApplyDamage(damage)

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, bonusDamage, nil)
end
-----------
function modifier_azwraith_armor_debuff:OnCreated()
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.bonusMagicShred = self:GetAbility():GetLevelSpecialValueFor("bonus_magical_resistance_shred", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_azwraith_armor_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
    }

    return funcs
end

function modifier_azwraith_armor_debuff:GetModifierMagicalResistanceBonus()
    return self.bonusMagicShred or self:GetAbility():GetLevelSpecialValueFor("bonus_magical_resistance_shred", (self:GetAbility():GetLevel() - 1))
end
------------
function modifier_azwraith_armor:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, --GetModifierHealthRegenPercentage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_MAX_DEBUFF_DURATION, --GetModifierMaxDebuffDuration
    }

    return funcs
end

function modifier_azwraith_armor:OnCreated()
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.bonusAgility = self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
        self.bonusStrength = self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
        self.bonusHealthRegen = self:GetAbility():GetLevelSpecialValueFor("bonus_hp_regen_pct", (self:GetAbility():GetLevel() - 1))
        self.bonusAttackSpeed = self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
        self.bonusMoveSpeed = self:GetAbility():GetLevelSpecialValueFor("bonus_movespeed_pct", (self:GetAbility():GetLevel() - 1))

        self.auraRadius = self:GetAbility():GetLevelSpecialValueFor("aura_radius", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_azwraith_armor:IsAura()
    if self:GetCaster():IsIllusion() then return false end

    return true
end

function modifier_azwraith_armor:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_azwraith_armor:GetAuraSearchTeam()
  return bit.bor(DOTA_UNIT_TARGET_TEAM_FRIENDLY)
end

function modifier_azwraith_armor:GetAuraRadius()
  return self.auraRadius
end

function modifier_azwraith_armor:GetModifierAura()
    return "modifier_azwraith_armor_aura"
end

function modifier_azwraith_armor:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED
end

function modifier_azwraith_armor:GetAuraEntityReject(target)
    if target:GetPlayerOwnerID() == self:GetCaster():GetPlayerOwnerID() and target:IsIllusion() then
        return false
    end

    return true
end

function modifier_azwraith_armor:GetModifierBonusStats_Agility()
    return self.bonusAgility or self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
end

function modifier_azwraith_armor:GetModifierHealthBonus()
    return self.bonusStrength or self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_azwraith_armor:GetModifierHealthRegenPercentage()
    return self.bonusHealthRegen or self:GetAbility():GetLevelSpecialValueFor("bonus_hp_regen_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_azwraith_armor:GetModifierAttackSpeedBonus_Constant()
    return self.bonusAttackSpeed or self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_azwraith_armor:GetModifierMoveSpeedBonus_Percentage()
    return self.bonusMoveSpeed or self:GetAbility():GetLevelSpecialValueFor("bonus_movespeed_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_azwraith_armor:GetModifierMaxDebuffDuration()
    return 500
end
--------------
function modifier_azwraith_armor_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }

    return funcs
end

function modifier_azwraith_armor_aura:OnCreated()
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.reductionStack = self:GetAbility():GetLevelSpecialValueFor("aura_reduction_stack", (self:GetAbility():GetLevel() - 1))
        self.maxReduction = self:GetAbility():GetLevelSpecialValueFor("aura_reduction_max", (self:GetAbility():GetLevel() - 1))
        self.radius = self:GetAbility():GetLevelSpecialValueFor("aura_radius", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_azwraith_armor_aura:GetModifierIncomingDamage_Percentage(event)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local owner = PlayerResource:GetSelectedHeroEntity(caster:GetPlayerOwnerID())
    local damage = event.damage
    local unit = event.target
    local attacker = event.attacker
    local damageType = event.damage_type
    local inflictor = event.inflictor

    if unit:GetPlayerOwnerID() ~= caster:GetPlayerID() then return end
    if not unit:IsIllusion() then return end

    -- Count illusions --
    self.illusionCount = 0

    playerAdditionalUnits = FindUnitsInRadius(caster:GetTeam(),
                                owner:GetAbsOrigin(),
                                nil,
                                FIND_UNITS_EVERYWHERE,
                                DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                                bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
                                DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED,
                                FIND_ANY_ORDER,
                                false)

    playerAdditionalUnits = playerAdditionalUnits or {}

    for _,illusion in ipairs(playerAdditionalUnits) do
        if (illusion:GetPlayerOwnerID() == caster:GetPlayerOwnerID()) and (illusion:IsIllusion()) and (illusion:HasModifier("modifier_azwraith_armor_aura")) then
            self.illusionCount = self.illusionCount + 1
        end
    end
    -- --

    local total = self.illusionCount * self.reductionStack

    if math.abs(total) > math.abs(self.maxReduction) then
        total = self.maxReduction
    end

    local totalDamage = damage * (math.abs(total) / 100)
    
    if damageType == DAMAGE_TYPE_MAGICAL and owner:IsMagicImmune() then
        totalDamage = 0
    end

    local damage = {
        victim = owner,
        attacker = attacker,
        damage = totalDamage,
        damage_type = damageType,
        ability = inflictor
    }

    ApplyDamage(damage)

    self.illusionCount = 0

    return total
end