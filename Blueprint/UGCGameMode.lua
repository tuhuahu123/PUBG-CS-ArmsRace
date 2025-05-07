ugcprint("!!!!!!!!!!!!!!!!!!!! UGCGameMode.lua IS BEING LOADED !!!!!!!!!!!!!!!!!!!!")

-- 引入游戏管理器，所有游戏逻辑都在管理器中实现
local GameManager = require('Script.Common.GameManager')

local UGCGameMode = {}

-- 游戏模式初始化，仅调用GameManager
function UGCGameMode:BeginPlay()
    -- 确保GameManager已初始化
    if not GameManager.IsInitialized then
        GameManager:Initialize()
    end
    
    -- 只在服务器上启动游戏阶段
    if UGCGameSystem.IsServer() then
        GameManager:StartPhase("Preparation")
    end
end

-- 以下方法只是简单地转发到GameManager，保持API兼容性

function UGCGameMode:StartPhase(phaseKey)
    return GameManager:StartPhase(phaseKey)
end

function UGCGameMode:GetCurrentPhaseInfo()
    return GameManager:GetCurrentPhaseInfo()
end

function UGCGameMode:NotifyGameEnd(winnerID, winnerTeam)
    return GameManager:NotifyGameEnd(winnerID, winnerTeam)
end

function UGCGameMode:ResetAllPlayerWeaponLevels()
    return GameManager:ResetAllPlayerWeaponLevels()
end

-- 服务器RPC处理
function UGCGameMode:ServerRPC_RequestPhaseInfo(controller)
    return GameManager:HandleClientRequestPhaseInfo(controller)
end

-- 导出可调用的服务器RPC
function UGCGameMode:GetAvailableServerRPCs()
    return
    "ServerRPC_RequestPhaseInfo"
end

return UGCGameMode