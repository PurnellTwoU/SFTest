public class CompleteUserAccountEventController {
    private final User_Account_Case__c uae;
    private User_Account__c ua;
    
    public CompleteUserAccountEventController (ApexPages.StandardController controller){        
        User_Account_Case__c local_uae = (User_Account_Case__c)controller.getRecord();
        this.uae = [
            SELECT 
                Id, 
                User_Account__c, 
                Employee__c, 
                Service__c, 
                Role__c, 
                Profile__c, 
                Type__c, 
                Status__c, 
                RecordTypeId,
                Business_Role__c,
                Business_Role__r.Service_Role__c,
                Business_Role__r.Service_Profile__c,
                Business_Role__r.Service__c,
                Business_Role__r.Service_Permission_Sets__c,
                Business_Role__r.Service_Packages__c
            FROM User_Account_Case__c 
            WHERE Id = :local_uae.Id];
    }
    
    public User_Account__c getUserAccount(){ 
        if( uae.User_Account__c == null ) {
            Map<Id,Id> Record_Type_Map = new Map<Id,Id>();
            Record_Type_Map.put(NewHireUtil.RECORDTYPE_PROVISIONING_TASK, NewHireUtil.RECORDTYPE_USER_ACCOUNT);/*Provisioning Request*/
            Record_Type_Map.put(NewHireUtil.RECORDTYPE_PROVISIONING_TASK_WITH_PROFILE, NewHireUtil.RECORDTYPE_USER_ACCOUNT_WITH_PROFILE);/*Provisioning Request with Profile*/
            Record_Type_Map.put(NewHireUtil.RECORDTYPE_SALESFORCE_PROVISIONING_TASK, NewHireUtil.RECORDTYPE_SALESFORCE_USER_ACCOUNT);/*Salesforce User Account*/
            ua = new User_Account__c(
                RecordTypeId = Record_Type_Map.get(uae.RecordTypeId), 
                Active__c = true, 
                Contact__c = uae.Employee__c, 
                Service__c = uae.Service__c, 
                Service_Role__c = uae.Business_Role__r.Service_Role__c, 
                Service_Profile__c = uae.Business_Role__r.Service_Profile__c,
                Access_Package__c = uae.Business_Role__c
                );
            return ua;
        }else if( uae.Type__c == NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE ){
            ua = [SELECT 
                    Id, 
                    Active__c, 
                    Contact__c, 
                    Service__c, 
                    Service_User_ID__c, 
                    Service_Username__c, 
                    Service_Role__c, 
                    Service_Profile__c, 
                    Access_Package__c,
                    Link_to_User_Page_in_the_Service__c, 
                    Initial_Password__c 
                FROM User_Account__c 
                WHERE Id = :uae.User_Account__c];
            ua.Active__c = true;
            return ua;
        }else if( uae.Type__c == NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE ){
            ua = [
                SELECT 
                    Id, 
                    Active__c, 
                    Contact__c, 
                    Service__c, 
                    Service_User_ID__c, 
                    Service_Username__c, 
                    Service_Role__c, 
                    Service_Profile__c, 
                    Access_Package__c,
                    Link_to_User_Page_in_the_Service__c, 
                    Initial_Password__c 
                FROM User_Account__c 
                WHERE Id = :uae.User_Account__c];
            ua.Active__c = false;
            return ua;
        }else{
            return null;
        }
    }
    
    public PageReference CompleteRequest(){
        if( ua <> null ){
            try{
                upsert ua;
            } catch (DMLException e) {
                ua.Service_User_ID__c.addError(e);
                return ApexPages.currentPage();
            }
            uae.User_Account__c = ua.Id;
            uae.Status__c = NewHireUtil.ASSET_CASE_STATUS_COMPLETE;
            update uae;
        }
        return new PageReference('/' + uae.Id);
    }  
}