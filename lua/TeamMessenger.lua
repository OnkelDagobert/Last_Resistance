// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
//    
// lua\TeamMessenger.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kTeamMessageTypes = enum({ 'GameStarted', 'PowerLost', 'PowerRestored', 'Eject', 'CannotSpawn',
                           'SpawningWait', 'Spawning', 'ResearchComplete', 'ResearchLost',
                           'HiveConstructed', 'HiveLowHealth', 'HiveKilled',
                           'CommandStationUnderAttack', 'IPUnderAttack', 'HiveUnderAttack',
                           'PowerPointUnderAttack', 'Beacon', 'NoCommander', 'TeamsUnbalanced',
                           'TeamsBalanced', 'PlayerMutated', 'TagMode', 'SurviveStart' })

local kTeamMessages = { }

kTeamMessages[kTeamMessageTypes.GameStarted] = { text = { [kMarineTeamType] = "MARINE_TEAM_GAME_STARTED", [kAlienTeamType] = "ALIEN_TEAM_GAME_STARTED" } }

// This function will generate the string to display based on a location Id.
local locationStringGen = function(locationId, messageString) return string.format(Locale.ResolveString(messageString), Shared.GetString(locationId)) end

// Thos function will generate the string to display based on a research Id.
local researchStringGen = function(researchId, messageString) return string.format(Locale.ResolveString(messageString), GetDisplayNameForTechId(researchId)) end

local usernameStringGen = function(playerid, messageString)
    /*local teams = GetGamerules():GetTeams()
    local player = teams[2]:GetPlayer(playerid)
    if player == nil then
        player = teams[3]:GetPlayer(playerid)        
    end
    local playername =  player:getName()*/   
    local allPlayers = ScoreboardUI_GetAllScores()
    local numPlayers = table.count(allPlayers)
    local playername = "NO NAME"
    for i = 1, numPlayers do
        local clientIndex = allPlayers[i].ClientIndex
        if clientIndex == playerid then
            playername = allPlayers[i].Name
            break
        end
    end 
    //return string.format(Locale.ResolveString(messageString),playername)
    return string.format("%s is mutating!",playername)
end

local tag_mode_str = function()
    return "           Tag mode!\nFrag your neighbor!!!"
end

local Marine_Surv_Start_str = function()
    return "SURVIVE!!!"
end
local Alien_Surv_Start_str = function()
    return "KILL ALL HUMANS!!!"
end

kTeamMessages[kTeamMessageTypes.PowerLost] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "POWER_LOST") end } }

kTeamMessages[kTeamMessageTypes.PowerRestored] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "POWER_RESTORED") end } }

kTeamMessages[kTeamMessageTypes.Eject] = { text = { [kMarineTeamType] = "COMM_EJECT", [kAlienTeamType] = "COMM_EJECT" } }

//Issue 9 :
// kTeamMessages[kTeamMessageTypes.CannotSpawn] = { text = { [kMarineTeamType] = "NO_IPS" } }

kTeamMessages[kTeamMessageTypes.SpawningWait] = { text = { [kAlienTeamType] = "WAITING_TO_SPAWN" } }

kTeamMessages[kTeamMessageTypes.Spawning] = { text = { [kMarineTeamType] = "SPAWNING", [kAlienTeamType] = "SPAWNING" } }

kTeamMessages[kTeamMessageTypes.ResearchComplete] = { text = { [kAlienTeamType] = function(data) return researchStringGen(data, "EVOLUTION_AVAILABLE") end } }

kTeamMessages[kTeamMessageTypes.ResearchLost] = { text = { [kAlienTeamType] = function(data) return researchStringGen(data, "EVOLUTION_LOST") end } }

kTeamMessages[kTeamMessageTypes.HiveConstructed] = { text = { [kAlienTeamType] = function(data) return locationStringGen(data, "HIVE_CONSTRUCTED") end } }

kTeamMessages[kTeamMessageTypes.HiveLowHealth] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "HIVE_LOW_HEALTH") end,
                                                            [kAlienTeamType] = function(data) return locationStringGen(data, "HIVE_LOW_HEALTH") end } }

kTeamMessages[kTeamMessageTypes.HiveKilled] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "HIVE_KILLED") end,
                                                         [kAlienTeamType] = function(data) return locationStringGen(data, "HIVE_KILLED") end } }

kTeamMessages[kTeamMessageTypes.CommandStationUnderAttack] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "COMM_STATION_UNDER_ATTACK") end } }

kTeamMessages[kTeamMessageTypes.IPUnderAttack] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "IP_UNDER_ATTACK") end } }

kTeamMessages[kTeamMessageTypes.HiveUnderAttack] = { text = { [kAlienTeamType] = function(data) return locationStringGen(data, "HIVE_UNDER_ATTACK") end } }

kTeamMessages[kTeamMessageTypes.PowerPointUnderAttack] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "POWER_POINT_UNDER_ATTACK") end } }

kTeamMessages[kTeamMessageTypes.Beacon] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "BEACON_TO") end } }

kTeamMessages[kTeamMessageTypes.NoCommander] = { text = { [kMarineTeamType] = "NO_COMM", [kAlienTeamType] = "NO_COMM" } }

//Issue 10:
//kTeamMessages[kTeamMessageTypes.TeamsUnbalanced] = { text = { [kMarineTeamType] = "TEAMS_UNBALANCED", [kAlienTeamType] = "TEAMS_UNBALANCED" } }

//kTeamMessages[kTeamMessageTypes.TeamsBalanced] = { text = { [kMarineTeamType] = "TEAMS_BALANCED", [kAlienTeamType] = "TEAMS_BALANCED" } }

kTeamMessages[kTeamMessageTypes.PlayerMutated] = { text = { [kMarineTeamType] = function(data) return usernameStringGen(data,"PLAYER_MUTATED") end,
                                                         [kAlienTeamType] = function(data) return usernameStringGen(data,"PLAYER_MUTATED") end } }
                                                         
//kTeamMessages[kTeamMessageTypes.TagMode] = { text = { [kMarineTeamType] = "TAG_MODE", [kAlienTeamType] = "TAG_MODE" } }
kTeamMessages[kTeamMessageTypes.TagMode] = { text = { [kMarineTeamType] = function(data) return tag_mode_str() end, [kAlienTeamType] = function(data) return tag_mode_str() end } }
//kTeamMessages[kTeamMessageTypes.SurviveStart] = { text = { [kMarineTeamType] = "SURV_START_MARINE", [kAlienTeamType] = "SURV_START_ALIEN" } }        
kTeamMessages[kTeamMessageTypes.SurviveStart] = { text = { [kMarineTeamType] = function(data) return Marine_Surv_Start_str() end, [kAlienTeamType] = function(data) return Alien_Surv_Start_str() end } }                                                  

// Silly name but it fits the convention.
local kTeamMessageMessage =
{
    type = "enum kTeamMessageTypes",
    data = "integer"
}

Shared.RegisterNetworkMessage("TeamMessage", kTeamMessageMessage)

if Server then

    /**
     * Sends every team the passed in message for display.
     */
    function SendGlobalMessage(messageType, optionalData)
    
        if GetGamerules():GetGameStarted() or GetGamerules():GetGameTagMode() then
        
            local teams = GetGamerules():GetTeams()
            for t = 1, #teams do
                SendTeamMessage(teams[t], messageType, optionalData)
            end
            
        end
        
    end
    
    /**
     * Sends every player on the passed in team the passed in message for display.
     */
    function SendTeamMessage(team, messageType, optionalData)
    
        if GetGamerules():GetGameStarted() or GetGamerules():GetGameTagMode() then
        
            local function SendToPlayer(player)
                Server.SendNetworkMessage(player, "TeamMessage", { type = messageType, data = optionalData or 0 }, true)
            end
            
            team:ForEachPlayer(SendToPlayer)
            
        end
        
    end
    
    /**
     * Sends the passed in message to the players passed in.
     */
    function SendPlayersMessage(playerList, messageType, optionalData)
    
        if GetGamerules():GetGameStarted() or GetGamerules():GetGameTagMode() then
        
            for p = 1, #playerList do
                Server.SendNetworkMessage(playerList[p], "TeamMessage", { type = messageType, data = optionalData or 0 }, true)
            end
            
        end
        
    end
    
    local function TestTeamMessage(client)
    
        local player = client:GetControllingPlayer()
        if player then
            SendPlayersMessage({ player }, kTeamMessageTypes.NoCommander)
        end
        
    end
    
    Event.Hook("Console_ttm", TestTeamMessage)
    
end

if Client then

    local function SetTeamMessage(messageType, messageData)
    
        local player = Client.GetLocalPlayer()
        if player and HasMixin(player, "TeamMessage") then
        
            local displayText = kTeamMessages[messageType].text[player:GetTeamType()]
            
            if displayText then
            
                if type(displayText) == "function" then
                    displayText = displayText(messageData)
                else
                    displayText = Locale.ResolveString(displayText)
                end
                
                assert(type(displayText) == "string")
                player:SetTeamMessage(string.upper(displayText))
                
            end
            
        end
        
    end
    
    function OnCommandTeamMessage(message)
        SetTeamMessage(message.type, message.data)
    end
    
    Client.HookNetworkMessage("TeamMessage", OnCommandTeamMessage)
    
end