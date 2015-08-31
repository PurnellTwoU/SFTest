/**
 * Unit tests for the AddAssetController class:
 * 
 * Assertions as follows:
 *
 * Constructor
 * - The new instance has a Case instance with the same ID as the one used
 *   to construct the ApexPages.StandardController we are using.
 * - The Case instance variable has all of the necessary data available.
 *
 * CanAddAsset
 * - The getCanAddAsset returns false if the Case is a Drop case, true otherwise.
 *
 * SetAssets
 * - The assetList member variable is populated with a list of asset classifications.
 * - Services with Available_on_provisioning_case__c == false are excluded.
 *
 * GetAssets
 * - The wrapperList member variable is populated with a list of AssetWrapper 
 *   instances
 * - A AssetWrapper exists for every item in the assetList member.
 * - Each AssetWrapper contains a list of SelectOption with one entry for 
 *   each newline-delimited value from the Asset_Classification__c.Specification_Picklist_Values__c
 *   field.
 * - Each SelectOption has its specification picklist value as both its VAlue and Label.
 * - Each AssetWrapper contains correct values for the corresponding asset classification's 
 *   Name, Id, and Field_Set__c variables.
 * - After calling getAssets() the getAsstSize() function returns the 
 *   size of the getAssets() output.
 *
 * AddAssets
 * - A new Asset_Case__c exists for each selected Asset_Classification__c
 * - The chosen Profile__c, Role__c, and Date__c values are properly inserted.
 * - Unparsable dates and bad Id values cause the controller to display an 
 *   error message and set the error flag to true.
 * - The correct RecordType is assigned based on the Asset_Classification__c fieldSet variable.
 * - All other fields on the inserted record have the proper values.
 *
 *
 * Back
 * - The returned PageReference points to the UserAccountCase page.
 * - The returned PageReference has an Id parameter with the ID of the Case.
 * - The returned PageReference has getRedirect()==true.
 * 
 */
@isTest
private class AddAssetControllerTest 
{

	public static final String PARAM_PREFIX     = 'main:theForm:infoPanel:repeat:[i]:';
	
	// The controller we are testing pulls its inputs from the 
	// ApexPages.currentPage().getParameters() map. 
	//
	// We use these parameter names as keys in the aforementioned
	// map when passing inputs to our controller. 
	// 
	// Before using any of these values, use String.replace()
	// to replace '[i]' with an actual number.
	//
	// For example, to get the key name for the Role ID for the
	// third Service (index = 2), use the following value:
	// 
	// PARAM_ASSET_ID.replace('[i]','2');
	// 
	//	
	public static final String PARAM_ASSET_SELECTED = PARAM_PREFIX+'asset';
	public static final String PARAM_SPECIFICATION  = PARAM_PREFIX+'aspec';
	public static final String PARAM_ASSET_ID       = PARAM_PREFIX+'aid';
	public static final String PARAM_DATE           = PARAM_PREFIX+'adate';
	public static final String PARAM_FIELDSET       = PARAM_PREFIX+'afieldset';
	public static final String PARAM_NOTES          = PARAM_PREFIX+'anotes';
	
		
	// Variable Name Shorthand:
	//
	// ac     => "Asset Classification"
	//
	// Gen    => With a "Generic ... " Field_Set__c value, such as "Generic Asset"
	//           or "Generic Asset with Specifications"
	// Oth    => With an "other" Field_Set__c value, generated randomly. 
	//
	// Spec   => The Asset_Classification__c.Specification_Picklist_Values__c field is used.
	// NoSpec => The Asset_Classification__c.Specification_Picklist_Values__c field is not used. 
	//
	// Av => Available (Available_on_provisioning_case__c==true)
	// Un => Unavailable (Available_on_provisioning_case__c==false)
	//
	
	// Data Layout (per setup()):
	//
	// - 1 Account
	//
	// - 1 Contact
	//
	// - 1 Case
	//
	// - 4 unavailable Asset Classifications, for each combination
	//   of Gen/Oth and Spec/NoSpec.
	//
	// - 4 available Asset Classifications, for each combination
	//   of Gen/Oth and Spec/NoSpec.
	//
	// - Each Asset Classification with Specification Picklist Values 
	//   has three of them, with randomly generated string values.
	//
	
	public static Account theAccount = null;
	public static Contact theContact = null;
	public static Case    theCase    = null;
	
	// Available Asset classifications
	public static Map<Id,Asset_Classification__c>   acAllAv   = null;	
	public static Asset_Classification__c           acGenSpecAv        = null;	 		
	public static Asset_Classification__c           acGenNoSpecAv      = null;
	public static Asset_Classification__c           acOthSpecAv        = null;
	public static Asset_Classification__c           acOthNoSpecAv      = null;
	
	// Unavailable Services
	public static Map<Id,Asset_Classification__c>   acAllUn           = null;
	public static Asset_Classification__c           acGenSpecUn        = null;	 		
	public static Asset_Classification__c           acGenNoSpecUn      = null;
	public static Asset_Classification__c           acOthSpecUn        = null;
	public static Asset_Classification__c           acOthNoSpecUn      = null;
	
 	
	public static String rndStr()
	{
		return 'ASConTest'+Math.random();		
	}
	
	public static void setup()
	{
		theAccount = new Account(Name=rndStr());
	 	insert theAccount;
	 	
	 	theContact = new Contact(
	 		AccountId=theAccount.Id,
	 		LastName=rndStr());
	 	insert theContact;
	 	
	 	theCase = new Case(
		 		Type=rndStr(),
		 		prEmployee__c=theContact.Id
	 		);	 	
	 	insert theCase;
		
 		Asset_Classification__c acProto = new Asset_Classification__c();
 		acProto.Available_on_provisioning_case__c = true;
 		
 		// Available Asset classifications
		acGenSpecAv                                  = acProto.clone();
		acGenSpecAv.Name                             = rndStr();
		acGenSpecAv.Field_Set__c                     = NewHireUtil.ASSET_FIELD_SET_GENERIC_WITH_SPEC;
		acGenSpecAv.Specification_Picklist_Values__c = rndStr()+'\n'+rndStr()+'\n'+rndStr();		
			 		
		acGenNoSpecAv                                = acProto.clone();
		acGenNoSpecAv.Name                           = rndStr();
		acGenNoSpecAv.Field_Set__c                   = NewHireUtil.ASSET_FIELD_SET_GENERIC;		
		
		acOthSpecAv                                  = acProto.clone();
		acOthSpecAv.Name                             = rndStr();
		acOthSpecAv.Field_Set__c                     = rndStr();
		acOthSpecAv.Specification_Picklist_Values__c = rndStr()+'\n'+rndStr()+'\n'+rndStr();		
		
		acOthNoSpecAv                                = acProto.clone();
		acOthNoSpecAv.Name                           = rndStr();
		acOthNoSpecAv.Field_Set__c                   = rndStr();
				
		// Unavailable Asset Classifications
		acProto.Available_on_provisioning_case__c = false;
		
		acGenSpecUn                                  = acProto.clone();
		acGenSpecUn.Name                             = rndStr();
		acGenSpecUn.Field_Set__c                     = NewHireUtil.ASSET_FIELD_SET_GENERIC_WITH_SPEC;
		acGenSpecUn.Specification_Picklist_Values__c = rndStr()+'\n'+rndStr()+'\n'+rndStr();
		
		acGenNoSpecUn                                = acProto.clone();
		acGenNoSpecUn.Name                           = rndStr();
		acGenNoSpecUn.Field_Set__c                   = NewHireUtil.ASSET_FIELD_SET_GENERIC;
		
		acOthSpecUn                                  = acProto.clone();
		acOthSpecUn.Name                             = rndStr();
		acOthSpecUn.Field_Set__c                     = rndStr();
		acOthSpecUn.Specification_Picklist_Values__c = rndStr()+'\n'+rndStr()+'\n'+rndStr();
		
		acOthNoSpecUn                                = acProto.clone();
		acOthNoSpecUn.Name                           = rndStr();
 		acOthNoSpecUn.Field_Set__c                   = rndStr();
 			 	
	 	Asset_Classification__c[] assetClassifications = new sOBject[]
	 	{
	 		acGenSpecAv,
	 		acGenNoSpecAv,
	 		acOthSpecAv,
	 		acOthNoSpecAv,
	 		acGenSpecUn,
	 		acGenNoSpecUn,
	 		acOthSpecUn,
	 		acOthNoSpecUn	 			 		
	 	};
	 	insert assetClassifications;
	 	 	
	 	// Populate our convenience aggregations.
	 	//
	 	acAllAv = new Map<Id,Asset_Classification__c>
	 	{
	 		acGenSpecAv.Id   => acGenSpecAv,
	 		acGenNoSpecAv.Id => acGenNoSpecAv,
	 		acOthSpecAv.Id   => acOthSpecAv,
	 		acOthNoSpecAv.Id => acOthNoSpecAv
	 	};
	 	
	 	acAllUn = new Map<Id,Asset_Classification__c>
	 	{
	 		acGenSpecUn.Id   => acGenSpecUn,
	 		acGenNoSpecUn.Id => acGenNoSpecUn,
	 		acOthSpecUn.Id   => acOthSpecUn,
	 		acOthNoSpecUn.Id => acOthNoSpecUn
	 	};	 	
	 	
	 	// Set the current page
	 	Test.setCurrentPage(Page.AddAsset);
	}
		
	 /**
	 * Constructor
	 * - The new instance has a Case instance with the same ID as the one used
	 *   to construct the ApexPages.StandardController we are using.
	 * - The Case instance variable has all of the necessary data available.
	 */
	 @isTest
	 public static void testConstructor()
	 {
	 	// Set up our data.
	 	setup();
	 	
	 	// Run the constructor.
	 	AddAssetController controller = 
	 	new AddAssetController(new ApexPages.StandardController(theCase));
	 	
	 	// Test the output.
	 	
	 	Case outCase = controller.getCase();
	 	
	 	System.assert(null!=outCase, 
	 		'The controller returned a null Case after constructing the controller.');
	 	
	 	System.assertEquals(theCase.Id,outCase.Id, 
	 		'After constructing the controller, the controller\'s Case has the wrong ID.');
	 	
	 	System.assertEquals(theCase.Id,outCase.Id, 
	 		'The controller\'s Case has the wrong ID.');
	 	
	 	System.assertEquals(theCase.Type,outCase.Type, 
	 		'The controller\'s Case has the wrong Type.');
	 		
	 	System.assertEquals(theCase.prEmployee__c,outCase.prEmployee__c, 
	 		'The controller\'s Case has the wrong prEmployee__c.');
	 	
	 }
	 
	 /**
	 * CanAddAsset
	 * - The getCanAddAsset returns false if the Case is a Drop case, true otherwise.
	 */
	 @isTest
	 public static void testCanAddAsset()
	 {
	 	// Set up our data.	 	
	 	setup();
	 	
	 	Case nonDropCase = theCase;	 		
	 	
	 	// Add a drop case to our setup.
	 	Case dropCase = nonDropCase.clone();	 	
	 	dropCase.Type = NewHireUtil.CASE_TYPE_DROP;	 		 		 	
	 	insert dropCase;
		 	
	 	// Run the constructor on our non-drop Case.
	 	AddAssetController controller = 
	 	new AddAssetController(new ApexPages.StandardController(nonDropCase));
	 	
	 	// Assert correct output.
	 	System.assertEquals(true,controller.getCanAddAsset(),
	 	'The getCanAddAsset() method returned false, even though the Case is not a Drop Case.');
	 	
	 	// Run the constructor again on our drop Case.
	 	controller = new AddAssetController(
	 		new ApexPages.StandardController(dropCase));
	 	
	 	// Assert correct output.
	 	System.assertEquals(false,controller.getCanAddAsset(),
	 	'The getCanAddAsset() method returned false, even though the Case is a Drop Case.');
	 		
	 }
	 	 	 
	 /**
	 * SetAssets
	 * - The assetList member variable is populated with a list of asset classifications.
	 * - Services with Available_on_provisioning_case__c == false are excluded.
	 */
	 @isTest
	 public static void testSetAssets()
	 {	
	 	// Set up our data.		
		setup();
		
		// Set up the controller.
	 	AddAssetController controller = 
	 	new AddAssetController(new ApexPages.StandardController(theCase));
	 	
	 	// Run the method.
	 	controller.setAssets();
	 	
	 	// Test our output.
	 	List<Asset_Classification__c> output = controller.assetList;
	 		
	 	System.assert(null!=output,
	 	'The Asset_Classification__c list was null after calling setAssets()');
	 	 		 		 	
	 	// Check each Asset_Classification__c.
	 	//
	 	Set<Id> assetIds = new Set<Id>();
	 	for(Asset_Classification__c assetClass : output)
	 	{
	 		System.assert(null != assetClass.Id, 
	 			'Found a Asset_Classification__c with Id=null.');
	 		
	 		System.assert(!acAllUn.containsKey(assetClass.Id),
	 			'Found a Asset_Classification__c from a group of records that had '
	 			+'Available_on_provisioning_case__c=false upon setup.');
	 		
	 		System.assertEquals(acAllAv.get(assetClass.Id).Name,assetClass.Name,
	 			'Found an unexpected value for Asset_Classification__c.Name');
	 			
	 		System.assertEquals(acAllAv.get(assetClass.Id).Field_Set__c,assetClass.Field_Set__c,
	 			'Found an unexpected value for Asset_Classification__c.Field_Set__c');
	 		
	 		System.assertEquals(acAllAv.get(assetClass.Id).Available_on_provisioning_case__c,assetClass.Available_on_provisioning_case__c,
	 			'Found an unexpected value for Asset_Classification__c.Available_on_provisioning_case__c');
	 		
	 		System.assertEquals(acAllAv.get(assetClass.Id).Specification_Picklist_Values__c,assetClass.Specification_Picklist_Values__c,
	 			'Found an unexpected value for Asset_Classification__c.Specification_Picklist_Values__c');
	 	}
	 	
	 }
	 
	 /**
	 * GetAssets
	 * - The wrapperList member variable is populated with a list of AssetWrapper 
	 *   instances
	 * - A AssetWrapper exists for every item in the assetList member.
	 * - Each AssetWrapper contains a list of SelectOption with one entry for 
	 *   each newline-delimited value from the Asset_Classification__c.Specification_Picklist_Values__c
	 *   field.
	 * - Each SelectOption has its specification picklist value as both its VAlue and Label.
	 * - Each AssetWrapper contains correct values for the corresponding asset classification's 
	 *   Name, Id, and Field_Set__c variables.
	 * - After calling getAssets() the getAsstSize() function returns the 
	 *   size of the getAssets() output.
	 */
	 @isTest
	 public static void testGetAssets()
	 {
	 	// Set up our data.		
		setup();
		
		// Set up the controller.
	 	AddAssetController controller = 
	 	new AddAssetController(new ApexPages.StandardController(theCase));
	 	
	 	// setAssets() must be run before getAssets() will work. 
	 	// See testSetAssets for unit tests on this method's output
	 	controller.setAssets();
	 	
	 	List<AddAssetController.AssetWrapper> allWrappers = controller.getAssets();
	 		 	
	 	// For each Asset classification ...
	 	for(Asset_Classification__c assetClass : controller.assetList)
	 	{
	 		System.assert(null != assetClass.Id, 
	 			'Found a Asset_Classification__c with Id==null. See testSetAssets() test results to troubleshoot.');
	 		
	 		/// ... look for a wrapper.
	 		AddAssetController.AssetWrapper wrapper = null;
	 		for(AddAssetController.AssetWrapper checkWrapper : allWrappers)
	 		{
	 			System.assert(null != checkWrapper.assetId,
	 				'Found a AssetWrapper with a null assetId');
	 				
	 			if(checkWrapper.assetId == assetClass.Id)
	 			{
	 				wrapper = checkWrapper;
	 				break;
	 			}
	 		}
	 		
	 		System.assert(null != wrapper,
	 			'Found an available Asset_Classification__c for which there is no wrapper with a matching assetId.');

	 		System.assertEquals(assetClass.Name,wrapper.assetName,
	 			'Found an unexpected value for AssetWrapper.assetName.');
	 		
	 		System.assertEquals(assetClass.Field_Set__c, wrapper.fieldSet,
	 			'Found an unexpected value for AssetWrapper.fieldSet');
	 		
	 		if(assetClass.Specification_Picklist_Values__c != null && 
	 		   assetClass.Specification_Picklist_Values__c.trim() != '')
	 		{
	 		
		 		// For each specification value ...
		 		//		
		 		String[] specList = assetClass.Specification_Picklist_Values__c.split('\n');
		 		for(String spec : specList)
		 		{	
		 			System.assert(null != wrapper.asstSpecifications,
		 				'Found a AssetWrapper with a null asstSpecifications list.');
		 				
		 			SelectOption specOption = null;
		 			
		 			// ... look for a matching SelectOption.
		 			for(SelectOption option : wrapper.asstSpecifications)
		 			{
		 				System.assert(null != option.getValue(),
		 					'Found a SelectOption with a null value.');
		 				if(option.getValue()==spec)
		 				{
		 					specOption = option;
		 					break;	 					
		 				}
		 			}
		 				 			
		 			// ... and compare the specification to its matching option.
		 			System.assert(null != specOption,
		 				'Found a Asset_Classification__c.Specification_Picklist_Values__c value for which there is no SelectOption whose '
		 				+'value matches the picklist value ('+spec+')');
		 				 			
		 			System.assertEquals(spec,specOption.getLabel(),
		 				'Found unexpected value for the SelectOption.getLabel() corresponding to a Asset_Classification__c.Specification_Picklist_Values__c value.');
		 		}
		 		
		 		System.assertEquals(specList.size(),wrapper.asstSpecifications.size(),
		 			'Wrong number of role SelectOptions for this AssetWrapper.');
	 		}
		 	
		 	System.assertEquals(controller.assetList.size(),allWrappers.size(),
		 		'Wrong number of AssetWrappers, compared to this controller\'s assetList');
	 	}
	 	
	 }
	 
	 /**
	 * AddAssets
	 * - A new Asset_Case__c exists for each selected Asset_Classification__c
	 * - The chosen Profile__c, Role__c, and Date__c values are properly inserted.
	 * - Unparsable dates and bad Id values cause the controller to display an 
 	 *   error message and set the error flag to true.
	 * - Unsavable input causes an exception and prevents DB changes from being made.
	 * - The correct RecordType is assigned based on the Asset_Classification__c fieldSet variable.
	 * - All other fields on the inserted record have the proper values.
	 */
	 @isTest
	 public static void testAddAssets()
	 {
	 	
	 	// Set up our data.		
		setup();
		
		// Set up the controller.
	 	AddAssetController controller = 
	 	new AddAssetController(new ApexPages.StandardController(theCase));
	 	
	 	// Setup our choices.
	 	controller.setAssets();
	 	controller.getAssets();
	 	
	 	// Prepare our input.
	 	Map<String,String> input = ApexPages.currentPage().getParameters();
	 		 	
	 	Date d1 = Date.today().addDays(24);
	 	String notes1 = rndStr();
	 	
	 	// First record selected, with user input	
	 	input.put(PARAM_ASSET_SELECTED .replace('[i]','0'),'on');
		input.put(PARAM_SPECIFICATION  .replace('[i]','0'),acGenSpecAv.Specification_Picklist_Values__c.split('\n')[1]);
		input.put(PARAM_ASSET_ID       .replace('[i]','0'),acGenSpecAv.Id);
		input.put(PARAM_DATE           .replace('[i]','0'),d1.month()+'/'+d1.day()+'/'+d1.year());
		input.put(PARAM_FIELDSET       .replace('[i]','0'),acGenSpecAv.Field_Set__c);
		input.put(PARAM_NOTES          .replace('[i]','0'),notes1);
		
		// Second record not selected	
	 	input.put(PARAM_ASSET_SELECTED .replace('[i]','1'),null);
		input.put(PARAM_SPECIFICATION  .replace('[i]','1'),null);
		input.put(PARAM_ASSET_ID       .replace('[i]','1'),acOthSpecAv.Id);
		input.put(PARAM_DATE           .replace('[i]','1'),d1.month()+'/'+d1.day()+'/'+d1.year());
		input.put(PARAM_FIELDSET       .replace('[i]','1'),acOthSpecAv.Field_Set__c);
		input.put(PARAM_NOTES          .replace('[i]','1'),notes1);		
						
		Date d2 = Date.today().addDays(15);
	 	String notes2 = rndStr();
	 	
		// Third record selected, with user input	
	 	input.put(PARAM_ASSET_SELECTED .replace('[i]','2'),'on');
		input.put(PARAM_SPECIFICATION  .replace('[i]','2'),null);
		input.put(PARAM_ASSET_ID       .replace('[i]','2'),acGenNoSpecAv.Id);
		input.put(PARAM_DATE           .replace('[i]','2'),d2.month()+'/'+d2.day()+'/'+d2.year());
		input.put(PARAM_FIELDSET       .replace('[i]','2'),acGenNoSpecAv.Field_Set__c);
		input.put(PARAM_NOTES          .replace('[i]','2'),notes2);
		
		// Fourth record not selected	
	 	input.put(PARAM_ASSET_SELECTED .replace('[i]','3'),null);
		input.put(PARAM_SPECIFICATION  .replace('[i]','3'),null);
		input.put(PARAM_ASSET_ID       .replace('[i]','3'),acOthNoSpecAv.Id);
		input.put(PARAM_DATE           .replace('[i]','3'),d2.month()+'/'+d2.day()+'/'+d2.year());
		input.put(PARAM_FIELDSET       .replace('[i]','3'),acOthNoSpecAv.Field_Set__c);
		input.put(PARAM_NOTES          .replace('[i]','3'),notes2);
		
				
		// Run the method we are testing.
		controller.addAssets();
		
		// Get results for the first option (selected).
		//
		
		Asset_Case__c[] acLst = [
			select
				Id,
				Employee__c,
				RecordTypeId,
				Asset_Classification__c,
				Case__c,
				Type__c,
				Status__c,
				Specifications__c,
				Notes__c,
				Date_Needed__c
			from Asset_Case__c			
			where Asset_Classification__c  = :acGenSpecAv.Id
			  and Case__c     = :theCase.Id
			  and Employee__c = :theCase.prEmployee__c
		];
		
		System.assert(acLst.size() > 0,
			'No Asset_Case__c was create for this Asset_Classification__c, Contact, and Case.');
			
		Asset_Case__c ac = acLst[0];
		
		System.assertEquals(NewHireUtil.ACASE_RTYPE_FOR_ACLASS_FIELDSET.get(acGenSpecAv.Field_Set__c),ac.RecordTypeId,
			'Wrong RecordTypeId on the new Asset_Case__c');
		
		System.assertEquals(acGenSpecAv.Specification_Picklist_Values__c.split('\n')[1], ac.Specifications__c, 
			'Wrong Specifications__c on the new Asset_Case__c');
			
		System.assertEquals(acGenSpecAv.Id, ac.Asset_Classification__c, 
			'Wrong Asset_Classification__c on the new Asset_Case__c');
		
		System.assertEquals(NewHireUtil.ASSET_CASE_STATUS_OPEN,ac.Status__c,
			'Wrong Status__c on the new Asset_Case__c');
		
		System.assertEquals(NewHireUtil.ASSET_CASE_TYPE_PROVISION,ac.Type__c,
			'Wrong Type__c on the new Asset_Case__c');
		
		System.assertEquals(notes1,ac.Notes__c,
			'Wrong Notes__c on the new Asset_Case__c');	
		
		System.assertEquals(d1,ac.Date_Needed__c,
			'Wrong Date_Needed__c on the new Asset_Case__c');
			
		
		// Get results for the second option (not selected).
		//
		
		acLst = [
			select Id
			from Asset_Case__c			
			where Asset_Classification__c  = :acOthSpecAv.Id
			  and Case__c     = :theCase.Id
			  and Employee__c = :theCase.prEmployee__c
		];
		
		System.assert(acLst.size() == 0,
			'A Asset_Case__c was created for a Asset_Classification__c that was not selected.');
			
		
		// Get results for the third option (selected).
		//
		
		acLst = [
			select
				Id,
				Employee__c,
				RecordTypeId,
				Asset_Classification__c,
				Case__c,
				Type__c,
				Status__c,
				Specifications__c,
				Notes__c,
				Date_Needed__c
			from Asset_Case__c			
			where Asset_Classification__c  = :acGenNoSpecAv.Id
			  and Case__c     = :theCase.Id
			  and Employee__c = :theCase.prEmployee__c
		];
		
		System.assert(acLst.size() > 0,
			'No Asset_Case__c was create for this Asset_Classification__c, Contact, and Case.');
			
		ac = acLst[0];
		
		System.assertEquals(NewHireUtil.ACASE_RTYPE_FOR_ACLASS_FIELDSET.get(acGenNoSpecAv.Field_Set__c),ac.RecordTypeId,
			'Wrong RecordTypeId on the new Asset_Case__c');
		
		System.assertEquals(null, ac.Specifications__c, 
			'Wrong Specifications__c on the new Asset_Case__c');
			
		System.assertEquals(acGenNoSpecAv.Id, ac.Asset_Classification__c, 
			'Wrong Asset_Classification__c on the new Asset_Case__c');
		
		System.assertEquals(NewHireUtil.ASSET_CASE_STATUS_OPEN,ac.Status__c,
			'Wrong Status__c on the new Asset_Case__c');
		
		System.assertEquals(NewHireUtil.ASSET_CASE_TYPE_PROVISION,ac.Type__c,
			'Wrong Type__c on the new Asset_Case__c');
		
		System.assertEquals(notes2,ac.Notes__c,
			'Wrong Notes__c on the new Asset_Case__c');	
		
		System.assertEquals(d2,ac.Date_Needed__c,
			'Wrong Date_Needed__c on the new Asset_Case__c');
			
		
		
		// Get results for the fourth option (not selected).
		//
		
		acLst = [
			select Id
			from Asset_Case__c			
			where Asset_Classification__c  = :acOthNoSpecAv.Id
			  and Case__c     = :theCase.Id
			  and Employee__c = :theCase.prEmployee__c
		];
		
		System.assert(acLst.size() == 0,
			'A Asset_Case__c was created for a Asset_Classification__c that was not selected.');
			
		
		// Try again with unparsable data in a selected option.
		//
		
		// Deselect the previous two selections.
		input.put(PARAM_ASSET_SELECTED .replace('[i]','0'),null);
		input.put(PARAM_ASSET_SELECTED .replace('[i]','2'),null);
		
		// Select the second asset classification.
		input.put(PARAM_ASSET_SELECTED .replace('[i]','1'),'on');
		
		// Enter an unparsable Date
		input.put(PARAM_DATE             .replace('[i]','1'),'XXXXXXXX');
		
		try
		{
			// Run the controller.
			controller.addAssets();
		} 
		catch(Exception e)
		{
			System.assert(false, 
				'When given an unparsable Date value, threw an uncaught '
				+'exception instead of reloading the page with an error message.');			
		}
		
		// Query results.
		acLst = [
			select Id
			from Asset_Case__c			
			where Asset_Classification__c  = :acOthSpecAv.Id
			  and Case__c     = :theCase.Id
			  and Employee__c = :theCase.prEmployee__c
		];
		
		System.assert(acLst.size()==0,
			'Created a Asset_Case__c record even though unparsable data was given.');
			
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
			'Given unparsable input, did not generate any messages with ApexPages.Severity.ERROR.');
		
		System.assertEquals(true,controller.error,
			'The error flag on the Controller was not set after unparsable data was given.');	 	
	 	
	 	// Try an error condition resulting in a DML exception	 	
	 	
	 	// Deselect the second asset classification
		input.put(PARAM_ASSET_SELECTED .replace('[i]','1'),null);
		
		// Select the last asset classification.
		input.put(PARAM_ASSET_SELECTED .replace('[i]','3'),'on');
		
		// Invalidate the Service ID by deleting the record.
		delete acOthNoSpecAv;
		
		try
		{
			// Run the controller.
			controller.addAssets();
			System.assert(false, 
				'When given an unsavable Asset_Classification__c ID, failed to throw an uncaught Exception.');	
		} 
		catch(Exception e)
		{
			System.assert(true);					
		}
		
		// Query results.
		acLst = [
			select Id
			from Asset_Case__c			
			where Asset_Classification__c  = :acOthNoSpecAv.Id
			  and Case__c     = :theCase.Id
			  and Employee__c = :theCase.prEmployee__c
		];
		
		System.assert(acLst.size()==0,
			'Created a Asset_Case__c record even though unsavable data was given.');
	 
	 	
	 }
	 
	 
	/**
	* Back
	* - The returned PageReference points to the UserAccountCase page.
	* - The returned PageReference has an Id parameter with the ID of the Case.
	* - The returned PageReference has getRedirect()==true.
	*/
	@isTest
	public static void testBack()
	{
		// Set up our data.		
		setup();
		
		// Set up the controller.
	 	AddAssetController controller = 
	 	new AddAssetController(new ApexPages.StandardController(theCase));
		
		PageReference nextPage = controller.back();
		
		String url = nextPage.getUrl();			
		System.assert(null != url, 'Next page URL is null.');
		
		// Normalize the URLs so we can compare them.
		String expectedUrl = Page.AssetCase.getUrl().replaceAll('\\\\','/').toLowercase();
		url = url.replaceall('\\\\','/').toLowercase().split('[?]')[0];
		
		System.assertEquals(expectedUrl,url,'Wrong URL for next page.');
		
		System.assert(nextPage.getParameters().containsKey('id'),
		'The next page URL does not include an ID parameter.');
		
		System.assertEquals(theCase.Id,nextPage.getParameters().get('id'),
		'The the ID parameter in the next page URL does not contain the current Case\'s ID.');
		
		System.assertEquals(true,nextPage.getRedirect(),'Wrong value for nextPage.getRedirect().');
	}
	 
}