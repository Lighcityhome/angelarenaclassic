LinkLuaModifier("modifier_conduit", "items/custom/item_conduit.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_conduit_empowered", "items/custom/item_conduit.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_conduit_pierce", "items/custom/item_conduit.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_conduit_shock", "items/custom/item_conduit.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseBuffClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBaseDebuffClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

item_conduit = class(ItemBaseClass)
item_conduit_2 = item_conduit
item_conduit_3 = item_conduit
modifier_conduit_empowered = class(ItemBaseBuffClass)
modifier_conduit_pierce = class(ItemBaseBuffClass)
modifier_conduit_shock = class(ItemBaseDebuffClass)
modifier_conduit = class(ItemBaseClass)
-------------
function item_conduit:GetIntrinsicModifierName()
    return "modifier_conduit"
end

function item_conduit:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    self.duration = self:GetLevelSpecialValueFor("bonus_empowered_duration", (self:GetLevel() - 1))
    self.empoweredAttackCount = self:GetLevelSpecialValueFor("bonus_empowered_attacks", (self:GetLevel() - 1))

    if caster:IsRangedAttacker() then
        caster:AddNewModifier(caster, self, "modifier_conduit_empowered", { duration = self.duration })
    end

    caster:AddNewModifier(caster, self, "modifier_conduit_pierce", { duration = self.duration })
end
------------
function modifier_conduit_shock:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
    }

    return funcs
end

function modifier_conduit_shock:OnCreated(params)
    if not IsServer() then return end

    self.slow = params.slow
end

function modifier_conduit_shock:GetModifierMoveSpeedBonus_Percentage()
    return -100
end
------------
function modifier_conduit_empowered:OnCreated()
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.empoweredAttackCount = self:GetAbility():GetLevelSpecialValueFor("bonus_empowered_attacks", (self:GetAbility():GetLevel() - 1))
        self.empoweredAttackDamage = self:GetAbility():GetLevelSpecialValueFor("bonus_empowered_attack_damage_pct", (self:GetAbility():GetLevel() - 1))
        self.empoweredBonusRange = self:GetAbility():GetLevelSpecialValueFor("bonus_empowered_range", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_conduit_empowered:DeclareFunctions()
    local funcs = {
        --MODIFIER_EVENT_ON_ATTACK_LANDED, --OnAttack
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS, --GetModifierAttackRangeBonus
        MODIFIER_PROPERTY_PROJECTILE_NAME
    }

    return funcs
end

function modifier_conduit_empowered:GetModifierProjectileName()
    return "particles/items_fx/conduit_projectile.vpcf"
end

function modifier_conduit_empowered:GetPriority()
    return MODIFIER_PRIORITY_SUPER_ULTRA 
end

function modifier_conduit_empowered:GetModifierAttackRangeBonus()
    return self.empoweredBonusRange or self:GetAbility():GetLevelSpecialValueFor("bonus_empowered_range", (self:GetAbility():GetLevel() - 1))
end

--[[
function modifier_conduit_empowered:OnAttackLanded(event)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local victim = event.target
    local ability = self:GetAbility()

    if not ability or ability:IsNull() then return end

    if event.attacker ~= caster then return end
    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then return end
    if not victim:IsBaseNPC() then return end
    if not caster:IsRealHero() or caster:IsIllusion() or victim:IsBuilding() then return end

    -- Apply bonus damage on the projectile as magical damage from damage dealt --
    local damage = {
        victim = victim,
        attacker = caster,
        damage = (event.damage * (self.empoweredAttackDamage / 100)),
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    }

    ApplyDamage(damage)
end
]]--
------------
function modifier_conduit:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,--GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_STATUS_RESISTANCE, --GetModifierStatusResistance
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS, --GetModifierProjectileSpeedBonus
        MODIFIER_EVENT_ON_ATTACK, --OnAttack
        MODIFIER_EVENT_ON_ATTACK_LANDED, --OnAttackLanded
    }

    return funcs
end

function modifier_conduit:OnCreated()
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.damage = self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
        self.strength = self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
        self.bonusAttackSpeed = self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
        self.statusresistance = self:GetAbility():GetLevelSpecialValueFor("bonus_status_resistance", (self:GetAbility():GetLevel() - 1))
        self.healamp = self:GetAbility():GetLevelSpecialValueFor("bonus_health_amp", (self:GetAbility():GetLevel() - 1))

        self.empoweredProjectileSpeed = self:GetAbility():GetLevelSpecialValueFor("bonus_empowered_ranged_projectile_speed", (self:GetAbility():GetLevel() - 1))
        self.empoweredAoe = self:GetAbility():GetLevelSpecialValueFor("bonus_empowered_aoe", (self:GetAbility():GetLevel() - 1))
        self.empoweredAoeDamage = self:GetAbility():GetLevelSpecialValueFor("bonus_empowered_aoe_damage", (self:GetAbility():GetLevel() - 1))

        self.shockamount = self:GetAbility():GetLevelSpecialValueFor("shock_amount", (self:GetAbility():GetLevel() - 1))
        self.shockduration = self:GetAbility():GetLevelSpecialValueFor("shock_duration", (self:GetAbility():GetLevel() - 1))
        self.shockchance = self:GetAbility():GetLevelSpecialValueFor("shock_chance", (self:GetAbility():GetLevel() - 1))
        self.shockdamage = self:GetAbility():GetLevelSpecialValueFor("shock_health_damage_pct", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_conduit:OnAttackLanded(event)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local victim = event.target
    local ability = self:GetAbility()

    if not ability or ability:IsNull() then return end

    if event.attacker ~= caster then return end
    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then return end
    if not victim:IsBaseNPC() then return end
    if not caster:IsRealHero() or caster:IsIllusion() or victim:IsBuilding() or IsBossUBA(victim) or not caster:IsRangedAttacker() then return end

    -- Apply the AOE damage that is a fixed amount --
    local units = FindUnitsInRadius(caster:GetTeam(), victim:GetAbsOrigin(), nil,
        self.empoweredAoe, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,unit in ipairs(units) do
        if not unit:IsMagicImmune() and victim ~= unit then 
            local aoeDamage = {
                victim = unit,
                attacker = caster,
                damage = (event.damage * (self.empoweredAoeDamage / 100)),
                damage_type = DAMAGE_TYPE_PHYSICAL,
                ability = ability
            }

            ApplyDamage(aoeDamage)
        end
    end

    -- Explosion Particle --
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_legion_commander/legion_commander_duel_ring.vpcf", PATTACH_ABSORIGIN_FOLLOW, victim)
    ParticleManager:SetParticleControl(particle, 0, victim:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(particle)
end

function modifier_conduit:OnAttack(event)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local victim = event.target
    local ability = self:GetAbility()

    if not ability or ability:IsNull() then return end

    if event.attacker ~= caster then return end
    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then return end
    if not victim:IsBaseNPC() then return end
    if not caster:IsRealHero() or caster:IsIllusion() or victim:IsBuilding() or IsBossUBA(victim) or victim:IsMagicImmune() then return end

    if RandomFloat(0.0, 1.0) <= (PrdCFinder:GetCForP((self.shockchance / 100)) * 1) then
        -- Apply bonus damage --
        local damage = {
            victim = victim,
            attacker = caster,
            damage = (victim:GetMaxHealth() * (self.shockdamage / 100)),
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = ability
        }

        ApplyDamage(damage)

        -- Explosion Particle --
        local particle = ParticleManager:CreateParticle("particles/econ/items/razor/razor_punctured_crest_golden/razor_storm_lightning_strike_blade_golden.vpcf", PATTACH_ABSORIGIN_FOLLOW, victim)
        ParticleManager:SetParticleControl(particle, 0, victim:GetAbsOrigin())
        ParticleManager:SetParticleControl(particle, 1, victim:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(particle)

        local debuff = victim:FindModifierByNameAndCaster("modifier_conduit_shock", caster)
        
        if not debuff then
            victim:AddNewModifier(caster, ability, "modifier_conduit_shock", { duration = self.shockduration, slow = self.shockamount })
            EmitSoundOnLocationWithCaster(victim:GetAbsOrigin(), "Hero_Razor.UnstableCurrent.Strike", caster)
        else
            debuff:ForceRefresh()
        end
    end
end

function modifier_conduit:GetModifierProjectileSpeedBonus()
    if self:GetCaster():IsRangedAttacker() then
        return self.empoweredProjectileSpeed or self:GetAbility():GetLevelSpecialValueFor("bonus_empowered_ranged_projectile_speed", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_conduit:GetModifierStatusResistance()
    return self.statusresistance or self:GetAbility():GetLevelSpecialValueFor("bonus_status_resistance", (self:GetAbility():GetLevel() - 1))
end

function modifier_conduit:GetModifierHPRegenAmplify_Percentage()
    return self.healamp or self:GetAbility():GetLevelSpecialValueFor("bonus_health_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_conduit:GetModifierPreAttack_BonusDamage()
    return self.damage or self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_conduit:GetModifierBonusStats_Strength()
    return self.strength or self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_conduit:GetModifierAttackSpeedBonus_Constant()
    return self.bonusAttackSpeed or self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end
---------
function modifier_conduit_pierce:CheckState()
    local state = {
        [MODIFIER_STATE_CANNOT_MISS] = true
    }

    return state
end

function modifier_conduit_pierce:IsHidden() return true end