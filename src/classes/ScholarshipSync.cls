public class ScholarshipSync {
	public static Boolean recurse_execution = false; 

	public static void handlerCreatedScholarships(List<Campaign> new_scholarships){
		//just in case we ever need to avoid executing this guy 
		if(!recurse_execution){
			//get all custom settings, equate to active spoke orgs
			Map<String,Scholarship_Sync__c> ss_settings = Scholarship_Sync__c.getAll(); 
			Map<String,List<Id>> new_recs_by_program = new Map<String,List<Id>>(); 
			for(Campaign c : new_scholarships){
				if(ss_settings.containsKey(c.Degree_Program__c)){
					//if the degree program is a custom setting key, it is an active sync candidate 
					if(!new_recs_by_program.containsKey(c.Degree_Program__c)){
						new_recs_by_program.put(c.Degree_Program__c,new List<Id>());
					}
					new_recs_by_program.get(c.Degree_Program__c).add(c.Id);
				}
			}
			//for each program generate async string to process 
			if(!System.isFuture() && !System.isBatch()){
				for(String pn : new_recs_by_program.keySet()){
					createScholarships(pn,new_recs_by_program.get(pn));
				}
			}
		}
	}

	public static void handlerUpdatedScholarships(List<Campaign> updated_scholarships){
		//protect from recursive call 
		if(!recurse_execution){
			//get all custom settings, equate to active spoke orgs
			Map<String,Scholarship_Sync__c> ss_settings = Scholarship_Sync__c.getAll(); 
			Map<String,List<Id>> new_recs_by_program = new Map<String,List<Id>>(); 
			for(Campaign c : updated_scholarships){
				//if the campaign has no spoke id, next 
				if(c.Program_Scholarship_Campaign_Id__c != null){
					//if the degree program is a custom setting key, it is an active sync candidate 
					if(ss_settings.containsKey(c.Degree_Program__c) && !new_recs_by_program.containsKey(c.Degree_Program__c)){
						new_recs_by_program.put(c.Degree_Program__c,new List<Id>());
					}
					new_recs_by_program.get(c.Degree_Program__c).add(c.Id);
				}
			}

			//for each program generate async string to process 
			if(!System.isFuture() && !System.isBatch()){
				for(String pn : new_recs_by_program.keySet()){
					updateScholarships(pn,new_recs_by_program.get(pn));
				}
			}
		}
	}

	@future(callout=true)
	public static void createScholarships(String program_name, List<Id> new_scholarships){
		//authenticate to spoke org rest api - uses username/password flow - credentials securely stored in SObject 
		S2SConnection connection = new S2SConnection(program_name,true);
		SalesforceClient client = new SalesforceClient(connection.conn,'27.0');
		
		//generate and execute dynamic query from field set 
		String query = GlobalUtil.soqlFromFieldSet('Scholarship','Campaign',' Id IN :new_scholarships'); 
		List<Campaign> scholarships = Database.query(query);
		Map<String,Campaign> scholarship_name_to_id = new Map<String,Campaign>(); 
		
		//generate object to serialize to json with our payload 
		ScholarshipRequest req = new ScholarshipRequest('create',scholarships);
		Map<String,ScholarshipRequest> request = new Map<String,ScholarshipRequest>{'request' => req};
		String json_req = JSON.serialize(request);
		
		//api callout handler and deserialize response into ScholarshipResponse class 
		ScholarshipResponse resp = (ScholarshipResponse)JSON.deserialize(client.customResource(json_req,'apexrest','Scholarships/',null,'POST'),ScholarshipResponse.class);
		system.debug('kc resp is ' + resp);
		//go through scholarship records, and add the returned id
		system.debug('kc ids are ' + resp.ids);
		if(resp.status_code != 200){
			String message = String.format('Message: {0} #### Status Code: {1} #### Error: {2} #### Notes: This error occured during the CreateScholarships method of the Scholarship Sync',new String[]{resp.message,String.valueOf(resp.status_code),resp.error});			
			LogUtil.log('CreateScholarships',message,new_scholarships);
		}
		else{
			system.debug('updatinggg');
			for(Campaign c : scholarships){
				system.debug('kc name is ' + c.Name);
				c.Program_Scholarship_Campaign_Id__c = resp.ids.get(c.Name);
			}
			system.debug('scholarships' + scholarships);
			update scholarships; 

		}
		ScholarshipSync.recurse_execution = true; 
	}

	@future(callout=true)
	public static void updateScholarships(String program_name,List<Id> updated_scholarships){
		//authenticate to spoke org rest api - uses username/password flow - credentials securely stored in SObject 
		S2SConnection connection = new S2SConnection(program_name,true);
		SalesforceClient client = new SalesforceClient(connection.conn,'27.0');
		
		//generate and execute dynamic query from field set 
		String query = GlobalUtil.soqlFromFieldSet('Scholarship','Campaign',' Id IN :updated_scholarships'); 
		List<Campaign> scholarships = Database.query(query);
		Map<String,Campaign> scholarship_name_to_id = new Map<String,Campaign>(); 

		//generate object to serialize to json with our payload 
		ScholarshipRequest req = new ScholarshipRequest('update',scholarships);
		Map<String,ScholarshipRequest> request = new Map<String,ScholarshipRequest>{'request' => req};
		String json_req = JSON.serialize(request);
		
		//api callout handler and deserialize response into ScholarshipResponse class 
		ScholarshipResponse resp = (ScholarshipResponse)JSON.deserialize(client.customResource(json_req,'apexrest','Scholarships/',null,'POST'),ScholarshipResponse.class);
		if(resp.status_code != 200){
			String message = String.format('Message: {0} #### Status Code: {1} #### Error: {2} #### Notes: This error occured during the UpdateScholarships method of the Scholarship Sync',new String[]{resp.message,String.valueOf(resp.status_code),resp.error});
			LogUtil.log('UpdateScholarships',message,updated_scholarships);
		}
		//set recurse flag to true to avoid any chance at recursion
		ScholarshipSync.recurse_execution = true; 
	}

		
	/**********************************************
		Classes to represent the structure of the 
		json sent and recieved, to ease in 
		de/serialization - both are reflected on 
		the custom rest endpoints in spoke orgs
	***********************************************/

	public class ScholarshipRequest {
		public String type; 
		public List<Campaign> records; 

		public ScholarshipRequest(String type,List<Campaign> records){
			this.records = records; 
			this.type = type; 
		}
	}

	public class ScholarshipResponse {
		public Integer status_code; 
		public String message; 
		public String stack_trace;
		public String error;  
		public Map<String,Id> ids;
	}
}