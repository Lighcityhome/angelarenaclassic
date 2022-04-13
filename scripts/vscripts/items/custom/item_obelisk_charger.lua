LinkLuaModifier("modifier_obelisk_charger", "items/custom/item_obelisk_charger.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_obelisk_charger_thinker", "items/custom/item_obelisk_charger.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_obelisk_charger_no_healing", "items/custom/item_obelisk_charger.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return true end
}

item_obelisk_charger = class(ItemBaseClass)
modifier_obelisk_charger = class(item_obelisk_charger)
modifier_obelisk_charger_thinker = class(item_obelisk_charger)
modifier_obelisk_charger_no_healing = class(item_obelisk_charger)
-------------
function item_obelisk_charger:GetIntrinsicModifierName()
    return "modifier_obelisk_charger"
end

function item_obelisk_charger:OnSpellStart()
    if not IsServer() then return end

    local target = self:GetCursorTarget()
    if not target or target:IsNull() then return end
    if target:GetUnitName() ~= "npc_dota_obelisk_gateway" then self:GetCaster():Stop() return end

    self.siphonfx = ParticleManager:CreateParticle("particles/units/heroes/hero_death_prophet/death_prophet_spiritsiphon.vpcf", PATTACH_ROOTBONE_FOLLOW, self:GetCaster())
    ParticleManager:SetParticleControl(self.siphonfx, 1, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.siphonfx, 5, Vector(11, 0, 0))
    ParticleManager:SetParticleControl(self.siphonfx, 10, target:GetAbsOrigin())

    target:AddNewModifier(self:GetCaster(), self, "modifier_obelisk_charger_thinker", { duration = 11.0, fx = self.siphonfx })
    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_obelisk_charger_no_healing", { duration = 11.0 })

    EmitSoundOnLocationWithCaster(self:GetCaster():GetOrigin(), "Hero_DeathProphet.SpiritSiphon.Cast", self:GetCaster())
    EmitSoundOnLocationWithCaster(target:GetOrigin(), "Hero_DeathProphet.SpiritSiphon.Target", target)
end

function item_obelisk_charger:OnChannelFinish()
    if not IsServer() then return end

    local target = self:GetCursorTarget()
    if not target or target:IsNull() then return end
    if target:GetUnitName() ~= "npc_dota_obelisk_gateway" then return end

    target:RemoveModifierByNameAndCaster("modifier_obelisk_charger_thinker", self:GetCaster())
    self:GetCaster():RemoveModifierByName("modifier_obelisk_charger_no_healing")

    ParticleManager:DestroyParticle(self.siphonfx, true)
    ParticleManager:ReleaseParticleIndex(self.siphonfx)
    self:GetCaster():StopSound("Hero_DeathProphet.SpiritSiphon.Cast")
    target:StopSound("Hero_DeathProphet.SpiritSiphon.Target")
end

function modifier_obelisk_charger_thinker:OnCreated(params)
    if not IsServer() then return end

    self.fx = params.fx
    self:StartIntervalThink(0.1)
end

function modifier_obelisk_charger_thinker:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_obelisk_charger_thinker:OnIntervalThink()
    local obelisk = self:GetParent()

    obelisk:Heal(0.33, self:GetAbility())

    local damage = {
        victim = self:GetCaster(),
        attacker = self:GetCaster(),
        damage = self:GetCaster():GetMaxHealth() * 0.005,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    }

    ApplyDamage(damage)

    local charges = self:GetAbility():GetCurrentCharges()

    self:GetAbility():SetCurrentCharges(charges - 1)

    if charges <= 1 then
        self:StartIntervalThink(-1)
        ParticleManager:DestroyParticle(self.fx, true)
        ParticleManager:ReleaseParticleIndex(self.fx)
        self:GetCaster():RemoveModifierByName("modifier_obelisk_charger_no_healing")
        self:GetCaster():RemoveItem(self:GetAbility())
        self:GetCaster():StopSound("Hero_DeathProphet.SpiritSiphon.Cast")
        obelisk:StopSound("Hero_DeathProphet.SpiritSiphon.Target")
    end
end
---------
function modifier_obelisk_charger_no_healing:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DISABLE_HEALING, --GetDisableHealing
    }

    return funcs
end

function modifier_obelisk_charger_no_healing:GetDisableHealing()
    return 1
end