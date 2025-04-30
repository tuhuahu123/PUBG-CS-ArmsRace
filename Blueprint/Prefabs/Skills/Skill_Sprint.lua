---@class Skill_Sprint_C:PESkillTemplate_Active_C
--Edit Below--
local Skill_Sprint = {}
 
--[[
function Skill_Sprint:OnEnableSkill_BP()
end

function Skill_Sprint:OnDisableSkill_BP(DeltaTime)
end

function Skill_Sprint:OnActivateSkill_BP()
end

function Skill_Sprint:OnDeActivateSkill_BP()
end

function Skill_Sprint:CanActivateSkill_BP()
end

--]]

function Skill_Sprint:OnActivateSkill_BP()
    print("Skill_Sprint:OnActivateSkill_BP -- 技能触发")
    if self:HasAuthority() then
        print("Skill_Sprint:OnActivateSkill_BP -- 设置无敌状态")
        --self.Owner.Owner:SetInvincible(true) 
        self:GetNetOwnerActor():SetInvincible(true)
    end

    Skill_Sprint.SuperClass.OnActivateSkill_BP(self);
end

function Skill_Sprint:OnDeActivateSkill_BP()
    print("Skill_Sprint:OnDeActivateSkill_BP -- 退出技能")
    if self:HasAuthority() then
        --关闭无敌状态
        print("Skill_Sprint:OnDeActivateSkill_BP -- 关闭无敌状态")
        --self.Owner.Owner:SetInvincible(false)
        self:GetNetOwnerActor():SetInvincible(false)
    end
    Skill_Sprint.SuperClass.OnDeActivateSkill_BP(self);
end

return Skill_Sprint