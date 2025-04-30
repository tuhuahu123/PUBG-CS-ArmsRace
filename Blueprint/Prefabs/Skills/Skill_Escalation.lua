---@class Skill_Escalation_C:PESkillPassiveSkillTemplate_C
--Edit Below--
local Skill_Escalation = {}
 
function Skill_Escalation:OnEnableSkill_BP()
    Skill_Escalation.SuperClass.OnEnableSkill_BP(self)
end

function Skill_Escalation:OnDisableSkill_BP()
    Skill_Escalation.SuperClass.OnDisableSkill_BP(self)
end

function Skill_Escalation:OnActivateSkill_BP()
    Skill_Escalation.SuperClass.OnActivateSkill_BP(self)
end

function Skill_Escalation:OnDeActivateSkill_BP()
    Skill_Escalation.SuperClass.OnDeActivateSkill_BP(self)
end

function Skill_Escalation:CanActivateSkill_BP()
    return Skill_Escalation.SuperClass.CanActivateSkill_BP(self)
end

return Skill_Escalation