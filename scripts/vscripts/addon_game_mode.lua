_G.ADDON_FOLDER = debug.getinfo(1,"S").source:sub(2,-37)
_G.PUBLISH_DATA = LoadKeyValues(ADDON_FOLDER:sub(5,-16).."publish_data.txt") or {}
_G.WORKSHOP_TITLE = PUBLISH_DATA.title or "Dota 2 but..."-- LoadKeyValues(debug.getinfo(1,"S").source:sub(7,-53).."publish_data.txt").title 
_G.MAX_LEVEL = 100

_G.GameMode = _G.GameMode or class({})

require("internal/utils/util")
require("internal/init")

require("internal/courier") -- EditFilterToCourier called from internal/filters
require("internal/utils/butt_api")
require("internal/utils/custom_gameevents")
require("internal/utils/particles")
require("internal/utils/timers")
require("item_drop")
-- require("internal/utils/notifications") -- will test it tomorrow 

require("internal/events")
require("internal/filters")
require("internal/panorama")
require("internal/shortcuts")
require("internal/talents")
require("internal/thinker")
require("internal/xp_modifier")

softRequire("events")
softRequire("filters")
softRequire("settings_butt")
softRequire("thinker")

--duel
require("duel/duel")
require("duel/position_check")
require("duel/teleport")

-- AABS
require('util/init')
require("libraries/keyvalues")
require("libraries/projectiles")
require("libraries/notifications")
require("libraries/animations")
require("libraries/attachments")
require("libraries/playertables")
require("libraries/containers")
require("libraries/worldpanels")
require("libraries/statcollection/init")
    --------------------------------------------------
require("data/constants")
require("data/globals")
require("data/kv_data")
require("data/modifiers")
require("data/abilities")
require("data/ability_functions")
    --------------------------------------------------
require("modules/index")

softRequire("events")
softRequire("custom_events")
softRequire("filters")

--AABS

function GameMode:OnGameInProgress() -- Функция начнет выполняться, когда начнется матч( на часах будет 00:00 ).
    Say(Returns:void Have Entity say ''string'', and teamOnly or not) -- Выводим в чат сообщение 'Wave №', в конце к которому добавится значение GAME_ROUND.
end

function Precache( context )
	FireGameEvent("addon_game_mode_precache",nil)
	PrecacheResource("soundfile", "soundevents/custom_sounds.vsndevts", context)
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
end

function Spawn()
	FireGameEvent("addon_game_mode_spawn",nil)
	local gmE = GameRules:GetGameModeEntity()

	gmE:SetUseDefaultDOTARuneSpawnLogic(true)
	gmE:SetTowerBackdoorProtectionEnabled(true)
	GameRules:SetShowcaseTime(0)

	FireGameEvent("created_game_mode_entity",{gameModeEntity = gmE})
end

function Activate()
	FireGameEvent("addon_game_mode_activate",nil)
	-- GameRules.GameMode = GameMode()
	-- FireGameEvent("init_game_mode",{})
end

ListenToGameEvent("addon_game_mode_activate", function()
	print( "Dota Butt Template is loaded." )
end, nil)

ListenToGameEvent('npc_spawned', function(event)
    HandleNpcSpawned(event.entindex)
end, nil)

function HandleNpcSpawned(entityIndex)
    local entity = EntIndexToHScript(entityIndex)
    local innateAbilityName = "neutral_upgrade"
    
    if  entity:HasAbility(innateAbilityName) then
        entity:FindAbilityByName(innateAbilityName):SetLevel(1)
    end

	local entity = EntIndexToHScript(entityIndex)
    local innateAbilityName = "pangolier_heartpiercer"
    
    if  entity:HasAbility(innateAbilityName) then
        entity:FindAbilityByName(innateAbilityName):SetLevel(1)
    end

	local entity = EntIndexToHScript(entityIndex)
    local innateAbilityName = "black_dragon_splash_attack"
    
    if  entity:HasAbility(innateAbilityName) then
        entity:FindAbilityByName(innateAbilityName):SetLevel(1)
    end

	local entity = EntIndexToHScript(entityIndex)
    local innateAbilityName = "life_stealer_feast"
    
    if  entity:HasAbility(innateAbilityName) then
        entity:FindAbilityByName(innateAbilityName):SetLevel(1)
    end

	local entity = EntIndexToHScript(entityIndex)
    local innateAbilityName = "special_bonus_truestrike"
    
    if  entity:HasAbility(innateAbilityName) then
        entity:FindAbilityByName(innateAbilityName):SetLevel(1)
    end

    local entity = EntIndexToHScript(entityIndex)
    local innateAbilityName = "sandking_caustic_finale"
    
    if  entity:HasAbility(innateAbilityName) then
        entity:FindAbilityByName(innateAbilityName):SetLevel(1)
    end

    local entity = EntIndexToHScript(entityIndex)
    local innateAbilityName = "chen_holy_persuasion"
    
    if  entity:HasAbility(innateAbilityName) then
        entity:FindAbilityByName(innateAbilityName):SetLevel(1)
    end

	local entity = EntIndexToHScript(entityIndex)
    local innateAbilityName = "life_stealer_rage"
    
    if  entity:HasAbility(innateAbilityName) then
        entity:FindAbilityByName(innateAbilityName):SetLevel(1)
    end

    local entity = EntIndexToHScript(entityIndex)
    local innateAbilityName = "life_stealer_infest"
    
    if  entity:HasAbility(innateAbilityName) then
        entity:FindAbilityByName(innateAbilityName):SetLevel(3)
    end




end

