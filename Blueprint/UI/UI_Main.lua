---@class UI_Main_C:UUserWidget
---@field UI_HP UI_HP_C
---@field UI_image UI_image_C
---@field UI_PlayerRanking UI_PlayerRanking_C
--Edit Below--
local UI_Main = { bInitDoOnce = false } 

function UI_Main:Construct()
    if not self.bInitDoOnce then
        self.bInitDoOnce = true
        -- 这里设置UI的可见性
        self:SetVisibility(0) -- 0表示Visible，确保UI是可见的
    end
end

function UI_Main:Tick(MyGeometry, InDeltaTime)
    -- UI的每帧更新逻辑
end

function UI_Main:Destruct()
    -- UI销毁时的清理逻辑
end

return UI_Main