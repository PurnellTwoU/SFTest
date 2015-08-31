/**
@ name          SFConnectionController
@ author        Aslam Bari
@ date          17 July, 2011
@ description   contains the main methods like
                1) login: to login the remote sfdc instance
                2) query: after login fire the query to remote sfdc instance
*/
public class SFConnectionController{
    private boolean isApexTest = false;
    public SFConnectionController(){
        if(Test.isRunningTest()){
            isApexTest = true;
        }
    }
    public Response sendRequest(string url, string header, string body){
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        req.setMethod('POST');
        req.setEndPoint(url); 
        req.setHeader('Content-type','text/xml');
        req.setHeader('SoapAction',header);
        req.setBody(body);
        Response responseData = new Response();
        if (!isApexTest){
             res = h.send(req);
             responseData.result = res.getBody();
             responseData.status=res.getStatus();
             responseData.statusCode=res.getStatusCode();
        }else{
             // A test is running
             responseData.result = '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns="urn:partner.soap.sforce.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soapenv:Body><loginResponse><result><metadataServerUrl>https://ap1-api.salesforce.com/services/Soap/m/21.0/00D90000000YYpr</metadataServerUrl><passwordExpired>false</passwordExpired><sandbox>false</sandbox><serverUrl>https://ap1-api.salesforce.com/services/Soap/u/21.0/00D90000000YYpr</serverUrl><sessionId>00D90000000YYpr!AQkAQGItxGayPzRLb3g2z96MsVuJnidnW2fZAUpNEKcq_i5tjmV_oj.eZZHn90l0A9PbZtgvuTIVUlahKDPYqgXuhR5Y9Md4</sessionId><userId>00590000000KRhTAAW</userId><userInfo><accessibilityMode>false</accessibilityMode><currencySymbol>$</currencySymbol><orgAttachmentFileSizeLimit>5242880</orgAttachmentFileSizeLimit><orgDefaultCurrencyIsoCode>USD</orgDefaultCurrencyIsoCode><orgDisallowHtmlAttachments>false</orgDisallowHtmlAttachments><orgHasPersonAccounts>false</orgHasPersonAccounts><organizationId>00D90000000YYprEAG</organizationId><organizationMultiCurrency>false</organizationMultiCurrency><organizationName>Angel</organizationName><profileId>00e90000000ooA1AAI</profileId><roleId xsi:nil="true"/><sessionSecondsValid>7200</sessionSecondsValid><userDefaultCurrencyIsoCode xsi:nil="true"/><userEmail>shivamsing@gmail.com</userEmail><userFullName>shivam singh</userFullName><userId>00590000000KRhTAAW</userId><userLanguage>en_US</userLanguage><userLocale>en_US</userLocale><userName>sameer.sites@angel.com</userName><userTimeZone>America/Los_Angeles</userTimeZone><userType>Standard</userType><userUiSkin>Theme3</userUiSkin></userInfo></result></loginResponse></soapenv:Body></soapenv:Envelope>';
             responseData.status='OK';
             responseData.statusCode=200;
        }       
        return responseData;
    }
    public LoginResult login(string username, string password, string securityToken){
        LoginResult loginResult = new LoginResult();
        try {            
            Response loginResponse = sendRequest(SFConnectionUtility.PRODUCTION_URL,
                                                 SFConnectionUtility.getLoginSoapAction(), 
                                                 SFConnectionUtility.getLoginSoapBody(username, password, securityToken));
            if(loginResponse.status == 'OK' & loginResponse.statusCode == 200){
                  loginResult.sessionId = loginResponse.result.substring(loginResponse.result.indexOf('<sessionId>')+11, loginResponse.result.indexOf('</sessionId>'));
                  loginResult.serverUrl = loginResponse.result.substring(loginResponse.result.indexOf('<serverUrl>')+11, loginResponse.result.indexOf('</serverUrl>'));
                  if(loginResult.sessionId != null && loginResult.serverUrl != null){
                     loginResult.isError = false;
                  }
            }
            else{
              loginResult.isError = true;
              loginResult.message = 'Login Failed';
            }
        }
        catch(Exception ex){
           loginResult.isError = true;
           loginResult.message = ex.getMessage();
        }
        return loginResult;
    }
    
    public Response query(string query, LoginResult loginResult){
        Response queryResponse = new Response();
        try{
            queryResponse = sendRequest(loginResult.serverUrl,
                                        SFConnectionUtility.getQuerySoapAction(loginResult.sessionId),
                                        SFConnectionUtility.getQuerySoapBody(loginResult.sessionId, query));
            string AngelXML='';
            if(queryResponse.status == 'OK' && queryResponse.statusCode == 200){
                queryResponse.isError = false;
                string str=String.ValueOf(queryResponse.result);
                str=str.replace('sf:','');                        
                str=str.replace(':','');    
                str=str.replace('<?xml version="1.0" encoding="UTF-8"?>',''); 
                SFXmlParser parser = new SFXmlParser();
                queryResponse.data = parser.parseXml(str, SFConnectionUtility.getFields(query));
                system.debug('####### ' + queryResponse.data);               
            }else{
              queryResponse.isError = true;
              queryResponse.message = 'Query Failed';
            }            
        }catch(Exception ex){
           queryResponse.isError = true;
           queryResponse.message = ex.getMessage();
        }
        
        return queryResponse;
    }
}