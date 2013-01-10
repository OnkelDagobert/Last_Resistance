if Server then
    Script.Load("lua/Server.lua")
    //Script.Load("lua/lr_Teamjoin.lua")
    kHumanPointsPerSec = 1


    local totalserverupdatetime = 0.0  
 
    local function h_UpdateServer(deltaTime)
        totalserverupdatetime = totalserverupdatetime + deltaTime        
        if((totalserverupdatetime % 1) < deltaTime) then//1 sec passed in this delta   
        
            //Add Score for Humans (ISSUE #1)
            if GetGamerules():GetGameState() == kGameState.Started then
                local h_team = GetGamerules():GetTeam(kTeam1Index)             
                playerlist = h_team:GetPlayers()
                table.foreach(playerlist,
                    function(_index)
                        if(playerlist[_index]:GetIsAlive()) then 
                            playerlist[_index]:AddScore(kHumanPointsPerSec,0)                             
                        end
                    end
                )
            end            
            //SendGlobalMessage(kTeamMessageTypes.NoCommander)            
            //SendGlobalMessage(kTeamMessageTypes.PlayerMutated, 1)
        end //end sec.
        
    end
    Event.Hook("UpdateServer", h_UpdateServer)
    

	
	
	
	

end