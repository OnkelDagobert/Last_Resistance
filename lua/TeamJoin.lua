// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TeamJoin.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Trigger.lua")

class 'TeamJoin' (Trigger)

TeamJoin.kMapName = "team_join"

local networkVars =
{
    teamNumber = string.format("integer (-1 to %d)", kSpectatorIndex),
    teamIsFull = "boolean",
    playerCount = "integer (0 to " .. kMaxPlayers - 1 .. ")"
}

function TeamJoin:OnCreate()

    Trigger.OnCreate(self)
    
    self.teamIsFull = true
    self.playerCount = 0
    
    if Server then
        self:SetUpdates(true)
    end
    
end

function TeamJoin:OnInitialized()

    Trigger.OnInitialized(self)
    
    // self:SetPropagate(Actor.Propagate_Never)
    self:SetPropagate(Entity.Propagate_Always)
    
    self:SetIsVisible(false)
    
    self:SetTriggerCollisionEnabled(true)
    
end

if Server then

    function TeamJoin:OnUpdate()
    
        local team1PlayerCount = GetGamerules():GetTeam(kTeam1Index):GetNumPlayers()
        local team2PlayerCount = GetGamerules():GetTeam(kTeam2Index):GetNumPlayers()
        if self.teamNumber == kTeam1Index then
        
            self.teamIsFull = team1PlayerCount > team2PlayerCount
            self.playerCount = team1PlayerCount
            
        elseif self.teamNumber == kTeam2Index then
        
            self.teamIsFull = team1PlayerCount == 0
            self.playerCount = team2PlayerCount
            
        end
        
    end
    


function JoinRandomTeam(player)

        // Join team with less players or random.
        local team1Players = GetGamerules():GetTeam(kTeam1Index):GetNumPlayers()
        local team2Players = GetGamerules():GetTeam(kTeam2Index):GetNumPlayers()
        
        // The first player will automatically joining aliens, all others will go to marines
        if team2Players == 0 then
            Server.ClientCommand(player, "jointeamtwo")
        else
            Server.ClientCommand(player, "jointeamone")
        end
        
    end





    function TeamJoin:OnTriggerEntered(enterEnt, triggerEnt)
        local team1Players = GetGamerules():GetTeam(kTeam1Index):GetNumPlayers()
        local team2Players = GetGamerules():GetTeam(kTeam2Index):GetNumPlayers()
        if enterEnt:isa("Player") then
        
            if self.teamNumber == kTeamReadyRoom then
                Server.ClientCommand(enterEnt, "spectate")
            elseif self.teamNumber == kTeam1Index then
                //if GetGamerules():GetGameStarted() or GetGamerules():GetGameTagMode() then
                    //playerl = {enterEnt}                    
                    //SendPlayersMessage(playerl ,kTeamMessageTypes.SurviveStart )
                //else                
                    Server.ClientCommand(enterEnt, "jointeamone")
                //end 
            elseif self.teamNumber == kTeam2Index then
                Server.ClientCommand(enterEnt, "jointeamtwo")
            elseif self.teamNumber == kRandomTeamType then
                Server.ClientCommand(enterEnt, "jointeamtwo")
                //JoinRandomTeam(enterEnt)
            end
            
        end
            
    end

end

Shared.LinkClassToMap("TeamJoin", TeamJoin.kMapName, networkVars)