LinkLuaModifier("modifier_mango_of_strength", "items/custom/item_mango_of_strength.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mango_of_strength_buff", "items/custom/item_mango_of_strength.lua", LUA_MODIFIER_MOTION_NONE)

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
}

item_mango_of_strength = class(ItemBaseClass)
modifier_mango_of_strength = class(item_mango_of_strength)
modifier_mango_of_strength_buff = class(ItemBaseClassBuff)
-------------
function item_mango_of_strength:GetIntrinsicModifierName()
    return "modifier_mango_of_strength"
end

function item_mango_of_strength:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    
    if not caster:IsAlive() or caster:GetHealthPercent() < 1 then return end

    if not caster:HasModifier("modifier_mango_of_strength_buff") then
        caster:AddNewModifier(caster, self, "modifier_mango_of_strength_buff", {});
        caster:SetModifierStackCount("modifier_mango_of_strength_buff", caster, 1)
    else
        caster:SetModifierStackCount("modifier_mango_of_strength_buff", caster, (caster:GetModifierStackCount("modifier_mango_of_strength_buff", caster) + 1))
    end

    local charges = self:GetCurrentCharges()
    if charges <= 1 then
        caster:RemoveItem(self)
    else
        self:SetCurrentCharges(charges-1)
    end
end
------------
function modifier_mango_of_strength_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS --GetModifierBonusStats_Strength
    }

    return funcs
end

function modifier_mango_of_strength_buff:GetModifierBonusStats_Strength()
    local stackCount = self:GetCaster():GetModifierStackCount("modifier_mango_of_strength_buff", self:GetCaster())

    return 5 * stackCount
end
------------
function modifier_mango_of_strength:DeclareFunctions()
    local funcs = {}

    return funcs
end