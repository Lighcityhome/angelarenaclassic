LinkLuaModifier("modifier_edible_aegis_buff", "items/custom/item_edible_aegis.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsPurgeException = function(self) return false end,
}

item_edible_aegis = class(ItemBaseClass)
modifier_edible_aegis_buff = class(ItemBaseClassBuff)
-------------
function item_edible_aegis:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if not caster:HasModifier("modifier_edible_aegis_buff") then
        caster:AddNewModifier(caster, self, "modifier_edible_aegis_buff", { duration = (300 + RandomInt(-100, 100)) })
    end

    caster:RemoveItem(self)
end
-------------------
function modifier_edible_aegis_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_REINCARNATION,
    }

    return funcs
end

function modifier_edible_aegis_buff:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()

    Timers:CreateTimer(300.0, function ()
        if not caster:HasModifier("modifier_edible_aegis_buff") then return end

        caster:RemoveModifierByName("modifier_edible_aegis_buff")
        caster:AddNewModifier(caster, nil, "modifier_rune_regen", { duration = 30 })
        EmitSoundOnLocationWithCaster(caster:GetOrigin(), "Aegis.Expire", caster)
    end)
end

function modifier_edible_aegis_buff:OnDeath(event)
    if not IsServer() then return end

    local caster = self:GetCaster()

    if event.unit ~= caster then return end

    CreateParticleWithTargetAndDuration("particles/items_fx/aegis_timer.vpcf", caster, 5.0)

    caster:SetTimeUntilRespawn(5.0)
    
    Timers:CreateTimer(5.0, function()
        CreateParticleWithTargetAndDuration("particles/items_fx/aegis_respawn.vpcf", caster, 1.0)
        caster:RemoveModifierByName("modifier_edible_aegis_buff")
    end)
end

function modifier_edible_aegis_buff:ReincarnateTime()
    return 5
end

function modifier_edible_aegis_buff:GetTexture()
    return "item_aegis"
end

function modifier_edible_aegis_buff:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end