---@class UGCPlayerController_C:BP_UGCPlayerController_C
--Edit Below--
local UGCPlayerController = {}

-- 初始化函数
function UGCPlayerController:ReceiveBeginPlay()
    self.SuperClass.ReceiveBeginPlay(self)
    
    -- 监听鼠标松开和开火事件
    self.OnReleaseFireBtn:Add(self.HandleReleaseFireBtn, self)
    self.OnStopFireEvent:Add(self.HandleStopFire, self)
    self.OnStartFireEvent:Add(self.HandleStartFire, self)
    
    -- 将本地控制器添加到PlayerSystem中
    if self:IsLocalController() then
        if UGCPlayerSystem then
            UGCPlayerSystem.LocalControllers = UGCPlayerSystem.LocalControllers or {}
            table.insert(UGCPlayerSystem.LocalControllers, self)
        end
    end
    
    --ugcprint("[UGCPlayerController] 已初始化开火事件监听")
end

-- 每帧更新
function UGCPlayerController:ReceiveTick(DeltaTime)
    self.SuperClass.ReceiveTick(self, DeltaTime)
end

-- 游戏结束时回调
function UGCPlayerController:ReceiveEndPlay()
    self.SuperClass.ReceiveEndPlay(self) 
    
    -- 清理事件监听
    if self.OnReleaseFireBtn then
        self.OnReleaseFireBtn:Remove(self.HandleReleaseFireBtn, self)
    end
    
    if self.OnStopFireEvent then
        self.OnStopFireEvent:Remove(self.HandleStopFire, self)
    end
    
    if self.OnStartFireEvent then
        self.OnStartFireEvent:Remove(self.HandleStartFire, self)
    end
end

-- 处理鼠标释放按钮事件
function UGCPlayerController:HandleReleaseFireBtn()
   -- ugcprint("[UGCPlayerController] 鼠标释放 - 强制停止开火")
    
    -- 确保停止开火
    self:OnStopFire()
    
    -- 双重保险，如果角色存在则强制停止开火
    local character = UGCGameSystem.GetPlayerCharacter(self)
    if character then
        local weapon = character:GetCurrentWeapon()
        if weapon then
            --ugcprint("[UGCPlayerController] 直接调用武器停火方法")
            weapon:StopFire()
        end
    end
end



-------------------------测试代码-----------------------------------
-- 处理停火事件
function UGCPlayerController:HandleStopFire()
    --ugcprint("[UGCPlayerController] 停火事件触发")
end

-- 处理开火事件
function UGCPlayerController:HandleStartFire()
    --ugcprint("[UGCPlayerController] 开火事件触发")
end



-- 接收服务器发送的角色血量同步数据
function UGCPlayerController:ClientRPC_SyncPawnHP(pawn, health, maxHealth)
    if not pawn or not UE.IsValid(pawn) then
        ugcprint("[Controller] ClientRPC_SyncPawnHP: 无效的Pawn")
        return
    end
    
    ugcprint("[Controller] ClientRPC_SyncPawnHP: 收到血量数据, pawn=" .. tostring(pawn) .. ", health=" .. tostring(health) .. ", maxHealth=" .. tostring(maxHealth))
    
    -- 保存到Pawn缓存
    pawn._lastHp = health
    pawn._lastMaxHp = maxHealth
    
    -- 检查是否是本地控制的Pawn
    local localPawn = self:K2_GetPawn()
    if pawn == localPawn then
        ugcprint("[Controller] ClientRPC_SyncPawnHP: 本地角色血量更新，通知UI")
        
        -- 直接获取和更新UI
        local hpUI = TryExecuteCallerFunction(UIManager, "GetUIByType", "UI_HP")
        if hpUI then
            ugcprint("[Controller] ClientRPC_SyncPawnHP: 找到UI_HP，强制刷新显示")
            hpUI:ForceRefreshHealth()
        else
            ugcprint("[Controller] ClientRPC_SyncPawnHP: 未找到UI_HP")
        end
    end
end

-- 接收服务器发送的武器升级消息
function UGCPlayerController:ClientRPC_ShowWeaponUpgradeMsg(weaponName)
    -- 在UI中显示武器升级消息
    if UE4.UKismetSystemLibrary.IsServer(self) == false then
        -- 获取当前武器等级
        local pawn = self:K2_GetPawn()
        local oldLevel = 0
        local newLevel = 1
        
        if pawn and pawn.CurrentWeaponLevel then
            newLevel = pawn.CurrentWeaponLevel
            oldLevel = newLevel - 1
        end
        
        -- 获取玩家ID
        local playerId = self:GetPlayerID() or 0
        
        -- 触发全局武器升级通知
        if _G.NotifyWeaponUpgrade then
            _G.NotifyWeaponUpgrade(playerId, oldLevel, newLevel, weaponName)
            ugcprint("[UGCPlayerController] 触发全局武器升级通知: 玩家ID=" .. tostring(playerId) .. ", 武器=" .. tostring(weaponName))
        end
        
        -- 兼容旧版UI
        local uiImage = TryExecuteCallerFunction(UIManager, "GetUIByType", "UI_image")
        if uiImage then
            uiImage:OnWeaponUpgraded()
        end
        
        -- 获取UI_Weapon组件
        local uiWeapon = TryExecuteCallerFunction(UIManager, "GetUIByType", "UI_Weapon")
        if uiWeapon and uiWeapon.OnWeaponUpgraded then
            uiWeapon:OnWeaponUpgraded(playerId, oldLevel, newLevel, weaponName)
            ugcprint("[UGCPlayerController] 直接通知UI_Weapon组件武器升级")
        end
        
        -- 显示提示消息
        local message = "武器升级: " .. weaponName
        UGCScreenMessageSystem.ShowScreenMessage(message, 3.0, {R=1, G=0.7, B=0.1, A=1})
        
        -- 播放升级音效（可选）
        --UGCScreenMessageSystem.PlaySound("SoundCue'/Game/Sound/SFX/SFX_Cue/Gemeral/General_SFX_Achievement_Cue.General_SFX_Achievement_Cue'")
    end
end

-- 确保RequestGamePhaseInfo函数能正确请求游戏阶段数据
function UGCPlayerController:RequestGamePhaseInfo()
    ugcprint("[UGCPlayerController] 向服务器请求游戏阶段信息")
    
    -- 获取GameMode以发送请求
    local gameMode = UGCGameSystem.GameMode
    if not gameMode then
        ugcprint("[UGCPlayerController] 错误: 无法获取GameMode，尝试获取GameState")
        -- 尝试从GameState获取信息
        local gameState = UGCGameSystem.GameState
        if not gameState then
            ugcprint("[UGCPlayerController] 错误: 同时无法获取GameState，请求失败")
            return
        end
        
        -- 使用GameState请求
        if UGCGameSystem.IsServer() then
            if gameState.GetCurrentPhaseInfo then
                local phaseKey, phaseName, timeRemaining = gameState:GetCurrentPhaseInfo()
                if phaseKey and phaseName then
                    ugcprint("[UGCPlayerController] 从GameState获取阶段信息: " .. phaseKey .. ", " .. (timeRemaining or 0) .. "秒")
                    self:ClientRPC_PhaseChanged(phaseKey, phaseName, timeRemaining or 0)
                end
            end
        elseif gameState.ServerRPC_RequestPhaseInfo then
            gameState:ServerRPC_RequestPhaseInfo(self)
        end
        return
    end
    
    -- 直接向GameMode请求
    if UGCGameSystem.IsServer() then
        -- 如果是服务器，直接调用GameMode获取当前阶段信息
        ugcprint("[UGCPlayerController] 服务器本地调用HandleClientRequestPhaseInfo")
        if gameMode.HandleClientRequestPhaseInfo then
            gameMode:HandleClientRequestPhaseInfo(self)
        end
    else
        -- 如果是客户端，通过ServerRPC函数请求
        if gameMode.ServerRPC_RequestPhaseInfo then
            ugcprint("[UGCPlayerController] 通过ServerRPC请求阶段信息")
            gameMode:ServerRPC_RequestPhaseInfo(self)
        else
            -- 尝试使用标准RPC调用
            UnrealNetwork.CallUnrealRPC(self, gameMode, "ServerRPC_RequestPhaseInfo", self)
            ugcprint("[UGCPlayerController] 通过标准RPC请求阶段信息")
        end
    end
end

-- 添加/更新接收游戏阶段信息的客户端RPC
function UGCPlayerController:ClientRPC_PhaseChanged(phaseKey, phaseName, duration)
    ugcprint("[UGCPlayerController] 收到阶段变更: " .. (phaseKey or "nil") .. ", " .. (phaseName or "nil") .. ", " .. (duration or 0))
    
    -- 保存阶段信息
    self.CurrentPhaseKey = phaseKey
    self.CurrentPhaseName = phaseName
    self.PhaseDuration = duration or 0
    
    -- 在主UI中更新阶段信息
    local mainUI = self.MainUI
    if mainUI and mainUI.UI_daojihi then
        ugcprint("[UGCPlayerController] 更新UI_daojihi阶段信息")
        mainUI.UI_daojihi:OnPhaseChanged(phaseKey, phaseName, duration)
    end
    
    -- 根据不同阶段执行特定操作
    if phaseKey == "Preparation" then
        -- 准备阶段特殊处理
        self:OnPreparationPhase()
    elseif phaseKey == "InProgress" then
        -- 游戏阶段特殊处理
        self:OnInProgressPhase()
    elseif phaseKey == "PostMatch" then
        -- 结束阶段特殊处理
        self:OnPostMatchPhase()
    end
end

-- 准备阶段处理
function UGCPlayerController:OnPreparationPhase()
    -- 显示准备阶段提示
    UGCScreenMessageSystem.ShowScreenMessage("准备阶段开始，请等待所有玩家准备就绪", 3.0, {R=0.1, G=0.8, B=0.1, A=1})
    
    -- 禁用武器使用
    local pawn = self:K2_GetPawn()
    if pawn and pawn.SetWeaponEnabled then
        pawn:SetWeaponEnabled(false)
    end
end

-- 游戏阶段处理
function UGCPlayerController:OnInProgressPhase()
    -- 显示游戏开始提示
    UGCScreenMessageSystem.ShowScreenMessage("游戏开始，击杀敌人提升武器等级!", 3.0, {R=0.1, G=0.8, B=0.1, A=1})
    
    -- 启用武器使用
    local pawn = self:K2_GetPawn()
    if pawn and pawn.SetWeaponEnabled then
        pawn:SetWeaponEnabled(true)
    end
end

-- 结束阶段处理
function UGCPlayerController:OnPostMatchPhase()
    -- 显示游戏结束提示
    UGCScreenMessageSystem.ShowScreenMessage("游戏结束，即将显示结果...", 3.0, {R=0.8, G=0.1, B=0.1, A=1})
    
    -- 禁用武器使用
    local pawn = self:K2_GetPawn()
    if pawn and pawn.SetWeaponEnabled then
        pawn:SetWeaponEnabled(false)
    end
end

-- 接收计时器更新的客户端RPC
function UGCPlayerController:ClientRPC_TimerUpdate(remainingTime)
    ugcprint("[UGCPlayerController] 收到计时器更新: " .. tostring(remainingTime) .. "秒")
    
    -- 更新主UI中的倒计时显示
    local mainUI = self.MainUI
    if mainUI and mainUI.UI_daojihi then
        mainUI.UI_daojihi:OnTimerUpdate(remainingTime)
    end
end

-- 接收服务器发送的队伍信息更新
function UGCPlayerController:ClientRPC_UpdateTeam(teamID)
    -- UI_daojihi组件通过RegisterClientRPCs中的回调函数处理此消息
    -- 这是一个空函数实现，以确保RPC调用不会产生错误
end

-- 客户端RPC：接收队伍分配
function UGCPlayerController:ClientRPC_TeamAssigned(teamID)
    ugcprint("[UGCPlayerController] 被分配到队伍: " .. teamID)
    
    local pawn = self:K2_GetPawn()
    if pawn and pawn.GrounpID ~= nil then
        pawn.GrounpID = teamID
        
        -- 显示队伍通知
        local teamNames = {"红队", "蓝队"}
        local teamName = teamNames[teamID] or ("队伍" .. teamID)
        
        -- 显示队伍分配消息
        local message = "您已被分配到: " .. teamName
        UGCScreenMessageSystem.ShowScreenMessage(message, 3.0, {R=teamID==1 and 1.0 or 0.2, G=0.2, B=teamID==2 and 1.0 or 0.2, A=1})
        
        -- 播放队伍分配音效
        UGCScreenMessageSystem.PlaySound("SoundCue'/Game/Sound/SFX/SFX_Cue/Gemeral/General_SFX_Revive_Cue.General_SFX_Revive_Cue'")
    end
end

-- 客户端RPC：接收最终排名
function UGCPlayerController:ClientRPC_ShowFinalRanking(rankings)
    ugcprint("[UGCPlayerController] 收到最终排名数据")
    
    -- 更新UI排行榜
    if _G.MainUIInstance and _G.MainUIInstance.UI_PlayerRanking and _G.MainUIInstance.UI_PlayerRanking.ShowFinalRanking then
        _G.MainUIInstance.UI_PlayerRanking:ShowFinalRanking(rankings)
    end
    
    -- 找出第一名玩家
    local winner = nil
    for _, playerData in ipairs(rankings) do
        if playerData.Rank == 1 then
            winner = playerData
            break
        end
    end
    
    -- 显示胜利者
    if winner then
        local message = winner.Name .. " 获得胜利！"
        UGCScreenMessageSystem.ShowScreenMessage(message, 5.0, {R=1.0, G=0.8, B=0.1, A=1})
        
        -- 播放胜利音效
        --UGCScreenMessageSystem.PlaySound("SoundCue'/Game/Sound/SFX/SFX_Cue/MP/MP_SFX_Win_Cue.MP_SFX_Win_Cue'")
    end
end

-- 客户端RPC：玩家胜利
function UGCPlayerController:ClientRPC_PlayerWin(playerKey, playerName)
    ugcprint("[UGCPlayerController] 玩家胜利: " .. playerName)
    
    -- 显示胜利消息
    local message = playerName .. " 获得胜利！"
    UGCScreenMessageSystem.ShowScreenMessage(message, 5.0, {R=1.0, G=0.8, B=0.1, A=1})
    
    -- 判断是否是本地玩家胜利
    local localPlayerKey = UGCGameSystem.GetPlayerKeyByPlayerController(self)
    if localPlayerKey == playerKey then
        -- 本地玩家胜利，播放胜利音效
        UGCScreenMessageSystem.PlaySound("SoundCue'/Game/Sound/SFX/SFX_Cue/MP/MP_SFX_Win_Cue.MP_SFX_Win_Cue'")
    else
        -- 其他玩家胜利，播放失败音效
        UGCScreenMessageSystem.PlaySound("SoundCue'/Game/Sound/SFX/SFX_Cue/MP/MP_SFX_Lose_Cue.MP_SFX_Lose_Cue'")
    end
end

return UGCPlayerController