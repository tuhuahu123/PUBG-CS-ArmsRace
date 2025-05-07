---@class UI_HP_C:UUserWidget
---@field HP_text UTextBlock
local UI_HP = {}

-- HP UI组件初始化
function UI_HP:Construct()
    ugcprint("[UI_HP] 初始化")
    
    -- 初始化数据
    self.lastHealth = nil
    self.lastMaxHealth = nil
    self.debugCount = 0  -- 用于控制日志输出频率
    
    -- 获取UI组件
    self.HP_text = self:GetWidgetFromName("HP_text")
    if not self.HP_text then
        ugcprint("[UI_HP] 错误: HP_text组件不存在，请检查UI蓝图！")
    else
        ugcprint("[UI_HP] HP_text组件已找到")
    end
    
    -- 设置初始显示
    self:UpdateHealthText("--", "--")
    
    -- 设置更新计时器
    self:StartUpdateTimer()
    
    -- 立即尝试一次获取血量
    self:RefreshHealth()
end

-- 启动更新计时器
function UI_HP:StartUpdateTimer()
    -- 创建委托
    self.updateDelegate = ObjectExtend.CreateDelegate(self, function()
        self:RefreshHealth()
    end, self)
    
    -- 设置计时器
    self.updateTimer = FTimerHandle.new()
    KismetSystemLibrary.K2_SetTimerDelegate(
        self.updateDelegate,
        0.2,  -- 每200毫秒更新一次，提高频率
        true, -- 循环
        0.0,  -- 无延迟
        self.updateTimer
    )
    
    ugcprint("[UI_HP] 血量更新计时器已启动")
end

-- 从Pawn更新血量 (供外部RPC回调使用)
function UI_HP:UpdateHealthFromPawn()
    local controller = UGCPlayerSystem.GetLocalController()
    if not controller then return end
    
    local pawn = controller:K2_GetPawn()
    if not pawn then return end
    
    -- 尝试从缓存获取健康值
    if pawn._lastHp and pawn._lastMaxHp then
        self:UpdateHealthText(math.floor(pawn._lastHp), math.floor(pawn._lastMaxHp))
        self.lastHealth = pawn._lastHp
        self.lastMaxHealth = pawn._lastMaxHp
        ugcprint("[UI_HP] UpdateHealthFromPawn: 从缓存更新血量: " .. tostring(pawn._lastHp) .. "/" .. tostring(pawn._lastMaxHp))
        return true
    end
    
    return false
end

-- 刷新血量显示
function UI_HP:RefreshHealth()
    self.debugCount = self.debugCount + 1
    local shouldLog = (self.debugCount % 15 == 0)  -- 每15次只输出一次日志
    
    -- 获取本地玩家控制器
    local controller = UGCPlayerSystem.GetLocalController()
    if not controller then
        if shouldLog then ugcprint("[UI_HP] RefreshHealth: 无法获取controller") end
        return
    end
    
    -- 获取玩家角色
    local pawn = controller:K2_GetPawn()
    if not pawn then
        if shouldLog then ugcprint("[UI_HP] RefreshHealth: 无法获取pawn") end
        return
    end
    
    -- 尝试方法1：先检查缓存的血量数据
    if pawn._lastHp and pawn._lastMaxHp and pawn._lastHp > 0 and pawn._lastMaxHp > 0 then
        -- 更新血量
        if pawn._lastHp ~= self.lastHealth or pawn._lastMaxHp ~= self.lastMaxHealth then
            self.lastHealth = pawn._lastHp
            self.lastMaxHealth = pawn._lastMaxHp
            self:UpdateHealthText(math.floor(pawn._lastHp), math.floor(pawn._lastMaxHp))
            if shouldLog then ugcprint("[UI_HP] 从缓存更新血量: " .. tostring(pawn._lastHp) .. "/" .. tostring(pawn._lastMaxHp)) end
        end
        return
    end
    
    -- 尝试方法2：使用API
    local health = UGCPawnAttrSystem.GetHealth(pawn)
    local maxHealth = UGCPawnAttrSystem.GetHealthMax(pawn)
    
    -- 如果方法2失败，尝试方法3：直接读取属性 
    if not health or not maxHealth or health <= 0 or maxHealth <= 0 then
        health = pawn.Health
        maxHealth = pawn.MaxHealth
        
        -- 如果方法3也失败，尝试方法4：访问当前血量和最大血量变量
        if not health or not maxHealth or health <= 0 or maxHealth <= 0 then
            health = pawn.currentHP
            maxHealth = pawn.maxHP
        end
    end
    
    -- 尝试方法5: 如果所有方法都失败，设置默认值
    if not health or not maxHealth or health <= 0 or maxHealth <= 0 then
        if not self.lastHealth or not self.lastMaxHealth then
            -- 没有历史数据，假设满血状态
            health = 100
            maxHealth = 100
            if shouldLog then ugcprint("[UI_HP] 所有方法均失败，使用默认血量: 100/100") end
        else
            -- 使用上次的有效值
            health = self.lastHealth
            maxHealth = self.lastMaxHealth
            if shouldLog then ugcprint("[UI_HP] 使用上次的有效血量值: " .. tostring(health) .. "/" .. tostring(maxHealth)) end
        end
    end
    
    -- 更新显示
    if health ~= self.lastHealth or maxHealth ~= self.lastMaxHealth then
        self.lastHealth = health
        self.lastMaxHealth = maxHealth
        
        -- 更新UI
        self:UpdateHealthText(math.floor(health), math.floor(maxHealth))
        if shouldLog then ugcprint("[UI_HP] 血量更新: " .. tostring(health) .. "/" .. tostring(maxHealth)) end
    end
end

-- 更新血量文本
function UI_HP:UpdateHealthText(health, maxHealth)
    if not self.HP_text then
        self.HP_text = self:GetWidgetFromName("HP_text")
        if not self.HP_text then
            ugcprint("[UI_HP] 错误: 未找到HP_text控件")
            return
        end
    end
    
    -- 设置文本
    local text = tostring(health) .. "/" .. tostring(maxHealth)
    self.HP_text:SetText(text)
end

-- 强制刷新血量（供外部调用）
function UI_HP:ForceRefreshHealth()
    ugcprint("[UI_HP] 强制刷新血量显示")
    
    -- 先尝试更新玩家角色的缓存血量
    if not self:UpdateHealthFromPawn() then
        -- 如果从缓存更新失败，使用常规方法刷新
        self:RefreshHealth()
    end
end

-- 组件销毁
function UI_HP:Destruct()
    -- 清理计时器
    if self.updateTimer then
        KismetSystemLibrary.K2_ClearTimerHandle(self, self.updateTimer)
        self.updateTimer = nil
    end
    
    -- 清理委托
    if self.updateDelegate then
        ObjectExtend.DestroyDelegate(self.updateDelegate)
        self.updateDelegate = nil
    end
    
    ugcprint("[UI_HP] 组件已销毁")
end

return UI_HP