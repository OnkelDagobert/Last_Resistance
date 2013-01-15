if Server then
    kFriendlyFire = false
    kRoundTimeLimit = 300 //5min
    
    
    //ISSUE #17
    kSupplyEnable           = true  //Enable Ammo/Health Spawn at TechPoints
    kSupplyRespawnTime      = 30
    
    kWeaponDropEnable       = true  //Enable Weapon Spawn at TechPoints
    kWeaponDropRespawnTime  = 60    //Time weapon spawn is blocked after someone took the old weapon
    kWeaponDropRefreshTime  = 30    //Time after old weapon is replaced with a random new weapon 
    kWeaponDrop_probability = {} 
    kWeaponDrop_probability.flamethrower    = 0.2
    kWeaponDrop_probability.grenadelauncher = 0.2
    kWeaponDrop_probability.shotgun         = 0.5
    kWeaponDrop_probability.minigun         = 0.0  //minigun doesn't work
    //ADD new WEAPON like: kWeaponDrop_probability.kMapName = probability
    //Shotgun.lua L.16: Shotgun.kMapName = "shotgun"   => kWeaponDrop_probability.shotgun
    
    Script.Load("lua/Server.lua")
    //Script.Load("lua/lr_Teamjoin.lua")
    kHumanPointsPerSec = 1


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
                            playerlist[_index]:AddScore(kHumanPointsPerSec,0)                             
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
            if kSupplyEnable then
                local ResourcePoints = GetEntitiesMatchAnyTypes({"ResourcePoint"})            
                table.foreach(ResourcePoints,
                        function(_index)                        
                               ResourcePoints[_index]:dropSupplyPacks() 
                        end
                )
            end
            
        end //end 2 sec.
        
        //ISSUE #17
        if kSupplyEnable and GetGamerules() ~= nil  then
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