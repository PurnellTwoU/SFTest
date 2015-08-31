/**
* Test class fro RequestUniversityEmail.
**/

public with sharing class RequestUniversityEmailTest
{
    @isTest
    public static void testRossierEmail()
    {
        //Setup Records
        Contact manager = new Contact(
            firstname           = 'Manager First Name',
            lastname            = 'Manager Last Name'
        );
        insert manager;
        
        Case c = new Case(
            RecordTypeId        = NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
            Origin              = 'Human Resources Portal',
            prFirst_Name__c     = 'Employee First Name',
            prLastName__c       = 'Employee Last Name',
            prPosition_Title__c = 'Employee Title',
            prDepartment__c     = 'Sales',
            prReports_To__c     = manager.id
        );
        insert c;
        
        Contact employee = new Contact(
            firstname           = 'Manager First Name',
            lastname            = 'Manager Last Name',
            email               = 'test@2u.com.test',
            phone               = '5555555555'
        );
        insert employee;
        
        Service__c rossier_email = new Service__c(
            name                = 'Rossier Email',
            External_Contacts__c= 'nsnyder+rossiertest1@2u.com;nsnyder+rossiertest1@2u.com'            
        );
        insert rossier_email;
        
        User_Account_Case__c rossier_email_request = new User_Account_Case__c(
            Case__c             = c.id,
            Service__c          = rossier_email.id,
            Employee__c         = employee.id,
            Date__c             = System.today()
        );
        insert rossier_email_request;
        
        
        
        Test.setCurrentPageReference(new PageReference('Page.RequestUniversityEmail'));
        ApexPages.currentPage().getParameters().put('id', rossier_email_request.id);
        RequestUniversityEmail controller = new RequestUniversityEmail(new ApexPages.StandardController(rossier_email_request));
        
        //Create file to attach
        controller.attachments.add(new Attachment(name = 'File name', body = Blob.valueof('This is a test file')));
        //controller.attachments[1].body = Blob.valueof('This is a test file');
        //controller.attachments[1].name = 'File name';
        
        //Test send
        controller.send();
        
        //Test getToAddresses
        List<String> toaddresses = controller.getToAddresses();
        System.assertequals(toaddresses, rossier_email.External_Contacts__c.split(';', 0));
        
        //Test getCCAddresses
        String ccaddresses = controller.getCCAddresses();
        User current_user = [select name, email from User where id= :UserInfo.getUserId()] ;
        System.assertequals(ccaddresses, current_user.email);
    }
    
    @isTest
    public static void testMSWEmail()
    {
        //Setup Records
        Contact manager = new Contact(
            firstname           = 'Manager First Name',
            lastname            = 'Manager Last Name'
        );
        insert manager;
        
        Case c = new Case(
            RecordTypeId        = NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
            Origin              = 'Human Resources Portal',
            prFirst_Name__c     = 'Employee First Name',
            prLastName__c       = 'Employee Last Name',
            prPosition_Title__c = 'Employee Title',
            prDepartment__c     = 'Sales',
            prReports_To__c     = manager.id
        );
        insert c;
        
        Contact employee = new Contact(
            firstname           = 'Manager First Name',
            lastname            = 'Manager Last Name',
            email               = 'test@2u.com.test',
            phone               = '5555555555'
        );
        insert employee;
        
        Service__c msw_email = new Service__c(
            name                = 'MSW Email',
            External_Contacts__c= 'nsnyder+rossiertest1@2u.com;nsnyder+rossiertest1@2u.com'            
        );
        insert msw_email;
        
        User_Account_Case__c msw_email_request = new User_Account_Case__c(
            Case__c             = c.id,
            Service__c          = msw_email.id,
            Employee__c         = employee.id,
            Date__c             = System.today()
        );
        insert msw_email_request;
        
        
        Test.setCurrentPageReference(new PageReference('Page.RequestUniversityEmail'));
        ApexPages.currentPage().getParameters().put('id', msw_email_request.id);
        RequestUniversityEmail controller = new RequestUniversityEmail(new ApexPages.StandardController(msw_email_request));
        
        //Test send
        controller.send();
    }
    
    @isTest
    public static void testMSNEmail()
    {
        //Setup Records
        Contact manager = new Contact(
            firstname           = 'Manager First Name',
            lastname            = 'Manager Last Name'
        );
        insert manager;
        
        Case c = new Case(
            RecordTypeId        = NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
            Origin              = 'Human Resources Portal',
            prFirst_Name__c     = 'Employee First Name',
            prLastName__c       = 'Employee Last Name',
            prPosition_Title__c = 'Employee Title',
            prDepartment__c     = 'Sales',
            prReports_To__c     = manager.id
        );
        insert c;
        
        Contact employee = new Contact(
            firstname           = 'Manager First Name',
            lastname            = 'Manager Last Name',
            email               = 'test@2u.com.test',
            phone               = '5555555555'
        );
        insert employee;
        
        Service__c msn_email = new Service__c(
            name                = 'MSN Email',
            External_Contacts__c= 'nsnyder+msntest1@2u.com;nsnyder+msntest1@2u.com'            
        );
        insert msn_email;
        
        User_Account_Case__c msn_email_request = new User_Account_Case__c(
            Case__c             = c.id,
            Service__c          = msn_email.id,
            Employee__c         = employee.id,
            Date__c             = System.today()
        );
        insert msn_email_request;
        
               
        Test.setCurrentPageReference(new PageReference('Page.RequestUniversityEmail'));
        ApexPages.currentPage().getParameters().put('id', msn_email_request.id);
        RequestUniversityEmail controller = new RequestUniversityEmail(new ApexPages.StandardController(msn_email_request));
        
        //Create file to attach
        controller.attachments.add(new Attachment(name = 'File name', body = Blob.valueof('This is a test file')));
        
        //Test send
        controller.send();
        
        //Test getToAddresses
        List<String> toaddresses = controller.getToAddresses();
        System.assertequals(toaddresses, msn_email.External_Contacts__c.split(';', 0));
        
        //Test getCCAddresses
        String ccaddresses = controller.getCCAddresses();
        User current_user = [select name, email from User where id= :UserInfo.getUserId()] ;
        System.assertequals(ccaddresses, current_user.email);
    }
    
    @isTest
    public static void testMBAEmail()
    {
        //Setup Records
        Contact manager = new Contact(
            firstname           = 'Manager First Name',
            lastname            = 'Manager Last Name'
        );
        insert manager;
        
        Case c = new Case(
            RecordTypeId        = NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
            Origin              = 'Human Resources Portal',
            prFirst_Name__c     = 'Employee First Name',
            prLastName__c       = 'Employee Last Name',
            prPosition_Title__c = 'Employee Title',
            prDepartment__c     = 'Sales',
            prReports_To__c     = manager.id
        );
        insert c;
        
        Contact employee = new Contact(
            firstname           = 'Manager First Name',
            lastname            = 'Manager Last Name',
            email               = 'test@2u.com.test',
            phone               = '5555555555'
        );
        insert employee;
        
        Service__c mba_email = new Service__c(
            name                = 'MBA Email',
            External_Contacts__c= 'nsnyder+mbatest1@2u.com;nsnyder+mbatest1@2u.com'            
        );
        insert mba_email;
        
        User_Account_Case__c mba_email_request = new User_Account_Case__c(
            Case__c             = c.id,
            Service__c          = mba_email.id,
            Employee__c         = employee.id,
            Date__c             = System.today()
        );
        insert mba_email_request;
        
               
        Test.setCurrentPageReference(new PageReference('Page.RequestUniversityEmail'));
        ApexPages.currentPage().getParameters().put('id', mba_email_request.id);
        RequestUniversityEmail controller = new RequestUniversityEmail(new ApexPages.StandardController(mba_email_request));
        
        //Create file to attach
        controller.attachments.add(new Attachment(name = 'File name', body = Blob.valueof('This is a test file')));
        controller.attachments.add(new Attachment(name = 'File name2', body = Blob.valueof('This is a test file2')));
        
        //Test send
        controller.send();
        
        //Test getToAddresses
        List<String> toaddresses = controller.getToAddresses();
        System.assertequals(toaddresses, mba_email.External_Contacts__c.split(';', 0));
        
        //Test getCCAddresses
        String ccaddresses = controller.getCCAddresses();
        User current_user = [select name, email from User where id= :UserInfo.getUserId()] ;
        System.assertequals(ccaddresses, current_user.email);
    }
}