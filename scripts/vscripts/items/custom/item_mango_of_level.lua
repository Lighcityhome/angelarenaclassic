LinkLuaModifier("modifier_mango_of_level", "items/custom/item_mango_of_level.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mango_of_level_buff", "items/custom/item_mango_of_level.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return true end,
}

item_mango_of_level = class(ItemBaseClass)
modifier_mango_of_level = class(item_mango_of_level)
-------------
function item_mango_of_level:GetIntrinsicModifierName()
    return "modifier_mango_of_level"
end

function item_mango_of_level:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    
    if not caster:IsAlive() or caster:GetHealthPercent() < 1 then return end
    
    caster:HeroLevelUp(true)

    local charges = self:GetCurrentCharges()
    if charges <= 1 then
        caster:RemoveItem(self)
    else
        self:SetCurrentCharges(charges-1)
    end
end