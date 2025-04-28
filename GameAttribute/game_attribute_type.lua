
-- auto exported game_attributes 
-- including native attributes and custom attributes 


---@enum UGCNativeGameAttributeType
UGCNativeGameAttributeType = { 
	--Character [血量-Health],
	Character_Health = 'Health',
	--Character [最大血量-HealthMax],
	Character_HealthMax = 'HealthMax',
	--Character [技能急速-SkillCDRecoverRate],
	Character_SkillCDRecoverRate = 'SkillCDRecoverRate',
	--Character [信号值-SignalHP],
	Character_SignalHP = 'SignalHP',
	--Character [当前能量值-EnergyCurrent],
	Character_EnergyCurrent = 'Energy|EnergyCurrent',
	--Character [UGC移动速度倍率-UGCGeneralMoveSpeedScale],
	Character_UGCGeneralMoveSpeedScale = 'UGCGeneralMoveSpeedScale',

---------------------------------------------------------

	--Weapon [无描述-MaxBulletNumInOneClip],
	Weapon_MaxBulletNumInOneClip = 'ShootWeaponEntityComp|MaxBulletNumInOneClip',
	--Weapon [无描述-AccessoriesRecoveryFactor],
	Weapon_AccessoriesRecoveryFactor = 'ShootWeaponEntityComp|AccessoriesRecoveryFactor',
	--Weapon [换弹时间影响因子-ReloadTimeFactorWrapper],
	Weapon_ReloadTimeFactorWrapper = 'ReloadTimeFactorWrapper',
	--Weapon [切枪时间影响因子-SwitchTimeFactorWrapper],
	Weapon_SwitchTimeFactorWrapper = 'SwitchTimeFactorWrapper',
	--Weapon [攻击间隔影响因子-ShootIntervalFactorWrapper],
	Weapon_ShootIntervalFactorWrapper = 'ShootIntervalFactorWrapper',
	--Weapon [后坐力影响因子-RecoilFactorWrapper],
	Weapon_RecoilFactorWrapper = 'RecoilFactorWrapper',
	--Weapon [散布影响因子-DeviationFactorWrapper],
	Weapon_DeviationFactorWrapper = 'DeviationFactorWrapper',
	--Weapon [子弹基础伤害-BaseImpactDamageWrapper],
	Weapon_BaseImpactDamageWrapper = 'BaseImpactDamageWrapper',
	--Weapon [子弹基础伤害-MinimumImpactDamageWrapper],
	Weapon_MinimumImpactDamageWrapper = 'MinimumImpactDamageWrapper',
	--Weapon [子弹飞行速度-BulletFireSpeedWrapper],
	Weapon_BulletFireSpeedWrapper = 'BulletFireSpeedWrapper',
	--Weapon [最大射程-BulletRangeWrapper],
	Weapon_BulletRangeWrapper = 'BulletRangeWrapper',
	--Weapon [一次拉栓子弹装填数量-MaxBulletNumInBarrelWrapper],
	Weapon_MaxBulletNumInBarrelWrapper = 'MaxBulletNumInBarrelWrapper',
	--Weapon [弹匣容量-MaxBulletNumInOneClipWrapper],
	Weapon_MaxBulletNumInOneClipWrapper = 'MaxBulletNumInOneClipWrapper',
	--Weapon [全自动射击间隔-AutoShootIntervalWrapper],
	Weapon_AutoShootIntervalWrapper = 'AutoShootIntervalWrapper',
	--Weapon [连发射击间隔-BurstShootCDWrapper],
	Weapon_BurstShootCDWrapper = 'BurstShootCDWrapper',
	--Weapon [连发数量-BurstShootBulletsNumWrapper],
	Weapon_BurstShootBulletsNumWrapper = 'BurstShootBulletsNumWrapper',
	--Weapon [连发子弹间隔-BurstShootIntervalWrapper],
	Weapon_BurstShootIntervalWrapper = 'BurstShootIntervalWrapper',
}; 

UGCNativeGameAttributeTypeCommentMap = { 

---------------------------------------------------------

	['Health'] = 'Character [血量-Health]', 
	['HealthMax'] = 'Character [最大血量-HealthMax]', 
	['SkillCDRecoverRate'] = 'Character [技能急速-SkillCDRecoverRate]', 
	['SignalHP'] = 'Character [信号值-SignalHP]', 
	['Energy|EnergyCurrent'] = 'Character [当前能量值-EnergyCurrent]', 
	['UGCGeneralMoveSpeedScale'] = 'Character [UGC移动速度倍率-UGCGeneralMoveSpeedScale]', 

---------------------------------------------------------

	['ShootWeaponEntityComp|MaxBulletNumInOneClip'] = 'Weapon [无描述-MaxBulletNumInOneClip]', 
	['ShootWeaponEntityComp|AccessoriesRecoveryFactor'] = 'Weapon [无描述-AccessoriesRecoveryFactor]', 
	['ReloadTimeFactorWrapper'] = 'Weapon [换弹时间影响因子-ReloadTimeFactorWrapper]', 
	['SwitchTimeFactorWrapper'] = 'Weapon [切枪时间影响因子-SwitchTimeFactorWrapper]', 
	['ShootIntervalFactorWrapper'] = 'Weapon [攻击间隔影响因子-ShootIntervalFactorWrapper]', 
	['RecoilFactorWrapper'] = 'Weapon [后坐力影响因子-RecoilFactorWrapper]', 
	['DeviationFactorWrapper'] = 'Weapon [散布影响因子-DeviationFactorWrapper]', 
	['BaseImpactDamageWrapper'] = 'Weapon [子弹基础伤害-BaseImpactDamageWrapper]', 
	['MinimumImpactDamageWrapper'] = 'Weapon [子弹基础伤害-MinimumImpactDamageWrapper]', 
	['BulletFireSpeedWrapper'] = 'Weapon [子弹飞行速度-BulletFireSpeedWrapper]', 
	['BulletRangeWrapper'] = 'Weapon [最大射程-BulletRangeWrapper]', 
	['MaxBulletNumInBarrelWrapper'] = 'Weapon [一次拉栓子弹装填数量-MaxBulletNumInBarrelWrapper]', 
	['MaxBulletNumInOneClipWrapper'] = 'Weapon [弹匣容量-MaxBulletNumInOneClipWrapper]', 
	['AutoShootIntervalWrapper'] = 'Weapon [全自动射击间隔-AutoShootIntervalWrapper]', 
	['BurstShootCDWrapper'] = 'Weapon [连发射击间隔-BurstShootCDWrapper]', 
	['BurstShootBulletsNumWrapper'] = 'Weapon [连发数量-BurstShootBulletsNumWrapper]', 
	['BurstShootIntervalWrapper'] = 'Weapon [连发子弹间隔-BurstShootIntervalWrapper]', 
}; 

---@enum UGCCustomGameAttributeType
UGCCustomGameAttributeType = { 
}; 

UGCCustomGameAttributeTypeCommentMap = { 
}; 

