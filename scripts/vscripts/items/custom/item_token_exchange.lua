local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_token_exchange = class(ItemBaseClass)
-------------
function item_token_exchange:OnSpellStart()
    print("hello")
end