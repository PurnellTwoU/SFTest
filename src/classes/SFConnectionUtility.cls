/**
@ name          SFConnectionUtility
@ author        Aslam Bari
@ date          17 July, 2011
@ description   contains some utility methods for soap related requests
*/
public class SFConnectionUtility{
    public static string PRODUCTION_URL = 'https://login.salesforce.com/services/Soap/u/21.0';
    
    public static string getLoginSoapAction(){
        return '<se:Header xmlns:sfns=\'partner.soap.sforce.com\'><sfns:CallOptions><sfns:client></sfns:client></sfns:CallOptions><sfns:SessionHeader><sessionId></sessionId></sfns:SessionHeader></se:Header>';
    }
    
    public static string getQuerySoapAction(string sessionId){
        return '<soapenv:Envelope xmlns:soapenv=\'http://schemas.xmlsoap.org/soap/envelope/\' xmlns:urn=\'urn:partner.soap.sforce.com\' xmlns:urn1=\'urn:sobject.partner.soap.sforce.com\'><soapenv:Header><urn:SessionHeader><urn:sessionId>'+sessionId+'</urn:sessionId><urn:CallOptions></urn:CallOptions></soapenv:Header></soapenv:Envelope>';
    }
    
    public static string getLoginSoapBody(string username, string password, string securityToken){
        return '<se:Envelope xmlns:sfdc=\'urn:enterprise.soap.sforce.com\' xmlns:se=\'http://schemas.xmlsoap.org/soap/envelope/\'><se:Body><login xmlns=\'urn:partner.soap.sforce.com\' xmlns:ns1=\'sobject.partner.soap.sforce.com\'><username>'+username+'</username><password>'+password+securityToken+'</password></login></se:Body></se:Envelope>';
    }
    
    public static string getQuerySoapBody(string sessionId, string query){
        return '<se:Envelope xmlns:sfdc=\'urn:partner.soap.sforce.com\' xmlns:se=\'http://schemas.xmlsoap.org/soap/envelope/\'><se:Header><SessionHeader xmlns=\'urn:partner.soap.sforce.com\'><sessionId>' +
               sessionId +
               '</sessionId></SessionHeader></se:Header><se:Body><query xmlns=\'urn:partner.soap.sforce.com\'><queryString>' + 
               query + 
               '</queryString></query></se:Body></se:Envelope>';
    }
    
    public static set<string> getFields(string query){
        set<string> fields = new set<string>();
        query = query.tolowercase();
        integer selectidx = query.indexOf('select');
        if(selectidx >=0 ){
            integer frmIdx = query.indexOf(' from ', selectidx + 6);
            if(frmIdx > selectidx){
                string fieldStr = query.substring(selectidx + 6, frmIdx);
                for(string fld: fieldStr.split(',')){
                    if(fld.trim().length() > 0){
                        fields.add(fld.trim());
                    }
                }
            }
        }
        return fields;
    }
}