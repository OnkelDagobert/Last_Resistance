// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Order.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// An order that is given to an AI unit or player.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/OwnerMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")

class 'Order' (Entity)

Order.kMapName = "order"

local networkVars =
{
    // No need to send entId as the entity origin is updated every frame
    orderType = "enum kTechId",
    // TODO: use exact max entity count here
    orderParam = "integer (-1 to 4000)",
    orderLocation = "vector",
    orderOrientation = "interpolated angle (11 bits)",
    orderSource = "vector",
}

function Order:OnCreate()

    if Server then
        InitMixin(self, OwnerMixin)
    end
    
    InitMixin(self, EntityChangeMixin)

    self.orderType = kTechId.None
    self.orderParam = -1
    self.orderLocation = Vector(0, 0, 0)
    self.orderOrientation = 0
    self.orderSource = Vector(0, 0, 0)
    self.orderTime = Shared.GetTime()
    
    self:SetPropagate(Entity.Propagate_Callback)
    self:SetRelevancyDistance(Math.infinity)
    
end

function Order:OnGetIsRelevant(player)
    
    if player:GetIsCommander() then
        // Send orders if they belong to a unit is selected
        return player:GetSelectionHasOrder(self)
    elseif player:isa("Marine") or player:isa("Exo") or player:isa("Gorge") then
        // Send orders given to players to those players
        return player.GetHasSpecifiedOrder and player:GetHasSpecifiedOrder(self)
    end
    
    return false

end

function Order:Initialize(orderType, orderParam, position, orientation)

    self.orderType = orderType
    self.orderParam = orderParam
    
    if orientation then
        self.orderOrientation = orientation
    end
    
    if position then
        self.orderLocation = position
    end
    
end

function Order:OnEntityChange(oldId, newId)

    // The orderParam represents a kTechId when the order type is
    // kTechId.Build so ignore the entity change event in this case.
    if self.orderType ~= kTechId.Build and self.orderParam == oldId then
    
        if newId == nil then
            newId = Entity.invalidId
        end
        self.orderParam = newId
        
    end
    
end

function Order:SetOrderSource(vector)
    self.orderSource = vector
end

function Order:tostring()
    return string.format("Order type: %s Location: %s", GetDisplayNameForTechId(self.orderType), self:GetLocation():tostring())
end

function Order:GetType()
    return self.orderType
end

function Order:SetType(orderType)
    self.orderType = orderType
end

// The tech id of a building when order type is kTechId.Build, or the entity id for a build or weld order
// When moving to an entity specified here, add in GetHoverHeight() so MACs and Drifters stay off the ground
function Order:GetParam()
    return self.orderParam
end

local kOrderTypesUseEntityOrigin = { }
kOrderTypesUseEntityOrigin[kTechId.Weld] = true
kOrderTypesUseEntityOrigin[kTechId.AutoWeld] = true
kOrderTypesUseEntityOrigin[kTechId.Heal] = true
kOrderTypesUseEntityOrigin[kTechId.Move] = true
kOrderTypesUseEntityOrigin[kTechId.Construct] = true
function Order:GetLocation()

    local location = self.orderLocation
    
    // For move orders with an entity specified, lookup location of entity as it may have moved.
    if not location or (kOrderTypesUseEntityOrigin[self.orderType] and self.orderParam > 0) then
    
        local entity = Shared.GetEntity(self.orderParam)
        if entity ~= nil then
            location = Vector(entity:GetOrigin())
        end
        
    end
    
    return location
    
end

// When setting this location, add in GetHoverHeight() so MACs and Drifters stay off the ground
function Order:SetLocation(position)

    if self.orderLocation == nil then
        self.orderLocation = Vector()
    end
    self.orderLocation = position
    
end

// In radians - could be nil
function Order:GetOrientation()
    return self.orderOrientation
end

function Order:GetOrderTime()
    return self.orderTime
end

function CreateOrder(orderType, orderParam, position, orientation)

    local newOrder = CreateEntity(Order.kMapName)
       
    newOrder:Initialize(orderType, orderParam, position, tonumber(orientation))
    
    return newOrder
    
end

function GetOrderTargetIsConstructTarget(order, doerTeamNumber)

    if(order ~= nil) then
    
        local entity = Shared.GetEntity(order:GetParam())
                        
        if entity and (HasMixin(entity, "Construct") and ((entity:GetTeamNumber() == doerTeamNumber) or (entity:GetTeamNumber() == kTeamReadyRoom)) and not entity:GetIsBuilt()) then
        
            return entity
            
        end
        
    end
    
    return nil

end

function GetOrderTargetIsDefendTarget(order, doerTeamNumber)

    if(order ~= nil) then
    
        local entity = Shared.GetEntity(order:GetParam())
                        
        if entity ~= nil and HasMixin(entity, "Live") and (entity:GetTeamNumber() == doerTeamNumber) then
        
            return entity
            
        end
        
    end
    
    return nil

end

function GetOrderTargetIsWeldTarget(order, doerTeamNumber)

    if(order ~= nil) then
    
        local entityId = order:GetParam()
        if(entityId > 0) then
        
            local entity = Shared.GetEntity(entityId)
            if entity ~= nil and HasMixin(entity, "Weldable") and entity:GetTeamNumber() == doerTeamNumber then
                return entity
            end
            
        end
        
    end
    
    return nil

end

function GetOrderTargetIsHealTarget(order, doerTeamNumber)

    if(order ~= nil) then
    
        local entityId = order:GetParam()
        if(entityId > 0) then
        
            local entity = Shared.GetEntity(entityId)
            if entity ~= nil and HasMixin(entity, "Live") and entity:GetTeamNumber() == doerTeamNumber and entity:GetHealthScalar() < 1 then
                return entity
            end
            
        end
        
    end
    
    return nil

end

function GetCopyFromOrder(order)

    if order == nil then
    
        Print("WARNING: called GetCopyFromOrder(nil)")
        return nil
        
    end
    
    local orderCopy = CreateOrder(order.orderType, order.orderParam, order.orderLocation, order.orderOrientation)
    orderCopy:SetOwner(order:GetOwner())
    
    return orderCopy

end

Shared.LinkClassToMap("Order", Order.kMapName, networkVars)

class 'SharedOrder' (Entity)

SharedOrder.kMapName = "sharedorder"

local sharedNetworkVars = { }

function CreateSharedOrder(orderType, orderParam, position, orientation)

    local newOrder = CreateEntity(SharedOrder.kMapName)       
    newOrder:Initialize(orderType, orderParam, position, tonumber(orientation))    
    return newOrder
    
end

if Server then

    function SharedOrder:OnCreate()
    
        Order.OnCreate(self)
        self.registeredEntities = 0
    
    end

    function SharedOrder:Register(entity)    
        self.registeredEntities = self.registeredEntities + 1    
    end

    function SharedOrder:Unregister(entity)    
        self.registeredEntities = self.registeredEntities - 1
        
        if self.registeredEntities <= 0 then
            DestroyEntity(self)
        end        
    end

end

Shared.LinkClassToMap("SharedOrder", SharedOrder.kMapName, sharedNetworkVars)