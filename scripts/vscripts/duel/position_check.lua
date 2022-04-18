local SafeTeleportAll = require("duels/teleport").SafeTeleportAll

function NotTouchingDuel(ev)
    if ev.activator:HasModifier("duel_player_modifier") and ev.activator:IsAlive() and not ev.activator:IsOutOfGame() then 
        if ev.activator:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
            SafeTeleportAll(ev.activator, Entities:FindByName(nil, "duel_radiant_tp_point"):GetAbsOrigin(), 100)
        else
            SafeTeleportAll(ev.activator, Entities:FindByName(nil, "duel_dire_tp_point"):GetAbsOrigin(), 100)
        end
    end
end