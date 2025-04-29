local BUFF_LevelUp = {}
 



-- buff启动条件
--[[
function BUFF_LevelUp:CanApply_BP(OwnerActor)
-- return true
end
--]]

-- buff开始
--[[
function BUFF_LevelUp:OnApply_BP(OwnerActor)

end
--]]

-- buff结束
--[[
function BUFF_LevelUp:OnUnApply_BP(OwnerActor, Reason)

end
--]]

-- buff合并条件，A为当前身上已有buff，B为外来buff，当要挂载外来buff时会判断A.CanMerge(B)
--[[
function BUFF_LevelUp:CanMerge_BP(PersistEffect)
-- return true
end
--]]

-- buff合并，A为当前身上已有buff，B为外来buff，调用A.OnMerge(B)
--[[
function BUFF_LevelUp:OnMerge_BP(PersistEffect)

end
--]]

-- 开启Tick需要SetTickEnable(true)，或buff为间隔触发类型会自动开启
--[[
function BUFF_LevelUp:Tick_BP(OwnerActor, DeltaTime)

end
--]]

--[[
function BUFF_LevelUp:OnInterrupted_BP(OwnerActor)

end
--]]

-- buff总持续时长变化，如修改ApplyTime、修改StackNum
--[[
function BUFF_LevelUp:OnTotalDurationChange_BP(PreTime, CurTime)

end
--]]

-- buff堆叠层数变化
--[[
function BUFF_LevelUp:OnStackChange_BP(PreNum, CurNum)

end
--]]

-- buff触发前条件判断
--[[
function BUFF_LevelUp:CanTrigger_BP()
	return true
end
--]]

-- buff触发效果
--[[
function BUFF_LevelUp:OnTrigger_BP(Delta)

end
--]]

return BUFF_LevelUp