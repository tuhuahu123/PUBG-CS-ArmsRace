---@class Skill_Sprint03_C:PESkillTemplate_Active_C
--Edit Below--
local Skill_Sprint03 = {}
 
--[[
function Skill_Sprint03:OnEnableSkill_BP()
end

function Skill_Sprint03:OnDisableSkill_BP(DeltaTime)
end

function Skill_Sprint03:OnActivateSkill_BP()
end

function Skill_Sprint03:OnDeActivateSkill_BP()
end

function Skill_Sprint03:CanActivateSkill_BP()
end

--]]

function Skill_Sprint03:OnActivateSkill_BP()
    print("Skill_Sprint03:OnActivateSkill_BP -- 技能触发")
    if self:HasAuthority() then
        print("Skill_Sprint03:OnActivateSkill_BP -- 设置无敌状态")
        --self.Owner.Owner:SetInvincible(true) 
        self:GetNetOwnerActor():SetInvincible(true)
    end

    Skill_Sprint03.SuperClass.OnActivateSkill_BP(self);
end

function Skill_Sprint03:OnDeActivateSkill_BP()
    print("Skill_Sprint03:OnDeActivateSkill_BP -- 退出技能")
    if self:HasAuthority() then
        --关闭无敌状态
        print("Skill_Sprint03:OnDeActivateSkill_BP -- 关闭无敌状态")
        --self.Owner.Owner:SetInvincible(false)
        self:GetNetOwnerActor():SetInvincible(false)
    end
    Skill_Sprint03.SuperClass.OnDeActivateSkill_BP(self);
end

return Skill_Sprint03