-- GameManager.lua - 游戏管理器模块
-- 负责管理游戏逻辑，作为单例存在

local GameTimer = require('Script.Common.GameTimer')
local GamePhaseConfig = require('Script.Config.GamePhaseConfig')

local GameManager = {
    -- 单例实例
    _instance = nil,
    
    -- 游戏状态
    GameTimer = nil,
    IsInitialized = false,
    
    -- 调试
    DebugMode = true
}

-- 输出调试信息
function GameManager:DebugLog(message)
    if self.DebugMode then
        ugcprint("[GameManager] " .. tostring(message))
    end
end

-- 获取单例实例
function GameManager.GetInstance()
    if not GameManager._instance then
        GameManager._instance = {}
        setmetatable(GameManager._instance, {__index = GameManager})
    end
    return GameManager._instance
end

-- 初始化游戏管理器
function GameManager:Initialize()
    if self.IsInitialized then 
        self:DebugLog("已经初始化过，跳过")
        return true 
    end
    
    self:DebugLog("初始化游戏管理器")
    
    -- 初始化游戏计时器
    self.GameTimer = GameTimer
    if not self.GameTimer:Initialize(GamePhaseConfig) then
        self:DebugLog("错误: GameTimer初始化失败")
        return false
    end
    
    self:DebugLog("GameTimer初始化成功")
    
    -- 设置定时器定期执行一些维护任务
    self:SetupMaintenanceTimer()
    
    self.IsInitialized = true
    return true
end

-- 设置维护计时器
function GameManager:SetupMaintenanceTimer()
    self:DebugLog("设置维护计时器")
    
    if not UGCTimer or not UGCTimer.SetTimer then
        self:DebugLog("警告: UGCTimer不可用，无法设置维护计时器")
        return
    end
    
    -- 每10秒运行一次维护任务
    UGCTimer.SetTimer(function()
        self:MaintenanceTask()
    end, 10.0, true, "GameManagerMaintenance")
    
    -- 延迟3秒后强制同步一次
    UGCTimer.SetTimer(function()
        self:ForceSyncGameState()
    end, 3.0, false, "InitialForceSyncTimer")
end

-- 维护任务
function GameManager:MaintenanceTask()
    if not UGCGameSystem.IsServer() then return end
    
    self:DebugLog("执行维护任务")
    
    -- 确保GameTimer正在运行
    if self.GameTimer and not self.GameTimer.IsRunning and self.GameTimer.CurrentPhaseKey then
        self:DebugLog("检测到GameTimer未运行但有当前阶段，尝试重新创建计时器")
        self.GameTimer:CreateTimer()
    end
    
    -- 如果没有玩家，可能会导致定时器停止，所以要确保它活着
    if self.GameTimer and self.GameTimer.CurrentPhaseKey then
        self:DebugLog("强制同步GameTimer状态")
        if self.GameTimer.ForceFullSync then
            self.GameTimer:ForceFullSync()
        else
            self.GameTimer:SyncToClients()
        end
    end
end

-- 强制同步游戏状态
function GameManager:ForceSyncGameState()
    if not UGCGameSystem.IsServer() then return end
    
    self:DebugLog("强制同步游戏状态")
    
    if self.GameTimer then
        if self.GameTimer.ForceFullSync then
            self.GameTimer:ForceFullSync()
        else
            self.GameTimer:SyncToClients()
        end
    end
    
    -- 检查并确保所有客户端都收到了正确的计时信息
    local playerControllers = UGCGameSystem.GetAllPlayerController()
    self:DebugLog("发现 " .. #playerControllers .. " 个玩家控制器")
    
    for i, controller in ipairs(playerControllers) do
        if controller and controller.ClientRPC_PhaseChanged then
            local phaseKey, phaseName, timeRemaining = self:GetCurrentPhaseInfo()
            self:DebugLog("发送阶段信息给玩家 #" .. i .. ": " .. 
                          (phaseKey or "nil") .. ", " .. 
                          (phaseName or "nil") .. ", " .. 
                          (timeRemaining or 0))
                          
            UnrealNetwork.CallUnrealRPC(
                controller,
                controller,
                "ClientRPC_PhaseChanged",
                phaseKey,
                phaseName,
                timeRemaining
            )
        end
    end
end

-- 启动指定游戏阶段
function GameManager:StartPhase(phaseKey)
    if not self.GameTimer then
        self:DebugLog("错误: GameTimer未初始化")
        return false
    end
    
    self:DebugLog("启动阶段: " .. tostring(phaseKey))
    return self.GameTimer:StartPhase(phaseKey)
end

-- 获取当前游戏阶段信息
function GameManager:GetCurrentPhaseInfo()
    if not self.GameTimer then
        self:DebugLog("错误: GameTimer未初始化")
        return "Unknown", "未知阶段", 0
    end
    
    return self.GameTimer.CurrentPhaseKey, 
           self.GameTimer.CurrentPhaseName, 
           self.GameTimer.RemainingTime
end

-- 通知游戏结束
function GameManager:NotifyGameEnd(winnerID, winnerTeam)
    self:DebugLog("游戏结束! 获胜者ID: " .. tostring(winnerID) .. ", 队伍: " .. tostring(winnerTeam))
    self:StartPhase("PostMatch")
    
    -- 通知所有玩家游戏结束
    local playerControllers = UGCGameSystem.GetAllPlayerController()
    for _, controller in ipairs(playerControllers or {}) do
        if controller and controller.ClientRPC_GameEnd then
            UnrealNetwork.CallUnrealRPC(
                controller,
                controller,
                "ClientRPC_GameEnd",
                winnerID,
                winnerTeam
            )
        end
    end
end

-- 重置所有玩家的武器等级
function GameManager:ResetAllPlayerWeaponLevels()
    self:DebugLog("重置所有玩家武器等级")
    
    -- 获取所有玩家Pawn
    local players = UGCGameSystem.GetAllPlayerPawn()
    for _, pawn in ipairs(players or {}) do
        if pawn and pawn.ResetWeaponLevel then
            pawn:ResetWeaponLevel()
        end
    end
end

-- 处理客户端请求游戏阶段信息
function GameManager:HandleClientRequestPhaseInfo(controller)
    if not controller then return end
    
    local phaseKey, phaseName, timeRemaining = self:GetCurrentPhaseInfo()
    if phaseKey and controller.ClientRPC_PhaseChanged then
        self:DebugLog("响应客户端请求，发送阶段信息: " .. 
                     (phaseKey or "nil") .. ", " .. 
                     (phaseName or "nil") .. ", " .. 
                     (timeRemaining or 0))
                     
        UnrealNetwork.CallUnrealRPC(
            controller, 
            controller, 
            "ClientRPC_PhaseChanged", 
            phaseKey, 
            phaseName, 
            timeRemaining
        )
    end
end

-- 自动初始化单例
GameManager.GetInstance():Initialize()

return GameManager.GetInstance() 