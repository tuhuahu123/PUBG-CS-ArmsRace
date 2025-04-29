local Escalation = {}
 
function Escalation:OnEnableSkill_BP()
    Escalation.SuperClass.OnEnableSkill_BP(self)
end

function Escalation:OnDisableSkill_BP()
    Escalation.SuperClass.OnDisableSkill_BP(self)
end

function Escalation:OnActivateSkill_BP()
    Escalation.SuperClass.OnActivateSkill_BP(self)
end

function Escalation:OnDeActivateSkill_BP()
    Escalation.SuperClass.OnDeActivateSkill_BP(self)
end

function Escalation:CanActivateSkill_BP()
    return Escalation.SuperClass.CanActivateSkill_BP(self)
end

return Escalation