Script.Load("lua/ConfigFileUtility.lua")

local lrconfigFileName = "Last_Resistance.json"

function tableMerge(t1, t2)
    for k,v in pairs(t2) do
    	if type(v) == "table" then
    		if type(t1[k] or false) == "table" then
    			tableMerge(t1[k] or {}, t2[k] or {})
    		else
    			t1[k] = v
    		end
    	else
    		t1[k] = v
    	end
    end
    return t1
end

//stuff Client needs to know
local kConfigUpdateMessage = 
{
    kPregameLength          = "integer (1 to 9999)",
    kTagModeMaxLength       = "integer (1 to 9999)",
    kRoundTimeLimit         = "integer (1 to 9999)", 
    kTimeToReadyRoom        = "integer (1 to 9999)"
}
function BuildConfigUpdateMessage(config)
    local t = {}    
    t.kPregameLength            = config.kPregameLength
    t.kTagModeMaxLength         = config.kTagModeMaxLength
    t.kRoundTimeLimit           = config.kRoundTimeLimit
    t.kTimeToReadyRoom          = config.kAftergameLength   
    return t        
end
Shared.RegisterNetworkMessage("LRConfig", kConfigUpdateMessage)

if Client then
    function OnConfigUpdateMessage(message)
        kPregameLength      = message.kPregameLength
        kTagModeMaxLength   = message.kTagModeMaxLength
        kRoundTimeLimit     = message.kRoundTimeLimit   
        kTimeToReadyRoom    = message.kTimeToReadyRoom	             
    end
    Client.HookNetworkMessage("LRConfig", OnConfigUpdateMessage)


end



if Server then
    local function h_onClientConnect(client)
            local player = client:GetControllingPlayer()
            if not Server.SendNetworkMessage(client, "LRConfig", BuildConfigUpdateMessage(kLRconfig), true) then
                            
            end
    end

    Event.Hook("ClientConnect", h_onClientConnect)



    function  makeDefaultConfig()
        
        kLRconfig.kPregameLength             = 3     //Time before Tagmode (no crosshair)
        kLRconfig.kTagModeMaxLength          = 30    //After this time Server decides who will be alien
        kLRconfig.kRoundTimeLimit            = 360   //6min
        kLRconfig.kAftergameLength           = 15    //Time the scoreboard will show up until the next round starts
        
        
        //ISSUE #17
        kLRconfig.kSupplyEnable              = true  //Enable Ammo/Health Spawn at TechPoints
        kLRconfig.kSupplyRespawnTime         = 20
        kLRconfig.kSupplyAmmoClips           = 2
        
        kLRconfig.kWeaponDropEnable          = true  //Enable Weapon Spawn at TechPoints
        kLRconfig.kWeaponDropRespawnTime     = 30    //Time weapon spawn is blocked after someone took the old weapon
        kLRconfig.kWeaponDropRefreshTime     = 15    //Time after old weapon is replaced with a random new weapon 
        kLRconfig.kWeaponDrop_probability    = {} 
        kLRconfig.kWeaponDrop_probability.flamethrower    = 0.2
        kLRconfig.kWeaponDrop_probability.grenadelauncher = 0.2
        kLRconfig.kWeaponDrop_probability.shotgun         = 0.5
        kLRconfig.kWeaponDrop_probability.rifle           = 0.0
        kLRconfig.kWeaponDrop_probability.mine            = 0.1
        //kLRconfig.kWeaponDrop_probability.jetpack         = 0.05        
        //kLRconfig.kWeaponDrop_probability.exosuit         = 0.0  //not tested
        //kLRconfig.kWeaponDrop_probability.railgun         = 0.0  //nope
        //kLRconfig.kWeaponDrop_probability.minigun         = 0.0  //minigun doesn't work
        //ADD new WEAPON like: kWeaponDrop_probability.kMapName = probability
        //Shotgun.lua L.16: Shotgun.kMapName = "shotgun"   => kWeaponDrop_probability.shotgun
        
        
        kLRconfig.kHumanPointsPerSec = 1
        
        kLRconfig.Marines                           = {}
        kLRconfig.Marines.Weapons                   = {}
        kLRconfig.Marines.Weapons.NumStartClips     = 2     // # of Ammo Clips Marines spawn with        
        kLRconfig.Marines.TechResearched            = {}
        kLRconfig.Marines.TechResearched.ArmorLvL   = 0
        kLRconfig.Marines.TechResearched.WeaponsLVL = 0
        
        
        kLRconfig.Aliens                            = {}
        kLRconfig.Aliens.TechResearched             = {}
        kLRconfig.Aliens.TechResearched.Leap        = true
        kLRconfig.Aliens.TechResearched.Xenocide    = false
        
        
        WriteDefaultConfigFile(lrconfigFileName, kLRconfig)
    end



    function LoadLRConfig()
        tableMerge(kLRconfig,LoadConfigFile(lrconfigFileName))   
    end

    function setConsts()
        kPregameLength      = kLRconfig.kPregameLength
        kTagModeMaxLength   = kLRconfig.kTagModeMaxLength
        kRoundTimeLimit     = kLRconfig.kRoundTimeLimit   
        kTimeToReadyRoom    = kLRconfig.kAftergameLength	

    end

end