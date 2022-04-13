LinkLuaModifier("modifier_mage_masher", "items/custom/item_mage_masher.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mage_masher_spell_debuff", "items/custom/item_mage_masher.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mage_masher_unique", "items/custom/item_mage_masher.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mage_masher_force_ally", "items/custom/item_mage_masher.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mage_masher_force_enemy", "items/custom/item_mage_masher.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mage_masher_force_self", "items/custom/item_mage_masher.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mage_masher_attack_speed", "items/custom/item_mage_masher.lua", LUA_MODIFIER_MOTION_NONE)

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

item_mage_masher = class(ItemBaseClass)
item_mage_masher_2 = item_mage_masher
item_mage_masher_3 = item_mage_masher
modifier_mage_masher = class(item_mage_masher)
modifier_mage_masher_spell_debuff = class(ItemBaseDebuffClass)
-------------
function item_mage_masher:GetIntrinsicModifierName()
    return "modifier_mage_masher"
end

function item_mage_masher:OnSpellStart()
    if not IsServer() then return end
    local ability = self
    local target = self:GetCursorTarget()
    local duration = 0.4

    if not ability or ability:IsNull() then return end

    if self:GetCaster():GetTeamNumber() == target:GetTeamNumber() then
        EmitSoundOn("DOTA_Item.ForceStaff.Activate", target)
        target:AddNewModifier(self:GetCaster(), ability, "modifier_mage_masher_force_ally", {duration = duration })
    else
        -- If the target possesses a ready Linken's Sphere, do nothing
        if target:TriggerSpellAbsorb(ability) then return end
    
        target:AddNewModifier(self:GetCaster(), ability, "modifier_mage_masher_force_enemy", {duration = duration})
        self:GetCaster():AddNewModifier(target, ability, "modifier_mage_masher_force_self", {duration = duration})
        local buff = self:GetCaster():AddNewModifier(self:GetCaster(), ability, "modifier_mage_masher_attack_speed", {duration = ability:GetSpecialValueFor("range_duration")})
        buff.target = target
        buff:SetStackCount(ability:GetSpecialValueFor("max_attacks"))
        EmitSoundOn("DOTA_Item.ForceStaff.Activate", target)
        EmitSoundOn("DOTA_Item.ForceStaff.Activate", self:GetCaster())
        
        if self:GetCaster():IsRangedAttacker() then
            local startAttack = {
                UnitIndex = self:GetCaster():entindex(),
                OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
                TargetIndex = target:entindex(),}
            ExecuteOrderFromTable(startAttack)
        end
    end
end

function modifier_mage_masher:GetAttributes()  return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_mage_masher:OnCreated()
    if IsServer() then
        if not self:GetAbility() then self:Destroy() end
    end

    if IsServer() then
        local parent = self:GetParent()
        if not parent:HasModifier("modifier_mage_masher_unique") then
            parent:AddNewModifier(parent, self:GetAbility(), "modifier_mage_masher_unique", {})
        end
    end
end

function modifier_mage_masher:OnDestroy()
    if IsServer() then
        local parent = self:GetParent()
        if not parent:HasModifier("modifier_mage_masher") then
            parent:RemoveModifierByName("modifier_mage_masher_unique")
        end
    end
end
------------

function modifier_mage_masher:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,--GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS, --GetModifierAttackRangeBonus
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_mage_masher:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.health = self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
        self.damage = self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
        self.agility = self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
        self.strength = self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
        self.intellect = self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
        self.magicArmor = self:GetAbility():GetLevelSpecialValueFor("bonus_magical_armor", (self:GetAbility():GetLevel() - 1))
        self.range = self:GetAbility():GetLevelSpecialValueFor("base_attack_range", (self:GetAbility():GetLevel() - 1))
        self.spellAmpDebuff = self:GetAbility():GetLevelSpecialValueFor("spell_amp_debuff", (self:GetAbility():GetLevel() - 1))
        self.spellAmpDebuffDuration = self:GetAbility():GetLevelSpecialValueFor("spell_amp_debuff_duration", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_mage_masher:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target

    if self:GetCaster() ~= attacker or not victim:IsHero() or victim:IsIllusion() or not UnitIsNotMonkeyClone(attacker) then return end

    local debuff = victim:FindModifierByNameAndCaster("modifier_mage_masher_spell_debuff", attacker)

    if not debuff then
        victim:AddNewModifier(attacker, ability, "modifier_mage_masher_spell_debuff", { duration = self.spellAmpDebuffDuration, amount = self.spellAmpDebuff })
    else
        debuff:ForceRefresh()
    end
end

function modifier_mage_masher:GetModifierHealthBonus()
    return self.health or self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
end

function modifier_mage_masher:GetModifierPreAttack_BonusDamage()
    return self.damage or self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_mage_masher:GetModifierBonusStats_Agility()
    return self.agility or self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
end

function modifier_mage_masher:GetModifierBonusStats_Strength()
    return self.strength or self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_mage_masher:GetModifierBonusStats_Intellect()
    return self.intellect or self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
end

function modifier_mage_masher:GetModifierMagicalResistanceBonus()
    return self.magicArmor or self:GetAbility():GetLevelSpecialValueFor("bonus_magical_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_mage_masher:GetModifierAttackRangeBonus()
    if not self:GetCaster():IsRangedAttacker() then return end
    
    return self.range or self:GetAbility():GetLevelSpecialValueFor("base_attack_range", (self:GetAbility():GetLevel() - 1))
end
-----------
function modifier_mage_masher_spell_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
    }
    return funcs
end

function modifier_mage_masher_spell_debuff:OnCreated(params)
    self.amount = params.amount
end

function modifier_mage_masher_spell_debuff:GetModifierSpellAmplify_Percentage()
    return self.amount
end
------------
modifier_mage_masher_unique = modifier_mage_masher_unique or class({})

function modifier_mage_masher_unique:IsHidden() return true end
function modifier_mage_masher_unique:IsPurgable() return false end
function modifier_mage_masher_unique:IsDebuff() return false end
function modifier_mage_masher_unique:RemoveOnDeath() return false end

function modifier_mage_masher_unique:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS
    }
end

function modifier_mage_masher_unique:OnCreated()
    self.bonus_attack_range = self:GetAbility():GetSpecialValueFor("base_attack_range")
end

function modifier_mage_masher_unique:GetModifierAttackRangeBonus()
    if self:GetParent():IsRangedAttacker() then
        return self.bonus_attack_range
    end
end

modifier_mage_masher_force_ally = modifier_mage_masher_force_ally or class({})

function modifier_mage_masher_force_ally:IsDebuff() return false end
function modifier_mage_masher_force_ally:IsHidden() return true end
function modifier_mage_masher_force_ally:IsPurgable() return false end
function modifier_mage_masher_force_ally:IsStunDebuff() return false end
function modifier_mage_masher_force_ally:IsMotionController()  return true end
function modifier_mage_masher_force_ally:GetMotionControllerPriority()  return DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM end

function modifier_mage_masher_force_ally:OnCreated()
    if IsServer() then
        if not self:GetAbility() then self:Destroy() end
    end

    if not IsServer() then return end

    if self:GetParent():HasModifier("modifier_legion_commander_duel") or self:GetParent():HasModifier("modifier_enigma_black_hole_thinker") or self:GetParent():HasModifier("modifier_faceless_void_chronosphere_freeze") or self:GetParent():HasModifier("modifier_enigma_black_hole_thinker_scepter") then
        self:Destroy()
        return
    end
    
    self.pfx = ParticleManager:CreateParticle("particles/items_fx/force_staff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    self:GetParent():StartGesture(ACT_DOTA_FLAIL)
    self:StartIntervalThink(FrameTime())
    self.angle = self:GetParent():GetForwardVector():Normalized()
    self.distance = self:GetAbility():GetSpecialValueFor("push_length") / ( self:GetDuration() / FrameTime())
end

function modifier_mage_masher_force_ally:OnDestroy()
    if not IsServer() then return end
    ParticleManager:DestroyParticle(self.pfx, false)
    ParticleManager:ReleaseParticleIndex(self.pfx)
    self:GetParent():FadeGesture(ACT_DOTA_FLAIL)
    ResolveNPCPositions(self:GetParent():GetAbsOrigin(), 128)
end

function modifier_mage_masher_force_ally:CheckMotionControllers()
    local parent = self:GetParent()
    local modifier_priority = self:GetMotionControllerPriority()
    local is_motion_controller = false
    local motion_controller_priority
    local found_modifier_handler

    local non_motion_controllers =
    {"modifier_brewmaster_storm_cyclone",
     "modifier_dark_seer_vacuum",
     "modifier_eul_cyclone",
     "modifier_earth_spirit_rolling_boulder_caster",
     "modifier_huskar_life_break_charge",
     "modifier_invoker_tornado",
     "modifier_item_forcestaff_active",
     "modifier_rattletrap_hookshot",
     "modifier_phoenix_icarus_dive",
     "modifier_shredder_timber_chain",
     "modifier_slark_pounce",
     "modifier_spirit_breaker_charge_of_darkness",
     "modifier_tusk_walrus_punch_air_time",
     "modifier_earthshaker_enchant_totem_leap"}
    

    -- Fetch all modifiers
    local modifiers = parent:FindAllModifiers() 

    for _,modifier in pairs(modifiers) do       
        -- Ignore the modifier that is using this function
        if self ~= modifier then            

            -- Check if this modifier is assigned as a motion controller
            if modifier.IsMotionController then
                if modifier:IsMotionController() then
                    -- Get its handle
                    found_modifier_handler = modifier

                    is_motion_controller = true

                    -- Get the motion controller priority
                    motion_controller_priority = modifier:GetMotionControllerPriority()

                    -- Stop iteration                   
                    break
                end
            end

            -- If not, check on the list
            for _,non_imba_motion_controller in pairs(non_motion_controllers) do                
                if modifier:GetName() == non_imba_motion_controller then
                    -- Get its handle
                    found_modifier_handler = modifier

                    is_motion_controller = true

                    -- We assume that vanilla controllers are the highest priority
                    motion_controller_priority = DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST

                    -- Stop iteration                   
                    break
                end
            end
        end
    end

    -- If this is a motion controller, check its priority level
    if is_motion_controller and motion_controller_priority then

        -- If the priority of the modifier that was found is higher, override
        if motion_controller_priority > modifier_priority then          
            return false

        -- If they have the same priority levels, check which of them is older and remove it
        elseif motion_controller_priority == modifier_priority then         
            if found_modifier_handler:GetCreationTime() >= self:GetCreationTime() then              
                return false
            else                
                found_modifier_handler:Destroy()
                return true
            end

        -- If the modifier that was found is a lower priority, destroy it instead
        else            
            parent:InterruptMotionControllers(true)
            found_modifier_handler:Destroy()
            return true
        end
    else
        -- If no motion controllers were found, apply
        return true
    end
end

function modifier_mage_masher_force_ally:OnIntervalThink()
    -- Remove force if conflicting
    if not self:CheckMotionControllers() then
        self:Destroy()
        return
    end
    self:HorizontalMotion(self:GetParent(), FrameTime())
end

function modifier_mage_masher_force_ally:HorizontalMotion(unit, time)
    if not IsServer() then return end
    
    -- Mars' Arena of Blood exception
    if self:GetParent():HasModifier("modifier_mars_arena_of_blood_leash") and self:GetParent():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAuraOwner() and (self:GetParent():GetAbsOrigin() - self:GetParent():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAuraOwner():GetAbsOrigin()):Length2D() >= self:GetParent():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAbility():GetSpecialValueFor("radius") - self:GetParent():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAbility():GetSpecialValueFor("width") then
        self:Destroy()
        return
    end
    
    local pos = unit:GetAbsOrigin()
    GridNav:DestroyTreesAroundPoint(pos, 80, false)
    local pos_p = self.angle * self.distance
    local next_pos = GetGroundPosition(pos + pos_p,unit)
    unit:SetAbsOrigin(next_pos)
end

modifier_mage_masher_force_enemy = modifier_mage_masher_force_enemy or class({})
modifier_mage_masher_force_self = modifier_mage_masher_force_self or class({})

function modifier_mage_masher_force_enemy:IsDebuff() return true end
function modifier_mage_masher_force_enemy:IsHidden() return true end
-- function modifier_mage_masher_force_enemy:IsPurgable() return false end
function modifier_mage_masher_force_enemy:IsStunDebuff() return false end
function modifier_mage_masher_force_enemy:IsMotionController()  return true end
function modifier_mage_masher_force_enemy:GetMotionControllerPriority()  return DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM end
function modifier_mage_masher_force_enemy:IgnoreTenacity() return true end

function modifier_mage_masher_force_enemy:OnCreated()
    if IsServer() then
        if not self:GetAbility() then self:Destroy() end
    end

    if not IsServer() then return end

    self.pfx = ParticleManager:CreateParticle("particles/items_fx/force_staff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    self:GetParent():StartGesture(ACT_DOTA_FLAIL)
    self:StartIntervalThink(FrameTime())
    self.angle = (self:GetParent():GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Normalized()
    self.distance = self:GetAbility():GetSpecialValueFor("enemy_length") / ( self:GetDuration() / FrameTime())
end

function modifier_mage_masher_force_enemy:OnDestroy()
    if not IsServer() then return end
    ParticleManager:DestroyParticle(self.pfx, false)
    ParticleManager:ReleaseParticleIndex(self.pfx)
    self:GetParent():FadeGesture(ACT_DOTA_FLAIL)
    ResolveNPCPositions(self:GetParent():GetAbsOrigin(), 128)
end

function modifier_mage_masher_force_enemy:CheckMotionControllers()
    local parent = self:GetParent()
    local modifier_priority = self:GetMotionControllerPriority()
    local is_motion_controller = false
    local motion_controller_priority
    local found_modifier_handler

    local non_motion_controllers =
    {"modifier_brewmaster_storm_cyclone",
     "modifier_dark_seer_vacuum",
     "modifier_eul_cyclone",
     "modifier_earth_spirit_rolling_boulder_caster",
     "modifier_huskar_life_break_charge",
     "modifier_invoker_tornado",
     "modifier_item_forcestaff_active",
     "modifier_rattletrap_hookshot",
     "modifier_phoenix_icarus_dive",
     "modifier_shredder_timber_chain",
     "modifier_slark_pounce",
     "modifier_spirit_breaker_charge_of_darkness",
     "modifier_tusk_walrus_punch_air_time",
     "modifier_earthshaker_enchant_totem_leap"}
    

    -- Fetch all modifiers
    local modifiers = parent:FindAllModifiers() 

    for _,modifier in pairs(modifiers) do       
        -- Ignore the modifier that is using this function
        if self ~= modifier then            

            -- Check if this modifier is assigned as a motion controller
            if modifier.IsMotionController then
                if modifier:IsMotionController() then
                    -- Get its handle
                    found_modifier_handler = modifier

                    is_motion_controller = true

                    -- Get the motion controller priority
                    motion_controller_priority = modifier:GetMotionControllerPriority()

                    -- Stop iteration                   
                    break
                end
            end

            -- If not, check on the list
            for _,non_imba_motion_controller in pairs(non_motion_controllers) do                
                if modifier:GetName() == non_imba_motion_controller then
                    -- Get its handle
                    found_modifier_handler = modifier

                    is_motion_controller = true

                    -- We assume that vanilla controllers are the highest priority
                    motion_controller_priority = DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST

                    -- Stop iteration                   
                    break
                end
            end
        end
    end

    -- If this is a motion controller, check its priority level
    if is_motion_controller and motion_controller_priority then

        -- If the priority of the modifier that was found is higher, override
        if motion_controller_priority > modifier_priority then          
            return false

        -- If they have the same priority levels, check which of them is older and remove it
        elseif motion_controller_priority == modifier_priority then         
            if found_modifier_handler:GetCreationTime() >= self:GetCreationTime() then              
                return false
            else                
                found_modifier_handler:Destroy()
                return true
            end

        -- If the modifier that was found is a lower priority, destroy it instead
        else            
            parent:InterruptMotionControllers(true)
            found_modifier_handler:Destroy()
            return true
        end
    else
        -- If no motion controllers were found, apply
        return true
    end
end

function modifier_mage_masher_force_enemy:OnIntervalThink()
    -- Remove force if conflicting
    if not self:CheckMotionControllers() then
        self:Destroy()
        return
    end
    self:HorizontalMotion(self:GetParent(), FrameTime())
end

function modifier_mage_masher_force_enemy:HorizontalMotion(unit, time)
    if not IsServer() then return end
    
    -- Mars' Arena of Blood exception
    if self:GetParent():HasModifier("modifier_mars_arena_of_blood_leash") and self:GetParent():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAuraOwner() and (self:GetParent():GetAbsOrigin() - self:GetParent():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAuraOwner():GetAbsOrigin()):Length2D() >= self:GetParent():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAbility():GetSpecialValueFor("radius") - self:GetParent():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAbility():GetSpecialValueFor("width") then
        self:Destroy()
        return
    end
    
    local pos = unit:GetAbsOrigin()
    GridNav:DestroyTreesAroundPoint(pos, 80, false)
    local pos_p = self.angle * self.distance
    local next_pos = GetGroundPosition(pos + pos_p,unit)
    unit:SetAbsOrigin(next_pos)
end

function modifier_mage_masher_force_self:IsDebuff() return false end
function modifier_mage_masher_force_self:IsHidden() return true end
-- function modifier_mage_masher_force_self:IsPurgable() return false end
function modifier_mage_masher_force_self:IsStunDebuff() return false end
function modifier_mage_masher_force_self:IgnoreTenacity() return true end
function modifier_mage_masher_force_self:IsMotionController()  return true end
function modifier_mage_masher_force_self:GetMotionControllerPriority()  return DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM end

function modifier_mage_masher_force_self:OnCreated()
    if IsServer() then
        if not self:GetAbility() then self:Destroy() end
    end

    if not IsServer() then return end

    self.pfx = ParticleManager:CreateParticle("particles/items_fx/force_staff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    self:GetParent():StartGesture(ACT_DOTA_FLAIL)
    self:StartIntervalThink(FrameTime())
    self.angle = (self:GetParent():GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Normalized()
    self.distance = self:GetAbility():GetSpecialValueFor("enemy_length") / ( self:GetDuration() / FrameTime())
end

function modifier_mage_masher_force_self:OnDestroy()
    if not IsServer() then return end
    ParticleManager:DestroyParticle(self.pfx, false)
    ParticleManager:ReleaseParticleIndex(self.pfx)
    self:GetParent():FadeGesture(ACT_DOTA_FLAIL)
    ResolveNPCPositions(self:GetParent():GetAbsOrigin(), 128)
end

function modifier_mage_masher_force_self:CheckMotionControllers()
    local parent = self:GetParent()
    local modifier_priority = self:GetMotionControllerPriority()
    local is_motion_controller = false
    local motion_controller_priority
    local found_modifier_handler

    local non_motion_controllers =
    {"modifier_brewmaster_storm_cyclone",
     "modifier_dark_seer_vacuum",
     "modifier_eul_cyclone",
     "modifier_earth_spirit_rolling_boulder_caster",
     "modifier_huskar_life_break_charge",
     "modifier_invoker_tornado",
     "modifier_item_forcestaff_active",
     "modifier_rattletrap_hookshot",
     "modifier_phoenix_icarus_dive",
     "modifier_shredder_timber_chain",
     "modifier_slark_pounce",
     "modifier_spirit_breaker_charge_of_darkness",
     "modifier_tusk_walrus_punch_air_time",
     "modifier_earthshaker_enchant_totem_leap"}
    

    -- Fetch all modifiers
    local modifiers = parent:FindAllModifiers() 

    for _,modifier in pairs(modifiers) do       
        -- Ignore the modifier that is using this function
        if self ~= modifier then            

            -- Check if this modifier is assigned as a motion controller
            if modifier.IsMotionController then
                if modifier:IsMotionController() then
                    -- Get its handle
                    found_modifier_handler = modifier

                    is_motion_controller = true

                    -- Get the motion controller priority
                    motion_controller_priority = modifier:GetMotionControllerPriority()

                    -- Stop iteration                   
                    break
                end
            end

            -- If not, check on the list
            for _,non_imba_motion_controller in pairs(non_motion_controllers) do                
                if modifier:GetName() == non_imba_motion_controller then
                    -- Get its handle
                    found_modifier_handler = modifier

                    is_motion_controller = true

                    -- We assume that vanilla controllers are the highest priority
                    motion_controller_priority = DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST

                    -- Stop iteration                   
                    break
                end
            end
        end
    end

    -- If this is a motion controller, check its priority level
    if is_motion_controller and motion_controller_priority then

        -- If the priority of the modifier that was found is higher, override
        if motion_controller_priority > modifier_priority then          
            return false

        -- If they have the same priority levels, check which of them is older and remove it
        elseif motion_controller_priority == modifier_priority then         
            if found_modifier_handler:GetCreationTime() >= self:GetCreationTime() then              
                return false
            else                
                found_modifier_handler:Destroy()
                return true
            end

        -- If the modifier that was found is a lower priority, destroy it instead
        else            
            parent:InterruptMotionControllers(true)
            found_modifier_handler:Destroy()
            return true
        end
    else
        -- If no motion controllers were found, apply
        return true
    end
end

function modifier_mage_masher_force_self:OnIntervalThink()
    -- Remove force if conflicting
    if not self:CheckMotionControllers() then
        self:Destroy()
        return
    end
    self:HorizontalMotion(self:GetParent(), FrameTime())
end

function modifier_mage_masher_force_self:HorizontalMotion(unit, time)
    if not IsServer() then return end
    
    -- Mars' Arena of Blood exception
    if self:GetParent():HasModifier("modifier_mars_arena_of_blood_leash") and self:GetParent():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAuraOwner() and (self:GetParent():GetAbsOrigin() - self:GetParent():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAuraOwner():GetAbsOrigin()):Length2D() >= self:GetParent():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAbility():GetSpecialValueFor("radius") - self:GetParent():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAbility():GetSpecialValueFor("width") then
        self:Destroy()
        return
    end
    
    local pos = unit:GetAbsOrigin()
    GridNav:DestroyTreesAroundPoint(pos, 80, false)
    local pos_p = self.angle * self.distance
    local next_pos = GetGroundPosition(pos + pos_p,unit)
    unit:SetAbsOrigin(next_pos)
end

modifier_mage_masher_attack_speed = modifier_mage_masher_attack_speed or class({})

function modifier_mage_masher_attack_speed:IsDebuff() return false end
function modifier_mage_masher_attack_speed:IsHidden() return false end
function modifier_mage_masher_attack_speed:IsPurgable() return true end
function modifier_mage_masher_attack_speed:IsStunDebuff() return false end
function modifier_mage_masher_attack_speed:IgnoreTenacity() return true end

function modifier_mage_masher_attack_speed:OnCreated()
    if IsServer() then
        if not self:GetAbility() then self:Destroy() end
    end
    
    if not IsServer() then return end
    self.as = 0
    self.ar = 0
    self:StartIntervalThink(FrameTime())
end

function modifier_mage_masher_attack_speed:OnIntervalThink()
    if not IsServer() then return end
    if self:GetParent():GetAttackTarget() == self.target then
        self.as = self:GetAbility():GetSpecialValueFor("bonus_attack_speed_active")
        if self:GetParent():IsRangedAttacker() then
            self.ar = 999999
        end
    else
        self.as = 0
        self.ar = 0
    end
end

function modifier_mage_masher_attack_speed:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ORDER,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS
    }
end

function modifier_mage_masher_attack_speed:GetModifierAttackSpeedBonus_Constant()
    if not IsServer() then return end
    return self.as
end

function modifier_mage_masher_attack_speed:GetModifierAttackRangeBonus()
    if not IsServer() then return end
    return self.ar
end

function modifier_mage_masher_attack_speed:OnAttack( keys )
    if not IsServer() then return end
    if keys.target == self.target and keys.attacker == self:GetParent() then
        if self:GetStackCount() > 1 then
            self:DecrementStackCount()
        else
            self:Destroy()
        end
    end
end

function modifier_mage_masher_attack_speed:OnOrder( keys )
    if not IsServer() then return end
    
    if keys.target == self.target and keys.unit == self:GetParent() and keys.order_type == 4 then
        if self:GetParent():IsRangedAttacker() then
            self.ar = 999999
        end
        
        self.as = self:GetAbility():GetSpecialValueFor("bonus_attack_speed_active")
    end
end