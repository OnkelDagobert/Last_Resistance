// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechPoint_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function TechPoint:GetCanTakeDamageOverride()
    return false
end

function TechPoint:GetCanDieOverride()
    return false
end

function TechPoint:OnAttached(entity)
    self.occupiedTeam = entity:GetTeamNumber()
end

function TechPoint:OnDetached()
    self.showObjective = false
    self.occupiedTeam = 0
end

function TechPoint:Reset()
    
    self:OnInitialized()
    
    self:ClearAttached()
    
end

function TechPoint:SetAttached(structure)
    ScriptActor.SetAttached(self, structure)
end 

// Spawn command station or hive on tech point
function TechPoint:SpawnCommandStructure(teamNumber)

    local alienTeam = (GetGamerules():GetTeam(teamNumber):GetTeamType() == kAlienTeamType)
    local techId = ConditionalValue(alienTeam, kTechId.Hive, kTechId.CommandStation)
    
    return CreateEntityForTeam(techId, Vector(self:GetOrigin()), teamNumber)
    
end

//ISSUE #17 weaponaddon
function GetWeaponbyProp()
    local total_prop = 0.0
    for k,v in pairs(kWeaponDrop_probability) do 
        total_prop = total_prop + v
    end
    local rand = math.random( total_prop*100 ) / 100.0
    local c_prop = 0.0    
    for k,v in pairs(kWeaponDrop_probability) do 
        c_prop = c_prop + v
        if rand < c_prop then
            return k
        end
    end
    return "rifle"
end


TechPoint.weapon_id = 0
TechPoint.ttime = 0
TechPoint.trf_time = 0
TechPoint.trs_time = -1
function TechPoint:DropWeapon(deltaTime)
    self.ttime = self.ttime + deltaTime    
    if self.ttime < 1 then
        return
    end     
    
    local old_weapon = nil    
    if self.weapon_id ~= 0 then
         old_weapon = Shared.GetEntity( self.weapon_id )
    end    
    
    if self.trs_time ~= -1 then
        self.trs_time = self.trs_time + self.ttime
    end
    if self.trs_time == -1 and self.weapon_id ~= 0 and old_weapon ~= nil and not old_weapon:GetWeaponWorldState() then        
        self.trs_time = 0
    end
    
    
    //refresh weapon  and destroy old one if worldState
    self.trf_time = self.trf_time + self.ttime
    if self.trf_time >= kWeaponDropRefreshTime then
        if self.trs_time == -1 then
            if old_weapon ~= nil and old_weapon:GetWeaponWorldState() then
                DestroyEntity(old_weapon)            
            end 
            self.weapon_id = 0
        end
        self.trf_time  = 0        
    end   
     
    
    if self.weapon_id == 0 or old_weapon == nil or self.trs_time > kWeaponDropRespawnTime  then 
        local weapon_pos = self:GetOrigin() + Vector(0,1,0)
        local weaponname = GetWeaponbyProp()
        local weapon = CreateEntity(weaponname, weapon_pos , kTeam1Index)
        weapon.weaponWorldState = true
        self.weapon_id = weapon:GetId()
        self.trf_time  = 0  
        self.trs_time = -1
    end
    
    self.ttime = 0
end


function TechPoint:OnUpdate(deltaTime)
    ScriptActor.OnUpdate(self, deltaTime)
    
    if self.smashed and not self.smashScouted then
        local attached = self:GetAttached()
        if attached and attached:GetIsSighted() then
            self.smashScouted = true
        end
    end    
    
    if kWeaponDropEnable then
        self:DropWeapon(deltaTime)
    end
    
end    




