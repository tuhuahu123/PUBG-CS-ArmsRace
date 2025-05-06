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




return UGCPlayerController