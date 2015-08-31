/**
* Added to NewHire app 4/19/2014
* Requested in SF-6850, per the needs of SF-6693.
*
* Via the CancelAllProvisioning method, this Case controller
* cancels its, along with all of its child User_Account_Case__c 
* and Asset_Case__c records. 

* The need for this action aries when the following happens:
*
* 1. A person is considered for employment.
*
* 2. Using the NewHires app, a provisioning Case is created, along 
*    with User_Account_Case__c and Asset_Case__c records for various
*    resources to be provisioned for the new employee.
*
* 3. The employment process falls through, and it is decided that the
*    person will not be hired after all.
*
* 4. The Case is cancelled.
*
* If Step 4 is performed via standard Case cancellation, the child 
* User_Account_Case__c and Asset_Case__c records are not cancelled.
*
* This controller and its accompanying page (CaseCancelNewHire) can 
* replace a standard "Close Case" button so that when the button is 
* clicked, child records are cancelled in addition the the Case itself.
*
* To use this controller, create acustom button or link to the 
* CaseCancelNewHire page, with the "id" URL parameter set to the Case ID.
* When clicked, the page will perform the aforementioned actions and then 
* forward to the standard Case detail page.
* 
*/
public class CaseCancelNewHireController
{
    
    private ApexPages.StandardController controller;
    
    public CaseCancelNewHireController(ApexPages.StandardController controller)
    {
        this.controller = controller;
    }    
    
    public PageReference CancelAllProvisioning()
    {
    
        // Query the case and its child records.
        //
        Case theCase = [
            select
                Id,
                (select
                    Id,
                    Status__c
                 from User_Accounts_Cases__r
                 where Status__c != :NewHireUtil.USER_ACCOUNT_CASE_STATUS_CANCEL
                   and (Type__c = :NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE
                     or Type__c = :NewHireUtil.USER_ACCOUNT_CASE_TYPE_PROVISION)
                ),
                (select
                    Id,
                    Status__c
                 from Assets_Cases__r
                 where Status__c != :NewHireUtil.ASSET_CASE_STATUS_CANCEL
                   and (Type__c = :NewHireUtil.ASSET_CASE_TYPE_PROVISION
                     or Type__c = :NewHireUtil.ASSET_CASE_TYPE_ACTIVATE)
                )
            from Case
            where Id = :this.controller.getId()
        ];        
        
        theCase.Status = NewHireUtil.CASE_STATUS_CANCEL;
        
        for(User_Account_Case__c uac : theCase.User_Accounts_Cases__r)
        {
            uac.Status__c = NewHireUtil.USER_ACCOUNT_CASE_STATUS_CANCEL;
        }
        
        for(Asset_Case__c ac : theCase.Assets_Cases__r)
        {
            ac.Status__c  = NewHireUtil.ASSET_CASE_STATUS_CANCEL;
        }
        
        List<sObject> toUpdate= new List<sObject>{(sObject)theCase};
        
        toUpdate.addAll((List<sObject>)theCase.User_Accounts_Cases__r);
        toUpdate.addAll((List<sObject>)theCase.Assets_Cases__r);
        
        update toUpdate;
        
        return this.controller.view();
    }
    
}