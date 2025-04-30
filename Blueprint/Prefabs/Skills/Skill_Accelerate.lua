---@class Skill_Accelerate_C:PESkillTemplate_Active_C
--Edit Below--
local Skill_Accelerate = {}
 
--[[
function Skill_Accelerate:OnEnableSkill_BP()
end

function Skill_Accelerate:OnDisableSkill_BP(DeltaTime)
end

function Skill_Accelerate:OnActivateSkill_BP()
end

function Skill_Accelerate:OnDeActivateSkill_BP()
end

function Skill_Accelerate:CanActivateSkill_BP()
end

--]]

function Skill_Accelerate:OnActivateSkill_BP()
    print("Skill_Accelerate:OnActivateSkill_BP -- 技能触发")
    if self:HasAuthority() then
        print("Skill_Accelerate:OnActivateSkill_BP -- 设置无敌状态")
        --self.Owner.Owner:SetInvincible(true) 
        self:GetNetOwnerActor():SetInvincible(true)
    end

    Skill_Accelerate.SuperClass.OnActivateSkill_BP(self);
end

function Skill_Accelerate:OnDeActivateSkill_BP()
    print("Skill_Accelerate:OnDeActivateSkill_BP -- 退出技能")
    if self:HasAuthority() then
        --关闭无敌状态
        print("Skill_Accelerate:OnDeActivateSkill_BP -- 关闭无敌状态")
        --self.Owner.Owner:SetInvincible(false)
        self:GetNetOwnerActor():SetInvincible(false)
    end
    Skill_Accelerate.SuperClass.OnDeActivateSkill_BP(self);
end

return Skill_Accelerate