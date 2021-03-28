//---------------------------------------------------------------------------------------
//  FILE:   X2DownloadableContentInfo_WOTCGremlinTargetProtocol.uc                                    
//           
//	Created by	RustyDios
//  Created		13/09/19	06:30
//	Last Update	01/03/20	06:40
//
//	A version of Holotargetting given by gremlin, granted for free with Scanning Protocol
//
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_WOTCGremlinTargetProtocol extends X2DownloadableContentInfo config (GTPConfig);

//grab config variables
var config bool bADDGTPFROMABIL;	//true
var config name nGTPGRANTINGABIL;	//scanning protocol

/// Called on first time load game if not already installed	
static event OnLoadedSavedGame(){}								//empty_func
static event OnLoadedSavedGameToStrategy(){}					//empty_func

/// Called on new campaign while this DLC / Mod is installed
static event InstallNewCampaign(XComGameState StartState){}		//empty_func

//*******************************************************************************************
// ADD/CHANGES AFTER TEMPLATES LOAD ~ OPTC ~
//*******************************************************************************************

static event OnPostTemplatesCreated()
{
	local X2AbilityTemplateManager		AllAbilities;		//holder for all abilities
	local X2AbilityTemplate				CurrentAbility;		//current thing to focus on
	
	//Grab the distinct template managers(lists) to search through
	AllAbilities     = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	//`LOG("Gremlin Target Protocol OPTC RUN",,'WOTCGremlinTargetProtocol');

	//////////////////////////////////////////////////////////////////////////////////////////
	// ADD Gremlin Target Protocol Ability to the configged ability
	//////////////////////////////////////////////////////////////////////////////////////////

	if (default.bADDGTPFROMABIL)
	{

		CurrentAbility = AllAbilities.FindAbilityTemplate(default.nGTPGRANTINGABIL);
		if (CurrentAbility != none)
		{
			CurrentAbility.AdditionalAbilities.AddItem('GremlinTargetProtocol');
			//`LOG("Target Protocol was added with ability: " @default.nGTPGRANTINGABIL,,'WOTCGremlinTargetProtocol');
		}

	}

} //END static event OnPostTemplatesCreated()
