LinkLuaModifier("modifier_mango_of_agility", "items/custom/item_mango_of_agility.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mango_of_agility_buff", "items/custom/item_mango_of_agility.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return true end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
    IsPermanent = function(self) return true end,
    IsPurgeException = function(self) return false end,
}

item_mango_of_agility = class(ItemBaseClass)
modifier_mango_of_agility = class(item_mango_of_agility)
modifier_mango_of_agility_buff = class(ItemBaseClassBuff)
-------------
function item_mango_of_agility:GetIntrinsicModifierName()
    return "modifier_mango_of_agility"
end

function item_mango_of_agility:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    
    if not caster:IsAlive() or caster:GetHealthPercent() < 1 then return end

    if not caster:HasModifier("modifier_mango_of_agility_buff") then
        caster:AddNewModifier(caster, self, "modifier_mango_of_agility_buff", {});
        caster:SetModifierStackCount("modifier_mango_of_agility_buff", caster, 1)
    else
        caster:SetModifierStackCount("modifier_mango_of_agility_buff", caster, (caster:GetModifierStackCount("modifier_mango_of_agility_buff", caster) + 1))
    end

    local charges = self:GetCurrentCharges()
    if charges <= 1 then
        caster:RemoveItem(self)
    else
        self:SetCurrentCharges(charges-1)
    end
end
------------
function modifier_mango_of_agility_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS --GetModifierBonusStats_Strength
    }

    return funcs
end

function modifier_mango_of_agility_buff:GetModifierBonusStats_Agility()
    local stackCount = self:GetCaster():GetModifierStackCount("modifier_mango_of_agility_buff", self:GetCaster())

    return 5 * stackCount
end
------------
function modifier_mango_of_agility:DeclareFunctions()
    local funcs = {}

    return funcs
end