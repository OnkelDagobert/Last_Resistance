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


function  makeDefaultConfig()
    
    kLRconfig.kPregameLength             = 15    //Time before Tagmode (no crosshair)
    kLRconfig.kTagModeMaxLength          = 30    //After this time Server decides who will be alien
    kLRconfig.kRoundTimeLimit            = 360   //6min
    kLRconfig.kAftergameLength           = 15    //Time the scoreboard will show up until the next round starts
    
    
    //ISSUE #17
    kLRconfig.kSupplyEnable              = true  //Enable Ammo/Health Spawn at TechPoints
    kLRconfig.kSupplyRespawnTime         = 30
    
    kLRconfig.kWeaponDropEnable          = true  //Enable Weapon Spawn at TechPoints
    kLRconfig.kWeaponDropRespawnTime     = 45    //Time weapon spawn is blocked after someone took the old weapon
    kLRconfig.kWeaponDropRefreshTime     = 15    //Time after old weapon is replaced with a random new weapon 
    kLRconfig.kWeaponDrop_probability    = {} 
    kLRconfig.kWeaponDrop_probability.flamethrower    = 0.2
    kLRconfig.kWeaponDrop_probability.grenadelauncher = 0.2
    kLRconfig.kWeaponDrop_probability.shotgun         = 0.5
    kLRconfig.kWeaponDrop_probability.minigun         = 0.0  //minigun doesn't work
    //ADD new WEAPON like: kWeaponDrop_probability.kMapName = probability
    //Shotgun.lua L.16: Shotgun.kMapName = "shotgun"   => kWeaponDrop_probability.shotgun
    
    
    kLRconfig.kHumanPointsPerSec = 1
    
    kLRconfig.Marines                           = {}
    kLRconfig.Marines.Weapons                   = {}
    kLRconfig.Marines.Weapons.NumStartClips     = 5     // # of Ammo Clips Marines spawn with
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
    kTimeToReadyRoom    = kLRconfig.kAftergameLength	

end