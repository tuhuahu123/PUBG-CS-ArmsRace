---@class UI_image_C:UUserWidget
---@field Image_WeaponName UImage
---@field TextBlock_WeaponName UTextBlock
--Edit Below--
local UI_image = { bInitDoOnce = false } 

-- 当前武器信息
UI_image.currentWeaponInfo = {
    iconPath = nil,
    name = nil
}

function UI_image:Construct()
	self:LuaInit()
end

-- function UI_image:Tick(MyGeometry, InDeltaTime)

-- end

-- function UI_image:Destruct()

-- end

-- [Editor Generated Lua] function define Begin:
function UI_image:LuaInit()
	if self.bInitDoOnce then
		return
	end
	self.bInitDoOnce = true
	
	-- 绑定UI属性
	self.Image_Weapon:BindingProperty("Brush", self.Weapon_image_Brush, self)
	if self.TextBlock_WeaponName then
		self.TextBlock_WeaponName:BindingProperty("Text", self.WeaponName_Text, self)
	end

	-- 初始设置下一把武器图标
	self:UpdateNextWeaponIcon()
end

-- 更新下一把武器图标
function UI_image:UpdateNextWeaponIcon()
	local controller = UGCPlayerSystem.GetLocalController()
	if not controller then return end
	
	local pawn = controller:K2_GetPawn()
	if not pawn then return end
	
	-- 检查玩家是否有当前武器等级属性
	if pawn.CurrentWeaponLevel and _G.GunGameWeaponSystem and _G.GunGameWeaponSystem.WeaponLevels then
		local currentLevel = pawn.CurrentWeaponLevel
		local nextLevel = currentLevel + 1
		
		-- 确保下一级别不超出范围
		if nextLevel <= #_G.GunGameWeaponSystem.WeaponLevels then
			local nextWeaponInfo = _G.GunGameWeaponSystem.WeaponLevels[nextLevel]
			
			if nextWeaponInfo then
				-- 更新缓存
				self.currentWeaponInfo.iconPath = nextWeaponInfo.IconPath
				self.currentWeaponInfo.name = nextWeaponInfo.Name
				
				-- 强制刷新UI
				self:RefreshWeaponImage()
				
				ugcprint("[UI_image] 下一把武器图标已更新: " .. nextWeaponInfo.Name .. ", IconPath: " .. nextWeaponInfo.IconPath)
			end
		else
			-- 已经是最后一级武器
			self.currentWeaponInfo.iconPath = nil
			self.currentWeaponInfo.name = "最终武器"
			self:RefreshWeaponImage()
		end
	end
	
	-- 设置定时器定期检查更新
	if not self.updateTimer then
		self.updateTimer = UGCTimer.SetTimer(function()
			self:UpdateNextWeaponIcon()
		end, 1.0, true)
	end
end

-- 刷新武器图标
function UI_image:RefreshWeaponImage()
	if self.Image_Weapon then
		self.Image_Weapon:ForceLayoutPrepass() 
	end
	
	if self.TextBlock_WeaponName then
		self.TextBlock_WeaponName:ForceLayoutPrepass()
	end
end

-- 获取武器图标Brush
function UI_image:Weapon_image_Brush(ReturnValue)
	if not self.currentWeaponInfo.iconPath then
		-- 默认返回空Brush
		return {}
	end
	
	-- 记录原始路径
	local originalPath = self.currentWeaponInfo.iconPath
	
	-- 处理路径格式 - 移除开头的斜杠和结尾的重复部分
	local assetPath = self.currentWeaponInfo.iconPath
	if assetPath:sub(1, 1) == "/" then
		assetPath = assetPath:sub(2)  -- 移除开头的斜杠
	end
	
	-- 对于路径如 "Game/Arts/.../Icon_WEP_M16A4.Icon_WEP_M16A4"，移除结尾的重复部分
	local lastDot = assetPath:find("%.[^%.]+$")
	if lastDot then
		local pathWithoutExt = assetPath:sub(1, lastDot-1)
		local ext = assetPath:sub(lastDot+1)
		
		-- 如果扩展名是路径的最后部分，则使用不带扩展名的路径
		if pathWithoutExt:sub(-#ext) == ext then
			assetPath = pathWithoutExt
		end
	end
	
	-- 使用直接的资源引用方式（UE4常用）
	local texturePath = "Texture2D'" .. assetPath .. "'"
	ugcprint("[UI_image] 尝试加载纹理: " .. texturePath)
	
	return {
		ResourceObject = UE.LoadObject(nil, texturePath),
		DrawAs = 0, -- Image
		TintColor = {R=1, G=1, B=1, A=1}, -- 白色，完全不透明
	}
end

-- 获取武器名称文本
function UI_image:WeaponName_Text(ReturnValue)
	if self.currentWeaponInfo.name then
		return "下一把武器：" .. self.currentWeaponInfo.name
	end
	return "下一把武器："
end

-- [Editor Generated Lua] function define End;

-- 接收武器升级通知
function UI_image:OnWeaponUpgraded()
	-- 立即更新武器图标
	self:UpdateNextWeaponIcon()
	
	-- 播放升级动画
	self:PlayWeaponUpgradeAnimation()
end

-- 播放武器升级动画
function UI_image:PlayWeaponUpgradeAnimation()
	if not self.Image_Weapon then return end
	
	-- 创建一个简单的缩放动画效果
	local startScale = 0.8
	local endScale = 1.2
	local duration = 0.5
	local elapsed = 0
	
	-- 保存原始缩放
	local originalScale = self.Image_Weapon:GetRenderScale()
	
	-- 创建动画定时器
	self.animationTimer = UGCTimer.SetTimer(function()
		elapsed = elapsed + 0.016 -- 假设16ms每帧
		
		if elapsed >= duration then
			-- 动画完成，恢复原始缩放
			self.Image_Weapon:SetRenderScale(originalScale.X, originalScale.Y)
			UGCTimer.ClearTimer(self.animationTimer)
			self.animationTimer = nil
			return
		end
		
		-- 计算当前缩放
		local progress = elapsed / duration
		local currentScale
		
		if progress <= 0.5 then
			-- 放大阶段
			local t = progress * 2 -- 0到1
			currentScale = startScale + (endScale - startScale) * t
		else
			-- 恢复阶段
			local t = (progress - 0.5) * 2 -- 0到1
			currentScale = endScale + (originalScale.X - endScale) * t
		end
		
		-- 应用缩放
		self.Image_Weapon:SetRenderScale(currentScale, currentScale)
	end, 0.016, true) -- 大约60fps
end

-- 手动预加载资源
function UI_image:PreloadWeaponIcons()
	if _G.GunGameWeaponSystem and _G.GunGameWeaponSystem.WeaponLevels then
		for _, weaponInfo in ipairs(_G.GunGameWeaponSystem.WeaponLevels) do
			if weaponInfo.IconPath then
				-- 预加载资源
				if UObjectGlobalStatics then
					UObjectGlobalStatics.AsyncLoadAsset(weaponInfo.IconPath)
				end
			end
		end
		ugcprint("[UI_image] 已预加载所有武器图标")
	end
end

return UI_image