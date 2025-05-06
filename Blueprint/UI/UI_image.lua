---@class UI_image_C:UUserWidget
---@field Image_Weapon UImage
---@field TextBlock_WeaponName UTextBlock
--Edit Below--
local UI_image = { bInitDoOnce = false } 


function UI_image:Construct()
	self:LuaInit();
	
end


-- function UI_image:Tick(MyGeometry, InDeltaTime)

-- end

-- function UI_image:Destruct()

-- end

-- [Editor Generated Lua] function define Begin:
function UI_image:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
	-- [Editor Generated Lua] BindingProperty Begin:
	self.Weapon_image:BindingProperty("Brush", self.Weapon_image_Brush, self);
	-- [Editor Generated Lua] BindingProperty End;
	
	-- [Editor Generated Lua] BindingEvent Begin:
	-- [Editor Generated Lua] BindingEvent End;
end

function UI_image:Weapon_image_Brush(ReturnValue)
	return { };
end

-- [Editor Generated Lua] function define End;

return UI_image