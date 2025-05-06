---@class UGCGameState_C:BP_UGCGameState_C
--Edit Below--
UGCGameSystem.UGCRequire('Script.Common.ue_enum_custom')   -- 引入自定义枚举


local UGCGameState = {}; 

-- 隐藏部分和平自带的UI
local function HideOriginalUI()
    local MainControlPanelUI = UGCWidgetManagerSystem.GetMainUI()

    if MainControlPanelUI == nil then
        return
    end

    local ShootingUIPanel = MainControlPanelUI.ShootingUIPanel
    local MainControlBaseUI = MainControlPanelUI.MainControlBaseUI

    if ShootingUIPanel then
        ShootingUIPanel.MultiLayer_RightWeaponSlot:AddAdvancedCollapsedCount(1)	 -- 右枪械栏
        ShootingUIPanel.Customize_ThrowPlus:AddAdvancedCollapsedCount(1)         -- 投掷模式
    end
    
    if MainControlBaseUI then
        MainControlBaseUI.Image_0:AddAdvancedCollapsedCount(1)                   -- 顶部三角标
        MainControlBaseUI.NavigatorPanel:AddAdvancedCollapsedCount(1)            -- 顶部指南标
        MainControlBaseUI.CanvasPanel_MiniMapAndSetting:AddAdvancedCollapsedCount(1)    -- 小地图
        MainControlBaseUI.CanvasPanelSurviveKill:AddAdvancedCollapsedCount(1)    -- 存活人数
        MainControlBaseUI.Image_IngameLogo:AddAdvancedCollapsedCount(1)          -- 和平顶部Logo
        MainControlBaseUI.Backpack_Border:AddAdvancedCollapsedCount(1)			 -- 背包
        MainControlBaseUI.PlayerInfoSocket:GetActivedSocket(false).VerticalLifeInfo:AddAdvancedCollapsedCount(1)	-- 人物血条
    end
end


function UGCGameState:ReceiveBeginPlay()
    self.SuperClass.ReceiveBeginPlay(self);

    if self:HasAuthority() == true then 
        -- 只有客户端加载UI
    else

        HideOriginalUI()   -- 隐藏和平精英的默认UI

        local MainUI = UE.LoadClass( UGCMapInfoLib.GetRootLongPackagePath().. "Asset/Blueprint/UI/UI_Main.UI_Main_C");
        ugcprint("Load MainUI Class");
        -- 加载 MainUI 蓝图类

        local PlayerController = GameplayStatics.GetPlayerController(self, 0);
        ugcprint("Get Player Controller");
        -- 获得当前PlayerController

        local MainUI_BP = UserWidget.NewWidgetObjectBP(PlayerController,MainUI);
        ugcprint("Load MainUI_BP");
        -- 加载 MainUI

        MainUI_BP:AddToViewport();
        ugcprint("MainUI_BP AddToViewport");
        -- 将 MainUI 加入视口，显示UI
    end
end

return UGCGameState;


