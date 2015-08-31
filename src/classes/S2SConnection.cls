public class S2SConnection {
	private final String SANDBOX_URL = 'https://test.salesforce.com/services/oauth2/token';
	private final String PRODUCTION_URL = 'https://login.salesforce.com/services/oauth2/token';

	public Connection conn; 

	/****************************************
		Any API authentication using the username/password flow, not OAuth should utilize the 
		methods included in this class, to enforce security as a best practice. 

	*****************************************/

	//constructor to take program name and env bool and retrieve auth creds from custom setting
	public S2SConnection(String program,Boolean isProduction) {
		OAuth_Credential__c creds = [SELECT Username__c
												 ,Password__c
												 ,Consumer_Secret__c
												 ,Consumer_Key__c
												 ,Endpoint__c 
										   FROM OAuth_Credential__c
										   WHERE Name = :program]; 
		this.conn = this.authenticate(creds.Username__c,creds.Password__c,creds.Consumer_Key__c,creds.Consumer_Secret__c,isProduction);
	}

	public S2SConnection(String username,String password,String consumer_key,String consumer_secret,Boolean isProduction){
		this.conn = this.authenticate(username,password,consumer_key,consumer_secret,isProduction);
	}

	private Connection authenticate(String username,String password,String consumer_key,String consumer_secret,Boolean isProduction){
		//base request string 
		String request_body = 'grant_type=password&client_id={0}&client_secret={1}&username={2}&password={3}';
		String target = (isProduction == true ? PRODUCTION_URL : SANDBOX_URL);
		
		//structure request 
		HttpRequest req = new HttpRequest(); 
		req.setEndpoint(target);
		req.setMethod('POST');
		Blob header = Blob.valueOf(username + ':' + password);
		String auth_header = 'BASIC ' + EncodingUtil.base64Encode(header);
		req.setHeader('Authorization',auth_header);
		req.setBody(String.format(request_body,new String[]{consumer_key,consumer_secret,username,password})); 
		req.setTimeout(60000);

		//make callout and pass response to connection object
		Http http = new Http(); 
		HttpResponse res = http.send(req); 

		//case the json into a connection object
		system.debug(res.getBody());
		return (Connection)JSON.deserialize(res.getBody(),Connection.class);
	}

	public class Connection {
		public String id; 
		public String issued_at; 
		public String instance_url; 
		public String signature; 
		public String access_token; 

		public Connection() {}
	}
}