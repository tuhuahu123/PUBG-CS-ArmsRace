-- Script/Config/GamePhaseConfig.lua
-- 游戏阶段配置信息

local GamePhaseConfig = {
    -- 准备阶段
    Preparation = {
        PhaseName = "准备阶段",
        Duration = 15,         -- 持续15秒
        NextPhase = "InProgress",
        RestartDelay = 5.0     -- 仅用于PostMatch结束后到Preparation的延迟
    },
    
    -- 游戏进行阶段
    InProgress = {
        PhaseName = "游戏中",
        Duration = 360,        -- 持续6分钟
        NextPhase = "PostMatch"
    },
    
    -- 结算阶段
    PostMatch = {
        PhaseName = "结算阶段",
        Duration = 10,         -- 持续10秒
        NextPhase = "Preparation", -- 游戏结束后会重新回到准备阶段
        RestartDelay = 5.0     -- 结算阶段结束后到下一个准备阶段开始的延迟时间
    }
    -- 移除了原有的 WeaponConfig 和 WeaponLevels，这些现在由 UGCPlayerPawn.lua 管理
}

return GamePhaseConfig 