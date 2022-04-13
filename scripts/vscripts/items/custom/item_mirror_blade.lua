LinkLuaModifier("modifier_mirror_blade", "items/custom/item_mirror_blade.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mirror_blade_doubleattack", "items/custom/item_mirror_blade.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mirror_blade_doubleattack_debuff", "items/custom/item_mirror_blade.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mirror_blade_illusion_modifier", "items/custom/item_mirror_blade.lua", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

item_mirror_blade = class(ItemBaseClass)
modifier_mirror_blade_illusion_modifier = class(ItemBaseClass)
item_mirror_blade_2 = item_mirror_blade
item_mirror_blade_3 = item_mirror_blade
modifier_mirror_blade_doubleattack = class(item_mirror_blade)
modifier_mirror_blade_doubleattack_debuff = class(ItemBaseDebuffClass)
modifier_mirror_blade = class(item_mirror_blade)
-------------
function item_mirror_blade:GetIntrinsicModifierName()
    return "modifier_mirror_blade"
end
------------
function modifier_mirror_blade_doubleattack:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,--GetModifierAttackSpeedBonus_Constant
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_mirror_blade_doubleattack:OnAttackLanded(event)
    if not IsServer() then return end
    local attacker = event.attacker

    if attacker:HasModifier("modifier_nyx_assassin_vendetta") then
        attacker:RemoveModifierByName("modifier_nyx_assassin_vendetta")
    end
end

function modifier_mirror_blade_doubleattack:GetModifierAttackSpeedBonus_Constant()
    return 410
end
------------
function modifier_mirror_blade_doubleattack_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,--GetModifierMoveSpeedBonus_Percentage
    }

    return funcs
end

function modifier_mirror_blade_doubleattack_debuff:GetModifierMoveSpeedBonus_Percentage()
    return -100
end
------------
function modifier_mirror_blade:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,--GetModifierMoveSpeedBonus_Constant
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,--GetModifierAttackSpeedBonus_Constant
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_mirror_blade:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    self.illusionOutgoing = ability:GetLevelSpecialValueFor("illusion_damage_pct", (ability:GetLevel() - 1))
    self.illusionIncoming = ability:GetLevelSpecialValueFor("illusion_damage_taken_pct", (ability:GetLevel() - 1))
    self.illusionDuration = ability:GetLevelSpecialValueFor("illusion_duration", (ability:GetLevel() - 1))
    self.cooldown = ability:GetLevelSpecialValueFor("tooltip_cooldown", (ability:GetLevel() - 1))
    self.slowDuration = ability:GetLevelSpecialValueFor("slow_duration", (ability:GetLevel() - 1))

    self.hits = 0
end

function modifier_mirror_blade:OnAttackLanded(event)
    if not IsServer() then return end
    local attacker = event.attacker
    local victim = event.target
    
    if self:GetCaster() ~= attacker then return end
    if event.inflictor ~= nil then return end

    -- Echo proc works only on melee
    if not attacker:IsRangedAttacker() and UnitIsNotMonkeyClone(attacker) and attacker:IsRealHero() then
        self.hits = self.hits + 1
        if self.hits >= 3 then
            attacker:RemoveModifierByName("modifier_mirror_blade_doubleattack")
            self.hits = 0
        end

        -- We allow the hit count to work when cd is up but it won't ever apply the modifier
        if not self:GetAbility():IsCooldownReady() then return end
        attacker:AddNewModifier(attacker, self:GetAbility(), "modifier_mirror_blade_doubleattack", {})
        victim:AddNewModifier(victim, self:GetAbility(), "modifier_mirror_blade_doubleattack_debuff", { duration = self.slowDuration })

        Timers:CreateTimer(self.cooldown, function()
            -- Remove the modifier when the cooldown becomes ready again
            attacker:RemoveModifierByName("modifier_mirror_blade_doubleattack")
            self.hits = 0
        end)
    end

    if not self:GetAbility():IsCooldownReady() then return end

    self:GetAbility():StartCooldown(self.cooldown)

    -- Should not make illusions of non-heroes, bosses, other illusions etc.
    if not attacker:IsHero() or attacker:IsIllusion() or not victim:IsHero() or victim:IsIllusion() or not UnitIsNotMonkeyClone(attacker) or attacker:IsMuted() then return end

    local owner = nil
    if attacker:GetTeamNumber() == DOTA_TEAM_BADGUYS then
        owner = Entities:FindByName(nil, "ent_dota_fountain_bad")
    elseif attacker:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
        owner = Entities:FindByName(nil, "ent_dota_fountain_good")
    end

    if not owner then return end

    local modifierKeys = {
        outgoing_damage = self.illusionOutgoing,
        incoming_damage = self.illusionIncoming,
        bounty_base = 0.0,
        outgoing_damage_structure = self.illusionOutgoing,
        outgoing_damage_roshan = self.illusionOutgoing
    }

    local illusions = CreateIllusions(EntIndexToHScript(attacker:entindex()), victim, modifierKeys, 1, 0, false, true)
    for _,illusion in ipairs(illusions) do
        illusion:SetForceAttackTarget(victim)
        illusion:AddNewModifier(illusion, nil, "modifier_mirror_blade_illusion_modifier", {})
        illusion:AddNewModifier(illusion, nil, "modifier_movement_speed_uba", { speed = 750 })
        
        Timers:CreateTimer(self.illusionDuration, function()
            if not illusion:IsAlive() then return end

            illusion:RemoveModifierByName("modifier_mirror_blade_illusion_modifier")
            illusion:ForceKill(false)
        end)
    end
end

function modifier_mirror_blade:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_mirror_blade:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
end

function modifier_mirror_blade:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_magical_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_mirror_blade:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_mirror_blade:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_mirror_blade:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_mirror_blade:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end
----------
function modifier_mirror_blade_illusion_modifier:DeclareFunctions()
    local funcs = {}
    return funcs
end

function modifier_mirror_blade_illusion_modifier:CheckState()
    local state = {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true
    }

    return state
end

function modifier_mirror_blade_illusion_modifier:GetEffectName()
    return "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf"
end

function modifier_mirror_blade_illusion_modifier:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_mirror_blade_illusion_modifier:GetStatusEffectName()
    return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_mirror_blade_illusion_modifier:StatusEffectPriority()
    return 10001
end