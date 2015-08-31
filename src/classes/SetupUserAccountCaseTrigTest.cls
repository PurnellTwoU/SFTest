/**
 * Test Cases for SetupUserAccountCase.trigger
 * 
 * Input Contexts:
 * - Batch operation with mixed input conditions. 
 * - Record is inserted.
 * - Record is updated.
 *
 * Test Cases
 * ----------
 *
 * ValidQueue: 
 * A valid User_Account_Case__c.Service__r.Provisioning_Queue__c is specified.
 * - User_Account_Case__c.Owner refers to a Queue where Queue.DeveloperName
 *   == User_Account_Case__c.Service__r.Provisioning_Queue__c
 *
 * ValidCaseTeam: 
 * A valid User_Account_Case__c.Service__r.Pre_Defined_Case_Team__c 
 * is specified.
 * - There exists exactly one CaseTeamTemplateRecord record 
 *   where CaseTeamTemplateRecord.TeamTemplateId is a CaseTeamTemplate with
 *   CaseTeamTemplate.Name == User_Account_Case__c.Service__r.Pre_Defined_Case_Team__c
 *
 * NoQueue: 
 * User_Account_Case__c.Service__r.Provisioning_Queue__c is null.
 * - No error is thrown and no change is made to User_Account_Case__c.Owner.
 *
 * NoService: 
 * User_Account_Case__c.Service__c is null.
 * - No error is thrown and no change is made to User_Account_Case__c.Owner.
 *
 * NoCaseTeam: 
 * User_Account_Case__c.Pre_Defined_Case_Team__c is null.
 * - No error is thrown and no Case Team is assigned.
 *
 * NoCase: 
 * User_Account_Case__c.Service__r.Pre_Defined_Case_Team__c is valid, but 
 * User_Account_Case__c.Case__c is null.
 * - An error is thrown.
 *
 * BadQueueName: 
 * User_Account_Case__c.Service__r.Provisioning_Queue__c refers to 
 * the name of a Queue which does not exist.
 * - The insert fails with an error message mentioning the bad queue name.
 *
 * WrongQueueName: 
 * User_Account_Case__c.Service__r.Provisioning_Queue__c refers to 
 * Queue.Name instead of Queue.DeveloperName.
 * - The insert fails with an error message mentioning the bad queue name.
 *
 * QueueNotEnabled: 
 * User_Account_Case__c.Service__r.Provisioning_Queue__c refers to 
 * the name of a Queue which is not enabled for use with User_Account_Case__c records.
 * - The insert fails with an error message mentioning the name of the bad queue.
 *
 * BadCaseTeam: 
 * User_Account_Case__c.Service__r.Pre_Defined_Case_Team__c names a 
 * CaseTeamTemplate which does not exist.
 * - The insert fails with an error message mentioning the CaseTeamTemplate name.
 *
 * CaseTeamAlreadyAssigned: 
 * User_Account_Case__c.Service__r.Pre_Defined_Case_Team__c names a 
 * CaseTeamTemplate that is already assigned to User_Account_Case__c.Case__c.
 * - No error is thrown.
 * - The correct CaseTeamTemplate is still assigned to the User_Account_Case__c.Case__c
 *
 */
@isTest
private class SetupUserAccountCaseTrigTest 
{
	// These globals will be inserted on-the-fly.
	/////////////////////////////////////////////
	
	public static Group QUEUE_DEFAULT     = null;
	public static Group QUEUE_VALID_0     = null;
	public static Group QUEUE_VALID_1     = null;
	public static Group QUEUE_NOT_ENABLED = null;
	
	public static CaseTeamTemplate CASE_TEAM_DEFAULT = null;
	public static CaseTeamTemplate CASE_TEAM_VALID_0 = null;
	public static CaseTeamTemplate CASE_TEAM_VALID_1 = null;
	public static Set<Id> RELEVANT_CASE_TEAM_IDS = null;
	
	public static Service__c SERVICE_DEFAULT               = null;
	public static Service__c SERVICE_VALID_0               = null;
	public static Service__c SERVICE_VALID_1               = null;	
	public static Service__c SERVICE_NO_QUEUE              = null;
	public static Service__c SERVICE_NO_CASE_TEAM          = null;	
	public static Service__c SERVICE_NO_QUEUE_NO_CASE_TEAM = null;
	public static Service__c SERVICE_QUEUE_NOT_ENABLED     = null;
	public static Service__c SERVICE_BAD_QUEUE_NAME        = null;
	public static Service__c SERVICE_WRONG_QUEUE_NAME      = null;
	public static Service__c SERVICE_BAD_CASE_TEAM_NAME    = null;
	
	public static Case CASE_DEFAULT = null;
	public static Case[] CASES = null;
	
	public static User TEST_USER = null;
	
	public static Integer nextCaseIndex = 0;
	
	/**
	* Dispense pre-inserted Case records for use in testCases.
	* @throws IndexOutOdBoundsException when the number of cases 
	* exceeds the number of Cases allocated. 
	*/
	public static Case getNextCase()
	{ return CASES[nextCaseIndex++]; }
	
	/*
	* A Test makes a set of assertions related to one of 
	* our output conditions.
	*/
	public interface Test 
	{
		/**
		* @param context a string giving extra information about the 
		*        context in which this test was asserted. Provides
		*        extra information for Assertion failure messages, such as 
		*        input conditions that may not be apparent from the stack trace.
		*
		* @param testCase the test case that was run
		*
		* @param the result of the TestCase having been run.
		*
		*/
		void assert(String context, TestCaseResult result); 
	}	
	
	/*
	* ValidQueue:
	* - User_Account_Case__c.Owner refers to a Queue where Queue.DeveloperName
	*   == User_Account_Case__c.Service__r.Provisioning_Queue__c
	*/
	public class ValidQueueTest implements Test {
		public void assert(String context, TestCaseResult result)
		{
			User_Account_Case__c objBefore = result.testCase.input;
			User_Account_Case__c objAfter = result.output.record;			
			Group ownerAfter = result.output.ownerQueue;
			
			Boolean succeeded = result.saveResult.isSuccess();
			System.assert(succeeded,context+': Dml operation failed for this record. First error was: '+
				(succeeded?null:result.saveResult.getErrors()[0].getMessage())
			);
			
			System.assert(null!=objBefore.Service__r,context+': The input service was null.');
			System.assertEquals('Queue',objAfter.Owner.Type, context+': Assigned owner is the wrong type.');
			System.assert(null!=ownerAfter,context+': The input service was null.');
			
			System.assertEquals(
				objBefore.Service__r.Provisioning_Queue__c,
				ownerAfter.DeveloperName,
				context+': The selected Queue.DeveloperName does not match User_Account_Case__c.Service__r.Provisioning_Queue__c'
			);
		} 
	}
   /**
	* ValidCaseTeam:
	* - There exists exactly one CaseTeamTemplateRecord record 
	*   where CaseTeamTemplateRecord.TeamTemplateId is a CaseTeamTemplate with
	*   CaseTeamTemplate.Name == User_Account_Case__c.Service__r.Pre_Defined_Case_Team__c
	*/
	public class ValidCaseTeamTest implements Test {
		public void assert(String context, TestCaseResult result)
		{
			Map<Id,CaseTeamTemplate> caseTeams = result.output.caseTeams;
			User_Account_Case__c objBefore = result.testCase.input;
			User_Account_Case__c objAfter = result.output.record; 
			
			Boolean succeeded = result.saveResult.isSuccess();
			System.assert(succeeded,context+': Dml operation failed for this record. First error was: '+
				(succeeded?null:result.saveResult.getErrors()[0].getMessage())
			);
			
			System.assert(null != objAfter.Case__c,context+': The modified record has Case__c==null');
			
			Integer foundCaseTeam = 0;
			for(CaseTeamTemplate caseTeam : caseTeams.values())
			{
				if(caseTeam.Name == objBefore.Service__r.Pre_Defined_Case_Team__c)
				{
					++foundCaseTeam;
				}
			}
			
			System.assertEquals(1,foundCaseTeam,context+': Found wrong number of Case Teams with Name == "'+
				objBefore.Service__r.Pre_Defined_Case_Team__c+'".');
			
		} 
	}
	
	/*
	* NoQueue:
 	* - No error is thrown and no change is made to User_Account_Case__c.Owner.
 	*/
	public class NoQueueTest implements Test  {
		public void assert(String context, TestCaseResult result)
		{
			Boolean succeeded = result.saveResult.isSuccess();
			System.assert(succeeded,context+': Dml operation failed for this record. First error was: '+
				(succeeded?null:result.saveResult.getErrors()[0].getMessage())
			);
			
			System.assert(
				result.testCase.input.OwnerId
				== result.output.record.OwnerId,
				context+': The record\'s owner has been changed.'
			);						
		} 
	}
	
	/*
	* NoService:
 	* - No error is thrown and no change is made to User_Account_Case__c.Owner.
 	*/
	public class NoServiceTest implements Test  {
		public void assert(String context, TestCaseResult result)
		{
			Boolean succeeded = result.saveResult.isSuccess();
			System.assert(succeeded,context+': Dml operation failed for this record. First error was: '+
				(succeeded?null:result.saveResult.getErrors()[0].getMessage())
			);
			
			System.assert(
				result.testCase.input.OwnerId
				== result.output.record.OwnerId,
				context+': The record\'s Owner has been changed.'
			);
			
		} 
	}
	
	/* NoCaseTeam
 	* - No error is thrown and no Case Team is assigned.
 	*/
	public class NoCaseTeamTest implements Test  {
		public void assert(String context, TestCaseResult result)
		{
			Boolean succeeded = result.saveResult.isSuccess();
			System.assert(succeeded,context+': Dml operation failed for this record. First error was: '+
				(succeeded?null:result.saveResult.getErrors()[0].getMessage())
			);
			
			System.assert(result.output.record.Case__c!=null,context+': The output record has no Case__c');
			Integer numCaseTeams = (result.output.caseTeams == null)?0:result.output.caseTeams.size(); 
			System.assert(
					numCaseTeams==0,
					context+': Trigger assigned '+numCaseTeams+' Case Team(s) to the input record\'s case. First Team was named: '+
					((numCaseTeams>0)?result.output.caseTeams.values()[0].Name:null)
				);
			
		} 
	}
	
	/* 
	* NoCase:
 	* - The insert fails with an error message mentioning the bad queue name.
 	*/
	public class NoCaseTest implements Test  {
		public void assert(String context, TestCaseResult result)
		{
			System.assert(!result.saveResult.isSuccess(),
			context+': The DML operation should have failed but did not.');			
		} 
	}
	
	/* 
	* BadQueueName:
 	* - The insert fails with an error message mentioning the bad queue name.
 	*/
	public class BadQueueNameTest implements Test  {
		public void assert(String context, TestCaseResult result)
		{
			System.assert(!result.saveResult.isSuccess(),
			'The DML operation should have failed but did not.');
			
			Boolean badQueueMentioned = false;
			for(Database.Error err : result.saveResult.getErrors())
			{
				if(err.getMessage().contains(result.testCase.input.Service__r.Provisioning_Queue__c))
				{
					badQueueMentioned = true;										
				}				
			}
			
			System.assert(badQueueMentioned, context+': None of the error messages mentioned the bad Queue name.');
			
		} 
	}
	
	/*
	* WrongQueueName:
 	* - The insert fails with an error message mentioning the bad queue name.
 	*/
	public class WrongQueueNameTest implements Test  {
		public void assert(String context, TestCaseResult result)
		{
			System.assert(!result.saveResult.isSuccess(),
			'The DML operation should have failed but did not.');
			
			Boolean badQueueMentioned = false;
			for(Database.Error err : result.saveResult.getErrors())
			{
				if(err.getMessage().contains(result.testCase.input.Service__r.Provisioning_Queue__c))
				{
					badQueueMentioned = true;										
				}				
			}
			
			System.assert(badQueueMentioned, context+': None of the error messages mentioned the bad Queue name.');
		} 
	}
	
	/*
	* QueueNotEnabled:
 	* - The insert fails with an error message mentioning the name of the bad queue.
 	*/
	public class QueueNotEnabledTest implements Test  {
		public void assert(String context, TestCaseResult result)
		{
			System.assert(!result.saveResult.isSuccess(),
			'The DML operation should have failed but did not.');
			
			Boolean badQueueMentioned = false;
			for(Database.Error err : result.saveResult.getErrors())
			{
				if(err.getMessage().contains(result.testCase.input.Service__r.Provisioning_Queue__c))
				{
					badQueueMentioned = true;										
				}				
			}
			
			System.assert(badQueueMentioned, context+': None of the error messages mentioned the bad Queue name.');
		} 
	}
	
	/*
	* BadCaseTeamName:
 	* - The insert fails with an error message mentioning the CaseTeamTemplate name.
 	*/
	public class BadCaseTeamNameTest implements Test  {
		public void assert(String context, TestCaseResult result)
		{
			System.assert(!result.saveResult.isSuccess(),
			'The DML operation should have failed but did not.');
			
			Boolean badCaseTeamMentioned = false;
			for(Database.Error err : result.saveResult.getErrors())
			{
				if(err.getMessage().contains(result.testCase.input.Service__r.Pre_Defined_Case_Team__c))
				{
					badCaseTeamMentioned = true;										
				}				
			}
			
			System.assert(badCaseTeamMentioned, context+': None of the error messages mentioned the bad Case Team name.');			
		} 
	}
	
	/*
	* CaseTeamAlreadyAssigned:
 	* - No error is thrown.
 	* - The correct CaseTeamTemplate is still assigned to the User_Account_Case__c.Case__c
 	*/
	public class CaseTeamAlreadyAssignedTest implements Test  {
		public void assert(String context, TestCaseResult result)
		{
			Map<Id,CaseTeamTemplate> caseTeams = result.output.caseTeams;
			User_Account_Case__c objBefore = result.testCase.input;
			User_Account_Case__c objAfter = result.output.record; 
			
			Boolean succeeded = result.saveResult.isSuccess();
			System.assert(succeeded,context+': Dml operation failed for this record. First error was: '+
				(succeeded?null:result.saveResult.getErrors()[0].getMessage())
			);
			
			System.assert(null != objAfter.Case__c,context+': The modified record has Case__c==null');
			
			Integer foundCaseTeam = 0;
			for(CaseTeamTemplate caseTeam : caseTeams.values())
			{
				if(caseTeam.Name == objBefore.Service__r.Pre_Defined_Case_Team__c)
				{
					++foundCaseTeam;
				}
			}
			
			System.assertEquals(1,foundCaseTeam,context+': Found wrong number of Case Teams with Name == "'+
				objBefore.Service__r.Pre_Defined_Case_Team__c+'".');			
		} 
	}
	
	public static TestCase[] makeTestCases()
	{	
		return new TestCase[]
		{
			// ValidQueue, ValidCaseTeam
			new TestCase(
				new User_Account_Case__c(
					Case__c    = getNextCase().Id,
					OwnerId    = QUEUE_DEFAULT.Id,
					Service__c = SERVICE_VALID_0.Id,
					Service__r = SERVICE_VALID_0),
				new Test[]{
					new ValidQueueTest(),
					new ValidCaseTeamTest()}
			),
			
			// NoService
			new TestCase(
				new User_Account_Case__c(
					Case__c    = getNextCase().Id,
					OwnerId    = QUEUE_DEFAULT.Id,
					Service__c = null),	
				new NoServiceTest()
			),
			
			// NoQueue
			new TestCase(
				new User_Account_Case__c(
					Case__c    = getNextCase().Id,
					OwnerId    = QUEUE_DEFAULT.Id,
					Service__c = SERVICE_NO_QUEUE.Id,
					Service__r = SERVICE_NO_QUEUE),
				new NoQueueTest()
			),	
			
			// NoCaseTeam
			new TestCase(
				new User_Account_Case__c(
					Case__c    = getNextCase().Id,
					OwnerId    = QUEUE_DEFAULT.Id,
					Service__c = SERVICE_NO_CASE_TEAM.Id,
					Service__r = SERVICE_NO_CASE_TEAM),	
				new NoCaseTeamTest()
			),
			
			// NoCase
			new TestCase(
				new User_Account_Case__c(
					Case__c    = null,
					OwnerId    = QUEUE_DEFAULT.Id,
					Service__c = SERVICE_DEFAULT.Id,
					Service__r = SERVICE_DEFAULT),	
				new NoCaseTest()
			),
			
			// NoQueue, NoCaseTeam
			new TestCase(
				new User_Account_Case__c(
					Case__c    = getNextCase().Id,
					OwnerId    = QUEUE_DEFAULT.Id,
					Service__c = SERVICE_NO_QUEUE_NO_CASE_TEAM.Id,
					Service__r = SERVICE_NO_QUEUE_NO_CASE_TEAM),
				new Test[]{
					new NoQueueTest(),
					new NoCaseTeamTest()}
			),
			
			// QueueNotEnabled
			new TestCase(
				new User_Account_Case__c(
					Case__c    = getNextCase().Id,
					OwnerId    = QUEUE_DEFAULT.Id,
					Service__c = SERVICE_QUEUE_NOT_ENABLED.Id,
					Service__r = SERVICE_QUEUE_NOT_ENABLED),	
				new QueueNotEnabledTest()
			),
			
			// BadQueueName
			new TestCase(
				new User_Account_Case__c(
					Case__c    = getNextCase().Id,
					OwnerId    = QUEUE_DEFAULT.Id,
					Service__c = SERVICE_BAD_QUEUE_NAME.Id,
					Service__r = SERVICE_BAD_QUEUE_NAME),	
				new BadQueueNameTest()
			),
			
			// WrongQueueName
			new TestCase(
				new User_Account_Case__c(
					Case__c    = getNextCase().Id,
					OwnerId    = QUEUE_DEFAULT.Id,
					Service__c = SERVICE_WRONG_QUEUE_NAME.Id,
					Service__r = SERVICE_WRONG_QUEUE_NAME),	
				new WrongQueueNameTest()
			),
			
			// BadCaseTeamName
			new TestCase(
				new User_Account_Case__c(
					Case__c    = getNextCase().Id,
					OwnerId    = QUEUE_DEFAULT.Id,
					Service__c = SERVICE_BAD_CASE_TEAM_NAME.Id,
					Service__r = SERVICE_BAD_CASE_TEAM_NAME),
				new BadCaseTeamNameTest()
			)			
		};
	}
	
	
	/*
	* Pairs an input with the tests that will be run on 
	* its output once the TestCase is run. 
	*/
	public class TestCase
	{
		// The record to be inserted/updated.
		public User_Account_Case__c input = null;
		
		// Tests to be asserted on the output, once this
		// test case has been run.
		public Test[] tests = null;
		
		public TestCase(User_Account_Case__c input, Test[] tests)
		{
			this.input = input;
			this.tests = tests;
		}
		public TestCase(User_Account_Case__c input, Test test)
		{
			this(input,new Test[]{test});
		}
	}
	
	/*
	* All information related to the initiation and completion 
	* of a test case
	*/
	public class TestCaseResult
	{
		// The test case that was run
		public TestCase testCase = null;
		
		// The output to be tested.
		public TestCaseOutput output = null;
		
		// The result of the database operation
		// that was performed on the test case's input.
		//		
		public Database.SaveResult saveResult = null;
		
		public TestCaseResult(
			TestCase testCase, 
			TestCaseOutput output, 
			Database.SaveResult saveResult)
		{
			this.testCase = testCase;
			this.output = output;
			this.saveResult = saveResult;
		}
	}
	
	public class TestCaseOutput
	{
		// The modified version of the input User_Account_Case__c
		public User_Account_Case__c record = null;
		
		// the owner if the User_Account_Case__c, if it is a queue
		public Group ownerQueue = null;
		
		// CaseTeams assigned to the output record.
		public Map<Id,CaseTeamTemplate> caseTeams = null;
		
		public TestCaseOutput(User_Account_Case__c record, Group ownerQueue, Map<Id,CaseTeamTemplate> caseTeams)
		{
			this.record = record;
			this.ownerQueue = ownerQueue;			
			this.caseTeams = caseTeams;
		}
	}
	
	public static List<TestCaseResult> runCases(TestCase[] testCases, Boolean isUpdate)
	{
		// Place all records in a list.
		List<User_Account_Case__c> inputs = new List<User_Account_Case__c>();
		for(TestCase testCase : testCases)
		{
			// Use a clone so the input is not affected.
			inputs.add(testCase.input.clone(true,true,true,true));	
		}
		
		// Insert or update the records.		
		Database.SaveResult[] saveResults = isUpdate?Database.update(inputs,false):Database.insert(inputs,false);	
		
		// Make a list of IDs for successfully inserted records	
		List<Id> idList = new List<Id>();		 
		for(Database.SaveResult saveResult : saveResults)
		{
			if(saveResult.isSuccess())
			{
				idList.add(saveResult.getId());							
			}
		}
		
		// Query outputs for testing.
		Map<Id,User_Account_Case__c> outputMap = 
			new Map<Id,User_Account_Case__c>([
				select
					Id,
					OwnerId,
					Owner.Type,
					Case__c,
					Service__c,
					Service__r.Pre_Defined_Case_Team__c,
					Service__r.Provisioning_Queue__c
				from User_Account_Case__c
				where Id in :idList
			]);
		
		// Collect IDs so we can query related results.
		Set<Id> ownerGroupIds = new Set<Id>();
		Set<Id> caseIds = new Set<Id>();
		for(User_Account_Case__c uac : outputMap.values())
		{
			if(uac.OwnerId != null)
			{
				ownerGroupIds.add(uac.OwnerId);
			}	
			if(uac.Case__c != null)
			{
				caseIds.add(uac.Case__c);
			}	
		}
		
		// Query all owners which are Groups (Queues)
		Map<Id,Group> ownerQueues = new Map<Id,Group>([
			select
				Id,DeveloperName
			from Group
			where Id in :ownerGroupIds				
		]);
		
		
		// Query for Case Teams related to our cases.
		CaseTeamTemplateRecord[] caseTeamAssignments = [
			select ParentId,TeamTemplateId
			from CaseTeamTemplateRecord
			where 
				ParentId in :caseIds
				and TeamTemplateId in :RELEVANT_CASE_TEAM_IDS
		];
		
		// Collect our CaseTeamTemplate Ids
		Set<Id> caseTeamTemplateIds = new Set<Id>();		
		for(CaseTeamTemplateRecord cttr : caseTeamAssignments)
		{ caseTeamTemplateIds.add(cttr.TeamTemplateId); }
		
		// Query our CaseTeamTemplates
		Map<Id,CaseTeamTemplate> allCaseTeams = new Map<Id,CaseTeamTemplate>([
			select Id,Name
			from CaseTeamTemplate
			where Id in :caseTeamTemplateIds
		]);
		
		// Map Case Ids to CaseTeamTemplates
		Map<Id,Map<Id,CaseTeamTemplate>> caseTeamsForCase = new Map<Id,Map<Id,CaseTeamTemplate>>();
		for(CaseTeamTemplateRecord cttr : caseTeamAssignments)
		{
			if(!caseTeamsForCase.containsKey(cttr.ParentId))
			{
				caseTeamsForCase.put(cttr.ParentId,new Map<Id,CaseTeamTemplate>());
			}
			caseTeamsForCase.get(cttr.ParentId)
			.put(cttr.TeamTemplateId,allCaseTeams.get(cttr.TeamTemplateId));			
		}
					
		// Generate results.
		List<TestCaseResult> testResults = new List<TestCaseResult>();
		Integer index = 0; 
		for(Database.SaveResult saveResult : saveResults)
		{
			// The newly modified version of the input record.
			User_Account_Case__c outputRecord = 
				saveResult.isSuccess()?
				outputMap.get(saveResult.getId()):null;
			
			// The Owner of the output record (if it is a queue)
			Group outputQueue = (outputRecord==null)?null:
				ownerQueues.get(outputRecord.OwnerId);
				
			// Any Case Teams assigned to the output Record's case.
			// or null if the output record has no Case
			Map<Id,CaseTeamTemplate> caseTeams = 
				(outputRecord==null || outputRecord.Case__c==null)?null:				
				caseTeamsForCase.get(outputRecord.Case__c);

			testResults.add(new TestCaseResult(
			
				// Add the original test case.
				testCases[index],
				
				// Add the output data
				new TestCaseOutput(outputRecord,outputQueue,caseTeams),
								
				// Add the save result itself.						
				saveResult
			));	
			index++;		
		}
		
		return testResults;				
	}
	
	/**
	* Assert all of the tests for each of the given test results.
	* Pass the given context into each assertion.
	*/
	public static void assertTests(TestCaseResult[] testResults, String context)
	{
		Integer i = 0;
		for(TestCaseResult testResult : testResults)
		{
			for(Test test : testResult.testCase.tests)
			{
				test.assert('[case '+i+']'+context,testResult);
			}			
			++i;
		}		
	}	
	
		
	@isTest
    static void testInsert() 
    {
        setup();
        
        TestCase[] testCases = makeTestCases();        
        TestCaseResult[] results = runCases(testCases,false);        
        assertTests(results,'[multi-record insert]');        
        
    }	
    
    /**
    * Run all test cases in an update context, as follows:
    * 1. For each test case, nullify all User_Account_Case__c.Service__c records.
    * 2. Insert the test records.
    * 3. Re-assign the User_Account_Case__c.Service__c records.
    * 4. Run an update and apply all test assertions.
    */ 
    @isTest
    static void testUpdate()
    {
    	setup();
    	TestCase[] testCases = makeTestCases();

    	// Add an extra testCase for the CaseTeamAlreadyAssigned case.
    	Case withCaseTeam = getNextCase();    	
    	testCases.add(
    		new TestCase(
				new User_Account_Case__c(
					Case__c    = withCaseTeam.Id,
					OwnerId    = QUEUE_DEFAULT.Id,
					Service__c = SERVICE_VALID_1.Id,
					Service__r = SERVICE_VALID_1),
				new CaseTeamAlreadyAssignedTest()
			)
    	);
    	
    	// Start a list of records to insert.
    	sObject[] toInsert = new sObject[]{};    
    	
    	// Include our Case Team Assignment	
    	toInsert.add(
    		new CaseTeamTemplateRecord(
    			ParentId=withCaseTeam.Id,
    			TeamTemplateId=CASE_TEAM_VALID_1.Id
    		)
    	);    	
    	
    	// We will nullify all affecting data from the User_Account_CAse__c 
    	// records prior to insertion then replace them afterwards.
    	User_Account_Case__c[] backups = new User_Account_Case__c[]{};	    	  	    	
    	for(TestCase tc : testCases)
    	{
    		backups.add(tc.input.clone(true,true,true,true));    		
    		tc.input.Service__c = null;  		
    		toInsert.add(tc.input);    		
    	}
    	    	
    	try
    	{   
    		System.runAs(TEST_USER)
    		{ 	
    		// Insert out test inputs, sans Service__c records.
    		insert toInsert;
    		}
    	} 
    	catch(Exception e)
    	{
    		System.assert(false, '[multi-record update]: Could not insert new records to test update trigger functionality. See the testInsert() results to investigate.');
    	}
    	
    	// Re-assign the data that we removed prior to insertion.
    	Integer index = 0;
    	for(TestCase tc : testCases)
    	{
    		tc.input.Service__c = backups[index].Service__c;
    		tc.input.Service__r = backups[index].Service__r;
    		++index;
    	}
    	
    	// Run all cases in an update context.
    	TestCaseResult[] results = runCases(testCases,true);
    	
    	// Assert our test results.
    	assertTests(results,'[multi-record update]');    	
    	    
    }
		
	static void setup()
	{
		TEST_USER = [select Id from User where Id = :UserInfo.getUserId()];
		
		System.runAs(TEST_USER)
		{
		
		// Set up the queues we will use.
		//
		Group[] queues = new Group[]
		{
			new Group(
				Name='DEFAULT_NAME',
				DeveloperName='SetupUserAccountCaseTrigTest_DEFAULT',
				Type='Queue'
			),
			new Group(
				Name='VALID_0_NAME',
				DeveloperName='SetupUserAccountCaseTrigTest_VALID_0',
				Type='Queue'
			),
			new Group(
				Name='VALID_1_NAME',
				DeveloperName='SetupUserAccountCaseTrigTest_VALID_1',
				Type='Queue'
			),
			new Group(
				Name='NOT_ENABLED_NAME',
				DeveloperName='SetupUserAccountCaseTrigTest_NOT_ENABLED',
				Type='Queue'
			)
		}; 		
		
		// Create Case teams
		//
		CaseTeamTemplate[] caseTeams = new CaseTeamTemplate[]
		{
			new CaseTeamTemplate(Name='SetupUserAccountCaseTrigTest_DEFAULT'),
			new CaseTeamTemplate(Name='SetupUserAccountCaseTrigTest_VALID_0'),
			new CaseTeamTemplate(Name='SetupUserAccountCaseTrigTest_VALID_1')
		}; 
		
		// Create Services
		//
		Service__c[] services = new Service__c[]{
			new Service__c(
				Name='SetupUserAccountCaseTrigTest_DEFAULT',
				Provisioning_Queue__c=queues[0].DeveloperName,
				Pre_Defined_Case_Team__c=caseTeams[0].Name
			),
			new Service__c(
				Name='SetupUserAccountCaseTrigTest_VALID_0',
				Provisioning_Queue__c=queues[1].DeveloperName,
				Pre_Defined_Case_Team__c=caseTeams[1].Name
			),
			new Service__c(
				Name='SetupUserAccountCaseTrigTest_VALID_1',
				Provisioning_Queue__c=queues[2].DeveloperName,
				Pre_Defined_Case_Team__c=caseTeams[2].Name
			),
			new Service__c(
				Name='SetupUserAccountCaseTrigTest_QUEUE_NOT_ENABLED',
				Provisioning_Queue__c=queues[3].DeveloperName,
				Pre_Defined_Case_Team__c=caseTeams[0].Name
			),			
			new Service__c(
				Name='SetupUserAccountCaseTrigTest_NO_QUEUE',
				Provisioning_Queue__c=null,
				Pre_Defined_Case_Team__c=caseTeams[0].Name
			),
			new Service__c(
				Name='SetupUserAccountCaseTrigTest_NO_CASE_TEAM',
				Provisioning_Queue__c=queues[0].DeveloperName,
				Pre_Defined_Case_Team__c=null
			),
			new Service__c(
				Name='SetupUserAccountCaseTrigTest_NO_QUEUE_NO_CASE_TEAM',
				Provisioning_Queue__c=null,
				Pre_Defined_Case_Team__c=null
			),
			new Service__c(
				Name='SetupUserAccountCaseTrigTest_BAD_QUEUE_NAME',
				Provisioning_Queue__c='BAD_NAME',
				Pre_Defined_Case_Team__c=caseTeams[0].Name
			),
			new Service__c(
				Name='SetupUserAccountCaseTrigTest_WRONG_QUEUE_NAME',
				Provisioning_Queue__c=queues[0].Name,
				Pre_Defined_Case_Team__c=caseTeams[0].Name
			),
			new Service__c(
				Name='SetupUserAccountCaseTrigTest_BAD_CASE_TEAM_NAME',
				Provisioning_Queue__c=queues[0].DeveloperName,
				Pre_Defined_Case_Team__c='BAD_NAME'
			)
		};
		
		// Create a default Account.
		Account defaultAccount = new Account(Name='SetupUserAccountCaseTrigTest_DEFAULT');
				
		// Insert all of our first-order objects.
		//
		sObject[] firstOrder = new sObject[]{};		
		firstOrder.addAll((List<sObject>)queues);
		firstOrder.addAll((List<sObject>)caseTeams);
		firstOrder.addAll((List<sObject>)services);
		firstOrder.add((sObject)defaultAccount);		
		insert firstOrder;	
				
		
		// Enable certain queues for use with User_Account_Case__c objects
		//
		QueueSObject[] queueEnablers = new QueueSObject[]{
			new QueueSObject(QueueId=queues[0].Id,SObjectType='User_Account_Case__c'),
			new QueueSObject(QueueId=queues[1].Id,SObjectType='User_Account_Case__c'),
			new QueueSObject(QueueId=queues[2].Id,SObjectType='User_Account_Case__c')
		};
		
		// Create a default Contact to represent the employee 
		// for our default Case.
		Contact defaultContact = new Contact(
			AccountId=defaultAccount.Id,
			LastName='SetupUserAccountCaseTrigTest_DEFAULT'
		);
		
		// Insert our second-order objects.
		//
		sObject[] secondOrder = new sObject[]{};
		secondOrder.addAll((List<sObject>)queueEnablers);
		secondOrder.add((sObject)defaultContact);		
		insert secondOrder;
		
		
		// Create and insert our default Case.
		CASES = new Case[]
		{
			new Case(
				Due_Date__c=Date.today().addDays(7),
				prEmployee__c=defaultContact.Id
			),
			new Case(
				Due_Date__c=Date.today().addDays(7),
				prEmployee__c=defaultContact.Id
			),
			new Case(
				Due_Date__c=Date.today().addDays(7),
				prEmployee__c=defaultContact.Id
			),
			new Case(
				Due_Date__c=Date.today().addDays(7),
				prEmployee__c=defaultContact.Id
			),
			new Case(
				Due_Date__c=Date.today().addDays(7),
				prEmployee__c=defaultContact.Id
			),
			new Case(
				Due_Date__c=Date.today().addDays(7),
				prEmployee__c=defaultContact.Id
			),
			new Case(
				Due_Date__c=Date.today().addDays(7),
				prEmployee__c=defaultContact.Id
			),
			new Case(
				Due_Date__c=Date.today().addDays(7),
				prEmployee__c=defaultContact.Id
			),
			new Case(
				Due_Date__c=Date.today().addDays(7),
				prEmployee__c=defaultContact.Id
			),
			new Case(
				Due_Date__c=Date.today().addDays(7),
				prEmployee__c=defaultContact.Id
			),
			new Case(
				Due_Date__c=Date.today().addDays(7),
				prEmployee__c=defaultContact.Id
			)			
		};
		insert CASES; 
		
		// Populate our globals.
				
		QUEUE_DEFAULT     = queues[0];
		QUEUE_VALID_0     = queues[1];
		QUEUE_VALID_1     = queues[2];
		QUEUE_NOT_ENABLED = queues[3];
		
		CASE_TEAM_DEFAULT = caseTeams[0];
		CASE_TEAM_VALID_0 = caseTeams[1];
		CASE_TEAM_VALID_1 = caseTeams[2];
		RELEVANT_CASE_TEAM_IDS = new Set<Id>
		{
			caseTeams[0].Id,
			caseTeams[1].Id,
			caseTeams[2].Id
		};
		
		SERVICE_DEFAULT               = services[0];
		SERVICE_VALID_0               = services[1];
		SERVICE_VALID_1               = services[2];
		SERVICE_QUEUE_NOT_ENABLED     = services[3];
		SERVICE_NO_QUEUE              = services[4];
		SERVICE_NO_CASE_TEAM          = services[5];
		SERVICE_NO_QUEUE_NO_CASE_TEAM = services[6];
		SERVICE_BAD_QUEUE_NAME        = services[7];
		SERVICE_WRONG_QUEUE_NAME      = services[8];
		SERVICE_BAD_CASE_TEAM_NAME    = services[9];	
		
		}	

	}
}