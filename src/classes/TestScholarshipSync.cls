@isTest
public class TestScholarshipSync {
	/*********** reusable objects ****************/
	public static Scholarship_Sync__c program_active = new Scholarship_Sync__c(Name = 'MPH');
	public static OAuth_Credential__c oauth = new OAuth_Credential__c(Name = 'MPH'
															,Username__c = 'testclass@2uapi.com'
															,Password__c = 'my_password'
															,Consumer_Secret__c = 'secret_secret'
															,Consumer_Key__c = 'my_secret_key'
															,Endpoint__c = 'https://login.salesforce.com'
															); 
	public static List<Campaign> new_campaigns = new List<Campaign>{new Campaign(Name = 'test scholarship'
								,Status = 'Active'
								,Degree_Program__c = 'MPH'
								,Fee_Waiver__c = true
								,Scholarship_Amount__c = 12345.14
					)};
	/***********************************************/

	//single scholarship, expecting status 200 response 
	public static testMethod void testSuccessfulSingleInsertSync() {
		insert program_active;
		insert oauth;
		ScholarshipSync.recurse_execution = true; 
		List<Database.SaveResult> dml_results = Database.insert(new_campaigns);
		test.startTest();
		ScholarshipSync.recurse_execution = false; 
		Map<String,Id> id_to_name = new Map<String,Id>{'test scholarship' => '701J0000001X4Qs'};
		Test.setMock(HttpCalloutMock.class,new ScholarshipMockHttpHandler('create',dml_results,id_to_name));
		ScholarshipSync.handlerCreatedScholarships(new_campaigns);
		test.stopTest();
	}

	public static testMethod void testFailureSingleInsertSync() {
		insert program_active;
		insert oauth;
		ScholarshipSync.recurse_execution = true; 
		List<Database.SaveResult> dml_results = Database.insert(new_campaigns);
		test.startTest();
		ScholarshipSync.recurse_execution = false; 
		Map<String,Id> id_to_name = new Map<String,Id>{'test scholarship' => '701J0000001X4Qs'};
		Test.setMock(HttpCalloutMock.class,new ScholarshipMockHttpHandler('fail',dml_results,id_to_name));
		ScholarshipSync.handlerCreatedScholarships(new_campaigns);
		test.stopTest();
	}

	public static testMethod void testFailureSingleUpdateSync() {
		insert program_active;
		insert oauth;
		ScholarshipSync.recurse_execution = true; 
		List<Database.SaveResult> dml_results = Database.insert(new_campaigns);
		test.startTest();
		ScholarshipSync.recurse_execution = false; 
		Map<String,Id> id_to_name = new Map<String,Id>{'test scholarship' => '701J0000001X4Qs'};
		Test.setMock(HttpCalloutMock.class,new ScholarshipMockHttpHandler('fail',dml_results,id_to_name));
		ScholarshipSync.handlerUpdatedScholarships(new_campaigns);
		test.stopTest();
	}

	//single update, expecting status 200 response 
	public static testMethod void testSuccessfulSingleUpdateSync() {
		insert program_active; 
		insert oauth; 
		ScholarshipSync.recurse_execution = true; 
		List<Database.SaveResult> dml_results = Database.insert(new_campaigns); 
		test.startTest();
		Map<String,Id> id_to_name = new Map<String,Id>{'test scholarship' => '701J0000001X4Qs'};
		ScholarshipSync.recurse_execution = false; 
		Test.setMock(HttpCalloutMock.class,new ScholarshipMockHttpHandler('update',dml_results,id_to_name));
		ScholarshipSync.handlerUpdatedScholarships(new_campaigns);
		test.stopTest();
	}

	public static testMethod void testSuccessfulBulkInsertSync() {
		insert program_active;
		insert oauth; 
		ScholarshipSync.recurse_execution = true; 
		for(Integer i = 0; i > 50; i++){
			new_campaigns.add(new Campaign(
											Name = 'test scholarship ' + i
											,Status = 'Active'
											,Fee_Waiver__c = true
											,Degree_Program__c = 'MPH' /*in the future toggle here back and forth between active programs */
											,Scholarship_Amount__c = 12345.13 
										  )
							); 
		}
		List<Database.SaveResult> dml_results = Database.insert(new_campaigns); 
		Map<String,Id> id_to_name = new Map<String,Id>(); 
		for(Campaign c : new_campaigns){
			id_to_name.put(c.Name,c.Id);
		}
		test.startTest(); 
		ScholarshipSync.recurse_execution = false; 
		Test.setMock(HttpCalloutMock.class,new ScholarshipMockHttpHandler('create',dml_results,id_to_name));
		ScholarshipSync.handlerCreatedScholarships(new_campaigns);
		test.stopTest();
	}

	public static testMethod void testSuccessfulBulkUpdateSync() {
		insert program_active;
		insert oauth; 
		ScholarshipSync.recurse_execution = true; 
		for(Integer i = 0; i > 50; i++){
			new_campaigns.add(new Campaign(
											Name = 'test scholarship ' + i
											,Status = 'Active'
											,Fee_Waiver__c = true
											,Degree_Program__c = 'MPH' /*in the future toggle here back and forth between active programs */
											,Scholarship_Amount__c = 12345.13 
											,Program_Scholarship_Campaign_Id__c = String.valueOf(i)
										  )
							); 
		}
		List<Database.SaveResult> dml_results = Database.insert(new_campaigns); 
		test.startTest(); 
		ScholarshipSync.recurse_execution = false; 
		Test.setMock(HttpCalloutMock.class,new ScholarshipMockHttpHandler('update',dml_results,null));
		ScholarshipSync.handlerUpdatedScholarships(new_campaigns);
		test.stopTest();
	}


}