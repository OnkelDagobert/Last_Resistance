if Server then

	kConfig = nil 						//Global variable storing all configuration items for mods
	kSettings = nil 					//Global variable storing all settings for mods	
	kGameID = { }						//List of connected clients for GameID	

	//Hook Function Lists
	kOnClientConnect = { }				//Functions run on Client Connect
	kOnClientDisconnect = { }			//Functions run on Client Disconnect
	kOnServerUpdate = { }				//Functions run on ServerUpdate
	kOnClientDelayedConnect = { }		//Functions run on DelayedClientConnect
	kOnTeamJoin = { }					//Functions run on TeamJoin from Gamerules
	kOnGameEnd = { }						//Functions run on GameEnd from Gamerules
	kOnEntityKilled = { }				//Functions run on EntityKilled from Gamerules
	kOnUpdatePregame = { }				//Functions run on UpdatePregame from Gamerules
	kOnCastVoteByPlayer = { }			//Functions run on CastVoteByPlayer from Gamerules
	kOnSetGameState = { }			    //Functions run on SetGameState from Gamerules
	kOnClientChatMessage = { }			//Functions run on ChatMessages
	kCheckMapChange = { }	    		//List of functions run to confirm if map should change
	kOverrideMapChange = { }	    		//Functions run before MapCycle

	function RegisterEventHook(functionarray, eventfunction, priority)
		//Register Event in Array
		if functionarray ~= nil then
			table.insert(functionarray, {func = eventfunction, priority = priority})
			table.sort(functionarray, function(f1, f2) return f1.priority < f2.priority end)
		end
	end

	function ReleaseEventHook(functionarray, eventfunction)
		//Remove Event in Array
		if functionarray ~= nil then
			for i = 1, #functionarray do
				if functionarray[i].func == eventfunction then
					table.remove(functionarray, i)
					break
				end
			end
		end
	end	

	
    Script.Load("lua/Server.lua")
    //Script.Load("lua/lr_Teamjoin.lua")


end