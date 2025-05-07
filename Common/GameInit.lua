-- GameInit.lua - 全局游戏初始化
-- 初始化所有重要的游戏系统和全局变量

-- 确保UGCTimer可用
if not UGCTimer then
    -- 绿洲启元编辑器中的计时器系统
    UGCTimer = UGC or _G.UGC or {}
    if not UGCTimer.SetTimer then
        UGCTimer.SetTimer = function(callback, interval, isRepeat, handle)
            -- 尝试不同的计时器API
            if UGC and UGC.InsertTimer then
                return UGC.InsertTimer(interval, callback, isRepeat, handle or "")
            elseif _G.UGC and _G.UGC.InsertTimer then
                return _G.UGC.InsertTimer(interval, callback, isRepeat, handle or "")
            else
                ugcprint("[GameInit] 警告: 找不到有效的计时器API")
                return nil
            end
        end
    end
    
    if not UGCTimer.ClearTimer then
        UGCTimer.ClearTimer = function(handle)
            if handle then
                if UGC and UGC.RemoveTimer then
                    UGC.RemoveTimer(handle)
                elseif _G.UGC and _G.UGC.RemoveTimer then
                    _G.UGC.RemoveTimer(handle)
                end
            end
        end
    end
    
    -- 添加直接的InsertTimer和RemoveTimer方法，以便与GameTimer兼容
    if not UGCTimer.InsertTimer then
        UGCTimer.InsertTimer = function(interval, callback, isRepeat, handle)
            -- 使用SetTimer作为InsertTimer的实现
            return UGCTimer.SetTimer(callback, interval, isRepeat, handle)
        end
    end
    
    if not UGCTimer.RemoveTimer then
        UGCTimer.RemoveTimer = function(handle)
            -- 使用ClearTimer作为RemoveTimer的实现
            UGCTimer.ClearTimer(handle)
        end
    end
    
    ugcprint("[GameInit] UGCTimer 初始化完成")
end

-- 引入必要的模块
local GameTimer = require("Script.Common.GameTimer")
local GamePhaseConfig = require("Script.Config.GamePhaseConfig")

-- 创建全局命名空间
if not _G.GunGameWeaponSystem then
    _G.GunGameWeaponSystem = {
        PlayerLevels = {},       -- 存储所有玩家的武器等级
        WeaponLevels = GamePhaseConfig.WeaponConfig.WeaponLevels or {}  -- 从配置获取武器等级定义
    }
end

-- 初始化武器系统
local function InitWeaponSystem()
    ugcprint("[GameInit] 初始化武器系统")
    
    -- 确保WeaponLevels有效
    if not _G.GunGameWeaponSystem.WeaponLevels or not next(_G.GunGameWeaponSystem.WeaponLevels) then
        _G.GunGameWeaponSystem.WeaponLevels = GamePhaseConfig.WeaponConfig.WeaponLevels
        ugcprint("[GameInit] 从配置加载武器等级定义")
    end
    
    -- 添加武器初始化函数
    _G.GunGameWeaponSystem.InitPlayerWeapon = function(playerKey, level)
        ugcprint("[Debug] 首次初始化武器等级: " .. (level or 1))
        
        local weaponLevel = level or 1
        _G.GunGameWeaponSystem.PlayerLevels[playerKey] = weaponLevel
        
        local weaponInfo = _G.GunGameWeaponSystem.WeaponLevels[weaponLevel]
        if weaponInfo then
            ugcprint("[Debug] 给予武器: " .. weaponInfo.Name .. " (ID: " .. weaponInfo.WeaponID .. ")")
            return weaponInfo.WeaponID
        else
            ugcprint("[Debug] 错误: 找不到等级" .. weaponLevel .. "的武器配置")
            return 101002  -- 默认给M16A4
        end
    end
    
    -- 添加获取武器函数
    _G.GunGameWeaponSystem.GetWeaponForLevel = function(level)
        local weaponInfo = _G.GunGameWeaponSystem.WeaponLevels[level]
        if weaponInfo then
            return weaponInfo.WeaponID, weaponInfo.Name
        else
            return 101002, "M16A4突击步枪"  -- 默认
        end
    end
end

-- 全局辅助函数
local function SetupGlobalHelpers()
    _G.MainUIInstance = _G.MainUIInstance or nil

    -- 全局武器升级通知函数 (Pawn中可能会调用此函数来通知UI)
    _G.NotifyWeaponUpgrade = function(playerId, oldLevel, newLevel, weaponName, weaponIconPath)
        ugcprint("[GameInit] NotifyWeaponUpgrade: Player " .. tostring(playerId) .. 
                 " upgraded from Lvl " .. tostring(oldLevel) .. 
                 " to Lvl " .. tostring(newLevel) .. 
                 ": " .. tostring(weaponName) ..
                 " (Icon: " .. tostring(weaponIconPath) .. ")")
        
        if _G.MainUIInstance and _G.MainUIInstance.UI_Weapon and _G.MainUIInstance.UI_Weapon.OnWeaponUpgraded then
            _G.MainUIInstance.UI_Weapon:OnWeaponUpgraded(playerId, oldLevel, newLevel, weaponName, weaponIconPath)
        else
            ugcprint("[GameInit] NotifyWeaponUpgrade: UI_Weapon or OnWeaponUpgraded method not found.")
        end
    end
end

-- 初始化计时器系统
local function InitTimerSystem()
    ugcprint("[GameInit] 初始化计时器系统")
    -- 已经在GameTimer模块中实现，此处可以添加额外的初始化逻辑
    
    -- 为非服务端添加请求阶段信息的逻辑
    if not UGCGameSystem.IsServer() then
        -- 使用安全的计时器创建方式
        if UGC and UGC.InsertTimer then
            UGC.InsertTimer(5.0, function()
                local controller = UGCGameSystem.GetLocalPlayerController()
                if controller and controller.RequestGamePhaseInfo then
                    controller:RequestGamePhaseInfo()
                end
            end, true, "PhaseInfoRequestTimer")  -- 每5秒请求一次游戏阶段信息
        else
            ugcprint("[GameInit] 警告: 无法创建周期性阶段信息请求定时器，找不到UGC.InsertTimer")
        end
    end
end

-- 主初始化函数
local function Initialize()
    ugcprint("[GameInit] 开始全局游戏初始化")
    
    -- 初始化武器系统
    InitWeaponSystem()
    
    -- 设置全局辅助函数
    SetupGlobalHelpers()
    
    -- 初始化计时器系统
    InitTimerSystem()
    
    ugcprint("[GameInit] 全局游戏初始化完成")
end

-- 执行初始化
Initialize()

return {
    -- 暴露API
    ReInitialize = Initialize
} 