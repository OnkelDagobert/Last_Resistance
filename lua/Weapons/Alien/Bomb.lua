//=============================================================================
//
// lua\Weapons\Alien\Bomb.lua
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
// Bile bomb projectile
//
//=============================================================================

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/Weapons/DotMarker.lua")

class 'Bomb' (Projectile)

Bomb.kMapName            = "bomb"
Bomb.kModelName          = PrecacheAsset("models/alien/gorge/bilebomb.model")

// The max amount of time a Bomb can last for
Bomb.kLifetime = 6

local kBileBombDotIntervall = 0.4

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function Bomb:OnCreate()

    Projectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)

    self.radius = 0.2

end

function Bomb:OnInitialized()

    Projectile.OnInitialized(self)
    
    if Server then
        self:AddTimedCallback(Bomb.TimeUp, Bomb.kLifetime)
    end

end

function Bomb:GetProjectileModel()
    return Bomb.kModelName
end 
   
function Bomb:GetDeathIconIndex()
    return 
end

if Server then

    function Bomb:ProcessHit(targetHit, surface)

        if (not self:GetOwner() or targetHit ~= self:GetOwner()) and not self.detonated then
    
            self:TriggerEffects("bilebomb_hit")
            
            local dotMarker = CreateEntity(DotMarker.kMapName, self:GetOrigin() + Vector(0, 0.2, 0), self:GetTeamNumber())
            dotMarker:SetDamageType(kBileBombDamageType)
            dotMarker:SetLifeTime(kBileBombDuration)
            dotMarker:SetDamage(kBileBombDamage)
            dotMarker:SetRadius(kBileBombSplashRadius)
            dotMarker:SetDamageIntervall(kBileBombDotIntervall)
            dotMarker:SetDotMarkerType(DotMarker.kType.Static)
            dotMarker:SetTargetEffectName("bilebomb_onstructure")
            dotMarker:SetDeathIconIndex(kDeathMessageIcon.BileBomb)
            dotMarker:SetOwner(self:GetOwner())

            DestroyEntity(self)

        end

    end
    
    function Bomb:TimeUp(currentRate)

        DestroyEntity(self)
        return false
    
    end

end

function Bomb:GetNotifiyTarget()
    return false
end


Shared.LinkClassToMap("Bomb", Bomb.kMapName, networkVars)