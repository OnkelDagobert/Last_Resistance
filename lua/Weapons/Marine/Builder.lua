// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Marine\Builder.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Weapon.lua")

class 'Builder' (Weapon)

Builder.kMapName = "builder"

local kModelName = PrecacheAsset("models/marine/welder/builder.model")
local kViewModelName = PrecacheAsset("models/marine/welder/welder_view.model")
local kAnimationGraph = PrecacheAsset("models/marine/welder/welder_view.animation_graph")

local kRange = 1.4
local kBuildEffectInterval = 0.2

local networkVars =
{
    building = "boolean",
    loopingSoundEntId = "entityid"
}

local kFireLoopingSound = PrecacheAsset("sound/NS2.fev/marine/welder/scan")

function Builder:OnCreate()

    Weapon.OnCreate(self)

    self.building = false
    
    self.loopingSoundEntId = Entity.invalidId
    
    if Server then
        
        self.loopingFireSound = Server.CreateEntity(SoundEffect.kMapName)
        self.loopingFireSound:SetAsset(kFireLoopingSound)
        self.loopingFireSound:SetParent(self)
        self.loopingSoundEntId = self.loopingFireSound:GetId()
        
    elseif Client then
        self.lastBuilderEffect = 0
    end

end

function Builder:OnInitialized()

    Weapon.OnInitialized(self)
    
    self:SetModel(kModelName)
    
end

function Builder:OnDestroy()

    Weapon.OnDestroy(self)
    
    if Server then
    
        // The loopingFireSound was already destroyed at this point, clear the reference.
        self.loopingFireSound = nil
    
    end

end

// for marine thirdperson pose
function Builder:OverrideWeaponName()
    return "builder"
end

function Builder:GetViewModelName()
    return kViewModelName
end

function Builder:GetAnimationGraphName()
    return kAnimationGraph
end

function Builder:GetHUDSlot()
    return kNoWeaponSlot
end

// Max degrees that weapon can swing left or right
function Builder:GetSwingAmount()
    return 10
end

function Builder:GetSprintAllowed()
    return false
end

function Builder:OnDraw(player, previousWeaponMapName)

    Weapon.OnDraw(self, player, previousWeaponMapName)
    
    // Attach weapon to parent's hand
    self:SetAttachPoint(Weapon.kHumanAttachPoint)
    
end

function Builder:OnHolster(player)

    Weapon.OnHolster(self, player)
    
    self.building = false
    
    if Server then
        self.loopingFireSound:Stop()
    end
    
end

function Builder:OnDrawClient()

    Weapon.OnDrawClient(self)
    
    self.playEffect = true
    
end

function Builder:OnHolsterClient()

    Weapon.OnHolsterClient(self)
    
    self.playEffect = false
    
end

function Builder:OnPrimaryAttack(player)
end

function Builder:OnPrimaryAttackEnd(player)
end

function Builder:UpdateViewModelPoseParameters(viewModel)
    viewModel:SetPoseParam("welder", 0)
end

function Builder:OnUpdateAnimationInput(modelMixin)

    PROFILE("Builder:OnUpdateAnimationInput")
    
    modelMixin:SetAnimationInput("activity", "primary")
    modelMixin:SetAnimationInput("welder", false)
    self:SetPoseParam("welder", 0)
    
end

function Builder:ProcessMoveOnWeapon(player, input)

    Weapon.ProcessMoveOnWeapon(self, player, input)
    
    if Server and not self.loopingFireSound:GetIsPlaying() then
        self.loopingFireSound:Start()
    end
    
end

local kCinematicName = PrecacheAsset("cinematics/marine/builder/builder_scan.cinematic")
local kMuzzleAttachPoint = "fxnode_weldermuzzle"

function Builder:OnUpdateRender()

    if self.playEffect then
    
        if self.lastBuilderEffect + kBuildEffectInterval <= Shared.GetTime() then
        
            CreateMuzzleCinematic(self, kCinematicName, kCinematicName, kMuzzleAttachPoint)
            self.lastBuilderEffect = Shared.GetTime()
            
        end
        
    end

end

Shared.LinkClassToMap("Builder", Builder.kMapName, networkVars)