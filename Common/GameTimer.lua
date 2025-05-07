---@class GameTimer
local GameTimer = {}

-- 核心属性
GameTimer.CurrentPhaseKey = nil      -- 当前游戏阶段键名
GameTimer.CurrentPhaseName = ""      -- 当前阶段名称 
GameTimer.PhaseStartTime = 0         -- 阶段开始时间戳
GameTimer.Duration = 0               -- 阶段总持续时间
GameTimer.RemainingTime = 0          -- 剩余时间
GameTimer.PhaseTimerHandle = nil     -- 计时器句柄
GameTimer.Listeners = {}             -- 计时器事件监听者
GameTimer.PhaseConfig = nil          -- 阶段配置数据
GameTimer.TimerDelegate = nil        -- 计时器委托对象
GameTimer.DebugMode = true           -- 调试模式开关
GameTimer.IsRunning = false         -- 新增：标记计时器是否正在运行
GameTimer.ForceFullSync = false      -- 新增：标记是否强制进行完整同步

-- 事件类型定义
GameTimer.EventType = {
    PhaseChanged = "OnPhaseChanged",         -- 阶段变更事件
    PhaseCountdownTick = "OnPhaseTick",      -- 每秒计时滴答事件
    PhaseEnd = "OnPhaseEnd"                  -- 阶段结束事件
}

-- 打印调试信息
function GameTimer:DebugLog(message)
    if self.DebugMode then
        ugcprint("[GameTimer] " .. tostring(message))
    end
end

-- 初始化计时器
function GameTimer:Initialize(phaseConfig)
    self:DebugLog("!!!!!!!!!!!!!!!!!!!! GameTimer: INITIALIZING !!!!!!!!!!!!!!!!!!!!")
    self.PhaseConfig = phaseConfig or require("Script.Config.GamePhaseConfig")
    if not self.PhaseConfig then
        self:DebugLog("错误: 无法加载阶段配置 GamePhaseConfig!")
        return false
    end
    
    -- 重置计时器状态
    self.CurrentPhaseKey = nil
    self.CurrentPhaseName = ""
    self.PhaseStartTime = 0
    self.Duration = 0
    self.RemainingTime = 0
    self.Listeners = {}
    self.IsRunning = false
    
    -- 清理已有计时器
    self:ClearTimer()
    
    self:DebugLog("!!!!!!!!!!!!!!!!!!!! GameTimer: INITIALIZED SUCCESSFULLY !!!!!!!!!!!!!!!!!!!!")
    return true
end

-- 开始一个新的阶段计时
function GameTimer:StartPhase(phaseKey)
    self:DebugLog("!!!!!!!!!!!!!!!!!!!! GameTimer: REQUEST TO START PHASE: " .. tostring(phaseKey) .. " !!!!!!!!!!!!!!!!!!!!")
    
    -- 验证阶段配置
    local phaseInfo = self.PhaseConfig[phaseKey]
    if not phaseInfo then
        self:DebugLog("错误: 找不到阶段配置: " .. tostring(phaseKey))
        return false
    end
    
    -- 更新计时器状态
    self.CurrentPhaseKey = phaseKey
    self.CurrentPhaseName = phaseInfo.PhaseName or "未知阶段"
    self.PhaseStartTime = os.time()
    self.Duration = phaseInfo.Duration or 0
    self.RemainingTime = self.Duration
    self.IsRunning = false -- 重置运行状态，将在计时器创建后设置
    
    self:DebugLog("开始阶段 " .. self.CurrentPhaseName .. " (" .. phaseKey .. "), 持续时间: " .. self.Duration .. "秒")
    
    -- 触发阶段变更事件
    self:TriggerEvent(self.EventType.PhaseChanged, phaseKey, self.CurrentPhaseName, self.Duration)
    
    -- 清除旧计时器
    self:ClearTimer()
    
    -- 如果持续时间为0，直接结束阶段
    if self.Duration <= 0 then
        self:DebugLog("阶段 " .. phaseKey .. " 持续时间为0或无效，直接结束")
        self:EndCurrentPhase()
        return true
    end
    
    -- 创建新计时器
    self:CreateTimer()
    
    -- 立即同步到客户端
    self:SyncToClients()
    
    self:DebugLog("!!!!!!!!!!!!!!!!!!!! GameTimer: StartPhase COMPLETED for " .. phaseKey .. " !!!!!!!!!!!!!!!!!!!!")
    return true
end

-- 创建计时器
function GameTimer:CreateTimer()
    self:ClearTimer()
    self:DebugLog("!!!!!!!!!!!!!!!!!!!! GameTimer: Creating K2_SetTimerDelegate !!!!!!!!!!!!!!!!!!!!")
    self.TimerDelegate = ObjectExtend.CreateDelegate(self, self.UpdateTimer, self)
    
    -- 创建计时器句柄
    self.PhaseTimerHandle = FTimerHandle.new()
    
    -- 使用标准UE4计时器API
    KismetSystemLibrary.K2_SetTimerDelegate(
        self.TimerDelegate,    -- 委托对象
        0.5,                   -- 时间间隔(秒)，改为0.5秒提高精度
        true,                  -- 是否循环(true=重复触发)
        0.0,                   -- 首次延迟(0=立即开始)
        self.PhaseTimerHandle  -- 计时器句柄引用
    )
    
    if KismetSystemLibrary.K2_IsTimerActiveHandle(self, self.PhaseTimerHandle) then
        self.IsRunning = true
        self:DebugLog("!!!!!!!!!!!!!!!!!!!! GameTimer: K2_SetTimerDelegate CREATED AND ACTIVE! Handle: " .. tostring(self.PhaseTimerHandle) .. ", Phase: " .. tostring(self.CurrentPhaseKey) .. " !!!!!!!!!!!!!!!!!!!!")
    else
        self.IsRunning = false
        self:DebugLog("!!!!!!!!!!!!!!!!!!!! GameTimer: K2_SetTimerDelegate FAILED TO ACTIVATE! Handle: " .. tostring(self.PhaseTimerHandle) .. ", Phase: " .. tostring(self.CurrentPhaseKey) .. " !!!!!!!!!!!!!!!!!!!!")
    end
    
    self:UpdateTimer() -- 立即执行一次更新
end

-- 更新计时器状态
function GameTimer:UpdateTimer()
    if not self.IsRunning and self.Duration > 0 then -- 如果计时器意外停止但阶段应该在运行，尝试重启
        self:DebugLog("警告: Timer was not running but phase is active. Attempting to restart timer for phase: " .. tostring(self.CurrentPhaseKey))
        self:CreateTimer() -- 尝试重新创建计时器
        if not self.IsRunning then -- 如果还是没成功
            self:DebugLog("错误: Failed to restart timer for phase: " .. tostring(self.CurrentPhaseKey))
            return -- 避免无限循环或错误
        end
    end

    if not self.CurrentPhaseKey or self.RemainingTime <= 0 then
        if self.IsRunning then -- 如果仍在运行但时间到了或阶段没了，则结束
             self:DebugLog("UpdateTimer: No current phase or remaining time is zero. Ending phase.")
             self:EndCurrentPhase()
        end
        return
    end

    local elapsedTime = os.time() - self.PhaseStartTime
    local newRemainingTime = math.max(0, self.Duration - elapsedTime)

    if math.floor(self.RemainingTime) ~= math.floor(newRemainingTime) or self.RemainingTime == self.Duration then
        self:DebugLog("计时更新: 阶段=" .. tostring(self.CurrentPhaseKey) .. ", 已用=" .. elapsedTime .. "s, 剩余=" .. math.floor(newRemainingTime) .. "s")
        self:TriggerEvent(self.EventType.PhaseCountdownTick, self.CurrentPhaseKey, newRemainingTime)
        self:SyncToClients()
    end
    
    self.RemainingTime = newRemainingTime

    if self.RemainingTime <= 0 then
        self:DebugLog("计时结束，触发阶段结束 for " .. tostring(self.CurrentPhaseKey))
        self:EndCurrentPhase()
    end
end

-- 结束当前阶段
function GameTimer:EndCurrentPhase()
    if not self.CurrentPhaseKey then 
        self:DebugLog("没有当前阶段，无法结束")
        return false 
    end
    
    local endedPhaseKey = self.CurrentPhaseKey
    local phaseInfo = self.PhaseConfig[endedPhaseKey]
    if not phaseInfo then 
        self:DebugLog("找不到当前阶段配置，无法结束")
        return false 
    end
    
    self:DebugLog("结束阶段: " .. (phaseInfo and phaseInfo.PhaseName or endedPhaseKey))
    
    -- 清理计时器
    self:ClearTimer()
    
    -- 触发阶段结束事件
    self:TriggerEvent(self.EventType.PhaseEnd, endedPhaseKey)
    
    -- 检查是否有下一阶段
    local nextPhaseKey = phaseInfo.NextPhase
    if nextPhaseKey and self.PhaseConfig[nextPhaseKey] then
        local restartDelay = (endedPhaseKey == "PostMatch" and self.PhaseConfig.PostMatch.RestartDelay) or 
                             (endedPhaseKey == "Preparation" and self.PhaseConfig.Preparation.RestartDelay) or 0
        
        self:DebugLog("准备在 " .. restartDelay .. " 秒后启动下一阶段: " .. nextPhaseKey)
        
        if self.NextPhaseTimerHandle then -- 清理可能存在的旧的下一阶段计时器
             KismetSystemLibrary.K2_ClearTimerHandle(self, self.NextPhaseTimerHandle)
             self.NextPhaseTimerHandle = nil
        end
        if self.NextPhaseDelegate then
            ObjectExtend.DestroyDelegate(self.NextPhaseDelegate)
            self.NextPhaseDelegate = nil
        end

        self.NextPhaseDelegate = ObjectExtend.CreateDelegate(self, function()
            self:DebugLog("下一阶段定时器触发，启动: " .. nextPhaseKey)
            self:StartPhase(nextPhaseKey)
            if self.NextPhaseTimerHandle then -- 清理自身
                 KismetSystemLibrary.K2_ClearTimerHandle(self, self.NextPhaseTimerHandle)
                 self.NextPhaseTimerHandle = nil
            end
            if self.NextPhaseDelegate then
                ObjectExtend.DestroyDelegate(self.NextPhaseDelegate)
                self.NextPhaseDelegate = nil
            end
        end, self)
        self.NextPhaseTimerHandle = FTimerHandle.new()
        KismetSystemLibrary.K2_SetTimerDelegate(self.NextPhaseDelegate, restartDelay, false, 0.0, self.NextPhaseTimerHandle)

    else
        self:DebugLog("没有下一阶段或配置错误，游戏流程结束。 Ended phase: " .. endedPhaseKey)
    end
    self.IsRunning = false
    self.CurrentPhaseKey = nil
    self.CurrentPhaseName = ""
    self.RemainingTime = 0
    return true
end

-- 清理计时器
function GameTimer:ClearTimer()
    -- 清理计时器句柄
    if self.PhaseTimerHandle then
        if KismetSystemLibrary.K2_IsTimerActiveHandle(self, self.PhaseTimerHandle) then
            self:DebugLog("清理 ACTIVE 计时器句柄: " .. tostring(self.PhaseTimerHandle))
            KismetSystemLibrary.K2_ClearTimerHandle(self, self.PhaseTimerHandle)
        else
            self:DebugLog("尝试清理 INACTIVE/NIL 计时器句柄: " .. tostring(self.PhaseTimerHandle))
        end
        self.PhaseTimerHandle = nil
    end
    
    -- 清理委托对象
    if self.TimerDelegate then
        self:DebugLog("清理委托对象")
        ObjectExtend.DestroyDelegate(self.TimerDelegate)
        self.TimerDelegate = nil
    end
    self.IsRunning = false
end

-- 同步计时器状态到客户端
function GameTimer:SyncToClients()
    -- 检查是否在服务器
    if not UGCGameSystem.IsServer() then 
        return
    end
    
    -- 获取所有玩家控制器
    local playerControllers = UGCGameSystem.GetAllPlayerController()
    if not playerControllers or #playerControllers == 0 then
        self:DebugLog("警告: 没有可用的玩家控制器，无法同步计时器状态")
        return
    end
    
    -- 调试用: 输出控制器列表
    self:DebugLog("SyncToClients: 发现 " .. #playerControllers .. " 个玩家控制器")
    
    -- 向每个玩家发送计时更新
    local successCount = 0
    for i, playerController in ipairs(playerControllers) do
        if playerController and playerController.ClientRPC_TimerUpdate then
            UnrealNetwork.CallUnrealRPC(
                playerController, 
                playerController, 
                "ClientRPC_TimerUpdate", 
                self.RemainingTime
            )
            successCount = successCount + 1
        else
            self:DebugLog("控制器 #" .. i .. " 没有ClientRPC_TimerUpdate方法")
        end
    end
    self:DebugLog("成功向 " .. successCount .. "/" .. #playerControllers .. " 个玩家发送时间更新")
    
    -- 更新GameState(如果有)
    local gameState = UGCGameSystem.GameState
    if gameState and gameState.UpdatePhaseRemainingTime then
        gameState:UpdatePhaseRemainingTime(self.RemainingTime)
        self:DebugLog("已更新GameState时间: " .. self.RemainingTime)
    else
        self:DebugLog("GameState不可用或没有UpdatePhaseRemainingTime方法")
    end
    
    -- 定期同步完整阶段信息
    if math.floor(self.RemainingTime) % 5 == 0 or self.ForceFullSync then  -- 每5秒或强制同步
        self.ForceFullSync = false  -- 重置强制同步标志
        
        local fullSyncCount = 0
        for i, playerController in ipairs(playerControllers) do
            if playerController and playerController.ClientRPC_PhaseChanged then
                UnrealNetwork.CallUnrealRPC(
                    playerController,
                    playerController,
                    "ClientRPC_PhaseChanged",
                    self.CurrentPhaseKey,
                    self.CurrentPhaseName,
                    self.RemainingTime
                )
                fullSyncCount = fullSyncCount + 1
            else
                self:DebugLog("控制器 #" .. i .. " 没有ClientRPC_PhaseChanged方法")
            end
        end
        self:DebugLog("已发送完整阶段信息到 " .. fullSyncCount .. "/" .. #playerControllers .. " 个玩家")
    end
end

-- 强制进行一次完整同步
function GameTimer:ForceFullSync()
    self:DebugLog("请求强制完整同步")
    self.ForceFullSync = true
    self:SyncToClients()
end

-- 获取格式化的剩余时间文本(例如 "01:30")
function GameTimer:GetFormattedTimeText()
    local minutes = math.floor(self.RemainingTime / 60)
    local seconds = math.floor(self.RemainingTime % 60)
    return string.format("%02d:%02d", minutes, seconds)
end

-- 获取带阶段名的格式化文本(例如 "准备阶段: 01:30")
function GameTimer:GetFullDisplayText()
    local timeText = self:GetFormattedTimeText()
    if self.CurrentPhaseName and self.CurrentPhaseName ~= "" then
        return string.format("%s: %s", self.CurrentPhaseName, timeText)
    else
        return timeText
    end
end

-- 注册事件监听者
function GameTimer:AddListener(eventType, callback, context)
    if not eventType or not callback then
        self:DebugLog("错误: 添加监听者失败，参数无效")
        return false
    end
    
    if not self.Listeners[eventType] then
        self.Listeners[eventType] = {}
    end
    
    table.insert(self.Listeners[eventType], {callback = callback, context = context})
    self:DebugLog("添加监听者成功: " .. eventType)
    return true
end

-- 移除事件监听者
function GameTimer:RemoveListener(eventType, callback, context)
    if not self.Listeners[eventType] then 
        return false 
    end
    
    for i, listener in ipairs(self.Listeners[eventType]) do
        if listener.callback == callback and listener.context == context then
            table.remove(self.Listeners[eventType], i)
            self:DebugLog("移除监听者成功: " .. eventType)
            return true
        end
    end
    
    return false
end

-- 触发事件
function GameTimer:TriggerEvent(eventType, ...)
    if not self.Listeners[eventType] then 
        return 
    end
    
    self:DebugLog("触发事件: " .. eventType .. " (监听者: " .. #self.Listeners[eventType] .. ")")
    
    for _, listener in ipairs(self.Listeners[eventType]) do
        if listener.callback then
            if listener.context then
                listener.callback(listener.context, ...)
            else
                listener.callback(...)
            end
        end
    end
    
    -- 如果引擎提供了事件系统，也通知它
    if UGCSendEvent then
        UGCSendEvent(eventType, ...)
    end
end

-- 强制设置剩余时间（用于调试）
function GameTimer:SetRemainingTime(time)
    if type(time) ~= "number" or time < 0 then
        self:DebugLog("错误: 设置剩余时间失败，参数无效")
        return false
    end
    
    self.RemainingTime = time
    self:DebugLog("手动设置剩余时间: " .. time .. "秒")
    
    -- 同步到客户端
    self:SyncToClients()
    
    return true
end

-- 手动强制同步
function GameTimer:ForceSyncToClients()
    self:DebugLog("强制同步计时器状态到客户端")
    self:SyncToClients()
    return true
end

return GameTimer 