/**
* Test clase for CompleteUserAccountEventController.
*/


public with sharing class CompleteUserAccountEventControllerTest
{
    @isTest
    public static void testNewUserAccount()
    {
        //Setup Records
        Contact testContact = new Contact(
            firstname = 'Testfirst',
            lastname = 'Testlast'
        );
        insert testContact;
        Case testCase = new Case(
                RecordTypeId            = NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
                Origin                  = 'Human Resources Portal'
        );
        insert testCase;
        
        Service__c testService = new Service__c(
                name                    = 'Test Service'
        );
        insert testService;
        
        Service_Role__c testRole = new Service_Role__c(
                name                    = 'Test Role',
                Service__c              = testService.id
        );
        insert testRole;
        
        Service_Profile__c testProfile = new Service_Profile__c(
                name                    = 'Test Profile',
                Service__c              = testService.id
        );
        insert testProfile;
        
        Access_Package__c testAccessPackage = new Access_Package__c(
            Name                        = 'Test Access Package',
            Service__c                  = testService.Id,
            Service_Role__c             = testRole.Id,
            Service_Profile__c          = testProfile.Id
        );        
        insert testAccessPackage;
        
        User_Account_Case__c request = new User_Account_Case__c(
                RecordTypeId            = NewHireUtil.RECORDTYPE_PROVISIONING_TASK,
                Case__c                 = testCase.id,
                Employee__c             = testContact.id,
                Status__c               = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN,
                Type__c                 = NewHireUtil.EMPLOYMENT_STATUS_ACTIVE,
                Service__c              = testService.id,
                Business_Role__c        = testAccessPackage.Id,
                //Role__c                 = testRole.id,
                //Profile__c              = testProfile.id,
                
                Notes__c                = 'Test Notes'
        );
        insert request;
        
        User_Account_Case__c requestPostInsert = [SELECT Id FROM User_Account_Case__c WHERE Id = :request.Id];
        Contact contactPostInsert = [SELECT Id FROM Contact WHERE Id = :testContact.Id];
        
        Test.setCurrentPage(Page.CompleteUserAccountEvent);
        
        // Initialize the controller.
        CompleteUserAccountEventController controller = new CompleteUserAccountEventController(new ApexPages.StandardController(requestPostInsert));
        
        // Run getUserAccount.
        User_Account__c ua = controller.getUserAccount();
        
        // Check Results
        System.assertEquals(ua.Service__c, request.Service__c);
        System.assertEquals(ua.Active__c, true, 'Should have set Active to True');
        System.assertEquals(ua.Contact__c, request.Employee__c, 'User Account Contact field not set properly');
        System.assertEquals(ua.Service_Role__c, testAccessPackage.Service_Role__c, 'User Account Service Role field not set properly');
        System.assertEquals(ua.Service_Profile__c, testAccessPackage.Service_Profile__c, 'User Account Service Profile field not set properly');
        
        //Run CompleteRequst
        PageReference finishPage = controller.CompleteRequest();
        
        //Check Results
        User_Account__c uaPostInsert = [SELECT Id FROM User_Account__c WHERE Id = :ua.Id];
        System.assertEquals(uaPostInsert.Id, ua.Id);
        User_Account_Case__c updatedRequest = [SELECT Id, Status__c, User_Account__c, User_Account__r.Id FROM User_Account_Case__c WHERE Id = :request.Id];
        System.assertEquals(updatedRequest.Status__c, NewHireUtil.ASSET_CASE_STATUS_COMPLETE);
        System.assertEquals(updatedRequest.User_Account__r.Id, ua.Id);

        
    }
    
    @isTest
    public static void testNewDuplicateUserAccount()
    {
        //Setup Records
        Contact testContact = new Contact(
            firstname = 'Testfirst',
            lastname = 'Testlast'
        );
        insert testContact;
        Case testCase = new Case(
                RecordTypeId            = NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
                Origin                  = 'Human Resources Portal'
        );
        insert testCase;
        
        Service__c testService = new Service__c(
                name                    = 'Test Service'
        );
        insert testService;
        
        Service_Role__c testRole = new Service_Role__c(
                name                    = 'Test Role',
                Service__c              = testService.id
        );
        insert testRole;
        
        Service_Profile__c testProfile = new Service_Profile__c(
                name                    = 'Test Profile',
                Service__c              = testService.id
        );
        insert testProfile;
        
        Access_Package__c testAccessPackage = new Access_Package__c(
            Name                        = 'Test Access Package',
            Service__c                  = testService.Id,
            Service_Role__c             = testRole.Id,
            Service_Profile__c          = testProfile.Id
        );        
        insert testAccessPackage;
        
        User_Account_Case__c request = new User_Account_Case__c(
                RecordTypeId            = NewHireUtil.RECORDTYPE_PROVISIONING_TASK,
                Case__c                 = testCase.id,
                Employee__c             = testContact.id,
                Status__c               = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN,
                Type__c                 = NewHireUtil.EMPLOYMENT_STATUS_ACTIVE,
                Service__c              = testService.id,
                //Role__c                 = testRole.id,                
                //Profile__c              = testProfile.id,
                Business_Role__c        = testAccessPackage.Id,
                Notes__c                = 'Test Notes'
        );
        insert request;
        
        User_Account__c testDupeUserAccount = new User_Account__c(
                Active__c               = false,
                Contact__c              = testContact.Id,
                Service__c              = testService.Id,
                RecordTypeId            = NewHireUtil.RECORDTYPE_SALESFORCE_USER_ACCOUNT,
                Service_User_ID__c      = '00Z00000008RJP',
                Service_Username__c     = 'testusername@2u.com.test',
                Service_Role__c         = testRole.Id,
                Service_Profile__c      = testProfile.Id
        );
        insert testDupeUserAccount;
        
        User_Account_Case__c requestPostInsert = [SELECT Id FROM User_Account_Case__c WHERE Id = :request.Id];
        Contact contactPostInsert = [SELECT Id FROM Contact WHERE Id = :testContact.Id];
        
        Test.setCurrentPage(Page.CompleteUserAccountEvent);
        
        // Initialize the controller.
        CompleteUserAccountEventController controller = new CompleteUserAccountEventController(new ApexPages.StandardController(requestPostInsert));
        
        // Run getUserAccount.
        User_Account__c ua = controller.getUserAccount();
        ua.Service_User_ID__c = '00Z00000008RJP';
        
        // Check Results
        System.assertEquals(ua.Service__c, request.Service__c);
        System.assertEquals(ua.Active__c, true, 'Should have set Active to True');
        System.assertEquals(ua.Contact__c, request.Employee__c, 'User Account Contact field not set properly');
        System.assertEquals(ua.Service_Role__c, testAccessPackage.Service_Role__c, 'User Account Service Role field not set properly');
        System.assertEquals(ua.Service_Profile__c, testAccessPackage.Service_Profile__c, 'User Account Service Profile field not set properly');
        
        //Run CompleteRequst
        PageReference finishPage = controller.CompleteRequest();
        
        //Check Results
        //System.assertEquals(finishPage, Page.CompleteUserAccountEvent); 

        
    }
    
    @isTest
    public static void testActivateUserAccount()
    {
        //Setup Records
        Contact testContact = new Contact(
            firstname = 'Testfirst',
            lastname = 'Testlast'
        );
        insert testContact;
        Case testCase = new Case(
                RecordTypeId            = NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
                Origin                  = 'Human Resources Portal'
        );
        insert testCase;
        
        Service__c testService = new Service__c(
                name                    = 'Test Service'
        );
        insert testService;
        
        Service_Role__c testRole = new Service_Role__c(
                name                    = 'Test Role',
                Service__c              = testService.id
        );
        insert testRole;
        
        Service_Profile__c testProfile = new Service_Profile__c(
                name                    = 'Test Profile',
                Service__c              = testService.id
        );
        insert testProfile;
        
        Access_Package__c testAccessPackage = new Access_Package__c(
            Name                        = 'Test Access Package',
            Service__c                  = testService.Id,
            Service_Role__c             = testRole.Id,
            Service_Profile__c          = testProfile.Id
        );        
        insert testAccessPackage;
        
        User_Account__c testUserAccount = new User_Account__c(
                Active__c               = false,
                Contact__c              = testContact.Id,
                Service__c              = testService.Id,
                RecordTypeId            = NewHireUtil.RECORDTYPE_SALESFORCE_USER_ACCOUNT,
                Service_User_ID__c      = '00Z00000008RJP',
                Service_Username__c     = 'testusername@2u.com.test',
                Service_Role__c         = testRole.Id,
                Service_Profile__c      = testProfile.Id
        );
        insert testUserAccount;
        
        User_Account_Case__c request = new User_Account_Case__c(
                RecordTypeId            = NewHireUtil.RECORDTYPE_PROVISIONING_TASK,
                Case__c                 = testCase.Id,
                Employee__c             = testContact.Id,
                User_Account__c         = testUserAccount.Id,
                Status__c               = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN,
                Type__c                 = NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE,
                Service__c              = testService.Id,
                //Role__c                 = testRole.Id,
                //Profile__c              = testProfile.Id,
                Business_Role__c        = testAccessPackage.Id,
                Notes__c                = 'Test Notes'
        );
        insert request;
        
        User_Account_Case__c requestPostInsert = [SELECT Id FROM User_Account_Case__c WHERE Id = :request.Id];
        Contact contactPostInsert = [SELECT Id FROM Contact WHERE Id = :testContact.Id];
        User_Account__c postInsertUserAccount = [SELECT Id FROM User_Account__c WHERE Id = :testUserAccount.Id];
        Test.setCurrentPage(Page.CompleteUserAccountEvent);
        
        // Initialize the controller.
        CompleteUserAccountEventController controller = new CompleteUserAccountEventController(new ApexPages.StandardController(requestPostInsert));
        
        // Run getUserAccount.
        User_Account__c ua = controller.getUserAccount();
        
        // Check Results
        System.assertEquals(ua.Id, postInsertUserAccount.Id);
        System.assertEquals(ua.Service__c, request.Service__c);
        System.assertEquals(ua.Active__c, true, 'Should have set Active to True');
        System.assertEquals(ua.Contact__c, request.Employee__c, 'User Account Contact field not set properly');
        System.assertEquals(ua.Service_Role__c, testAccessPackage.Service_Role__c, 'User Account Service Role field not set properly');
        System.assertEquals(ua.Service_Profile__c, testAccessPackage.Service_Profile__c, 'User Account Service Profile field not set properly');
        
        //Run CompleteRequst
        PageReference finishPage = controller.CompleteRequest();
        
        //Check Results
        User_Account__c uaPostInsert = [SELECT Id FROM User_Account__c WHERE Id = :ua.Id];
        System.assertEquals(uaPostInsert.Id, ua.Id);
        User_Account_Case__c updatedRequest = [SELECT Id, Status__c, User_Account__c, User_Account__r.Id FROM User_Account_Case__c WHERE Id = :request.Id];
        System.assertEquals(updatedRequest.Status__c, NewHireUtil.ASSET_CASE_STATUS_COMPLETE);
        System.assertEquals(updatedRequest.User_Account__r.Id, ua.Id); 
    }
    
    @isTest
    public static void testDeactivateUserAccount()
    {
        //Setup Records
        Contact testContact = new Contact(
            firstname = 'Testfirst',
            lastname = 'Testlast'
        );
        insert testContact;
        Case testCase = new Case(
                RecordTypeId            = NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
                Origin                  = 'Human Resources Portal'
        );
        insert testCase;
        
        Service__c testService = new Service__c(
                name                    = 'Test Service'
        );
        insert testService;
        
        Service_Role__c testRole = new Service_Role__c(
                name                    = 'Test Role',
                Service__c              = testService.id
        );
        insert testRole;
        
        Service_Profile__c testProfile = new Service_Profile__c(
                name                    = 'Test Profile',
                Service__c              = testService.id
        );
        insert testProfile;
        
        Access_Package__c testAccessPackage = new Access_Package__c(
            Name                        = 'Test Access Package',
            Service__c                  = testService.Id,
            Service_Role__c             = testRole.Id,
            Service_Profile__c          = testProfile.Id
        );        
        insert testAccessPackage;
        
        User_Account__c testUserAccount = new User_Account__c(
                Active__c               = false,
                Contact__c              = testContact.Id,
                Service__c              = testService.Id,
                RecordTypeId            = NewHireUtil.RECORDTYPE_SALESFORCE_USER_ACCOUNT,
                Service_User_ID__c      = '00Z00000008RJP',
                Service_Username__c     = 'testusername@2u.com.test',
                Service_Role__c         = testRole.Id,
                Service_Profile__c      = testProfile.Id
        );
        insert testUserAccount;
        
        User_Account_Case__c request = new User_Account_Case__c(
                RecordTypeId            = NewHireUtil.RECORDTYPE_PROVISIONING_TASK,
                Case__c                 = testCase.Id,
                Employee__c             = testContact.Id,
                User_Account__c         = testUserAccount.Id,
                Status__c               = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN,
                Type__c                 = NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE,
                Service__c              = testService.Id,
                //Role__c                 = testRole.Id,
                //Profile__c              = testProfile.Id,
                Business_Role__c        = testAccessPackage.Id,
                Notes__c                = 'Test Notes'
        );
        insert request;
        
        User_Account_Case__c requestPostInsert = [SELECT Id FROM User_Account_Case__c WHERE Id = :request.Id];
        Contact contactPostInsert = [SELECT Id FROM Contact WHERE Id = :testContact.Id];
        User_Account__c postInsertUserAccount = [SELECT Id FROM User_Account__c WHERE Id = :testUserAccount.Id];
        Test.setCurrentPage(Page.CompleteUserAccountEvent);
        
        // Initialize the controller.
        CompleteUserAccountEventController controller = new CompleteUserAccountEventController(new ApexPages.StandardController(requestPostInsert));
        
        // Run getUserAccount.
        User_Account__c ua = controller.getUserAccount();
        
        // Check Results
        System.assertEquals(ua.Id, postInsertUserAccount.Id);
        System.assertEquals(ua.Service__c, request.Service__c);
        System.assertEquals(ua.Active__c, false, 'Should have set Active to True');
        System.assertEquals(ua.Contact__c, request.Employee__c, 'User Account Contact field not set properly');
        System.assertEquals(ua.Service_Role__c, testAccessPackage.Service_Role__c, 'User Account Service Role field not set properly');
        System.assertEquals(ua.Service_Profile__c, testAccessPackage.Service_Profile__c, 'User Account Service Profile field not set properly');
        
        //Run CompleteRequst
        PageReference finishPage = controller.CompleteRequest();
        
        //Check Results
        User_Account__c uaPostInsert = [SELECT Id FROM User_Account__c WHERE Id = :ua.Id];
        System.assertEquals(uaPostInsert.Id, ua.Id);
        User_Account_Case__c updatedRequest = [SELECT Id, Status__c, User_Account__c, User_Account__r.Id FROM User_Account_Case__c WHERE Id = :request.Id];
        System.assertEquals(updatedRequest.Status__c, NewHireUtil.ASSET_CASE_STATUS_COMPLETE);
        System.assertEquals(updatedRequest.User_Account__r.Id, ua.Id); 
    }
    
    
    @isTest
    public static void testNullUserAccount()
    {
        //Setup Records
        Contact testContact = new Contact(
            firstname = 'Testfirst',
            lastname = 'Testlast'
        );
        insert testContact;
        Case testCase = new Case(
                RecordTypeId            = NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
                Origin                  = 'Human Resources Portal'
        );
        insert testCase;
        
        Service__c testService = new Service__c(
                name                    = 'Test Service'
        );
        insert testService;
        
        Service_Role__c testRole = new Service_Role__c(
                name                    = 'Test Role',
                Service__c              = testService.id
        );
        insert testRole;
        
        Service_Profile__c testProfile = new Service_Profile__c(
                name                    = 'Test Profile',
                Service__c              = testService.id
        );
        insert testProfile;
        
        Access_Package__c testAccessPackage = new Access_Package__c(
            Name                        = 'Test Access Package',
            Service__c                  = testService.Id,
            Service_Role__c             = testRole.Id,
            Service_Profile__c          = testProfile.Id
        );        
        insert testAccessPackage;
        
        User_Account__c testUserAccount = new User_Account__c(
                Active__c               = false,
                Contact__c              = testContact.Id,
                Service__c              = testService.Id,
                RecordTypeId            = NewHireUtil.RECORDTYPE_SALESFORCE_USER_ACCOUNT,
                Service_User_ID__c      = '00Z00000008RJP',
                Service_Username__c     = 'testusername@2u.com.test',
                Service_Role__c         = testRole.Id,
                Service_Profile__c      = testProfile.Id
        );
        insert testUserAccount;
        
        User_Account_Case__c request = new User_Account_Case__c(
                RecordTypeId            = NewHireUtil.RECORDTYPE_PROVISIONING_TASK,
                Case__c                 = testCase.Id,
                Employee__c             = testContact.Id,
                User_Account__c         = testUserAccount.Id,
                Status__c               = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN,
                Service__c              = testService.Id,
                //Role__c                 = testRole.Id,
                //Profile__c              = testProfile.Id,
                Business_Role__c        = testAccessPackage.Id,
                Notes__c                = 'Test Notes'
        );
        insert request;
        
        User_Account_Case__c requestPostInsert = [SELECT Id FROM User_Account_Case__c WHERE Id = :request.Id];
        Contact contactPostInsert = [SELECT Id FROM Contact WHERE Id = :testContact.Id];
        User_Account__c postInsertUserAccount = [SELECT Id FROM User_Account__c WHERE Id = :testUserAccount.Id];
        Test.setCurrentPage(Page.CompleteUserAccountEvent);
        
        // Initialize the controller.
        CompleteUserAccountEventController controller = new CompleteUserAccountEventController(new ApexPages.StandardController(requestPostInsert));
        
        // Run getUserAccount.
        User_Account__c ua = controller.getUserAccount();
        
        // Check Results
        System.assertEquals(ua, null);
        
        //Run CompleteRequst
        PageReference finishPage = controller.CompleteRequest();
        
        //Check Results
        System.assertEquals(finishPage.getURL(), '/' + requestPostInsert.Id); 
    }
    
}