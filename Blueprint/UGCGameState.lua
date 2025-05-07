---@class UGCGameState_C:BP_UGCGameState_C
--Edit Below--
UGCGameSystem.UGCRequire('Script.Common.ue_enum_custom')   -- 引入自定义枚举

-- 确保UGCTimer可用
if not UGCTimer then
    -- 绿洲启元编辑器中的计时器系统
    UGCTimer = {}
    
    -- 检测可用的定时器API
    local timerAPI = nil
    if _G.UGC and _G.UGC.InsertTimer then
        timerAPI = _G.UGC
    elseif UGC and UGC.InsertTimer then
        timerAPI = UGC
    end
    
    if timerAPI then
        -- 设置定时器函数
        UGCTimer.SetTimer = function(callback, interval, isRepeat, handle)
            return timerAPI.InsertTimer(interval, callback, isRepeat, handle or "")
        end
        
        -- 清除定时器函数
        UGCTimer.ClearTimer = function(handle)
            if handle then
                timerAPI.RemoveTimer(handle)
            end
        end
    else
        -- 空实现避免错误
        UGCTimer.SetTimer = function() return nil end
        UGCTimer.ClearTimer = function() end
    end
    
    ugcprint("[UGCGameState] 初始化UGCTimer完成")
end

local GameInit = require('Script.Common.GameInit')  -- 引入游戏初始化模块

local UGCGameState = {}; 

-- 隐藏部分和平自带的UI
local function HideOriginalUI()
    local MainControlPanelUI = UGCWidgetManagerSystem.GetMainUI()

    if MainControlPanelUI == nil then
        ugcprint("[UGCGameState] 警告: 无法获取MainControlPanelUI")
        return
    end

    local ShootingUIPanel = MainControlPanelUI.ShootingUIPanel
    local MainControlBaseUI = MainControlPanelUI.MainControlBaseUI

    if ShootingUIPanel then
        ShootingUIPanel.MultiLayer_RightWeaponSlot:AddAdvancedCollapsedCount(1)	 -- 右枪械栏
        ShootingUIPanel.Customize_ThrowPlus:AddAdvancedCollapsedCount(1)         -- 投掷模式
    end
    
    if MainControlBaseUI then
        MainControlBaseUI.Image_0:AddAdvancedCollapsedCount(1)                   -- 顶部三角标
        MainControlBaseUI.NavigatorPanel:AddAdvancedCollapsedCount(1)            -- 顶部指南标
        MainControlBaseUI.CanvasPanel_MiniMapAndSetting:AddAdvancedCollapsedCount(1)    -- 小地图
        MainControlBaseUI.CanvasPanelSurviveKill:AddAdvancedCollapsedCount(1)    -- 存活人数
        MainControlBaseUI.Image_IngameLogo:AddAdvancedCollapsedCount(1)          -- 和平顶部Logo
        MainControlBaseUI.Backpack_Border:AddAdvancedCollapsedCount(1)			 -- 背包
        MainControlBaseUI.PlayerInfoSocket:GetActivedSocket(false).VerticalLifeInfo:AddAdvancedCollapsedCount(0)	-- 人物血条
    end
    
    ugcprint("[UGCGameState] 成功隐藏原始UI")
end



function UGCGameState:ReceiveBeginPlay()
    self.SuperClass.ReceiveBeginPlay(self);
    
    ugcprint("[UGCGameState] ReceiveBeginPlay 开始执行, HasAuthority=" .. tostring(self:HasAuthority()))

    if self:HasAuthority() == true then 
        -- 服务端初始化逻辑
        ugcprint("[UGCGameState] 服务端开始初始化")
        GameInit.ReInitialize() -- 确保游戏系统已初始化
    else
        -- 客户端初始化UI
        ugcprint("[UGCGameState] 客户端开始初始化UI")
        
        -- 隐藏和平精英的默认UI
        HideOriginalUI()

        -- 加载 MainUI 蓝图类
        local MainUI = UE.LoadClass(UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/Blueprint/UI/UI_Main.UI_Main_C");
        if not MainUI then
            ugcprint("[UGCGameState] 严重错误: 无法加载UI_Main类")
            return
        end
        ugcprint("[UGCGameState] 成功加载MainUI类")

        -- 获得当前PlayerController
        local PlayerController = GameplayStatics.GetPlayerController(self, 0);
        if not PlayerController then
            ugcprint("[UGCGameState] 严重错误: 无法获取PlayerController")
            return
        end
        ugcprint("[UGCGameState] 成功获取PlayerController")

        -- 创建 MainUI 实例
        local MainUI_BP = UserWidget.NewWidgetObjectBP(PlayerController, MainUI);
        if not MainUI_BP then
            ugcprint("[UGCGameState] 严重错误: 无法创建MainUI实例")
            return
        end
        ugcprint("[UGCGameState] 成功创建MainUI_BP实例")
        
        -- 保存UI引用到全局变量
        _G.MainUIInstance = MainUI_BP

        -- 将 MainUI 加入视口，显示UI
        MainUI_BP:AddToViewport();
        ugcprint("[UGCGameState] 成功将MainUI添加到视口")
        
        -- 创建间隔尝试多次获取游戏阶段的计时器
        UGCTimer.SetTimer(function()
            local PlayerController = UGCGameSystem.GetLocalPlayerController()
            if PlayerController and PlayerController.RequestGamePhaseInfo then
                ugcprint("[UGCGameState] 请求游戏阶段信息")
                PlayerController:RequestGamePhaseInfo()
            end
        end, 1.0, false)
    end
    
    ugcprint("[UGCGameState] ReceiveBeginPlay 执行完毕")
end

-- 游戏状态每帧更新
function UGCGameState:ReceiveTick(DeltaTime)
    self.SuperClass.ReceiveTick(self, DeltaTime);
end

-- 服务端RPC：客户端请求启动游戏
function UGCGameState:ServerRPC_RequestStartGame()
    if not self:HasAuthority() then
        ugcprint("[UGCGameState] 错误: 非服务端不能启动游戏")
        return
    end
    
    ugcprint("[UGCGameState] 收到启动游戏请求")
    
    local gameMode = UGCGameSystem.GameMode
    if gameMode and gameMode.StartPhase then
        -- 如果游戏已经在运行，则不做任何处理
        if gameMode.CurrentPhaseKey then
            ugcprint("[UGCGameState] 游戏已经开始，当前阶段: " .. gameMode.CurrentPhaseKey)
            return
        end
        
        -- 启动游戏
        gameMode:StartPhase("Preparation")
        ugcprint("[UGCGameState] 已启动游戏流程")
    else
        ugcprint("[UGCGameState] 错误: 无法启动游戏，GameMode不可用")
    end
end

-- 添加ServerRPC_RequestPhaseInfo函数来处理客户端请求
function UGCGameState:ServerRPC_RequestPhaseInfo(playerController)
    ugcprint("[UGCGameState] 收到客户端阶段信息请求，获取当前阶段")
    
    -- 调用GameMode获取当前阶段信息
    local phaseKey, phaseName, timeRemaining = self:GetCurrentPhaseInfo()
    
    if not phaseKey or not phaseName then
        ugcprint("[UGCGameState] 警告: 无法获取有效阶段信息")
        return
    end
    
    -- 向请求的客户端发送阶段信息
    if playerController and playerController.ClientRPC_PhaseChanged then
        ugcprint("[UGCGameState] 发送阶段信息到客户端: " .. phaseKey .. ", " .. phaseName .. ", " .. (timeRemaining or 0))
        playerController:ClientRPC_PhaseChanged(phaseKey, phaseName, timeRemaining or 0)
    else
        ugcprint("[UGCGameState] 错误: 无效的PlayerController或缺少ClientRPC_PhaseChanged方法")
    end
end

-- 获取当前游戏阶段信息
function UGCGameState:GetCurrentPhaseInfo()
    local gameMode = UGCGameSystem.GameMode
    
    -- 如果GameMode可用且有GetCurrentPhaseInfo方法
    if gameMode and gameMode.GetCurrentPhaseInfo then
        return gameMode:GetCurrentPhaseInfo()
    end
    
    -- 使用GameState自身存储的阶段信息作为备用
    if self.CurrentPhaseKey and self.CurrentPhaseName then
        local timeRemaining = 0
        
        -- 计算剩余时间
        if self.PhaseEndTime then
            local currentTime = UGCGameSystem.IsServer() 
                and UGCGameSystem.GetServerTimeSec() 
                or os.time()
            
            timeRemaining = math.max(0, self.PhaseEndTime - currentTime)
        end
        
        return self.CurrentPhaseKey, self.CurrentPhaseName, timeRemaining
    end
    
    -- 如果没有可用信息，返回默认阶段信息
    return "Preparation", "准备阶段", 30
end

-- 设置当前游戏阶段
function UGCGameState:SetCurrentPhase(phaseKey, phaseName, duration)
    if not phaseKey or not phaseName then
        ugcprint("[UGCGameState] 错误: 设置阶段参数无效")
        return
    end
    
    ugcprint("[UGCGameState] 设置当前阶段: " .. phaseKey .. ", " .. phaseName .. ", " .. (duration or 0))
    
    -- 保存阶段信息
    self.CurrentPhaseKey = phaseKey
    self.CurrentPhaseName = phaseName
    self.PhaseDuration = duration or 0
    
    -- 计算阶段结束时间
    if duration and duration > 0 then
        -- 使用服务器时间
        local currentTime = UGCGameSystem.IsServer() 
            and UGCGameSystem.GetServerTimeSec() 
            or os.time()
            
        self.PhaseEndTime = currentTime + duration
    else
        self.PhaseEndTime = nil
    end
    
    -- 通知所有客户端
    self:NotifyAllClients_PhaseChanged(phaseKey, phaseName, duration)
end

-- 通知所有客户端阶段变更
function UGCGameState:NotifyAllClients_PhaseChanged(phaseKey, phaseName, duration)
    ugcprint("[UGCGameState] 向所有客户端通知阶段变更")
    
    -- 获取所有PlayerController
    local controllers = UGCGameSystem.GetAllPlayerController(false)
    if not controllers or #controllers == 0 then
        ugcprint("[UGCGameState] 警告: 没有找到任何PlayerController")
        return
    end
    
    -- 向每个客户端发送通知
    for i, controller in ipairs(controllers) do
        if controller and controller.ClientRPC_PhaseChanged then
            ugcprint("[UGCGameState] 向客户端 " .. i .. " 发送阶段变更")
            controller:ClientRPC_PhaseChanged(phaseKey, phaseName, duration)
        end
    end
end

-- 更新阶段剩余时间
function UGCGameState:UpdatePhaseRemainingTime(remainingTime)
    self.PhaseRemainingTime = remainingTime
end

-- 获取阶段剩余时间
function UGCGameState:GetPhaseRemainingTime()
    return self.PhaseRemainingTime or 0
end

return UGCGameState;


