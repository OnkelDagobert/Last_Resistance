// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIReadyRoomOrders.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//   Interpretes the current state of the client world and returns a list of techIds / screenPositions,
//   which can be clicked like the regular commander menu buttons.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local gGetMarineCommanderHelp = nil
local gGetAlienCommanderHelp = nil

kWorldButtonSize = GUIScale(80)


// --------- Resource Tower help function --------------------

local function GetEmptyResourceNodes( conditionFunc )

    local resultList = {}

    for _, resourceNode in ientitylist(Shared.GetEntitiesWithClassname("ResourcePoint")) do
    
        if resourceNode:GetAttached() == nil and conditionFunc(resourceNode) then

            local result = {}
            result.Position = Client.WorldToScreen(resourceNode:GetOrigin())
            result.Entity = nil
        
            table.insert(resultList, result)
            
        end
    
    end

    return resultList
    
end

local function GetExtractorIndicators()

    local conditionFunc = function(resourceNode)    
        return #GetEntitiesWithinRange("Marine", resourceNode:GetOrigin(), 15) > 0 or #GetEntitiesWithinRange("MAC", resourceNode:GetOrigin(), 15) > 0
    end
    
    return GetEmptyResourceNodes( conditionFunc )

end

local function GetHarvesterIndicators()

    local conditionFunc = function(resourceNode)    
        return GetIsPointOnInfestation( resourceNode:GetOrigin(), kTechId.Harvester )
    end
    
    return GetEmptyResourceNodes( conditionFunc )
    
end

// --------- tech utility functions --------------------------------------

local function GetShowResearch(techId)

    local localPlayer = Client.GetLocalPlayer()
    
    if localPlayer then        
        return not GetIsTechResearched(localPlayer:GetTeamNumber(), techId) and not GetIsTechResearching(localPlayer, techId)        
    end

end

local function GetResearchList(className, techId, xOffset, yOffset)

    local resultList = {}
    xOffset = xOffset or 0
    yOffset = yOffset or 0
    
    if GetShowResearch(techId) then
    
        for _, researchStructure in ientitylist( Shared.GetEntitiesWithClassname(className) ) do
        
            if researchStructure:GetCanResearch(techId) then
            
                local entry = {}
                entry.Position = Client.WorldToScreen(researchStructure:GetOrigin()) + Vector(xOffset, yOffset, 0)
                entry.Entity = researchStructure
            
                table.insert(resultList, entry)
            
            end
        
        end

    end

    return resultList

end

local function GetResearchHelpFunction(className, techId, xOffset, yOffset)
    return function() return GetResearchList(className, techId, xOffset, yOffset) end
end

// --------- upgrade help functions --------------------------------------

local function GetUpgradeList(className, techId, upgradedId, xOffset)

    local localPlayer = Client.GetLocalPlayer()
    local resultList = {}
    
    if localPlayer and not GetHasTech(localPlayer, upgradedId) and not GetIsTechResearching(localPlayer, techId) then
    
        for _, upgradeAble in ientitylist( Shared.GetEntitiesWithClassname(className) ) do
        
            local defaultTechId = LookupTechId(upgradeAble:GetMapName(), kTechDataMapName, kTechId.None)
            if upgradeAble:GetCanResearch(techId) and upgradeAble:GetTechId() == defaultTechId then 
                
                local entry = {}
                entry.Position = Client.WorldToScreen(upgradeAble:GetOrigin()) + Vector(xOffset, 0, 0)
                entry.Entity = upgradeAble
           
                table.insert(resultList, entry)            
            end
        
        end
    
    end
    
    return resultList

end

local function GetUpgradeHelpFunction(className, techId, upgradedId, xOffset)
    return function() return GetUpgradeList(className, techId, upgradedId, xOffset) end
end

// --------- base structure help functions --------------------

local function GetClosestCommStructure()

    local localPlayer = Client.GetLocalPlayer()
    local closestCommStructure = nil
    
    if localPlayer then
    
        local commStructures = GetEntitiesForTeam("CommandStructure", localPlayer:GetTeamNumber())
        Shared.SortEntitiesByDistance(localPlayer:GetOrigin(), commStructures)
        
        for _, commStructure in ipairs(commStructures) do
        
            if GetIsUnitActive(commStructure) then
                closestCommStructure = commStructure
                break
            end
        
        end
    
    end

    return closestCommStructure

end

local function GetIsStructureInRange(techId)

    local localPlayer = Client.GetLocalPlayer()
    if localPlayer then
    
        for _, structure in ipairs(GetEntitiesWithMixinForTeam("Construct", localPlayer:GetTeamNumber())) do

            if HasMixin(structure, "Tech") and structure:GetTechId() == techId then  
                return true 
            end
       
        end
        
    end

    return false

end

local gCachedRandomPos = nil
local gUsedCommStructureOrigin = Vector(0,0,0)
local gTimeLastUpdate = 0
local gLastSingletonTechId = kTechId.None

local function GetPlaceInBaseForTechIdSingleton(techId)

    if gTimeLastUpdate ~= Shared.GetTime() and not GetHasTech(Client.GetLocalPlayer(), techId) and not GetIsStructureInRange(techId) then

        local closestCommStructure = GetClosestCommStructure()
    
        if closestCommStructure and ( not gCachedRandomPos or closestCommStructure:GetOrigin() ~= gUsedCommStructureOrigin or gLastSingletonTechId ~= techId ) then
        
            local extents = GetExtents(techId)
            gUsedCommStructureOrigin = closestCommStructure:GetOrigin()
            
            local validationFunc = LookupTechData(techId, kTechDataRequiresInfestation, nil) and GetIsPointOnInfestation or nil
            gCachedRandomPos = GetRandomSpawnForCapsule(extents.y, extents.x, closestCommStructure:GetOrigin(), 3.5, 18, EntityFilterAll(), validationFunc)
    
        end
        
        if gCachedRandomPos then
        
            gTimeLastUpdate = Shared.GetTime()
            gLastSingletonTechId = techId
            return {{ Position = Client.WorldToScreen(gCachedRandomPos) }}
            
        end
    
    end
    
    return {}  

end

local function GetBaseStructureHelpFunction(techId)
    return function() return GetPlaceInBaseForTechIdSingleton(techId) end
end

// --------- CommandStructure help functions --------------------

local function GetEmptyTechPoints( conditionFunc, TechId )

    local resultList = {}
    
    local gameInfoEnt = GetGameInfoEntity()
    
    // only show 2nd command structure after 5 minutes
    if gameInfoEnt and gameInfoEnt:GetGameStarted() and Shared.GetTime() - gameInfoEnt:GetStartTime() > 300 then

        for _, techPoint in ientitylist(Shared.GetEntitiesWithClassname("TechPoint")) do
        
            local attached = techPoint:GetAttached()
        
            if ( not attached or (GetAreEnemies(Client.GetLocalPlayer(), techPoint) and not attached:GetIsSighted()) ) and 
               ( not conditionFunc or conditionFunc(techPoint) ) then

                local result = {}
                result.Position = Client.WorldToScreen(techPoint:GetOrigin())
                result.Entity = nil
            
                table.insert(resultList, result)
                
            end
        
        end
    
    end

    return resultList
    
end

local function GetCommandStationHint()

    local conditionFunc = function(resourceNode)    
        return #GetEntitiesWithinRange("Marine", resourceNode:GetOrigin(), 15) > 0 or #GetEntitiesWithinRange("MAC", resourceNode:GetOrigin(), 15) > 0
    end
    
    return GetEmptyTechPoints(conditionFunc)

end

local function GetHiveHint()
    return GetEmptyTechPoints(nil)
end

// ------------- marine comm support -----------------

local function GetRequiresAmmo(marine)

    local weapon = marine:GetActiveWeapon()
    if weapon and weapon:isa("ClipWeapon") then
        return weapon:GetAmmo() < weapon:GetClipSize()
    end

    return false    
 
end

local function GetAmmoHelpFunction()

    local resultList = {}

    for _, marine in ientitylist(Shared.GetEntitiesWithClassname("Marine")) do
    
        if marine:GetIsAlive() and GetRequiresAmmo(marine) then
        
            local entry = {}
            entry.Position = Client.WorldToScreen(marine:GetOrigin()) - Vector(kWorldButtonSize *.5, 0, 0)
            table.insert(resultList, entry )
        
        end
        
    end

    return resultList

end

local function GetMedpackHelpFunction()

    local resultList = {}

    for _, marine in ientitylist(Shared.GetEntitiesWithClassname("Marine")) do
    
        if marine:GetIsAlive() and marine:GetHealth() < 40 then
        
            local entry = {}
            entry.Position = Client.WorldToScreen(marine:GetOrigin()) - Vector(kWorldButtonSize *.5, 0, 0)
            table.insert(resultList, entry )
            
        end
    
    end

    return resultList

end

local function GetClosestHive()

    local localPlayer = Client.GetLocalPlayer()

    if localPlayer then

        local hives = GetEntitiesForTeam("Hive", localPlayer:GetTeamNumber())
        Shared.SortEntitiesByDistance(localPlayer:GetOrigin(), hives)
        
        for _, hive in ipairs(hives) do
        
            if GetIsUnitActive(hive) then
                return hive
            end    
        
        end
    
    end

end

local gLastCystOrigin = Vector(0,0,0)
local gCachedCystHelp = nil

local function GetCystHelpFunction()

    local localPlayer = Client.GetLocalPlayer()

    if localPlayer then
    
        local cysts = GetEntitiesForTeamWithinRange("Cyst", localPlayer:GetTeamNumber(), localPlayer:GetOrigin(), 60)
        Shared.SortEntitiesByDistance(localPlayer:GetOrigin(), cysts)
        
        if #cysts == 0 then
        
            local hive = GetClosestHive()
                        if hive and ( hive:GetOrigin() ~= gLastCystOrigin or not gCachedCystHelp ) then
            
                local extents = GetExtents(kTechId.Hive)
                gLastCystOrigin = hive:GetOrigin()
                gCachedCystHelp = GetRandomSpawnForCapsule(extents.y, extents.x, hive:GetOrigin(), 5, 25, EntityFilterAll(), nil)
            
            end
        
        else

            for _, cyst in ipairs(cysts) do

                if not cyst:GetHasChild() and cyst:GetIsConnected() then
                
                    if cyst:GetOrigin() ~= gLastCystOrigin or not gCachedCystHelp then
                    
                        local extents = GetExtents(kTechId.Cyst)
                        gLastCystOrigin = cyst:GetOrigin()
                        gCachedCystHelp = GetRandomSpawnForCapsule(extents.y, extents.x, cyst:GetOrigin(), 5, 25, EntityFilterAll(), GetIsPointOffInfestation)
                        
                    end
                    
                    break
                
                end

            end
        
        end
    
    end
    
    if gCachedCystHelp then
        return {{ Position = Client.WorldToScreen(gCachedCystHelp) }}
    else
        return {}
    end

end

// #######################################################

local function BuildCommanderHelpFunctions()

    gGetMarineCommanderHelp = {}
    gGetAlienCommanderHelp = {}
    
    // marine help functions
    
    table.insert(gGetMarineCommanderHelp, {kTechId.Extractor, GetExtractorIndicators} )
    table.insert(gGetMarineCommanderHelp, {kTechId.InfantryPortal, GetBaseStructureHelpFunction(kTechId.InfantryPortal)} )
    table.insert(gGetMarineCommanderHelp, {kTechId.Armory, GetBaseStructureHelpFunction(kTechId.Armory)} )
    table.insert(gGetMarineCommanderHelp, {kTechId.ShotgunTech, GetResearchHelpFunction("Armory", kTechId.ShotgunTech, -kWorldButtonSize * .5) })
    table.insert(gGetMarineCommanderHelp, {kTechId.Observatory, GetBaseStructureHelpFunction(kTechId.Observatory)} )
    table.insert(gGetMarineCommanderHelp, {kTechId.PhaseTech, GetResearchHelpFunction("Observatory", kTechId.PhaseTech, 0) })
    table.insert(gGetMarineCommanderHelp, {kTechId.PhaseGate, GetBaseStructureHelpFunction(kTechId.PhaseGate)} )

    table.insert(gGetMarineCommanderHelp, {kTechId.ArmsLab, GetBaseStructureHelpFunction(kTechId.ArmsLab)} )
    table.insert(gGetMarineCommanderHelp, {kTechId.PrototypeLab, GetBaseStructureHelpFunction(kTechId.PrototypeLab)} )
    table.insert(gGetMarineCommanderHelp, {kTechId.AdvancedArmoryUpgrade, GetUpgradeHelpFunction("Armory", kTechId.AdvancedArmoryUpgrade, kTechId.AdvancedArmory, kWorldButtonSize * .5)} )
    
    table.insert(gGetMarineCommanderHelp, {kTechId.Weapons1, GetResearchHelpFunction("ArmsLab", kTechId.Weapons1, -kWorldButtonSize * .5) })
    table.insert(gGetMarineCommanderHelp, {kTechId.Weapons2, GetResearchHelpFunction("ArmsLab", kTechId.Weapons2, -kWorldButtonSize * .5) })
    table.insert(gGetMarineCommanderHelp, {kTechId.Weapons3, GetResearchHelpFunction("ArmsLab", kTechId.Weapons3, -kWorldButtonSize * .5) })
    table.insert(gGetMarineCommanderHelp, {kTechId.Armor1, GetResearchHelpFunction("ArmsLab", kTechId.Armor1, kWorldButtonSize * .5) })
    table.insert(gGetMarineCommanderHelp, {kTechId.Armor2, GetResearchHelpFunction("ArmsLab", kTechId.Armor2, kWorldButtonSize * .5) })
    table.insert(gGetMarineCommanderHelp, {kTechId.Armor3, GetResearchHelpFunction("ArmsLab", kTechId.Armor3, kWorldButtonSize * .5) })

    table.insert(gGetMarineCommanderHelp, {kTechId.JetpackTech, GetResearchHelpFunction("PrototypeLab", kTechId.JetpackTech, -kWorldButtonSize * .5) })
    table.insert(gGetMarineCommanderHelp, {kTechId.ExosuitTech, GetResearchHelpFunction("PrototypeLab", kTechId.ExosuitTech, kWorldButtonSize * .5) })
    table.insert(gGetMarineCommanderHelp, {kTechId.DualMinigunTech, GetResearchHelpFunction("PrototypeLab", kTechId.DualMinigunTech, kWorldButtonSize * .5) })

    table.insert(gGetMarineCommanderHelp, {kTechId.MedPack, GetMedpackHelpFunction})
    table.insert(gGetMarineCommanderHelp, {kTechId.AmmoPack, GetAmmoHelpFunction})
    
    table.insert(gGetMarineCommanderHelp, {kTechId.CommandStation, GetCommandStationHint})
    
    // alien help functions
  
    table.insert(gGetAlienCommanderHelp, {kTechId.Harvester, GetHarvesterIndicators} )
    table.insert(gGetAlienCommanderHelp, {kTechId.UpgradeToCragHive, GetUpgradeHelpFunction("Hive", kTechId.UpgradeToCragHive, kTechId.CragHive, -kWorldButtonSize)} )
    table.insert(gGetAlienCommanderHelp, {kTechId.UpgradeToShiftHive, GetUpgradeHelpFunction("Hive", kTechId.UpgradeToShiftHive, kTechId.ShiftHive, 0)} )
    table.insert(gGetAlienCommanderHelp, {kTechId.UpgradeToShadeHive, GetUpgradeHelpFunction("Hive", kTechId.UpgradeToShadeHive, kTechId.ShadeHive, kWorldButtonSize)} )
    
    table.insert(gGetAlienCommanderHelp, {kTechId.Shell, GetBaseStructureHelpFunction(kTechId.Shell)} )
    table.insert(gGetAlienCommanderHelp, {kTechId.Spur, GetBaseStructureHelpFunction(kTechId.Spur)} )
    table.insert(gGetAlienCommanderHelp, {kTechId.Veil, GetBaseStructureHelpFunction(kTechId.Veil)} )

    table.insert(gGetAlienCommanderHelp, {kTechId.UpgradeCarapaceShell, GetUpgradeHelpFunction("Shell", kTechId.UpgradeCarapaceShell, kTechId.CarapaceShell, -kWorldButtonSize *.5)} )
    table.insert(gGetAlienCommanderHelp, {kTechId.UpgradeRegenerationShell, GetUpgradeHelpFunction("Shell", kTechId.UpgradeRegenerationShell, kTechId.RegenerationShell, kWorldButtonSize *.5)} )

    table.insert(gGetAlienCommanderHelp, {kTechId.UpgradeCeleritySpur, GetUpgradeHelpFunction("Spur", kTechId.UpgradeCeleritySpur, kTechId.CeleritySpur, -kWorldButtonSize)} )
    table.insert(gGetAlienCommanderHelp, {kTechId.UpgradeAdrenalineSpur, GetUpgradeHelpFunction("Spur", kTechId.UpgradeAdrenalineSpur, kTechId.AdrenalineSpur, 0)} )
    table.insert(gGetAlienCommanderHelp, {kTechId.UpgradeHyperMutationSpur, GetUpgradeHelpFunction("Spur", kTechId.UpgradeHyperMutationSpur, kTechId.HyperMutationSpur, kWorldButtonSize)} )

    table.insert(gGetAlienCommanderHelp, {kTechId.UpgradeSilenceVeil, GetUpgradeHelpFunction("Veil", kTechId.UpgradeSilenceVeil, kTechId.SilenceVeil, -kWorldButtonSize)} )
    table.insert(gGetAlienCommanderHelp, {kTechId.UpgradeCamouflageVeil, GetUpgradeHelpFunction("Veil", kTechId.UpgradeCamouflageVeil, kTechId.CamouflageVeil, 0)} )
    table.insert(gGetAlienCommanderHelp, {kTechId.UpgradeFeintVeil, GetUpgradeHelpFunction("Veil", kTechId.UpgradeFeintVeil, kTechId.FeintVeil, kWorldButtonSize)} )

    table.insert(gGetAlienCommanderHelp, {kTechId.Leap, GetResearchHelpFunction("Hive", -kTechId.Leap, -kWorldButtonSize * .5, -kWorldButtonSize) })
    table.insert(gGetAlienCommanderHelp, {kTechId.BileBomb, GetResearchHelpFunction("Hive", -kTechId.BileBomb, kWorldButtonSize * .5, -kWorldButtonSize) })
    
    
    table.insert(gGetAlienCommanderHelp, {kTechId.Cyst, GetCystHelpFunction})
    
    table.insert(gGetAlienCommanderHelp, {kTechId.Hive, GetHiveHint})

end

// function returns a list of worldbutton info:
// { TechId, Position, Entity }

function CommanderHelp_GetWorldButtons()

    local localPlayer = Client.GetLocalPlayer()
    local useFunctions = nil
    local worldButtons = {}
    
    if not gGetMarineCommanderHelp or not gGetAlienCommanderHelp then
        BuildCommanderHelpFunctions()
    end
    
    if localPlayer then
    
        if GetIsMarineUnit(localPlayer) then
            useFunctions = gGetMarineCommanderHelp    
        elseif GetIsAlienUnit(localPlayer) then
            useFunctions = gGetAlienCommanderHelp   
        end
        
        local teamNumber = localPlayer:GetTeamNumber()
        
        for i = 1, #useFunctions do
        
            local entry = useFunctions[i]
        
            local techId = entry[1]
            local helpFunc = entry[2]
        
            if GetCostForTech(techId) <= localPlayer:GetTeamResources() and GetIsTechAvailable(teamNumber, techId) then
        
                local resultList = helpFunc()
                for j = 1, #resultList do
                    table.insert(worldButtons, { TechId = techId, Position = resultList[j].Position, Entity = resultList[j].Entity })
                end
            
            end
        
        end
    
    end
    
    return worldButtons

end

local function GetShowCommanderWidget(commander)
    return Client.GetOptionBoolean( "commanderHelp", true )
end

function CommanderHelp_GetShowWorldButtons()

    local commander = Client.GetLocalPlayer()
    local showButtons = false
    
    if commander and commander:isa("Commander") then    
        showButtons = not commander:GetShowGhostModel() and GetShowCommanderWidget(commander) and 
                      commander:GetTimeLastTargetedAction() + 1 < Shared.GetTime()
    end
    
    return showButtons 

end

function CommanderHelp_ProccessTechIdAction(techId, entity)

    local commander = Client.GetLocalPlayer()
    
    if commander and commander:isa("Commander") then
    
        local menuTechId = commander:GetMenuTechIdFor(techId) or kTechId.RootMenu
        local buttonTable = nil

        if menuTechId == kTechId.RootMenu and entity and commander:GetIsEntityValidForSelection(entity) then
        
            commander:InternalSetSelection( { {entity:GetId(), Shared.GetTime()} } )
            Client.SendNetworkMessage("SelectId", BuildSelectIdMessage(entity:GetId()), true)
            if entity.GetMenuTechIdFor then
                
                menuTechId = entity:GetMenuTechIdFor(techId)
                if menuTechId then
                    commander:SetCurrentTech(menuTechId)
                end
                
            end
            
        elseif menuTechId then        
            commander:SetCurrentTech(menuTechId)        
        end

        commander:SetCurrentTech(techId)
        
    end

end

