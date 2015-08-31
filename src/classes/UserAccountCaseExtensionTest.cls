/**
* Unit tests for the UserAccountCaseExtension class.
*
* Assertions as follows:
*
* GetTheCase
* - The case from the Contructor is returned.
* - The Id, Due_Date__c, and prEmployee__c are populated.
* - An invalid Case causes the page to fail.
*
* GetCanRequestUserAccount
* - Returns false if Case.Type != NewHireUtil.CASE_TYPE_DROP
* - Returns true otherwise.
*
* Invalidate
* - New records are added to lists.
* - Deleted records are removed from lists.
* - Records with changed status are moved to the appropriate lists.
* - User inputs on User_Account_Case__c request prototypes for User_Account__c records that do not change.
*
* GetRequestPrototype
* - A prototype is returned for every User_Account__c
* - First call reflects the data in the Case.
* - Second call preserves Date__c and Notes__c from user and reflects changes to the Case and User_Account__c.
*
* GetOpenUserAccountCaseCount
* - Output matches getOpenUserAccountCaseRows().size().
*
* GetOpenUserAccountCaseRows
* - Output matches queryUserAccountCaseRows(NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN)
*
* GetCompleteUserAccountCaseCount
* - Output matches getCompleteUserAccountCaseRows().size()
*
* GetCompleteUserAccountCaseRows
* - Output matches queryUserAccountCaseRows(NewHireUtil.USER_ACCOUNT_CASE_STATUS_COMPLETE)
* 
* QueryUserAccountCaseRows
* - Each Complete User_Account_Case__c record belonging to the Case has a row.
* - Complete User_Account_Case__c records not belonging to the Case are excluded.
* - Non-Complete User_Account_Case__c records belonging to the Case are excluded.
*
* GetUserAccountCount
* - Output matches getUserAccountRows().size()
*
* GetUserAccountRows
* - Output matches GetUserAccountRowMap.values()
*
* GetUserAccountRowMap
* - A row is returned for each User_Account__c belonging to the Contact.
* - User_Account__c records belonging to other Contacts are ignored.
* - Each row returns a User_Account_Case__c prototype matching the output of getRequestPrototype(User_Account__c).
* - The getCanReactivate(), getCanDeactivate(), getHasPendingReactivation(), and getHasPendingDeactivation()
*   methods function properly on each row, ignoring records belonging to other Cases.
* - The method has queried all necessary data for the User_Account__c record.
*
* RequestActivation
* - A User_Account_Case__c record is created for the given User_Account__c
* - All fields on the User_Account_Case__c are properly populated.
* - Bad editid causes failure, with a Page Message.
* - If the User_Account__c cannot be Activated (per UserAccountRow.getCanReactivate()), 
*   the operation fails with a page message.
*
* RequestDeactivation
* - A User_Account_Case__c record is created for the given User_Account__c
* - All fields on the User_Account_Case__c are properly populated.
* - Bad editid causes failure, with a Page Message.
* - If the User_Account__c cannot be Deactivated (per UserAccountRow.getCanDeactivate()), 
*   the operation fails with a page message. 
*
* CancelRequest
* - If the User_Account_Case__c cannot be Canceled (per UserAccountCaseRow.getCanCancel()),
*   the operation fails with a page message.
* - The User_Account_Case__c record with the given ID has its status changed to 
*   NewHireUtil.USER_ACCOUNT_CASE_STATUS_CANCEL
* - All fields on the User_Account_Case__c are properly populated.
*
* MakeActivationChangeRequest
* Method is covered extensively by RequestDeactivation and RequestActivation
*
*/
@isTest
private class UserAccountCaseExtensionTest 
{
	
	public static String rndStr()
	{
		return 'UACExtTest'+Math.random(); 
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
		Test.setCurrentPage(Page.UserAccountCase);
		UserAccountCaseExtension controller = 
			new UserAccountCaseExtension(
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
			new UserAccountCaseExtension(
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
	* GetCanRequestUserAccount
	* - Returns false if Case.Type == NewHireUtil.CASE_TYPE_DROP
	* - Returns true otherwise.
	*/
	@isTest
	public static void testGetCanRequestUserAccount()
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
		Test.setCurrentPage(Page.UserAccountCase);
		UserAccountCaseExtension controller = 
			new UserAccountCaseExtension(
				new ApexPages.StandardController(theCase));
				
		System.assert(!controller.getCanRequestUserAccount(),'Returned true for a Drop Case.');
		
		// Try again with a different Type.
		//
		theCase.Type = rndStr();
		update theCase;
		
		controller = 
			new UserAccountCaseExtension(
				new ApexPages.StandardController(theCase));
		
		System.assert(controller.getCanRequestUserAccount(),'Returned false for a non Drop Case.');
		
	}
	
	/**
	* Invalidate
	* - New records are added to lists.
	* - Deleted records are removed from lists.
	* - Records with changed status are moved to the appropriate lists.
	* - User inputs on User_Account_Case__c request prototypes for User_Account__c records that do not change.
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
		
		Service__c theService = new Service__c();
		insert theService;
		
		// Set up our User_Account__c records.
		User_Account__c uaToKeep = new User_Account__c(Contact__c=theContact.Id,Service__c=theService.Id);		
		User_Account__c uaToDelete = new User_Account__c(Contact__c=theContact.Id,Service__c=theService.Id);
		User_Account__c uaToChange = new User_Account__c(Contact__c=theContact.Id,Service__c=theService.Id);
		User_Account__c uaToAdd = new User_Account__c(Contact__c=theContact.Id,Service__c=theService.Id);
		insert new sOBject[]{uaToKeep,uaToDelete,uaToChange};
		
		// Set up our open User_Account_Case__c records.
		User_Account_Case__c uacOpenToKeep   = 
			new User_Account_Case__c(Status__c=NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN, Case__c=theCase.Id,User_Account__c=uaToKeep.Id);
		User_Account_Case__c uacOpenToDelete = 
			new User_Account_Case__c(Status__c=NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN,Case__c=theCase.Id,User_Account__c=uaToKeep.Id);
		User_Account_Case__c uacOpenToChange = 
			new User_Account_Case__c(Type__c=NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE, Status__c=NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN,Case__c=theCase.Id,User_Account__c=uaToChange.Id);
		User_Account_Case__c uacOpenToMove = 
			new User_Account_Case__c(Status__c=NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN,Case__c=theCase.Id,User_Account__c=uaToKeep.Id);
		User_Account_Case__c uacOpenToAdd = 
			new User_Account_Case__c(Status__c=NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN,Case__c=theCase.Id,User_Account__c=uaToKeep.Id);
		
		// Set up our Closed User_Account_Case__c records.
		User_Account_Case__c uacClosedToKeep   = 
			new User_Account_Case__c(Status__c=NewHireUtil.USER_ACCOUNT_CASE_STATUS_COMPLETE, Case__c=theCase.Id,User_Account__c=uaToKeep.Id);
		User_Account_Case__c uacClosedToDelete = 
			new User_Account_Case__c(Status__c=NewHireUtil.USER_ACCOUNT_CASE_STATUS_COMPLETE, Case__c=theCase.Id,User_Account__c=uaToKeep.Id);
		User_Account_Case__c uacClosedToMove = 
			new User_Account_Case__c(Status__c=NewHireUtil.USER_ACCOUNT_CASE_STATUS_COMPLETE, Case__c=theCase.Id,User_Account__c=uaToKeep.Id);
		User_Account_Case__c uacClosedToAdd = 
			new User_Account_Case__c(Status__c=NewHireUtil.USER_ACCOUNT_CASE_STATUS_COMPLETE, Case__c=theCase.Id,User_Account__c=uaToKeep.Id);
		
		insert new sObject[]{uacOpenToKeep,uacOpenToDelete,uacOpenToChange,uacOpenToMove,uacClosedToKeep,uacClosedToDelete,uacClosedToMove};
		
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.UserAccountCase);
		UserAccountCaseExtension controller = 
			new UserAccountCaseExtension(
				new ApexPages.StandardController(theCase));
		
		// Comprehensive testing of these functions is done 
		// elsewhere, but we test them here as a sanity check.  
		
		// Pull a map of User_Account__c records.
		Map<Id,UserAccountCaseExtension.UserAccountRow>  
			userAccounts = controller.getUserAccountRowMap();
		
		// Pull a map of open User_Account_Case__c records.			
		List<UserAccountCaseExtension.UserAccountCaseRow> 
			openUserAccountCasesList = controller.getOpenUserAccountCaseRows();
		Map<Id,UserAccountCaseExtension.UserAccountCaseRow> 
			openUserAccountCases = new  Map<Id,UserAccountCaseExtension.UserAccountCaseRow>();
		for(UserAccountCaseExtension.UserAccountCaseRow row : openUserAccountCasesList)
		{ openUserAccountCases.put(row.getObj().Id,row); }
		
		// Pull a map of closed User_Account_Case__c records.						
		List<UserAccountCaseExtension.UserAccountCaseRow> 
			closedUserAccountCasesList = controller.getCompleteUserAccountCaseRows();
		Map<Id,UserAccountCaseExtension.UserAccountCaseRow> 
			closedUserAccountCases = new  Map<Id,UserAccountCaseExtension.UserAccountCaseRow>();
		for(UserAccountCaseExtension.UserAccountCaseRow row : closedUserAccountCasesList)
		{ closedUserAccountCases.put(row.getObj().Id,row); }
		
		// Place some user input into a row.
		UserAccountCaseExtension.UserAccountRow uaRowToKeep = userAccounts.get(uaToKeep.Id);
		uaRowToKeep.getRequestPrototype().Notes__c = 'This is a test (before).';
				
		System.assert(userAccounts.containsKey(uaToKeep.Id),
			'A row for one of the initial User_Account__c records was missing on initialization.');
		System.assert(userAccounts.containsKey(uaToDelete.Id),
			'A row for one of the initial User_Account__c records was missing on initialization.');
		System.assert(userAccounts.containsKey(uaToChange.Id),
			'A row for one of the initial User_Account__c records was missing on initialization.');
			
		System.assert(openUserAccountCases.containsKey(uacOpenToKeep.Id),
			'A row for one of the initial open User_Account_Case__c records was missing on initialization.');
		System.assert(openUserAccountCases.containsKey(uacOpenToDelete.Id),
			'A row for one of the initial open User_Account_Case__c records was missing on initialization.');
		System.assert(openUserAccountCases.containsKey(uacOpenToMove.Id),
			'A row for one of the initial open User_Account_Case__c records was missing on initialization.');
		System.assert(openUserAccountCases.containsKey(uacOpenToChange.Id),
			'A row for one of the initial open User_Account_Case__c records was missing on initialization.');
		
		System.assert(closedUserAccountCases.containsKey(uacClosedToKeep.Id),
			'A row for one of the initial closed User_Account_Case__c records was missing on initialization.');
		System.assert(closedUserAccountCases.containsKey(uacClosedToDelete.Id),
			'A row for one of the initial closed User_Account_Case__c records was missing on initialization.');
		System.assert(closedUserAccountCases.containsKey(uacClosedToMove.Id),
			'A row for one of the initial closed User_Account_Case__c records was missing on initialization.');
		
		// Delete some records.
		delete new sObject[]{uaToDelete,uacOpenToDelete,uacClosedToDelete};
		
		// Add some records.
		insert new sObject[]{uaToAdd,uacOpenToAdd,uacClosedToAdd};
		
		// Move some records.
		uacOpenToMove.Status__c   = NewHireUtil.USER_ACCOUNT_CASE_STATUS_COMPLETE;
		uacClosedToMove.Status__c = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN;
		
		// Change some records.
		User_Account_Case__c newUacOpenToChange = uacOpenToChange.clone(true,true,true,true);
		newUacOpenToChange.Type__c = NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE;
		
		update new sObject[]{uacOpenToMove,uacClosedToMove,newUacOpenToChange};
		
		// Save an instance of our changeable User_Account_Row__c for comparison
		// after the change.
		UserAccountCaseExtension.UserAccountRow uaRowToChange = userAccounts.get(uaToChange.Id);	
				
		// Do the invalidation.		
		controller.invalidate();
		
		// Pull a map of User_Account__c records.
		userAccounts = controller.getUserAccountRowMap();
		
		// Pull a map of open User_Account_Case__c records.			
		openUserAccountCasesList = controller.getOpenUserAccountCaseRows();
		openUserAccountCases = new  Map<Id,UserAccountCaseExtension.UserAccountCaseRow>();
		for(UserAccountCaseExtension.UserAccountCaseRow row : openUserAccountCasesList)
		{ openUserAccountCases.put(row.getObj().Id,row); }
		
		// Pull a map of closed User_Account_Case__c records.						
		closedUserAccountCasesList = controller.getCompleteUserAccountCaseRows();
		closedUserAccountCases = new  Map<Id,UserAccountCaseExtension.UserAccountCaseRow>();
		for(UserAccountCaseExtension.UserAccountCaseRow row : closedUserAccountCasesList)
		{ closedUserAccountCases.put(row.getObj().Id,row); }
		
		System.assert(userAccounts.containsKey(uaToKeep.Id),
			'A row for one of the initial User_Account__c records went missing after invalidation.');
		System.assert(!userAccounts.containsKey(uaToDelete.Id),
			'A deleted User_Account__c record still had a row after invalidation.');
		System.assert(userAccounts.containsKey(uaToChange.Id),
			'A row for one of the initial User_Account__c records went missing after invalidation.');
		System.assert(userAccounts.containsKey(uaToAdd.Id),
			'A row for a newly added User_Account__c record was missing after invalidation.');
			
		System.assert(openUserAccountCases.containsKey(uacOpenToKeep.Id),
			'A row for one of the initial open User_Account_Case__c records was missing after invalidation.');
		System.assert(!openUserAccountCases.containsKey(uacOpenToDelete.Id),
			'A deleted open User_Account__c record still had a row after invalidation.');
		System.assert(!openUserAccountCases.containsKey(uacOpenToMove.Id),
			'An open open User_Account_Case__c was still persent on the open list after it was changed to closed.');
		System.assert(closedUserAccountCases.containsKey(uacOpenToMove.Id),
			'An open User_Account_Case__c record did not appear on the closed list after its status was changed to closed.');
		System.assert(openUserAccountCases.containsKey(uacOpenToChange.Id),
			'A row for one of the initial open User_Account_Case__c records was missing after invalidation.');
		System.assert(openUserAccountCases.get(uacOpenToChange.Id).getObj().Type__c != uacOpenToChange.Type__c,
			'An open User_Account_Case__c whose Type__c had changed did not show the new Type__c after invalidation.');
		System.assert(openUserAccountCases.containsKey(uacOpenToAdd.Id),
			'A row for a newly added open User_Account_Case__c record was missing after invalidation.');
			
		System.assert(closedUserAccountCases.containsKey(uacClosedToKeep.Id),
			'A row for one of the initial closed User_Account_Case__c records was missing after invalidation.');
		System.assert(!closedUserAccountCases.containsKey(uacClosedToDelete.Id),
			'A deleted closed User_Account_Case__c record still had a row after invalidation.');
		System.assert(!closedUserAccountCases.containsKey(uacClosedToMove.Id),
			'A closed User_Account_Case__c was still persent on the open list after it was changed to open.');
		System.assert(openUserAccountCases.containsKey(uacClosedToMove.Id),
			'A closed User_Account_Case__c record did not appear on the open list after its status was changed to open.');
		System.assert(closedUserAccountCases.containsKey(uacClosedToAdd.Id),
			'A row for a newly added closed User_Account_Case__c record was missing after invalidation.');
			
		System.assert(uaRowToChange.getHasPendingReactivation()!=userAccounts.get(uaToChange.Id).getHasPendingReactivation(),
			'A Type change from Activate to Reactivate on a User_Account_Case__c request did not show up on the corresponding User_Account__c record\'s row'
		);
		
		System.assertEquals(uaRowToKeep.getRequestPrototype().Notes__c,userAccounts.get(uaToKeep.Id).getRequestPrototype().Notes__c,
			'User input on a User_Account__c row was not preserved after invalidation'
		);		
	}
	
	/**
	* GetRequestPrototype
	* - A prototype is returned for every User_Account__c
	* - First call reflects the data in the Case.
	* - Second call preserves Date__c and Notes__c from user and reflects changes to the User_Account__c.
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
		
		Service__c theService1 = new Service__c();
		Service__c theService2 = new Service__c();
		insert new sOBject[]{theService1,theService2};
		
		Service_Role__c theRole1 = new Service_Role__c(Service__c=theService1.Id);
		Service_Role__c theRole2 = new Service_Role__c(Service__c=theService2.Id);
		Service_Profile__c theProfile1 = new Service_Profile__c(Service__c=theService1.Id);		
		Service_Profile__c theProfile2 = new Service_Profile__c(Service__c=theService2.Id);
		insert new sOBject[]{theRole1,theProfile1,theRole2,theProfile2};
		
		// Set up our User_Account__c records.
		User_Account__c uaFirst = new User_Account__c(Contact__c=theContact.Id,Service__c=theService1.Id,Service_Role__c=theRole1.Id,Service_Profile__c=theProfile1.Id);		
		User_Account__c uaSecond = new User_Account__c(Contact__c=theContact.Id,Service__c=theService1.Id,Service_Role__c=theRole1.Id,Service_Profile__c=theProfile1.Id);
		User_Account__c uaThird = new User_Account__c(Contact__c=theContact.Id,Service__c=theService1.Id,Service_Role__c=theRole1.Id,Service_Profile__c=theProfile1.Id);
		insert new sOBject[]{uaFirst,uaSecond,uaThird};
		
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.UserAccountCase);
		UserAccountCaseExtension controller = 
			new UserAccountCaseExtension(
				new ApexPages.StandardController(theCase));
		
		Map<Id,UserAccountCaseExtension.UserAccountRow>
			userAccountRows = controller.getUserAccountRowMap();
		
		System.assert(userAccountRows.containsKey(uaFirst.Id), 
			'One of the User_Account__c records did not have a row in the table.');
		System.assert(userAccountRows.containsKey(uaSecond.Id), 
			'One of the User_Account__c records did not have a row in the table.');
		System.assert(userAccountRows.containsKey(uaThird.Id), 
			'One of the User_Account__c records did not have a row in the table.');
		
		System.assert(null != userAccountRows.get(uaFirst.Id).getRequestPrototype(), 
			'One of the User_Account_Case__c prototypes was null.');		
		System.assert(null != userAccountRows.get(uaSecond.Id).getRequestPrototype(), 
			'One of the User_Account_Case__c prototypes was null.');
		System.assert(null != userAccountRows.get(uaThird.Id).getRequestPrototype(), 
			'One of the User_Account_Case__c prototypes was null.');
		
		User_Account__c theUserAccount = userAccountRows.get(uaFirst.Id).getObj();
		User_Account_Case__c thePrototype = userAccountRows.get(uaFirst.Id).getRequestPrototype();
		
		System.assert(null != theUserAccount, 'A row returned null for its User_Account__c.');
		
		System.assertEquals(theCase.Due_Date__c,thePrototype.Date__c,
			'Prototype has wrong value for Date__c.');
		System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN, thePrototype.Status__c,
			'Prototype has wrong value for Status__c.');
		System.assertEquals(theCase.prEmployee__c,thePrototype.Employee__c,
			'Prototype has wrong value for Employee__c.');
		System.assertEquals(theUserAccount.Id,thePrototype.User_Account__c,
			'Prototype has wrong value for User_Account__c.');
		System.assertEquals(theUserAccount.Service_Role__c,thePrototype.Role__c,
			'Prototype has wrong value for Role__c.');
		System.assertEquals(theUserAccount.Service_Profile__c,thePrototype.Profile__c,
			'Prototype has wrong value for Profile__c.');
		System.assertEquals(theUserAccount.Service__c,thePrototype.Service__c,
			'Prototype has wrong value for Service__c.');
		
		// Make Changes to the User_Account__c.		
		//theUserAccount.Service__c = theService2.Id; // field is not writeable
		theUserAccount.Service_Role__c = theRole2.Id;
		theUserAccount.Service_Profile__c = theProfile2.Id;
		
		// Add some user input.
		Date newDate = Date.today().addDays(60);
		String newNotes = rndStr();
		
		thePrototype.Date__c = newDate;
		thePrototype.Notes__c = newNotes;
		
		// Request the prototype again.
		thePrototype = userAccountRows.get(uaFirst.Id).getRequestPrototype();
		
		System.assertEquals(theUserAccount.Service_Role__c,thePrototype.Role__c,
			'Prototype has wrong value for Role__c after the value was changed on the User_Account__c.');
		System.assertEquals(theUserAccount.Service_Profile__c,thePrototype.Profile__c,
			'Prototype has wrong value for Profile__c after the value was changed on the User_Account__c.');
		//System.assertEquals(theUserAccount.Service__c,thePrototype.Service__c,
		//	'Prototype has wrong value for Service__c after the value was changed on the User_Account__c.');
		System.assertEquals(newDate,thePrototype.Date__c,
			'Prototype did not preserve user input for Date__c.');
		System.assertEquals(newNotes,thePrototype.Notes__c,
			'Prototype did not preserve user input for Notes__c.');		
		
	}
	
	/**
	* GetOpenUserAccountCaseCount
	* - Output matches getOpenUserAccountCaseRows().size().
	*/
	@isTest
	public static void testGetOpenUserAccountCaseCount()
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
		
		Service__c theService1 = new Service__c();
		Service__c theService2 = new Service__c();
		insert new sOBject[]{theService1,theService2};
		
		Service_Role__c theRole1 = new Service_Role__c(Service__c=theService1.Id,Name=rndStr());
		Service_Role__c theRole2 = new Service_Role__c(Service__c=theService2.Id,Name=rndStr());
		Service_Profile__c theProfile1 = new Service_Profile__c(Service__c=theService1.Id,Name=rndStr());		
		Service_Profile__c theProfile2 = new Service_Profile__c(Service__c=theService2.Id,Name=rndStr());
		insert new sOBject[]{theRole1,theRole2,theProfile1,theProfile2};
				
		// Set up our User_Account__c records.		
		User_Account__c uaIncluded1 = new User_Account__c(Contact__c=theContact.Id,Service__c=theService1.Id,Service_Role__c=theRole1.Id,Service_Profile__c=theProfile1.Id);		
		User_Account__c uaIncluded2 = new User_Account__c(Contact__c=theContact.Id,Service__c=theService2.Id,Service_Role__c=theRole2.Id,Service_Profile__c=theProfile2.Id);
		User_Account__c uaOtherContact = new User_Account__c(Contact__c=otherContact.Id,Service__c=theService1.Id,Service_Role__c=theRole1.Id,Service_Profile__c=theProfile1.Id);
		insert new sOBject[]{uaIncluded1,uaIncluded2,uaOtherContact};
		
		// Create arbitrary test values for Status__c.
		String statusValue = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN;
		String otherStatusValue = rndStr();
		while(statusValue == otherStatusValue) { otherStatusValue = rndStr(); }
		
		User_Account_Case__c uacIncluded1 = new User_Account_Case__c(
			Date__c           = Date.today().addDays(7),
			Status__c         = statusValue,
			User_Account__c   = uaIncluded1.Id,
			Case__c           = theCase.Id,
			Role__c           = theRole1.Id,
			Profile__c        = theProfile1.Id,
			Service__c        = theService1.Id);
			
		User_Account_Case__c uacIncluded2= new User_Account_Case__c(
			Date__c           = Date.today().addDays(14),
			Status__c         = statusValue,
			User_Account__c   = uaIncluded2.Id,
			Case__c           = theCase.Id,
			Role__c           = theRole2.Id,
			Profile__c        = theProfile2.Id,
			Service__c        = theService2.Id);

		User_Account_Case__c uacOtherContact = uacIncluded1.clone();
			uacOtherContact.User_Account__c = uaOtherContact.Id;
		User_Account_Case__c uacOtherStatus = uacIncluded1.clone();
			uacOtherStatus.Status__c = otherStatusValue;
		User_Account_Case__c uacOtherCase = uacIncluded1.clone();
			uacOtherCase.Case__c = otherCase.Id;
		
		insert new sObject[]{
				uacIncluded1,uacIncluded2,uacOtherContact,uacOtherStatus,uacOtherCase
			};
		
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.UserAccountCase);
		UserAccountCaseExtension controller = 
			new UserAccountCaseExtension(
				new ApexPages.StandardController(theCase));
		
		Map<Id,UserAccountCaseExtension.UserAccountCaseRow>
			rowMap = controller.queryUserAccountCaseRows(statusValue);
		
		System.assert(null != rowMap, 'Returned a null set of rows.');
		System.assert(null != controller.getOpenUserAccountCaseRows(),
			'The getOpenUserAccountCaseRows() method returned null.');		
		System.assertEquals(controller.getOpenUserAccountCaseCount(),controller.getOpenUserAccountCaseRows().size(),
			'Output does not match getOpenUserAccountCaseRows().size()');				
	}
	
	/**
	* GetOpenUserAccountCaseRows
	* - Output matches queryUserAccountCaseRows(NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN)
	*/
	@isTest
	public static void testGetOpenUserAccountCaseRows()
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
		
		Service__c theService1 = new Service__c();
		Service__c theService2 = new Service__c();
		insert new sOBject[]{theService1,theService2};
		
		Service_Role__c theRole1 = new Service_Role__c(Service__c=theService1.Id,Name=rndStr());
		Service_Role__c theRole2 = new Service_Role__c(Service__c=theService2.Id,Name=rndStr());
		Service_Profile__c theProfile1 = new Service_Profile__c(Service__c=theService1.Id,Name=rndStr());		
		Service_Profile__c theProfile2 = new Service_Profile__c(Service__c=theService2.Id,Name=rndStr());
		insert new sOBject[]{theRole1,theRole2,theProfile1,theProfile2};
				
		// Set up our User_Account__c records.		
		User_Account__c uaIncluded1 = new User_Account__c(Contact__c=theContact.Id,Service__c=theService1.Id,Service_Role__c=theRole1.Id,Service_Profile__c=theProfile1.Id);		
		User_Account__c uaIncluded2 = new User_Account__c(Contact__c=theContact.Id,Service__c=theService2.Id,Service_Role__c=theRole2.Id,Service_Profile__c=theProfile2.Id);
		User_Account__c uaOtherContact = new User_Account__c(Contact__c=otherContact.Id,Service__c=theService1.Id,Service_Role__c=theRole1.Id,Service_Profile__c=theProfile1.Id);
		insert new sOBject[]{uaIncluded1,uaIncluded2,uaOtherContact};
		
		// Create arbitrary test values for Status__c.
		String statusValue = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN;
		String otherStatusValue = rndStr();
		while(statusValue == otherStatusValue) { otherStatusValue = rndStr(); }
		
		User_Account_Case__c uacIncluded1 = new User_Account_Case__c(
			Date__c           = Date.today().addDays(7),
			Status__c         = statusValue,
			User_Account__c   = uaIncluded1.Id,
			Case__c           = theCase.Id,
			Role__c           = theRole1.Id,
			Profile__c        = theProfile1.Id,
			Service__c        = theService1.Id);
			
		User_Account_Case__c uacIncluded2= new User_Account_Case__c(
			Date__c           = Date.today().addDays(14),
			Status__c         = statusValue,
			User_Account__c   = uaIncluded2.Id,
			Case__c           = theCase.Id,
			Role__c           = theRole2.Id,
			Profile__c        = theProfile2.Id,
			Service__c        = theService2.Id);

		User_Account_Case__c uacOtherContact = uacIncluded1.clone();
			uacOtherContact.User_Account__c = uaOtherContact.Id;
		User_Account_Case__c uacOtherStatus = uacIncluded1.clone();
			uacOtherStatus.Status__c = otherStatusValue;
		User_Account_Case__c uacOtherCase = uacIncluded1.clone();
			uacOtherCase.Case__c = otherCase.Id;
		
		insert new sObject[]{
				uacIncluded1,uacIncluded2,uacOtherContact,uacOtherStatus,uacOtherCase
			};
		
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.UserAccountCase);
		UserAccountCaseExtension controller = 
			new UserAccountCaseExtension(
				new ApexPages.StandardController(theCase));
		
		// Query the row map, to which we will compare the
		// getOpenUserAccountCaseRows() function's output.
		//
		Map<Id,UserAccountCaseExtension.UserAccountCaseRow>
			rowMap = controller.queryUserAccountCaseRows(statusValue);		
		System.assert(null != rowMap, 'Returned a null set of rows.');
		
		// Get the output for the function we are testing.
		//
		List<UserAccountCaseExtension.UserAccountCaseRow>
			rowList = controller.getOpenUserAccountCaseRows();
		System.assert(null != rowList,
			'The getOpenUserAccountCaseRows() method returned null.');
		
		// To verify the equivalence of the two lists, we verify that:
		// 1. The lists are the same size.
		// 2. Every User_Account_Case__c on one list appears on the other.	
		
		System.assertEquals(rowMap.size(),rowList.size(), 
			'The list size did not match the size of the output from queryUserAccountCaseRows()');
		
		Set<Id> rowsReturned = new Set<id>{};
		for(UserAccountCaseExtension.UserAccountCaseRow row : rowList)
		{
			System.assert(null != row.getObj(), 
				'A row from getOpenUserAccountCaseRows() returned null for its object.');
			rowsReturned.add(row.getObj().Id);
		}		
		
		for(UserAccountCaseExtension.UserAccountCaseRow row : rowMap.values())
		{
			System.assert(null != row.getObj(), 
				'A row from queryUserAccountCaseRows() returned null for its object.');
			System.assert(rowsReturned.contains(row.getObj().Id),
				'A row from queryUserAccountCaseRows() returned a User_Account_Case__c record that did not appear in the list from getOpenUserAccountCaseRows().');			
		}
	}
	
	/**
	* GetCompleteUserAccountCaseCount
	* - Output matches getCompleteUserAccountCaseRows().size()
	*/
	@isTest
	public static void testGetCompleteUserAccountCaseCount()
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
		
		Service__c theService1 = new Service__c();
		Service__c theService2 = new Service__c();
		insert new sOBject[]{theService1,theService2};
		
		Service_Role__c theRole1 = new Service_Role__c(Service__c=theService1.Id,Name=rndStr());
		Service_Role__c theRole2 = new Service_Role__c(Service__c=theService2.Id,Name=rndStr());
		Service_Profile__c theProfile1 = new Service_Profile__c(Service__c=theService1.Id,Name=rndStr());		
		Service_Profile__c theProfile2 = new Service_Profile__c(Service__c=theService2.Id,Name=rndStr());
		insert new sOBject[]{theRole1,theRole2,theProfile1,theProfile2};
				
		// Set up our User_Account__c records.		
		User_Account__c uaIncluded1 = new User_Account__c(Contact__c=theContact.Id,Service__c=theService1.Id,Service_Role__c=theRole1.Id,Service_Profile__c=theProfile1.Id);		
		User_Account__c uaIncluded2 = new User_Account__c(Contact__c=theContact.Id,Service__c=theService2.Id,Service_Role__c=theRole2.Id,Service_Profile__c=theProfile2.Id);
		User_Account__c uaOtherContact = new User_Account__c(Contact__c=otherContact.Id,Service__c=theService1.Id,Service_Role__c=theRole1.Id,Service_Profile__c=theProfile1.Id);
		insert new sOBject[]{uaIncluded1,uaIncluded2,uaOtherContact};
		
		// Create arbitrary test values for Status__c.
		String statusValue = NewHireUtil.USER_ACCOUNT_CASE_STATUS_COMPLETE;
		String otherStatusValue = rndStr();
		while(statusValue == otherStatusValue) { otherStatusValue = rndStr(); }
		
		User_Account_Case__c uacIncluded1 = new User_Account_Case__c(
			Date__c           = Date.today().addDays(7),
			Status__c         = statusValue,
			User_Account__c   = uaIncluded1.Id,
			Case__c           = theCase.Id,
			Role__c           = theRole1.Id,
			Profile__c        = theProfile1.Id,
			Service__c        = theService1.Id);
			
		User_Account_Case__c uacIncluded2= new User_Account_Case__c(
			Date__c           = Date.today().addDays(14),
			Status__c         = statusValue,
			User_Account__c   = uaIncluded2.Id,
			Case__c           = theCase.Id,
			Role__c           = theRole2.Id,
			Profile__c        = theProfile2.Id,
			Service__c        = theService2.Id);

		User_Account_Case__c uacOtherContact = uacIncluded1.clone();
			uacOtherContact.User_Account__c = uaOtherContact.Id;
		User_Account_Case__c uacOtherStatus = uacIncluded1.clone();
			uacOtherStatus.Status__c = otherStatusValue;
		User_Account_Case__c uacOtherCase = uacIncluded1.clone();
			uacOtherCase.Case__c = otherCase.Id;
		
		insert new sObject[]{
				uacIncluded1,uacIncluded2,uacOtherContact,uacOtherStatus,uacOtherCase
			};
		
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.UserAccountCase);
		UserAccountCaseExtension controller = 
			new UserAccountCaseExtension(
				new ApexPages.StandardController(theCase));
		
		Map<Id,UserAccountCaseExtension.UserAccountCaseRow>
			rowMap = controller.queryUserAccountCaseRows(statusValue);
		
		System.assert(null != rowMap, 'Returned a null set of rows.');
		System.assert(null != controller.getCompleteUserAccountCaseRows(),
			'The getCompleteUserAccountCaseRows() method returned null.');		
		System.assertEquals(
			controller.getCompleteUserAccountCaseCount(),
			controller.getCompleteUserAccountCaseRows().size(),
			'Output does not match getCompleteUserAccountCaseRows().size()');
		
	}
	
	/**
	* GetCompleteUserAccountCaseRows
	* - Output matches queryUserAccountCaseRows(NewHireUtil.USER_ACCOUNT_CASE_STATUS_COMPLETE)
	*/
	@isTest
	public static void testGetCompleteUserAccountCaseRows()
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
		
		Service__c theService1 = new Service__c();
		Service__c theService2 = new Service__c();
		insert new sOBject[]{theService1,theService2};
		
		Service_Role__c theRole1 = new Service_Role__c(Service__c=theService1.Id,Name=rndStr());
		Service_Role__c theRole2 = new Service_Role__c(Service__c=theService2.Id,Name=rndStr());
		Service_Profile__c theProfile1 = new Service_Profile__c(Service__c=theService1.Id,Name=rndStr());		
		Service_Profile__c theProfile2 = new Service_Profile__c(Service__c=theService2.Id,Name=rndStr());
		insert new sOBject[]{theRole1,theRole2,theProfile1,theProfile2};
				
		// Set up our User_Account__c records.		
		User_Account__c uaIncluded1 = new User_Account__c(Contact__c=theContact.Id,Service__c=theService1.Id,Service_Role__c=theRole1.Id,Service_Profile__c=theProfile1.Id);		
		User_Account__c uaIncluded2 = new User_Account__c(Contact__c=theContact.Id,Service__c=theService2.Id,Service_Role__c=theRole2.Id,Service_Profile__c=theProfile2.Id);
		User_Account__c uaOtherContact = new User_Account__c(Contact__c=otherContact.Id,Service__c=theService1.Id,Service_Role__c=theRole1.Id,Service_Profile__c=theProfile1.Id);
		insert new sOBject[]{uaIncluded1,uaIncluded2,uaOtherContact};
		
		// Create arbitrary test values for Status__c.
		String statusValue = NewHireUtil.USER_ACCOUNT_CASE_STATUS_COMPLETE;
		String otherStatusValue = rndStr();
		while(statusValue == otherStatusValue) { otherStatusValue = rndStr(); }
		
		User_Account_Case__c uacIncluded1 = new User_Account_Case__c(
			Date__c           = Date.today().addDays(7),
			Status__c         = statusValue,
			User_Account__c   = uaIncluded1.Id,
			Case__c           = theCase.Id,
			Role__c           = theRole1.Id,
			Profile__c        = theProfile1.Id,
			Service__c        = theService1.Id);
			
		User_Account_Case__c uacIncluded2= new User_Account_Case__c(
			Date__c           = Date.today().addDays(14),
			Status__c         = statusValue,
			User_Account__c   = uaIncluded2.Id,
			Case__c           = theCase.Id,
			Role__c           = theRole2.Id,
			Profile__c        = theProfile2.Id,
			Service__c        = theService2.Id);

		User_Account_Case__c uacOtherContact = uacIncluded1.clone();
			uacOtherContact.User_Account__c = uaOtherContact.Id;
		User_Account_Case__c uacOtherStatus = uacIncluded1.clone();
			uacOtherStatus.Status__c = otherStatusValue;
		User_Account_Case__c uacOtherCase = uacIncluded1.clone();
			uacOtherCase.Case__c = otherCase.Id;
		
		insert new sObject[]{
				uacIncluded1,uacIncluded2,uacOtherContact,uacOtherStatus,uacOtherCase
			};
		
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.UserAccountCase);
		UserAccountCaseExtension controller = 
			new UserAccountCaseExtension(
				new ApexPages.StandardController(theCase));
		
		// Query the row map, to which we will compare the
		// getCompleteUserAccountCaseRows() function's output.
		//
		Map<Id,UserAccountCaseExtension.UserAccountCaseRow>
			rowMap = controller.queryUserAccountCaseRows(statusValue);		
		System.assert(null != rowMap, 'Returned a null set of rows.');
		
		// Get the output for the function we are testing.
		//
		List<UserAccountCaseExtension.UserAccountCaseRow>
			rowList = controller.getCompleteUserAccountCaseRows();
		System.assert(null != rowList,
			'The getCompleteUserAccountCaseRows() method returned null.');
		
		// To verify the equivalence of the two lists, we verify that:
		// 1. The lists are the same size.
		// 2. Every User_Account_Case__c on one list appears on the other.		
		 
		System.assertEquals(rowMap.size(),rowList.size(), 
			'The list size did not match the size of the output from queryUserAccountCaseRows()');
		
		Set<Id> rowsReturned = new Set<id>{};
		for(UserAccountCaseExtension.UserAccountCaseRow row : rowList)
		{
			System.assert(null != row.getObj(), 
				'A row from getCompleteUserAccountCaseRows() returned null for its object.');
			rowsReturned.add(row.getObj().Id);
		}		
		
		for(UserAccountCaseExtension.UserAccountCaseRow row : rowMap.values())
		{
			System.assert(null != row.getObj(), 
				'A row from queryUserAccountCaseRows() returned null for its object.');
			System.assert(rowsReturned.contains(row.getObj().Id),
				'A row from queryUserAccountCaseRows() returned a User_Account_Case__c record that did not appear in the list from getCompleteUserAccountCaseRows().');			
		}
		
	}
	
	/**
	* QueryUserAccountCaseRows
	* - User_Account_Case__c records without the given Status are excluded.
	* - User_Account_Case__c records belonging to other Cases are excluded.
	* - User_Account_Case__c records belonging to other Contacts are not excluded.
	* - Rows are returned for all non-excluded User_Account_Case__c records.
	* - All necessary fields are queried for an included record.
	*/
	@isTest
	public static void testQueryUserAccountCaseRows()
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
		
		Service__c theService1 = new Service__c();
		Service__c theService2 = new Service__c();
		insert new sOBject[]{theService1,theService2};
		
		Service_Role__c theRole1 = new Service_Role__c(Service__c=theService1.Id,Name=rndStr());
		Service_Role__c theRole2 = new Service_Role__c(Service__c=theService2.Id,Name=rndStr());
		Service_Profile__c theProfile1 = new Service_Profile__c(Service__c=theService1.Id,Name=rndStr());		
		Service_Profile__c theProfile2 = new Service_Profile__c(Service__c=theService2.Id,Name=rndStr());
		insert new sOBject[]{theRole1,theRole2,theProfile1,theProfile2};
				
		// Set up our User_Account__c records.		
		User_Account__c uaIncluded1 = new User_Account__c(Contact__c=theContact.Id,Service__c=theService1.Id,Service_Role__c=theRole1.Id,Service_Profile__c=theProfile1.Id);		
		User_Account__c uaIncluded2 = new User_Account__c(Contact__c=theContact.Id,Service__c=theService2.Id,Service_Role__c=theRole2.Id,Service_Profile__c=theProfile2.Id);
		User_Account__c uaOtherContact = new User_Account__c(Contact__c=otherContact.Id,Service__c=theService1.Id,Service_Role__c=theRole1.Id,Service_Profile__c=theProfile1.Id);
		insert new sOBject[]{uaIncluded1,uaIncluded2,uaOtherContact};
		
		// Create arbitrary test values for Status__c.
		String statusValue = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN;
		String otherStatusValue = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN;
		while(statusValue == otherStatusValue) { otherStatusValue = rndStr(); }
		
		User_Account_Case__c uacIncluded1 = new User_Account_Case__c(
			Date__c           = Date.today().addDays(7),
			Date_Complete__c  = Date.today().addDays(21),
			Status__c         = statusValue,
			Type__c           = NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE,
			User_Account__c   = uaIncluded1.Id,
			Case__c           = theCase.Id,
			Role__c           = theRole1.Id,
			Profile__c        = theProfile1.Id,
			Service__c        = theService1.Id);
			
		User_Account_Case__c uacIncluded2= new User_Account_Case__c(
			Date__c           = Date.today().addDays(14),
			Status__c         = statusValue,
			Type__c           = NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE,
			User_Account__c   = uaIncluded2.Id,
			Case__c           = theCase.Id,
			Role__c           = theRole2.Id,
			Profile__c        = theProfile2.Id,
			Service__c        = theService2.Id);

		User_Account_Case__c uacOtherContact = uacIncluded1.clone();
			uacOtherContact.User_Account__c = uaOtherContact.Id;
		User_Account_Case__c uacOtherStatus = uacIncluded1.clone();
			uacOtherStatus.Status__c = otherStatusValue;
		User_Account_Case__c uacOtherCase = uacIncluded1.clone();
			uacOtherCase.Case__c = otherCase.Id;
		
		insert new sObject[]{
				uacIncluded1,uacIncluded2,uacOtherContact,uacOtherStatus,uacOtherCase
			};
		
		User_Account_Case__c uacBef = [
			select
				Id,
				Status_Summary__c,
				Service__c,
				Service__r.Name,
				User_Account__c,
				User_Account__r.Name,
				Detail_Summary__c,
				Date__c,
				Date_Complete__c
			from User_Account_Case__c
			where Id = :uacIncluded1.Id
		];
		
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.UserAccountCase);
		UserAccountCaseExtension controller = 
			new UserAccountCaseExtension(
				new ApexPages.StandardController(theCase));
		
		Map<Id,UserAccountCaseExtension.UserAccountCaseRow>
			rowMap = controller.queryUserAccountCaseRows(statusValue);
		
		System.assert(null != rowMap, 'Returned a null set of rows.');
		
		// Positive assertions.
		System.assert(rowMap.containsKey(uacIncluded1.Id), 
			'A relevant User_Account_Case__c record was missing a row.');			
		System.assert(rowMap.containsKey(uacIncluded2.Id), 
			'A relevant User_Account_Case__c record was missing a row.');
		System.assert(rowMap.containsKey(uacOtherContact.Id), 
			'A relevant User_Account_Case__c record was missing a row becaus it references a User_Account__c belonging to another Contact.');
		
		// Negative assertions.
		System.assert(!rowMap.containsKey(uacOtherStatus.Id), 
			'Row list included a User_Account_Case__c record with the wrong status.');
		System.assert(!rowMap.containsKey(uacOtherStatus.Id), 
			'Row list included a User_Account_Case__c record belonging to another Case.');
		
		// Data assertions.
		
		User_Account_Case__c uacAft = rowMap.get(uacIncluded1.Id).getObj();
		
		System.assert(null != uacAft, 'A row returned null for its User_Account_Case__c.');
		System.assertEquals(uacBef.Id,uacAft.Id,
			'Wrong User_Account_Case__c.Id value.');
		System.assertEquals(uacBef.Status_Summary__c,uacAft.Status_Summary__c,
			'Wrong User_Account_Case__c.Status__c value.');
		System.assertEquals(uacBef.Service__c,uacAft.Service__c,
			'Wrong User_Account_Case__c.Service__c value.');
		System.assertEquals(uacBef.Service__r.Name,uacAft.Service__r.Name,
			'Wrong User_Account_Case__c.Service__r.Name value.');
		System.assertEquals(uacBef.User_Account__c,uacAft.User_Account__c,
			'Wrong User_Account_Case__c.User_Account__c value.');
		System.assertEquals(uacBef.User_Account__r.Name,uacAft.User_Account__r.Name,
			'Wrong User_Account_Case__c.User_Account__r.Name value.');
		System.assertEquals(uacBef.Detail_Summary__c,uacAft.Detail_Summary__c,
			'Wrong User_Account_Case__c.Detail_Summary__c value.');
		System.assertEquals(uacBef.Date__c,uacAft.Date__c,
			'Wrong User_Account_Case__c.Date__c value.');
		System.assertEquals(uacBef.Date_Complete__c,uacAft.Date_Complete__c,
			'Wrong User_Account_Case__c.Date_Complete__c value.');
	}
	
	/**
	* GetUserAccountCount
	* - Output matches getUserAccountRows().size()
	*/
	@isTest
	public static void testGetUserAccountCount()
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
		
		Service__c theService = new Service__c(Name=rndStr());
		insert theService;
		
		Service_Role__c theRole = new Service_Role__c(Service__c=theService.Id,Name=rndStr());
		Service_Profile__c theProfile = new Service_Profile__c(Service__c=theService.Id,Name=rndStr());
		insert new sOBject[]{theRole,theProfile};
		
		User_Account__c uaThisContact = new User_Account__c(
				Contact__c=theContact.Id,
				Service__c=theService.Id,
				Service_Role__c = theRole.Id,
				Service_Profile__c = theProfile.Id);
		User_Account__c uaOtherContact = uaThisContact.clone();
			    uaOtherContact.Contact__c = otherContact.Id;
		
		
		insert new sOBject[]{uaThisContact,uaOtherContact};
		
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.UserAccountCase);
		UserAccountCaseExtension controller = 
			new UserAccountCaseExtension(
				new ApexPages.StandardController(theCase));
		
		// Get the output for the method we are testing.
		Map<Id,UserAccountCaseExtension.UserAccountRow>
			rowMap = controller.getUserAccountRowMap();
		
		System.assert(null != rowMap, 'The getUserAccountRows() method returned null.');
		System.assert(null != controller.getUserAccountRows(),
			'The getUserAccountRows() method returned null.');		
		System.assertEquals(controller.getUserAccountCount(),controller.getUserAccountRows().size(),
			'Output does not match getUserAccountRows().size()');
	}
	
	/**
	* GetUserAccountRows
	* - Output matches GetUserAccountRowMap.values()
	*/
	@isTest
	public static void testGetUserAccountRows()
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
		
		Service__c theService = new Service__c(Name=rndStr());
		insert theService;
		
		Service_Role__c theRole = new Service_Role__c(Service__c=theService.Id,Name=rndStr());
		Service_Profile__c theProfile = new Service_Profile__c(Service__c=theService.Id,Name=rndStr());
		insert new sOBject[]{theRole,theProfile};
		
		User_Account__c uaThisContact = new User_Account__c(
				Contact__c=theContact.Id,
				Service__c=theService.Id,
				Service_Role__c = theRole.Id,
				Service_Profile__c = theProfile.Id);
		User_Account__c uaOtherContact = uaThisContact.clone();
			    uaOtherContact.Contact__c = otherContact.Id;
		
		
		insert new sOBject[]{uaThisContact,uaOtherContact};
		
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.UserAccountCase);
		UserAccountCaseExtension controller = 
			new UserAccountCaseExtension(
				new ApexPages.StandardController(theCase));
		
		// Query the row map, to which we will compare the
		// getOpenUserAccountCaseRows() function's output.
		//
		Map<Id,UserAccountCaseExtension.UserAccountRow>
			rowMap = controller.getUserAccountRowMap();		
		System.assert(null != rowMap, 'Returned a null set of rows.');
		
		// Get the output for the function we are testing.
		//
		List<UserAccountCaseExtension.UserAccountRow>
			rowList = controller.getUserAccountRows();
		System.assert(null != rowList,
			'The getUserAccountRows() method returned null.');
		
		// To verify the equivalence of the two lists, we verify that:
		// 1. The lists are the same size.
		// 2. Every User_Account__c on one list appears on the other.	
		
		System.assertEquals(rowMap.size(),rowList.size(), 
			'The list size did not match the size of the output from getUserAccountRowMap()');
		
		Set<Id> rowsReturned = new Set<id>{};
		for(UserAccountCaseExtension.UserAccountRow row : rowList)
		{
			System.assert(null != row.getObj(), 
				'A row from getUserAccountRows() returned null for its object.');
			rowsReturned.add(row.getObj().Id);
		}		
		
		for(UserAccountCaseExtension.UserAccountRow row : rowMap.values())
		{
			System.assert(null != row.getObj(), 
				'A row from getUserAccountRowMap() returned null for its object.');
			System.assert(rowsReturned.contains(row.getObj().Id),
				'A row from getUserAccountRowMap() returned a User_Account_Case__c record that did not appear in the list from getUserAccountRows().');			
		}
				
	}
	
	/**
	* GetUserAccountRowMap
	* - A row is returned for each User_Account__c belonging to the Contact.
	* - User_Account__c records belonging to other Contacts are ignored.
	* - Each row returns a User_Account_Case__c prototype matching the output of getRequestPrototype(User_Account__c).
	* - The getCanReactivate(), getCanDeactivate(), getHasPendingReactivation(), and getHasPendingDeactivation()
	*   methods function properly on each row, ignoring records belonging to other Cases.
	* - The method has queried all necessary data for the User_Account__c record.
	*/
	@isTest
	public static void testGetUserAccountRowMap()
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
		
		Service__c theService = new Service__c(Name=rndStr());
		insert theService;
		
		Service_Role__c theRole = new Service_Role__c(Service__c=theService.Id,Name=rndStr());
		Service_Profile__c theProfile = new Service_Profile__c(Service__c=theService.Id,Name=rndStr());
		insert new sOBject[]{theRole,theProfile};
		
		// User_Account__c and User_Account_Case__c 
		// variable naming conventions:
		//
		// ua         => User_Account__c
		// uac        => User_Account_Case__c
		//
		// Active     => The User_Account__c.Active__c = true
		// Inactive   => The User_Account__c.Active__c = false
		//
		// Open       => User_Account__c has a User_Account_Case__c 
		//               with Status__c=NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN
		// Closed     => User_Account__c has a User_Account_Case__c 
		//               with Status__c=NewHireUtil.USER_ACCOUNT_CASE_STATUS_COMPLETE
		//
		// Activate   => User_Account__c has a User_Account_Case__c 
		//               with Status__c=NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE
		// Deactivate => User_Account__c has a User_Account_Case__c 
		//               with Status__c=NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE
		//
		
		// Set up our User_Account__c records, based on this prototype.
		User_Account__c uaProto = new User_Account__c(
				Contact__c=theContact.Id,
				Service__c=theService.Id,
				Service_Role__c = theRole.Id,
				Service_Profile__c = theProfile.Id);
				
		User_Account__c uaActiveOpenActivate       = uaProto.clone();
			uaActiveOpenActivate.Active__c       = true;						
		User_Account__c uaActiveOpenDeactivate     = uaProto.clone();
			uaActiveOpenDeactivate.Active__c     = true;
		User_Account__c uaActiveOpenOther          = uaProto.clone();
			uaActiveOpenOther.Active__c          = true;
		User_Account__c uaActiveClosedActivate     = uaProto.clone();
			uaActiveClosedActivate.Active__c     = true;			
		User_Account__c uaActiveClosedDeactivate   = uaProto.clone();
			uaActiveClosedDeactivate.Active__c   = true;
		User_Account__c uaActiveClosedOther        = uaProto.clone();
			uaActiveClosedOther.Active__c        = true;		
		User_Account__c uaInactiveOpenActivate     = uaProto.clone();
			uaInactiveOpenActivate.Active__c     = false;			
		User_Account__c uaInactiveOpenDeactivate   = uaProto.clone();
			uaInactiveOpenDeactivate.Active__c   = false;
		User_Account__c uaInactiveOpenOther        = uaProto.clone();
			uaInactiveOpenOther.Active__c        = false;
		User_Account__c uaInactiveClosedActivate   = uaProto.clone();
			uaInactiveClosedActivate.Active__c   = false;			
		User_Account__c uaInactiveClosedDeactivate = uaProto.clone();
			uaInactiveClosedDeactivate.Active__c = false;
		User_Account__c uaInactiveClosedOther      = uaProto.clone();
			uaInactiveClosedOther.Active__c      = false;
				
		User_Account__c uaOtherContact                 = uaProto.clone();
			uaOtherContact.Contact__c                 = otherContact.Id;
		User_Account__c uaActiveOpenDeactivateOtherCase = uaProto.clone();			
			uaActiveOpenDeactivateOtherCase.Active__c = true;
		User_Account__c uaActiveNoUac                   = uaProto.clone();
			uaActiveNoUac.Active__c                   = true;
		
		insert new sOBject[]{
			uaActiveOpenActivate,
			uaActiveOpenDeactivate,
			uaActiveOpenOther,
			uaActiveClosedActivate,
			uaActiveClosedDeactivate,
			uaActiveClosedOther,
			uaInactiveOpenActivate,
			uaInactiveOpenDeactivate,
			uaInactiveOpenOther,
			uaInactiveClosedActivate,
			uaInactiveClosedDeactivate,
			uaInactiveClosedOther,
			uaOtherContact,
			uaActiveOpenDeactivateOtherCase,
			uaActiveNoUac};
		
		// Set up our User_Account_Case__c records, based on this prototype.
		
		User_Account_Case__c uacProto = new User_Account_Case__c(
			Date__c           = Date.today().addDays(14),
			Case__c           = theCase.Id,
			Role__c           = theRole.Id,
			Profile__c        = theProfile.Id,
			Service__c        = theService.Id);
		
		User_Account_Case__c uacActiveOpenActivate       =  uacProto.clone();
			uacActiveOpenActivate.User_Account__c       = uaActiveOpenActivate.Id; 
			uacActiveOpenActivate.Status__c             = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN;
			uacActiveOpenActivate.Type__c               = NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE;
		User_Account_Case__c uacActiveOpenDeactivate     =  uacProto.clone();
			uacActiveOpenDeactivate.User_Account__c     = uaActiveOpenDeactivate.Id;
			uacActiveOpenDeactivate.Status__c           = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN;
			uacActiveOpenDeactivate.Type__c             = NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE;		
		User_Account_Case__c uacActiveOpenOther          =  uacProto.clone();
			uacActiveOpenOther.User_Account__c          = uaActiveOpenOther.Id;
			uacActiveOpenOther.Status__c                = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN;
			uacActiveOpenOther.Type__c                  = rndStr();
		User_Account_Case__c uacActiveClosedActivate     =  uacProto.clone();
			uacActiveClosedActivate.User_Account__c     = uaActiveClosedActivate.Id;
			uacActiveClosedActivate.Status__c           = NewHireUtil.USER_ACCOUNT_CASE_STATUS_COMPLETE;
			uacActiveClosedActivate.Type__c             = NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE;
		User_Account_Case__c uacActiveClosedDeactivate   =  uacProto.clone();
			uacActiveClosedDeactivate.User_Account__c   = uaActiveClosedDeactivate.Id;
			uacActiveClosedDeactivate.Status__c         = NewHireUtil.USER_ACCOUNT_CASE_STATUS_COMPLETE;
			uacActiveClosedDeactivate.Type__c           = NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE;
		User_Account_Case__c uacActiveClosedOther        =  uacProto.clone();
			uacActiveClosedOther.User_Account__c        = uaActiveClosedOther.Id;
			uacActiveClosedOther.Status__c              = NewHireUtil.USER_ACCOUNT_CASE_STATUS_COMPLETE;
			uacActiveClosedOther.Type__c                = rndStr();		
		User_Account_Case__c uacInactiveOpenActivate     =  uacProto.clone();
			uacInactiveOpenActivate.User_Account__c     = uaInactiveOpenActivate.Id;			
			uacInactiveOpenActivate.Status__c           = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN;
			uacInactiveOpenActivate.Type__c             = NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE;
		User_Account_Case__c uacInactiveOpenDeactivate   =  uacProto.clone();
			uacInactiveOpenDeactivate.User_Account__c   = uaInactiveOpenDeactivate.Id;
			uacInactiveOpenDeactivate.Status__c         = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN;
			uacInactiveOpenDeactivate.Type__c           = NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE;
		User_Account_Case__c uacInactiveOpenOther        =  uacProto.clone();
			uacInactiveOpenOther.User_Account__c        = uaInactiveOpenOther.Id;
			uacInactiveOpenOther.Status__c              = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN;
			uacInactiveOpenOther.Type__c                = rndStr();
		User_Account_Case__c uacInactiveClosedActivate   =  uacProto.clone();
			uacInactiveClosedActivate.User_Account__c   = uaInactiveClosedActivate.Id;	
			uacInactiveClosedActivate.Status__c         = NewHireUtil.USER_ACCOUNT_CASE_STATUS_COMPLETE;
			uacInactiveClosedActivate.Type__c           = NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE;		
		User_Account_Case__c uacInactiveClosedDeactivate =  uacProto.clone();
			uacInactiveClosedDeactivate.User_Account__c = uaInactiveClosedDeactivate.Id;
			uacInactiveClosedDeactivate.Status__c       = NewHireUtil.USER_ACCOUNT_CASE_STATUS_COMPLETE;
			uacInactiveClosedDeactivate.Type__c         = NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE;
		User_Account_Case__c uacInactiveClosedOther      =  uacProto.clone();
			uacInactiveClosedOther.User_Account__c      = uaInactiveClosedOther.Id;
			uacInactiveClosedOther.Status__c            = NewHireUtil.USER_ACCOUNT_CASE_STATUS_COMPLETE;
			uacInactiveClosedOther.Type__c              = rndStr();
		User_Account_Case__c uacActiveOpenDeactivateOtherCase = uacProto.clone();
			uacActiveOpenDeactivateOtherCase.User_Account__c = uaActiveOpenDeactivateOtherCase.Id;
			uacActiveOpenDeactivateOtherCase.Status__c  = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN;
			uacActiveOpenDeactivateOtherCase.Type__c    = NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE;
			uacActiveOpenDeactivateOtherCase.Case__c    = otherCase.Id;
		
		insert new sOBject[]{
			uacActiveOpenActivate,
			uacActiveOpenDeactivate,
			uacActiveOpenOther,
			uacActiveClosedActivate,
			uacActiveClosedDeactivate,
			uacActiveClosedOther,
			uacInactiveOpenActivate,
			uacInactiveOpenDeactivate,
			uacInactiveOpenOther,
			uacInactiveClosedActivate,
			uacInactiveClosedDeactivate,
			uacInactiveClosedOther,
			uacActiveOpenDeactivateOtherCase};
		
		 
		// Set up the page and its controllers.
		Test.setCurrentPage(Page.UserAccountCase);
		UserAccountCaseExtension controller = 
			new UserAccountCaseExtension(
				new ApexPages.StandardController(theCase));
		
		// Get the output for the method we are testing.
		Map<Id,UserAccountCaseExtension.UserAccountRow>
			rowMap = controller.getUserAccountRowMap();
		
		System.assert(null != rowMap, 'The getUserAccountRows() method returned null.');
		
									
		System.assert(rowMap.containsKey(uaActiveOpenActivate.Id), 
			'[Active w/OpenActivateRequest]: Output mssing a row.');
		System.assert(null != rowMap.get(uaActiveOpenActivate.Id).getObj(),
			'[Active w/OpenActivateRequest]: A row returned null for its User_Account__c.');
		System.assertEquals(uaActiveOpenActivate.Id,rowMap.get(uaActiveOpenActivate.Id).getObj().Id,
			'[Active w/OpenActivateRequest]: A row returned a User_Account__c with the wrong Id.');
		System.assertEquals(false,rowMap.get(uaActiveOpenActivate.Id).getCanReactivate(),
			'[Active w/OpenActivateRequest]: Wrong value for getCanReactivate().');
		System.assertEquals(false,rowMap.get(uaActiveOpenActivate.Id).getCanDeactivate(),
			'[Active w/OpenActivateRequest]: Wrong value for getCanDeactivate().');
		System.assertEquals(true,rowMap.get(uaActiveOpenActivate.Id).getHasPendingReactivation(),
			'[Active w/OpenActivateRequest]: Wrong value for getHasPendingReactivation().');
		System.assertEquals(false,rowMap.get(uaActiveOpenActivate.Id).getHasPendingDeactivation(),
			'[Active w/OpenActivateRequest]: Wrong value for getHasPendingDeactivation().');
				
		System.assert(rowMap.containsKey(uaActiveOpenDeactivate.Id), 
			'[Active w/ Open Deactivate Request]: Output mssing a row.');
		System.assert(null != rowMap.get(uaActiveOpenDeactivate.Id).getObj(),
			'[Active w/ Open Deactivate Request]: A row returned null for its User_Account__c.');
		System.assertEquals(uaActiveOpenDeactivate.Id,rowMap.get(uaActiveOpenDeactivate.Id).getObj().Id,
			'[Active w/ Open Deactivate Request]: A row returned a User_Account__c with the wrong Id.');
		System.assertEquals(false,rowMap.get(uaActiveOpenDeactivate.Id).getCanReactivate(),
			'[Active w/ Open Deactivate Request]: Wrong value for getCanReactivate().');
		System.assertEquals(false,rowMap.get(uaActiveOpenDeactivate.Id).getCanDeactivate(),
			'[Active w/ Open Deactivate Request]: Wrong value for getCanDeactivate().');
		System.assertEquals(false,rowMap.get(uaActiveOpenDeactivate.Id).getHasPendingReactivation(),
			'[Active w/ Open Deactivate Request]: Wrong value for getHasPendingReactivation().');
		System.assertEquals(true,rowMap.get(uaActiveOpenDeactivate.Id).getHasPendingDeactivation(),
			'[Active w/ Open Deactivate Request]: Wrong value for getHasPendingDeactivation().');
		
		System.assert(rowMap.containsKey(uaActiveOpenOther.Id), 
			'[Active w/ Open Request of unrecognized Type]: Output mssing a row.');
		System.assert(null != rowMap.get(uaActiveOpenOther.Id).getObj(),
			'[Active w/ Open Request of unrecognized Type]: A row returned null for its User_Account__c.');
		System.assertEquals(uaActiveOpenOther.Id,rowMap.get(uaActiveOpenOther.Id).getObj().Id,
			'[Active w/ Open Request of unrecognized Type]: A row returned a User_Account__c with the wrong Id.');
		System.assertEquals(false,rowMap.get(uaActiveOpenOther.Id).getCanReactivate(),
			'[Active w/ Open Request of unrecognized Type]: Wrong value for getCanReactivate().');
		System.assertEquals(false,rowMap.get(uaActiveOpenOther.Id).getCanDeactivate(),
			'[Active w/ Open Request of unrecognized Type]: Wrong value for getCanDeactivate().');
		System.assertEquals(false,rowMap.get(uaActiveOpenOther.Id).getHasPendingReactivation(),
			'[Active w/ Open Request of unrecognized Type]: Wrong value for getHasPendingReactivation().');
		System.assertEquals(false,rowMap.get(uaActiveOpenOther.Id).getHasPendingDeactivation(),
			'[Active w/ Open Request of unrecognized Type]: Wrong value for getHasPendingDeactivation().');
		
		System.assert(rowMap.containsKey(uaActiveClosedActivate.Id), 
			'[Active w/ Closed Activate Request]: Output mssing a row.');
		System.assert(null != rowMap.get(uaActiveClosedActivate.Id).getObj(),
			'[Active w/ Closed Activate Request]: A row returned null for its User_Account__c.');
		System.assertEquals(uaActiveClosedActivate.Id,rowMap.get(uaActiveClosedActivate.Id).getObj().Id,
			'[Active w/ Closed Activate Request]: A row returned a User_Account__c with the wrong Id.');
		System.assertEquals(false,rowMap.get(uaActiveClosedActivate.Id).getCanReactivate(),
			'[Active w/ Closed Activate Request]: Wrong value for getCanReactivate().');
		System.assertEquals(true,rowMap.get(uaActiveClosedActivate.Id).getCanDeactivate(),
			'[Active w/ Closed Activate Request]: Wrong value for getCanDeactivate().');
		System.assertEquals(false,rowMap.get(uaActiveClosedActivate.Id).getHasPendingReactivation(),
			'[Active w/ Closed Activate Request]: Wrong value for getHasPendingReactivation().');
		System.assertEquals(false,rowMap.get(uaActiveClosedActivate.Id).getHasPendingDeactivation(),
			'[Active w/ Closed Activate Request]: Wrong value for getHasPendingDeactivation().');
		
		System.assert(rowMap.containsKey(uaActiveClosedDeactivate.Id), 
			'[Active w/ Closed Deactivate Request]: Output mssing a row.');
		System.assert(null != rowMap.get(uaActiveClosedDeactivate.Id).getObj(),
			'[Active w/ Closed Deactivate Request]: A row returned null for its User_Account__c.');
		System.assertEquals(uaActiveClosedDeactivate.Id,rowMap.get(uaActiveClosedDeactivate.Id).getObj().Id,
			'[Active w/ Closed Deactivate Request]: A row returned a User_Account__c with the wrong Id.');
		System.assertEquals(false,rowMap.get(uaActiveClosedDeactivate.Id).getCanReactivate(),
			'[Active w/ Closed Deactivate Request]: Wrong value for getCanReactivate().');
		System.assertEquals(true,rowMap.get(uaActiveClosedDeactivate.Id).getCanDeactivate(),
			'[Active w/ Closed Deactivate Request]: Wrong value for getCanDeactivate().');
		System.assertEquals(false,rowMap.get(uaActiveClosedDeactivate.Id).getHasPendingReactivation(),
			'[Active w/ Closed Deactivate Request]: Wrong value for getHasPendingReactivation().');
		System.assertEquals(false,rowMap.get(uaActiveClosedDeactivate.Id).getHasPendingDeactivation(),
			'[Active w/ Closed Deactivate Request]: Wrong value for getHasPendingDeactivation().');
		
		System.assert(rowMap.containsKey(uaActiveClosedOther.Id), 
			'[Active w/ Closed Request of unrecognized Type]: Output mssing a row.');
		System.assert(null != rowMap.get(uaActiveClosedOther.Id).getObj(),
			'[Active w/ Closed Request of unrecognized Type]: A row returned null for its User_Account__c.');
		System.assertEquals(uaActiveClosedOther.Id,rowMap.get(uaActiveClosedOther.Id).getObj().Id,
			'[Active w/ Closed Request of unrecognized Type]: A row returned a User_Account__c with the wrong Id.');
		System.assertEquals(false,rowMap.get(uaActiveClosedOther.Id).getCanReactivate(),
			'[Active w/ Closed Request of unrecognized Type]: Wrong value for getCanReactivate().');
		System.assertEquals(true,rowMap.get(uaActiveClosedOther.Id).getCanDeactivate(),
			'[Active w/ Closed Request of unrecognized Type]: Wrong value for getCanDeactivate().');
		System.assertEquals(false,rowMap.get(uaActiveClosedOther.Id).getHasPendingReactivation(),
			'[Active w/ Closed Request of unrecognized Type]: Wrong value for getHasPendingReactivation().');
		System.assertEquals(false,rowMap.get(uaActiveClosedOther.Id).getHasPendingDeactivation(),
			'[Active w/ Closed Request of unrecognized Type]: Wrong value for getHasPendingDeactivation().');
		
		System.assert(rowMap.containsKey(uaInactiveOpenActivate.Id), 
			'[Inactive w/ Open Activate Request]: Output mssing a row.');
		System.assert(null != rowMap.get(uaInactiveOpenActivate.Id).getObj(),
			'[Inactive w/ Open Activate Request]: A row returned null for its User_Account__c.');
		System.assertEquals(uaInactiveOpenActivate.Id,rowMap.get(uaInactiveOpenActivate.Id).getObj().Id,
			'[Inactive w/ Open Activate Request]: A row returned a User_Account__c with the wrong Id.');
		System.assertEquals(false,rowMap.get(uaInactiveOpenActivate.Id).getCanReactivate(),
			'[Inactive w/ Open Activate Request]: Wrong value for getCanReactivate().');
		System.assertEquals(false,rowMap.get(uaInactiveOpenActivate.Id).getCanDeactivate(),
			'[Inactive w/ Open Activate Request]: Wrong value for getCanDeactivate().');
		System.assertEquals(true,rowMap.get(uaInactiveOpenActivate.Id).getHasPendingReactivation(),
			'[Inactive w/ Open Activate Request]: Wrong value for getHasPendingReactivation().');
		System.assertEquals(false,rowMap.get(uaInactiveOpenActivate.Id).getHasPendingDeactivation(),
			'[Inactive w/ Open Activate Request]: Wrong value for getHasPendingDeactivation().');
		
		System.assert(rowMap.containsKey(uaInactiveOpenDeactivate.Id), 
			'[Inactive w/ Open Deactivate Request]: Output mssing a row.');
		System.assert(null != rowMap.get(uaInactiveOpenDeactivate.Id).getObj(),
			'[Inactive w/ Open Deactivate Request]: A row returned null for its User_Account__c.');
		System.assertEquals(uaInactiveOpenDeactivate.Id,rowMap.get(uaInactiveOpenDeactivate.Id).getObj().Id,
			'[Inactive w/ Open Deactivate Request]: A row returned a User_Account__c with the wrong Id.');
		System.assertEquals(false,rowMap.get(uaInactiveOpenDeactivate.Id).getCanReactivate(),
			'[Inactive w/ Open Deactivate Request]: Wrong value for getCanReactivate().');
		System.assertEquals(false,rowMap.get(uaInactiveOpenDeactivate.Id).getCanDeactivate(),
			'[Inactive w/ Open Deactivate Request]: Wrong value for getCanDeactivate().');
		System.assertEquals(false,rowMap.get(uaInactiveOpenDeactivate.Id).getHasPendingReactivation(),
			'[Inactive w/ Open Deactivate Request]: Wrong value for getHasPendingReactivation().');
		System.assertEquals(true,rowMap.get(uaInactiveOpenDeactivate.Id).getHasPendingDeactivation(),
			'[Inactive w/ Open Deactivate Request]: Wrong value for getHasPendingDeactivation().');
		
		System.assert(rowMap.containsKey(uaInactiveOpenOther.Id), 
			'[Inactive w/ Open Request of unrecognized Type]: Output mssing a row.');
		System.assert(null != rowMap.get(uaInactiveOpenOther.Id).getObj(),
			'[Inactive w/ Open Request of unrecognized Type]: A row returned null for its User_Account__c.');
		System.assertEquals(uaInactiveOpenOther.Id,rowMap.get(uaInactiveOpenOther.Id).getObj().Id,
			'[Inactive w/ Open Request of unrecognized Type]: A row returned a User_Account__c with the wrong Id.');
		System.assertEquals(false,rowMap.get(uaInactiveOpenOther.Id).getCanReactivate(),
			'[Inactive w/ Open Request of unrecognized Type]: Wrong value for getCanReactivate().');
		System.assertEquals(false,rowMap.get(uaInactiveOpenOther.Id).getCanDeactivate(),
			'[Inactive w/ Open Request of unrecognized Type]: Wrong value for getCanDeactivate().');
		System.assertEquals(false,rowMap.get(uaInactiveOpenOther.Id).getHasPendingReactivation(),
			'[Inactive w/ Open Request of unrecognized Type]: Wrong value for getHasPendingReactivation().');
		System.assertEquals(false,rowMap.get(uaInactiveOpenOther.Id).getHasPendingDeactivation(),
			'[Inactive w/ Open Request of unrecognized Type]: Wrong value for getHasPendingDeactivation().');
		
		System.assert(rowMap.containsKey(uaInactiveClosedActivate.Id), 
			'[Inactive w/ Closed Activate Request]: Output mssing a row.');
		System.assert(null != rowMap.get(uaInactiveClosedActivate.Id).getObj(),
			'[Inactive w/ Closed Activate Request]: A row returned null for its User_Account__c.');
		System.assertEquals(uaInactiveClosedActivate.Id,rowMap.get(uaInactiveClosedActivate.Id).getObj().Id,
			'[Inactive w/ Closed Activate Request]: A row returned a User_Account__c with the wrong Id.');
		System.assertEquals(true,rowMap.get(uaInactiveClosedActivate.Id).getCanReactivate(),
			'[Inactive w/ Closed Activate Request]: Wrong value for getCanReactivate().');
		System.assertEquals(false,rowMap.get(uaInactiveClosedActivate.Id).getCanDeactivate(),
			'[Inactive w/ Closed Activate Request]: Wrong value for getCanDeactivate().');
		System.assertEquals(false,rowMap.get(uaInactiveClosedActivate.Id).getHasPendingReactivation(),
			'[Inactive w/ Closed Activate Request]: Wrong value for getHasPendingReactivation().');
		System.assertEquals(false,rowMap.get(uaInactiveClosedActivate.Id).getHasPendingDeactivation(),
			'[Inactive w/ Closed Activate Request]: Wrong value for getHasPendingDeactivation().');
		
		System.assert(rowMap.containsKey(uaInactiveClosedDeactivate.Id), 
			'[Inactive w/ Closed Deactivate Request]: Output mssing a row.');
		System.assert(null != rowMap.get(uaInactiveClosedDeactivate.Id).getObj(),
			'[Inactive w/ Closed Deactivate Request]: A row returned null for its User_Account__c.');
		System.assertEquals(uaInactiveClosedDeactivate.Id,rowMap.get(uaInactiveClosedDeactivate.Id).getObj().Id,
			'[Inactive w/ Closed Deactivate Request]: A row returned a User_Account__c with the wrong Id.');
		System.assertEquals(true,rowMap.get(uaInactiveClosedDeactivate.Id).getCanReactivate(),
			'[Inactive w/ Closed Deactivate Request]: Wrong value for getCanReactivate().');
		System.assertEquals(false,rowMap.get(uaInactiveClosedDeactivate.Id).getCanDeactivate(),
			'[Inactive w/ Closed Deactivate Request]: Wrong value for getCanDeactivate().');
		System.assertEquals(false,rowMap.get(uaInactiveClosedDeactivate.Id).getHasPendingReactivation(),
			'[Inactive w/ Closed Deactivate Request]: Wrong value for getHasPendingReactivation().');
		System.assertEquals(false,rowMap.get(uaInactiveClosedDeactivate.Id).getHasPendingDeactivation(),
			'[Inactive w/ Closed Deactivate Request]: Wrong value for getHasPendingDeactivation().');
		
		System.assert(rowMap.containsKey(uaInactiveClosedOther.Id), 
			'[Inactive w/ Closed Request of unrecognized Type]: Output mssing a row.');
		System.assert(null != rowMap.get(uaInactiveClosedOther.Id).getObj(),
			'[Inactive w/ Closed Request of unrecognized Type]: A row returned null for its User_Account__c.');
		System.assertEquals(uaInactiveClosedOther.Id,rowMap.get(uaInactiveClosedOther.Id).getObj().Id,
			'[Inactive w/ Closed Request of unrecognized Type]: A row returned a User_Account__c with the wrong Id.');
		System.assertEquals(true,rowMap.get(uaInactiveClosedOther.Id).getCanReactivate(),
			'[Inactive w/ Closed Request of unrecognized Type]: Wrong value for getCanReactivate().');
		System.assertEquals(false,rowMap.get(uaInactiveClosedOther.Id).getCanDeactivate(),
			'[Inactive w/ Closed Request of unrecognized Type]: Wrong value for getCanDeactivate().');
		System.assertEquals(false,rowMap.get(uaInactiveClosedOther.Id).getHasPendingReactivation(),
			'[Inactive w/ Closed Request of unrecognized Type]: Wrong value for getHasPendingReactivation().');
		System.assertEquals(false,rowMap.get(uaInactiveClosedOther.Id).getHasPendingDeactivation(),
			'[Inactive w/ Closed Request of unrecognized Type]: Wrong value for getHasPendingDeactivation().');
		
		System.assert(!rowMap.containsKey(uaOtherContact.Id), 
			'[Belongs to another Contact]: User_Account__c should not have a row but does.');
		
		System.assert(rowMap.containsKey(uaActiveOpenDeactivateOtherCase.Id), 
			'[Active w/ Open Deactivate Request under another Case]: Output mssing a row.');
		System.assert(null != rowMap.get(uaActiveOpenDeactivateOtherCase.Id).getObj(),
			'[Active w/ Open Deactivate Request under another Case]: A row returned null for its User_Account__c.');
		System.assertEquals(uaActiveOpenDeactivateOtherCase.Id,rowMap.get(uaActiveOpenDeactivateOtherCase.Id).getObj().Id,
			'[Active w/ Open Deactivate Request under another Case]: A row returned a User_Account__c with the wrong Id.');
		System.assertEquals(false,rowMap.get(uaActiveOpenDeactivateOtherCase.Id).getCanReactivate(),
			'[Active w/ Open Deactivate Request under another Case]: Wrong value for getCanReactivate().');
		System.assertEquals(true,rowMap.get(uaActiveOpenDeactivateOtherCase.Id).getCanDeactivate(),
			'[Active w/ Open Deactivate Request under another Case]: Wrong value for getCanDeactivate().');
		System.assertEquals(false,rowMap.get(uaActiveOpenDeactivateOtherCase.Id).getHasPendingReactivation(),
			'[Active w/ Open Deactivate Request under another Case]: Wrong value for getHasPendingReactivation().');
		System.assertEquals(false,rowMap.get(uaActiveOpenDeactivateOtherCase.Id).getHasPendingDeactivation(),
			'[Active w/ Open Deactivate Request under another Case]: Wrong value for getHasPendingDeactivation().');
		
		System.assert(rowMap.containsKey(uaActiveNoUac.Id), 
			'[Active w/ No Requests]: Output mssing a row.');
		System.assert(null != rowMap.get(uaActiveNoUac.Id).getObj(),
			'[Active w/ No Requests]: A row returned null for its User_Account__c.');
		System.assertEquals(uaActiveNoUac.Id,rowMap.get(uaActiveNoUac.Id).getObj().Id,
			'[Active w/ No Requests]: A row returned a User_Account__c with the wrong Id.');
		System.assertEquals(false,rowMap.get(uaActiveNoUac.Id).getCanReactivate(),
			'[Active w/ No Requests]: Wrong value for getCanReactivate().');
		System.assertEquals(true,rowMap.get(uaActiveNoUac.Id).getCanDeactivate(),
			'[Active w/ No Requests]: Wrong value for getCanDeactivate().');
		System.assertEquals(false,rowMap.get(uaActiveNoUac.Id).getHasPendingReactivation(),
			'[Active w/ No Requests]: Wrong value for getHasPendingReactivation().');
		System.assertEquals(false,rowMap.get(uaActiveNoUac.Id).getHasPendingDeactivation(),
			'[Active w/ No Requests]: Wrong value for getHasPendingDeactivation().');
		
		// Check the data on one of our User_Account__c records.
		User_Account__c uaBef = [
			select 
				Id,
				Name,
				Active__c,
				Service__c,
				Service__r.Name,
				Detail_Summary__c
			from User_Account__c
			where Id = :uaActiveOpenDeactivate.Id];
			
		User_Account__c uaAft = rowMap.get(uaBef.Id).getObj();
				
		System.assertEquals(uaBef.Id,uaAft.Id,
			'Row instance returned User_Account__c where Id was null or wrong.');
		System.assertEquals(uaBef.Name,uaAft.Name,
			'Row instance returned User_Account__c where Name was null or wrong.');
		System.assertEquals(uaBef.Active__c,uaAft.Active__c,
			'Row instance returned User_Account__c where Active__c was null or wrong.');
		System.assertEquals(uaBef.Service__c,uaAft.Service__c,
			'Row instance returned User_Account__c where Service__c was null or wrong.');
		System.assertEquals(uaBef.Service__r.Name,uaAft.Service__r.Name,
			'Row instance returned User_Account__c where Service__r.Name was null or wrong.');
		System.assertEquals(uaBef.Detail_Summary__c,uaAft.Detail_Summary__c,
			'Row instance returned User_Account__c where Detail_Summary__c was null or wrong.');
		
		// Check the output for our prototype.
		User_Account_Case__c thisProto = rowMap.get(uaAft.Id).getRequestPrototype();
		User_Account_Case__c thatProto = controller.getRequestPrototype(uaAft);
		
		System.assertEquals(thatProto,thisProto, 
			'The UserAccountCaseExtension.getRequestPrototype(UserAccount__c)'+ 
			'and UserAccountCaseExtension.UserAccountRow.getRequestPrototype() methods did not return the same record.');
		
	}
	
	/**
	* RequestActivation
	* - A User_Account_Case__c record is created for the given User_Account__c
	* - All fields on the User_Account_Case__c are properly populated.
	* - Bad editid causes failure, with a Page Message.
	* - If the User_Account__c cannot be Activated (per UserAccountRow.getCanReactivate()), 
	*   the operation fails with a page message.
	*/
	@isTest
	public static void testRequestActivation()
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
		
		Service__c theService = new Service__c(Name=rndStr());
		insert theService;
		
		Service_Role__c theRole = new Service_Role__c(Service__c=theService.Id,Name=rndStr());
		Service_Profile__c theProfile = new Service_Profile__c(Service__c=theService.Id,Name=rndStr());
		insert new sOBject[]{theRole,theProfile};
		
		// Set up our User_Account__c records, based on this prototype.
		User_Account__c uaProto = new User_Account__c(
				Contact__c=theContact.Id,
				Service__c=theService.Id,
				Service_Role__c = theRole.Id,
				Service_Profile__c = theProfile.Id);
				
		User_Account__c uaCanActivate        = uaProto.clone();
			uaCanActivate.Active__c   = false;		
		User_Account__c uaAlreadyActive      = uaProto.clone();
			uaAlreadyActive.Active__c = true;
		User_Account__c uaAlreadyPending     = uaProto.clone();
			uaAlreadyPending.Active__c      = false;
		User_Account__c uaPendingOnOtherCase = uaProto.clone();
			uaPendingOnOtherCase.Active__c      = false;		
		User_Account__c uaOtherContact       = uaProto.clone();
			uaOtherContact.Active__c         = false;
			uaOtherContact.Contact__c        = otherContact.Id;			
		User_Account__c uaDeleted            = uaProto.clone();
		
		insert new sOBject[]{
				uaCanActivate,
				uaAlreadyActive,
				uaAlreadyPending,
				uaPendingOnOtherCase,
				uaOtherContact,
				uaDeleted};

		delete uaDeleted;
		
		// Set up our User_Account_Case__c records, based on this prototype.
		
		User_Account_Case__c uacAlreadyPending = new User_Account_Case__c(
				Date__c           = Date.today().addDays(14),
				Case__c           = theCase.Id,
				Role__c           = theRole.Id,
				Profile__c        = theProfile.Id,
				Service__c        = theService.Id,
				User_Account__c   = uaAlreadyPending.Id,
				Status__c         = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN,
				Type__c           = NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE
			);
		User_Account_Case__c uacPendingOnOtherCase = uacAlreadyPending.clone();
			uacPendingOnOtherCase.Case__c = otherCase.Id;
		
		insert new sOBject[]{
				uacAlreadyPending,
				uacPendingOnOtherCase};
		
		// Check before/after counts on User_Account_Case__c records, just in 
		// case an external trigger creates some unexpectedly.
		//
		Map<Id,User_Account__c> counts = new Map<Id,User_Account__c>([
				select 
					Id,
					(select Id 
					 from User_Accounts_Cases__r
					 where Case__c = :theCase.Id)
				from User_Account__c
				where 
					Id in :new List<Id>{
						uaCanActivate.Id,
						uaAlreadyActive.Id,
						uaAlreadyPending.Id,
						uaPendingOnOtherCase.Id,
						uaOtherContact.Id,
						uaDeleted.Id
					}
			]);
		 
		// Test with no editid.
		
		Test.setCurrentPage(Page.UserAccountCase);
		UserAccountCaseExtension controller = 
			new UserAccountCaseExtension(
				new ApexPages.StandardController(theCase));
		try
		{ controller.requestActivation(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling requestActivation() with no editid caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
				'Attempted activation with no ID generated no page messages with ApexPage.Severity.ERROR.');
		
		// Test with null editid.
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
				
		ApexPages.currentPage().getParameters().put('editid',null);
		try
		{ controller.requestActivation(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling requestActivation() with null editid caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
				'Attempted activation with null editid generated no page messages with ApexPage.Severity.ERROR.');
		
		// Test with deleted editid.
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
				
		ApexPages.currentPage().getParameters().put('editid',uaDeleted.Id);
		try
		{ controller.requestActivation(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling requestActivation() with a deleted editid caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
			'Attempted activation with a deleted editid generated no page messages with ApexPage.Severity.ERROR.');
			
		// Make sure that no User_Account_Case__c was created.
		User_Account_Case__c[] uacCreated = [
			select Id
			from User_Account_Case__c
			where 
				User_Account__c = :uaDeleted.Id 
				and Case__c = :theCase.Id
			limit 1 
		];
		System.assert(uacCreated.size()==0, 
			'At least one User_Account_Case__c record was created for a User_Account__c which was deletd at the time of the request.');
	
		// Test with already active editid.
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
				
		ApexPages.currentPage().getParameters().put('editid',uaAlreadyActive.Id);
		try
		{ controller.requestActivation(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling requestActivation() with an editid for an already active User_Account__c caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
			'Attempted activation with an editid for an already active User_Account__c generated no page messages with ApexPage.Severity.ERROR.');
			
		// Make sure that no User_Account_Case__c was created.
		uacCreated = [
			select Id
			from User_Account_Case__c
			where 
				User_Account__c = :uaAlreadyActive.Id 
				and Case__c = :theCase.Id
			limit 1 
		];
		System.assert(uacCreated.size()==counts.get(uaAlreadyActive.Id).User_Accounts_Cases__r.size(), 
			'At least one User_Account_Case__c record was created for a User_Account__c which was already active at the time of the request.');
	
		
		// Test with already pending editid.
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
				
		ApexPages.currentPage().getParameters().put('editid',uaAlreadyPending.Id);
		try
		{ controller.requestActivation(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling requestActivation() with an editid for a User_Account__c with an already pending Activation request caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
			'Attempted activation with an editid for a User_Account__c with an already pending Activation request generated no page messages with ApexPage.Severity.ERROR.');
			
		// Make sure that no User_Account_Case__c was created.
		uacCreated = [
			select Id
			from User_Account_Case__c
			where 
				User_Account__c = :uaAlreadyPending.Id 
				and Case__c = :theCase.Id
		];
		System.assert(uacCreated.size()==counts.get(uaAlreadyPending.Id).User_Accounts_Cases__r.size(), 
			'At least one User_Account_Case__c record was created for a User_Account__c with an already pending Activation request at the time of the request.');
		
		
		// Test with a User_Account__c belonging to another Contact.
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
				
		ApexPages.currentPage().getParameters().put('editid',uaOtherContact.Id);
		try
		{ controller.requestActivation(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling requestActivation() with an editid for a User_Account__c belonging to another contact caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
			'Attempted activation with an editid for a User_Account__c belonging to another contact generated no page messages with ApexPage.Severity.ERROR.');
			
		// Make sure that no User_Account_Case__c was created.
		uacCreated = [
			select Id
			from User_Account_Case__c
			where 
				User_Account__c = :uaOtherContact.Id 
				and Case__c = :theCase.Id
		];
		System.assert(uacCreated.size()==counts.get(uaOtherContact.Id).User_Accounts_Cases__r.size(), 
			'At least one User_Account_Case__c record was created for a User_Account__c belonging to another contact at the time of the request.');
		
		
		// Test a basic success case (an inactive User_Account__c with no pending User_Account_Case__c)
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
		
		// Add some user input.
		//
		User_Account_Case__c proto = controller.getRequestPrototype(uaCanActivate);
		proto.Date__c = Date.today().addDays(60);
		proto.Notes__c = rndStr();
				
		ApexPages.currentPage().getParameters().put('editid',uaCanActivate.Id);
		controller.requestActivation();
		
		// Make sure a User_Account_Case__c was created.
		
		User_Account_Case__c[] uacLst = [
			select 
				Id,
				Date__c,
				Status__c,
				Employee__c,
				User_Account__c,
				Role__c,
				Profile__c,
				Service__c,
				Notes__c
			from User_Account_Case__c
			where User_Account__c = :uaCanActivate.Id
			  and Case__c = :theCase.Id
			  and Type__c = :NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE
		];
		System.assertEquals(1,uacLst.size(),'Wrong number of Activate Requests found for the given User_Account__c and Case__c.');
		
		User_Account_Case__c uac = uacLst[0];
		
		// Check the data in the request.
		System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN, uac.Status__c,
			'New User_Account_Case__c has wrong value for Status__c.');
		System.assertEquals(theCase.prEmployee__c,uac.Employee__c,
			'New User_Account_Case__c.Employee__c does not match Case.prEmployee__c.');
		System.assertEquals(uaCanActivate.Id,uac.User_Account__c,
			'New User_Account_Case__c.User_Account__c does not match the given Id.');
		System.assertEquals(uaCanActivate.Service_Role__c,uac.Role__c,
			'New User_Account_Case__c.Role__c does not match User_Account__c.Service_Role__c.');
		System.assertEquals(uaCanActivate.Service_Profile__c,uac.Profile__c,
			'New User_Account_Case__c.Profile__c does not match User_Account__c.Profile__c.');
		System.assertEquals(uaCanActivate.Service__c,uac.Service__c,
			'New User_Account_Case__c.Service__c does not match User_Account__c.Service__c.');
		System.assertEquals(proto.Date__c,uac.Date__c,
			'New User_Account_Case__c.Date__c does not match the user\'s input.');
		System.assertEquals(proto.Notes__c,uac.Notes__c,
			'New User_Account_Case__c.Notes__c does not match the user\'s input.');
		
		
		// Test an inactive User_Account__c whose one pending User_Account_Case__c belongs to another Case.
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
		
		// Add some user input.
		//
		proto = controller.getRequestPrototype(uaPendingOnOtherCase);
		// Don't set the Date__c: should default to Case.Due_Date__c
		proto.Notes__c = rndStr();
				
		ApexPages.currentPage().getParameters().put('editid',uaPendingOnOtherCase.Id);
		controller.requestActivation();
		
		// Make sure a User_Account_Case__c was created.
		
		uacLst = [
			select 
				Id,
				Date__c,
				Status__c,
				Employee__c,
				User_Account__c,
				Role__c,
				Profile__c,
				Service__c,
				Notes__c
			from User_Account_Case__c
			where User_Account__c = :uaPendingOnOtherCase.Id
			  and Case__c = :theCase.Id
			  and Type__c = :NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE
		];
		System.assertEquals(1,uacLst.size(),'Wrong number of Activate Requests found for the given User_Account__c and Case__c.');
		
		uac = uacLst[0];
		
		// Check the data in the request.
		System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN, uac.Status__c,
			'New User_Account_Case__c has wrong value for Status__c.');
		System.assertEquals(theCase.prEmployee__c,uac.Employee__c,
			'New User_Account_Case__c.Employee__c does not match Case.prEmployee__c.');
		System.assertEquals(uaPendingOnOtherCase.Id,uac.User_Account__c,
			'New User_Account_Case__c.User_Account__c does not match the given Id.');
		System.assertEquals(uaPendingOnOtherCase.Service_Role__c,uac.Role__c,
			'New User_Account_Case__c.Role__c does not match User_Account__c.Service_Role__c.');
		System.assertEquals(uaPendingOnOtherCase.Service_Profile__c,uac.Profile__c,
			'New User_Account_Case__c.Profile__c does not match User_Account__c.Profile__c.');
		System.assertEquals(uaPendingOnOtherCase.Service__c,uac.Service__c,
			'New User_Account_Case__c.Service__c does not match User_Account__c.Service__c.');
		System.assertEquals(theCase.Due_Date__c,uac.Date__c,
			'New User_Account_Case__c.Date__c did not default to Case.Due_Date__c when no value was given.');
		System.assertEquals(proto.Notes__c,uac.Notes__c,
			'New User_Account_Case__c.Notes__c does not match the user\'s input.');
					
	}
	
	/**
	* RequestDeactivation
	* - A User_Account_Case__c record is created for the given User_Account__c
	* - All fields on the User_Account_Case__c are properly populated.
	* - Bad editid causes failure, with a Page Message.
	* - If the User_Account__c cannot be Deactivated (per UserAccountRow.getCanDeactivate()), 
	*   the operation fails with a page message. 
	*/
	@isTest
	public static void testRequestDeactivation()
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
		
		Service__c theService = new Service__c(Name=rndStr());
		insert theService;
		
		Service_Role__c theRole = new Service_Role__c(Service__c=theService.Id,Name=rndStr());
		Service_Profile__c theProfile = new Service_Profile__c(Service__c=theService.Id,Name=rndStr());
		insert new sOBject[]{theRole,theProfile};
		
		// Set up our User_Account__c records, based on this prototype.
		User_Account__c uaProto = new User_Account__c(
				Contact__c=theContact.Id,
				Service__c=theService.Id,
				Service_Role__c = theRole.Id,
				Service_Profile__c = theProfile.Id);
				
		User_Account__c uaCanDeactivate      = uaProto.clone();
			uaCanDeactivate.Active__c        = true;		
		User_Account__c uaAlreadyInactive    = uaProto.clone();
			uaAlreadyInactive.Active__c      = false;
		User_Account__c uaAlreadyPending     = uaProto.clone();
			uaAlreadyPending.Active__c       = true;
		User_Account__c uaPendingOnOtherCase = uaProto.clone();
			uaPendingOnOtherCase.Active__c   = true;		
		User_Account__c uaOtherContact       = uaProto.clone();
			uaOtherContact.Active__c         = true;
			uaOtherContact.Contact__c        = otherContact.Id;			
		User_Account__c uaDeleted            = uaProto.clone();
		
		insert new sOBject[]{
				uaCanDeactivate,
				uaAlreadyInactive,
				uaAlreadyPending,
				uaPendingOnOtherCase,
				uaOtherContact,
				uaDeleted};

		delete uaDeleted;
		
		// Set up our User_Account_Case__c records, based on this prototype.
		
		User_Account_Case__c uacAlreadyPending = new User_Account_Case__c(
				Date__c           = Date.today().addDays(14),
				Case__c           = theCase.Id,
				Role__c           = theRole.Id,
				Profile__c        = theProfile.Id,
				Service__c        = theService.Id,
				User_Account__c   = uaAlreadyPending.Id,
				Status__c         = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN,
				Type__c           = NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE
			);
		User_Account_Case__c uacPendingOnOtherCase = uacAlreadyPending.clone();
			uacPendingOnOtherCase.Case__c = otherCase.Id;
		
		insert new sOBject[]{
				uacAlreadyPending,
				uacPendingOnOtherCase};
		
		// Check before/after counts on User_Account_Case__c records, just in 
		// case an external trigger creates some unexpectedly.
		//
		Map<Id,User_Account__c> counts = new Map<Id,User_Account__c>([
				select 
					Id,
					(select Id 
					 from User_Accounts_Cases__r
					 where Case__c = :theCase.Id)
				from User_Account__c
				where 
					Id in :new List<Id>{
						uaCanDeactivate.Id,
						uaAlreadyInactive.Id,
						uaAlreadyPending.Id,
						uaPendingOnOtherCase.Id,
						uaOtherContact.Id,
						uaDeleted.Id
					}
			]);
		 
		// Test with no editid.
		
		Test.setCurrentPage(Page.UserAccountCase);
		UserAccountCaseExtension controller = 
			new UserAccountCaseExtension(
				new ApexPages.StandardController(theCase));
		try
		{ controller.requestDeactivation(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling requestDeactivation() with no editid caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
				'Attempted deactivation with no ID generated no page messages with ApexPage.Severity.ERROR.');
		
		// Test with null editid.
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
				
		ApexPages.currentPage().getParameters().put('editid',null);
		try
		{ controller.requestDeactivation(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling requestDeactivation() with null editid caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
				'Attempted deactivation with null editid generated no page messages with ApexPage.Severity.ERROR.');
		
		// Test with deleted editid.
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
				
		ApexPages.currentPage().getParameters().put('editid',uaDeleted.Id);
		try
		{ controller.requestDeactivation(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling requestDeactivation() with a deleted editid caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
			'Attempted deactivation with a deleted editid generated no page messages with ApexPage.Severity.ERROR.');
			
		// Make sure that no User_Account_Case__c was created.
		User_Account_Case__c[] uacCreated = [
			select Id
			from User_Account_Case__c
			where 
				User_Account__c = :uaDeleted.Id 
				and Case__c = :theCase.Id
			limit 1 
		];
		System.assert(uacCreated.size()==0, 
			'At least one User_Account_Case__c record was created for a User_Account__c which was deletd at the time of the request.');
	
		// Test with already active editid.
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
				
		ApexPages.currentPage().getParameters().put('editid',uaAlreadyInactive.Id);
		try
		{ controller.requestDeactivation(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling requestDeactivation() with an editid for an already active User_Account__c caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
			'Attempted deactivation with an editid for an already active User_Account__c generated no page messages with ApexPage.Severity.ERROR.');
			
		// Make sure that no User_Account_Case__c was created.
		uacCreated = [
			select Id
			from User_Account_Case__c
			where 
				User_Account__c = :uaAlreadyInactive.Id 
				and Case__c = :theCase.Id
			limit 1 
		];
		System.assert(uacCreated.size()==counts.get(uaAlreadyInactive.Id).User_Accounts_Cases__r.size(), 
			'At least one User_Account_Case__c record was created for a User_Account__c which was already active at the time of the request.');
	
		
		// Test with already pending editid.
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
				
		ApexPages.currentPage().getParameters().put('editid',uaAlreadyPending.Id);
		try
		{ controller.requestDeactivation(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling requestDeactivation() with an editid for a User_Account__c with an already pending Activation request caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
			'Attempted deactivation with an editid for a User_Account__c with an already pending Activation request generated no page messages with ApexPage.Severity.ERROR.');
			
		// Make sure that no User_Account_Case__c was created.
		uacCreated = [
			select Id
			from User_Account_Case__c
			where 
				User_Account__c = :uaAlreadyPending.Id 
				and Case__c = :theCase.Id
		];
		System.assert(uacCreated.size()==counts.get(uaAlreadyPending.Id).User_Accounts_Cases__r.size(), 
			'At least one User_Account_Case__c record was created for a User_Account__c with an already pending Activation request at the time of the request.');
		
		
		// Test with a User_Account__c belonging to another Contact.
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
				
		ApexPages.currentPage().getParameters().put('editid',uaOtherContact.Id);
		try
		{ controller.requestDeactivation(); } 
		catch(Exception e)
		{
			System.assert(false, 
			'Calling requestDeactivation() with an editid for a User_Account__c belonging to another contact caused an uncaught exception instead of a page message: '
			+e.getStackTraceString());
		}
		
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
			'Attempted deactivation with an editid for a User_Account__c belonging to another contact generated no page messages with ApexPage.Severity.ERROR.');
			
		// Make sure that no User_Account_Case__c was created.
		uacCreated = [
			select Id
			from User_Account_Case__c
			where 
				User_Account__c = :uaOtherContact.Id 
				and Case__c = :theCase.Id
		];
		System.assert(uacCreated.size()==counts.get(uaOtherContact.Id).User_Accounts_Cases__r.size(), 
			'At least one User_Account_Case__c record was created for a User_Account__c belonging to another contact at the time of the request.');
		
		
		// Test a basic success case (an inactive User_Account__c with no pending User_Account_Case__c)
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
		
		// Add some user input.
		//
		User_Account_Case__c proto = controller.getRequestPrototype(uaCanDeactivate);
		proto.Date__c = Date.today().addDays(60);
		proto.Notes__c = rndStr();
				
		ApexPages.currentPage().getParameters().put('editid',uaCanDeactivate.Id);
		controller.requestDeactivation();
		
		// Make sure a User_Account_Case__c was created.
		
		User_Account_Case__c[] uacLst = [
			select 
				Id,
				Date__c,
				Status__c,
				Employee__c,
				User_Account__c,
				Role__c,
				Profile__c,
				Service__c,
				Notes__c
			from User_Account_Case__c
			where User_Account__c = :uaCanDeactivate.Id
			  and Case__c = :theCase.Id
			  and Type__c = :NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE
		];
		System.assertEquals(1,uacLst.size(),'Wrong number of Deactivate Requests found for the given User_Account__c and Case__c.');
		
		User_Account_Case__c uac = uacLst[0];
		
		// Check the data in the request.
		System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN, uac.Status__c,
			'New User_Account_Case__c has wrong value for Status__c.');
		System.assertEquals(theCase.prEmployee__c,uac.Employee__c,
			'New User_Account_Case__c.Employee__c does not match Case.prEmployee__c.');
		System.assertEquals(uaCanDeactivate.Id,uac.User_Account__c,
			'New User_Account_Case__c.User_Account__c does not match the given Id.');
		System.assertEquals(uaCanDeactivate.Service_Role__c,uac.Role__c,
			'New User_Account_Case__c.Role__c does not match User_Account__c.Service_Role__c.');
		System.assertEquals(uaCanDeactivate.Service_Profile__c,uac.Profile__c,
			'New User_Account_Case__c.Profile__c does not match User_Account__c.Profile__c.');
		System.assertEquals(uaCanDeactivate.Service__c,uac.Service__c,
			'New User_Account_Case__c.Service__c does not match User_Account__c.Service__c.');
		System.assertEquals(proto.Date__c,uac.Date__c,
			'New User_Account_Case__c.Date__c does not match the user\'s input.');
		System.assertEquals(proto.Notes__c,uac.Notes__c,
			'New User_Account_Case__c.Notes__c does not match the user\'s input.');
		
		
		// Test an inactive User_Account__c whose one pending User_Account_Case__c belongs to another Case.
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
		
		// Add some user input.
		//
		proto = controller.getRequestPrototype(uaPendingOnOtherCase);
		// Don't set the Date__c: should default to Case.Due_Date__c
		proto.Notes__c = rndStr();
				
		ApexPages.currentPage().getParameters().put('editid',uaPendingOnOtherCase.Id);
		controller.requestDeactivation();
		
		// Make sure a User_Account_Case__c was created.
		
		uacLst = [
			select 
				Id,
				Date__c,
				Status__c,
				Employee__c,
				User_Account__c,
				Role__c,
				Profile__c,
				Service__c,
				Notes__c
			from User_Account_Case__c
			where User_Account__c = :uaPendingOnOtherCase.Id
			  and Case__c = :theCase.Id
			  and Type__c = :NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE
		];
		System.assertEquals(1,uacLst.size(),'Wrong number of Deactivate Requests found for the given User_Account__c and Case__c.');
		
		uac = uacLst[0];
		
		// Check the data in the request.
		System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN, uac.Status__c,
			'New User_Account_Case__c has wrong value for Status__c.');
		System.assertEquals(theCase.prEmployee__c,uac.Employee__c,
			'New User_Account_Case__c.Employee__c does not match Case.prEmployee__c.');
		System.assertEquals(uaPendingOnOtherCase.Id,uac.User_Account__c,
			'New User_Account_Case__c.User_Account__c does not match the given Id.');
		System.assertEquals(uaPendingOnOtherCase.Service_Role__c,uac.Role__c,
			'New User_Account_Case__c.Role__c does not match User_Account__c.Service_Role__c.');
		System.assertEquals(uaPendingOnOtherCase.Service_Profile__c,uac.Profile__c,
			'New User_Account_Case__c.Profile__c does not match User_Account__c.Profile__c.');
		System.assertEquals(uaPendingOnOtherCase.Service__c,uac.Service__c,
			'New User_Account_Case__c.Service__c does not match User_Account__c.Service__c.');
		System.assertEquals(theCase.Due_Date__c,uac.Date__c,
			'New User_Account_Case__c.Date__c did not default to Case.Due_Date__c when no value was given.');
		System.assertEquals(proto.Notes__c,uac.Notes__c,
			'New User_Account_Case__c.Notes__c does not match the user\'s input.');
		
	}
	
	/**
	* CancelRequest
	* - If the User_Account_Case__c cannot be Canceled (per UserAccountCaseRow.getCanCancel()),
	*   the operation fails with a page message.
	* - The User_Account_Case__c record with the given ID has its status changed to 
	*   NewHireUtil.USER_ACCOUNT_CASE_STATUS_CANCEL
	* - All fields on the User_Account_Case__c are properly populated.
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
		
		Service__c theService = new Service__c(Name=rndStr());
		insert theService;
		
		Service_Role__c theRole = new Service_Role__c(Service__c=theService.Id,Name=rndStr());
		Service_Profile__c theProfile = new Service_Profile__c(Service__c=theService.Id,Name=rndStr());
		insert new sOBject[]{theRole,theProfile};
		
		// Set up our User_Account__c records, based on this prototype.
		User_Account__c theUserAccount = new User_Account__c(
				Contact__c=theContact.Id,
				Service__c=theService.Id,
				Service_Role__c = theRole.Id,
				Service_Profile__c = theProfile.Id,
				Active__c = true);
		
		insert theUserAccount;
		
		// Set up our User_Account_Case__c records, based on this prototype.
		
		User_Account_Case__c uacCanCancel = new User_Account_Case__c(
				Date__c           = Date.today().addDays(14),
				Case__c           = theCase.Id,
				Role__c           = theRole.Id,
				Profile__c        = theProfile.Id,
				Service__c        = theService.Id,
				User_Account__c   = theUserAccount.Id,
				Status__c         = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN,
				Type__c           = NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE
			);
		User_Account_Case__c uacBadStatus = uacCanCancel.clone();
			uacBadStatus.Status__c = rndStr();
		User_Account_Case__c uacBadType = uacCanCancel.clone();
			uacBadType.Type__c     = rndStr();
		User_Account_Case__c uacDeleted = uacCanCancel.clone();
			
		insert new sObject[]{uacCanCancel,uacDeleted,uacBadStatus,uacBadType};		
		delete uacDeleted;
						
		// Test with no editid.
		
		Test.setCurrentPage(Page.UserAccountCase);
		UserAccountCaseExtension controller = 
			new UserAccountCaseExtension(
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
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
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
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
		ApexPages.currentPage().getParameters().put('editid',uacDeleted.Id);
		
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
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
		ApexPages.currentPage().getParameters().put('editid',uacBadStatus.Id);
		
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
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
		ApexPages.currentPage().getParameters().put('editid',uacBadType.Id);
		
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
		
		Test.setCurrentPage(Page.UserAccountCase);
		controller = new UserAccountCaseExtension(new ApexPages.StandardController(theCase));
				
		ApexPages.currentPage().getParameters().put('editid',uacCanCancel.Id);
		controller.cancelRequest();
		
		User_Account_Case__c theReq = [
			select
				Id,
				Status__c
			from User_Account_Case__c
			where Id = :uacCanCancel.Id
		];
		
		System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_STATUS_CANCEL, theReq.Status__c,
			'The Status__c did not change after cancelRequest() was called.');
		
	}
	
	
	/**
	* RequestUserAccount
	* - The returned PageReference points to the AddService page.
	* - The returned PageReference has an Id parameter with the ID of the Case.
	* - The returned PageReference has getRedirect()==true.
	*/
	@isTest
	public static void testRequestUserAccount()
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
		
		
		Test.setCurrentPage(Page.UserAccountCase);
		UserAccountCaseExtension controller = 
			new UserAccountCaseExtension(
				new ApexPages.StandardController(theCase));
		
		PageReference nextPage = controller.requestUserAccount();
		
		String url = nextPage.getUrl();			
		System.assert(null != url, 'Next page URL is null.');
		
		// Normalize the URLs so we can compare them.
		String expectedUrl = Page.AddService.getUrl().replaceAll('\\\\','/').toLowercase();
		url = url.replaceall('\\\\','/').toLowercase().split('[?]')[0];
		
		System.assertEquals(expectedUrl,url,'Wrong URL for next page.');
		
		System.assert(nextPage.getParameters().containsKey('id'),
		'The next page URL does not include an ID parameter.');
		System.assertEquals(theCase.Id,nextPage.getParameters().get('id'),
		'The the ID parameter in the next page URL does not contain the current Case\'s ID.');
		System.assertEquals(true,nextPage.getRedirect(),'Wrong value for nextPage.getRedirect().');
	}
	
	/**
	* MakeActivationChangeRequest
	* Method is covered extensively by RequestDeactivation and RequestActivation
	*/ 
	/*@isTest
	public static void testMakeActivationChangeRequest()
	{
		
	}*/
	
}