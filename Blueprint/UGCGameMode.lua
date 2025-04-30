---@class UGCGameMode_C:BP_UGCGameBase_C
--Edit Below--
local UGCGameMode = {}; 

--死亡玩家的Key和击杀者的Key--
function UGCGameMode:HandlePlayerDeath(deadPlayerKey, killerPlayerKey)    
    ugcprint("[UGCGameMode] HandlePlayerDeath: deadPlayerKey=" .. tostring(deadPlayerKey))
    
    -- 设置复活时间为1秒
    local respawnTime = 1.0
    
    -- 创建延迟执行复活的委托
    local respawnTimerDelegate = ObjectExtend.CreateDelegate(self, function()
        ugcprint("[UGCGameMode] 开始复活玩家: " .. tostring(deadPlayerKey))
        
        -- 使用UGCGameSystem复活
        local respawnSuccess = UGCGameSystem.RespawnPlayer(deadPlayerKey)
        ugcprint("[UGCGameMode] 复活尝试结果: " .. tostring(respawnSuccess))
        
        -- 销毁委托
        ObjectExtend.DestroyDelegate(respawnTimerDelegate)
    end)
    
    -- 设置复活计时器
    ugcprint("[UGCGameMode] 设置复活计时器，延迟: " .. tostring(respawnTime) .. "秒")
    KismetSystemLibrary.K2_SetTimerDelegateForLua(respawnTimerDelegate, self, respawnTime, false)
end




function UGCGameMode:ReceiveBeginPlay()
    self.SuperClass.ReceiveBeginPlay(self)
    
    if UGCGameSystem.IsServer() then
        -- 获取复活组件并进行设置
        local RespawnComponent = UGCGameSystem.GetRespawnComponent()
        if RespawnComponent then
            -- 设置复活和无敌时间都为1秒
            RespawnComponent:SetRespawnTime(1.0, 1.0)
            ugcprint("设置复活时间为1秒，无敌时间为1秒")
            
            -- 确保启用随机重生
            RespawnComponent.bIsEnableRespawn = true
            RespawnComponent.bIsRespawnGenerateInitialItems = true
            RespawnComponent.bIsRespawnKeepSuitSkinConfig = true
            
            ugcprint("复活组件初始化完成")
        else
            ugcprint("错误: 无法获取复活组件!")
        end
    end
end







-- function UGCGameMode:ReceiveBeginPlay()

-- end
-- function UGCGameMode:ReceiveTick(DeltaTime)

-- end
-- function UGCGameMode:ReceiveEndPlay()
 
-- end
return UGCGameMode;