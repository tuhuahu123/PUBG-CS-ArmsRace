---@class UGCPlayerPawn_C:BP_UGCPlayerPawn_C
--Edit Below--
local UGCPlayerPawn = 
{
    GrounpID = 0,            -- 队伍ID
    PlayerIndex = 0,         -- 玩家序列号
    GoldCoin = 0,            -- 金币
    CusBloodColor = 0,       -- 自定义飘血
    DropItemTable = {},      -- 道具表
    CurrentWeaponLevel = 1,  -- 当前武器等级
    bInitializedWeapon = false -- 是否已初始化武器
};

-- 武器升级系统全局配置
if not _G.GunGameWeaponSystem then
    _G.GunGameWeaponSystem = {
        -- 游戏配置
        RespawnTime = 1.0,          -- 玩家复活时间(秒)
        EnableInfiniteAmmo = true,  -- 无限弹药开关
        
        
        -- 玩家数据
        PlayerLevels = {},          -- 记录玩家等级，key是playerKey
        
        -- 武器等级列表 - 从简单到困难排序
        WeaponLevels = {
            { 
                WeaponID = 101001, 
                Name = "AKM突击步枪",
                Attachments = {
                    203001,  -- 红点瞄准镜
                }
            },
            { 
                WeaponID = 101002, 
                Name = "M16A4突击步枪",
                Attachments = {
                    203002,  -- 全息瞄准镜
                }
            },
            { 
                WeaponID = 101003, 
                Name = "SCAR-L突击步枪",
                Attachments = {
                    203002,  -- 全息瞄准镜
                }
            },
            { 
                WeaponID = 101004, 
                Name = "M416突击步枪",
                Attachments = {
                    203001,  -- 红点瞄准镜
                    202001   -- 直角前握把
                }
            },
            { 
                WeaponID = 101005, 
                Name = "GROZA突击步枪",
                Attachments = {
                    203001,  -- 红点瞄准镜
                }
            },
            { 
                WeaponID = 101006, 
                Name = "AUG A3突击步枪",
                Attachments = {
                    203001,  -- 红点瞄准镜
                }
            },
            { 
                WeaponID = 101007, 
                Name = "QBZ95突击步枪",
                Attachments = {
                    203001,  -- 红点瞄准镜
                }
            },
            { 
                WeaponID = 101008, 
                Name = "FAMAS突击步枪",
                Attachments = {
                    203001,  -- 红点瞄准镜
                }
            },
            { 
                WeaponID = 101009, 
                Name = "M249轻机枪",
                Attachments = {
                    203001,  -- 红点瞄准镜
                }
            },
            { 
                WeaponID = 101010, 
                Name = "DP-28轻机枪",
                Attachments = {
                    203001,  -- 红点瞄准镜
                }
            },
            { 
                WeaponID = 103001, 
                Name = "Kar98K狙击枪",
                Attachments = {
                    203004,  -- 4倍 瞄准镜
                }
            },
            { 
                WeaponID = 104001, 
                Name = "双管猎枪",
            },
            { 
                WeaponID = 106001, 
                Name = "普通手枪",
            },
            { 
                WeaponID = 107008, 
                Name = "燃点复合弓",
            }
        }
    }
end

-- 使用全局变量
local WeaponSystem = _G.GunGameWeaponSystem

-- 武器初始化函数
local function InitializeWeapon(weapon, weaponConfig)
    -- 确保只在服务端执行
    if not weapon or not weapon:HasAuthority() then return end
    
    -- 获取物品所有者
    local owner = weapon:GetOwner()
    if not owner then return end
    
    -- 启用无限弹夹
    if UGCGunSystem then
        UGCGunSystem.EnableClipInfiniteBullets(weapon, true)
        ugcprint("[Debug] 武器启用无限弹夹: " .. weaponConfig.WeaponID)
        
        -- 添加配件
        if weaponConfig.Attachments then
            for _, attachmentID in ipairs(weaponConfig.Attachments) do
                -- 先添加配件到背包再装配
                UGCBackPackSystem.AddItem(owner, attachmentID, 1)
                UGCGunSystem.CreateAndAddGunAttachment(weapon, attachmentID)
            end
        end
    end
end

-- 获取需要复制的属性
function UGCPlayerPawn:GetReplicatedProperties()
    return
    "GrounpID",
    "PlayerIndex",
    "GoldCoin",
    "CusBloodColor",
    "DropItemTable",
    "CurrentWeaponLevel",
    "bInitializedWeapon"
end

-- 游戏开始时调用
function UGCPlayerPawn:ReceiveBeginPlay()
    ugcprint("[UGCPlayerPawn] ReceiveBeginPlay")
    self.SuperClass.ReceiveBeginPlay(self)
    self.OnCharacterHpChange:Add(self.OnHealthChanged, self)
    
    -- 只在服务器上处理武器逻辑
    if self:HasAuthority() then
        local initDelegate = ObjectExtend.CreateDelegate(self, function()
            local playerKey = UGCGameSystem.GetPlayerKeyByPlayerPawn(self)
            if not playerKey then
                ObjectExtend.DestroyDelegate(initDelegate)
                return
            end
            
            -- 如果已经初始化过，直接返回
            if self.bInitializedWeapon then
                ObjectExtend.DestroyDelegate(initDelegate)
                return
            end
            
            -- 检查是否是复活后的情况
            if WeaponSystem.PlayerLevels[playerKey] then
                self.CurrentWeaponLevel = WeaponSystem.PlayerLevels[playerKey]
                ugcprint("[Debug] 复活后恢复武器等级: " .. self.CurrentWeaponLevel)
            else
                -- 首次初始化
                self.CurrentWeaponLevel = 1
                WeaponSystem.PlayerLevels[playerKey] = 1
                ugcprint("[Debug] 首次初始化武器等级: " .. self.CurrentWeaponLevel)
            end
            
            -- 清空背包
            local BackPackInfo = UGCBackPackSystem.GetAllItemData(self)
            for k, v in pairs(BackPackInfo) do
                UGCBackPackSystem.DropItem(self, v.ItemID, v.Count, true)
            end
            
            -- 添加武器
            local weapon = WeaponSystem.WeaponLevels[self.CurrentWeaponLevel]
            if weapon then
                ugcprint("[Debug] 给予武器: " .. weapon.Name .. " (ID: " .. weapon.WeaponID .. ")")
                UGCBackPackSystem.AddItem(self, weapon.WeaponID, 1)
                
                -- 延迟初始化武器属性
                local weaponDelegate = ObjectExtend.CreateDelegate(self, function()
                    local currentWeapon = self:GetCurrentWeapon()
                    if currentWeapon then
                        ugcprint("[Debug] 获取到武器实例,准备初始化")
                        InitializeWeapon(currentWeapon, weapon)
                        ObjectExtend.DestroyDelegate(weaponDelegate)
                    end
                end)
                
                KismetSystemLibrary.K2_SetTimerDelegateForLua(weaponDelegate, self, 0.5, false)
            end
            
            -- 标记为已初始化
            self.bInitializedWeapon = true
            ObjectExtend.DestroyDelegate(initDelegate)
        end)
        
        -- 延迟初始化
        KismetSystemLibrary.K2_SetTimerDelegateForLua(initDelegate, self, 0.5, false)
    else
        ugcprint("[Debug] 非服务器环境，跳过初始化")
    end
end

-- 处理玩家死亡事件
function UGCPlayerPawn:UGC_PlayerDeadEvent(Killer, DamageType)
    if not self:HasAuthority() then return end
    
    -- 获取玩家标识
    local playerKey = UGCGameSystem.GetPlayerKeyByPlayerPawn(self)
    if not playerKey then return end
    
    ugcprint("[Debug] 玩家死亡: " .. playerKey)
    
    -- 获取击杀者信息
    local killerKey = nil
    local killerController = nil
    local killerPawn = nil
    
    if Killer and UE.IsValid(Killer) then
        killerController = Killer
        killerKey = UGCGameSystem.GetPlayerKeyByPlayerController(killerController)
        
        if killerKey then
            killerPawn = UGCGameSystem.GetPlayerPawnByPlayerKey(killerKey)
            ugcprint("[Debug] 击杀者: " .. killerKey)
        end
    end
    
    -- 处理击杀者武器升级
    if killerPawn and killerKey and killerKey ~= playerKey then
        -- 增加击杀者武器等级
        local oldLevel = killerPawn.CurrentWeaponLevel
        killerPawn.CurrentWeaponLevel = math.min(killerPawn.CurrentWeaponLevel + 1, #WeaponSystem.WeaponLevels)
        
        -- 更新全局记录
        WeaponSystem.PlayerLevels[killerKey] = killerPawn.CurrentWeaponLevel
        
        ugcprint("[Debug] 击杀者武器等级: " .. oldLevel .. " -> " .. killerPawn.CurrentWeaponLevel)
        
        if oldLevel ~= killerPawn.CurrentWeaponLevel then
            -- 先清空击杀者背包
            local BackPackInfo = UGCBackPackSystem.GetAllItemData(killerPawn)
            for k, v in pairs(BackPackInfo) do
                UGCBackPackSystem.DropItem(killerPawn, v.ItemID, v.Count, true)
            end
            
            -- 给予新武器
            local weapon = WeaponSystem.WeaponLevels[killerPawn.CurrentWeaponLevel]
            if weapon then
                UGCBackPackSystem.AddItem(killerPawn, weapon.WeaponID, 1)
                
                local weaponDelegate = ObjectExtend.CreateDelegate(killerPawn, function()
                    local currentWeapon = killerPawn:GetCurrentWeapon()
                    if currentWeapon then
                        ugcprint("[Debug] 升级后获取到新武器,准备初始化")
                        InitializeWeapon(currentWeapon, weapon)
                        ObjectExtend.DestroyDelegate(weaponDelegate)
                    end
                end)
                
                KismetSystemLibrary.K2_SetTimerDelegateForLua(weaponDelegate, killerPawn, 0.5, false)
                
                -- 发送UI通知
                if killerController then
                    UnrealNetwork.CallUnrealRPC(killerController, killerController, "ClientRPC_ShowWeaponUpgradeMsg", weapon.Name)
                end
                
                ugcprint("[Debug] 升级武器成功: " .. weapon.Name)
            end
            
            -- 检查游戏结束
            if killerPawn.CurrentWeaponLevel >= #WeaponSystem.WeaponLevels then
                ugcprint("[Debug] 玩家" .. killerKey .. "完成所有武器升级！")
                local gameMode = UGCGameSystem.GameMode
                if gameMode then
                    gameMode:NotifyGameEnd()
                end
            end
        end
    end
    
    -- 复活玩家
    ugcprint("[Debug] 准备复活玩家: " .. playerKey)
    
    local playerRespawnComponentClass = ScriptGameplayStatics.FindClass("PlayerRespawnComponent")
    if playerRespawnComponentClass then
        local gameMode = UGCGameSystem.GameMode
        if gameMode then
            local playerRespawnComponent = gameMode:GetComponentByClass(playerRespawnComponentClass)
            if playerRespawnComponent then
                ugcprint("[Debug] 使用PlayerRespawnComponent复活")
                playerRespawnComponent:AddRespawnPlayerWithTime(playerKey, 1.0)
            end
        end
    end
end

-- 死亡处理
function UGCPlayerPawn:OnDeath(Killer, Damager, DamageEvent, HitPoint, HitDirection)
    ugcprint("[UGCPlayerPawn] OnDeath被调用")
    
    -- 标记武器为未初始化，这样复活后才能重新装备
    self.bInitializedWeapon = false
    
    -- 调用父类方法
    if self.SuperClass and self.SuperClass.OnDeath then
        self.SuperClass.OnDeath(self, Killer, Damager, DamageEvent, HitPoint, HitDirection)
    end
    
    -- 调用自定义处理函数
    self:UGC_PlayerDeadEvent(Killer, DamageEvent and DamageEvent.DamageType)
end

-- 血量变化处理
function UGCPlayerPawn:OnHealthChanged(NewHealth, OldHealth, Instigator)
    if self:HasAuthority() == false and NewHealth < OldHealth then
        TryExecuteCallerFunction(UIManager:GetUIByType(UIManager.HitUIID), "ShowRingDamageHit", NewHealth, OldHealth)
    end
end

-- 死亡不掉落盒子
function UGCPlayerPawn:IsSkipSpawnDeadTombBox(EventInstigater)
    return true
end

return UGCPlayerPawn;