@RestResource(urlMapping='/AutoProvision/*')
global class AutoProvision {
    @HttpPost
	global static APResponse doPost(APRequest request) {
        try{
            Case c = [SELECT prEmployee__r.Email FROM Case WHERE Id = :request.case_id];
            system.debug('email for employee' + c.prEmployee__r.Email);
            if(c.prEmployee__r.Email != '' && c.prEmployee__r.Email != null){
                Contact con = [SELECT Id,(SELECT Service__r.Id, Id from UserAccounts__r where service__r.recordtype.name='Salesforce Org' and  Service__r.Domain__c = :request.domain ) from contact where email = :c.prEmployee__r.Email];
                if(!(con.UserAccounts__r).isEmpty()){
                    Id service_id = con.UserAccounts__r[0].service__r.Id;
                    Id ua_id = con.UserAccounts__r[0].Id;
                    User_Account_Case__c  uav = new User_Account_Case__c(Case__c=request.case_id, Employee__c=con.Id, Service__c=service_id, User_Account__c=ua_id, Status__c='Open', Type__c='Activate');
                    Database.SaveResult sr = Database.insert(uav);
                    return new APResponse(200, 'User Account Event Created Successfully', sr);
                }
                else{
                    LogUtil.log('AutoProvision.doPost', 'User account not found', new List<String>{request.case_id});
                    return new APResponse(200, 'User account not found');
                }
            }
            else{
                system.debug('in here at 22');
                LogUtil.log('AutoProvision.doPost', 'Case contact has no email address', new List<String>{request.case_id});
                return new APResponse(200, 'Case contact has no email address');
            }
        } catch(Exception e){
            LogUtil.log('AutoProvision.doPost', e, new List<String>{request.case_id}, '');
            return new APResponse(505, e.getMessage());
        }
	}

    global class APRequest {
        global String domain;
        global Id case_id;

        global APRequest(String domain, Id case_id){
            this.domain = domain;
            this.case_id = case_id;
        }
    }

    global class APResponse {
        global Integer status_code;
        global String message;
        global Id new_id;

        global APResponse(Integer sc, String message, Database.SaveResult sr){
            this.status_code = sc;
            this.new_id = sr.getId();
        }
        global APResponse(Integer sc, String message){
            this.status_code = sc;
            this.message = message;
        }
    }
}