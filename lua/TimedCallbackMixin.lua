// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\TimedCallbackMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

TimedCallbackMixin = CreateMixin( TimedCallbackMixin )
TimedCallbackMixin.type = "TimedCallback"

function TimedCallbackMixin:__initmixin()

    self.timedCallbacks = { }
    
end

function TimedCallbackMixin:AddTimedCallback(addFunction, callRate)

    table.insert(self.timedCallbacks, { Function = addFunction, Rate = callRate, Time = 0 })

end
AddFunctionContract(TimedCallbackMixin.AddTimedCallback,
                    { Arguments = { "Entity", "function", "number" }, Returns = { } })

local function RemoveCallbacks(self, removeCallbacks)

    for _, removeCallback in ipairs(removeCallbacks) do
    
        // Find the callback in the timedCallbacks list.
        for index, timedCallback in ipairs(self.timedCallbacks) do
        
            if timedCallback == removeCallback then
                table.remove(self.timedCallbacks, index)
            end
            
        end
        
    end

end

local function SharedUpdate(self, deltaTime)

    local removeCallbacks = { }
    for index, callback in ipairs(self.timedCallbacks) do
    
        callback.Time = callback.Time + deltaTime
        local numberOfIterations = 0
        while callback.Time >= callback.Rate and numberOfIterations < 3 do
        
            callback.Time = callback.Time - callback.Rate
            local continueCallback, atRate = callback.Function(self, callback.Rate)
            if atRate then
                callback.Rate = atRate
            end
            
            if not continueCallback then
            
                table.insert(removeCallbacks, callback)
                break
                
            end
            numberOfIterations = numberOfIterations + 1
            
        end
        
    end
    
    RemoveCallbacks(self, removeCallbacks)
    
end

function TimedCallbackMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end
AddFunctionContract(TimedCallbackMixin.OnUpdate, { Arguments = { "Entity", "number" }, Returns = { } })

function TimedCallbackMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end
AddFunctionContract(TimedCallbackMixin.OnProcessMove, { Arguments = { "Entity", "Move" }, Returns = { } })