---@class UI_daojihi_C:UUserWidget
---@field Countdown UTextBlock
--Edit Below--
local UI_daojihi = {}

-- 构造函数，UI初始化时调用
function UI_daojihi:Construct()
    ugcprint("[UI_daojihi] Construct - 初始化")
    self.currentPhaseName = ""
    self.timeRemaining = 0
    self.hasReceivedInitialPhase = false -- 标记是否已收到初始阶段信息
    self.requestAttemptCount = 0 -- 请求尝试计数
    self.debugMode = true -- 开启调试日志
    
    -- 获取UI组件
    self.Countdown = self:GetWidgetFromName("Countdown")
    if not self.Countdown then
        ugcprint("[UI_daojihi] 错误: 无法获取Countdown组件")
    else
        ugcprint("[UI_daojihi] 成功获取Countdown组件")
        self:UpdateDisplay("等待同步", "00:00") -- 初始显示
    end
    
    -- 注册客户端RPC
    self:RegisterClientRPCs()
    
    -- 启动计时器
    self:StartTimer() -- UI本地计时器，用于平滑显示和在未收到服务器更新时做fallback
    
    -- 启动重复请求计时器
    self:StartRequestTimer()
end

-- 调试日志
function UI_daojihi:DebugLog(message)
    if self.debugMode then
        ugcprint("[UI_daojihi] " .. tostring(message))
    end
end

-- 注册客户端RPC
function UI_daojihi:RegisterClientRPCs()
    local controller = UGCGameSystem.GetLocalPlayerController()
    if not controller then
        ugcprint("[UI_daojihi] 错误: 无法获取本地控制器，RPC注册失败")
        return
    end
    
    -- 阶段变更RPC
    controller.ClientRPC_PhaseChanged = function(ctrl, phaseKey, phaseName, duration)
        ugcprint("[UI_daojihi] !!收到PhaseChanged RPC!!: Key=" .. tostring(phaseKey) .. ", Name=" .. tostring(phaseName) .. ", Duration=" .. tostring(duration))
        self:OnPhaseChanged(phaseKey, phaseName, duration)
    end
    
    -- 计时器更新RPC
    controller.ClientRPC_TimerUpdate = function(ctrl, remainingTime)
        self:DebugLog("收到TimerUpdate RPC: RemainingTime=" .. tostring(remainingTime))
        self:OnTimerUpdate(remainingTime)
    end
    
    ugcprint("[UI_daojihi] 客户端RPC注册完成")
end

-- 启动请求计时器
function UI_daojihi:StartRequestTimer()
    self:DebugLog("启动请求计时器")
    
    -- 立即请求一次
    self:RequestInitialGamePhaseInfo()
    
    -- 创建定时请求计时器
    if not self._requestTimer then
        self._requestTimer = UGCTimer.SetTimer(function()
            if not self.hasReceivedInitialPhase then
                self:RequestInitialGamePhaseInfo()
            end
        end, 2.0, true, "DaojishiRequestTimer")
    end
end

-- 启动计时器
function UI_daojihi:StartTimer()
    -- 创建计时器委托
    self.uiTimerDelegate = ObjectExtend.CreateDelegate(self, self.OnUITimerTick, self)
    
    -- 创建计时器
    self.uiTimerHandle = FTimerHandle.new()
    KismetSystemLibrary.K2_SetTimerDelegate(
        self.uiTimerDelegate,
        0.5,  -- 每0.5秒更新一次
        true, -- 循环
        0.0,  -- 无延迟
        self.uiTimerHandle
    )
    
    ugcprint("[UI_daojihi] UI本地更新计时器已启动")
end

-- 处理阶段变更RPC
function UI_daojihi:OnPhaseChanged(phaseKey, phaseName, duration)
    self.currentPhaseName = phaseName or ""
    self.timeRemaining = duration or 0
    self.hasReceivedInitialPhase = true
    self.requestAttemptCount = 0 -- 重置请求计数
    
    -- 停止请求计时器
    if self.requestTimerHandle then
        KismetSystemLibrary.K2_ClearTimerHandle(self, self.requestTimerHandle)
        self.requestTimerHandle = nil
    end
    
    self:UpdateTimerDisplay()
    self:PlayPhaseTransitionEffects(phaseKey)
    
    self:DebugLog("阶段已更新: " .. tostring(phaseKey) .. ", 时间: " .. tostring(duration))
end

-- 处理计时器更新RPC
function UI_daojihi:OnTimerUpdate(remainingTime)
    if self.hasReceivedInitialPhase then -- 只有在收到过初始阶段信息后才接受服务器的精确时间
        self.timeRemaining = remainingTime or 0
        self:UpdateTimerDisplay()
    else
        -- 可能我们错过了初始阶段信息，尝试重新请求
        self:DebugLog("收到时间更新但未有阶段信息，请求阶段信息")
        self:RequestInitialGamePhaseInfo()
    end
end

-- 计时器回调
function UI_daojihi:OnUITimerTick()
    if self.hasReceivedInitialPhase then -- 如果已从服务器同步过
        if self.timeRemaining > 0 then
            self.timeRemaining = math.max(0, self.timeRemaining - 0.5)
            self:UpdateTimerDisplay()
        end
    else
        -- 如果长时间未收到服务器信息，可以更新特定提示
        local waitingText = "等待同步"
        if self.requestAttemptCount > 0 then
            waitingText = waitingText .. "." .. string.rep(".", (self.requestAttemptCount % 3))
        end
        self:UpdateDisplay(waitingText, "--:--")
    end
end

-- 更新倒计时显示
function UI_daojihi:UpdateTimerDisplay()
    if not self.hasReceivedInitialPhase then
        self:DebugLog("尚未收到阶段信息，使用默认显示")
        self:UpdateDisplay("等待同步", "--:--")
        return
    end
    
    local minutes = math.floor(self.timeRemaining / 60)
    local seconds = math.floor(self.timeRemaining % 60)
    self:UpdateDisplay(self.currentPhaseName, string.format("%02d:%02d", minutes, seconds))
end

-- 更新显示文本
function UI_daojihi:UpdateDisplay(phaseText, timeText)
    if not self.Countdown then
        self.Countdown = self:GetWidgetFromName("Countdown")
        if not self.Countdown then
            ugcprint("[UI_daojihi] 错误: 无法获取Countdown组件")
            return
        end
    end
    
    local displayText = ""
    if phaseText and phaseText ~= "" then
        displayText = phaseText .. ": " .. timeText
    else
        displayText = timeText
    end
    
    self:DebugLog("更新显示: " .. displayText)
    self.Countdown:SetText(displayText)
end

-- 请求服务器游戏阶段信息
function UI_daojihi:RequestInitialGamePhaseInfo()
    if self.hasReceivedInitialPhase then 
        self:DebugLog("已收到阶段信息，不再请求")
        return 
    end

    self.requestAttemptCount = self.requestAttemptCount + 1
    self:DebugLog("请求初始游戏阶段信息 (尝试次数: " .. self.requestAttemptCount .. ")")
    
    -- 尝试通过GameManager获取阶段信息
    local GameManager = require('Script.Common.GameManager')
    if GameManager and GameManager.IsInitialized then
        self:DebugLog("尝试从GameManager获取阶段信息")
        local phaseKey, phaseName, timeRemaining = GameManager:GetCurrentPhaseInfo()
        if phaseKey and phaseKey ~= "Unknown" then
            self:DebugLog("从GameManager获取阶段信息成功")
            self:OnPhaseChanged(phaseKey, phaseName, timeRemaining)
            return
        end
    end
    
    -- 尝试标准方法：通过PlayerController请求
    local controller = UGCGameSystem.GetLocalPlayerController()
    if controller and controller.RequestGamePhaseInfo then
        self:DebugLog("通过PlayerController请求阶段信息")
        controller:RequestGamePhaseInfo() 
    else
        self:DebugLog("请求失败: controller 或 RequestGamePhaseInfo 不可用")
    end
end

-- 播放阶段切换效果
function UI_daojihi:PlayPhaseTransitionEffects(phaseKey)
    local message = ""
    if phaseKey == "Preparation" then message = "准备阶段开始!"
    elseif phaseKey == "InProgress" then message = "游戏开始!"
    elseif phaseKey == "PostMatch" then message = "游戏结束!"
    end
    if message ~= "" then
        UGCScreenMessageSystem.ShowScreenMessage(message, 3.0, {R=0.2, G=0.8, B=0.2, A=1})
    end
end

-- 组件销毁
function UI_daojihi:Destruct()
    -- 清理计时器
    if self.uiTimerHandle then
        KismetSystemLibrary.K2_ClearTimerHandle(self, self.uiTimerHandle)
        self.uiTimerHandle = nil
    end
    
    if self.uiTimerDelegate then
        ObjectExtend.DestroyDelegate(self.uiTimerDelegate)
        self.uiTimerDelegate = nil
    end
    
    if self.requestTimerHandle then
        KismetSystemLibrary.K2_ClearTimerHandle(self, self.requestTimerHandle)
        self.requestTimerHandle = nil
    end
    
    if self._requestTimer and UGCTimer and UGCTimer.ClearTimer then
        UGCTimer.ClearTimer(self._requestTimer)
        self._requestTimer = nil
    end
    
    ugcprint("[UI_daojihi] 组件已销毁")
end

return UI_daojihi