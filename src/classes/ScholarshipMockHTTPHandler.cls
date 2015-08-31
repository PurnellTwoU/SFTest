@isTest
global class ScholarshipMockHTTPHandler implements HttpCalloutMock{
	private final String type; 
	private List<Database.SaveResult> dml_result; 
	private Map<String,Id> ids; 
	/* Mock HTTP Callout constructor, used to keep logic in one mock class, but handle multiple callout types */
	global ScholarshipMockHTTPHandler(String type,List<Database.SaveResult> dml_result,Map<String,Id> ids){
		this.type = type; 
		this.dml_result = dml_result;
		this.ids = ids; 
	}

	global HTTPResponse respond(HTTPRequest req) {
		//if the endpoint contains oauth2 it's looking to authenticate
		if(req.getEndpoint().contains('oauth2')){
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type','application/json');
			Connection conn = new Connection('abcd1234','01/01/2014','https://na4.salesforce.com','signature1234','abcd_1234');
			res.setBody(json.serialize(conn));
			return res; 
		}
		//otherwise it is looking to do some sync action
		else{
			HTTPResponse res = new HttpResponse();
			res.setHeader('Content-Type','application/json');
			ScholarshipResponse sres; 
			//sets up for the create sync handler
			if(type == 'create'){
				sres = new ScholarshipResponse(200,this.ids,this.dml_result,'Scholarship create was initiated successfully, view results for specific dml results.',null);
			}
			//sets up for the update sync handler
			else if(type == 'update'){
				sres = new ScholarshipResponse(200,null,this.dml_result,'Scholarship create was initiated successfully, view results for specific dml results.',null);
			}
			//sets up to test bad response
			else if(type == 'fail'){
				//generate us a nifty little exception object 
				try{
					Integer x = 0/0;
				}catch(Exception e){
					sres = new ScholarshipResponse(404,null,null, 'test error',e);
				}
			}			
			res.setBody(JSON.serialize(sres));
			res.setStatusCode(200);
			return res; 
		}
	}

	global class ScholarshipResponse {
        public Integer status_code; 
        public String message; 
        public Map<String,Id> ids; 
        public String stack_trace; 
        public String error; 
        public List<Database.SaveResult> results; 

        public ScholarshipResponse(Integer status_code,Map<String,Id> ids,List<Database.SaveResult> results,String message,Exception ex){
            this.status_code = status_code;
            this.results = results; 
            this.message = message; 
            this.ids = ids;
            if(ex != null){
                this.stack_trace = ex.getStackTraceString(); 
                this.error = ex.getMessage(); 
            }
        }
    }

    private class Connection {
		private String id; 
		private String issued_at; 
		private String instance_url; 
		private String signature; 
		private String access_token; 

		private Connection(String id,String issued_at,String instance_url,String signature,String access_token){
			this.id = id; 
			this.issued_at = issued_at; 
			this.instance_url = instance_url; 
			this.signature = signature; 
			this.access_token = access_token; 
		}


	}

}