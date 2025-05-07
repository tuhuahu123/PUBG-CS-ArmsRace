-- Script/Module/PlayerDataManager.lua

---@class PlayerDataManager
-- 玩家数据管理器 - 使用官方API进行存档数据的保存和加载
PlayerDataManager = PlayerDataManager or {}

-- 玩家数据缓存 {[PlayerKey] = {Data, UID}}
PlayerDataManager.DataCache = {}

-- 默认玩家数据模板
PlayerDataManager.DefaultData = {
    -- 基础信息
    Version = "1.0.0",            -- 存档版本号
    LastSaveTime = 0,             -- 最后保存时间
    
    -- 角色数据
    Character = {
        Level = 1,                -- 角色等级
        Experience = 0,           -- 经验值
        Coins = 0,                -- 金币 
    },
    
    -- 游戏统计数据
    Stats = {
        TotalKills = 0,           -- 总击杀数
        TotalDeaths = 0,          -- 总死亡数
        TotalDamage = 0,          -- 总伤害量
        GamesPlayed = 0,          -- 游戏局数
        Wins = 0,                 -- 获胜次数
        HeadShots = 0,            -- 爆头数
        HighestKillStreak = 0,    -- 最高连杀数
    },
    
    -- 武器数据
    Weapons = {
        -- 已解锁武器列表
        Unlocked = {},            -- [武器ID] = true
        -- 武器熟练度
        Mastery = {},             -- [武器ID] = 熟练度值
        -- 武器偏好设置
        Preferences = {},         -- [武器ID] = {配件ID列表}
    },
    
    -- 装备物品
    Inventory = {
        -- 拥有的物品列表 {ItemID = 数量}
        Items = {},
        -- 已装备物品
        Equipped = {
            Head = 0,             -- 头部装备ID
            Body = 0,             -- 身体装备ID
            Legs = 0,             -- 腿部装备ID
            Accessory = 0,        -- 配饰ID
        },
    },
    
    -- 玩家设置
    Settings = {
        MusicVolume = 1.0,        -- 音乐音量
        SoundVolume = 1.0,        -- 音效音量
        Sensitivity = 1.0,        -- 鼠标/手指灵敏度
        Language = "zh_CN",       -- 语言
    },
    
    -- 成就进度
    Achievements = {
        -- [成就ID] = {已完成=true/false, 进度=数值}
    },
}

-- 初始化管理器
function PlayerDataManager:Initialize()
    print("PlayerDataManager: 初始化数据管理器")
    
    -- 注册事件监听
    UGCAddListener(UGCEventType.OnPlayerLoginGame, function(PlayerKey)
        self:OnPlayerLogin(PlayerKey)
    end)
    
    UGCAddListener(UGCEventType.OnPlayerLogoutGame, function(PlayerKey)
        self:OnPlayerLogout(PlayerKey)
    end)
    
    UGCAddListener(UGCEventType.OnGameSettlement, function(GameResult)
        self:OnGameSettlement(GameResult)
    end)
    
    print("PlayerDataManager: 初始化完成")
    return true
end

-- 玩家登录回调
function PlayerDataManager:OnPlayerLogin(PlayerKey)
    print(string.format("PlayerDataManager: 玩家 [%s] 登录", PlayerKey))
    
    -- 获取玩家UID
    local playerUID = self:GetPlayerUID(PlayerKey)
    if not playerUID then
        print(string.format("警告: PlayerDataManager - 无法获取玩家 [%s] 的UID", PlayerKey))
        return
    end
    
    -- 加载玩家数据
    self:LoadPlayerData(PlayerKey, playerUID)
end

-- 玩家登出回调
function PlayerDataManager:OnPlayerLogout(PlayerKey)
    print(string.format("PlayerDataManager: 玩家 [%s] 登出", PlayerKey))
    
    -- 保存玩家数据
    self:SavePlayerData(PlayerKey)
    
    -- 清除缓存
    self.DataCache[PlayerKey] = nil
end

-- 游戏结算回调
function PlayerDataManager:OnGameSettlement(GameResult)
    print("PlayerDataManager: 处理游戏结算")
    
    if not GameResult or not GameResult.PlayerDatas then
        print("警告: PlayerDataManager - 无效的游戏结果数据")
        return
    end
    
    -- 更新每个玩家的数据
    for _, playerResult in ipairs(GameResult.PlayerDatas) do
        local PlayerKey = playerResult.PlayerKey
        
        -- 更新统计数据
        self:UpdatePlayerStats(PlayerKey, {
            kills = playerResult.KillPlayerNum or 0,
            damage = playerResult.Damage or 0,
            isWinner = playerResult.IsWinner or false
        })
    end
    
    -- 保存所有玩家数据
    -- 注意: 必须在发送结算数据前保存
    for PlayerKey, _ in pairs(self.DataCache) do
        self:SavePlayerData(PlayerKey)
    end
end

-- 获取玩家UID
function PlayerDataManager:GetPlayerUID(PlayerKey)
    local playerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(PlayerKey)
    if not playerPawn then return nil end
    
    local UID = UGCPawnAttrSystem.GetPlayerUID(playerPawn)
    return tonumber(UID)
end

-- 加载玩家数据
function PlayerDataManager:LoadPlayerData(PlayerKey, playerUID)
    if not PlayerKey or not playerUID then return end
    
    -- 从官方API获取存档数据
    local archiveData = UGCPlayerStateSystem.GetPlayerArchiveData(playerUID)
    
    local playerData
    if not archiveData or type(archiveData) ~= "table" then
        -- 玩家没有存档，创建新数据
        print(string.format("PlayerDataManager: 玩家 [%s] 没有存档，创建新数据", PlayerKey))
        playerData = table.deepcopy(self.DefaultData)
    else
        -- 使用存档数据
        print(string.format("PlayerDataManager: 成功加载玩家 [%s] 的存档数据", PlayerKey))
        playerData = archiveData
        
        -- 检查版本号并升级数据结构(如有必要)
        playerData = self:UpgradeDataIfNeeded(playerData)
    end
    
    -- 缓存数据
    self.DataCache[PlayerKey] = {
        Data = playerData,
        UID = playerUID
    }
    
    -- 返回加载的数据
    return playerData
end

-- 保存玩家数据
function PlayerDataManager:SavePlayerData(PlayerKey)
    if not PlayerKey or not self.DataCache[PlayerKey] then
        print(string.format("警告: PlayerDataManager - 无法保存玩家 [%s] 的数据，数据不存在", PlayerKey))
        return false
    end
    
    local cachedData = self.DataCache[PlayerKey]
    local playerData = cachedData.Data
    local playerUID = cachedData.UID
    
    -- 更新保存时间
    playerData.LastSaveTime = os.time()
    
    -- 使用官方API保存数据
    print(string.format("PlayerDataManager: 保存玩家 [%s] 的存档数据", PlayerKey))
    UGCPlayerStateSystem.SavePlayerArchiveData(playerUID, playerData)
    
    return true
end

-- 获取玩家数据
function PlayerDataManager:GetPlayerData(PlayerKey)
    if not PlayerKey then return nil end
    
    -- 检查缓存
    if self.DataCache[PlayerKey] then
        return self.DataCache[PlayerKey].Data
    end
    
    -- 如果没有缓存，尝试加载
    local playerUID = self:GetPlayerUID(PlayerKey)
    if playerUID then
        return self:LoadPlayerData(PlayerKey, playerUID)
    end
    
    return nil
end

-- 更新玩家统计数据
function PlayerDataManager:UpdatePlayerStats(PlayerKey, gameStats)
    local playerData = self:GetPlayerData(PlayerKey)
    if not playerData or not playerData.Stats then return end
    
    -- 更新基本统计
    playerData.Stats.GamesPlayed = (playerData.Stats.GamesPlayed or 0) + 1
    
    -- 更新击杀和伤害
    if gameStats.kills then
        playerData.Stats.TotalKills = (playerData.Stats.TotalKills or 0) + gameStats.kills
    end
    
    if gameStats.damage then
        playerData.Stats.TotalDamage = (playerData.Stats.TotalDamage or 0) + gameStats.damage
    end
    
    -- 更新获胜次数
    if gameStats.isWinner then
        playerData.Stats.Wins = (playerData.Stats.Wins or 0) + 1
    end
    
    -- 如果本局的连杀数更高，更新最高连杀
    if gameStats.killStreak and gameStats.killStreak > (playerData.Stats.HighestKillStreak or 0) then
        playerData.Stats.HighestKillStreak = gameStats.killStreak
    end
    
    -- 更新缓存
    self.DataCache[PlayerKey].Data = playerData
end

-- 添加/移除玩家物品
function PlayerDataManager:UpdatePlayerItem(PlayerKey, itemID, amount)
    local playerData = self:GetPlayerData(PlayerKey)
    if not playerData or not playerData.Inventory or not playerData.Inventory.Items then return false end
    
    -- 初始化物品
    playerData.Inventory.Items[itemID] = playerData.Inventory.Items[itemID] or 0
    
    -- 添加或减少数量
    playerData.Inventory.Items[itemID] = playerData.Inventory.Items[itemID] + amount
    
    -- 如果数量为0或负数，移除物品
    if playerData.Inventory.Items[itemID] <= 0 then
        playerData.Inventory.Items[itemID] = nil
    end
    
    -- 更新缓存
    self.DataCache[PlayerKey].Data = playerData
    
    return true
end

-- 解锁武器
function PlayerDataManager:UnlockWeapon(PlayerKey, weaponID)
    local playerData = self:GetPlayerData(PlayerKey)
    if not playerData or not playerData.Weapons or not playerData.Weapons.Unlocked then return false end
    
    -- 设置武器为已解锁
    playerData.Weapons.Unlocked[weaponID] = true
    
    -- 初始化武器熟练度
    if not playerData.Weapons.Mastery[weaponID] then
        playerData.Weapons.Mastery[weaponID] = 0
    end
    
    -- 更新缓存
    self.DataCache[PlayerKey].Data = playerData
    
    return true
end

-- 更新玩家设置
function PlayerDataManager:UpdatePlayerSettings(PlayerKey, newSettings)
    local playerData = self:GetPlayerData(PlayerKey)
    if not playerData or not playerData.Settings then return false end
    
    -- 更新设置
    for key, value in pairs(newSettings) do
        playerData.Settings[key] = value
    end
    
    -- 更新缓存
    self.DataCache[PlayerKey].Data = playerData
    
    return true
end

-- 检查和升级数据结构
function PlayerDataManager:UpgradeDataIfNeeded(playerData)
    -- 检查版本号
    local dataVersion = playerData.Version or "0.0.0"
    local currentVersion = self.DefaultData.Version
    
    -- 如果版本相同，不需要升级
    if dataVersion == currentVersion then
        return playerData
    end
    
    print(string.format("PlayerDataManager: 正在升级玩家数据从版本 %s 到 %s", dataVersion, currentVersion))
    
    -- 这里实现数据结构版本升级逻辑
    -- 例如: 添加新字段、转换旧数据格式等
    
    -- 简单示例: 确保所有必要字段存在
    for key, value in pairs(self.DefaultData) do
        if playerData[key] == nil then
            playerData[key] = table.deepcopy(value)
        elseif type(value) == "table" and type(playerData[key]) == "table" then
            -- 深度检查并填充缺失的嵌套字段
            self:EnsureDataFields(playerData[key], value)
        end
    end
    
    -- 更新版本号
    playerData.Version = currentVersion
    
    return playerData
end

-- 确保数据字段存在
function PlayerDataManager:EnsureDataFields(targetTable, templateTable)
    for key, value in pairs(templateTable) do
        if targetTable[key] == nil then
            targetTable[key] = table.deepcopy(value)
        elseif type(value) == "table" and type(targetTable[key]) == "table" then
            -- 递归检查嵌套表
            self:EnsureDataFields(targetTable[key], value)
        end
    end
end

-- 工具函数 - 表深拷贝
function table.deepcopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
        end
        setmetatable(copy, table.deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- 示例用法:
--[[
-- 初始化数据管理器
PlayerDataManager:Initialize()

-- 获取玩家数据
local PlayerKey = "player123"
local playerData = PlayerDataManager:GetPlayerData(PlayerKey)

-- 更新玩家物品
PlayerDataManager:UpdatePlayerItem(PlayerKey, 1001, 5)  -- 添加5个ID为1001的物品
PlayerDataManager:UpdatePlayerItem(PlayerKey, 1002, -1) -- 移除1个ID为1002的物品

-- 解锁武器
PlayerDataManager:UnlockWeapon(PlayerKey, 2001)

-- 更新玩家设置
PlayerDataManager:UpdatePlayerSettings(PlayerKey, {
    MusicVolume = 0.8,
    SoundVolume = 0.7
})

-- 保存玩家数据
PlayerDataManager:SavePlayerData(PlayerKey)
]]--

return PlayerDataManager