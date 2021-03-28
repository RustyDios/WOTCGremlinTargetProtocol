//---------------------------------------------------------------------------------------
//  FILE:   X2Ability_GremlinTargetProtocol.uc                                    
//           
//	Created by		RustyDios
//  Created			13/09/19	06:30
//	Last Updated	03/03/20	16:00
//
//	A version of Holotargetting given by gremlin, granted for free with Scanning Protocol
//
//---------------------------------------------------------------------------------------

class X2Ability_GremlinTargetProtocol extends X2Ability config (GTPConfig);

//grab variables from the config
var config int iTARGET_PROTOCOL_APCOST;
var config bool bTARGET_PROTOCOL_CONSUMEALL;
var config bool bTARGET_PROTOCOL_FREEREQUIRESPOINTS;

var config int iTARGET_PROTOCOL_CHARGES; 
var config int iTARGET_PROTOCOL_CHARGESCOST;

var config int iTARGET_PROTOCOL_COOLDOWN;

var config bool bTARGET_PROTOCOL_REQUIRESVIS;
var config bool bTARGET_PROTOCOL_SQUADSIGHT;

var config bool bTARGET_PROTOCOL_DAMAGESASCOMBATPROTOCOL;
var config bool bTARGET_PROTOCOL_DOESEXTRADAMAGEVSROBOTS;

var config bool bTARGET_PROTOCOL_EFFECT_ON_ROBOTS_ONLY;

var config bool bTARGET_PROTOCOL_OVERRIDES_COMBATPROTOCOL;
var config bool bTARGET_PROTOCOL_REQUIRES_COMBATPROTOCOL;

var config bool bTARGET_PROTOCOL_PREVENTSENEMYTELEPORT;

var config bool bTARGET_PROTOCOL_CONCEALMENTRULE;

var config int iTARGET_PROTOCOL_EFFECTLASTSTURNS; 

var config float fGREMLIN_ARRIVAL_TIMEOUT;
 
//add the abilities to the game
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Create_GTP_Passive());
	Templates.AddItem(Create_GTP());

	return Templates;
}

// copy of HoloTargeting Passive to control the Perk Content/ Visualization working correctly :) -- thanks to Musashi
//  This is a dummy effect so that the perk content package works correctly
// Note: the effect is set to not show any information
// Note: no visualization on purpose!
static function X2AbilityTemplate Create_GTP_Passive()
{
	local X2AbilityTemplate             Template;
	local X2Effect_Persistent           PersistentEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'GTP_Passive');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_adventmec_minigun";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bIsPassive = true;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	PersistentEffect = new class'X2Effect_Persistent';
	PersistentEffect.BuildPersistentEffect(1, true, true);
	PersistentEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, false,,Template.AbilitySourceName);
	Template.AddTargetEffect(PersistentEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	Template.bCrossClassEligible = true;

	return Template;
}

//create the ability, base is a clone of combat protocol, with added Holo target effects
static function X2AbilityTemplate Create_GTP()
{
	local X2AbilityTemplate					Template;

	local X2AbilityCost_ActionPoints		ActionPointCost;
	local X2AbilityCharges					Charges;
	local X2AbilityCost_Charges				ChargeCost;
	local X2AbilityCooldown					Cooldown;

	local X2Effect_ApplyWeaponDamage		RobotDamage;

	local X2Condition_UnitProperty			RobotProperty;
	local X2Condition_Visibility			VisCondition;

	local X2Condition_AbilityProperty		AbilityProperty;

	local X2Effect_HoloTarget_GTP			Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'GremlinTargetProtocol');

	//UI Visuals
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_adventmec_minigun";				//icon
	Template.AbilitySourceName = 'eAbilitySource_Perk';										//colour of icon
	Template.Hostility = eHostility_Offensive;												//enemy reactions to this ability
	Template.DisplayTargetHitChance = false;												//set as deadeye/never miss so no need to display hitchance
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideSpecificErrors;				//when  to show in hud? 
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_CORPORAL_PRIORITY;	//where to show on hud?
	Template.bDontDisplayInAbilitySummary = false;											//does it show in armoury scroll ? reverse logic.. nope
	Template.bDisplayInUITacticalText = true;												//does it have in strategy hud displaying desc if on a weapon/item?
	Template.bDisplayInUITooltip = true;													//does it have in tactical hud displaying lochelptext?

	//does it require combat protocol
	if (default.bTARGET_PROTOCOL_REQUIRES_COMBATPROTOCOL)
	{
		AbilityProperty = new class'X2Condition_AbilityProperty';
		AbilityProperty.OwnerHasSoldierAbilities.AddItem('CombatProtocol');
		Template.AbilityShooterConditions.AddItem(AbilityProperty);

		//if it does require and the soldier doesn't have CP, hide it
		Template.HideErrors.AddItem('AA_AbilityUnavailable');
		Template.HideErrors.AddItem('AA_UnknownError');

	}

	//does it override combat protocol or is it additional
	if (default.bTARGET_PROTOCOL_OVERRIDES_COMBATPROTOCOL)
	{
		Template.OverrideAbilities.AddItem('CombatProtocol');
	}

	//AP Cost .. default config :: 1action, turn ending, not free
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = default.iTARGET_PROTOCOL_APCOST;
	ActionPointCost.bConsumeAllPoints = default.bTARGET_PROTOCOL_CONSUMEALL;
	ActionPointCost.bFreeCost = default.bTARGET_PROTOCOL_FREEREQUIRESPOINTS;
	Template.AbilityCosts.AddItem(ActionPointCost);

	//Charges .. default config :: no
	if (default.iTARGET_PROTOCOL_CHARGES > 0)
	{
		Charges = new class 'X2AbilityCharges';
		Charges.InitialCharges = default.iTARGET_PROTOCOL_CHARGES;
		Template.AbilityCharges = Charges;

		ChargeCost = new class'X2AbilityCost_Charges';
		ChargeCost.NumCharges = default.iTARGET_PROTOCOL_CHARGESCOST;
		Template.AbilityCosts.AddItem(ChargeCost);
	}

	//Cooldown .. default config :: 3 turn cooldown
	if (default.iTARGET_PROTOCOL_COOLDOWN > 0)
	{
		Cooldown = new class'X2AbilityCooldown';
		Cooldown.iNumTurns = default.iTARGET_PROTOCOL_COOLDOWN;
		Template.AbilityCooldown = Cooldown;
	}

	//Ability to target - deadeye - always hits, single target only, triggered by player choice
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SingleTargetWithSelf;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	//visibility settings - who can I see to target
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitOnlyProperty);

	VisCondition = new class'X2Condition_Visibility';
	VisCondition.bRequireBasicVisibility = default.bTARGET_PROTOCOL_REQUIRESVIS;
	VisCondition.bRequireGameplayVisible = default.bTARGET_PROTOCOL_REQUIRESVIS;
	VisCondition.bActAsSquadsight = default.bTARGET_PROTOCOL_SQUADSIGHT;
	Template.AbilityTargetConditions.AddItem(VisCondition);
	
	Template.bLimitTargetIcons = true;

	//should it add the damage effects of combat protocol and double damage to robots
	if (default.bTARGET_PROTOCOL_DAMAGESASCOMBATPROTOCOL)
	{
		Template.AddTargetEffect(new class'X2Effect_ApplyWeaponDamage');
	}

	if (default.bTARGET_PROTOCOL_DOESEXTRADAMAGEVSROBOTS)
	{
		RobotDamage = new class'X2Effect_ApplyWeaponDamage';
		RobotDamage.bIgnoreBaseDamage = true;
		RobotDamage.DamageTag = 'CombatProtocol_Robotic';
			RobotProperty = new class'X2Condition_UnitProperty';
			RobotProperty.IncludeWeakAgainstTechLikeRobot = true;
			RobotProperty.ExcludeOrganic = true;
			RobotDamage.TargetConditions.AddItem(RobotProperty);
		Template.AddTargetEffect(RobotDamage);
	}

	//almost forgot to add the actual custom HoloTargeting effect, see below and if it should only work on robots
	//hack on the setdisplay message! as the ability is never miss, can use the miss string from the ability :)
	//otherwise GetMyHelpText() or LocLongDescription was also showing for the shot hud tooltip!
	Effect = new class'X2Effect_HoloTarget_GTP';
	Effect.TargetConditions.Length = 0;
	Effect.BuildPersistentEffect(default.iTARGET_PROTOCOL_EFFECTLASTSTURNS, false, false, false, eGameRule_PlayerTurnBegin);
	Effect.bRemoveWhenTargetDies = true;
	Effect.bUseSourcePlayerState = true;
	Effect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, Template.LocMissMessage, Template.IconImage,true,,Template.AbilitySourceName);

		if (default.bTARGET_PROTOCOL_EFFECT_ON_ROBOTS_ONLY)
		{
			RobotProperty = new class'X2Condition_UnitProperty';
			RobotProperty.ExcludeOrganic = true;
			RobotProperty.IncludeWeakAgainstTechLikeRobot = true;
			Effect.TargetConditions.AddItem(RobotProperty);
		}

	Template.AddTargetEffect(Effect);

	//can the target teleport/split away after, so f-u codick
	Template.bPreventsTargetTeleport = default.bTARGET_PROTOCOL_PREVENTSENEMYTELEPORT;

	//should it break concealment
	if (default.bTARGET_PROTOCOL_CONCEALMENTRULE)
	{
		Template.ConcealmentRule = eConceal_AlwaysEvenWithObjective;
	}

	//VISUALIZATIONS AS IF IT WAS AID MIXED WITH COMBAT WITH SOUNDS OF SCANNING AND HOLOTARGET EFFECT.. USES PERK CONTENT PACKAGE
	Template.bStationaryWeapon = true;
	Template.DefaultSourceItemSlot = eInvSlot_SecondaryWeapon;

	Template.BuildNewGameStateFn = AttachGremlinToTarget_BuildGameState_GTP; 
	Template.BuildVisualizationFn = GremlinSingleTarget_BuildVisualization_GTP;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.ActivationSpeech = 'ScanningProtocol';		//soldier voice lines to try
	Template.bShowActivation = true;					//true to show the flyover pop-ups					
	Template.bSkipPerkActivationActions = false;		//false here lets the effects from perk package actually play

	Template.CustomSelfFireAnim = 'NO_DefenseProtocol';	//  .. NO_CombatProtocol .. NO_RevivalProtocol
	Template.CinescriptCameraType = "Specialist_CombatProtocol";

	//denote it as a holotarget style effect !
	//thanks to Musashi this little hack lets the HT duration effect play and expire correctly :)
	Template.AdditionalAbilities.AddItem('GTP_Passive');
	Template.AssociatedPassives.AddItem('GTP_Passive'); //Template.AssociatedPassives.AddItem('HoloTargeting');

	//ability extra stuffs
	Template.PostActivationEvents.AddItem('ItemRecalled'); //recall the GREMLIN after it's done its thing

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = 0;	//DONT ATTRACT THE LOST :) ... class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;
}

//****************************************************************************************
//	VISUALIZATION STUFFS
//****************************************************************************************

//build visualization	- code copy from X2Ability_SpecialistAbilitySet	- slight adjustments to remove threat assessment/aid protocol checks as they are not needed
static function XComGameState AttachGremlinToTarget_BuildGameState_GTP( XComGameStateContext Context )
{
	local XComGameStateContext_Ability		AbilityContext;
	local XComGameState						NewGameState;
	local XComGameState_Item				GremlinItemState;
	local XComGameState_Unit				GremlinUnitState, TargetUnitState;
	local TTile								TargetTile;

	AbilityContext = XComGameStateContext_Ability(Context);
	NewGameState = TypicalAbility_BuildGameState(Context);

	TargetUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (TargetUnitState == none)
	{
		TargetUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', AbilityContext.InputContext.PrimaryTarget.ObjectID));
	}
	GremlinItemState = XComGameState_Item(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
	if (GremlinItemState == none)
	{
		GremlinItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', AbilityContext.InputContext.ItemObject.ObjectID));
	}
	GremlinUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(GremlinItemState.CosmeticUnitRef.ObjectID));
	if (GremlinUnitState == none)
	{
		GremlinUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', GremlinItemState.CosmeticUnitRef.ObjectID));
	}

	`assert(TargetUnitState != none);
	`assert(GremlinItemState != none); 
	`assert(GremlinUnitState != none);

	GremlinItemState.AttachedUnitRef = TargetUnitState.GetReference();

	//Handle height offset for tall units
	TargetTile = TargetUnitState.GetDesiredTileForAttachedCosmeticUnit();

	GremlinUnitState.SetVisibilityLocation(TargetTile);

	return NewGameState;
}

//build single target ability	- code copy from X2Ability_SpecialistAbilitySet	- slight adjustments to remove threat assessment/aid protocol checks as they are not needed
static simulated function GremlinSingleTarget_BuildVisualization_GTP(XComGameState VisualizeGameState)
{
	local XComGameStateHistory			History;
	local XComGameStateContext_Ability  Context;

	local X2AbilityTemplate             AbilityTemplate;
	local X2AbilityTag					AbilityTag;

	local StateObjectReference          InteractingUnitRef;
	local XComGameState_Item			GremlinItem;
	local XComGameState_Unit			TargetUnitState, AttachedUnitState, GremlinUnitState;	//ActivatingUnitState;
	local Actor							TargetVisualizer;

	local array<PathPoint>				Path;
	local PathingInputData              PathData;
	local PathingResultData				ResultData;
	local TTile                         StartTile, TargetTile;

	local VisualizationActionMetadata   ActionMetadata, EmptyTrack;
	local X2VisualizerInterface			TargetVisualizerInterface;

	local X2Action_WaitForAbilityEffect DelayAction;
	local X2Action_AbilityPerkStart		PerkStartAction;
	local X2Action_CameraLookAt			CameraAction, TargetCameraAction;

	local X2Action_PlaySoundAndFlyOver 	SoundAndFlyOver;
	local X2Action_PlayAnimation		PlayAnimation;

	local string FlyOverText,			FlyOverIcon;
	local int EffectIndex;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);

	TargetUnitState = XComGameState_Unit( VisualizeGameState.GetGameStateForObjectID( Context.InputContext.PrimaryTarget.ObjectID ) );

	GremlinItem = XComGameState_Item( History.GetGameStateForObjectID( Context.InputContext.ItemObject.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1 ) );
	GremlinUnitState = XComGameState_Unit( History.GetGameStateForObjectID( GremlinItem.CosmeticUnitRef.ObjectID ) );
	AttachedUnitState = XComGameState_Unit( History.GetGameStateForObjectID( GremlinItem.AttachedUnitRef.ObjectID ) );
	//ActivatingUnitState = XComGameState_Unit( History.GetGameStateForObjectID( Context.InputContext.SourceObject.ObjectID) );

	if( GremlinUnitState == none )
	{
		`RedScreen("Attempting GremlinSingleTarget_BuildVisualization with a GremlinUnitState of none");
		return;
	}

	//****************************************************************************************
	//Configure the visualization track for the shooter
	//****************************************************************************************

	InteractingUnitRef = Context.InputContext.SourceObject;
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID( InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1 );
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID( InteractingUnitRef.ObjectID );
	ActionMetadata.VisualizeActor = History.GetVisualizer( InteractingUnitRef.ObjectID );

	CameraAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	CameraAction.LookAtActor = ActionMetadata.VisualizeActor;
	CameraAction.BlockUntilActorOnScreen = true;

	class'X2Action_IntrusionProtocolSoldier'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);

	if (AbilityTemplate.ActivationSpeech != '')
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", AbilityTemplate.ActivationSpeech, eColor_Good);
	}

	// make sure he waits for the gremlin to come back, so that the cinescript camera doesn't pop until then
	X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded)).SetCustomTimeOutSeconds(30);

	//****************************************************************************************
	//Configure the visualization track for the gremlin
	//****************************************************************************************

	InteractingUnitRef = GremlinUnitState.GetReference( );

	ActionMetadata = EmptyTrack;
	History.GetCurrentAndPreviousGameStatesForObjectID(GremlinUnitState.ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, , VisualizeGameState.HistoryIndex);
	ActionMetadata.VisualizeActor = GremlinUnitState.GetVisualizer();
	TargetVisualizer = History.GetVisualizer(Context.InputContext.PrimaryTarget.ObjectID);

	class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);

	if (AttachedUnitState.TileLocation != TargetUnitState.TileLocation)
	{
		// Given the target location, we want to generate the movement data.  

		//Handle tall units.
		TargetTile = TargetUnitState.GetDesiredTileForAttachedCosmeticUnit();
		StartTile = AttachedUnitState.GetDesiredTileForAttachedCosmeticUnit();

		class'X2PathSolver'.static.BuildPath(GremlinUnitState, StartTile, TargetTile, PathData.MovementTiles);
		class'X2PathSolver'.static.GetPathPointsFromPath( GremlinUnitState, PathData.MovementTiles, Path );
		class'XComPath'.static.PerformStringPulling(XGUnitNativeBase(ActionMetadata.VisualizeActor), Path);

		PathData.MovingUnitRef = GremlinUnitState.GetReference();
		PathData.MovementData = Path;
		Context.InputContext.MovementPaths.AddItem(PathData);

		class'X2TacticalVisibilityHelpers'.static.FillPathTileData(PathData.MovingUnitRef.ObjectID,	PathData.MovementTiles,	ResultData.PathTileData);
		Context.ResultContext.PathResults.AddItem(ResultData);

		class'X2VisualizerHelpers'.static.ParsePath( Context, ActionMetadata);

		if( TargetVisualizer != none )
		{
			TargetCameraAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
			TargetCameraAction.LookAtActor = TargetVisualizer;
			TargetCameraAction.BlockUntilActorOnScreen = true;
			TargetCameraAction.LookAtDuration = 10.0f;		// longer than we need - camera will be removed by tag below
			TargetCameraAction.CameraTag = 'TargetFocusCamera';
			TargetCameraAction.bRemoveTaggedCamera = false;
		}
	}

	PerkStartAction = X2Action_AbilityPerkStart(class'X2Action_AbilityPerkStart'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	PerkStartAction.NotifyTargetTracks = true;

	PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree( ActionMetadata, Context ));
	if( AbilityTemplate.CustomSelfFireAnim != '' )
	{
		//PlayAnimation.Params.AnimName = AbilityTemplate.CustomFireAnim;
		PlayAnimation.Params.AnimName = AbilityTemplate.CustomSelfFireAnim;
	}
	else
	{
		PlayAnimation.Params.AnimName = 'NO_CombatProtocol';
	}

	class'X2Action_AbilityPerkEnd'.static.AddToVisualizationTree( ActionMetadata, Context );

	//****************************************************************************************
	//Configure the visualization track for the target == Marked Visual handled by effect ==
	//****************************************************************************************

	InteractingUnitRef = Context.InputContext.PrimaryTarget;
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = TargetVisualizer;

	DelayAction = X2Action_WaitForAbilityEffect( class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree( ActionMetadata, Context ) );
	DelayAction.ChangeTimeoutLength( default.fGREMLIN_ARRIVAL_TIMEOUT );       //  give the gremlin plenty of time to show up in seconds
	
	for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
	{
		AbilityTemplate.AbilityTargetEffects[ EffectIndex ].AddX2ActionsForVisualization( VisualizeGameState, ActionMetadata, Context.FindTargetEffectApplyResult( AbilityTemplate.AbilityTargetEffects[ EffectIndex ] ) );
		//add effect x2action here? .. nope custom perk content
	}
					
	if (AbilityTemplate.bShowActivation)
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
			FlyOverText = AbilityTemplate.LocFlyOverText;
			FlyOverIcon = AbilityTemplate.IconImage;

		AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
		AbilityTag.ParseObj = History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID);
		FlyOverText = `XEXPAND.ExpandString(FlyOverText);
		AbilityTag.ParseObj = none;

		SoundAndFlyOver.SetSoundAndFlyOverParameters(none, FlyOverText, '', eColor_Good, FlyOverIcon, 1.5f, true);
	}

	TargetVisualizerInterface = X2VisualizerInterface(ActionMetadata.VisualizeActor);
	if (TargetVisualizerInterface != none)
	{
		//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
		TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, ActionMetadata);
	}

	if( TargetCameraAction != none )
	{
		TargetCameraAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		TargetCameraAction.CameraTag = 'TargetFocusCamera';
		TargetCameraAction.bRemoveTaggedCamera = true;
	}
}

//****************************************************************************************
