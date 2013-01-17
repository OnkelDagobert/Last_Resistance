if Server then
    kFriendlyFire = false //Dont edit
    
    //Load Config
    kLRconfig = {}     
    Script.Load("lua/lr_Config.lua")
    makeDefaultConfig()
    LoadLRConfig()
    
    Script.Load("lua/Server.lua")
    setConsts()
    //Script.Load("lua/lr_Teamjoin.lua")
    


    

    local totalserverupdatetime = 0.0   
    local function h_UpdateServer(deltaTime)
        totalserverupdatetime = totalserverupdatetime + deltaTime        
        if((totalserverupdatetime % 1) < deltaTime) then//1 sec passed in this delta   
            local h_team = GetGamerules():GetTeam(kTeam1Index) 
        
            //Add Score for Humans (ISSUE #1)
            if GetGamerules():GetGameState() == kGameState.Started then
                            
                playerlist = h_team:GetPlayers()
                table.foreach(playerlist,
                    function(_index)
                        if(playerlist[_index]:GetIsAlive()) then 
                            playerlist[_index]:AddScore(kLRconfig.kHumanPointsPerSec,0)                             
                        end
                    end
                )
            end            
            //SendGlobalMessage(kTeamMessageTypes.NoCommander)            
            //SendGlobalMessage(kTeamMessageTypes.PlayerMutated, 1)
            
            
        end //end 1 sec.
        
        if((totalserverupdatetime % 2) < deltaTime) then//2 sec passed in this delta
            local h_team = GetGamerules():GetTeam(kTeam1Index) 
            
            //ISSUE #3
            if GetGamerules():GetGameTagMode() then
                SendTeamMessage(h_team, kTeamMessageTypes.TagMode)   
            end        
            
            //ISSUE #17
            if kLRconfig.kSupplyEnable then
                local ResourcePoints = GetEntitiesMatchAnyTypes({"ResourcePoint"})            
                table.foreach(ResourcePoints,
                        function(_index)                        
                               ResourcePoints[_index]:dropSupplyPacks() 
                        end
                )
            end
            
        end //end 2 sec.
        
        //ISSUE #17
        if kLRconfig.kSupplyEnable and GetGamerules() ~= nil  then
            local ResourcePoints = GetEntitiesMatchAnyTypes({"ResourcePoint"})            
                table.foreach(ResourcePoints,
                    function(_index)                                                    
                           ResourcePoints[_index]:OnUpdateDropPosition(deltaTime) 
                    end
               )
        end
        
    end
    Event.Hook("UpdateServer", h_UpdateServer)
    

	
	
	
	

end