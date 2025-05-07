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
        
        -- 武器等级列表 - 按照指定顺序排序，从M16A4开始
        WeaponLevels = {
            { 
                WeaponID = 101002, 
                Name = "M16A4突击步枪",
                IconPath = "/Game/Arts/UI/TableIcons/ItemIcon/Weapon/Icon_WEP_M16A4.Icon_WEP_M16A4",
                Attachments = {
                    203002,  -- 全息瞄准镜
                }
            },
            { 
                WeaponID = 101003, 
                Name = "SCAR-L突击步枪",
                IconPath = "/Game/Arts/UI/TableIcons/ItemIcon/Weapon/Icon_WEP_SCAR.Icon_WEP_SCAR",
                Attachments = {
                    203002,  -- 全息瞄准镜
                }
            },
            { 
                WeaponID = 101004, 
                Name = "M416突击步枪",
                IconPath = "/Game/Arts/UI/TableIcons/ItemIcon/Weapon/Icon_WEP_M416.Icon_WEP_M416",
                Attachments = {
                    203001,  -- 红点瞄准镜
                    202001   -- 直角前握把
                }
            },
            { 
                WeaponID = 101005, 
                Name = "GROZA突击步枪",
                IconPath = "/Game/Arts/UI/TableIcons/ItemIcon/Weapon/Icon_WEP_GROZA.Icon_WEP_GROZA",
                Attachments = {
                    203001,  -- 红点瞄准镜
                }
            },
            { 
                WeaponID = 101006, 
                Name = "AUG A3突击步枪",
                IconPath = "/Game/Arts/UI/TableIcons/ItemIcon/Weapon/Icon_WEP_AUG.Icon_WEP_AUG",
                Attachments = {
                    203001,  -- 红点瞄准镜
                }
            },
            { 
                WeaponID = 101007, 
                Name = "QBZ95突击步枪",
                IconPath = "/Game/Arts/UI/TableIcons/ItemIcon/Weapon/Icon_WEP_QBZ95_Small.Icon_WEP_QBZ95_Small",
                Attachments = {
                    203001,  -- 红点瞄准镜
                }
            },
            { 
                WeaponID = 101008, 
                Name = "FAMAS突击步枪",
                IconPath = "/Game/Arts/UI/TableIcons/ItemIcon/Weapon/Icon_WEP_Famas.Icon_WEP_Famas",
                Attachments = {
                    203001,  -- 红点瞄准镜
                }
            },
            { 
                WeaponID = 101009, 
                Name = "M249轻机枪",
                IconPath = "/Game/Arts/UI/TableIcons/ItemIcon/Weapon/Icon_WEP_M249.Icon_WEP_M249",
                Attachments = {
                    203001,  -- 红点瞄准镜
                }
            },
            { 
                WeaponID = 103001, 
                Name = "Kar98K狙击枪",
                IconPath = "/Game/Arts/UI/TableIcons/ItemIcon/Weapon/Icon_WEP_Kar98k.Icon_WEP_Kar98k",
                Attachments = {
                    203004,  -- 4倍 瞄准镜
                }
            },
            { 
                WeaponID = 104001, 
                Name = "双管猎枪",
                IconPath = "/Game/Arts/UI/TableIcons/ItemIcon/Weapon/Icon_WEP_S686.Icon_WEP_S686",
            },
            { 
                WeaponID = 106001, 
                Name = "P92手枪",
                IconPath = "/Game/Arts/UI/TableIcons/ItemIcon/Weapon/Icon_WEP_P92.Icon_WEP_P92",
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
    "bInitializedWeapon",
    "currentHP",
    "maxHP"
end

-- 游戏开始时调用
function UGCPlayerPawn:ReceiveBeginPlay()
    --ugcprint("[PawnDebug] Enter ReceiveBeginPlay. self="..tostring(self) .. ", HasAuthority=" .. tostring(self:HasAuthority())) -- CLIENT LOG POINT A
    self.SuperClass.ReceiveBeginPlay(self)
    --ugcprint("[PawnDebug] After SuperClass.ReceiveBeginPlay. self="..tostring(self)) -- CLIENT LOG POINT B
    self.OnCharacterHpChange:Add(self.OnHealthChanged, self)
    --ugcprint("[PawnDebug] After OnCharacterHpChange:Add. self="..tostring(self)) -- CLIENT LOG POINT C
    
    -- 只在本地客户端加定时器  （捕获HP）
    if not self:HasAuthority() then
        ugcprint("[PawnDebug] Client: Setting up _debugHpTimer. self="..tostring(self)) -- CLIENT LOG POINT D
        if not self._debugHpTimer then
            self._debugHpTimer = UGCTimer.SetTimer(function()
                ugcprint("[PawnDebug] Client _debugHpTimer EXECUTING. self="..tostring(self))
                local health = UGCPawnAttrSystem.GetHealth(self)
                local maxHealth = UGCPawnAttrSystem.GetHealthMax(self)
                ugcprint("[PawnDebug] Client _debugHpTimer: Pawn Health="..tostring(health)..", MaxHealth="..tostring(maxHealth)..", self="..tostring(self))
            end, 1.0, true)
        end
    end

    
    -- 只在服务器上处理武器逻辑 和 HP同步
    if self:HasAuthority() then 
        ugcprint("[PawnDebug] Server: Entered HasAuthority block for weapon and HP sync. self=" .. tostring(self)) -- LOG POINT 1
        local initDelegate = ObjectExtend.CreateDelegate(self, function()
            local playerKey = UGCGameSystem.GetPlayerKeyByPlayerPawn(self)
            if not playerKey then
                ObjectExtend.DestroyDelegate(initDelegate)
                return
            end
            
            if self.bInitializedWeapon then
                ObjectExtend.DestroyDelegate(initDelegate)
                return
            end
            
            if WeaponSystem.PlayerLevels[playerKey] then
                self.CurrentWeaponLevel = WeaponSystem.PlayerLevels[playerKey]
                ugcprint("[Debug] 复活后恢复武器等级: " .. self.CurrentWeaponLevel)
            else
                self.CurrentWeaponLevel = 1
                WeaponSystem.PlayerLevels[playerKey] = 1
                ugcprint("[Debug] 首次初始化武器等级: " .. self.CurrentWeaponLevel)
            end
            
            local BackPackInfo = UGCBackPackSystem.GetAllItemData(self)
            for k, v in pairs(BackPackInfo) do
                UGCBackPackSystem.DropItem(self, v.ItemID, v.Count, true)
            end
            
            local weapon = WeaponSystem.WeaponLevels[self.CurrentWeaponLevel]
            if weapon then
                ugcprint("[Debug] 给予武器: " .. weapon.Name .. " (ID: " .. weapon.WeaponID .. ")")
                UGCBackPackSystem.AddItem(self, weapon.WeaponID, 1)
                
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
            self.bInitializedWeapon = true
            ObjectExtend.DestroyDelegate(initDelegate)
        end)
        KismetSystemLibrary.K2_SetTimerDelegateForLua(initDelegate, self, 0.5, false)

        -- _forceSyncHp实现部分
        ugcprint("[PawnDebug] Server: About to check/setup _forceSyncHp timer. self=" .. tostring(self)) -- LOG POINT 2
        if not self._forceSyncHp then
            ugcprint("[PawnDebug] Server: Setting up _forceSyncHp timer (SIMPLIFIED CALLBACK). self=" .. tostring(self)) -- LOG POINT 3 (modified)
            self._forceSyncHp = UGCTimer.SetTimer(function()
                ugcprint("[PawnDebug] Server: _forceSyncHp TIMER CALLBACK EXECUTING. self=" .. tostring(self)) -- SIMPLIFIED LOG POINT 4
                
                -- 获取血量数据并同步到客户端
                local health = UGCPawnAttrSystem.GetHealth(self)
                local maxHealth = UGCPawnAttrSystem.GetHealthMax(self)
                
                ugcprint("[PawnDebug] Server: 准备同步血量, health=" .. tostring(health) .. ", maxHealth=" .. tostring(maxHealth))
                
                -- 直接设置玩家角色血量变量（这些会在下一次网络同步中自动复制到客户端）
                self._lastHp = health
                self._lastMaxHp = maxHealth
                
                -- 直接通过RPC同步血量 - 使用原始CallUnrealRPC (单播到所有客户端)
                local allControllers = UGCGameSystem.GetAllPlayerControllers()
                for _, controller in ipairs(allControllers) do
                    ugcprint("[PawnDebug] Server: 向Controller发送血量同步RPC, controller=" .. tostring(controller))
                    UnrealNetwork.CallUnrealRPC(controller, controller, "ClientRPC_SyncPawnHP", self, health, maxHealth)
                end 
                
            end, 0.5, true) -- 保持较低的更新频率以避免过载
        end
    else
        ugcprint("[PawnDebug] Client: self:HasAuthority() is FALSE for HP sync part. Skipping server-side HP sync setup. self=" .. tostring(self) .. ", CurrentHealth (API): " .. tostring(UGCPawnAttrSystem.GetHealth(self))) -- LOG POINT 6
    end
    
    ugcprint("[PawnDebug] End of ReceiveBeginPlay (ATTEMPTING FINAL LOG). IsAuthority="..tostring(self:HasAuthority())..", Health (API)="..tostring(UGCPawnAttrSystem.GetHealth(self)) .. ", for self=" .. tostring(self)) -- FINAL LOG PLACEMENT CHECK
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
                
                -- 尝试先通过GameManager通知游戏结束
                local GameManager = require('Script.Common.GameManager')
                if GameManager and GameManager.IsInitialized then
                    ugcprint("[Debug] 通过GameManager通知游戏结束")
                    GameManager:NotifyGameEnd(killerKey, killerPawn.GrounpID or 0)
                else
                    -- 兼容性处理：如果GameManager不可用，尝试通过GameMode
                    local gameMode = UGCGameSystem.GameMode
                    if gameMode and gameMode.NotifyGameEnd then
                        ugcprint("[Debug] 通过GameMode通知游戏结束")
                        gameMode:NotifyGameEnd(killerKey, killerPawn.GrounpID or 0)
                    end
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
    ugcprint("[PawnDebug] OnHealthChanged被调用: NewHealth=" .. tostring(NewHealth) .. ", OldHealth=" .. tostring(OldHealth))
    
    -- 在服务器上，向所有客户端广播血量变化
    if self:HasAuthority() then
        local maxHealth = UGCPawnAttrSystem.GetHealthMax(self)
        ugcprint("[PawnDebug] 服务器: 血量变化，广播到所有客户端, NewHealth=" .. tostring(NewHealth) .. ", MaxHealth=" .. tostring(maxHealth))
        
        -- 保存为最新数据
        self._lastHp = NewHealth
        self._lastMaxHp = maxHealth
        
        -- 向所有客户端广播血量更新
        self:ClientMulticast_SyncHp(NewHealth, maxHealth)
        
        -- 对每个客户端单独发送
        local allControllers = UGCGameSystem.GetAllPlayerController()
        for _, controller in ipairs(allControllers) do
            if controller and controller.ClientRPC_SyncPawnHP then
                ugcprint("[PawnDebug] 服务器: 发送血量同步RPC给controller: " .. tostring(controller))
                UnrealNetwork.CallUnrealRPC(controller, controller, "ClientRPC_SyncPawnHP", self, NewHealth, maxHealth)
            end
        end
    end
    
    -- 在客户端处理伤害UI效果
    if self:HasAuthority() == false and NewHealth < OldHealth then
        ugcprint("[PawnDebug] 客户端: 显示伤害特效")
        TryExecuteCallerFunction(UIManager:GetUIByType(UIManager.HitUIID), "ShowRingDamageHit", NewHealth, OldHealth)
    end
end

-- 死亡不掉落盒子
function UGCPlayerPawn:IsSkipSpawnDeadTombBox(EventInstigater)
    return true
end

-- 客户端RPC实现
function UGCPlayerPawn:ClientMulticast_SyncHp(health, maxHealth)
    ugcprint("[PawnDebug] ClientMulticast_SyncHp收到数据, health="..tostring(health)..", maxHealth="..tostring(maxHealth)..", self="..tostring(self))
    
    -- 保存当前健康值到本地缓存（用于UI显示）
    if not self._lastHp then
        ugcprint("[PawnDebug] 首次设置血量缓存")
    elseif self._lastHp ~= health or self._lastMaxHp ~= maxHealth then
        ugcprint("[PawnDebug] 血量缓存已更新: "..tostring(self._lastHp).."/"..tostring(self._lastMaxHp).." -> "..tostring(health).."/"..tostring(maxHealth))
    end
    
    -- 保存血量缓存
    self._lastHp = health
    self._lastMaxHp = maxHealth
    
    -- 检查是否为本地玩家角色
    local controller = UGCPlayerSystem.GetLocalController()
    if controller and controller:K2_GetPawn() == self then
        ugcprint("[PawnDebug] 本地玩家血量更新，通知UI")
        -- 主动触发UI更新
        local uiHP = TryExecuteCallerFunction(UIManager, "GetUIByType", "UI_HP")
        if uiHP then
            ugcprint("[PawnDebug] 找到UI_HP，触发即时更新")
            uiHP:UpdateHealthFromPawn()
        end
    end
end

return UGCPlayerPawn