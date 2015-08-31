/**
 * Unit Tests for CaseAutocreateContact.trigger
 *
 * Overview
 * ---------
 * The CaseAutocreateContact trigger operates upon insertion of
 * a Case into the database. Testing this involves the following 
 * steps:
 *
 * 1. Define the Case record(s) to be inserted and the conditions
 *    under which it will be inserted.
 * 2. Set up any background data or related records necessary 
 *    for the test.
 * 3. Insert the Case(s).
 * 4. Query all the data needed to make the necessary assertions.
 * 5. Make assertions on the queried data.
 *
 * This class uses the following inner classes to automate the above:
 * 
 * TestCase:
 * Contains all of the information necessary for Step 1.
 * This in cludes the Case itself, variables defining the test conditions,
 * and the TestSetup (see below).
 *
 * TestSetup:
 * Contains all of the information necessary for Step 2.
 * This includes any records related to the Case and any other
 * records which affect the trigger's behvior toward the inserted 
 * Case. 
 *
 * The information in the TestSetup may depend on the conditions of 
 * the Test. For example, if an email address on the Case should match 
 * a Contact already in the database, the TestSetup will contain the 
 * Contact record to be inserted.
 *
 * TestResult:
 * Contains all information necessary for Step 5. This includes the
 * original TestCase, the Database.SaveResults for the insert, and
 * any other data that was queried after the insertion was run.
 *
 * Usage
 * ------
 * To use this framework, do the following:
 *
 * 1. Instantiate a TestCase or list of TestCases.
 *
 * 2. Call setup() on the TestCase(s). This inserts a full set of 
 *    unique records for each TestCase.
 *
 * 3. Call runTests() on the TestCase(s) to get a TestResult list.
 *
 * 4. Call one or more assert*() methods on each TestResult.
 *    Each assert*() method accepts a context string, which will be 
 *    appended to the front of any message generated when an assertion 
 *    fails. This should be used to specify information that would not 
 *    be clear from the standard test output.
 *
 * Input Conditions
 * ----------------
 * A TestCase is defined by providing some combination of the following 
 * variables:
 *
 * RecordType: 
 * The RecordType for the Case to be inserted.
 *
 * EmployeeValue: 
 * How the Case.prEmployee__c field relates to the Database.
 * Can be one of: 
 * - NULL (Case.prEmployee__c = null)
 * - EXISTS (prEmployee__c points to a Contact in the database.)
 * - DELETED (prEmployee__c points to a deleted Contact)
 *
 * EmailValue:
 * How the Case.prPersonal_Email__c field relates to the 
 * Database.
 * Can be one of:
 * - NULL (value is null)
 * - BLANK (value is the empty string '')
 * - UNIQUE (email does not match the prPersonal_Email__c of any Contact 
 *   in the Database)
 * - NON_UNIQUE (email matches the prPersonal_Email__c of a 
 *   Contact in the Database)
 *
 * Assertions
 * -----------
 * The set of assertions used depends on the
 * RecordType of the inserted Case. 
 * 
 * The following assertion methods are available:
 *
 * assertUpdateRules()
 * - Assert all conditions resulting from the input being an Update Case
 * 
 * assertDropRules()
 * - Assert all conditions resulting from the input being a Drop Case
 *
 * assertSuspensionRules()
 * - Assert all conditions resulting from the input being a Suspension Case
 *
 * assertReactivationCaseRules()
 * - Assert all conditions resulting from the automatic creation
 *   of an additional Case to handle the future Reactivation of a temporarily 
 *   suspended employee.
 *
 * assertAutoCreatedContactRules()
 * - Assert the all conditions resulting from the automatic creation of 
 *   a new contact related to the inserted Case. 
 * 
 * assertNothingChanged()
 * - Assert all conditions resulting from the input Case being ignored, perhaps 
 *   due to an irrelevant RecordType or unworkable data configuration. 
 *   Confirms that fields related to this trigger did not change.
 *
 * Other assert methods are helpers, called from within 
 * the above methods.
 *
 */
@isTest
private class CaseAutocreateContactTrigTest {
	
	// Default number of User_Account__c records per test Contact.
	// User_Account__c.Active__c value will alternate between true 
	// and false as records are created.
	public static final Integer DEFAULT_NUM_USER_ACCOUNTS = 2*NewHireUtil.USER_ACCOUNT_TO_USER_ACCOUNT_CASE_RECORD_TYPE.size();
	
	// Default number of Asset__c records per Contact. 
	public static final Integer DEFAULT_NUM_ASSETS = 2;
	
	// A string appended to various record names/values 
	// to distinguish them from any org data.
	//
	public static final String TEST_CLASS_ID = 'CACTrigTest';
	
	
	// Describes how Case.prEmployee__c will be populated
	// for a TestCase 
	public enum EmployeeValue {
		EMPLOYEE_NULL,
		EMPLOYEE_EXISTS,
		EMPLOYEE_DELETED
	}
	
	// Describes how Case.prPersonal_Email__c will be populated
	// for a TestCase
	public enum EmailValue {
		EMAIL_NULL,
		EMAIL_BLANK,
		EMAIL_NON_UNIQUE,
		EMAIL_UNIQUE
	}
	
	@isTest
	public static void testAddNewContact()
	{
		TestCase testCase = new TestCase(
			'ADD_NEWCONTACT',
			NewHireUtil.RECORDTYPE_PROVISIONING_ADD,
			EmployeeValue.EMPLOYEE_NULL,
			EmailValue.EMAIL_UNIQUE
		);
		setup(testCase);
		TestResult result = runTest(testCase);
		
		String error = result.saveResult.isSuccess()?'':result.saveResult.getErrors()[0].getMessage();
		System.assert(result.saveResult.isSuccess(), 'The DML operation failed. First error was: '+error);
		
		assertAutoCreatedContactRules('[single-record insert]',result);
	}

	@isTest
	public static void testAddNewContactContractor()
	{
		TestCase testCase = new TestCase(
			'ADD_NEWCONTACT_CONTRACTOR',
			NewHireUtil.RECORDTYPE_PROVISIONING_ADD,
			EmployeeValue.EMPLOYEE_NULL,
			EmailValue.EMAIL_UNIQUE
		);
		testCase.theCase.Employee_Type__c = NewHireUtil.CASE_EMPLOYEE_TYPE_CONTRACTOR;
		setup(testCase);
		TestResult result = runTest(testCase);
		
		String error = result.saveResult.isSuccess()?'':result.saveResult.getErrors()[0].getMessage();
		System.assert(result.saveResult.isSuccess(), 'The DML operation failed. First error was: '+error);
		
		assertAutoCreatedContactRules('[single-record-contractor-insert]',result);
	}

	@isTest
	public static void testAddNewContactThenChangeEmployeeType()
	{
		// The Default Case.Employee_Type__c is NewHirUtil.CASE_EMPLOYEE_TYPE_EMPLOYEE
		//
		TestCase testCase = new TestCase(
			'ADD_NEWCONTACT',
			NewHireUtil.RECORDTYPE_PROVISIONING_ADD,
			EmployeeValue.EMPLOYEE_NULL,
			EmailValue.EMAIL_UNIQUE
		);
		setup(testCase);
		TestResult result = runTest(testCase);
		
		String error = result.saveResult.isSuccess()?'':result.saveResult.getErrors()[0].getMessage();
		System.assert(result.saveResult.isSuccess(), 'The DML operation failed. First error was: '+error);
		
		// These assertions will make sure that the proper Account (the one for an "employee") is 
		// applied upon insertion.
		//
		assertAutoCreatedContactRules('[single-record insert]',result);

		Case theCase = result.theCase;
		
		// Change the Case.Employee_Type__c from "employee" to "contactor"
		theCase.Employee_Type__c = NewHireutil.CASE_EMPLOYEE_TYPE_CONTRACTOR;

		// Update the Case
		update theCase;

		// Query the Contact
		Contact theContact = [select Id, AccountId from Contact where Id = :theCase.prEmployee__c];

		// Make sure the proper AccountId is assigned.
		Id correctAccountId = NewHireutil.getAccountIdForNewContact(theCase);
		System.assertEquals(
			correctAccountId, theContact.AccountId, 
			'[single-record-insert-then-update] Wrong Case.AccountId after Case update.');

	}
	
	@isTest
	public static void testAddOldContact()
	{
		TestCase testCase = new TestCase(
			'ADD_OLDCONTACT',
			NewHireUtil.RECORDTYPE_PROVISIONING_ADD,
			EmployeeValue.EMPLOYEE_EXISTS,
			EmailValue.EMAIL_NULL
		);
		setup(testCase);
		TestResult result = runTest(testCase);
		
		String error = result.saveResult.isSuccess()?'':result.saveResult.getErrors()[0].getMessage();
		System.assert(result.saveResult.isSuccess(), 'The DML operation failed. First error was: '+error);
		
		assertNothingChanged('[single-record insert]',result);
	}
	
	@isTest
	public static void testDropNewContact()
	{
		TestCase testCase = new TestCase(
			'DROP_NEWCONTACT',
			NewHireUtil.RECORDTYPE_PROVISIONING_DROP,
			EmployeeValue.EMPLOYEE_NULL,
			EmailValue.EMAIL_UNIQUE
		);
		setup(testCase);
		TestResult result = runTest(testCase);
		
		String error = result.saveResult.isSuccess()?'':result.saveResult.getErrors()[0].getMessage();
		System.assert(result.saveResult.isSuccess(), 'The DML operation failed. First error was: '+error);
		
		assertNothingChanged('[single-record insert]',result);
	}
	
	@isTest
	public static void testDropOldContact()
	{
		TestCase testCase = new TestCase(
			'DROP_OLDCONTACT',
			NewHireUtil.RECORDTYPE_PROVISIONING_DROP,
			EmployeeValue.EMPLOYEE_EXISTS,
			EmailValue.EMAIL_NULL
		);
		
		setup(testCase);
		TestResult result = runTest(testCase);
		
		String error = result.saveResult.isSuccess()?'':result.saveResult.getErrors()[0].getMessage();
		System.assert(result.saveResult.isSuccess(), 'The DML operation failed. First error was: '+error);
		
		assertDropRules('[single-record insert]',result);
	}
	
	@isTest
	public static void testUpdateNewContact()
	{
		TestCase testCase = new TestCase(
			'UPDATE_NEWCONTACT',
			NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
			EmployeeValue.EMPLOYEE_NULL,
			EmailValue.EMAIL_UNIQUE
		);
		setup(testCase);
		TestResult result = runTest(testCase);
		
		String error = result.saveResult.isSuccess()?'':result.saveResult.getErrors()[0].getMessage();
		System.assert(result.saveResult.isSuccess(), 'The DML operation failed. First error was: '+error);
		
		assertNothingChanged('[single-record insert]',result);
	}
	
	@isTest
	public static void testUpdateOldContact()
	{
		TestCase testCase = new TestCase(
			'UPDATE_OLDCONTACT',
			NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
			EmployeeValue.EMPLOYEE_EXISTS,
			EmailValue.EMAIL_NULL
		);
		setup(testCase);
		TestResult result = runTest(testCase);
		
		String error = result.saveResult.isSuccess()?'':result.saveResult.getErrors()[0].getMessage();
		System.assert(result.saveResult.isSuccess(), 'The DML operation failed. First error was: '+error);
		
		assertUpdateRules('[single-record insert]',result);
	}
	
	@isTest
	public static void testSuspendNewContact()
	{
		TestCase testCase = new TestCase(
			'SUSPEND_NEWCONTACT',
			NewHireUtil.RECORDTYPE_PROVISIONING_SUSPENSION,
			EmployeeValue.EMPLOYEE_NULL,
			EmailValue.EMAIL_UNIQUE
		);
		setup(testCase);
		TestResult result = runTest(testCase);
		
		String error = result.saveResult.isSuccess()?'':result.saveResult.getErrors()[0].getMessage();
		System.assert(result.saveResult.isSuccess(), 'The DML operation failed. First error was: '+error);
		
		assertNothingChanged('[single-record insert]',result);
	}
	
	@isTest
	public static void testSuspendOldContact()
	{
		TestCase testCase = new TestCase(
			'SUSPEND_OLDCONTACT',
			NewHireUtil.RECORDTYPE_PROVISIONING_SUSPENSION,
			EmployeeValue.EMPLOYEE_EXISTS,
			EmailValue.EMAIL_NULL
		);
		setup(testCase);
		TestResult result = runTest(testCase);
		
		String error = result.saveResult.isSuccess()?'':result.saveResult.getErrors()[0].getMessage();
		System.assert(result.saveResult.isSuccess(), 'The DML operation failed. First error was: '+error);
		
		assertSuspensionRules('[single-record insert]',result);
	}
	
	@isTest
	public static void testGenericOldContact()
	{
		TestCase testCase = new TestCase(
			'GENERIC_OLDCONTACT',
			NewHireUtil.RECORDTYPE_PROVISIONING_CASE,
			EmployeeValue.EMPLOYEE_EXISTS,
			EmailValue.EMAIL_NULL
		);
		setup(testCase);
		TestResult result = runTest(testCase);
		
		String error = result.saveResult.isSuccess()?'':result.saveResult.getErrors()[0].getMessage();
		System.assert(result.saveResult.isSuccess(), 'The DML operation failed. First error was: '+error);
		
		assertNothingChanged('[single-record insert]',result);
	}
	
	@isTest
	public static void testCompleteOldContact()
	{
		TestCase testCase = new TestCase(
			'COMPLETE_OLDCONTACT',
			NewHireUtil.RECORDTYPE_PROVISIONING_CASE_COMPLETE,
			EmployeeValue.EMPLOYEE_EXISTS,
			EmailValue.EMAIL_NULL
		);
		setup(testCase);
		TestResult result = runTest(testCase);
		
		String error = result.saveResult.isSuccess()?'':result.saveResult.getErrors()[0].getMessage();
		System.assert(result.saveResult.isSuccess(), 'The DML operation failed. First error was: '+error);
		
		assertNothingChanged('[single-record insert]',result);
	}
	
	/*
	@isTest
	public static void testUpdateDeletedContact()
	{
		TestCase testCase = new TestCase(
			'UPDATE_OLDCONTACT_DELETED_CONTACT',
			NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
			EmployeeValue.EMPLOYEE_DELETED,
			EmailValue.EMAIL_NULL
		);
		setup(testCase);
		TestResult result = runTest(testCase);
		
		String error = result.saveResult.isSuccess()?'':result.saveResult.getErrors()[0].getMessage();
		System.assert(result.saveResult.isSuccess(), 'The DML operation failed. First error was: '+error);
		
		assertUpdateRules('[single-record insert]',result);
	}
	*/
	
	@isTest
	public static void testAddNewContactDupEmail()
	{
		TestCase testCase = new TestCase(
			'ADD_NEWCONTACT_DUP_EMAIL',
			NewHireUtil.RECORDTYPE_PROVISIONING_ADD,
			EmployeeValue.EMPLOYEE_NULL,
			EmailValue.EMAIL_NON_UNIQUE
		);
		setup(testCase);				
		TestResult result = runTest(testCase);
		
		System.assert(!result.saveResult.isSuccess(),
			'[single-record-insert]: The Save should have failed but did not.');
		
		Boolean foundMention = false;
		for(Database.Error err : result.saveResult.getErrors())
		{
			if(err.getMessage().contains(testCase.testSetup.contact.Id)
			|| err.getMessage().contains(testCase.testSetup.contact.Name))
			{
				foundMention = true;
				break;
			}			
		}
		
		System.assert(foundMention, '[single-record-insert]: Neither the Contact Name nor Id was mentioned in an error message.');
		
	}
	
	@isTest
	public static void testAddNewContactBlankEmail()
	{
		TestCase testCase = new TestCase(
			'ADD_NEWCONTACT_BLANK_EMAIL',
			NewHireUtil.RECORDTYPE_PROVISIONING_ADD,
			EmployeeValue.EMPLOYEE_NULL,
			EmailValue.EMAIL_BLANK
		);
		setup(testCase);		
		
		TestResult result = runTest(testCase);

		String error = result.saveResult.isSuccess()?'':result.saveResult.getErrors()[0].getMessage();
		System.assert(result.saveResult.isSuccess(), 'The DML operation failed. First error was: '+error);
		
		assertNothingChanged('[single-record insert]',result);
	}
	
	@isTest
	public static void testAddNewContactNullEmail()
	{
		TestCase testCase = new TestCase(
			'ADD_NEWCONTACT_NULL_EMAIL',
			NewHireUtil.RECORDTYPE_PROVISIONING_ADD,
			EmployeeValue.EMPLOYEE_NULL,
			EmailValue.EMAIL_NULL
		);
		setup(testCase);
		TestResult result = runTest(testCase);
		
		String error = result.saveResult.isSuccess()?'':result.saveResult.getErrors()[0].getMessage();
		System.assert(result.saveResult.isSuccess(), 'The DML operation failed. First error was: '+error);
		
		assertNothingChanged('[single-record insert]',result);
	}
	
	@isTest
	public static void testAddNewContactNoDefaultAccount()
	{
		TestCase testCase = new TestCase(
			'ADD_NEWCONTACT_NO_DEFAULT_ACCOUNT',
			NewHireUtil.RECORDTYPE_PROVISIONING_ADD,
			EmployeeValue.EMPLOYEE_NULL,
			EmailValue.EMAIL_UNIQUE
		);
		setup(testCase,false);				
		TestResult result = runTest(testCase);
		
		System.assert(!result.saveResult.isSuccess(),
			'[single-record-insert]: The Save should have failed but did not.');
		
		Boolean foundMention = false;
		for(Database.Error err : result.saveResult.getErrors())
		{
			if(err.getMessage().contains(NewHireUtil.DEFAULT_ACCOUNT_NAME))
			{
				foundMention = true;
				break;
			}			
		}
		
		System.assert(foundMention, '[single-record-insert]: No error message mentions the Default Account Name.');
		
	}

	@isTest
	public static void testAddNewContactNoContractorAccount()
	{
		TestCase testCase = new TestCase(
			'ADD_NEWCONTACT_NO_CONTRACTOR_ACCOUNT',
			NewHireUtil.RECORDTYPE_PROVISIONING_ADD,
			EmployeeValue.EMPLOYEE_NULL,
			EmailValue.EMAIL_UNIQUE
		);

		// Make this a Contractor Case.
		testCase.theCase.Employee_Type__c = NewHireUtil.CASE_EMPLOYEE_TYPE_CONTRACTOR;

		setup(testCase, true, false);				
		TestResult result = runTest(testCase);
		
		System.assert(!result.saveResult.isSuccess(),
			'[single-record-insert]: The Save should have failed but did not.');
		
		Boolean foundMention = false;
		for(Database.Error err : result.saveResult.getErrors())
		{
			if(err.getMessage().contains(NewHireUtil.CONTRACTOR_ACCOUNT_NAME))
			{
				foundMention = true;
				break;
			}			
		}
		
		System.assert(foundMention, '[single-record-insert]: No error message mentions the Contractor Account Name.');
		
	}
	
	public static String norm(String input)
	{
		return input==''?null:input;		
	}
	
	public static String trim(String input) { return trim(input,40); }
	public static String trim(String input,Integer length)
	{
		Integer diff = input.length()-length;
		return ((diff>0)?input.substring(diff):input).toLowercase();
	}
		
	/**
	* For the given TestResult, assert rules common to all Case records.
	*/
	static void assertCommonRules(String ctx, TestResult res)
	{
		Case caseObj = res.theCase;
		Contact conObj = res.contact;
		
		System.assertEquals(NewHireUtil.RECORDTYPE_PROVISIONING_CASE,caseObj.RecordTypeId, 
        	ctx+'Wrong value for Case.RecordTypeId');
        
        System.assertEquals(conObj.Id,caseObj.prEmployee__c,
        	ctx+'Case.prEmployee__c does not match Contact.Id');
		
		// Test all the fields pulled from the Contact record.
				
        System.assertEquals(conObj.FirstName,caseObj.prFirst_Name__c,
        	ctx+'Case.prFirst_Name__c does not match Case.prEmployee__r.FirstName');
        	
        System.assertEquals(conObj.LastName,caseObj.prLastName__c,
        	ctx+'Case.prLastName__c does not match Case.prEmployee__r.LastName');
        	
        System.assertEquals(conObj.Title,caseObj.prPosition_Title__c,
        	ctx+'Case.prPosition_Title__c does not match Case.prEmployee__r.Title');
        	
        System.assertEquals(conObj.Personal_Email__c,caseObj.prPersonal_Email__c,
        	ctx+'Case.prPersonal_Email__c does not match Case.prEmployee__r.Personal_Email__c');
        	
        System.assertEquals(conObj.Budget_Line_Item__c,caseObj.prBudget_Line_Item__c,
        	ctx+'Case.prBudget_Line_Item__c does not match Case.prEmployee__r.Budget_Line_Item__c');
        	
        System.assertEquals(conObj.torDepartment__c,caseObj.prDepartment__c,
        	ctx+'Case.prDepartment__c does not match Case.prEmployee__r.torDepartment__c');
        	
        System.assertEquals(conObj.Office_Location__c,caseObj.prLocation__c,
        	ctx+'Case.prLocation__c does not match Case.prEmployee__r.Office_Location__c');
        	
        System.assertEquals(conObj.ReportsToId,caseObj.prReports_To__c,
        	ctx+'Case.prReports_To__c does not match Case.prEmployee__r.ReportsToId');
        	
        System.assertEquals(conObj.Billing_Code__c,caseObj.prPayroll_Department_Code__c,
        	ctx+'Case.prPayroll_Department_Code__c does not match Case.prEmployee__r.Billing_Code__c');
        	
        System.assertEquals(conObj.Full_Time_Part_Time__c,caseObj.prFull_Time_Part_Time__c,
        	ctx+'Case.prFull_Time_Part_Time__c does not match Case.prEmployee__r.Full_Time_Part_Time__c');
        	
        System.assertEquals(conObj.HomePhone,caseObj.prPersonal_Phone__c,
        	ctx+'Case.prPersonal_Phone__c does not match Case.prEmployee__r.HomePhone');
        	
        System.assertEquals(conObj.Signing_Limit__c,caseObj.prSigning_Limit__c,
        	ctx+'Case.prSigning_Limit__c does not match Case.prEmployee__r.Signing_Limit__c');
        	
        System.assertEquals(conObj.Division__c,caseObj.prDivision__c,
        	ctx+'Case.prDivision__c does not match Case.prEmployee__r.Division__c');
        	
        System.assertEquals(conObj.Cell_Phone_Reimbursement__c,caseObj.prCell_Phone_Reimbursement__c,
        	ctx+'Case.prCell_Phone_Reimbursement__c does not match Case.prEmployee__r.Cell_Phone_Reimbursement__c');
        	
        System.assertEquals(conObj.Desk_Assignment__c,caseObj.prDesk_Assignment__c,
        	ctx+'Case.prDesk_Assignment__c does not match Case.prEmployee__r.Desk_Assignment__c');
        	
        //System.assertEquals(conObj.Employment_Status__c,caseObj.prEmployment_Status__c,
        //	ctx+'Case.prEmployment_Status__c does not match Case.prEmployee__r.Employment_Status__c');
				
	}
	
	/**
	* For the given User_Account__c, make the assertions common to all User_Account_Case__c records.
	*/	
	static void assertCommonRules(String ctx, TestResult res, User_Account__c userAccount)
	{
		User_Account_Case__c userAccountCase = res.userAccountCaseMap.get(userAccount.Id);
				
		System.assert(userAccountCase.Case__c!=null, ctx+'User_Account_Case__c.Case__c is null.');
		System.assert(userAccountCase.Case__c==res.theCase.Id, 
			ctx+'User_Account_Case__c.Case__c does not match Case.Id');
		
		System.assert(userAccountCase.User_Account__c!=null, ctx+'User_Account_Case__c.User_Account__c is null.');
		System.assert(userAccountCase.User_Account__c==userAccount.Id, 
			ctx+'User_Account_Case__c.User_Account__c does not match User_Account__c.Id');
		
		System.assert(userAccountCase.Service__c!=null, ctx+'User_Account_Case__c.Service__c is null.');
		System.assert(userAccountCase.Service__c==userAccount.Service__c,
			ctx+'User_Account_Case__c.Service__c does not match User_Account__c.Service__c');
		
		System.assert(userAccountCase.Profile__c!=null, ctx+'User_Account_Case__c.Profile__c is null.');
		System.assert(userAccountCase.Profile__c==userAccount.Service_Profile__c,
			ctx+'User_Account_Case__c.Profile__c does not match User_Account__c.Service_Profile__c');
		
		System.assert(userAccountCase.Role__c!=null, ctx+'User_Account_Case__c.Role__c is null.');
		System.assert(userAccountCase.Role__c==userAccount.Service_Role__c,
			ctx+'User_Account_Case__c.Role__c does not match User_Account__c.Service_Role__c');
		
		Id expected = NewHireUtil.USER_ACCOUNT_TO_USER_ACCOUNT_CASE_RECORD_TYPE.get(userAccount.RecordTypeId);
		System.assertEquals(expected,userAccountCase.RecordTypeId,
			ctx+'Wrong value for User_Account_Case__c.RecordTypeId');
		
		System.assert(userAccountCase.Employee__c!=null, ctx+'User_Account_Case__c.Employee__c is null.');
		System.assert(userAccountCase.Employee__c==res.theCase.prEmployee__c,
			ctx+'User_Account_Case__c.Employee__c does not match Case__c.prEmployee__c');				
	}
	
	/**
	* For the given Asset__c, make the assertions common to all Asset_Case__c records
	*/
	static void assertCommonRules(String ctx, TestResult res, Asset__c asset)
	{
		Asset_Case__c assetCase = res.assetCaseMap.get(asset.Id);
			
		// These assertions are common to all Case RecordTypes
		// For specific cases (e.g. drop vs provision), see the 
		// other assertions in this class.
		
		System.assert(assetCase.Case__c!= null, ctx+'Asset_Case__c.Case__c is null.');
		System.assert(assetCase.Case__c==res.theCase.Id,
			ctx+'Asset_Case__c.Case__c does not match Case.Id');
		
		System.assert(assetCase.Asset__c!= null, ctx+'Asset_Case__c.Asset__c is null.');
		System.assert(assetCase.Asset__c==asset.Id,
			ctx+'Asset_Case__c.Asset__c does not match the correct Asset__c.Id');
		
		System.assert(assetCase.Asset_Classification__c!= null, ctx+'Asset_Case__c.Asset_Classification__c is null.');
		System.assert(assetCase.Asset_Classification__c==asset.Asset_Classification__c,
			ctx+'Asset_Case__c.Asset_Classification__c does not match the correct Asset__c.Asset_Classification__c');
		
		System.assertEquals(NewHireUtil.RECORDTYPE_ASSET_CASE_PROVISIONING_REQUEST, assetCase.RecordTypeId,
			ctx+'Wrong value for Asset_Case__c.RecordTypeId');
		
		System.assert(assetCase.Employee__c!= null, ctx+'Asset_Case__c.Employee__c is null.');
		System.assert(assetCase.Employee__c==res.theCase.prEmployee__c,
			ctx+'Asset_Case__c.Employee__c does not match Case.prEmployee__c');
	}
	
	/**
	* Assertions for a TestResult for a Case with
	* RecordTypeId=NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE
	*/ 
	static void assertUpdateRules(String ctx, TestResult res)
	{
		TestCase input = res.testCase;
		String msg = ctx+input.toString()+': ';
		
		// Make assertions common to all output scenarios.
		//
		assertCommonRules(msg,res);
		
		System.assertEquals(res.contact.Employment_Status__c,res.theCase.prEmployment_Status__c,
			msg+'Case.prEmployment_Status__c does not match Contact.Employment_Status__c');
		
		String expectedSubject = 
			NewHireUtil.CASE_SUBJECT_UPDATE
			+res.contact.FirstName + ' ' + res.contact.LastName + ' - ' + String.valueOf(res.testCase.theCase.Due_Date__c);
			
		System.assertEquals(expectedSubject, res.theCase.Subject,
			msg+'Wrong output for Case.Subject');
		
		// Test outputs for all User_Account_Case__c records.
		// 
		for(User_Account__c userAccount : res.contact.UserAccounts__r)
		{	
			// No User_Account_Case__c records shpould be created.
			//			
			System.assert(!res.userAccountCaseMap.containsKey(userAccount.Id),
				msg+'An Update Case caused the generation of a User_Account_Case__c record.');			
		}
		
		// Test outputs for all Asset_Case__c records.
		// 
		for(Asset__c asset : res.contact.ContactsAssets__r)
		{
			// No Asset_Case__c records should be created.
			//
			System.assert(!res.userAccountCaseMap.containsKey(asset.Id),
				msg+'An Update Case caused the generation of an Asset_Case__c record.');
		}				
	}
	
	/**
	* Assertions for a TestResult for a Case with
	* RecordTypeId=NewHireUtil.RECORDTYPE_PROVISIONING_DROP
	*/ 
	static void assertDropRules(String ctx, TestResult res)
	{
		TestCase input = res.testCase;
		String msg = ctx+input.toString()+': ';
		
		// Make assertions common to all output scenarios.
		//
		assertCommonRules(msg,res);
		
		System.assertEquals(NewHireUtil.EMPLOYMENT_STATUS_INACTIVE,res.theCase.prEmployment_Status__c,
			msg+'Wrong output for Contact.Employment_Status__c');
		
		String expectedSubject = 
			NewHireUtil.CASE_SUBJECT_DROP
			+res.contact.FirstName + ' ' + res.contact.LastName + ' - ' + String.valueOf(res.testCase.theCase.Due_Date__c);
			
		System.assertEquals(expectedSubject, res.theCase.Subject,
			msg+'Wrong output for Case.Subject');
		
		// Test outputs for all User_Account_Case__c records.
		// 
		for(User_Account__c userAccount : res.contact.UserAccounts__r)
		{	
			User_Account_Case__c userAccountCase = res.userAccountCaseMap.get(userAccount.Id);
			
			// Assert for Active User Accounts.
			if(userAccount.Active__c)
            {
            	// Make sure that every active User_Account__c has a corresponding User_Account_Case__c
				//
				System.assert(res.userAccountCaseMap.containsKey(userAccount.Id),
				msg+'At least one User_Account__c record is missing a User_Account_Case__c record with Active__c=true.');
				
				// Assert rules common to all User_Account_Case__c records.
				assertCommonRules(msg,res,userAccount);
			
            	System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE, userAccountCase.Type__c, 
            		msg+'Wrong Type__c for User_Account_Case__c with Active__c=true');
            	System.assertEquals(NewHireutil.USER_ACCOUNT_CASE_STATUS_OPEN, userAccountCase.Status__c,
            		msg+'Wrong Status__c for a User_Account_Case__c with Active__c=true');
            	System.assertEquals(res.theCase.Due_Date__c,userAccountCase.Date__c,
            		msg+'[User_Account_Case__c.Active__c=true]: User_Account_Case__c.Date__c does not match Case__c.Due_Date__c');
            }
            // Assert for inactive User Accounts.
            else
            {
            	// Inactive User_Account__c records should not have User_Account_Case__c records
				//
				System.assert(!res.userAccountCaseMap.containsKey(userAccount.Id),
				msg+'A User_Account_Case__c record was created for a User_Account__c record with Active__c=false.');
            }
		}
		
		// Test outputs for all Asset_Case__c records.
		// 
		for(Asset__c asset : res.contact.ContactsAssets__r)
		{
			// Make sure that every Asset has a corresponding Asset_Case__c
			//
			System.assert(res.assetCaseMap.containsKey(asset.Id),
			msg+'At least one Asset__c record is missing an Asset_Case__c record.');
			
			Asset_Case__c assetCase = res.assetCaseMap.get(asset.Id);
			
			// Assert rules common to all Asset_Case__c records.
			//
			assertCommonRules(msg,res,asset);
			
			System.assertEquals(NewHireUtil.ASSET_CASE_TYPE_RECLAIM, assetCase.Type__c, 
        		msg+'Wrong Type__c for Asset_Case__c');
        	System.assertEquals(NewHireutil.ASSET_CASE_STATUS_OPEN, assetCase.Status__c,
        		msg+'Wrong Asset_Case__c.Status__c value');
        	System.assertEquals(res.theCase.Due_Date__c,assetCase.Date_Needed__c,
        		msg+'Asset_Case__c.Date_Needed__c does not match Case__c.Due_Date__c');        	
		}				
	}
	
	/**
	* Assertions for a TestResult for a Case with
	* RecordTypeId=NewHireUtil.RECORDTYPE_PROVISIONING_SUSPENSION
	*/ 
	static void assertSuspensionRules(String ctx, TestResult res)
	{
		TestCase input = res.testCase;
		String msg = ctx+input.toString()+': ';
		
		// Make assertions common to all output scenarios.
		//
		assertCommonRules(msg,res);
		
		System.assertEquals(NewHireUtil.EMPLOYMENT_STATUS_TEMPORARILY_SUSPENDED,res.theCase.prEmployment_Status__c,
			msg+'Wrong output for Contact.Employment_Status__c');
		
		String expectedSubject = 
			NewHireUtil.CASE_SUBJECT_SUSPENSION
			+res.contact.FirstName + ' ' + res.contact.LastName + ' - ' + String.valueOf(res.testCase.theCase.Due_Date__c);
			
		System.assertEquals(expectedSubject, res.theCase.Subject,
			msg+'Wrong output for Case.Subject');
		
		// Test outputs for all User_Account_Case__c records.
		// 
		for(User_Account__c userAccount : res.contact.UserAccounts__r)
		{	
			// Make sure that every User_Account__c has a corresponding User_Account_Case__c
			//
			System.assert(res.userAccountCaseMap.containsKey(userAccount.Id),
			msg+'At least one User_Account__c record is missing an User_Account_Case__c record.');
			
			User_Account_Case__c userAccountCase = res.userAccountCaseMap.get(userAccount.Id);
			
			// Assert rules common to all User_Account_Case__c records.
			assertCommonRules(msg,res,userAccount);
			
			// Assert for Active User Accounts.			
			if(userAccount.Active__c)
            {
            	System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE, userAccountCase.Type__c, 
            		msg+'Wrong Type__c for User_Account_Case__c with Active__c=true');
            	System.assertEquals(NewHireutil.USER_ACCOUNT_CASE_STATUS_OPEN, userAccountCase.Status__c,
            		msg+'Wrong Status__c for a User_Account_Case__c with Active__c=true');
            	System.assertEquals(res.theCase.Due_Date__c,userAccountCase.Date__c,
            		msg+'[User_Account_Case__c.Active__c=true]: User_Account_Case__c.Date__c does not match Case__c.Due_Date__c');
            	System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_NOTES_SUSPENSION_ACTIVE,userAccountCase.Notes__c,
            		msg+'Wrong Notes__c value for User_Account_Case__c with Active__c == true');
            }
            // Assert for inactive User Accounts.
            else
            {
            	System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_TYPE_NONE, userAccountCase.Type__c==null?'':userAccountCase.Type__c,
            		msg+'Wrong Type__c value on a User_Account_Case__c with Active__c=false');
            	System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_STATUS_NONE, userAccountCase.Status__c==null?'':userAccountCase.Status__c,
            		msg+'Wrong Status__c value on a User_Account_Case__c with Active__c=false');
            }
		}
		
		// Test outputs for all Asset_Case__c records.
		// 
		/* Commented out for SF-3364 to disable automatic Asset Reclamation Case creation on Suspension
		for(Asset__c asset : res.contact.ContactsAssets__r)
		{
			// Make sure that every Asset has a corresponding Asset_Case__c
			//
			System.assert(res.assetCaseMap.containsKey(asset.Id),
			msg+'At least one Asset__c record is missing an Asset_Case__c record.');
			
			Asset_Case__c assetCase = res.assetCaseMap.get(asset.Id);
			
			// Assert rules common to all Asset_Case__c records.
			//
			assertCommonRules(msg,res,asset);
			
			System.assertEquals(NewHireUtil.ASSET_CASE_TYPE_RECLAIM, assetCase.Type__c, 
        		msg+'Wrong Type__c for Asset_Case__c');
        	System.assertEquals(NewHireutil.ASSET_CASE_STATUS_OPEN, assetCase.Status__c,
        		msg+'Wrong Asset_Case__c.Status__c value');
        	System.assertEquals(res.theCase.Due_Date__c,assetCase.Date_Needed__c,
        		msg+'Asset_Case__c.Date_Needed__c does not match Case__c.Due_Date__c');
        	System.assertEquals(NewHireUtil.ASSET_CASE_NOTES_SUSPENSION,assetCase.Notes__c,
        		msg+'Wrong Asset_Case__c.Notes__c value');		
		}
		*/
		
		System.assert(null!=res.extraCase,
			msg+'Did not find an automatically created Case for reactivating the Contact later. (Queried for a Case based on prEmployee__c and Origin).');
		
		assertReactivationCaseRules(ctx,res.extraCase);
	}
	
	/**
	* Assertions for a TestResult for a Case with
	* RecordTypeId=NewHireUtil.RECORDTYPE_PROVISIONING_CASE.
	*
	* This Record Type indicates that the Case was automatically 
	* generated for the activation step of a temporary suspension. 
	*/ 
	static void assertReactivationCaseRules(String ctx, TestResult res)
	{
		TestCase input = res.testCase;
		String msg = ctx+input.toString()+'[Reactivation Case]: ';
		
		// Make assertions common to all output scenarios.
		//
		assertCommonRules(msg,res);
		
		Case theCase = res.theCase;
		
		System.assertEquals(NewHireUtil.EMPLOYMENT_STATUS_ACTIVE,theCase.prEmployment_Status__c,
			msg+'Wrong output for Contact.Employment_Status__c');
		
		String expectedSubject = 
			NewHireUtil.CASE_SUBJECT_PROVISIONING
			+res.contact.FirstName + ' ' + res.contact.LastName + ' - ' + String.valueOf(res.theCase.Due_Date__c);
			
		System.assertEquals(expectedSubject, res.theCase.Subject,
			msg+'Wrong output for Case.Subject');
		
		System.assertEquals(NewHireUtil.CASE_TYPE_UPDATE,theCase.Type,
			msg+'Wrong output for Case.Type');
		
		System.assertEquals(res.testCase.theCase.prReturn_Date__c, theCase.Due_Date__c,
			msg+'Case.Due_Date__c does not match the Case.prReturn_Date__c on the original Case');
		
		System.assertEquals(NewHireUtil.CASE_AUTOCREATE_ORIGIN,theCase.Origin,
			msg+'Wrong value for Case.Origin');
		
		
		// Test outputs for all User_Account_Case__c records.
		// 
		for(User_Account__c userAccount : res.contact.UserAccounts__r)
		{	
			// Make sure that every User_Account__c has a corresponding User_Account_Case__c
			//
			System.assert(res.userAccountCaseMap.containsKey(userAccount.Id),
			msg+'At least one User_Account__c record is missing an User_Account_Case__c record.');
			
			User_Account_Case__c userAccountCase = res.userAccountCaseMap.get(userAccount.Id);
			
			// Assert rules common to all User_Account_Case__c records.
			assertCommonRules(msg,res,userAccount);
			
			// Assert for Active User Accounts.			
			if(userAccount.Active__c)
            {
            	System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE, userAccountCase.Type__c, 
            		msg+'Wrong Type__c for User_Account_Case__c with Active__c=true');
            	System.assertEquals(NewHireutil.USER_ACCOUNT_CASE_STATUS_OPEN, userAccountCase.Status__c,
            		msg+'Wrong Status__c for a User_Account_Case__c with Active__c=true');
            	System.assertEquals(res.theCase.Due_Date__c,userAccountCase.Date__c,
            		msg+'[User_Account_Case__c.Active__c=true]: User_Account_Case__c.Date__c does not match Case__c.Due_Date__c');
            	System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_NOTES_PROVISIONING_ACTIVE,userAccountCase.Notes__c,
            		msg+'Wrong Notes__c value for User_Account_Case__c with Active__c == true');
            }
            // Assert for inactive User Accounts.
            else
            {
            	System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_TYPE_NONE, userAccountCase.Type__c==null?'':userAccountCase.Type__c,
            		msg+'Wrong Type__c value on a User_Account_Case__c with Active__c=false');
            	System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_STATUS_NONE, userAccountCase.Status__c==null?'':userAccountCase.Status__c,
            		msg+'Wrong Status__c value on a User_Account_Case__c with Active__c=false');
            }
		}
		
		// Test outputs for all Asset_Case__c records.
		/* Commented out for SF-3364 to disable automatic Asset Reclamation Case creation on Suspension
		for(Asset__c asset : res.contact.ContactsAssets__r)
		{
			// Make sure that every Asset has a corresponding Asset_Case__c
			//
			System.assert(res.assetCaseMap.containsKey(asset.Id),
			msg+'At least one Asset__c record is missing an Asset_Case__c record.');
			
			Asset_Case__c assetCase = res.assetCaseMap.get(asset.Id);
			
			// Assert rules common to all Asset_Case__c records.
			//
			assertCommonRules(msg,res,asset);
			
			System.assertEquals(NewHireUtil.ASSET_CASE_TYPE_PROVISION, assetCase.Type__c, 
        		msg+'Wrong Type__c for Asset_Case__c');
        	System.assertEquals(NewHireutil.ASSET_CASE_STATUS_OPEN, assetCase.Status__c,
        		msg+'Wrong Asset_Case__c.Status__c value');
        	System.assertEquals(res.theCase.Due_Date__c,assetCase.Date_Needed__c,
        		msg+'Asset_Case__c.Date_Needed__c does not match Case__c.Due_Date__c');
        	System.assertEquals(NewHireUtil.ASSET_CASE_NOTES_PROVISIONING,assetCase.Notes__c,
        		msg+'Wrong Asset_Case__c.Notes__c value');		
		}				
		*/
	}
	
	static void assertAutoCreatedContactRules(String ctx, TestResult res)
	{
		TestCase input = res.testCase;
		String msg = ctx+input.toString()+': ';
		
		Contact theContact = res.contact;
		
		// The Case before the Contact was added
		// The Case After the contact was added.
		Case theCase = res.testCase.theCase;
		
		Case theCaseAfter = res.theCase;
		
		System.assert(null != theContact,msg+'No Contact was added to the Case.');
		

		Id correctAccountId = NewHireUtil.getAccountIdForNewContact(theCaseAfter);
		System.assertEquals(correctAccountId, theContact.AccountId,
			msg+'The newly created Contact does not belong to the account specified by NewHirUtil.getAccountIdForNewContact().');
	
		System.assertEquals(theCase.prFirst_Name__c,theContact.FirstName,
			msg+'The newly created Contact\'s FirstName does not match the input Case.prFirst_Name__c');
		
		System.assertEquals(theCase.prPersonal_Email__c,theContact.Personal_Email__c,
			msg+'The newly created Contact\'s Personal_Email__c does not match the input Case.prPersonal_Email__c');
		
		System.assertEquals(theCase.prLastName__c,theContact.LastName,
			msg+'The newly created Contact\'s LastName does not match the input Case.prLastName__c');
		
		System.assertEquals(NewHireUtil.EMPLOYMENT_STATUS_NEW,theContact.Employment_Status__c,
			msg+'Wrong Employment_Status__c value on the newly created Contact.');
		
		System.assertEquals(NewHireUtil.RECORDTYPE_PROVISIONING_CASE,theCaseAfter.RecordTypeId,
			msg+'Wrong RecordTypeId on the output Case.');
		
		System.assertEquals(NewHireUtil.EMPLOYMENT_STATUS_ACTIVE,theCaseAfter.prEmployment_Status__c,
			msg+'Wrong prEmployment_Status__c on the output Case.');
		
		String expectedSubject = 
			NewHireUtil.CASE_SUBJECT_ADD
			+res.contact.FirstName + ' ' + res.contact.LastName + ' - ' + String.valueOf(res.testCase.theCase.Due_Date__c);
			
		System.assertEquals(expectedSubject, theCaseAfter.Subject,
			msg+'Wrong output for Case.Subject');
						
	}
	
	static void assertNothingChanged(String ctx, TestResult res)
	{
		TestCase input = res.testCase;
		String msg = ctx+input.toString()+': ';
		
		Case inCase = res.testCase.theCase;
		Case outCase = res.theCase;
		
		System.assertEquals(inCase.RecordTypeId,outCase.RecordTypeId,
			msg+'The RecordTypeId changed.');
		
		System.assertEquals(inCase.prEmployee__c,outCase.prEmployee__c,
			msg+'The prEmployee__c changed.');
		
		System.assertEquals(inCase.Due_Date__c,outCase.Due_Date__c,
			msg+'The Due_Date__c changed.');
		
		System.assertEquals(inCase.prReturn_Date__c,outCase.prReturn_Date__c,
			msg+'The prReturn_Date__c changed.');
		
		System.assertEquals(inCase.prFirst_Name__c,outCase.prFirst_Name__c,
			msg+'The prFirst_Name__c changed.');
		
		System.assertEquals(inCase.prLastName__c,outCase.prLastName__c,
			msg+'The prLastName__c changed.');
		
		System.assertEquals(norm(inCase.prPersonal_Email__c),outCase.prPersonal_Email__c,
			msg+'The prPersonal_Email__c changed.');
		
		System.assertEquals(0,outCase.User_Accounts_Cases__r.size(),
			msg+'User_Account_Case__c records were created.');
		
		System.assertEquals(0,outCase.Assets_Cases__r.size(),
			msg+'Asset_Case__c records were created.');
				
	}
	
	
	
	
	/**
	* Run the given list of tests and return a list of TestResult objects 
	* corresponding to the given list of TestCases.
	*
	* Each TestResult contains all output data upon which 
	* we will make assertions.
	*/
	static TestResult runTest(TestCase testCase) { return runTests(new List<TestCase>{testCase})[0]; }
	static List<TestResult> runTests(TestCase[] testCases)
	{
		// Extract and insert all of the Case records.
		List<Case> toInsert = new List<Case>();
		Set<Id> contactIds = new Set<Id>();		
		for(TestCase testCase : testCases)
		{ 
			Case theCase = testCase.theCase;
			toInsert.add(theCase.clone(true,true,true,true));
			if(theCase.prEmployee__c != null)
			{
				contactIds.add(theCase.prEmployee__c);
			}
		}
		
		// Find out which cases existed before the test,
		// so we can determine after the test which ones have 
		// been newly created.
		//
		Map<Id,Case> preTestCases = new Map<Id,Case>([
			select
				Id,
				prFirst_Name__c,
	            prLastName__c,
	            prPosition_Title__c,
	            prPersonal_Email__c,
	            prBudget_Line_Item__c,
	            prDepartment__c,
	            prLocation__c,
	            prReports_To__c,
	            prPayroll_Department_Code__c,
	            prFull_Time_Part_Time__c,
	            prPersonal_Phone__c,
	            prSigning_Limit__c,
	            prDivision__c,
	            prCell_Phone_Reimbursement__c,
	            prDesk_Assignment__c,
	            prReturn_Date__c,
	            Employee_Type__c,
	            RecordTypeId	            
			from Case
			where prEmployee__c in :contactIds
			and Origin = :NewHireUtil.CASE_AUTOCREATE_ORIGIN
		]);
		
		
		Database.DMLOptions dmlOpt = new Database.DMLOptions();
		// We will collect individual results later, so
		// allow partial batch successes.
		dmlOpt.optAllOrNone = false;
		// Most of our string values are generated arbitrarily on-the-fly.
		// Allow truncation to prevent values from causing failures.
		dmlOpt.allowFieldTruncation = true;
		
		// Run the insert.
		Database.SaveResult[] saveResults = Database.insert(toInsert,dmlOpt);
		
		// Collect Case Ids for querying output 
		Set<Id> outputCaseIds = new Set<Id>();
		for(Database.SaveResult saveResult : saveResults)
		{
			if(saveResult.isSuccess())
			{
				outputCaseIds.add(saveResult.getId());
			}			
		}
		
		// Query our Cases and their associated User_Account_Case__c 
		// and Asset_Case__c records.
		Map<Id,Case> outputCases = new Map<Id,Case>([
			select
				Id,
				RecordTypeId,
				Employee_Type__c,
				prEmployee__c,
				prFirst_Name__c,
				prLastName__c,
				prPosition_Title__c,
				prPersonal_Email__c,
				prBudget_Line_Item__c,
				prDepartment__c,
				prLocation__c,
				prReports_To__c,
				prPayroll_Department_Code__c,
				prFull_Time_Part_Time__c,
				prPersonal_Phone__c,
				prSigning_Limit__c,
				prDivision__c,
				prCell_Phone_Reimbursement__c,
				prDesk_Assignment__c,
				prEmployment_Status__c,
				prReturn_Date__c,
				Due_Date__c,
				Type,
				Subject,
				Origin,				
				(select 
					Id,
					Case__c,
					User_Account__c,
					Service__c,
					Profile__c,
					Role__c,
					RecordTypeId,
					Employee__c,
					Type__c,
					Status__c,
					Date__c,
					Notes__c
				 from User_Accounts_Cases__r),
				(select 
					Id,
					Case__c,
					Asset__c,
					Asset_Classification__c,
					RecordTypeId,
					Employee__c,
					Type__c,
					Status__c,
					Date_Needed__c,
					Notes__c 
				 from Assets_Cases__r)
			from Case
			where Id in :outputCaseIds
		]);
		
		// Collect our Contact Ids
		Set<Id> outputContactIds = new Set<Id>();		
		for(Case outputCase : outputCases.values())
		{	
			if(outputCase.prEmployee__c != null)
			{
				outputContactIds.add(outputCase.prEmployee__c);
			}
		}
		
		// Query our Contacts and their associated User_Account__c
		// and Asset__c records.
		Map<Id,Contact> outputContacts = new Map<Id,Contact>([
			select
				Id,
				AccountId,
				FirstName,
				LastName,
				Title,
				Budget_Line_Item__c,
				torDepartment__c,
				Office_Location__c,
				ReportsToId,
				Billing_Code__c,
				Full_Time_Part_Time__c,
				HomePhone,
				Signing_Limit__c,
				Division__c,
				Cell_Phone_Reimbursement__c,
				Desk_Assignment__c,
				Employment_Status__c,		
				Personal_Email__c,
				(select 
					Id,
					Service__c,
					Service_Profile__c,
					Service_Role__c,
					Active__c,
					RecordTypeId 
				from UserAccounts__r),
				(select 
					Id,
					Asset_Classification__c,
					RecordTypeId
				from ContactsAssets__r)
			from Contact
			where Id in :outputContactIds
		]);
		
		// Look for cases created for future reactivation
		// of a temprarily suspended employee.
		// 
		List<Case> extraCases = [
			select
				Id,
				RecordTypeId,
				Employee_Type__c,
				prEmployee__c,
				prFirst_Name__c,
				prLastName__c,
				prPosition_Title__c,
				prPersonal_Email__c,
				prBudget_Line_Item__c,
				prDepartment__c,
				prLocation__c,
				prReports_To__c,
				prPayroll_Department_Code__c,
				prFull_Time_Part_Time__c,
				prPersonal_Phone__c,
				prSigning_Limit__c,
				prDivision__c,
				prCell_Phone_Reimbursement__c,
				prDesk_Assignment__c,
				prEmployment_Status__c,
				prReturn_Date__c,
				Due_Date__c,
				Type,
				Subject,
				Origin,				
				(select 
					Id,
					Case__c,
					User_Account__c,
					Service__c,
					Profile__c,
					Role__c,
					RecordTypeId,
					Employee__c,
					Type__c,
					Status__c,
					Date__c,
					Notes__c
				 from User_Accounts_Cases__r),
				(select 
					Id,
					Case__c,
					Asset__c,
					Asset_Classification__c,
					RecordTypeId,
					Employee__c,
					Type__c,
					Status__c,
					Date_Needed__c,
					Notes__c 
				 from Assets_Cases__r)
			from Case 
			where prEmployee__c in :outputContacts.keySet()
			  and Origin = :NewHireUtil.CASE_AUTOCREATE_ORIGIN
			  and Id not in :preTestCases.keySet()
			  and Id not in :outputCases.keySet()
			 order by CreatedDate desc
		];
		
		// Map Contact IDs to extra Cases.
		// In the event that multiple cases correspond to a single Contact,
		// we assume that each extra Case corresponds to a single input Case,
		// and that the order order of extra cases corresponds to the order of 
		// their corresponding input cases.
		Map<Id,List<Case>> extraCasesForContactId = new Map<Id,List<Case>>();
		for(Case extraCase : extraCases)
		{						
			// If necessary, initialize the collection for this Contact
			if(!extraCasesForContactId.containsKey(extraCase.prEmployee__c))
			{ extraCasesForContactId.put(extraCase.prEmployee__c,new List<Case>()); }
			
			// Add the Case to our list.
			extraCasesForContactId.get(extraCase.prEmployee__c).add(extraCase);			
		}
		
		// Construct our TestResults
		List<TestResult> results = new List<TestResult>();
		Integer index = 0;
		for(TestCase testCase : testCases)
		{
			// Set the Database.SaveResult
			Database.SaveResult saveResult = saveResults[index];
			
			// If the insert failed, no further data is relevant.
			if(saveResult.isSuccess())
			{
			
				// Set the Case that we queried.
				Case theCase = outputCases.get(saveResult.getId());
				
				Contact contact = null;
				Case extraCase = null;
				
				if(theCase.prEmployee__c != null)
				{
					// Set the Contact that we queried.			
					contact = outputContacts.get(theCase.prEmployee__c);
					
					List<Case> extraCaseList = extraCasesForContactId.get(theCase.prEmployee__c);
					
					// If there is at least one extra case for this Contact ...			
					if(extraCaseList != null && !extraCaseList.isEmpty())
					{ 
						// ... pull the next Case and place it in our result 
						extraCase = extraCaseList.remove(0);
					}
				}
				
				results.add(new TestResult(testCase,theCase,contact,extraCase,saveResult));
			} else
			{
				results.add(new TestResult(testCase,null,null,null,saveResult));
			}
			 			
			++index;
		}

		return results;
	}
	
	/**
	* Set up pre-test data for the given list of 
	* TestCases, using as few SOQL queries as possible.
	*
	* Make sure that each TestCase has its own 
	* isolated set of data and that all references 
	* point to the appropriate records.
	*
	* See the TestSetup class for details on how the 
	* non-reference fields are populated.
	*
	*/
	
	public static void setup(TestCase   testCase)  { setup(new TestCase[]{testCase},true, true); }
	public static void setup(TestCase[] testCases) { setup(testCases               ,true, true); }	
	
	public static void setup(TestCase   testCase,  Boolean addDefaultAccount) { setup(new TestCase[]{testCase}, addDefaultAccount, true); }
	public static void setup(TestCase[] testCases, Boolean addDefaultAccount) { setup(testCases,                addDefaultAccount, true); }
	
	public static void setup(TestCase   testCase,  Boolean addDefaultAccount, Boolean addContractorAccount)
		{ setup(new TestCase[]{testCase}, addDefaultAccount, addContractorAccount); }
	public static void setup(TestCase[] testCases, Boolean addDefaultAccount, Boolean addContractorAccount)
	{	
		// "first-order" records do not require the IDs of 
		// any other records and can be inserted first. 
		// Higher-order records require the IDs of lower-order
		// records.
		
		// Account, Service__c, and Asset_Classification__c
		List<sObject> firstOrder = new List<sObject>();
		
		// Contact.ReportsTo
		List<sObject> secondOrder = new List<sObject>();
		
		// Contact
		List<sObject> thirdOrder = new List<sObject>();
		
		// User_Account__c, Asset__c
		List<sObject> fourthOrder = new List<sObject>();
		
		if(addDefaultAccount)
		{
			// If we do not have a default account, insert one.
			Account[] defaultAccount = [Select Id from Account where Name=:NewHireUtil.DEFAULT_ACCOUNT_NAME];
			if(defaultAccount.isEmpty())
			{
				firstOrder.add(new Account(Name=NewHireUtil.DEFAULT_ACCOUNT_NAME));			
			}
		}

		if(addContractorAccount)
		{
			// If we do not have a default account, insert one.
			Account[] contractorAccount = [Select Id from Account where Name=:NewHireUtil.CONTRACTOR_ACCOUNT_NAME];
			if(contractorAccount.isEmpty())
			{
				firstOrder.add(new Account(Name=NewHireUtil.CONTRACTOR_ACCOUNT_NAME));			
			}
		}
		
		Map<String,Contact> dupContactForEmail = new Map<String,Contact>();
				
		// Collect our objects for insertion
		for(TestCase testCase : testCases)
		{
			TestSetup setup = testCase.testSetup;
			
			// Don't bother inserting any records for cases where
			// the Contact won't be used.
			if(setup != null
			&& (testCase.employeeReference == EmployeeValue.EMPLOYEE_EXISTS 
			 || testCase.emailReference    == EmailValue.EMAIL_NON_UNIQUE))
			{
				firstOrder.add(setup.account);
				firstOrder.add(setup.service);
				firstOrder.add(setup.assetClassification);
				
				secondOrder.add(setup.bossContact);
				secondOrder.add(setup.serviceRole);
				secondOrder.add(setup.serviceProfile);
				
				thirdOrder.add(setup.contact);
				
				fourthOrder.addAll((List<sObject>)setup.userAccounts);
				fourthOrder.addAll((List<sObject>)setup.assets);
				
				if(testCase.employeeReference == EmployeeValue.EMPLOYEE_DELETED)
				{
					// We will insert a duplicate Contact, use its ID, 
					// then delete it later. 
					Contact dup = setup.contact.clone();
					
					// Add a suffix to avoid errors from third-party dup checkers.
					dup.Personal_Email__c += '.dup';
					
					// We will use the Personal_Email__c value to get this recod back later.
					dupContactForEmail.put(dup.Personal_Email__c,dup);
					
					secondOrder.add(dup);				
				}
			}			
		}
		
		// Insert first-order records and link their IDs
		insert firstOrder;
		for(TestCase testCase : testCases)
		{
			TestSetup setup = testCase.testSetup;
			if(null == setup) { continue; }
			
			setup.bossContact.AccountId = setup.account.Id;
			setup.serviceRole.Service__c = setup.service.Id;
			setup.serviceProfile.Service__c = setup.service.Id;						
		}
		
		// Insert second-order records and link their IDs
		insert secondOrder;
		for(TestCase testCase : testCases)
		{
			TestSetup setup = testCase.testSetup;
			if(null == setup) { continue; }
			
			setup.contact.AccountId = setup.Account.Id;
			setup.contact.ReportsToId = setup.bossContact.Id;

		}
		
		// Inset third-order records.
		insert thirdOrder;
		for(TestCase testCase : testCases)
		{
			TestSetup setup = testCase.testSetup;
			if(null == setup) { continue; }
						
			// Tie User Accounts to their Services and Contacts
			for(User_Account__c userAccount : setup.userAccounts)
			{
				userAccount.Service__c = setup.service.Id;
				userAccount.Contact__c = setup.contact.Id;
				userAccount.Service_Role__c = setup.serviceRole.Id;
				userAccount.Service_Profile__c = setup.serviceProfile.Id;
				// System.debug('User_Account__c.Service__c = '+userAccount.Service__c);
				// System.debug('User_Account__c.Contact__c = '+userAccount.Contact__c);
			}
			
			// Tie Assets to their Asset Classifications and Contacts
			for(Asset__c asset : setup.assets)
			{
				asset.Asset_Classification__c = setup.assetClassification.Id;
				asset.Contact__c = setup.contact.Id;
				// System.debug('Asset__c.Asset_Classification__c = '+asset.Asset_Classification__c);
				// System.debug('Asset__c.Contact__c = '+asset.Contact__c);				
			}
		}		
		insert fourthOrder;
		
		
		// Tie contacts to their Cases based on TestCase 
		// setup information.
		
		for(TestCase testCase : testCases)
		{
			TestSetup setup = testCase.testSetup;
						
			// Set up the pr_Employee__c reference.
			if(testCase.employeeReference == EmployeeValue.EMPLOYEE_NULL)
			{
				testCase.theCase.prEmployee__c = null;								
			} 
			else if(testCase.employeeReference == EmployeeValue.EMPLOYEE_EXISTS && setup != null)
			{
				testCase.theCase.prEmployee__c = setup.contact.Id;								
			} 
			else if(testCase.employeeReference == EmployeeValue.EMPLOYEE_DELETED && setup != null)
			{
				// Use the ID of the duplicate that we created.
				Contact theContact = dupContactForEmail.get(setup.contact.Personal_Email__c+'.dup');
				testCase.theCase.prEmployee__c = theContact.Id;
			}
			
			// Set up the prPersonal_Email__c field,
			// based on our TestCase specification. 
			//
			if(testCase.emailReference == EmailValue.EMAIL_NULL)
			{
				testCase.theCase.prPersonal_Email__c = null;				
			} 
			else if(testCase.emailReference == EmailValue.EMAIL_BLANK)
			{
				testCase.theCase.prPersonal_Email__c = '';				
			} 
			else if(testCase.emailReference == EmailValue.EMAIL_NON_UNIQUE && setup != null)
			{
				testCase.theCase.prPersonal_Email__c = setup.contact.Personal_Email__c;				
			} 
			else if(testCase.emailReference == EmailValue.EMAIL_UNIQUE && setup != null)
			{
				testCase.theCase.prPersonal_Email__c = setup.contact.Personal_Email__c + '.unq';	
			}
		}
		
		if(dupContactForEmail.size() > 0)
		{
			// Delete the records for which we were only using ID values.
			delete dupContactForEmail.values();
		}		
		
		
		
	}
	
	/**
	 * TestCase:
	 * Contains all of the information necessary for Step 1.
	 * This in cludes the Case itself, variables defining the test conditions,
	 * and the TestSetup (see below).
	 */
	public class TestCase
	{
		// Used to distinguish this test from others in error messages
		//
		public String name = null;
		
		// The case to be inserted
		//
		public Case theCase = null;
		
		// Defines how Case.prEmployee__c will relate to the 
		// records in the Database after setup.
		//
		public EmployeeValue employeeReference = null;
		
		// Defines how Case.prPersonal_Email__c will relate to the 
		// records in the Database after setup.
		//
		public EmailValue emailReference = null;
				
		// Contains all data to be inserted into the database
		// prior to inserting the Case.
		//
		public TestSetup testSetup = null;
		
		
		public override String toString()
		{
			String output = '[TestCase:"'+name+'":'+this.employeeReference+','+this.emailReference;
			if(testSetup != null)
			{
				output += ','+(testSetup.assets==null?0:testSetup.userAccounts.size())+' Assets';
				output += ','+(testSetup.userAccounts==null?0:testSetup.userAccounts.size())+' User Accounts (active, inactive, ...)';
			}			
			output += ']';
			
			return output;
		}
		
		public TestCase(
			String name, 
			Id recordTypeId, 
			EmployeeValue employeeReference, 
			EmailValue emailReference)
		{
			this(name,
				recordTypeId,
				employeeReference,
				emailReference,
				DEFAULT_NUM_USER_ACCOUNTS,
				DEFAULT_NUM_ASSETS);			
		}
		
		public TestCase(
			String name, 
			Id recordTypeId, 
			EmployeeValue employeeReference, 
			EmailValue emailReference,
			Integer numUserAccounts,
			Integer numAssets)
		{
			this.name = name;
			this.employeeReference = employeeReference;
			this.emailReference = emailReference;
			
			this.theCase = new Case(
				RecordTypeId     = recordTypeId,
				Due_Date__c      = Date.today().addDays(7),
				prReturn_Date__c = Date.today().addDays(120),
				Employee_Type__c = NewHireutil.CASE_EMPLOYEE_TYPE_EMPLOYEE,
				
				// These values will be copied into a new Contact if 
				// one is automatically created.
				//
				prFirst_Name__c     = trim(TEST_CLASS_ID+'_'+name+'_input00'),
				prLastName__c       = trim(TEST_CLASS_ID+'_'+name+'_input01'),
				prPersonal_Email__c = trim(TEST_CLASS_ID+'_'+name+'_input02@example.com',35)
			);

			if(this.employeeReference == EmployeeValue.EMPLOYEE_EXISTS
			|| this.emailReference == EmailValue.EMAIL_NON_UNIQUE)
			{
				this.testSetup = new TestSetup(
					name,numUserAccounts,numAssets
				);
			}
		}
	}
	
	/**
	 * Contains all of the information necessary for Step 2.
	 * This includes any records related to the Case and any other
	 * records which affect the trigger's behvior toward the inserted 
	 * Case. 
	 */
	public class TestSetup 
	{
		// Case.prEmployee__r.Account
		//
		public Account account = null;
		
		// Case.prEmployee__c
		//
		public Contact contact = null;
		
		// Case.prEmployee__r.ReportsTo
		//
		public Contact bossContact = null;
		
		// All User Accounts related to Case.prEmployee__c
		//
		public User_Account__c[] userAccounts = null;
		
		// A single Service referenced by all of 
		// Case.prEmployee__c's User Accounts.
		// 
		public Service__c service = null;
		
		// A single Service Role referenced by all of 
		// Case.prEmployee__c's User Accounts.
		// 
		public Service_Role__c serviceRole = null;
		
		// A single Service Profile referenced by all of 
		// Case.prEmployee__c's User Accounts.
		// 
		public Service_Profile__c serviceProfile = null;
		
		// All Assets related to Case.prEmployee__c
		//
		public Asset__c[] assets = null;
		
		// A single Asset Classification referenced by all of 
		// Case.prEmployee__c's Assets.
		// 
		public Asset_Classification__c assetClassification = null;
		
		/** 
		* Create all of the records necessary for a single test. Records are 
		* instantiated here but not inserted, and all references between records
		* are left blank until insertion time.
		*
		* Records are inserted and references are populated in the 
		* setup(TestSetup[]) method, so that DML operations on multiple TestSetups
		* can be consolidated into as few operations as possible. 
		*
		* @param name A string value to be used in various fields to distinguish this 
		*             TestSetup from others in the same scope.
		* @param numUserAccounts The maximum number of User_Account__c records to create 
		*             for the Contact. As they are created, every other record has an 
		*             Active__c value of true.
		* @param numAssets How many Assets to create.
		*/
		public TestSetup(
			String name,
			Integer numUserAccounts, 
			Integer numAssets)
		{
			// A generic string value that we will use to populate
			// Strings and Picklists. 
			
			// For some fields, the actual value does not matter;
			// we will only validate whether the value was properly 
			// transfered from one location to another.
			// This generic string value helps distinguish each field
			// on each record in this test setup.  
			String strVal = trim(TEST_CLASS_ID+'_'+name,37);
			
						
			// The Account to which our Contacts will belong.
			this.account = new Account(Name=strVal+'_13');
			
			// The contact whose ID will populate the main contact's ReportsToId
			this.bossContact = new Contact(LastName=strVal+'_12');
			
			// The main Contact, whose values will be pushed onto the Case.
			this.contact = new Contact(
				AccountId                   = null, // Will be account
				FirstName                   = strVal+'_00',
				LastName                    = strVal+'_01',
				Title                       = strVal+'_02',
				Budget_Line_Item__c         = strVal+'_03',
				torDepartment__c            = strVal+'_04',
				Office_Location__c          = strVal+'_05',
				ReportsToId                 = null, // Will be bossContact
				Billing_Code__c             = strVal+'_06',
				Full_Time_Part_Time__c      = strVal+'_07',
				HomePhone                   = '+1-555-555-5555',
				Signing_Limit__c            = 123456.78,
				Division__c                 = strVal+'_08',
				Cell_Phone_Reimbursement__c = strVal+'_09',
				Desk_Assignment__c          = strVal+'_10',
				Employment_Status__c        = strVal+'_11',				
				Personal_Email__c           = trim(strVal+'@example.com',35)
			);
			
			// Referenced by all User_Account__c records in this setup.
			this.service = new Service__c(
				Name       = strVal
			);
			
			// Referenced by all User_Account__c records in this setup. 
			this.serviceRole = new Service_Role__c(
				Name       = strVal,
				Service__c = null // will be this.service.Id
			);
			// Referenced by all User_Account__c records in this setup.
			this.serviceProfile = new Service_Profile__c(
				Name       = strVal,
				Service__c = null // will be this.service.Id
			);
			
			// Referenced by all Asset__c records in this setup.
			this.assetClassification = new Asset_Classification__c(
				Name       = strVal				
			);
			
			
			this.userAccounts = new User_Account__c[]{};
			Boolean active = false;
			
			// Add two User_Account__c records (one active, one inactive) for each RecordType
			for(Id userAccountRecordType : NewHireUtil.USER_ACCOUNT_TO_USER_ACCOUNT_CASE_RECORD_TYPE.keySet())
			{
				this.userAccounts.add(new User_Account__c(
					Contact__c  = null, // will be this.contact.Id
					Active__c    = true,
					RecordTypeId = userAccountRecordType
				));
				if(--numUserAccounts < 1) { break; }
				
				this.userAccounts.add(new User_Account__c(
					Contact__c  = null, // will be this.contact.Id
					Active__c    = false,
					RecordTypeId = userAccountRecordType
				));
				if(--numUserAccounts < 1) { break; }								
			}
			
			// Add the specified number of Asset records.				
			this.assets = new Asset__c[]{};
			while(numAssets > 0)
			{
				this.assets.add(new Asset__c(
					Contact__c = null // will be this.contact.Id
				));
				--numAssets;			
			}	
		}		
	}
	
	/**
	* TestResult:
	 * Contains all information necessary for Step 5. This includes the
	 * original TestCase, the Database.SaveResults for the insert, and
	 * any other data that was queried after the insertion was run.
	 */
	public class TestResult
	{
		// The TestCase that was run.
		//
		public TestCase testCase = null;
		
		// The Case, as queried after insertion
		//
		public Case theCase = null;
		
		// The Contact, as queried after insertion
		//
		public Contact contact = null;
		
		// If the test resulted in the creation of another case
		// (e.g. a case for future reactivation of a temporarily 
		// suspended employee), a TestResult is instantiated for 
		// the new stored here. Note that extraCase shares data with 
		// this TestResult, rather than requerying it.
		public TestResult extraCase = null;
		
		// The SaveResult corresponding to the insertion of the Case. 
		public Database.SaveResult saveResult = null;
		
		// Convenience variable, populated on construction from
		// theCase.User_Accounts_Cases__r
		//
		public Map<Id,User_Account_Case__c> userAccountCaseMap = null;
		
		// Convenience variable, populated on construction from
		// theCase.Assets_Cases__r
		//
		public Map<Id,Asset_Case__c> assetCaseMap = null;
		
		public TestResult(
			TestCase testCase,
			Case theCase, 
			Contact contact, 
			Case extraCase, 
			Database.SaveResult saveResult)
		{
			this.testCase = testCase;
			this.theCase = theCase;
			this.contact = contact;
			this.saveResult = saveResult;
			
			// Since the extra case undergoes mostly the same process as the main case, 
			// we recursively create a TestResult for it. 
			this.extraCase = (extraCase==null)?null
				 :new TestResult(testCase,extraCase,contact,null,saveResult);

			
			// Populate some maps, which we will use 
			// to check whether each Asset__c/User_Account__c has an 
			// Asset_Case__c/User_Account_Case__c. 
			if(this.theCase != null)
			{
				this.userAccountCaseMap = new Map<Id,User_Account_Case__c>();
				for(User_Account_Case__c userAccountCase : this.theCase.User_Accounts_Cases__r)
				{
					this.userAccountCaseMap.put(userAccountCase.User_Account__c,userAccountCase);					
				}
				
				this.assetCaseMap = new Map<Id,Asset_Case__c>();
				for(Asset_Case__c assetCase : this.theCase.Assets_Cases__r)
				{
					this.assetCaseMap.put(assetCase.Asset__c,assetCase);					
				}
				
			}
						
		}		
								
	}

        
}