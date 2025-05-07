---@class UI_Weapon_C:UUserWidget
---@field Image_Weapon UImage
---@field TextBlock_WeaponName UTextBlock
--Edit Below--
local UI_Weapon = {} 

function UI_Weapon:Construct()
    ugcprint("[UI_Weapon] 初始化")
    
    -- 检查组件引用
    if self.TextBlock_WeaponName then
        ugcprint("[UI_Weapon] TextBlock_WeaponName组件已找到")
        self.TextBlock_WeaponName:SetText("下一把武器: 加载中...")
    else
        ugcprint("[UI_Weapon] 警告: TextBlock_WeaponName组件未找到")
    end
    
    -- 获取武器等级信息
    if _G.GunGameWeaponSystem and _G.GunGameWeaponSystem.WeaponLevels then
        self.weaponLevels = _G.GunGameWeaponSystem.WeaponLevels
        ugcprint("[UI_Weapon] 武器配置已加载，共" .. #self.weaponLevels .. "把武器")
    else
        -- 创建备用武器配置
        self.weaponLevels = {
            { Name = "M16A4突击步枪", WeaponID = 101002 },
            { Name = "SCAR-L突击步枪", WeaponID = 101003 },
            { Name = "M416突击步枪", WeaponID = 101004 },
            { Name = "GROZA突击步枪", WeaponID = 101005 },
            { Name = "AUG A3突击步枪", WeaponID = 101006 },
            { Name = "QBZ95突击步枪", WeaponID = 101007 },
            { Name = "FAMAS突击步枪", WeaponID = 101008 },
            { Name = "M249轻机枪", WeaponID = 101009 },
            { Name = "Kar98K狙击枪", WeaponID = 103001 },
            { Name = "双管猎枪", WeaponID = 104001 },
            { Name = "P92手枪", WeaponID = 106001 }
        }
        ugcprint("[UI_Weapon] 警告: 全局武器配置未找到，使用备用配置")
    end
    
    -- 设置初始值
    self.currentLevel = 1
    self:UpdateWeaponText()
    
    -- 创建定时器定期检查更新
    self.updateTimer = UGCTimer.SetTimer(function()
        self:CheckForWeaponUpdate()
    end, 0.2, true)
    
    -- 注册到全局事件监听
    if not _G.WeaponUICallbacks then
        _G.WeaponUICallbacks = {}
    end
    table.insert(_G.WeaponUICallbacks, self)
    
    -- 创建全局通知函数
    _G.NotifyWeaponUpgrade = function(playerId, oldLevel, newLevel, weaponName)
        ugcprint("[UI_Weapon] 收到武器升级通知: " .. tostring(oldLevel) .. " -> " .. tostring(newLevel))
        for _, ui in ipairs(_G.WeaponUICallbacks or {}) do
            if ui and ui.OnWeaponUpgraded then
                ui:OnWeaponUpgraded(playerId, oldLevel, newLevel, weaponName)
            end
        end
    end
end

-- 更新武器文本显示
function UI_Weapon:UpdateWeaponText()
    local nextLevel = math.min(self.currentLevel + 1, #self.weaponLevels)
    local nextWeapon = self.weaponLevels[nextLevel]
    
    if nextWeapon and self.TextBlock_WeaponName then
        local weaponText = "下一把武器: " .. nextWeapon.Name
        self.TextBlock_WeaponName:SetText(weaponText)
        ugcprint("[UI_Weapon] 设置武器文本: " .. weaponText)
    end
end

-- 检查武器等级更新
function UI_Weapon:CheckForWeaponUpdate()
    local controller = UGCPlayerSystem.GetLocalController()
    if not controller then return end
    
    local pawn = controller:K2_GetPawn()
    if not pawn then return end
    
    -- 检查玩家当前武器等级
    if pawn.CurrentWeaponLevel then
        local currentLevel = tonumber(pawn.CurrentWeaponLevel) or 1
        
        -- 如果等级变化，更新UI
        if currentLevel ~= self.currentLevel then
            ugcprint("[UI_Weapon] 武器等级变化: " .. self.currentLevel .. " -> " .. currentLevel)
            self.currentLevel = currentLevel
            self:UpdateWeaponText()
        end
    end
end

-- 接收武器升级通知
function UI_Weapon:OnWeaponUpgraded(playerId, oldLevel, newLevel, weaponName)
    local controller = UGCPlayerSystem.GetLocalController()
    if not controller then return end
    
    -- 只处理本地玩家的升级
    local localPlayerId = controller:GetPlayerID()
    if localPlayerId ~= playerId then return end
    
    ugcprint("[UI_Weapon] 本地玩家武器升级: " .. tostring(oldLevel) .. " -> " .. tostring(newLevel))
    self.currentLevel = newLevel
    self:UpdateWeaponText()
end

return UI_Weapon