---@class UI_Main_C:UUserWidget
---@field UI_daojihi UI_daojihi_C
---@field UI_HP UI_HP_C
---@field UI_PlayerRanking UI_PlayerRanking_C
---@field UI_Weapon UI_Weapon_C
--Edit Below--
local UI_Main = { bInitDoOnce = false } 

function UI_Main:Construct()
    ugcprint("[UI_Main] 构造函数开始")
    
    if not self.bInitDoOnce then
        self.bInitDoOnce = true
        -- 这里设置UI的可见性
        self:SetVisibility(0) -- 0表示Visible，确保UI是可见的
        
        -- 检查子UI组件
        self:ValidateChildComponents()
        
        -- 强制刷新所有子组件
        self:ForceRefreshChildComponents()
        
        -- 启动定时器，确保UI组件持续更新
        self:StartUIUpdateTimer()
        
        -- 注册全局回调处理武器升级消息
        self:RegisterWeaponUpgradeCallback()
        
        ugcprint("[UI_Main] 初始化完成")
    end
end

-- 验证子UI组件是否存在
function UI_Main:ValidateChildComponents()
    -- 检查UI_daojihi
    if not self.UI_daojihi then
        ugcprint("[UI_Main] 错误: UI_daojihi组件引用丢失!")
    else
        ugcprint("[UI_Main] UI_daojihi组件已找到")
    end
    
    -- 检查UI_HP
    if not self.UI_HP then
        ugcprint("[UI_Main] 错误: UI_HP组件引用丢失!")
    else
        ugcprint("[UI_Main] UI_HP组件已找到")
    end
    
    -- 检查UI_PlayerRanking
    if not self.UI_PlayerRanking then
        ugcprint("[UI_Main] 错误: UI_PlayerRanking组件引用丢失!")
    else
        ugcprint("[UI_Main] UI_PlayerRanking组件已找到")
    end
    
    -- 检查UI_Weapon
    if not self.UI_Weapon then
        ugcprint("[UI_Main] 错误: UI_Weapon组件引用丢失!")
    else
        ugcprint("[UI_Main] UI_Weapon组件已找到")
    end
end

-- 强制刷新所有子组件
function UI_Main:ForceRefreshChildComponents()
    -- 刷新UI_daojihi
    if self.UI_daojihi then
        -- 如果有额外的初始化方法，可以调用
        if self.UI_daojihi.bInitDoOnce == false then
            ugcprint("[UI_Main] 强制初始化UI_daojihi")
            self.UI_daojihi:LuaInit()
            self.UI_daojihi:RegisterClientRPCs()
        end
        
        -- 强制更新倒计时显示
        if self.UI_daojihi.UpdateCountdownDisplay then
            self.UI_daojihi:UpdateCountdownDisplay()
        end
    end
    
    -- 刷新UI_HP
    if self.UI_HP and self.UI_HP.ForceRefreshHealth then
        self.UI_HP:ForceRefreshHealth()
    end
    
    -- 刷新UI_Weapon
    if self.UI_Weapon and self.UI_Weapon.RefreshWeaponDisplay then
        self.UI_Weapon:RefreshWeaponDisplay()
    end
    
    -- 刷新排行榜
    if self.UI_PlayerRanking and self.UI_PlayerRanking.RefreshRanking then
        self.UI_PlayerRanking:RefreshRanking()
    end
end

-- 启动UI更新定时器
function UI_Main:StartUIUpdateTimer()
    -- 清理已有定时器
    if self.UIUpdateTimerHandle then
        UGCTimer.ClearTimer(self.UIUpdateTimerHandle)
        self.UIUpdateTimerHandle = nil
    end
    
    -- 创建一个2秒执行一次的定时器，确保UI状态一致
    self.UIUpdateTimerHandle = UGCTimer.SetTimer(function()
        -- 检查倒计时组件
        if self.UI_daojihi and self.UI_daojihi.bInitDoOnce and self.UI_daojihi.TimeRemaining <= 0 then
            -- 如果倒计时为0，尝试重新请求游戏阶段
            local controller = UGCGameSystem.GetLocalPlayerController()
            if controller and controller.RequestGamePhaseInfo then
                controller:RequestGamePhaseInfo()
            end
        end
        
        -- 刷新血量显示
        if self.UI_HP and self.UI_HP.ForceRefreshHealth then
            self.UI_HP:ForceRefreshHealth()
        end
        
        -- 刷新武器显示
        if self.UI_Weapon and self.UI_Weapon.RefreshWeaponDisplay then
            self.UI_Weapon:RefreshWeaponDisplay()
        end
    end, 2.0, true)
end

-- 注册全局武器升级回调
function UI_Main:RegisterWeaponUpgradeCallback()
    if not _G.NotifyWeaponUpgrade then
        _G.NotifyWeaponUpgrade = function(playerId, oldLevel, newLevel, weaponName)
            -- 在UI上更新武器信息
            if self.UI_Weapon and self.UI_Weapon.OnWeaponUpgraded then
                self.UI_Weapon:OnWeaponUpgraded(playerId, oldLevel, newLevel, weaponName)
            end
            
            -- 如果是当前玩家的升级，显示提示
            local localController = UGCGameSystem.GetLocalPlayerController()
            if localController and localController:GetPlayerID() == playerId then
                -- 显示升级提示
                local message = "武器升级: " .. (weaponName or "")
                UGCScreenMessageSystem.ShowScreenMessage(message, 3.0, {R=1, G=0.7, B=0.1, A=1})
            end
        end
    end
end

-- 获取指定阶段名称的本地化文本
function UI_Main:GetPhaseNameText(phaseKey)
    local phaseTexts = {
        Preparation = "准备阶段",
        InProgress = "游戏阶段",
        PostMatch = "结束阶段"
    }
    
    return phaseTexts[phaseKey] or phaseKey
end

-- 处理阶段变更
function UI_Main:OnPhaseChanged(phaseKey, phaseName, duration)
    -- 更新倒计时UI
    if self.UI_daojihi and self.UI_daojihi.OnPhaseChanged then
        self.UI_daojihi:OnPhaseChanged(phaseKey, phaseName, duration)
    end
    
    -- 根据阶段调整UI显示
    if phaseKey == "Preparation" then
        -- 准备阶段特殊显示
        self:SetPreparationUI()
    elseif phaseKey == "InProgress" then
        -- 游戏阶段特殊显示
        self:SetInProgressUI()
    elseif phaseKey == "PostMatch" then
        -- 结束阶段特殊显示
        self:SetPostMatchUI()
    end
end

-- 设置准备阶段UI状态
function UI_Main:SetPreparationUI()
    -- 显示准备阶段特殊UI元素
    if self.UI_PlayerRanking then
        self.UI_PlayerRanking:SetVisibility(1) -- 隐藏排行榜
    end
    
    -- 其他准备阶段UI调整...
end

-- 设置游戏阶段UI状态
function UI_Main:SetInProgressUI()
    -- 显示游戏阶段特殊UI元素
    if self.UI_PlayerRanking then
        self.UI_PlayerRanking:SetVisibility(0) -- 显示排行榜
    end
    
    -- 其他游戏阶段UI调整...
end

-- 设置结束阶段UI状态
function UI_Main:SetPostMatchUI()
    -- 显示结束阶段特殊UI元素
    if self.UI_PlayerRanking then
        self.UI_PlayerRanking:SetVisibility(0) -- 显示排行榜
    end
    
    -- 其他结束阶段UI调整...
end

function UI_Main:Tick(MyGeometry, InDeltaTime)
    -- 仅在必要时执行刷新操作，减少不必要的日志
end

function UI_Main:Destruct()
    -- 清理UI更新定时器
    if self.UIUpdateTimerHandle then
        UGCTimer.ClearTimer(self.UIUpdateTimerHandle)
        self.UIUpdateTimerHandle = nil
    end
    
    self.bInitDoOnce = false
end

return UI_Main