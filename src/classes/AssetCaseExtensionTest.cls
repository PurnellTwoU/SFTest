/**
* Unit tests for the AssetCaseExtension class.
*
* Assertions as follows:
*
* GetTheCase
* - The case from the Contructor is returned.
* - The Id, Due_Date__c, and prEmployee__c are populated.
* - An invalid Case causes the page to fail.
*
* GetCanRequestAsset
* - Returns false if Case.Type != NewHireUtil.CASE_TYPE_DROP
* - Returns true otherwise.
*
* Invalidate
* - New records are added to lists.
* - Deleted records are removed from lists.
* - Records with changed status are moved to the appropriate lists.
* - User inputs on Asset_Case__c request prototypes for Asset__c records do not change.
*
* GetRequestPrototype
* - A prototype is returned for every Asset__c
* - First call reflects the data in the Case.
* - Second call preserves Date_Needed__c and Notes__c from user and reflects changes to the Case and Asset__c.
*
* GetOpenAssetCaseCount
* - Output matches getOpenAssetCaseRows().size().
*
* GetOpenAssetCaseRows
* - Output matches queryAssetCaseRows(NewHireUtil.ASSET_CASE_STATUS_OPEN)
*
* GetCompleteAssetCaseCount
* - Output matches getCompleteAssetCaseRows().size()
*
* GetCompleteAssetCaseRows
* - Output matches queryAssetCaseRows(NewHireUtil.ASSET_CASE_STATUS_COMPLETE)
* 
* QueryAssetCaseRows
* - Each Complete Asset_Case__c record belonging to the Case has a row.
* - Complete Asset_Case__c records not belonging to the Case are excluded.
* - Non-Complete Asset_Case__c records belonging to the Case are excluded.
*
* GetAssetCount
* - Output matches getAssetRows().size()
*
* GetAssetRows
* - Output matches GetAssetRowMap.values()
*
* GetAssetRowMap
* - A row is returned for each Asset__c belonging to the Contact.
* - Asset__c records belonging to other Contacts are ignored.
* - Each row returns a Asset_Case__c prototype matching the output of getRequestPrototype(Asset__c).
* - The getCanReclaim(), and getHasPendingReclamation()
*   methods function properly on each row, ignoring records belonging to other Cases.
* - The method has queried all necessary data for the Asset__c record.
*
* RequestActivation
* - A Asset_Case__c record is created for the given Asset__c
* - All fields on the Asset_Case__c are properly populated.
* - Bad editid causes failure, with a Page Message.
* - If the Asset__c cannot be Activated (per AssetRow.getCanReactivate()), 
*   the operation fails with a page message.
*
* RequestReclamation
* - A Asset_Case__c record is created for the given Asset__c
* - All fields on the Asset_Case__c are properly populated.
* - Bad editid causes failure, with a Page Message.
* - If the Asset__c cannot be Reclaimed (per AssetRow.getCanReclaim()), 
*   the operation fails with a page message. 
*
* CancelRequest
* - If the Asset_Case__c cannot be Canceled (per AssetCaseRow.getCanCancel()),
*   the operation fails with a page message.
* - The Asset_Case__c record with the given ID has its status changed to 
*   NewHireUtil.ASSET_CASE_STATUS_CANCEL
* - All fields on the Asset_Case__c are properly populated.
*
* MakeActivationChangeRequest
* Method is covered extensively by RequestReclamation and RequestActivation
*
*/
@isTest
private class AssetCaseExtensionTest 
{
	
	public static String rndStr()
	{
		return 'ACExtTest'+Math.random(); 
	}
	
	/*
    * GetTheCase
	* - The case from the Contructor is returned.
	* - The Id, Due_Date__c, and prEmployee__c are populated.
	* - An invalid Case causes the page to fail.
	*/
	@isTest
	public static void testGetTheCase()
	{
		Account theAccount = new Account(Name=rndStr());
		insert theAccount;
		
		Contact theContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		insert theContact;
		
		Case theCase = new Case(
			prEmployee__c = theContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		insert theCase;

		// Set up the page and its controllers.
		Test.setCurrentPage(Page.AssetCase);
		AssetCaseExtension controller = 
			new AssetCaseExtension(
				new ApexPages.StandardController(theCase));
		
		// Run the test.
		Case output = controller.getTheCase();
		
		System.assert(null != output, 
			'Output Case was null.');
		System.assertEquals(theCase.Id,output.Id, 
			'Output Case has the wrong ID.');
		System.assertEquals(theCase.prEmployee__c,output.prEmployee__c, 
			'Output Case has the wrong prEmployee__c.');
		
		delete theCase;
		
		// Try again with the deleted Case
		controller = 
			new AssetCaseExtension(
				new ApexPages.StandardController(theCase));
				
		try
		{
			controller.getTheCase();
			System.assert(false, 'Did not fail when given a deleted Case.');										
		} 
		catch(Exception e)
		{
			System.assert(true);			
		}
		
		// Null Cases and Cases with null IDs are handled by the  
		// Salesforce framework when the StandardController is 
		// instantiated.
					
	}
	
	/**
	* GetCanRequestAsset
	* - Returns false if Case.Type == NewHireUtil.CASE_TYPE_DROP
	* - Returns true otherwise.
	*/
	@isTest
	public static void testGetCanRequestAsset()
	{
		Account theAccount = new Account(Name=rndStr());
		insert theAccount;
		
		Contact theContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		insert theContact;
		
		Case theCase = new Case(
			Type          = NewHireUtil.CASE_SUBJECT_DROP,
			prEmployee__c = theContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		insert theCase;

		// Set up the page and its controllers.
		Test.setCurrentPage(Page.AssetCase);
		AssetCaseExtension controller = 
			new AssetCaseExtension(
				new ApexPages.StandardController(theCase));
				
		System.assert(!controller.getCanRequestAsset(),'Returned true for a Drop Case.');
		
		// Try again with a different Type.
		//
		theCase.Type = rndStr();
		update theCase;
		
		controller = 
			new AssetCaseExtension(
				new ApexPages.StandardController(theCase));
		
		System.assert(controller.getCanRequestAsset(),'Returned false for a non Drop Case.');
		
	}
	
	/**
	* Invalidate
	* - New records are added to lists.
	* - Deleted records are removed from lists.
	* - Records with changed status are moved to the appropriate lists.
	* - User inputs on Asset_Case__c request prototypes for Asset__c records do not change.
	*/
	@isTest
	public static void testInvalidate()
	{
		Account theAccount = new Account(Name=rndStr());
		insert theAccount;
		
		Contact theContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		insert theContact;
		
		Case theCase = new Case(
			prEmployee__c = theContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		insert theCase;
		
		Asset_Classification__c theAssetClass = new Asset_Classification__c();
		insert theAssetClass;
		
		// Set up our Asset__c records.
		Asset__c aToKeep = new Asset__c(Contact__c=theContact.Id,Asset_Classification__c=theAssetClass.Id);		
		Asset__c aToDelete = new Asset__c(Contact__c=theContact.Id,Asset_Classification__c=theAssetClass.Id);
		Asset__c aToChange = new Asset__c(Contact__c=theContact.Id,Asset_Classification__c=theAssetClass.Id);
		Asset__c aToAdd = new Asset__c(Contact__c=theContact.Id,Asset_Classification__c=theAssetClass.Id);
		insert new sOBject[]{aToKeep,aToDelete,aToChange};
		
		// Set up our open Asset_Case__c records.
		Asset_Case__c acOpenToKeep   = 
			new Asset_Case__c(Status__c=NewHireUtil.ASSET_CASE_STATUS_OPEN, Case__c=theCase.Id,Asset__c=aToKeep.Id);
		Asset_Case__c acOpenToDelete = 
			new Asset_Case__c(Status__c=NewHireUtil.ASSET_CASE_STATUS_OPEN,Case__c=theCase.Id,Asset__c=aToKeep.Id);
		Asset_Case__c acOpenToChange = 
			new Asset_Case__c(Type__c=NewHireUtil.ASSET_CASE_TYPE_PROVISION, Status__c=NewHireUtil.ASSET_CASE_STATUS_OPEN,Case__c=theCase.Id,Asset__c=aToChange.Id);
		Asset_Case__c acOpenToMove = 
			new Asset_Case__c(Status__c=NewHireUtil.ASSET_CASE_STATUS_OPEN,Case__c=theCase.Id,Asset__c=aToKeep.Id);
		Asset_Case__c acOpenToAdd = 
			new Asset_Case__c(Status__c=NewHireUtil.ASSET_CASE_STATUS_OPEN,Case__c=theCase.Id,Asset__c=aToKeep.Id);
		
		// Set up our Closed Asset_Case__c records.
		Asset_Case__c acClosedToKeep   = 
			new Asset_Case__c(Status__c=NewHireUtil.ASSET_CASE_STATUS_COMPLETE, Case__c=theCase.Id,Asset__c=aToKeep.Id);
		Asset_Case__c acClosedToDelete = 
			new Asset_Case__c(Status__c=NewHireUtil.ASSET_CASE_STATUS_COMPLETE, Case__c=theCase.Id,Asset__c=aToKeep.Id);
		Asset_Case__c acClosedToMove = 
			new Asset_Case__c(Status__c=NewHireUtil.ASSET_CASE_STATUS_COMPLETE, Case__c=theCase.Id,Asset__c=aToKeep.Id);
		Asset_Case__c acClosedToAdd = 
			new Asset_Case__c(Status__c=NewHireUtil.ASSET_CASE_STATUS_COMPLETE, Case__c=theCase.Id,Asset__c=aToKeep.Id);
		
		insert new sObject[]{acOpenToKeep,acOpenToDelete,acOpenToChange,acOpenToMove,acClosedToKeep,acClosedToDelete,acClosedToMove};
		
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.AssetCase);
		AssetCaseExtension controller = 
			new AssetCaseExtension(
				new ApexPages.StandardController(theCase));
		
		// Comprehensive testing of these functions is done 
		// elsewhere, but we test them here as a sanity check.  
		
		// Pull a map of Asset__c records.
		Map<Id,AssetCaseExtension.AssetRow>  
			assets = controller.getAssetRowMap();
		
		// Pull a map of open Asset_Case__c records.			
		List<AssetCaseExtension.AssetCaseRow> 
			openAssetCasesList = controller.getOpenAssetCaseRows();
		Map<Id,AssetCaseExtension.AssetCaseRow> 
			openAssetCases = new  Map<Id,AssetCaseExtension.AssetCaseRow>();
		for(AssetCaseExtension.AssetCaseRow row : openAssetCasesList)
		{ openAssetCases.put(row.getObj().Id,row); }
		
		// Pull a map of closed Asset_Case__c records.						
		List<AssetCaseExtension.AssetCaseRow> 
			closedAssetCasesList = controller.getCompleteAssetCaseRows();
		Map<Id,AssetCaseExtension.AssetCaseRow> 
			closedAssetCases = new  Map<Id,AssetCaseExtension.AssetCaseRow>();
		for(AssetCaseExtension.AssetCaseRow row : closedAssetCasesList)
		{ closedAssetCases.put(row.getObj().Id,row); }
		
		// Place some user input into a row.
		AssetCaseExtension.AssetRow aRowToKeep = assets.get(aToKeep.Id);
		aRowToKeep.getRequestPrototype().Notes__c = 'This is a test (before).';
				
		System.assert(assets.containsKey(aToKeep.Id),
			'A row for one of the initial Asset__c records was missing on initialization.');
		System.assert(assets.containsKey(aToDelete.Id),
			'A row for one of the initial Asset__c records was missing on initialization.');
		System.assert(assets.containsKey(aToChange.Id),
			'A row for one of the initial Asset__c records was missing on initialization.');
			
		System.assert(openAssetCases.containsKey(acOpenToKeep.Id),
			'A row for one of the initial open Asset_Case__c records was missing on initialization.');
		System.assert(openAssetCases.containsKey(acOpenToDelete.Id),
			'A row for one of the initial open Asset_Case__c records was missing on initialization.');
		System.assert(openAssetCases.containsKey(acOpenToMove.Id),
			'A row for one of the initial open Asset_Case__c records was missing on initialization.');
		System.assert(openAssetCases.containsKey(acOpenToChange.Id),
			'A row for one of the initial open Asset_Case__c records was missing on initialization.');
		
		System.assert(closedAssetCases.containsKey(acClosedToKeep.Id),
			'A row for one of the initial closed Asset_Case__c records was missing on initialization.');
		System.assert(closedAssetCases.containsKey(acClosedToDelete.Id),
			'A row for one of the initial closed Asset_Case__c records was missing on initialization.');
		System.assert(closedAssetCases.containsKey(acClosedToMove.Id),
			'A row for one of the initial closed Asset_Case__c records was missing on initialization.');
		
		// Delete some records.
		delete new sObject[]{aToDelete,acOpenToDelete,acClosedToDelete};
		
		// Add some records.
		insert new sObject[]{aToAdd,acOpenToAdd,acClosedToAdd};
		
		// Move some records.
		acOpenToMove.Status__c   = NewHireUtil.ASSET_CASE_STATUS_COMPLETE;
		acClosedToMove.Status__c = NewHireUtil.ASSET_CASE_STATUS_OPEN;
		
		// Change some records.
		Asset_Case__c newUacOpenToChange = acOpenToChange.clone(true,true,true,true);
		newUacOpenToChange.Type__c = NewHireUtil.ASSET_CASE_TYPE_RECLAIM;
		
		update new sObject[]{acOpenToMove,acClosedToMove,newUacOpenToChange};
		
		// Save an instance of our changeable Asset_Row__c for comparison
		// after the change.
		AssetCaseExtension.AssetRow aRowToChange = assets.get(aToChange.Id);	
				
		// Do the invalidation.		
		controller.invalidate();
		
		// Pull a map of Asset__c records.
		assets = controller.getAssetRowMap();
		
		// Pull a map of open Asset_Case__c records.			
		openAssetCasesList = controller.getOpenAssetCaseRows();
		openAssetCases = new  Map<Id,AssetCaseExtension.AssetCaseRow>();
		for(AssetCaseExtension.AssetCaseRow row : openAssetCasesList)
		{ openAssetCases.put(row.getObj().Id,row); }
		
		// Pull a map of closed Asset_Case__c records.						
		closedAssetCasesList = controller.getCompleteAssetCaseRows();
		closedAssetCases = new  Map<Id,AssetCaseExtension.AssetCaseRow>();
		for(AssetCaseExtension.AssetCaseRow row : closedAssetCasesList)
		{ closedAssetCases.put(row.getObj().Id,row); }
		
		System.assert(assets.containsKey(aToKeep.Id),
			'A row for one of the initial Asset__c records went missing after invalidation.');
		System.assert(!assets.containsKey(aToDelete.Id),
			'A deleted Asset__c record still had a row after invalidation.');
		System.assert(assets.containsKey(aToChange.Id),
			'A row for one of the initial Asset__c records went missing after invalidation.');
		System.assert(assets.containsKey(aToAdd.Id),
			'A row for a newly added Asset__c record was missing after invalidation.');
			
		System.assert(openAssetCases.containsKey(acOpenToKeep.Id),
			'A row for one of the initial open Asset_Case__c records was missing after invalidation.');
		System.assert(!openAssetCases.containsKey(acOpenToDelete.Id),
			'A deleted open Asset__c record still had a row after invalidation.');
		System.assert(!openAssetCases.containsKey(acOpenToMove.Id),
			'An open open Asset_Case__c was still persent on the open list after it was changed to closed.');
		System.assert(closedAssetCases.containsKey(acOpenToMove.Id),
			'An open Asset_Case__c record did not appear on the closed list after its status was changed to closed.');
		System.assert(openAssetCases.containsKey(acOpenToChange.Id),
			'A row for one of the initial open Asset_Case__c records was missing after invalidation.');
		System.assert(openAssetCases.get(acOpenToChange.Id).getObj().Type__c != acOpenToChange.Type__c,
			'An open Asset_Case__c whose Type__c had changed did not show the new Type__c after invalidation.');
		System.assert(openAssetCases.containsKey(acOpenToAdd.Id),
			'A row for a newly added open Asset_Case__c record was missing after invalidation.');
			
		System.assert(closedAssetCases.containsKey(acClosedToKeep.Id),
			'A row for one of the initial closed Asset_Case__c records was missing after invalidation.');
		System.assert(!closedAssetCases.containsKey(acClosedToDelete.Id),
			'A deleted closed Asset_Case__c record still had a row after invalidation.');
		System.assert(!closedAssetCases.containsKey(acClosedToMove.Id),
			'A closed Asset_Case__c was still persent on the open list after it was changed to open.');
		System.assert(openAssetCases.containsKey(acClosedToMove.Id),
			'A closed Asset_Case__c record did not appear on the open list after its status was changed to open.');
		System.assert(closedAssetCases.containsKey(acClosedToAdd.Id),
			'A row for a newly added closed Asset_Case__c record was missing after invalidation.');
			
		System.assert(aRowToChange.getHasPendingReclamation()!=assets.get(aToChange.Id).getHasPendingReclamation(),
			'A Type change from Activate to Reactivate on a Asset_Case__c request did not show up on the corresponding Asset__c record\'s row'
		);
		
		System.assertEquals(aRowToKeep.getRequestPrototype().Notes__c,assets.get(aToKeep.Id).getRequestPrototype().Notes__c,
			'User input on a Asset__c row was not preserved after invalidation'
		);		
	}
	
	/**
	* GetRequestPrototype
	* - A prototype is returned for every Asset__c
	* - First call reflects the data in the Case.
	* - Second call preserves Date_Needed__c and Notes__c from user and reflects changes to the Asset__c.
	*/
	@isTest
	public static void testGetRequestPrototype()
	{
		Account theAccount = new Account(Name=rndStr());
		insert theAccount;
		
		Contact theContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		insert theContact;
		
		Case theCase = new Case(
			prEmployee__c = theContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		insert theCase;
		
		Asset_Classification__c theAssetClass1 = new Asset_Classification__c();
		Asset_Classification__c theAssetClass2 = new Asset_Classification__c();
		insert new sOBject[]{theAssetClass1,theAssetClass2};
		
		// Set up our Asset__c records.
		Asset__c aFirst = new Asset__c(Contact__c=theContact.Id,Asset_Classification__c=theAssetClass1.Id);		
		Asset__c aSecond = new Asset__c(Contact__c=theContact.Id,Asset_Classification__c=theAssetClass1.Id);
		Asset__c aThird = new Asset__c(Contact__c=theContact.Id,Asset_Classification__c=theAssetClass1.Id);
		insert new sOBject[]{aFirst,aSecond,aThird};
		
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.AssetCase);
		AssetCaseExtension controller = 
			new AssetCaseExtension(
				new ApexPages.StandardController(theCase));
		
		Map<Id,AssetCaseExtension.AssetRow>
			assetRows = controller.getAssetRowMap();
		
		System.assert(assetRows.containsKey(aFirst.Id), 
			'One of the Asset__c records did not have a row in the table.');
		System.assert(assetRows.containsKey(aSecond.Id), 
			'One of the Asset__c records did not have a row in the table.');
		System.assert(assetRows.containsKey(aThird.Id), 
			'One of the Asset__c records did not have a row in the table.');
		
		System.assert(null != assetRows.get(aFirst.Id).getRequestPrototype(), 
			'One of the Asset_Case__c prototypes was null.');		
		System.assert(null != assetRows.get(aSecond.Id).getRequestPrototype(), 
			'One of the Asset_Case__c prototypes was null.');
		System.assert(null != assetRows.get(aThird.Id).getRequestPrototype(), 
			'One of the Asset_Case__c prototypes was null.');
		
		Asset__c theAsset = assetRows.get(aFirst.Id).getObj();
		Asset_Case__c thePrototype = assetRows.get(aFirst.Id).getRequestPrototype();
		
		System.assert(null != theAsset, 'A row returned null for its Asset__c.');
		
		System.assertEquals(theCase.Due_Date__c,thePrototype.Date_Needed__c,
			'Prototype has wrong value for Date_Needed__c.');
		System.assertEquals(NewHireUtil.ASSET_CASE_STATUS_OPEN, thePrototype.Status__c,
			'Prototype has wrong value for Status__c.');
		System.assertEquals(theCase.prEmployee__c,thePrototype.Employee__c,
			'Prototype has wrong value for Employee__c.');
		System.assertEquals(theAsset.Id,thePrototype.Asset__c,
			'Prototype has wrong value for Asset__c.');
		System.assertEquals(theAsset.Asset_Classification__c,thePrototype.Asset_Classification__c,
			'Prototype has wrong value for Asset_Classification__c.');
		
		// Make Changes to the Asset__c.		
		//theAsset.Asset_Classification__c = theAssetClass2.Id; // field is not writeable
				
		// Add some user input.
		Date newDate = Date.today().addDays(60);
		String newNotes = rndStr();
		
		thePrototype.Date_Needed__c = newDate;
		thePrototype.Notes__c = newNotes;
		
		// Request the prototype again.
		thePrototype = assetRows.get(aFirst.Id).getRequestPrototype();
		
		//System.assertEquals(theAsset.Asset_Classification__c,thePrototype.Asset_Classification__c,
		//	'Prototype has wrong value for Asset_Classification__c after the value was changed on the Asset__c.');
		System.assertEquals(newDate,thePrototype.Date_Needed__c,
			'Prototype did not preserve user input for Date_Needed__c.');
		System.assertEquals(newNotes,thePrototype.Notes__c,
			'Prototype did not preserve user input for Notes__c.');		
		
	}
	
	/**
	* GetOpenAssetCaseCount
	* - Output matches getOpenAssetCaseRows().size().
	*/
	@isTest
	public static void testGetOpenAssetCaseCount()
	{
		Account theAccount = new Account(Name=rndStr());
		insert theAccount;
		
		Contact theContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		Contact otherContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		insert new sOBject[]{theContact,otherContact};
		
		Case theCase = new Case(
			prEmployee__c = theContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		Case otherCase = new Case(
			prEmployee__c = otherContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		insert new sOBject[]{theCase,otherCase};
		
		Asset_Classification__c theAssetClass1 = new Asset_Classification__c();
		Asset_Classification__c theAssetClass2 = new Asset_Classification__c();
		insert new sOBject[]{theAssetClass1,theAssetClass2};
				
		// Set up our Asset__c records.		
		Asset__c aIncluded1 = new Asset__c(Contact__c=theContact.Id,Asset_Classification__c=theAssetClass1.Id);		
		Asset__c aIncluded2 = new Asset__c(Contact__c=theContact.Id,Asset_Classification__c=theAssetClass2.Id);
		Asset__c aOtherContact = new Asset__c(Contact__c=otherContact.Id,Asset_Classification__c=theAssetClass1.Id);
		insert new sOBject[]{aIncluded1,aIncluded2,aOtherContact};
		
		// Create arbitrary test values for Status__c.
		String statusValue = NewHireUtil.ASSET_CASE_STATUS_OPEN;
		String otherStatusValue = rndStr();
		while(statusValue == otherStatusValue) { otherStatusValue = rndStr(); }
		
		Asset_Case__c acIncluded1 = new Asset_Case__c(
			Date_Needed__c           = Date.today().addDays(7),
			Status__c         = statusValue,
			Asset__c   = aIncluded1.Id,
			Case__c           = theCase.Id,

			Asset_Classification__c        = theAssetClass1.Id);
			
		Asset_Case__c acIncluded2= new Asset_Case__c(
			Date_Needed__c           = Date.today().addDays(14),
			Status__c         = statusValue,
			Asset__c   = aIncluded2.Id,
			Case__c           = theCase.Id,


			Asset_Classification__c        = theAssetClass2.Id);

		Asset_Case__c acOtherContact = acIncluded1.clone();
			acOtherContact.Asset__c = aOtherContact.Id;
		Asset_Case__c acOtherStatus = acIncluded1.clone();
			acOtherStatus.Status__c = otherStatusValue;
		Asset_Case__c acOtherCase = acIncluded1.clone();
			acOtherCase.Case__c = otherCase.Id;
		
		insert new sObject[]{
				acIncluded1,acIncluded2,acOtherContact,acOtherStatus,acOtherCase
			};
		
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.AssetCase);
		AssetCaseExtension controller = 
			new AssetCaseExtension(
				new ApexPages.StandardController(theCase));
		
		Map<Id,AssetCaseExtension.AssetCaseRow>
			rowMap = controller.queryAssetCaseRows(statusValue);
		
		System.assert(null != rowMap, 'Returned a null set of rows.');
		System.assert(null != controller.getOpenAssetCaseRows(),
			'The getOpenAssetCaseRows() method returned null.');		
		System.assertEquals(controller.getOpenAssetCaseCount(),controller.getOpenAssetCaseRows().size(),
			'Output does not match getOpenAssetCaseRows().size()');				
	}
	
	/**
	* GetOpenAssetCaseRows
	* - Output matches queryAssetCaseRows(NewHireUtil.ASSET_CASE_STATUS_OPEN)
	*/
	@isTest
	public static void testGetOpenAssetCaseRows()
	{
		Account theAccount = new Account(Name=rndStr());
		insert theAccount;
		
		Contact theContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		Contact otherContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		insert new sOBject[]{theContact,otherContact};
		
		Case theCase = new Case(
			prEmployee__c = theContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		Case otherCase = new Case(
			prEmployee__c = otherContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		insert new sOBject[]{theCase,otherCase};
		
		Asset_Classification__c theAssetClass1 = new Asset_Classification__c();
		Asset_Classification__c theAssetClass2 = new Asset_Classification__c();
		insert new sOBject[]{theAssetClass1,theAssetClass2};
								
		// Set up our Asset__c records.		
		Asset__c aIncluded1 = new Asset__c(Contact__c=theContact.Id,Asset_Classification__c=theAssetClass1.Id);		
		Asset__c aIncluded2 = new Asset__c(Contact__c=theContact.Id,Asset_Classification__c=theAssetClass2.Id);
		Asset__c aOtherContact = new Asset__c(Contact__c=otherContact.Id,Asset_Classification__c=theAssetClass1.Id);
		insert new sOBject[]{aIncluded1,aIncluded2,aOtherContact};
		
		// Create arbitrary test values for Status__c.
		String statusValue = NewHireUtil.ASSET_CASE_STATUS_OPEN;
		String otherStatusValue = rndStr();
		while(statusValue == otherStatusValue) { otherStatusValue = rndStr(); }
		
		Asset_Case__c acIncluded1 = new Asset_Case__c(
			Date_Needed__c           = Date.today().addDays(7),
			Status__c         = statusValue,
			Asset__c   = aIncluded1.Id,
			Case__c           = theCase.Id,

			Asset_Classification__c        = theAssetClass1.Id);
			
		Asset_Case__c acIncluded2= new Asset_Case__c(
			Date_Needed__c           = Date.today().addDays(14),
			Status__c         = statusValue,
			Asset__c   = aIncluded2.Id,
			Case__c           = theCase.Id,


			Asset_Classification__c        = theAssetClass2.Id);

		Asset_Case__c acOtherContact = acIncluded1.clone();
			acOtherContact.Asset__c = aOtherContact.Id;
		Asset_Case__c acOtherStatus = acIncluded1.clone();
			acOtherStatus.Status__c = otherStatusValue;
		Asset_Case__c acOtherCase = acIncluded1.clone();
			acOtherCase.Case__c = otherCase.Id;
		
		insert new sObject[]{
				acIncluded1,acIncluded2,acOtherContact,acOtherStatus,acOtherCase
			};
		
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.AssetCase);
		AssetCaseExtension controller = 
			new AssetCaseExtension(
				new ApexPages.StandardController(theCase));
		
		// Query the row map, to which we will compare the
		// getOpenAssetCaseRows() function's output.
		//
		Map<Id,AssetCaseExtension.AssetCaseRow>
			rowMap = controller.queryAssetCaseRows(statusValue);		
		System.assert(null != rowMap, 'Returned a null set of rows.');
		
		// Get the output for the function we are testing.
		//
		List<AssetCaseExtension.AssetCaseRow>
			rowList = controller.getOpenAssetCaseRows();
		System.assert(null != rowList,
			'The getOpenAssetCaseRows() method returned null.');
		
		// To verify the equivalence of the two lists, we verify that:
		// 1. The lists are the same size.
		// 2. Every Asset_Case__c on one list appears on the other.	
		
		System.assertEquals(rowMap.size(),rowList.size(), 
			'The list size did not match the size of the output from queryAssetCaseRows()');
		
		Set<Id> rowsReturned = new Set<id>{};
		for(AssetCaseExtension.AssetCaseRow row : rowList)
		{
			System.assert(null != row.getObj(), 
				'A row from getOpenAssetCaseRows() returned null for its object.');
			rowsReturned.add(row.getObj().Id);
		}		
		
		for(AssetCaseExtension.AssetCaseRow row : rowMap.values())
		{
			System.assert(null != row.getObj(), 
				'A row from queryAssetCaseRows() returned null for its object.');
			System.assert(rowsReturned.contains(row.getObj().Id),
				'A row from queryAssetCaseRows() returned a Asset_Case__c record that did not appear in the list from getOpenAssetCaseRows().');			
		}
	}
	
	/**
	* GetCompleteAssetCaseCount
	* - Output matches getCompleteAssetCaseRows().size()
	*/
	@isTest
	public static void testGetCompleteAssetCaseCount()
	{
		Account theAccount = new Account(Name=rndStr());
		insert theAccount;
		
		Contact theContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		Contact otherContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		insert new sOBject[]{theContact,otherContact};
		
		Case theCase = new Case(
			prEmployee__c = theContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		Case otherCase = new Case(
			prEmployee__c = otherContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		insert new sOBject[]{theCase,otherCase};
		
		Asset_Classification__c theAssetClass1 = new Asset_Classification__c();
		Asset_Classification__c theAssetClass2 = new Asset_Classification__c();
		insert new sOBject[]{theAssetClass1,theAssetClass2};
				
		// Set up our Asset__c records.		
		Asset__c aIncluded1 = new Asset__c(Contact__c=theContact.Id,Asset_Classification__c=theAssetClass1.Id);		
		Asset__c aIncluded2 = new Asset__c(Contact__c=theContact.Id,Asset_Classification__c=theAssetClass2.Id);
		Asset__c aOtherContact = new Asset__c(Contact__c=otherContact.Id,Asset_Classification__c=theAssetClass1.Id);
		insert new sOBject[]{aIncluded1,aIncluded2,aOtherContact};
		
		// Create arbitrary test values for Status__c.
		String statusValue = NewHireUtil.ASSET_CASE_STATUS_COMPLETE;
		String otherStatusValue = rndStr();
		while(statusValue == otherStatusValue) { otherStatusValue = rndStr(); }
		
		Asset_Case__c acIncluded1 = new Asset_Case__c(
			Date_Needed__c           = Date.today().addDays(7),
			Status__c         = statusValue,
			Asset__c   = aIncluded1.Id,
			Case__c           = theCase.Id,

			Asset_Classification__c        = theAssetClass1.Id);
			
		Asset_Case__c acIncluded2= new Asset_Case__c(
			Date_Needed__c           = Date.today().addDays(14),
			Status__c         = statusValue,
			Asset__c   = aIncluded2.Id,
			Case__c           = theCase.Id,


			Asset_Classification__c        = theAssetClass2.Id);

		Asset_Case__c acOtherContact = acIncluded1.clone();
			acOtherContact.Asset__c = aOtherContact.Id;
		Asset_Case__c acOtherStatus = acIncluded1.clone();
			acOtherStatus.Status__c = otherStatusValue;
		Asset_Case__c acOtherCase = acIncluded1.clone();
			acOtherCase.Case__c = otherCase.Id;
		
		insert new sObject[]{
				acIncluded1,acIncluded2,acOtherContact,acOtherStatus,acOtherCase
			};
		
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.AssetCase);
		AssetCaseExtension controller = 
			new AssetCaseExtension(
				new ApexPages.StandardController(theCase));
		
		Map<Id,AssetCaseExtension.AssetCaseRow>
			rowMap = controller.queryAssetCaseRows(statusValue);
		
		System.assert(null != rowMap, 'Returned a null set of rows.');
		System.assert(null != controller.getCompleteAssetCaseRows(),
			'The getCompleteAssetCaseRows() method returned null.');		
		System.assertEquals(
			controller.getCompleteAssetCaseCount(),
			controller.getCompleteAssetCaseRows().size(),
			'Output does not match getCompleteAssetCaseRows().size()');
		
	}
	
	/**
	* GetCompleteAssetCaseRows
	* - Output matches queryAssetCaseRows(NewHireUtil.ASSET_CASE_STATUS_COMPLETE)
	*/
	@isTest
	public static void testGetCompleteAssetCaseRows()
	{
		Account theAccount = new Account(Name=rndStr());
		insert theAccount;
		
		Contact theContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		Contact otherContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		insert new sOBject[]{theContact,otherContact};
		
		Case theCase = new Case(
			prEmployee__c = theContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		Case otherCase = new Case(
			prEmployee__c = otherContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		insert new sOBject[]{theCase,otherCase};
		
		Asset_Classification__c theAssetClass1 = new Asset_Classification__c();
		Asset_Classification__c theAssetClass2 = new Asset_Classification__c();
		insert new sOBject[]{theAssetClass1,theAssetClass2};
				
		// Set up our Asset__c records.		
		Asset__c aIncluded1 = new Asset__c(Contact__c=theContact.Id,Asset_Classification__c=theAssetClass1.Id);		
		Asset__c aIncluded2 = new Asset__c(Contact__c=theContact.Id,Asset_Classification__c=theAssetClass2.Id);
		Asset__c aOtherContact = new Asset__c(Contact__c=otherContact.Id,Asset_Classification__c=theAssetClass1.Id);
		insert new sOBject[]{aIncluded1,aIncluded2,aOtherContact};
		
		// Create arbitrary test values for Status__c.
		String statusValue = NewHireUtil.ASSET_CASE_STATUS_COMPLETE;
		String otherStatusValue = rndStr();
		while(statusValue == otherStatusValue) { otherStatusValue = rndStr(); }
		
		Asset_Case__c acIncluded1 = new Asset_Case__c(
			Date_Needed__c           = Date.today().addDays(7),
			Status__c         = statusValue,
			Asset__c   = aIncluded1.Id,
			Case__c           = theCase.Id,

			Asset_Classification__c        = theAssetClass1.Id);
			
		Asset_Case__c acIncluded2= new Asset_Case__c(
			Date_Needed__c           = Date.today().addDays(14),
			Status__c         = statusValue,
			Asset__c   = aIncluded2.Id,
			Case__c           = theCase.Id,


			Asset_Classification__c        = theAssetClass2.Id);

		Asset_Case__c acOtherContact = acIncluded1.clone();
			acOtherContact.Asset__c = aOtherContact.Id;
		Asset_Case__c acOtherStatus = acIncluded1.clone();
			acOtherStatus.Status__c = otherStatusValue;
		Asset_Case__c acOtherCase = acIncluded1.clone();
			acOtherCase.Case__c = otherCase.Id;
		
		insert new sObject[]{
				acIncluded1,acIncluded2,acOtherContact,acOtherStatus,acOtherCase
			};
		
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.AssetCase);
		AssetCaseExtension controller = 
			new AssetCaseExtension(
				new ApexPages.StandardController(theCase));
		
		// Query the row map, to which we will compare the
		// getCompleteAssetCaseRows() function's output.
		//
		Map<Id,AssetCaseExtension.AssetCaseRow>
			rowMap = controller.queryAssetCaseRows(statusValue);		
		System.assert(null != rowMap, 'Returned a null set of rows.');
		
		// Get the output for the function we are testing.
		//
		List<AssetCaseExtension.AssetCaseRow>
			rowList = controller.getCompleteAssetCaseRows();
		System.assert(null != rowList,
			'The getCompleteAssetCaseRows() method returned null.');
		
		// To verify the equivalence of the two lists, we verify that:
		// 1. The lists are the same size.
		// 2. Every Asset_Case__c on one list appears on the other.		
		 
		System.assertEquals(rowMap.size(),rowList.size(), 
			'The list size did not match the size of the output from queryAssetCaseRows()');
		
		Set<Id> rowsReturned = new Set<id>{};
		for(AssetCaseExtension.AssetCaseRow row : rowList)
		{
			System.assert(null != row.getObj(), 
				'A row from getCompleteAssetCaseRows() returned null for its object.');
			rowsReturned.add(row.getObj().Id);
		}		
		
		for(AssetCaseExtension.AssetCaseRow row : rowMap.values())
		{
			System.assert(null != row.getObj(), 
				'A row from queryAssetCaseRows() returned null for its object.');
			System.assert(rowsReturned.contains(row.getObj().Id),
				'A row from queryAssetCaseRows() returned a Asset_Case__c record that did not appear in the list from getCompleteAssetCaseRows().');			
		}
		
	}
	
	/**
	* QueryAssetCaseRows
	* - Asset_Case__c records without the given Status are excluded.
	* - Asset_Case__c records belonging to other Cases are excluded.
	* - Asset_Case__c records belonging to other Contacts are not excluded.
	* - Rows are returned for all non-excluded Asset_Case__c records.
	* - All necessary fields are queried for an included record.
	*/
	@isTest
	public static void testQueryAssetCaseRows()
	{
		Account theAccount = new Account(Name=rndStr());
		insert theAccount;
		
		Contact theContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		Contact otherContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		insert new sOBject[]{theContact,otherContact};
		
		Case theCase = new Case(
			prEmployee__c = theContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		Case otherCase = new Case(
			Type          = NewHireUtil.CASE_TYPE_UPDATE,
			prEmployee__c = otherContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		insert new sOBject[]{theCase,otherCase};
		
		Asset_Classification__c theAssetClass1 = new Asset_Classification__c();
		Asset_Classification__c theAssetClass2 = new Asset_Classification__c();
		insert new sOBject[]{theAssetClass1,theAssetClass2};
				
		// Set up our Asset__c records.		
		Asset__c aIncluded1 = new Asset__c(Contact__c=theContact.Id,Asset_Classification__c=theAssetClass1.Id);		
		Asset__c aIncluded2 = new Asset__c(Contact__c=theContact.Id,Asset_Classification__c=theAssetClass2.Id);
		Asset__c aOtherContact = new Asset__c(Contact__c=otherContact.Id,Asset_Classification__c=theAssetClass1.Id);
		insert new sOBject[]{aIncluded1,aIncluded2,aOtherContact};
		
		// Decide on test values for Status__c.
		// Status_Summary__c depends on these, so we cannot use arbitrary ones.
		String statusValue = NewHireUtil.ASSET_CASE_STATUS_OPEN;
		String otherStatusValue = NewHireUtil.ASSET_CASE_STATUS_COMPLETE;
		while(statusValue == otherStatusValue) { otherStatusValue = rndStr(); }
		
		Asset_Case__c acIncluded1 = new Asset_Case__c(
			Date_Needed__c          = Date.today().addDays(7),
			Date_Complete__c        = Date.today().addDays(21),
			Status__c               = statusValue,
			Type__c                 = NewHireUtil.ASSET_CASE_TYPE_RECLAIM,
			Asset__c                = aIncluded1.Id,
			Case__c                 = theCase.Id,
			Asset_Classification__c = theAssetClass1.Id);
			
		Asset_Case__c acIncluded2 = new Asset_Case__c(
			Date_Needed__c          = Date.today().addDays(14),
			Date_Complete__c        = Date.today().addDays(21),
			Status__c               = statusValue,
			Type__c                 = NewHireUtil.ASSET_CASE_TYPE_RECLAIM,
			Asset__c                = aIncluded2.Id,
			Case__c                 = theCase.Id,
			Asset_Classification__c = theAssetClass2.Id);

		Asset_Case__c acOtherContact = acIncluded1.clone();
			acOtherContact.Asset__c = aOtherContact.Id;
		Asset_Case__c acOtherStatus  = acIncluded1.clone();
			acOtherStatus.Status__c = otherStatusValue;
		Asset_Case__c acOtherCase    = acIncluded1.clone();
			acOtherCase.Case__c     = otherCase.Id;
		
		insert new sObject[]{
				acIncluded1,acIncluded2,acOtherContact,acOtherStatus,acOtherCase
			};
		
		Asset_Case__c acBef = [
			select
				Id,
				Status_Summary__c,
				Asset_Classification__c,
				Asset_Classification__r.Name,
				Asset__c,
				Asset__r.Name,
				Detail_Summary__c,
				Date_Needed__c,
				Date_Complete__c
			from Asset_Case__c
			where Id = :acIncluded1.Id
		];
		
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.AssetCase);
		AssetCaseExtension controller = 
			new AssetCaseExtension(
				new ApexPages.StandardController(theCase));
		
		Map<Id,AssetCaseExtension.AssetCaseRow>
			rowMap = controller.queryAssetCaseRows(statusValue);
		
		System.assert(null != rowMap, 'Returned a null set of rows.');
		
		// Positive assertions.
		System.assert(rowMap.containsKey(acIncluded1.Id), 
			'A relevant Asset_Case__c record was missing a row.');			
		System.assert(rowMap.containsKey(acIncluded2.Id), 
			'A relevant Asset_Case__c record was missing a row.');
		System.assert(rowMap.containsKey(acOtherContact.Id), 
			'A relevant Asset_Case__c record was missing a row becaus it references a Asset__c belonging to another Contact.');
		
		// Negative assertions.
		System.assert(!rowMap.containsKey(acOtherStatus.Id), 
			'Row list included a Asset_Case__c record with the wrong status.');
		System.assert(!rowMap.containsKey(acOtherStatus.Id), 
			'Row list included a Asset_Case__c record belonging to another Case.');
		
		// Data assertions.
		
		Asset_Case__c acAft = rowMap.get(acIncluded1.Id).getObj();
		
		System.assert(null != acAft, 'A row returned null for its Asset_Case__c.');
		System.assertEquals(acBef.Id,acAft.Id,
			'Wrong Asset_Case__c.Id value.');
		System.assertEquals(acBef.Status_Summary__c,acAft.Status_Summary__c,
			'Wrong Asset_Case__c.Status_Summary__c value.');
		System.assertEquals(acBef.Asset_Classification__c,acAft.Asset_Classification__c,
			'Wrong Asset_Case__c.Asset_Classification__c value.');
		System.assertEquals(acBef.Asset_Classification__r.Name,acAft.Asset_Classification__r.Name,
			'Wrong Asset_Case__c.Asset_Classification__r.Name value.');
		System.assertEquals(acBef.Asset__c,acAft.Asset__c,
			'Wrong Asset_Case__c.Asset__c value.');
		System.assertEquals(acBef.Asset__r.Name,acAft.Asset__r.Name,
			'Wrong Asset_Case__c.Asset__r.Name value.');
		System.assertEquals(acBef.Detail_Summary__c,acAft.Detail_Summary__c,
			'Wrong Asset_Case__c.Detail_Summary__c value.');
		System.assertEquals(acBef.Date_Needed__c,acAft.Date_Needed__c,
			'Wrong Asset_Case__c.Date_Needed__c value.');
		System.assertEquals(acBef.Date_Complete__c,acAft.Date_Complete__c,
			'Wrong Asset_Case__c.Date_Complete__c value.');
	}
	
	/**
	* GetAssetCount
	* - Output matches getAssetRows().size()
	*/
	@isTest
	public static void testGetAssetCount()
	{
		Account theAccount = new Account(Name=rndStr());
		insert theAccount;
		
		Contact theContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		Contact otherContact = theContact.clone();
		insert new sOBject[]{theContact,otherContact};
		
		Case theCase = new Case(
			prEmployee__c = theContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		Case otherCase = theCase.clone();
		insert new sOBject[]{theCase,otherCase};
		
		Asset_Classification__c theAssetClass = new Asset_Classification__c(Name=rndStr());
		insert theAssetClass;
		
		
		Asset__c aThisContact = new Asset__c(
				Contact__c=theContact.Id,
				Asset_Classification__c=theAssetClass.Id);


		Asset__c aOtherContact = aThisContact.clone();
			    aOtherContact.Contact__c = otherContact.Id;
		
		
		insert new sOBject[]{aThisContact,aOtherContact};
		
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.AssetCase);
		AssetCaseExtension controller = 
			new AssetCaseExtension(
				new ApexPages.StandardController(theCase));
		
		// Get the output for the method we are testing.
		Map<Id,AssetCaseExtension.AssetRow>
			rowMap = controller.getAssetRowMap();
		
		System.assert(null != rowMap, 'The getAssetRows() method returned null.');
		System.assert(null != controller.getAssetRows(),
			'The getAssetRows() method returned null.');		
		System.assertEquals(controller.getAssetCount(),controller.getAssetRows().size(),
			'Output does not match getAssetRows().size()');
	}
	
	/**
	* GetAssetRows
	* - Output matches GetAssetRowMap.values()
	*/
	@isTest
	public static void testGetAssetRows()
	{
		Account theAccount = new Account(Name=rndStr());
		insert theAccount;
		
		Contact theContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		Contact otherContact = theContact.clone();
		insert new sOBject[]{theContact,otherContact};
		
		Case theCase = new Case(
			prEmployee__c = theContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		Case otherCase = theCase.clone();
		insert new sOBject[]{theCase,otherCase};
		
		Asset_Classification__c theAssetClass = new Asset_Classification__c(Name=rndStr());
		insert theAssetClass;
		
		Asset__c aThisContact = new Asset__c(
				Contact__c=theContact.Id,
				Asset_Classification__c=theAssetClass.Id);


		Asset__c aOtherContact = aThisContact.clone();
			    aOtherContact.Contact__c = otherContact.Id;
		
		
		insert new sOBject[]{aThisContact,aOtherContact};
		
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.AssetCase);
		AssetCaseExtension controller = 
			new AssetCaseExtension(
				new ApexPages.StandardController(theCase));
		
		// Query the row map, to which we will compare the
		// getOpenAssetCaseRows() function's output.
		//
		Map<Id,AssetCaseExtension.AssetRow>
			rowMap = controller.getAssetRowMap();		
		System.assert(null != rowMap, 'Returned a null set of rows.');
		
		// Get the output for the function we are testing.
		//
		List<AssetCaseExtension.AssetRow>
			rowList = controller.getAssetRows();
		System.assert(null != rowList,
			'The getAssetRows() method returned null.');
		
		// To verify the equivalence of the two lists, we verify that:
		// 1. The lists are the same size.
		// 2. Every Asset__c on one list appears on the other.	
		
		System.assertEquals(rowMap.size(),rowList.size(), 
			'The list size did not match the size of the output from getAssetRowMap()');
		
		Set<Id> rowsReturned = new Set<id>{};
		for(AssetCaseExtension.AssetRow row : rowList)
		{
			System.assert(null != row.getObj(), 
				'A row from getAssetRows() returned null for its object.');
			rowsReturned.add(row.getObj().Id);
		}		
		
		for(AssetCaseExtension.AssetRow row : rowMap.values())
		{
			System.assert(null != row.getObj(), 
				'A row from getAssetRowMap() returned null for its object.');
			System.assert(rowsReturned.contains(row.getObj().Id),
				'A row from getAssetRowMap() returned a Asset_Case__c record that did not appear in the list from getAssetRows().');			
		}
				
	}
	
	/**
	* GetAssetRowMap
	* - A row is returned for each Asset__c belonging to the Contact.
	* - Asset__c records belonging to other Contacts are ignored.
	* - Each row returns a Asset_Case__c prototype matching the output of getRequestPrototype(Asset__c).
	* - The getCanReclaim() and getHasPendingReclamation()
	*   methods function properly on each row, ignoring records belonging to other Cases.
	* - The method has queried all necessary data for the Asset__c record.
	*/
	@isTest
	public static void testGetAssetRowMap()
	{
		Account theAccount = new Account(Name=rndStr());
		insert theAccount;
		
		Contact theContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		Contact otherContact = theContact.clone();
		insert new sOBject[]{theContact,otherContact};
		
		Case theCase = new Case(
			prEmployee__c = theContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		Case otherCase = theCase.clone();
		insert new sOBject[]{theCase,otherCase};
		
		Asset_Classification__c theAssetClass = new Asset_Classification__c(Name=rndStr());
		insert theAssetClass;
		
		// Asset__c and Asset_Case__c 
		// variable naming conventions:
		//
		// a         => Asset__c
		// ac        => Asset_Case__c
		//
		// Open       => Asset__c has a Asset_Case__c 
		//               with Status__c=NewHireUtil.ASSET_CASE_STATUS_OPEN
		// Closed     => Asset__c has a Asset_Case__c 
		//               with Status__c=NewHireUtil.ASSET_CASE_STATUS_COMPLETE
		//
		// Provision  => Asset__c has a Asset_Case__c 
		//               with Status__c=NewHireUtil.ASSET_CASE_TYPE_PROVISION
		// Reclaim    => Asset__c has a Asset_Case__c 
		//               with Status__c=NewHireUtil.ASSET_CASE_TYPE_RECLAIM
		//
		
		// Set up our Asset__c records, based on this prototype.
		Asset__c aProto = new Asset__c(
				Contact__c=theContact.Id,
				Asset_Classification__c=theAssetClass.Id);

		Asset__c aOpenProvision       = aProto.clone();
		Asset__c aOpenReclaim     = aProto.clone();
		Asset__c aOpenOther          = aProto.clone();
		Asset__c aClosedProvision     = aProto.clone();
		Asset__c aClosedReclaim   = aProto.clone();
		Asset__c aClosedOther        = aProto.clone();
						
		Asset__c aOtherContact                 = aProto.clone();
			aOtherContact.Contact__c                 = otherContact.Id;
		Asset__c aOpenReclaimOtherCase = aProto.clone();			
		Asset__c aNoAc                   = aProto.clone();
		
		insert new sOBject[]{
			aOpenProvision,
			aOpenReclaim,
			aOpenOther,
			aClosedProvision,
			aClosedReclaim,
			aClosedOther,
			aOtherContact,
			aOpenReclaimOtherCase,
			aNoAc};
		
		// Set up our Asset_Case__c records, based on this prototype.
		
		Asset_Case__c acProto = new Asset_Case__c(
			Date_Needed__c          = Date.today().addDays(14),
			Case__c                 = theCase.Id,
			Asset_Classification__c = theAssetClass.Id);
		
		Asset_Case__c acOpenProvision   =  acProto.clone();
			acOpenProvision.Asset__c    = aOpenProvision.Id; 
			acOpenProvision.Status__c   = NewHireUtil.ASSET_CASE_STATUS_OPEN;
			acOpenProvision.Type__c     = NewHireUtil.ASSET_CASE_TYPE_PROVISION;
		Asset_Case__c acOpenReclaim     =  acProto.clone();
			acOpenReclaim.Asset__c      = aOpenReclaim.Id;
			acOpenReclaim.Status__c     = NewHireUtil.ASSET_CASE_STATUS_OPEN;
			acOpenReclaim.Type__c       = NewHireUtil.ASSET_CASE_TYPE_RECLAIM;		
		Asset_Case__c acOpenOther       =  acProto.clone();
			acOpenOther.Asset__c        = aOpenOther.Id;
			acOpenOther.Status__c       = NewHireUtil.ASSET_CASE_STATUS_OPEN;
			acOpenOther.Type__c         = rndStr();
		Asset_Case__c acClosedProvision =  acProto.clone();
			acClosedProvision.Asset__c  = aClosedProvision.Id;
			acClosedProvision.Status__c = NewHireUtil.ASSET_CASE_STATUS_COMPLETE;
			acClosedProvision.Type__c   = NewHireUtil.ASSET_CASE_TYPE_PROVISION;
		Asset_Case__c acClosedReclaim   =  acProto.clone();
			acClosedReclaim.Asset__c    = aClosedReclaim.Id;
			acClosedReclaim.Status__c   = NewHireUtil.ASSET_CASE_STATUS_COMPLETE;
			acClosedReclaim.Type__c     = NewHireUtil.ASSET_CASE_TYPE_RECLAIM;
		Asset_Case__c acClosedOther     =  acProto.clone();
			acClosedOther.Asset__c      = aClosedOther.Id;
			acClosedOther.Status__c     = NewHireUtil.ASSET_CASE_STATUS_COMPLETE;
			acClosedOther.Type__c       = rndStr();		

		Asset_Case__c acOpenReclaimOtherCase  = acProto.clone();
			acOpenReclaimOtherCase.Asset__c   = aOpenReclaimOtherCase.Id;
			acOpenReclaimOtherCase.Status__c  = NewHireUtil.ASSET_CASE_STATUS_OPEN;
			acOpenReclaimOtherCase.Type__c    = NewHireUtil.ASSET_CASE_TYPE_RECLAIM;
			acOpenReclaimOtherCase.Case__c    = otherCase.Id;
		
		insert new sOBject[]{
			acOpenProvision,
			acOpenReclaim,
			acOpenOther,
			acClosedProvision,
			acClosedReclaim,
			acClosedOther,
			acOpenReclaimOtherCase};

		// Set up the page and its controllers.
		Test.setCurrentPage(Page.AssetCase);
		AssetCaseExtension controller = 
			new AssetCaseExtension(
				new ApexPages.StandardController(theCase));
		
		// Get the output for the method we are testing.
		Map<Id,AssetCaseExtension.AssetRow>
			rowMap = controller.getAssetRowMap();
		
		System.assert(null != rowMap, 'The getAssetRows() method returned null.');
				
		System.assert(rowMap.containsKey(aOpenProvision.Id), 
			'[Active w/OpenProvisionRequest]: Output mssing a row.');
		System.assert(null != rowMap.get(aOpenProvision.Id).getObj(),
			'[Active w/OpenProvisionRequest]: A row returned null for its Asset__c.');
		System.assertEquals(aOpenProvision.Id,rowMap.get(aOpenProvision.Id).getObj().Id,
			'[Active w/OpenProvisionRequest]: A row returned a Asset__c with the wrong Id.');
		System.assertEquals(true,rowMap.get(aOpenProvision.Id).getCanReclaim(),
			'[Active w/OpenProvisionRequest]: Wrong value for getCanReclaim().');
		System.assertEquals(false,rowMap.get(aOpenProvision.Id).getHasPendingReclamation(),
			'[Active w/OpenProvisionRequest]: Wrong value for getHasPendingReclamation().');
				
		System.assert(rowMap.containsKey(aOpenReclaim.Id), 
			'[Active w/ Open Reclaim Request]: Output mssing a row.');
		System.assert(null != rowMap.get(aOpenReclaim.Id).getObj(),
			'[Active w/ Open Reclaim Request]: A row returned null for its Asset__c.');
		System.assertEquals(aOpenReclaim.Id,rowMap.get(aOpenReclaim.Id).getObj().Id,
			'[Active w/ Open Reclaim Request]: A row returned a Asset__c with the wrong Id.');
		System.assertEquals(false,rowMap.get(aOpenReclaim.Id).getCanReclaim(),
			'[Active w/ Open Reclaim Request]: Wrong value for getCanReclaim().');
		System.assertEquals(true,rowMap.get(aOpenReclaim.Id).getHasPendingReclamation(),
			'[Active w/ Open Reclaim Request]: Wrong value for getHasPendingReclamation().');
		
		System.assert(rowMap.containsKey(aOpenOther.Id), 
			'[Active w/ Open Request of unrecognized Type]: Output mssing a row.');
		System.assert(null != rowMap.get(aOpenOther.Id).getObj(),
			'[Active w/ Open Request of unrecognized Type]: A row returned null for its Asset__c.');
		System.assertEquals(aOpenOther.Id,rowMap.get(aOpenOther.Id).getObj().Id,
			'[Active w/ Open Request of unrecognized Type]: A row returned a Asset__c with the wrong Id.');
		System.assertEquals(true,rowMap.get(aOpenOther.Id).getCanReclaim(),
			'[Active w/ Open Request of unrecognized Type]: Wrong value for getCanReclaim().');
		System.assertEquals(false,rowMap.get(aOpenOther.Id).getHasPendingReclamation(),
			'[Active w/ Open Request of unrecognized Type]: Wrong value for getHasPendingReclamation().');
		
		System.assert(rowMap.containsKey(aClosedProvision.Id), 
			'[Active w/ Closed Activate Request]: Output mssing a row.');
		System.assert(null != rowMap.get(aClosedProvision.Id).getObj(),
			'[Active w/ Closed Activate Request]: A row returned null for its Asset__c.');
		System.assertEquals(aClosedProvision.Id,rowMap.get(aClosedProvision.Id).getObj().Id,
			'[Active w/ Closed Activate Request]: A row returned a Asset__c with the wrong Id.');
		System.assertEquals(true,rowMap.get(aClosedProvision.Id).getCanReclaim(),
			'[Active w/ Closed Activate Request]: Wrong value for getCanReclaim().');
		System.assertEquals(false,rowMap.get(aClosedProvision.Id).getHasPendingReclamation(),
			'[Active w/ Closed Activate Request]: Wrong value for getHasPendingReclamation().');
		
		System.assert(rowMap.containsKey(aClosedReclaim.Id), 
			'[Active w/ Closed Reclaim Request]: Output mssing a row.');
		System.assert(null != rowMap.get(aClosedReclaim.Id).getObj(),
			'[Active w/ Closed Reclaim Request]: A row returned null for its Asset__c.');
		System.assertEquals(aClosedReclaim.Id,rowMap.get(aClosedReclaim.Id).getObj().Id,
			'[Active w/ Closed Reclaim Request]: A row returned a Asset__c with the wrong Id.');
		System.assertEquals(true,rowMap.get(aClosedReclaim.Id).getCanReclaim(),
			'[Active w/ Closed Reclaim Request]: Wrong value for getCanReclaim().');
		System.assertEquals(false,rowMap.get(aClosedReclaim.Id).getHasPendingReclamation(),
			'[Active w/ Closed Reclaim Request]: Wrong value for getHasPendingReclamation().');
		
		System.assert(rowMap.containsKey(aClosedOther.Id), 
			'[Active w/ Closed Request of unrecognized Type]: Output mssing a row.');
		System.assert(null != rowMap.get(aClosedOther.Id).getObj(),
			'[Active w/ Closed Request of unrecognized Type]: A row returned null for its Asset__c.');
		System.assertEquals(aClosedOther.Id,rowMap.get(aClosedOther.Id).getObj().Id,
			'[Active w/ Closed Request of unrecognized Type]: A row returned a Asset__c with the wrong Id.');
		System.assertEquals(true,rowMap.get(aClosedOther.Id).getCanReclaim(),
			'[Active w/ Closed Request of unrecognized Type]: Wrong value for getCanReclaim().');
		System.assertEquals(false,rowMap.get(aClosedOther.Id).getHasPendingReclamation(),
			'[Active w/ Closed Request of unrecognized Type]: Wrong value for getHasPendingReclamation().');
		
		System.assert(!rowMap.containsKey(aOtherContact.Id), 
			'[Belongs to another Contact]: Asset__c should not have a row but does.');
		
		System.assert(rowMap.containsKey(aOpenReclaimOtherCase.Id), 
			'[Active w/ Open Reclaim Request under another Case]: Output mssing a row.');
		System.assert(null != rowMap.get(aOpenReclaimOtherCase.Id).getObj(),
			'[Active w/ Open Reclaim Request under another Case]: A row returned null for its Asset__c.');
		System.assertEquals(aOpenReclaimOtherCase.Id,rowMap.get(aOpenReclaimOtherCase.Id).getObj().Id,
			'[Active w/ Open Reclaim Request under another Case]: A row returned a Asset__c with the wrong Id.');
		System.assertEquals(true,rowMap.get(aOpenReclaimOtherCase.Id).getCanReclaim(),
			'[Active w/ Open Reclaim Request under another Case]: Wrong value for getCanReclaim().');
		System.assertEquals(false,rowMap.get(aOpenReclaimOtherCase.Id).getHasPendingReclamation(),
			'[Active w/ Open Reclaim Request under another Case]: Wrong value for getHasPendingReclamation().');
		
		System.assert(rowMap.containsKey(aNoAc.Id), 
			'[Active w/ No Requests]: Output mssing a row.');
		System.assert(null != rowMap.get(aNoAc.Id).getObj(),
			'[Active w/ No Requests]: A row returned null for its Asset__c.');
		System.assertEquals(aNoAc.Id,rowMap.get(aNoAc.Id).getObj().Id,
			'[Active w/ No Requests]: A row returned a Asset__c with the wrong Id.');
		System.assertEquals(true,rowMap.get(aNoAc.Id).getCanReclaim(),
			'[Active w/ No Requests]: Wrong value for getCanReclaim().');
		System.assertEquals(false,rowMap.get(aNoAc.Id).getHasPendingReclamation(),
			'[Active w/ No Requests]: Wrong value for getHasPendingReclamation().');
		
		// Check the data on one of our Asset__c records.
		Asset__c aBef = [
			select 
				Id,
				Name,
				Asset_Classification__c,
				Asset_Classification__r.Name,
				Detail_Summary__c
			from Asset__c
			where Id = :aOpenReclaim.Id];
			
		Asset__c aAft = rowMap.get(aBef.Id).getObj();
				
		System.assertEquals(aBef.Id,aAft.Id,
			'Row instance returned Asset__c where Id was null or wrong.');
		System.assertEquals(aBef.Name,aAft.Name,
			'Row instance returned Asset__c where Name was null or wrong.');
		System.assertEquals(aBef.Asset_Classification__c,aAft.Asset_Classification__c,
			'Row instance returned Asset__c where Asset_Classification__c was null or wrong.');
		System.assertEquals(aBef.Asset_Classification__r.Name,aAft.Asset_Classification__r.Name,
			'Row instance returned Asset__c where Asset_Classification__r.Name was null or wrong.');
		System.assertEquals(aBef.Detail_Summary__c,aAft.Detail_Summary__c,
			'Row instance returned Asset__c where Detail_Summary__c was null or wrong.');
		
		// Check the output for our prototype.
		Asset_Case__c thisProto = rowMap.get(aAft.Id).getRequestPrototype();
		Asset_Case__c thatProto = controller.getRequestPrototype(aAft);
		
		System.assertEquals(thatProto,thisProto, 
			'The AssetCaseExtension.getRequestPrototype(Asset__c)'+ 
			'and AssetCaseExtension.AssetRow.getRequestPrototype() methods did not return the same record.');
		
	}
	
	
	/**
	* RequestReclamation
	* - A Asset_Case__c record is created for the given Asset__c
	* - All fields on the Asset_Case__c are properly populated.
	* - Bad editid causes failure, with a Page Message.
	* - If the Asset__c cannot be Reclaimed (per AssetRow.getCanReclaim()), 
	*   the operation fails with a page message. 
	*/
	@isTest
	public static void testRequestReclamation()
	{
		Account theAccount = new Account(Name=rndStr());
		insert theAccount;
		
		Contact theContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		Contact otherContact = theContact.clone();
		insert new sOBject[]{theContact,otherContact};
		
		Case theCase = new Case(
			prEmployee__c = theContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		Case otherCase = theCase.clone();
		insert new sOBject[]{theCase,otherCase};
		
		Asset_Classification__c theAssetClass = new Asset_Classification__c(Name=rndStr());
		insert theAssetClass;
		
		// Set up our Asset__c records, based on this prototype.
		Asset__c aProto = new Asset__c(
				Contact__c=theContact.Id,
				Asset_Classification__c=theAssetClass.Id);

		Asset__c aCanReclaim      = aProto.clone();
		Asset__c aAlreadyPending     = aProto.clone();
		Asset__c aPendingOnOtherCase = aProto.clone();
		Asset__c aOtherContact       = aProto.clone();
			aOtherContact.Contact__c        = otherContact.Id;			
		Asset__c aDeleted            = aProto.clone();
		
		insert new sOBject[]{
				aCanReclaim,
				aAlreadyPending,
				aPendingOnOtherCase,
				aOtherContact,
				aDeleted};

		delete aDeleted;
		
		// Set up our Asset_Case__c records, based on this prototype.
		
		Asset_Case__c acAlreadyPending  = new Asset_Case__c(
				Date_Needed__c          = Date.today().addDays(14),
				Case__c                 = theCase.Id,
				Asset_Classification__c = theAssetClass.Id,
				Asset__c                = aAlreadyPending.Id,
				Status__c               = NewHireUtil.ASSET_CASE_STATUS_OPEN,
				Type__c                 = NewHireUtil.ASSET_CASE_TYPE_RECLAIM
			);
		Asset_Case__c acPendingOnOtherCase = acAlreadyPending.clone();
			acPendingOnOtherCase.Case__c = otherCase.Id;
		
		insert new sOBject[]{
				acAlreadyPending,
				acPendingOnOtherCase};
		
		// Check before/after counts on Asset_Case__c records, just in 
		// case an external trigger creates some unexpectedly.
		//
		Map<Id,Asset__c> counts = new Map<Id,Asset__c>([
				select 
					Id,
					(select Id 
					 from Assets_Cases__r
					 where Case__c = :theCase.Id)
				from Asset__c
				where 
					Id in :new List<Id>{
						aCanReclaim.Id,
						aAlreadyPending.Id,
						aPendingOnOtherCase.Id,
						aOtherContact.Id,
						aDeleted.Id
					}
			]);
		 
		// Test with no editid.
		
		Test.setCurrentPage(Page.AssetCase);
		AssetCaseExtension controller = 
			new AssetCaseExtension(
				new ApexPages.StandardController(theCase));
		try
		{ controller.requestReclamation(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling requestReclamation() with no editid caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
				'Attempted reclamation with no ID generated no page messages with ApexPage.Severity.ERROR.');
		
		// Test with null editid.
		
		Test.setCurrentPage(Page.AssetCase);
		controller = new AssetCaseExtension(new ApexPages.StandardController(theCase));
				
		ApexPages.currentPage().getParameters().put('editid',null);
		try
		{ controller.requestReclamation(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling requestReclamation() with null editid caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
				'Attempted reclamation with null editid generated no page messages with ApexPage.Severity.ERROR.');
		
		// Test with deleted editid.
		
		Test.setCurrentPage(Page.AssetCase);
		controller = new AssetCaseExtension(new ApexPages.StandardController(theCase));
				
		ApexPages.currentPage().getParameters().put('editid',aDeleted.Id);
		try
		{ controller.requestReclamation(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling requestReclamation() with a deleted editid caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
			'Attempted reclamation with a deleted editid generated no page messages with ApexPage.Severity.ERROR.');
			
		// Make sure that no Asset_Case__c was created.
		Asset_Case__c[] acCreated = [
			select Id
			from Asset_Case__c
			where 
				Asset__c = :aDeleted.Id 
				and Case__c = :theCase.Id
			limit 1 
		];
		System.assert(acCreated.size()==0, 
			'At least one Asset_Case__c record was created for a Asset__c which was deletd at the time of the request.');
	
				
		// Test with already pending editid.
		
		Test.setCurrentPage(Page.AssetCase);
		controller = new AssetCaseExtension(new ApexPages.StandardController(theCase));
				
		ApexPages.currentPage().getParameters().put('editid',aAlreadyPending.Id);
		try
		{ controller.requestReclamation(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling requestReclamation() with an editid for a Asset__c with an already pending Reclamation request caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
			'Attempted reclamation with an editid for a Asset__c with an already pending Reclamation request generated no page messages with ApexPage.Severity.ERROR.');
			
		// Make sure that no Asset_Case__c was created.
		acCreated = [
			select Id
			from Asset_Case__c
			where 
				Asset__c = :aAlreadyPending.Id 
				and Case__c = :theCase.Id
		];
		System.assert(acCreated.size()==counts.get(aAlreadyPending.Id).Assets_Cases__r.size(), 
			'At least one Asset_Case__c record was created for a Asset__c with an already pending Reclamation request at the time of the request.');
		
		
		// Test with a Asset__c belonging to another Contact.
		
		Test.setCurrentPage(Page.AssetCase);
		controller = new AssetCaseExtension(new ApexPages.StandardController(theCase));
				
		ApexPages.currentPage().getParameters().put('editid',aOtherContact.Id);
		try
		{ controller.requestReclamation(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling requestReclamation() with an editid for a Asset__c belonging to another contact caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
			'Attempted reclamation with an editid for a Asset__c belonging to another contact generated no page messages with ApexPage.Severity.ERROR.');
			
		// Make sure that no Asset_Case__c was created.
		acCreated = [
			select Id
			from Asset_Case__c
			where 
				Asset__c = :aOtherContact.Id 
				and Case__c = :theCase.Id
		];
		System.assert(acCreated.size()==counts.get(aOtherContact.Id).Assets_Cases__r.size(), 
			'At least one Asset_Case__c record was created for a Asset__c belonging to another contact at the time of the request.');
		
		
		// Test a basic success case (an inactive Asset__c with no pending Asset_Case__c)
		
		Test.setCurrentPage(Page.AssetCase);
		controller = new AssetCaseExtension(new ApexPages.StandardController(theCase));
		
		// Add some user input.
		//
		Asset_Case__c proto = controller.getRequestPrototype(aCanReclaim);
		proto.Date_Needed__c = Date.today().addDays(60);
		proto.Notes__c = rndStr();
				
		ApexPages.currentPage().getParameters().put('editid',aCanReclaim.Id);
		controller.requestReclamation();
		
		// Make sure a Asset_Case__c was created.
		
		Asset_Case__c[] acLst = [
			select 
				Id,
				Date_Needed__c,
				Status__c,
				Employee__c,
				Asset__c,


				Asset_Classification__c,
				Notes__c
			from Asset_Case__c
			where Asset__c = :aCanReclaim.Id
			  and Case__c = :theCase.Id
			  and Type__c = :NewHireUtil.ASSET_CASE_TYPE_RECLAIM
		];
		System.assertEquals(1,acLst.size(),'Wrong number of Reclaim Requests found for the given Asset__c and Case__c.');
		
		Asset_Case__c uac = acLst[0];
		
		// Check the data in the request.
		System.assertEquals(NewHireUtil.ASSET_CASE_STATUS_OPEN, uac.Status__c,
			'New Asset_Case__c has wrong value for Status__c.');
		System.assertEquals(theCase.prEmployee__c,uac.Employee__c,
			'New Asset_Case__c.Employee__c does not match Case.prEmployee__c.');
		System.assertEquals(aCanReclaim.Id,uac.Asset__c,
			'New Asset_Case__c.Asset__c does not match the given Id.');
		System.assertEquals(aCanReclaim.Asset_Classification__c,uac.Asset_Classification__c,
			'New Asset_Case__c.Asset_Classification__c does not match Asset__c.Asset_Classification__c.');
		System.assertEquals(proto.Date_Needed__c,uac.Date_Needed__c,
			'New Asset_Case__c.Date_Needed__c does not match the user\'s input.');
		System.assertEquals(proto.Notes__c,uac.Notes__c,
			'New Asset_Case__c.Notes__c does not match the user\'s input.');
		
		
		// Test an inactive Asset__c whose one pending Asset_Case__c belongs to another Case.
		
		Test.setCurrentPage(Page.AssetCase);
		controller = new AssetCaseExtension(new ApexPages.StandardController(theCase));
		
		// Add some user input.
		//
		proto = controller.getRequestPrototype(aPendingOnOtherCase);
		// Don't set the Date_Needed__c: should default to Case.Due_Date__c
		proto.Notes__c = rndStr();
				
		ApexPages.currentPage().getParameters().put('editid',aPendingOnOtherCase.Id);
		controller.requestReclamation();
		
		// Make sure a Asset_Case__c was created.
		
		acLst = [
			select 
				Id,
				Date_Needed__c,
				Status__c,
				Employee__c,
				Asset__c,


				Asset_Classification__c,
				Notes__c
			from Asset_Case__c
			where Asset__c = :aPendingOnOtherCase.Id
			  and Case__c = :theCase.Id
			  and Type__c = :NewHireUtil.ASSET_CASE_TYPE_RECLAIM
		];
		System.assertEquals(1,acLst.size(),'Wrong number of Reclaim Requests found for the given Asset__c and Case__c.');
		
		uac = acLst[0];
		
		// Check the data in the request.
		System.assertEquals(NewHireUtil.ASSET_CASE_STATUS_OPEN, uac.Status__c,
			'New Asset_Case__c has wrong value for Status__c.');
		System.assertEquals(theCase.prEmployee__c,uac.Employee__c,
			'New Asset_Case__c.Employee__c does not match Case.prEmployee__c.');
		System.assertEquals(aPendingOnOtherCase.Id,uac.Asset__c,
			'New Asset_Case__c.Asset__c does not match the given Id.');
		System.assertEquals(aPendingOnOtherCase.Asset_Classification__c,uac.Asset_Classification__c,
			'New Asset_Case__c.Asset_Classification__c does not match Asset__c.Asset_Classification__c.');
		System.assertEquals(theCase.Due_Date__c,uac.Date_Needed__c,
			'New Asset_Case__c.Date_Needed__c did not default to Case.Due_Date__c when no value was given.');
		System.assertEquals(proto.Notes__c,uac.Notes__c,
			'New Asset_Case__c.Notes__c does not match the user\'s input.');
		
	}
	
	/**
	* CancelRequest
	* - If the Asset_Case__c cannot be Canceled (per AssetCaseRow.getCanCancel()),
	*   the operation fails with a page message.
	* - The Asset_Case__c record with the given ID has its status changed to 
	*   NewHireUtil.ASSET_CASE_STATUS_CANCEL
	* - All fields on the Asset_Case__c are properly populated.
	*/
	@isTest
	public static void testCancelRequest()
	{
		Account theAccount = new Account(Name=rndStr());
		insert theAccount;
		
		Contact theContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		Contact otherContact = theContact.clone();
		insert new sOBject[]{theContact,otherContact};
		
		Case theCase = new Case(
			prEmployee__c = theContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		insert new sOBject[]{theCase};
		
		Asset_Classification__c theAssetClass = new Asset_Classification__c(Name=rndStr());
		insert theAssetClass;
		
		// Set up our Asset__c records, based on this prototype.
		Asset__c theAsset = new Asset__c(
				Contact__c=theContact.Id,
				Asset_Classification__c=theAssetClass.Id);
		
		insert theAsset;
		
		// Set up our Asset_Case__c records, based on this prototype.
		
		Asset_Case__c acCanCancel = new Asset_Case__c(
				Date_Needed__c          = Date.today().addDays(14),
				Case__c                 = theCase.Id,
				Asset_Classification__c = theAssetClass.Id,
				Asset__c                = theAsset.Id,
				Status__c               = NewHireUtil.ASSET_CASE_STATUS_OPEN,
				Type__c                 = NewHireUtil.ASSET_CASE_TYPE_RECLAIM
			);
		Asset_Case__c acBadStatus = acCanCancel.clone();
			acBadStatus.Status__c = rndStr();
		Asset_Case__c acBadType = acCanCancel.clone();
			acBadType.Type__c     = rndStr();
		Asset_Case__c acDeleted = acCanCancel.clone();
			
		insert new sObject[]{acCanCancel,acDeleted,acBadStatus,acBadType};		
		delete acDeleted;
						
		// Test with no editid.
		
		Test.setCurrentPage(Page.AssetCase);
		AssetCaseExtension controller = 
			new AssetCaseExtension(
				new ApexPages.StandardController(theCase));
		try
		{ controller.cancelRequest(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling cancelRequest() with no editid caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
				'Attempted cancellation with no ID generated no page messages with ApexPage.Severity.ERROR.');
		
		// Test with null editid.
		
		Test.setCurrentPage(Page.AssetCase);
		controller = new AssetCaseExtension(new ApexPages.StandardController(theCase));
		ApexPages.currentPage().getParameters().put('editid',null);
		
		try
		{ controller.cancelRequest(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling cancelRequest() with null editid caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
				'Attempted cancellation with null ID generated no page messages with ApexPage.Severity.ERROR.');
		
		// Test with deleted editid.
		
		Test.setCurrentPage(Page.AssetCase);
		controller = new AssetCaseExtension(new ApexPages.StandardController(theCase));
		ApexPages.currentPage().getParameters().put('editid',acDeleted.Id);
		
		try
		{ controller.cancelRequest(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling cancelRequest() with deleted editid caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
				'Attempted cancellation with deleted ID generated no page messages with ApexPage.Severity.ERROR.');
		
		// Test with unrecognized Status__c.
		
		Test.setCurrentPage(Page.AssetCase);
		controller = new AssetCaseExtension(new ApexPages.StandardController(theCase));
		ApexPages.currentPage().getParameters().put('editid',acBadStatus.Id);
		
		try
		{ controller.cancelRequest(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling cancelRequest() on a record with unrecognized Status caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
				'Attempted cancellation of a record with unrecognized Status generated no page messages with ApexPage.Severity.ERROR.');
		
		// Test with unrecognized Type__c.
		
		Test.setCurrentPage(Page.AssetCase);
		controller = new AssetCaseExtension(new ApexPages.StandardController(theCase));
		ApexPages.currentPage().getParameters().put('editid',acBadType.Id);
		
		try
		{ controller.cancelRequest(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling cancelRequest() on a record with unrecognized Type caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
				'Attempted cancellation of a record with unrecognized Type generated no page messages with ApexPage.Severity.ERROR.');
		
		// Test a basic success case
		
		Test.setCurrentPage(Page.AssetCase);
		controller = new AssetCaseExtension(new ApexPages.StandardController(theCase));
				
		ApexPages.currentPage().getParameters().put('editid',acCanCancel.Id);
		controller.cancelRequest();
		
		Asset_Case__c theReq = [
			select
				Id,
				Status__c
			from Asset_Case__c
			where Id = :acCanCancel.Id
		];
		
		System.assertEquals(NewHireUtil.ASSET_CASE_STATUS_CANCEL, theReq.Status__c,
			'The Status__c did not change after cancelRequest() was called.');
		
	}
	
	
	/**
	* RequestAsset
	* - The returned PageReference points to the AddService page.
	* - The returned PageReference has an Id parameter with the ID of the Case.
	* - The returned PageReference has getRedirect()==true.
	*/
	@isTest
	public static void testRequestAsset()
	{
		Account theAccount = new Account(Name=rndStr());
		insert theAccount;
		
		Contact theContact = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
		insert theContact;
		
		Case theCase = new Case(
			prEmployee__c = theContact.Id,
			Due_Date__c   = Date.today().addDays(30)
		);
		insert theCase;		
		
		Test.setCurrentPage(Page.AssetCase);
		AssetCaseExtension controller = 
			new AssetCaseExtension(
				new ApexPages.StandardController(theCase));
		
		PageReference nextPage = controller.requestAsset();
		
		String url = nextPage.getUrl();			
		System.assert(null != url, 'Next page URL is null.');
		
		// Normalize the URLs so we can compare them.
		String expectedUrl = Page.AddAsset.getUrl().replaceAll('\\\\','/').toLowercase();
		url = url.replaceall('\\\\','/').toLowercase().split('[?]')[0];
		
		System.assertEquals(expectedUrl,url,'Wrong URL for next page.');
		
		System.assert(nextPage.getParameters().containsKey('id'),
		'The next page URL does not include an ID parameter.');
		System.assertEquals(theCase.Id,nextPage.getParameters().get('id'),
		'The the ID parameter in the next page URL does not contain the current Case\'s ID.');
		System.assertEquals(true,nextPage.getRedirect(),'Wrong value for nextPage.getRedirect().');
	}
	
}