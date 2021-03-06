// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\SpitSpray.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Spit attack on primary.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/Spit.lua")
Script.Load("lua/Weapons/Alien/HealSprayMixin.lua")

class 'SpitSpray' (Ability)

SpitSpray.kMapName = "spitspray"

local kSpitSpeed = 40

local kAnimationGraph = PrecacheAsset("models/alien/gorge/gorge_view.animation_graph")

local kSpitViewEffect = PrecacheAsset("cinematics/alien/gorge/spit_1p.cinematic")
local kSpitProjectileEffect = PrecacheAsset("cinematics/alien/gorge/spit_1p_projectile.cinematic")
local attackEffectMaterial = nil

if Client then

    attackEffectMaterial = Client.CreateRenderMaterial()
    attackEffectMaterial:SetMaterial("materials/effects/mesh_effects/view_spit.material")
    
end

local networkVars =
{
}

AddMixinNetworkVars(HealSprayMixin, networkVars)

function SpitSpray:OnCreate()

    Ability.OnCreate(self)
    
    self.primaryAttacking = false
    
    InitMixin(self, HealSprayMixin)
    
end

function SpitSpray:GetAnimationGraphName()
    return kAnimationGraph
end

function SpitSpray:GetEnergyCost(player)
    return kSpitEnergyCost
end

function SpitSpray:GetHUDSlot()
    return 1
end

function SpitSpray:GetSecondaryTechId()
    return kTechId.Spray
end

function SpitSpray:GetPrimaryEnergyCost()
    return kSpitEnergyCost
end

local function CreateSpitProjectile(self, player)   

    if Server then
        
        local viewAngles = player:GetViewAngles()
        local viewCoords = viewAngles:GetCoords()
        local startPoint = player:GetEyePos() + viewCoords.zAxis * 1

        local startVelocity = viewCoords.zAxis * kSpitSpeed
        
        local spit = CreateEntity(Spit.kMapName, startPoint, player:GetTeamNumber())
        SetAnglesFromVector(spit, viewCoords.zAxis)
        spit:Setup(player, startVelocity, false)
        
    end

end

local function CreatePredictedProjectile(self, player)

    if Client then

        local viewAngles = player:GetViewAngles()
        local viewCoords = viewAngles:GetCoords()
        local tracerStart = player:GetEyePos() - viewCoords.yAxis * 0.2
        local trace = Shared.TraceRay(tracerStart, player:GetEyePos() + viewCoords.zAxis * 20, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterAll())

        local tracerVelocity = viewCoords.zAxis * kSpitSpeed * 0.7
        CreateTracer(tracerStart, trace.endPoint, tracerVelocity, self, kSpitProjectileEffect)
    
    end

end

function SpitSpray:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() then
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end
    
end

function SpitSpray:OnPrimaryAttackEnd(player)

    Ability.OnPrimaryAttackEnd(self, player)
    
    self.primaryAttacking = false
    
end

function SpitSpray:OnTag(tagName)

    PROFILE("SpitSpray:OnTag")

    if self.primaryAttacking and tagName == "shoot" then
    
        local player = self:GetParent()
        
        if player then
        
            CreateSpitProjectile(self, player)
            CreatePredictedProjectile(self, player)
            
            player:DeductAbilityEnergy(self:GetEnergyCost())
            
            self:TriggerEffects("spitspray_attack")
            
            if Client then
            
                local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
                cinematic:SetCinematic(kSpitViewEffect)
                
                local model = player:GetViewModelEntity():GetRenderModel()

                model:RemoveMaterial(attackEffectMaterial)
                model:AddMaterial(attackEffectMaterial)
                attackEffectMaterial:SetParameter("attackTime", Shared.GetTime())
                
            end
            
        end
        
    end
    
end

function SpitSpray:OnUpdateAnimationInput(modelMixin)

    PROFILE("SpitSpray:OnUpdateAnimationInput")

    modelMixin:SetAnimationInput("ability", "spit")
    
    local activityString = "none"
    if self.primaryAttacking then
        activityString = "primary"
    end
    modelMixin:SetAnimationInput("activity", activityString)
    
end

Shared.LinkClassToMap("SpitSpray", SpitSpray.kMapName, networkVars)