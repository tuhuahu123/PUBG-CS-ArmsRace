---@class CS_Gamemode_C:GameModeBase
---@field DefaultSceneRoot USceneComponent
--Edit Below--
ugcprint("!!!!!!!!!!!!!!!!!!!! MINIMAL CS_Gamemode.lua IS BEING LOADED !!!!!!!!!!!!!!!!!!!!")

local CS_Gamemode = {}

function CS_Gamemode:BeginPlay()
    ugcprint("!!!!!!!!!!!!!!!!!!!! MINIMAL CS_Gamemode:BeginPlay EXECUTED !!!!!!!!!!!!!!!!!!!!")
    
    -- 暂时不执行任何其他操作
end

function CS_Gamemode:NotUsed() -- 只是为了让表不为空
end

--[[
function CS_Gamemode:ReceiveBeginPlay()
    CS_Gamemode.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function CS_Gamemode:ReceiveTick(DeltaTime)
    CS_Gamemode.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function CS_Gamemode:ReceiveEndPlay()
    CS_Gamemode.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function CS_Gamemode:GetReplicatedProperties()
    return
end
--]]

--[[
function CS_Gamemode:GetAvailableServerRPCs()
    return
end
--]]

return CS_Gamemode