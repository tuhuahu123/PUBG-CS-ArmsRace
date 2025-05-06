---@class UI_HP_C:UUserWidget
---@field HP_text UTextBlock
local UI_HP = {}

function UI_HP:Construct()
    -- 初始化，不预设固定值
    self.currentHealth = 0
    self.maxHealth = 100  -- 用作初始默认值，但会被实际值覆盖
    self.lastHealth = 0
    self.lastMaxHealth = 100
    
    -- 监听血量变化事件
    UGCEventSystem:AddListener(UGCEventType.PlayerHealthChanged, self.OnPlayerHealthChanged, self)
    
    -- 设置定时器，定期检查血量和最大血量
    self.timerHandle = UGCTimer.SetTimer(function()
        self:CheckHealthFromPawn()
    end, 0.5, true)  -- 增加检查频率到0.5秒一次
    
    -- 初始检查一次
    self:CheckHealthFromPawn()
end

-- 从事件获取血量变化
function UI_HP:OnPlayerHealthChanged(PlayerKey, CurrentHealth, MaxHealth)
    local LocalPlayerKey = UGCPlayerSystem.GetLocalPlayerKey()
    
    -- 只处理本地玩家
    if PlayerKey == LocalPlayerKey then
        self.currentHealth = CurrentHealth
        self.maxHealth = MaxHealth or self.maxHealth  -- 如果未提供MaxHealth，保留当前值
        
        -- 检测血量或最大血量变化并更新显示
        if self.currentHealth ~= self.lastHealth or self.maxHealth ~= self.lastMaxHealth then
            self:UpdateHealthText()
            self.lastHealth = self.currentHealth
            self.lastMaxHealth = self.maxHealth
        end
    end
end

-- 直接从玩家Pawn获取血量和最大血量
function UI_HP:CheckHealthFromPawn()
    local localController = LocalController
    if not localController then return end
    
    local playerPawn = localController:K2_GetPawn()
    if not playerPawn then return end
    
    -- 获取当前血量
    local currentHealth = UGCPawnAttrSystem.GetHealth(playerPawn)
    
    -- 获取最大血量 (可以通过属性系统获取)
    -- 假设有这个函数获取最大血量，如果没有可以替换成相应的方法
    local maxHealth = UGCPawnAttrSystem.GetMaxHealth and UGCPawnAttrSystem.GetMaxHealth(playerPawn) or 
                      -- 备选方法：直接从Pawn获取HealthMax属性
                      playerPawn.HealthMax or 
                      -- 如果都失败，使用之前的最大血量
                      self.maxHealth
    
    -- 检测变化
    if currentHealth ~= self.lastHealth or maxHealth ~= self.lastMaxHealth then
        self.currentHealth = currentHealth or 0  -- 防止nil值
        self.maxHealth = maxHealth or 100        -- 防止nil值
        self:UpdateHealthText()
        self.lastHealth = self.currentHealth
        self.lastMaxHealth = self.maxHealth
    end
end

-- 更新血量文本显示
function UI_HP:UpdateHealthText()
    if self.HP_text then
        -- 确保最大血量不为0避免除以0错误
        local maxHealth = self.maxHealth > 0 and self.maxHealth or 100
        
        -- 显示格式可以根据需要调整
        self.HP_text:SetText(string.format("%d/%d", self.currentHealth, maxHealth))
        
        -- 根据血量比例变化颜色
        local healthPercent = self.currentHealth / maxHealth
        if healthPercent <= 0.3 then
            -- 低血量显示红色
            self.HP_text:SetColorAndOpacity(FLinearColor.New(1, 0, 0, 1))
        elseif healthPercent <= 0.6 then
            -- 中等血量显示黄色
            self.HP_text:SetColorAndOpacity(FLinearColor.New(1, 1, 0, 1))
        else
            -- 高血量显示绿色
            self.HP_text:SetColorAndOpacity(FLinearColor.New(0, 1, 0, 1))
        end
    end
end

-- 处理UI销毁
function UI_HP:Destruct()
    -- 移除事件监听
    UGCEventSystem:RemoveListener(UGCEventType.PlayerHealthChanged, self.OnPlayerHealthChanged, self)
    
    -- 移除定时器
    if self.timerHandle then
        UGCTimer.ClearTimer(self.timerHandle)
    end
end

return UI_HP