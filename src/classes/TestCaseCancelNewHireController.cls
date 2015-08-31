@isTest
public class TestCaseCancelNewHireController
{

    public static string rndStr()
    {
        return 'TestCCNHC'+Math.random();
    }

    @isTest
    public static void testCancelAllProvisioning()
    {
       Case testCase = new Case(
           Subject              = rndStr(),
           Due_Date__c          = System.today().addDays(10),
           prFirst_Name__c      = rndStr(),
           prLastName__c        = rndStr(),
           prPersonal_Email__c  = rndStr()+'@example.com'
       );
       Case unrelatedCase = testCase.clone();
       
        
       insert new Case[]
       {
           testCase, 
           unrelatedCase
       };
       
       //
       // User_Account_Case__c records
       //
       ////////////////////////////////////////////
 
       // Should be updated
       //
       
       User_Account_Case__c uacActivate  = new User_Account_Case__c(
                Case__c   = testCase.Id,
                Status__c = rndStr(),
                Type__c   = NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE 
            );
            
       User_Account_Case__c uacProvision = new User_Account_Case__c(
                Case__c   = testCase.Id,
                Status__c = rndStr(),
                Type__c   = NewHireUtil.USER_ACCOUNT_CASE_TYPE_PROVISION
            );
            
       // Should not be updated.
       //
       
       User_Account_Case__c uacActivateCanceled  = uacActivate.clone();
       uacActivateCanceled.Status__c = NewHireUtil.USER_ACCOUNT_CASE_STATUS_CANCEL;
            
       User_Account_Case__c uacProvisionCanceled = uacProvision.clone();
       uacProvisionCanceled.Status__c = NewHireUtil.USER_ACCOUNT_CASE_STATUS_CANCEL;
       
       User_Account_Case__c uacActivateUnrelated  = uacActivate.clone();
       uacActivateUnrelated.Case__c    = unrelatedCase.Id;
            
       User_Account_Case__c uacProvisionUnrelated = uacProvision.clone();
       uacProvisionUnrelated.Case__c   = unrelatedCase.Id;
       
       
       //
       // Asset_Case__c records
       //
       ////////////////////////////////////////////
       
       // Should be updated
       //
       
       Asset_Case__c acActivate  = new Asset_Case__c (
                Case__c   = testCase.Id,
                Status__c = rndStr(),
                Type__c   = NewHireUtil.ASSET_CASE_TYPE_ACTIVATE 
            );
            
       Asset_Case__c acProvision = new Asset_Case__c (
                Case__c   = testCase.Id,
                Status__c = rndStr(),
                Type__c   = NewHireUtil.ASSET_CASE_TYPE_PROVISION
            );
            
       // Should not be updated.
       //
       
       Asset_Case__c acActivateCanceled   = acActivate.clone();
       acActivateCanceled.Status__c = NewHireUtil.ASSET_CASE_STATUS_CANCEL;
            
       Asset_Case__c acProvisionCanceled  = acProvision.clone();
       acProvisionCanceled.Status__c = NewHireUtil.ASSET_CASE_STATUS_CANCEL;
       
       Asset_Case__c acActivateUnrelated  = acActivate.clone();
       acActivateUnrelated.Case__c    = unrelatedCase.Id;
            
       Asset_Case__c acProvisionUnrelated = acProvision.clone();
       acProvisionUnrelated.Case__c   = unrelatedCase.Id;
       
       // Insert User_Account_Case__c records and collect their Ids
       //
       User_Account_Case__c[] uacList = new User_Account_Case__c[]
       {
           uacActivate,
           uacProvision,
           uacActivateCanceled,
           uacProvisionCanceled,
           uacActivateUnrelated,
           uacProvisionUnrelated
       };
       insert uacList;
       Set<Id> uacIds = new Set<Id>();
       for(User_Account_Case__c uac : uacList) { uacIds.add(uac.Id); }
       
       
       // Insert Asset_Case__c records and collect their Ids
       //
       Asset_Case__c[] acList = new Asset_Case__c[]
       {    
           acActivate,
           acProvision,
           acActivateCanceled,
           acProvisionCanceled,
           acActivateUnrelated,
           acProvisionUnrelated
       };
       insert acList;
       Set<Id> acIds = new Set<Id>();
       for(Asset_Case__c ac : acList) { acIds.add(ac.Id); }
       
       
       // Do the test
       //
       ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
       CaseCancelNewHireController testController = new CaseCancelNewHireController(stdController);
       PageReference result = testController.cancelAllProvisioning();
       
       System.assertEquals(
           stdController.view().getUrl(), result.getUrl(), 
           'Controller did not return a reference to the Case\'s standard detail page.'
       );
       
       // Pull the Case result.
       //
       Case testCaseAfter = [
           select 
               Id, 
               Status,
               IsClosed
           from Case where id = :testCase.Id
       ];
       
       // Pull the User_Account_Case__c results.
       //
       Map<Id, User_Account_Case__c> uacNewMap = new Map<Id, User_Account_Case__c>([
           select
               Id, 
               Status__c
           from User_Account_Case__c
           where Id in :uacIds
       ]);
       
       // Pull the Asset_Case__c results.
       //
       Map<Id, Asset_Case__c> acNewMap = new Map<Id, Asset_Case__c>([
           select
               Id, 
               Status__c
           from Asset_Case__c
           where Id in :acIds
       ]);
       
       
       // Test the Case record.
       //
       System.assertEquals(
           NewHireUtil.CASE_STATUS_CANCEL,
           testCaseAfter.Status,
           'Wrong status on the Case.'
       );
       
       System.assertEquals(
           true,
           testCaseAfter.IsClosed,
           'The controller did not close the Case.'
       );
       
       // Test User_Account_Case__c records which should be updated
       //
       
       System.assertEquals(
           NewHireUtil.USER_ACCOUNT_CASE_STATUS_CANCEL,
           uacNewMap.get(uacActivate.Id).Status__c,
           'Wrong status for a User_Account_Case__c with Type__c=NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE'
       );
       
       System.assertEquals(
           NewHireUtil.USER_ACCOUNT_CASE_STATUS_CANCEL,
           uacNewMap.get(uacProvision.Id).Status__c,
           'Wrong status for a User_Account_Case__c with Type__c=NewHireUtil.USER_ACCOUNT_CASE_TYPE_PROVISION'
       );
       
           
       // Test User_Account_Case__c records which should not be updated
       //
       
       System.assertEquals(
           uacActivateCanceled.Status__c,
           uacNewMap.get(uacActivateCanceled.Id).Status__c,
           'Erroneously changed the Status of an already canceled User_Account_Case__c with Type__c = NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE.'
       );
       
       System.assertEquals(
           uacProvisionCanceled.Status__c,
           uacNewMap.get(uacProvisionCanceled.Id).Status__c,
           'Erroneously changed the Status of an already canceled User_Account_Case__c with Type__c = NewHireUtil.USER_ACCOUNT_CASE_TYPE_PROVISION.'
       );
       
       System.assertEquals(
           uacActivateUnrelated.Status__c,
           uacNewMap.get(uacActivateUnrelated.Id).Status__c,
           'Erroneously changed the Status of an unrelated User_Account_Case__c with Type__c = NewHireUtil.USER_ACCOUNT_CASE_ACTIVATE.'
       );
       
       System.assertEquals(
           uacProvisionUnrelated.Status__c,
           uacNewMap.get(uacProvisionUnrelated.Id).Status__c,
           'Erroneously changed the Status of an unrealted User_Account_Case__c with Type__c = NewHireUtil.USER_ACCOUNT_CASE_TYPE_PROVISION.'
       );
              
       // Test Asset_Case__c records which should be updated
       //
       
       System.assertEquals(
           NewHireUtil.ASSET_CASE_STATUS_CANCEL,
           acNewMap.get(acActivate.Id).Status__c,
           'Wrong status for a Asset_Case__c with Type__c=NewHireUtil.ASSET_CASE_TYPE_ACTIVATE'
       );
       
       System.assertEquals(
           NewHireUtil.ASSET_CASE_STATUS_CANCEL,
           acNewMap.get(acProvision.Id).Status__c,
           'Wrong status for a Asset_Case__c with Type__c=NewHireUtil.ASSET_CASE_TYPE_PROVISION'
       );
       
           
       // Test Asset_Case__c records which should not be updated
       //
       
       System.assertEquals(
           acActivateCanceled.Status__c,
           acNewMap.get(acActivateCanceled.Id).Status__c,
           'Erroneously changed the Status of an already canceled Asset_Case__c with Type__c = NewHireUtil.ASSET_CASE_TYPE_ACTIVATE.'
       );
       
       System.assertEquals(
           acProvisionCanceled.Status__c,
           acNewMap.get(acProvisionCanceled.Id).Status__c,
           'Erroneously changed the Status of an already canceled Asset_Case__c with Type__c = NewHireUtil.ASSET_CASE_TYPE_PROVISION.'
       );
       
       System.assertEquals(
           acActivateUnrelated.Status__c,
           acNewMap.get(acActivateUnrelated.Id).Status__c,
           'Erroneously changed the Status of an unrelated Asset_Case__c  with Type__c = NewHireUtil.ASSET_CASE_TYPE_ACTIVATE.'
       );
       
       System.assertEquals(
           acProvisionUnrelated.Status__c,
           acNewMap.get(acProvisionUnrelated.Id).Status__c,
           'Erroneously changed the Status of an unrealted Asset_Case__c with Type__c = NewHireUtil.ASSET_CASE_TYPE_PROVISION.'
       );
       
  
    }
}