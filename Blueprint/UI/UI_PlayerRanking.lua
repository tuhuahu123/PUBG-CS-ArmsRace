---@class UI_PlayerRanking_C:UUserWidget
---@field Border_PlayerData UBorder
---@field TextBlock_Damage UTextBlock
---@field TextBlock_KillNumber UTextBlock
---@field TextBlock_PlayerName UTextBlock
---@field TextBlock_Ranking UTextBlock
--Edit Below--
local UI_PlayerRanking = { bInitDoOnce = false } -- UI_PlayerRanking类初始化，设置初始化标志为false

local WBP_DataList = { bInitDoOnce = false; }; -- WBP_DataList类初始化，设置初始化标志为false
-- 将自己那一列设置为黄色
function WBP_DataList:SelfPlayerData()
    print("WBP_DataList:SelfPlayerData") -- 打印函数调用信息，用于调试
    
    self.TextBlock_Damage:SetColorAndOpacity(self.MyPlayerTextColor) -- 设置伤害文本颜色为玩家专属颜色
    self.TextBlock_KillNumber:SetColorAndOpacity(self.MyPlayerTextColor) -- 设置击杀数文本颜色为玩家专属颜色
    self.TextBlock_PlayerName:SetColorAndOpacity(self.MyPlayerTextColor) -- 设置玩家名称文本颜色为玩家专属颜色
    self.TextBlock_Ranking:SetColorAndOpacity(self.MyPlayerTextColor) -- 设置排名文本颜色为玩家专属颜色
end


function WBP_DataList:RefreshPlayerData(PlayerData,Ranking)
    
    if PlayerData then -- 检查PlayerData是否存在
        self.TextBlock_PlayerName:SetText(PlayerData.PlayerName) -- 设置玩家名称文本
        self.TextBlock_KillNumber:SetText(tostring(PlayerData.KillNumber)) -- 设置击杀数文本，转换为字符串
        self.TextBlock_Damage:SetText(tostring(PlayerData.PlayerDamage)) -- 设置伤害文本，转换为字符串
        self.TextBlock_Ranking:SetText(tostring(Ranking)) -- 设置排名文本，转换为字符串

    end
end

--[==[ Construct
function UI_PlayerRanking:Construct()
	
end
-- Construct ]==]

-- function UI_PlayerRanking:Tick(MyGeometry, InDeltaTime) -- 更新函数，暂未实现

-- end

-- function UI_PlayerRanking:Destruct() -- 析构函数，暂未实现

-- end

return UI_PlayerRanking -- 返回UI_PlayerRanking类