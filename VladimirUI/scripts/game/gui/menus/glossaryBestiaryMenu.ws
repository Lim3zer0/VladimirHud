/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/

exec function bestiary()
{
	theGame.RequestMenu( 'GlossaryBestiaryMenu' );
}

class CR4GlossaryBestiaryMenu extends CR4ListBaseMenu
{	
	default DATA_BINDING_NAME 		= "glossary.bestiary.list";
	default DATA_BINDING_NAME_SUBLIST	= "glossary.bestiary.sublist.items";
	default DATA_BINDING_NAME_DESCRIPTION	= "glossary.bestiary.description";
	
	var allCreatures					: array<CJournalCreature>;
	
	// ---=== VladimirHUD ===--- Lim3zer0
	private var m_fxImageModule			: CScriptedFlashSprite;
	private var m_fxDescModule			: CScriptedFlashSprite;
	private var m_fxListModule			: CScriptedFlashSprite;
	
	private const var TITLE_FONT_SIZE	: int;
			  default TITLE_FONT_SIZE	= 21;
	
	private const var DESC_FONT_SIZE	: int;
			  default DESC_FONT_SIZE	= 19;
			  
	private const var LABEL_FONT_SIZE	: int;
			  default LABEL_FONT_SIZE	= 20;
			  
	private const var DESC_TEXT_LEADING	: int;
			  default DESC_TEXT_LEADING	= 10;
			  
	private const var TAB_FONT_SIZE		: int;
			  default TAB_FONT_SIZE		= 25;
	// ---=== VladimirHUD ===---

	private var m_fxHideContent	 		: CScriptedFlashFunction;	
	private var m_fxSetTitle			: CScriptedFlashFunction;
	private var m_fxSetText				: CScriptedFlashFunction;
	private var m_fxSetImage			: CScriptedFlashFunction;
	
	event  OnConfigUI()
	{	
		var i							: int;
		var tempCreatures				: array<CJournalBase>;
		var creatureTemp				: CJournalCreature;
		var status						: EJournalStatus;
		super.OnConfigUI();
		
		m_initialSelectionsToIgnore = 2;
		
		m_journalManager.GetActivatedOfType( 'CJournalCreature', tempCreatures );
		
		for( i = 0; i < tempCreatures.Size(); i += 1 )
		{
			status = m_journalManager.GetEntryStatus( tempCreatures[i] );
			if( status == JS_Active )
			{
				creatureTemp = (CJournalCreature)tempCreatures[i];
				if( creatureTemp )
				{
					allCreatures.PushBack(creatureTemp); 
				}
			}
		}
		
		m_fxHideContent = m_flashModule.GetMemberFlashFunction("hideContent");
		
		m_fxSetTitle = m_flashModule.GetMemberFlashFunction("setTitle");
		m_fxSetText = m_flashModule.GetMemberFlashFunction("setText");
		m_fxSetImage = m_flashModule.GetMemberFlashFunction("setImage");
		
		// ---=== VladimirHUD ===--- Lim3zer0
		m_fxImageModule	= m_flashModule.GetChildFlashSprite( "mcMonsterTexture" );
		m_fxDescModule = m_flashModule.GetChildFlashSprite( "mcTextAreaModule" );
		m_fxListModule = m_flashModule.GetChildFlashSprite( "mcMainListModule" );
		// ---=== VladimirHUD ===---
		
		ShowRenderToTexture("");
		m_flashValueStorage.SetFlashBool("journal.rewards.panel.visible",false);
		
		PopulateData();
		SelectCurrentModule();
		
		m_fxSetTooltipState.InvokeSelfTwoArgs( FlashArgBool( thePlayer.upscaledTooltipState ), FlashArgBool( true ) );
		
		UpdatePos();
	}
	
	private function UpdatePos()
	{
		m_flashModule.GetChildFlashSprite( "mcGlossarySubModule" ).SetX( 1297 );
		m_flashModule.GetChildFlashSprite( "mcGlossarySubModule" ).SetY( 249 );
		m_flashModule.GetChildFlashSprite( "mcGlossarySubModule" ).GetChildFlashSprite( "mcRewards" ).SetX( -574 );
		m_flashModule.GetChildFlashSprite( "mcGlossarySubModule" ).GetChildFlashSprite( "mcRewards" ).SetY( 441 );
		m_flashModule.GetChildFlashSprite( "mcGlossarySubModule" ).GetChildFlashSprite( "mcRewards" ).GetChildFlashSprite( "tfRewards" ).SetX( -168 );
		m_flashModule.GetChildFlashSprite( "mcGlossarySubModule" ).GetChildFlashSprite( "mcRewards" ).GetChildFlashSprite( "tfRewards" ).SetY( 98 );
	}
	
	// ---=== VladimirHUD ===--- Lim3zer0
	
	private function FormatDescription( l_creature : CJournalCreature ) : string
	{
		return "<textformat leading=\"" + DESC_TEXT_LEADING + "\"><font size='" + DESC_FONT_SIZE + "'>"
			 + GetDescription(l_creature)
			 + "</font></textformat>";
	}
	
	private function FormatTitle( l_creature : CJournalCreature ) : string
	{
		return "<font color ='#FFFFFF' size='" + TITLE_FONT_SIZE + "' face=\"$BoldFont\">"
			 + GetLocStringById( l_creature.GetNameStringId())
			 + "</font>";
	}
	
	private function FormatLabel( title : string ) : string
	{
		return "<font size='" + LABEL_FONT_SIZE + "'>" + StrUpper( title ) + "</font>";
	}
	
	private function FormatTab( tab : string ) : string
	{
		return "<font size='" + TAB_FONT_SIZE + "' face=\"$BoldFont\">" + StrUpper( tab ) + "</font>";
	}
	// ---=== VladimirHUD ===---
	
	event OnGuiSceneEntitySpawned(entity : CEntity)
	{
		UpdateSceneEntityFromCreatureDataComponent( entity );

		Event_OnGuiSceneEntitySpawned();
		
		//UpdateItemsFromEntity(entity);
	}
	
	event OnGuiSceneEntityDestroyed()
	{
		Event_OnGuiSceneEntityDestroyed();
	}
	
	event OnEntrySelected( tag : name ) 
	{
		if (tag != '')
		{
			m_fxHideContent.InvokeSelfOneArg(FlashArgBool(true));
			super.OnEntrySelected(tag);			
		}
		else
		{		
			lastSentTag = '';
			currentTag = '';
			m_fxHideContent.InvokeSelfOneArg(FlashArgBool(false));
		}
	}
	
	event OnCategoryOpened( categoryName : name, opened : bool )
	{
		var player : W3PlayerWitcher;

		player = GetWitcherPlayer();
		if ( !player )
		{
			return false;
		}
		if ( opened )
		{
			player.AddExpandedBestiaryCategory( categoryName );
		}
		else
		{
			player.RemoveExpandedBestiaryCategory( categoryName );
		}

		
		super.OnCategoryOpened( categoryName, opened );
	}
	
	function UpdateImage( entryName : name )
	{
		var creature : CJournalCreature;
		var templatepath : string;
		var template : CEntityTemplate;
		var environment : CEnvironmentDefinition;
		var sunRotation : EulerAngles;
		
		
		creature = (CJournalCreature)m_journalManager.GetEntryByTag( entryName );
		
		if(creature)
		{
			//templatepath = creature.GetEntityTemplateFilename();
				
			//template = ( CEntityTemplate )LoadResource( templatepath, true );
			//if ( template )
			//{
			//	theGame.GetGuiManager().SetSceneEntityTemplate( template, 'locomotion_idle' );
			//	m_fxSetImage.InvokeSelfOneArg(FlashArgString(""));				
			//}
			//else
			//{	
				ShowRenderToTexture("");
				templatepath = thePlayer.ProcessGlossaryImageOverride( creature.GetImage(), entryName );
				m_fxSetImage.InvokeSelfOneArg(FlashArgString(templatepath));
				theGame.GetGuiManager().RequestClearScene();
			//}
		}
		else
		{
			ShowRenderToTexture("");
			m_fxSetImage.InvokeSelfOneArg(FlashArgString(""));
			theGame.GetGuiManager().RequestClearScene();
		}
	}

	private function PopulateData()
	{
		var l_DataFlashArray		: CScriptedFlashArray;
		var l_DataFlashObject 		: CScriptedFlashObject;
		
		var i, length				: int;
		var l_creature 				: CJournalCreature;
		var l_creatureGroup			: CJournalCreatureGroup;

		
		var l_Title					: string;
		var l_Tag					: name;
		var l_CategoryTag			: name;
		var l_IconPath				: string;
		var l_GroupTitle			: string;
		var l_IsNew					: bool;
		
		var expandedBestiaryCategories : array< name >;
		
		expandedBestiaryCategories = GetWitcherPlayer().GetExpandedBestiaryCategories();
		
		l_DataFlashArray = m_flashValueStorage.CreateTempFlashArray();
		length = allCreatures.Size();
		
		for( i = 0; i < length; i+= 1 )
		{	
			l_creature = allCreatures[i];
			
			l_creatureGroup = (CJournalCreatureGroup)m_journalManager.GetEntryByGuid( l_creature.GetLinkedParentGUID() );
			l_GroupTitle = GetLocStringById( l_creatureGroup.GetNameStringId() );	
			l_CategoryTag = l_creatureGroup.GetUniqueScriptTag();
			
			l_Title = GetLocStringById( l_creature.GetNameStringId() );
			l_Tag = l_creature.GetUniqueScriptTag();
			l_IconPath = thePlayer.ProcessGlossaryImageOverride( l_creature.GetImage(), l_Tag );
			l_IsNew	= m_journalManager.IsEntryUnread( l_creature );
			
			l_DataFlashObject = m_flashValueStorage.CreateTempFlashObject();
				
			l_DataFlashObject.SetMemberFlashUInt(  "tag", NameToFlashUInt(l_Tag) );
			// ---=== VladimirHUD ===--- Lim3zer0
			l_DataFlashObject.SetMemberFlashString(  "dropDownLabel", FormatTab( l_GroupTitle ));
			// ---=== VladimirHUD ===---
			l_DataFlashObject.SetMemberFlashUInt(  "dropDownTag",  NameToFlashUInt(l_CategoryTag) );
			l_DataFlashObject.SetMemberFlashBool(  "dropDownOpened", expandedBestiaryCategories.Contains( l_CategoryTag ) );
			l_DataFlashObject.SetMemberFlashString(  "dropDownIcon", "icons/monsters/ICO_MonsterDefault.png" );
			
			l_DataFlashObject.SetMemberFlashBool( "isNew", l_IsNew );
			l_DataFlashObject.SetMemberFlashBool( "selected", ( l_Tag == currentTag ) );	
			// ---=== VladimirHUD ===--- Lim3zer0
			l_DataFlashObject.SetMemberFlashString(  "label", FormatLabel( l_Title ) );
			// ---=== VladimirHUD ===---
			l_DataFlashObject.SetMemberFlashString(  "iconPath", "icons/monsters/"+l_IconPath );
			
			l_DataFlashArray.PushBackFlashObject(l_DataFlashObject);
		}
		
		if( l_DataFlashArray.GetLength() > 0 )
		{
			m_flashValueStorage.SetFlashArray( DATA_BINDING_NAME, l_DataFlashArray );
			m_fxShowSecondaryModulesSFF.InvokeSelfOneArg(FlashArgBool(true));
		}
		else
		{
			m_fxShowSecondaryModulesSFF.InvokeSelfOneArg(FlashArgBool(false));
		}
	}

    
	function GetDescription( currentCreature : CJournalCreature ) : string 
	{
		var i : int;
		var currentIndex:int;
		var str : string;
		var locStrId : int;
		var descriptionsGroup, tmpGroup : CJournalCreatureDescriptionGroup;
		var description : CJournalCreatureDescriptionEntry;
		
		var placedString : bool;
		var currentJournalDescriptionText : JournalDescriptionText;
		var journalDescriptionArray : array<JournalDescriptionText>;
		
		str = "";
		for( i = 0; i < currentCreature.GetNumChildren(); i += 1 )
		{
			tmpGroup = (CJournalCreatureDescriptionGroup)(currentCreature.GetChild(i));
			if( tmpGroup )
			{
				descriptionsGroup = tmpGroup;
				break;
			}
		}
		for ( i = 0; i < descriptionsGroup.GetNumChildren(); i += 1 )
		{
			description = (CJournalCreatureDescriptionEntry)descriptionsGroup.GetChild(i);
			if( m_journalManager.GetEntryStatus(description) == JS_Active )
			{
				
				currentJournalDescriptionText.stringKey = description.GetDescriptionStringId();
				currentJournalDescriptionText.order = description.GetOrder();
				currentJournalDescriptionText.groupOrder = descriptionsGroup.GetOrder();
				
				if (journalDescriptionArray.Size() == 0)
				{
					journalDescriptionArray.PushBack(currentJournalDescriptionText);
				}
				else
				{
					placedString = false;
					
					for (currentIndex = 0; currentIndex < journalDescriptionArray.Size(); currentIndex += 1)
					{
						if (journalDescriptionArray[currentIndex].groupOrder > currentJournalDescriptionText.groupOrder ||
							(journalDescriptionArray[currentIndex].groupOrder <= currentJournalDescriptionText.groupOrder && 
							 journalDescriptionArray[currentIndex].order > currentJournalDescriptionText.order))
						{
							journalDescriptionArray.Insert(Max(0, currentIndex), currentJournalDescriptionText);
							placedString = true;
							break;
						}
					}
					
					if (!placedString)
					{
						journalDescriptionArray.PushBack(currentJournalDescriptionText);
					}
				}
			}
		}
		
		for ( i = 0; i < journalDescriptionArray.Size(); i += 1 )
		{
			str += GetLocStringById(journalDescriptionArray[i].stringKey) + "<br>";
		}
		
		if( str == "" || str == "<br>" )
		{
			str = GetLocStringByKeyExt("panel_journal_quest_empty_description");
		}
		
		return str;
	}
	
	function UpdateDescription( entryName : name )
	{
		var l_creature : CJournalCreature;
		var description : string;
		var title : string;
		
		
		l_creature = (CJournalCreature)m_journalManager.GetEntryByTag( entryName );
		// ---=== VladimirHUD ===--- Lim3zer0
		description = FormatDescription( l_creature );
		title = FormatTitle( l_creature );
		// ---=== VladimirHUD ===---		
		
		m_fxSetTitle.InvokeSelfOneArg(FlashArgString(title));
		m_fxSetText.InvokeSelfOneArg(FlashArgString(description));
	}	

	function UpdateItems( tag : name )
	{
		var itemsFlashArray			: CScriptedFlashArray;
		var l_creature : CJournalCreature;
		var l_creatureParams : SJournalCreatureParams;
		var l_creatureEntityTemplateFilename : string;
		
		
		
		l_creature = (CJournalCreature)m_journalManager.GetEntryByTag( tag );
		
		itemsNames = l_creature.GetItemsUsedAgainstCreature();
		itemsFlashArray = CreateItems(itemsNames);
		
		if( itemsFlashArray && itemsFlashArray.GetLength() > 0 )
		{
			m_flashValueStorage.SetFlashBool("journal.rewards.panel.visible",true);
			m_flashValueStorage.SetFlashArray(DATA_BINDING_NAME_SUBLIST, itemsFlashArray );
		}
		else
		{
			m_flashValueStorage.SetFlashBool("journal.rewards.panel.visible", false);
		}
	}
	
	function UpdateItemsFromEntity( entity : CEntity ) : void
	{
		var l_creature 				: CJournalCreature;
		var creatureDataComponent	: CCreatureDataComponent;
		var itemsFlashArray			: CScriptedFlashArray;
		
		l_creature = (CJournalCreature)m_journalManager.GetEntryByTag( currentTag );
		
		if (l_creature && m_journalManager.GetEntryHasAdvancedInfo(l_creature))
		{
			creatureDataComponent = (CCreatureDataComponent)(entity.GetComponentByClassName('CCreatureDataComponent'));
			
			if (creatureDataComponent)
			{
				itemsFlashArray = CreateItems(creatureDataComponent.GetItemsUsedAgainstCreature());
			}
		}
		
		if( itemsFlashArray )
		{
			m_flashValueStorage.SetFlashBool("journal.rewards.panel.visible",true);
			m_flashValueStorage.SetFlashArray(DATA_BINDING_NAME_SUBLIST, itemsFlashArray );
		}
		else
		{
			m_flashValueStorage.SetFlashBool("journal.rewards.panel.visible",false);
		}
	}
	
	private function CreateItems( itemsNames : array< name > ) : CScriptedFlashArray
	{
		var l_flashArray				: CScriptedFlashArray;
		var l_flashObject				: CScriptedFlashObject;
		var i 							: int;
		var dm 							: CDefinitionsManagerAccessor = theGame.GetDefinitionsManager();
		var curName						: name;
		var curLocName					: string;
		var curIconPath					: string;
		
		if( itemsNames.Size() < 1 )
		{
			return NULL;
		}
		
		l_flashArray = m_flashValueStorage.CreateTempFlashArray();
		
		for( i = 0; i < itemsNames.Size(); i += 1 )
		{
			curName = itemsNames[i];
			
			TryGetSignData(curName, curLocName, curIconPath);
			if (curLocName == "")
			{
				curIconPath = dm.GetItemIconPath( curName );
			}
			l_flashObject = m_flashValueStorage.CreateTempFlashObject("red.game.witcher3.menus.common.ItemDataStub");
			l_flashObject.SetMemberFlashInt( "id", i + 1 ); 
			l_flashObject.SetMemberFlashInt( "quantity", 1 );
			l_flashObject.SetMemberFlashString( "iconPath",  curIconPath);
			l_flashObject.SetMemberFlashInt( "gridPosition", i );
			l_flashObject.SetMemberFlashInt( "gridSize", 1 );
			l_flashObject.SetMemberFlashInt( "slotType", 1 );	
			l_flashObject.SetMemberFlashBool( "isNew", false );
			l_flashObject.SetMemberFlashBool( "needRepair", false );
			l_flashObject.SetMemberFlashInt( "actionType", IAT_None );
			l_flashObject.SetMemberFlashInt( "price", 0 ); 		
			l_flashObject.SetMemberFlashString( "userData", "");
			l_flashObject.SetMemberFlashString( "category", "" );
			l_flashArray.PushBackFlashObject(l_flashObject);
		}
		
		return l_flashArray;
	}
	
	private function TryGetSignData(signName : name, out localizationKey : string, out iconPath : string):void
	{
		switch (signName)
		{
			case 'Yrden':
				localizationKey = "Yrden";
				iconPath = "hud/radialmenu/mcYrden.png";
				break;
			case 'Quen':
				localizationKey = "Quen";
				iconPath = "hud/radialmenu/mcQuen.png";
				break;
			case 'Igni':
				localizationKey = "Igni";
				iconPath = "hud/radialmenu/mcIgni.png";
				break;
			case 'Axii':
				localizationKey = "Axii";
				iconPath = "hud/radialmenu/mcAxii.png";
				break;
			case 'Aard':
				localizationKey = "Aard";
				iconPath = "hud/radialmenu/mcAard.png";
				break;
			default:
				localizationKey = "";
				iconPath = "";
		}
	}
	
	event OnGetItemData(item : int, compareItemType : int) 
	{
		
		
		var itemName 			: string;
		var category			: name;
		var typeStr				: string;
		var weight 				: float;
		var iconPath			: string;
		
		var resultData 			: CScriptedFlashObject;
		var statsList			: CScriptedFlashArray;		
		var dm 					: CDefinitionsManagerAccessor = theGame.GetDefinitionsManager();
		
		item = item - 1;
		itemName = itemsNames[item];
		resultData = m_flashValueStorage.CreateTempFlashObject();
		statsList = m_flashValueStorage.CreateTempFlashArray();
		
		TryGetSignData(itemsNames[item], itemName, iconPath);
		if (itemName == "")
		{
			iconPath = dm.GetItemIconPath( itemsNames[item] );
			itemName = dm.GetItemLocalisationKeyName( itemsNames[item] );
			category = dm.GetItemCategory(itemsNames[item]);
			typeStr = GetItemCategoryLocalisedString( category );
		}
		else
		{
			typeStr = GetLocStringByKeyExt( "panel_character_skill_signs" );
		}
		
		itemName = GetLocStringByKeyExt(itemName);
		resultData.SetMemberFlashString("ItemName", itemName);
		
		resultData.SetMemberFlashString("PriceValue", dm.GetItemPrice(itemsNames[item]));
		
		resultData.SetMemberFlashString("ItemRarity", "" );
		
		resultData.SetMemberFlashString("ItemType", typeStr );
		
		resultData.SetMemberFlashString("DurabilityValue", "");

		resultData.SetMemberFlashString("IconPath", iconPath );
		resultData.SetMemberFlashString("ItemCategory", category);
		m_flashValueStorage.SetFlashObject("context.tooltip.data", resultData);
	}
	
	function PlayOpenSoundEvent()
	{
		
		
	}
}

exec function testbes()
{
	var manager : CWitcherJournalManager;
	
	manager = theGame.GetJournalManager();
	
	activateJournalBestiaryEntryWithAlias("BestiaryArmoredArachas", manager);
}
