public class SalesforceClient {
	private final String instance_url; 
	private final String access_token; 
	private final String base_url; 
	private final String custom_base_url;
	private final String version; 

	public SalesforceClient(S2SConnection.Connection conn,String api_version) {
		this.instance_url = conn.instance_url; 
		this.access_token = conn.access_token; 
		this.base_url = this.instance_url + '/services/{0}/v' + api_version + '/{1}{2}'; 
		this.custom_base_url = this.instance_url + '/services/{0}/{1}{2}';
		this.version = api_version;
	}

	public String execute(String namespace,String action,String args,String body,String method,Boolean isCustom){
		if(args == null){
			args = '';
		}

		String url = String.format((isCustom == true ? this.custom_base_url : this.base_url), new String[]{namespace,action,args});
		system.debug(url);
		HttpRequest req = new HttpRequest();
		req.setEndpoint(url);
		req.setMethod(method);
		if(body != null && method != 'GET'){
			req.setBody(body);
		}
		system.debug(req.getBody());
		String auth_header = 'Bearer ' + this.access_token;
		req.setHeader('Authorization',auth_header);
		req.setHeader('Content-Type','application/json; charset=UTF-8');
		req.setHeader('Accept','application/json');
		req.setTimeout(60000);

		//make callout and pass response to connection object
		Http http = new Http(); 
		HttpResponse res = http.send(req); 

		return res.getBody();
	}

	public QueryResponse query(String query){
		String args ='/?q=' + EncodingUtil.urlEncode(query,'UTF-8');
		String query_res = this.execute('data','query',args,null,'GET',false);
		system.debug(query_res);
		return (QueryResponse)JSON.deserialize(query_res,QueryResponse.class);
	}

	public List<DMLResponse> create(List<SObject> obj,String type){
		String args = '/' + type + '/'; 
		String json_body = JSON.serializePretty(obj);
		system.debug('json is ' + json_body);
		String dml_res = this.execute('data','sobjects',args,json_body,'POST',false);
		system.debug(dml_res);
		return (List<DMLResponse>)JSON.deserialize(dml_res,List<DMLResponse>.class);
	}

	public void updatee(SObject obj,String type,Id record_id){
		String args = '/' + type + '/' + record_id + '/?_HttpMethod=PATCH';
		String json_body = JSON.serializePretty(obj);
		String dml_res = this.execute('data','sobjects',args,json_body,'POST',false);
		system.debug(dml_res);
	}

	//method to call a custom defined rest resource - returns a json string that can be easily casted to a salesforce class object
	public String customResource(String body,String namespace,String action,String args,String method){
		String resp = this.execute(namespace,action,null,body,method,true);
		return resp; 
	}

	public class DMLResponse {
		public String id; 
		public List<Database.Error> errors;
		public String success; 

		public DMLResponse() {}
	}

	public class QueryResponse {
		public List<SObject> records; 
		public String totalSize; 

		public QueryResponse(){}
	}
}