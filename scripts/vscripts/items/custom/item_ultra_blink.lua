LinkLuaModifier("modifier_ultra_blink", "items/custom/item_ultra_blink.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ultra_blink_arcane_buff", "items/custom/item_ultra_blink.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ultra_blink_swift_buff", "items/custom/item_ultra_blink.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_ultra_blink = class(ItemBaseClass)
item_ultra_blink_2 = item_ultra_blink
item_ultra_blink_3 = item_ultra_blink
modifier_ultra_blink = class(item_ultra_blink)
modifier_ultra_blink_arcane_buff = class(ItemBaseClassBuff)
modifier_ultra_blink_swift_buff = class(ItemBaseClassBuff)
-------------
function item_ultra_blink:GetIntrinsicModifierName()
    return "modifier_ultra_blink"
end

function item_ultra_blink:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local blinkRangeClamp = self:GetLevelSpecialValueFor("blink_range_clamp", (self:GetLevel() - 1)) 
    local blinkMaxRange = self:GetLevelSpecialValueFor("blink_range", (self:GetLevel() - 1)) 
    local buffDuration = self:GetLevelSpecialValueFor("duration", (self:GetLevel() - 1)) 

    caster:EmitSound("DOTA_Item.BlinkDagger.Activate")
    caster:EmitSound("Blink_Layer.Arcane")
    caster:EmitSound("Blink_Layer.Swift")

    ProjectileManager:ProjectileDodge(caster)  --Disjoints disjointable incoming projectiles.

    local origin_point = caster:GetAbsOrigin()
    local target_point = caster:GetCursorPosition()
    local difference_vector = target_point - origin_point
    
    if difference_vector:Length2D() > blinkMaxRange then  --Clamp the target point to the BlinkRangeClamp range in the same direction.
        target_point = origin_point + (target_point - origin_point):Normalized() * blinkRangeClamp
    end

    ParticleManager:ReleaseParticleIndex(ParticleManager:CreateParticle("particles/items3_fx/blink_overwhelming_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster))
    ParticleManager:ReleaseParticleIndex(ParticleManager:CreateParticle("particles/items3_fx/blink_arcane_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster))
    ParticleManager:ReleaseParticleIndex(ParticleManager:CreateParticle("particles/items3_fx/blink_swift_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster))
    
    caster:SetAbsOrigin(target_point)
    FindClearSpaceForUnit(caster, target_point, false)
    
    ParticleManager:CreateParticle("particles/items_fx/blink_dagger_end.vpcf", PATTACH_ABSORIGIN, caster)

    item_ultra_blink:GiveArcaneBuff(caster, self, buffDuration)
    item_ultra_blink:GiveSwiftBuff(caster, self, buffDuration)
    item_ultra_blink:ActivateOverwhelming(caster, self, buffDuration)
end

function item_ultra_blink:GiveArcaneBuff(caster, ability, duration)
    if ability == nil or not ability then return end

    CreateParticleWithTargetAndDuration("particles/generic_gameplay/rune_arcane_owner_glow.vpcf", caster, duration)

    if not caster:IsAlive() or caster:HasModifier("modifier_item_arcane_blink_buff") then return end

    caster:AddNewModifier(caster, ability, "modifier_ultra_blink_arcane_buff", { duration = duration })
    ParticleManager:ReleaseParticleIndex(ParticleManager:CreateParticle("particles/items3_fx/blink_arcane_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster))
end

function item_ultra_blink:GiveSwiftBuff(caster, ability, duration)
    if ability == nil or not ability then return end

    CreateParticleWithTargetAndDuration("particles/items3_fx/blink_swift_buff_hands.vpcf", caster, duration)
    CreateParticleWithTargetAndDuration("particles/items3_fx/blink_swift_buff.vpcf", caster, duration)

    if not caster:IsAlive() or caster:HasModifier("modifier_item_swift_blink_buff") then return end

    caster:AddNewModifier(caster, ability, "modifier_ultra_blink_swift_buff", { duration = duration })
    caster:AddNewModifier(caster, ability, "modifier_phased", { duration = duration })
    ParticleManager:ReleaseParticleIndex(ParticleManager:CreateParticle("particles/items3_fx/blink_swift_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster))
end

function item_ultra_blink:ActivateOverwhelming(caster, ability, duration)
    if ability == nil or not ability then return end

    CreateParticleWithTargetAndDuration("particles/generic_gameplay/rune_arcane_owner_glow.vpcf", caster, duration)

    if not caster:IsAlive() then return end

    local radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() - 1)) 
    local initialDamage = ability:GetLevelSpecialValueFor("initial_damage", (ability:GetLevel() - 1)) 
    local primaryMultiplier = ability:GetLevelSpecialValueFor("damage_pct", (ability:GetLevel() - 1)) 

    caster:EmitSound("Blink_Layer.Overwhelming")

    local overwhelmingParticle = ParticleManager:CreateParticle("particles/items3_fx/blink_overwhelming_burst.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(overwhelmingParticle, 0, caster:GetOrigin())
    ParticleManager:SetParticleControl(overwhelmingParticle, 1, Vector(radius, radius, radius))

    ParticleManager:ReleaseParticleIndex(ParticleManager:CreateParticle("particles/items3_fx/blink_overwhelming_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster))

    local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_ANY_ORDER, false)

    local totalDamage = initialDamage + caster:GetPrimaryStatValue() * (primaryMultiplier/100)

    for _,unit in ipairs(units) do
        local damage = {
            victim = unit,
            attacker = caster,
            damage = totalDamage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = ability
        }

        ApplyDamage(damage)
    end
end
--todo add all 3 blink effects at once instead of vanilla blink 
--todo effect for overwhelming on use and play sound
------------
function modifier_ultra_blink_arcane_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE, --GetModifierPercentageCooldown
        MODIFIER_PROPERTY_CASTTIME_PERCENTAGE, --GetModifierPercentageCasttime
    }

    return funcs
end

function modifier_ultra_blink_arcane_buff:GetModifierPercentageCooldown()
    local ability = self:GetAbility()
    if ability == nil or not ability then return end

    return ability:GetLevelSpecialValueFor("base_cooldown", (ability:GetLevel() - 1))
end

function modifier_ultra_blink_arcane_buff:GetModifierPercentageCasttime()
    local ability = self:GetAbility()
    if ability == nil or not ability then return end

    return ability:GetLevelSpecialValueFor("cast_pct_improvement", (ability:GetLevel() - 1))
end
------------
function modifier_ultra_blink_swift_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,--GetModifierPreAttack_BonusDamage
    }

    return funcs
end

function modifier_ultra_blink_swift_buff:GetModifierMoveSpeedBonus_Percentage()
    local ability = self:GetAbility()
    if ability == nil or not ability then return end

    return ability:GetLevelSpecialValueFor("bonus_movement", (ability:GetLevel() - 1))
end

function modifier_ultra_blink_swift_buff:GetModifierAttackSpeedBonus_Constant()
    local ability = self:GetAbility()
    if ability == nil or not ability then return end

    return ability:GetLevelSpecialValueFor("bonus_attack_speed", (ability:GetLevel() - 1))
end

function modifier_ultra_blink_swift_buff:GetModifierPreAttack_BonusDamage()
    local ability = self:GetAbility()
    if ability == nil or not ability then return end

    return ability:GetLevelSpecialValueFor("bonus_attack_damage", (ability:GetLevel() - 1))
end
------------
function modifier_ultra_blink:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_EVENT_ON_TAKEDAMAGE 
    }

    return funcs
end

function modifier_ultra_blink:OnTakeDamage(keys)
    if self:GetCaster() ~= keys.unit then return end
    if self:GetCaster() == keys.attacker or keys.attacker:IsCreature() then return end -- Self damage or creatures won't proc the cooldown

    local attacker_name = keys.attacker:GetName()
    local cooldown = self:GetAbility():GetLevelSpecialValueFor("blink_damage_cooldown", (self:GetAbility():GetLevel() - 1)) 

    if keys.damage > 0 and keys.attacker:IsControllableByAnyPlayer() then  --If the damage was dealt by neutrals or lane creeps, essentially.
        if self:GetAbility():GetCooldownTimeRemaining() < cooldown then
            self:GetAbility():StartCooldown(cooldown)
        end
    end
end

function modifier_ultra_blink:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_ultra_blink:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_ultra_blink:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end