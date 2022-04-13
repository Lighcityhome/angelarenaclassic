LinkLuaModifier("modifier_omniscient_greaves", "items/custom/item_omniscient_greaves.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_omniscient_greaves_aura", "items/custom/item_omniscient_greaves.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_omniscient_greaves = class(ItemBaseClass)
item_omniscient_greaves_2 = item_omniscient_greaves
item_omniscient_greaves_3 = item_omniscient_greaves
modifier_omniscient_greaves = class(item_omniscient_greaves)
-------------
function item_omniscient_greaves:GetIntrinsicModifierName()
    return "modifier_omniscient_greaves"
end

function item_omniscient_greaves:OnSpellStart()
  if not IsServer() then return end

    local caster = self:GetCaster()

  -- Disable working on Meepo Clones
  if caster:IsClone() then
    self:RefundManaCost()
    self:EndCooldown()
    return
  end

  local heroes = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster:GetAbsOrigin(),
    nil,
    self:GetSpecialValueFor("replenish_radius"),
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO),
    DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
    FIND_ANY_ORDER,
    false
  )

  -- Apply basic dispel to caster
  caster:Purge(false, true, false, false, false)

  local function HasNoHealCooldown(hero)
    return not hero:HasModifier("modifier_item_mekansm_noheal")
  end

  local function ReplenishMana(hero)
    if not hero:IsAlive() or hero:GetHealth() < 1 then return end
    
    local manaReplenishAmount = self:GetSpecialValueFor("replenish_mana")
    local manaReplenishAmountPct = self:GetSpecialValueFor("replenish_health_pct")
    manaReplenishAmount = manaReplenishAmount + (caster:GetMaxMana() * (manaReplenishAmountPct / 100))
    hero:GiveMana(manaReplenishAmount)

    SendOverheadEventMessage(caster:GetPlayerOwner(), OVERHEAD_ALERT_MANA_ADD, hero, manaReplenishAmount, caster:GetPlayerOwner())

    if hero ~= caster then
      SendOverheadEventMessage(hero:GetPlayerOwner(), OVERHEAD_ALERT_MANA_ADD, hero, manaReplenishAmount, caster:GetPlayerOwner())
    end
  end

  local function ReplenishHealth(hero)
    if not hero:IsAlive() or hero:GetHealth() < 1 then return end

    local healAmount = self:GetSpecialValueFor("replenish_health")
    local healAmountPct = self:GetSpecialValueFor("replenish_health_pct")
    healAmount = healAmount + (caster:GetMaxHealth() * (healAmountPct / 100))
    hero:Heal(healAmount, self)
    hero:AddNewModifier(caster, self, "modifier_item_mekansm_noheal", {duration = self:GetCooldownTime() - 2})

    local particleHealName = "particles/items3_fx/warmage_recipient.vpcf"
    local particleHealNonHeroName = "particles/items3_fx/warmage_recipient_nonhero.vpcf"

    SendOverheadEventMessage(caster:GetPlayerOwner(), OVERHEAD_ALERT_HEAL, hero, healAmount, caster:GetPlayerOwner())

    if hero ~= caster then
      SendOverheadEventMessage(hero:GetPlayerOwner(), OVERHEAD_ALERT_HEAL, hero, healAmount, caster:GetPlayerOwner())
    end

    if hero:IsHero() then
      local particleHeal = ParticleManager:CreateParticle(particleHealName, PATTACH_ABSORIGIN_FOLLOW, hero)
      ParticleManager:ReleaseParticleIndex(particleHeal)
    else
      local particleHealNonHero = ParticleManager:CreateParticle(particleHealNonHeroName, PATTACH_ABSORIGIN_FOLLOW, hero)
      ParticleManager:ReleaseParticleIndex(particleHealNonHero)
    end

    hero:EmitSound("Item.GuardianGreaves.Target")
  end

  for _,hHero in ipairs(heroes) do
    ReplenishMana(hHero)

    if HasNoHealCooldown(hHero) then 
        ReplenishHealth(hHero)
    end
  end

  local particleCastName = "particles/items3_fx/warmage.vpcf"
  local particleCast = ParticleManager:CreateParticle(particleCastName, PATTACH_ABSORIGIN, caster)
  ParticleManager:ReleaseParticleIndex(particleCast)
  caster:EmitSound("Item.GuardianGreaves.Activate")
end
------------
function modifier_omniscient_greaves:OnCreated()
    local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_ms = ability:GetSpecialValueFor("bonus_movement")
    self.bonus_stats = ability:GetSpecialValueFor("bonus_all_stats")
    self.bonus_mana = ability:GetSpecialValueFor("bonus_mana")
    self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
    self.aura_radius = ability:GetSpecialValueFor("aura_radius")
  end
  if IsServer() then
    local parent = self:GetParent()
    -- Remove effect modifiers from units in radius to force refresh
    local units = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetAbsOrigin(),
      nil,
      self.aura_radius,
      DOTA_UNIT_TARGET_TEAM_FRIENDLY,
      bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    local function RemoveGuardianAuraEffect(unit)
      unit:RemoveModifierByName("modifier_item_guardian_greaves_aura")
    end

    for _,un in ipairs(units) do
        RemoveGuardianAuraEffect(un)
    end
  end
end

function modifier_omniscient_greaves:IsAura()
  return true
end

function modifier_omniscient_greaves:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_omniscient_greaves:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_omniscient_greaves:GetAuraRadius()
  return self.aura_radius or self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_omniscient_greaves:GetModifierAura()
  return "modifier_item_guardian_greaves_aura"
end
-----------

modifier_omniscient_greaves_aura = class({})

function modifier_omniscient_greaves_aura:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
  }
end

function modifier_omniscient_greaves_aura:GetModifierConstantHealthRegen()
  local hero = self:GetParent()
  if not hero or not hero.GetHealth then
    return
  end
  local hpPercent = (hero:GetHealth() / hero:GetMaxHealth()) * 100
  if hpPercent < self:GetAbility():GetSpecialValueFor("aura_bonus_threshold") then
    return self:GetAbility():GetSpecialValueFor("aura_health_regen_bonus")
  else
    return self:GetAbility():GetSpecialValueFor("aura_health_regen")
  end
end

function modifier_omniscient_greaves_aura:GetModifierPhysicalArmorBonus()
  local hero = self:GetParent()
  if not hero or not hero.GetHealth then
    return
  end
  local hpPercent = (hero:GetHealth() / hero:GetMaxHealth()) * 100
  if hpPercent < self:GetAbility():GetSpecialValueFor("aura_bonus_threshold") then
    return self:GetAbility():GetSpecialValueFor("aura_armor_bonus")
  else
    return 0
  end
end
------------

function modifier_omniscient_greaves:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,--GetModifierMoveSpeedBonus_Constant
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_MANA_BONUS, -- GetModifierManaBonus
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE, --GetModifierHealAmplify_PercentageSource
    }

    return funcs
end

function modifier_omniscient_greaves:GetModifierHealAmplify_PercentageSource()
    return self:GetAbility():GetLevelSpecialValueFor("heal_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_omniscient_greaves:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_movement", (self:GetAbility():GetLevel() - 1))
end

function modifier_omniscient_greaves:GetModifierHealthBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
end

function modifier_omniscient_greaves:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_omniscient_greaves:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_omniscient_greaves:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_omniscient_greaves:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_omniscient_greaves:GetModifierManaBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana", (self:GetAbility():GetLevel() - 1))
end