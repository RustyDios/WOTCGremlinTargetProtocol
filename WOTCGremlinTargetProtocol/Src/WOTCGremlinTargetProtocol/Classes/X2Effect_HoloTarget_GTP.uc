//---------------------------------------------------------------------------------------
//  FILE:   X2Effect_HoloTarget_GTP.uc                                    
//           
//	Created by		RustyDios
//  Created			13/09/19	06:30
//	Last Updated	01/03/20	06:45
//
//	A version of Holotargetting given by gremlin, granted for free with Scanning Protocol
//	Code assistance given from Iridar on the XCOM Discord
//
//---------------------------------------------------------------------------------------

class X2Effect_HoloTarget_GTP extends X2Effect_Persistent config (GTPConfig);

//grab variables from the config
var config int iTARGET_PROTOCOL_HOLOTARGETBONUS_AIM;
var config int iTARGET_PROTOCOL_HOLOTARGETBONUS_AIM_CV;
var config int iTARGET_PROTOCOL_HOLOTARGETBONUS_AIM_MG;
var config int iTARGET_PROTOCOL_HOLOTARGETBONUS_AIM_BM;

var config bool bTARGET_PROTOCOL_HOLOTARGET_APPLIES_TOSHOT;
var config bool bTARGET_PROTOCOL_HOLOTARGET_APPLIES_TOCRIT;

var config bool bEnableLogging;

var int HitMod;

//add modifiers to shot types for other units
function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local XComGameStateHistory	History;
	local ShotModifierInfo		ModInfo;

	local XComGameState_Item	SourceWeapon;
	local X2WeaponTemplate		CurrentWeapon;

	//get the effect originator weapon
	History = `XCOMHISTORY;
	SourceWeapon = XComGameState_Item(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID));

	//set a default integer, fallback backup
	HitMod = 5;

	//Change Aim value bonus/debuff based on tier of gremlin
	if (SourceWeapon != none)
	{
		//log msg to confirm what weapon was
		`LOG("HoloTarget Source Weapon Was: " @SourceWeapon.GetMyTemplateName(),default.bEnableLogging,'WOTCGremlinTargetProtocol');

		CurrentWeapon = X2WeaponTemplate(SourceWeapon.GetMyTemplate());
		`LOG("HoloTarget Weapon Template Was: " @CurrentWeapon.CosmeticUnitTemplate,default.bEnableLogging,'WOTCGremlinTargetProtocol');

		//double check it was a gremlin
		if (CurrentWeapon.WeaponCat == 'gremlin' )
		{
			//Basic MK I Gremlin
			if ( CurrentWeapon.WeaponTech == 'conventional' )	
				{
					HitMod = default.iTARGET_PROTOCOL_HOLOTARGETBONUS_AIM_CV;	
					`LOG("HoloTarget Weapon Tech Was: " @CurrentWeapon.WeaponTech,default.bEnableLogging,'WOTCGremlinTargetProtocol');
					`LOG("HitMod set to: " @default.iTARGET_PROTOCOL_HOLOTARGETBONUS_AIM_CV,default.bEnableLogging,'WOTCGremlinTargetProtocol');
				}

			//Advanced MK II Gremlin
			else if ( CurrentWeapon.WeaponTech == 'magnetic' )		
				{ 
					HitMod = default.iTARGET_PROTOCOL_HOLOTARGETBONUS_AIM_MG;	
					`LOG("HoloTarget Weapon Tech Was: " @CurrentWeapon.WeaponTech,default.bEnableLogging,'WOTCGremlinTargetProtocol');
					`LOG("HitMod set to: " @default.iTARGET_PROTOCOL_HOLOTARGETBONUS_AIM_MG,default.bEnableLogging,'WOTCGremlinTargetProtocol');
				}

			//Improved MK III Gremlin
			else if ( CurrentWeapon.WeaponTech == 'beam' )
				{ 
					HitMod = default.iTARGET_PROTOCOL_HOLOTARGETBONUS_AIM_BM;
					`LOG("HoloTarget Weapon Tech Was: " @CurrentWeapon.WeaponTech,default.bEnableLogging,'WOTCGremlinTargetProtocol');
					`LOG("HitMod set to: " @default.iTARGET_PROTOCOL_HOLOTARGETBONUS_AIM_BM,default.bEnableLogging,'WOTCGremlinTargetProtocol');
				}

			//UNCLEAR TIER ~ Default aim
			else 
				{ 
					HitMod = default.iTARGET_PROTOCOL_HOLOTARGETBONUS_AIM; 
					`LOG("HoloTarget Weapon Tech Was: " @CurrentWeapon.WeaponTech,default.bEnableLogging,'WOTCGremlinTargetProtocol');
					`LOG("HitMod set to: " @default.iTARGET_PROTOCOL_HOLOTARGETBONUS_AIM,default.bEnableLogging,'WOTCGremlinTargetProtocol');
				}
		}
	}

	if (default.bTARGET_PROTOCOL_HOLOTARGET_APPLIES_TOSHOT)
	{
		// add to shot chance
		ModInfo.ModType = eHit_Success;
		ModInfo.Reason = FriendlyName;
		ModInfo.Value = HitMod;
		ShotModifiers.AddItem(ModInfo);
	}

	if (default.bTARGET_PROTOCOL_HOLOTARGET_APPLIES_TOCRIT)
	{
		// add to crit chance
		ModInfo.ModType = eHit_Crit;
		ModInfo.Reason = FriendlyName;
		ModInfo.Value = HitMod;
		ShotModifiers.AddItem(ModInfo);
	}
}

/*	VISUALIZATION NOW HANDLED BY PERK CONTENTS PACKAGE !!		MASSIVE PROPS TO MUSASHI AND MR.NICE FOR HELP IMPLEMENTING THIS
//add the holotarget visual effect , managed to make a whole new colour, yellow, for crits :)
simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
    local X2Action_PlayEffect		EffectAction;
 
    if (EffectApplyResult != 'AA_Success' || ActionMetadata.VisualizeActor == none)
        return;
  
    EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
 		EffectAction.AttachToUnit = true;
		EffectAction.AttachToSocketName = 'FX_Chest';
		EffectAction.EffectName = "FX_Holo_Targeting_Extra.P_Tracer_Beam_Target_Yellow";	//custom made yellow version
		//EffectAction.EffectName = "FX_Holo_Targeting.P_Tracer_Beam_Target";				//the default xcom blue
		//EffectAction.EffectName = "FX_Holo_Targeting.P_Tracer_Beam_Target_Red";			//the advents red version
		//EffectAction.EffectName = "FX_WP_Heavy_Plasma.P_Target_Screen_Holo";				//a weird green one I found
}

//remove the holotarget visual effect on expiry
simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
    local X2Action_PlayEffect		EffectAction;
 
    if (EffectApplyResult != 'AA_Success' || ActionMetadata.VisualizeActor == none)
        return;
 
    EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		EffectAction.AttachToUnit = true;
		EffectAction.EffectName = "HoloTarget_GTP"; // "FX_Holo_Targeting_Extra.P_Tracer_Beam_Target_Yellow";	//custom made yellow version
    EffectAction.bStopEffect = true;
}
*/

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);
}

//set default properties for this effect type
DefaultProperties
{
	EffectName = "HoloTarget_GTP";
	//VFXTemplateName = "HoloTarget";
	//VFXSocket = "FX_Chest";
	//PersistentPerkName = 'GremlinTargetProtocol';
	DuplicateResponse = eDupe_Refresh;
	bApplyOnHit = true;
	bApplyOnMiss = true;
}
