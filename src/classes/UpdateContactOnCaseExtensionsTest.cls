/**
* Test cases for the UpdateContactONCaseExtensions controller.
*
* Assertions as follows:
*
* ValidCaseAndContact:
* - All appropriate values from the Case are moved onto the Contact.
* - The Case is marked as complete.
* - Return value forwards to the Case detail page.
*
* InvalidCase
* - An uncaught Exception is thrown.
*
* NullContact
* - The function call is quietly ignored.
* - The Case is not marked as Complete.
* - Return value forwards to the Case detail page. 
*
* BlankFields
* - Null and blank fields on the Case have no effect on their 
*   corresponding Contact fields.
*
* NotUpdateContact
* - No changes are made.
* - Return value forwards to the Case detail page.
*
*
*/
public with sharing class UpdateContactOnCaseExtensionsTest 
{
    
    /**
    * Generate a random string for test use.
    */
    public static String rndStr()
    {
        return 'UDCCETest'+Math.random();
    }

    /**
    * A basic DML setup, with:
    *  - Open Case
    *  - Salesforce Business Role not set on Case
    *  - Salesforce Business Role not set on Contact
    *  - One open Generaic User_Account_Case__c
    *  - One open Salesforce User_Account_Case__c
    */
    class BasicSetup
    {
        Account theAccount;
        Contact theContact;
        Case theCase;
        Service__c service1;
        Service__c service2;
        User_Account_Case__c uac1;
        User_Account_Case__c uac2;
        UpdateContactOnCaseExtensions controller;


        public BasicSetup()
        {
            reset();
        }

        public BasicSetup reset()
        {
            theAccount = new Account(Name=rndStr());
            
            theContact = new Contact(LastName=rndStr());
            
            theCase = new Case(
                    Type=NewHireUtil.CASE_TYPE_ADD,
                    RecordTypeId = NewHireUtil.RECORDTYPE_PROVISIONING_CASE
                );

            service1 = new Service__c(
                Available_on_provisioning_case_c__c = true,
                Offer_Access_Packages__c            = true,
                Field_Set__c                        = NewHireUtil.UAC_FIELD_SET_SALESFORCE,
                Name                                = rndStr()
            );

            service2 = new Service__c(
                Available_on_provisioning_case_c__c = true,
                Offer_Access_Packages__c            = true,
                Field_Set__c                        = NewHireUtil.UAC_FIELD_SET_GENERIC,
                Name                                = rndStr()
            );

            uac1 = new User_Account_Case__c(
                    RecordTypeId      = NewHireUtil.RECORDTYPE_PROVISIONING_TASK, 
                    Status__c         = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN,
                    Type__c           = NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE
                );

            uac2 = uac1.clone();

            return this;
        }

        public BasicSetup save()
        {

            insert theAccount;

            theContact.AccountId=theAccount.Id;
            insert theContact;
            
            theCase.prEmployee__c = theContact.Id;
            insert theCase;

            insert new Service__c[]{service1, service2};

            uac1.Service__c = service1.Id;
            uac1.Employee__c = theCase.prEmployee__c;
            uac1.Case__c = theCase.Id;

            uac2.Service__c = service2.Id;
            uac2.Employee__c = theCase.prEmployee__c;
            uac2.Case__c = theCase.Id;

            insert new User_Account_Case__c[]{uac1, uac2};

            // Re-query the Case so that the controller has to 
            // requery data.  
            Case theCasePostInsert = [
                select Id from Case where Id = :theCase.Id];
            
            Test.setCurrentPage(Page.UpdateContact);
            
            // Initialize the controller.
            controller = new UpdateContactOnCaseExtensions(
                    new ApexPages.StandardController(theCasePostInsert));

            return this;
        }

    }


    @isTest
    public static void testNeedsBusinessRole_UACVars()
    {
        BasicSetup setup = new BasicSetup();

        // Try with User_Account_Case__c.Type__c = Provision
        //
        setup.uac1.Type__c = NewHireUtil.USER_ACCOUNT_CASE_TYPE_PROVISION;
        setup.save();
        System.assertEquals(
            true, setup.controller.getNeedsBusinessRole(),
            'Wrong output when the User_Account_Case__c.Type__c was changed from "Activate" to "Provision".'
        );

        // Try again with User_Account_Case__c.Type__c = random
        //
        setup.reset();
        setup.uac1.Type__c = rndStr();
        setup.save();
        System.assertEquals(
            false, setup.controller.getNeedsBusinessRole(),
            'Wrong output when the User_Account_Case__c.Type__c was changed to an unrecognized value.'
        );

        // Try again with User_Account_Case__c.Status__c = None
        //
        setup.reset();
        setup.uac1.Status__c = NewHireUtil.USER_ACCOUNT_CASE_STATUS_NONE;
        setup.save();
        System.assertEquals(
            true, setup.controller.getNeedsBusinessRole(),
            'Wrong output when the User_Account_Case__c.Status__c was changed to "".'
        );

        // Try again with User_Account_Case__c.Status__c = None
        //
        setup.reset();
        setup.uac1.Status__c = rndStr();
        setup.save();
        System.assertEquals(
            false, setup.controller.getNeedsBusinessRole(),
            'Wrong output when the User_Account_Case__c.Status__c was changed to a random value.'
        );

    }

    @isTest
    public static void testNeedsBusinessRole_ServiceVars()
    {
        BasicSetup setup = new BasicSetup();

        // Try with no Salesforce Services.
        //
        setup.service1.Field_Set__c = NewHireUtil.UAC_FIELD_SET_GENERIC;
        setup.save();
        System.assertEquals(
            false, setup.controller.getNeedsBusinessRole(),
            'Asked for a Salesforce Business Role, even though none of the requested User_Account_Case__c records were for Salesforce services.'
        );
    }

    @isTest
    public static void testNeedsBusinessRole_CaseVars()
    {
        BasicSetup setup = new BasicSetup();

        // Try with a different Case.RecordTypeId.
        //
        setup.theCase.RecordTypeId = NewHireUtil.RECORDTYPE_PROVISIONING_CASE_COMPLETE;
        setup.save();
        System.assertEquals(
            false, setup.controller.getNeedsBusinessRole(),
            'Asked for a Salesforce Business Role, even though the Case was not a Provisioning Case.'
        );


        // Try again with a Case.Type = Update.
        //
        setup.reset();
        setup.theCase.Type = NewHireUtil.CASE_TYPE_UPDATE;
        setup.save();
        System.assertEquals(
            true, setup.controller.getNeedsBusinessRole(),
            'Did not ask for a Salesforce Business Role, even though the Case Type was Update.'
        );

        // Try again with a Case.Type = random.
        //
        setup.reset();
        setup.theCase.Type = rndStr();
        setup.save();
        System.assertEquals(
            false, setup.controller.getNeedsBusinessRole(),
            'Asked for a Salesforce Business Role, even though the Case Type was random.'
        );

        // Try again with Salesforce_Business_Role__c already populated.
        //
        setup.reset();
        setup.theCase.Salesforce_Business_Role__c = rndStr();
        setup.save();
        System.assertEquals(
            false, setup.controller.getNeedsBusinessRole(),
            'Asked for a Salesforce Business Role, even though the Case already specified a Salesforce_Business_Role__c.'
        );

    }

    @isTest
    public static void testNeedsBusinessRole_ContactVars()
    {
        BasicSetup setup = new BasicSetup();

        // Try with Salesforce_Business_Role__c already populated.
        //
        setup.theContact.Salesforce_Business_Role__c = rndStr();
        setup.save();
        System.assertEquals(
            false, setup.controller.getNeedsBusinessRole(),
            'Asked for a Salesforce Business Role, even though the Contact already specified a Salesforce_Business_Role__c.'
        );

    }

    /**
    * ValidCaseAndContact:
    * - All appropriate values from the Case are moved onto the Contact.
    * - The Case is marked as complete.
    * - Return value forwards to the Case detail page.
    */
    @isTest
    public static void testValidCaseAndContact()
    {
        Account theAccount = new Account(Name=rndStr());
        insert theAccount;
        
        Contact bossContact1 = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact bossContact2 = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        insert new sObject[]{bossContact1,bossContact2};
        
        Contact theContact = new Contact(
                AccountId                   = theAccount.Id,
                
                // These values will be replaced by the ones on the Case
                FirstName                   = rndStr(),
                LastName                    = rndStr(),
                Title                       = rndStr(),
                Personal_Email__c           = (rndStr()+'@example.com').toLowercase(),
                Budget_Line_Item__c         = rndStr(),
                torDepartment__c            = rndStr(),
                Office_Location__c          = rndStr(),
                ReportsToId                 = bossContact1.Id,
                Billing_Code__c             = rndStr(),
                Full_Time_Part_Time__c      = rndStr(),
                HomePhone                   = '+1 234-567-8901',
                Employment_Status__c        = rndStr(),
                Signing_Limit__c            = 111.11,
                Salesforce_Business_Role__c = rndStr(),
                Division__c                 = rndStr(),
                Cell_Phone_Reimbursement__c = rndStr(),
                Desk_Assignment__c          = rndStr()
            );
        
        insert theContact;
        
        // These values will be pushed onto the Contact.
        Case theCasePreInsert = new Case(
        
            // If we set the employee upon creation,the 
            // CaseAutocreateContact trigger will overwrite 
            // our test values with those from the Contact.
            // to avoid this, we will use an update to set 
            // prEmployee__c after the Case has been created.
            //
            // prEmployee__c                 = theContact.Id,
            
            RecordTypeId                  = NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
            
            // These values will replace the corresponding ones on the Contact.
            prFirst_Name__c               = rndStr(),
            prLastName__c                 = rndStr(),
            prPosition_Title__c           = rndStr(),
            prPersonal_Email__c           = (rndStr()+'@example.com').toLowercase(),
            prBudget_Line_Item__c         = rndStr(),
            prDepartment__c               = rndStr(),
            prLocation__c                 = rndStr(),
            prReports_To__c               = bossContact2.Id,
            prPayroll_Department_Code__c  = rndStr(),
            prFull_Time_Part_Time__c      = rndStr(),
            prPersonal_Phone__c           = '+1 345-678-9012',
            prEmployment_Status__c        = rndStr(),
            prSigning_Limit__c            = 222.22,
            Salesforce_Business_Role__c   = rndStr(),
            prDivision__c                 = rndStr(),
            prCell_Phone_Reimbursement__c = rndStr(),
            prDesk_Assignment__c          = rndStr()
        );

        insert theCasePreInsert;        
        theCasePreInsert.prEmployee__c = theContact.Id;
        update theCasePreInsert;
        
        
        // Re-query the Case so that the controller has to 
        // requery data.  
        Case theCasePostInsert = [
            select Id from Case where Id = :theCasePreInsert.Id];
        
        Test.setCurrentPage(Page.UpdateContact);
        
        // Initialize the controller.
        UpdateContactOnCaseExtensions controller = 
            new UpdateContactOnCaseExtensions(
                new ApexPages.StandardController(theCasePostInsert));
        
        // Run the method.
        PageReference nextPage = controller.updateContact();
        
        // Check the next page reference
        System.assertEquals(true,nextPage.getRedirect(), 
            'Unexpected value for nextPage.getRedirect()');     
        System.assertEquals('/'+theCasePostInsert.Id,nextPage.getUrl(),
            'Unexpected URL for next page.');
        
        // Query the results
        
        Contact contactPostUpdate = [
            select
                FirstName,
                LastName,
                Title,
                Personal_Email__c,
                Budget_Line_Item__c,
                torDepartment__c,
                Office_Location__c,
                ReportsToId,
                Billing_Code__c,
                Full_Time_Part_Time__c,
                HomePhone,
                Employment_Status__c,
                Signing_Limit__c,
                Salesforce_Business_Role__c,
                Division__c,
                Cell_Phone_Reimbursement__c,
                Desk_Assignment__c
            from Contact
            where Id = :theContact.Id
        ];
        
        // Check values
        
        System.assertEquals(theCasePreInsert.prFirst_Name__c,contactPostUpdate.FirstName,
            'Contact.FirstName does not match Case.prFirst_Name__c.');
        
        System.assertEquals(theCasePreInsert.prLastName__c,contactPostUpdate.LastName,
            'Contact.LastName does not match Case.prLastName__c.');
        
        System.assertEquals(theCasePreInsert.prPosition_Title__c,contactPostUpdate.Title,
            'Contact.Title does not match Case.prPosition_Title__c.');
        
        System.assertEquals(theCasePreInsert.prPersonal_Email__c,contactPostUpdate.Personal_Email__c,
            'Contact.Personal_Email__c does not match Case.prPersonal_Email__c.');
        
        System.assertEquals(theCasePreInsert.prBudget_Line_Item__c,contactPostUpdate.Budget_Line_Item__c,
            'Contact.Budget_Line_Item__c does not match Case.prBudget_Line_Item__c.');
        
        System.assertEquals(theCasePreInsert.prDepartment__c,contactPostUpdate.torDepartment__c,
            'Contact.torDepartment__c does not match Case.prDepartment__c.');
        
        System.assertEquals(theCasePreInsert.prLocation__c,contactPostUpdate.Office_Location__c,
            'Contact.Office_Location__c does not match Case.prLocation__c.');
        
        System.assertEquals(theCasePreInsert.prReports_To__c,contactPostUpdate.ReportsToId,
            'Contact.ReportsToId does not match Case.prReports_To__c.');
        
        System.assertEquals(theCasePreInsert.prPayroll_Department_Code__c,contactPostUpdate.Billing_Code__c,
            'Contact.Billing_Code__c does not match Case.prPayroll_Department_Code__c.');
        
        System.assertEquals(theCasePreInsert.prFull_Time_Part_Time__c,contactPostUpdate.Full_Time_Part_Time__c,
            'Contact.Full_Time_Part_Time__c does not match Case.prFull_Time_Part_Time__c.');
        
        System.assertEquals(theCasePreInsert.prPersonal_Phone__c,contactPostUpdate.HomePhone,
            'Contact.HomePhone does not match Case.prPersonal_Phone__c.');
        
        System.assertEquals(theCasePreInsert.prEmployment_Status__c,contactPostUpdate.Employment_Status__c,
            'Contact.Employment_Status__c does not match Case.prEmployment_Status__c.');
        
        System.assertEquals(theCasePreInsert.prSigning_Limit__c,contactPostUpdate.Signing_Limit__c,
            'Contact.Signing_Limit__c does not match Case.prSigning_Limit__c.');
            
        System.assertEquals(theCasePreInsert.Salesforce_Business_Role__c,contactPostUpdate.Salesforce_Business_Role__c,
            'Contact.Salesforce_Business_Role__c does not match Case.Salesforce_Business_Role__c.');
                
        System.assertEquals(theCasePreInsert.prDivision__c,contactPostUpdate.Division__c,
            'Contact.Division__c does not match Case.prDivision__c.');
        
        System.assertEquals(theCasePreInsert.prCell_Phone_Reimbursement__c,contactPostUpdate.Cell_Phone_Reimbursement__c,
            'Contact.Cell_Phone_Reimbursement__c does not match Case.prCell_Phone_Reimbursement__c.');
        
        System.assertEquals(theCasePreInsert.prDesk_Assignment__c,contactPostUpdate.Desk_Assignment__c,
            'Contact.Desk_Assignment__c does not match Case.prDesk_Assignment__c.');    
        
        // Check the Case
        Case theCasePostUpdate = [
            select 
                Id,
                RecordTypeId
            from Case 
            where Id = :theCasePostInsert.Id
        ];
        
        System.assertEquals(NewHireUtil.RECORDTYPE_PROVISIONING_CASE_COMPLETE, theCasePostUpdate.RecordTypeId,
            'Unexpected value for Case.RecordTypeId.');
        
    }
    
    /**
    * InvalidCase
    * - An uncaught Exception is thrown.
    */
    @isTest
    public static void testInvalidCase()
    {
        Account theAccount = new Account(Name=rndStr());
        insert theAccount;
        
        Contact theContact = new Contact(AccountId = theAccount.Id, LastName=rndStr());
        insert theContact;
        
        Case theCase = new Case(
            prEmployee__c                 = theContact.Id,          
            RecordTypeId                  = NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE
        );
        insert theCase;
        
        // invalidate the Case by deleting it.
        
        delete theCase;
        
        
        Test.setCurrentPage(Page.UpdateContact);
        
        // Initialize the controller.
        UpdateContactOnCaseExtensions controller = 
            new UpdateContactOnCaseExtensions(
                new ApexPages.StandardController(theCase));
        

        try
        {
            // Run the method.
            controller.updateContact();
            System.assert(false, 'Failed to throw an exception when updateContact was called on a deleted Case.');
        } 
        catch(Exception e)
        {
            System.assert(true);            
        }

    }
    
    
    /**
    * NullContact
    * - The function call is quietly ignored.
    * - The Case is not marked as Complete.
    * - Return value forwards to the Case detail page. 
    */
    @isTest
    public static void testNullContact()
    {
        Account theAccount = new Account(Name=rndStr());
        insert theAccount;
        
        Contact bossContact1 = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact bossContact2 = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        insert new sObject[]{bossContact1,bossContact2};
        
        Contact theContact = new Contact(
                AccountId                   = theAccount.Id,
                LastName                    = rndStr()
            );
        
        insert theContact;
        
        // Invalidate the Contac ID by deleting the record.
        delete theContact;
        
        // These values will be pushed onto the Contact.
        Case theCasePreInsert = new Case(
            prEmployee__c                 = null,
            RecordTypeId                  = NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
            
            // These values will replace the corresponding ones on the Contact.
            prFirst_Name__c               = 'testtesttest',
            prLastName__c                 = rndStr(),
            prPosition_Title__c           = rndStr(),
            prPersonal_Email__c           = (rndStr()+'@example.com').toLowercase(),
            prBudget_Line_Item__c         = rndStr(),
            prDepartment__c               = rndStr(),
            prLocation__c                 = rndStr(),
            prReports_To__c               = bossContact2.Id,
            prPayroll_Department_Code__c  = rndStr(),
            prFull_Time_Part_Time__c      = rndStr(),
            prPersonal_Phone__c           = '+1 345-678-9012',
            prEmployment_Status__c        = rndStr(),
            prSigning_Limit__c            = 222.22,
            Salesforce_Business_Role__c   = rndStr(),
            prDivision__c                 = rndStr(),
            prCell_Phone_Reimbursement__c = rndStr(),
            prDesk_Assignment__c          = rndStr()
        );

        insert theCasePreInsert;        
        theCasePreInsert.prEmployee__c = theContact.Id;
        
        // Re-query the Case so that the controller has to 
        // requery data.  
        Case theCasePostInsert = [
            select Id from Case where Id = :theCasePreInsert.Id];
        
        Test.setCurrentPage(Page.UpdateContact);
        
        // Initialize the controller.
        UpdateContactOnCaseExtensions controller = 
            new UpdateContactOnCaseExtensions(
                new ApexPages.StandardController(theCasePostInsert));
        
        // Run the method.
        PageReference nextPage = controller.updateContact();
        
        // Check the next page reference
        System.assertEquals(true,nextPage.getRedirect(), 
            'Unexpected value for nextPage.getRedirect()');     
        System.assertEquals('/'+theCasePostInsert.Id,nextPage.getUrl(),
            'Unexpected URL for next page.');
        
        // Check the Case
        Case theCasePostUpdate = [
            select 
                Id,
                RecordTypeId
            from Case 
            where Id = :theCasePostInsert.Id
        ];
        
        System.assertNotEquals(NewHireUtil.RECORDTYPE_PROVISIONING_CASE_COMPLETE, theCasePostUpdate.RecordTypeId,
            'The Case\'s record type was changed to complete, even though no prEmployee__c was given.');
        
    }
    
    /**
    * BlankFields
    * - Null and blank fields on the Case have no effect on their 
    *   corresponding Contact fields.
    */
    @isTest
    public static void testBlankFields()
    {
        Account theAccount = new Account(Name=rndStr());
        insert theAccount;
        
        Contact bossContact1 = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact bossContact2 = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        insert new sObject[]{bossContact1,bossContact2};
        
        Contact theContact = new Contact(
                AccountId                   = theAccount.Id,
                
                // These values will be replaced by the ones on the Case
                FirstName                   = rndStr(),
                LastName                    = rndStr(),
                Title                       = rndStr(),
                Personal_Email__c           = (rndStr()+'@example.com').toLowercase(),
                Budget_Line_Item__c         = rndStr(),
                torDepartment__c            = rndStr(),
                Office_Location__c          = rndStr(),
                ReportsToId                 = bossContact1.Id,
                Billing_Code__c             = rndStr(),
                Full_Time_Part_Time__c      = rndStr(),
                HomePhone                   = '+1 234-567-8901',
                Employment_Status__c        = rndStr(),
                Signing_Limit__c            = 111.11,
                Salesforce_Business_Role__c = rndStr(),
                Division__c                 = rndStr(),
                Cell_Phone_Reimbursement__c = rndStr(),
                Desk_Assignment__c          = rndStr()
            );
        
        insert theContact;
        
        // These values will be pushed onto the Contact.
        Case theCasePreInsert = new Case(
        
            // If we set the employee upon creation,the 
            // CaseAutocreateContact trigger will overwrite 
            // our test values with those from the Contact.
            // to avoid this, we will use an update to set 
            // prEmployee__c after the Case has been created.
            //
            // prEmployee__c                 = theContact.Id,
            
            RecordTypeId                  = NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
            
            // Mix null and non-null fields.
            prFirst_Name__c               = null,
            prLastName__c                 = rndStr(),
            prPosition_Title__c           = null,
            prPersonal_Email__c           = (rndStr()+'@example.com').toLowercase(),
            prBudget_Line_Item__c         = null,
            prDepartment__c               = rndStr(),
            prLocation__c                 = null,
            prReports_To__c               = bossContact2.Id,
            prPayroll_Department_Code__c  = null,
            prFull_Time_Part_Time__c      = rndStr(),
            prPersonal_Phone__c           = null,
            prEmployment_Status__c        = rndStr(),
            prSigning_Limit__c            = null,
            Salesforce_Business_Role__c   = null,
            prDivision__c                 = rndStr(),
            prCell_Phone_Reimbursement__c = null,
            prDesk_Assignment__c          = rndStr()
        );

        insert theCasePreInsert;
        theCasePreInsert.prEmployee__c = theContact.Id;
        update theCasePreInsert;
        
        
        // Re-query the Case so that the controller has to 
        // requery data.
        Case theCasePostInsert = [
            select Id from Case where Id = :theCasePreInsert.Id];
        
        Test.setCurrentPage(Page.UpdateContact);
        
        // Initialize the controller.
        UpdateContactOnCaseExtensions controller = 
            new UpdateContactOnCaseExtensions(
                new ApexPages.StandardController(theCasePostInsert));

        // Run the method.
        PageReference nextPage = controller.updateContact();

        
        // Check the next page reference
        System.assertEquals(true,nextPage.getRedirect(), 
            'Unexpected value for nextPage.getRedirect()');
        System.assertEquals('/'+theCasePostInsert.Id,nextPage.getUrl(),
            'Unexpected URL for next page.');
        
        // Query the results
        
        Contact contactPostUpdate = [
            select
                FirstName,
                LastName,
                Title,
                Personal_Email__c,
                Budget_Line_Item__c,
                torDepartment__c,
                Office_Location__c,
                ReportsToId,
                Billing_Code__c,
                Full_Time_Part_Time__c,
                HomePhone,
                Employment_Status__c,
                Signing_Limit__c,
                Salesforce_Business_Role__c,
                Division__c,
                Cell_Phone_Reimbursement__c,
                Desk_Assignment__c
            from Contact
            where Id = :theContact.Id
        ];
        
        // Check values
        
        System.assertEquals(theContact.FirstName,contactPostUpdate.FirstName,
            'The Contact.FirstName field changed even though its corresponding Case value was null.');
        
        System.assertEquals(theCasePreInsert.prLastName__c,contactPostUpdate.LastName,
            'Contact.LastName does not match Case.prLastName__c.');
        
        System.assertEquals(theContact.Title,contactPostUpdate.Title,
            'The Contact.Title field changed even though its corresponding Case value was null.');
        
        System.assertEquals(theCasePreInsert.prPersonal_Email__c,contactPostUpdate.Personal_Email__c,
            'Contact.Personal_Email__c does not match Case.prPersonal_Email__c.');
        
        System.assertEquals(theContact.Budget_Line_Item__c,contactPostUpdate.Budget_Line_Item__c,
            'The Contact.Budget_Line_Item__c field changed even though its corresponding Case value was null.');
        
        System.assertEquals(theCasePreInsert.prDepartment__c,contactPostUpdate.torDepartment__c,
            'Contact.torDepartment__c does not match Case.prDepartment__c.');
        
        System.assertEquals(theContact.Office_Location__c,contactPostUpdate.Office_Location__c,
            'The Contact.Office_Location__c field changed even though its corresponding Case value was null.');
        
        System.assertEquals(theCasePreInsert.prReports_To__c,contactPostUpdate.ReportsToId,
            'Contact.ReportsToId does not match Case.prReports_To__c.');
        
        System.assertEquals(theContact.Billing_Code__c,contactPostUpdate.Billing_Code__c,
            'The Contact.Billing_Code__c field changed even though its corresponding Case value was null.');
        
        System.assertEquals(theCasePreInsert.prFull_Time_Part_Time__c,contactPostUpdate.Full_Time_Part_Time__c,
            'Contact.Full_Time_Part_Time__c does not match Case.prFull_Time_Part_Time__c.');
        
        System.assertEquals(theContact.HomePhone,contactPostUpdate.HomePhone,
            'The Contact.HomePhone field changed even though its corresponding Case value was null.');
        
        System.assertEquals(theCasePreInsert.prEmployment_Status__c,contactPostUpdate.Employment_Status__c,
            'Contact.Employment_Status__c does not match Case.prEmployment_Status__c.');
        
        System.assertEquals(theContact.Signing_Limit__c,contactPostUpdate.Signing_Limit__c,
            'The Contact.Signing_Limit__c field changed even though its corresponding Case value was null.');

        System.assertEquals(theContact.Salesforce_Business_Role__c,contactPostUpdate.Salesforce_Business_Role__c,
            'The Contact.Salesforce_Business_Role__c field changed even though its corresponding Case value was null.');
        
        System.assertEquals(theCasePreInsert.prDivision__c,contactPostUpdate.Division__c,
            'Contact.Division__c does not match Case.prDivision__c.');
        
        System.assertEquals(theContact.Cell_Phone_Reimbursement__c,contactPostUpdate.Cell_Phone_Reimbursement__c,
            'The Contact.Cell_Phone_Reimbursement__c field changed even though its corresponding Case value was null.');
        
        System.assertEquals(theCasePreInsert.prDesk_Assignment__c,contactPostUpdate.Desk_Assignment__c,
            'Contact.Desk_Assignment__c does not match Case.prDesk_Assignment__c.');    
        
        // Check the Case
        Case theCasePostUpdate = [
            select 
                Id,
                RecordTypeId
            from Case 
            where Id = :theCasePostInsert.Id
        ];
        
        System.assertEquals(NewHireUtil.RECORDTYPE_PROVISIONING_CASE_COMPLETE, theCasePostUpdate.RecordTypeId,
            'Unexpected value for Case.RecordTypeId.');
            
        
        // Try again, but nullify the other fields.
        
        theContact = new Contact(
                AccountId                   = theAccount.Id,
                
                // These values will be replaced by the ones on the Case
                FirstName                   = rndStr(),
                LastName                    = rndStr(),
                Title                       = rndStr(),
                Personal_Email__c           = (rndStr()+'@example.com').toLowercase(),
                Budget_Line_Item__c         = rndStr(),
                torDepartment__c            = rndStr(),
                Office_Location__c          = rndStr(),
                ReportsToId                 = bossContact1.Id,
                Billing_Code__c             = rndStr(),
                Full_Time_Part_Time__c      = rndStr(),
                HomePhone                   = '+1 234-567-8901',
                Employment_Status__c        = rndStr(),
                Signing_Limit__c            = 111.11,
                Salesforce_Business_Role__c = rndStr(),
                Division__c                 = rndStr(),
                Cell_Phone_Reimbursement__c = rndStr(),
                Desk_Assignment__c          = rndStr()
            );
        
        insert theContact;
        
        // These values will be pushed onto the Contact.
        theCasePreInsert = new Case(
        
            // If we set the employee upon creation,the 
            // CaseAutocreateContact trigger will overwrite 
            // our test values with those from the Contact.
            // to avoid this, we will use an update to set 
            // prEmployee__c after the Case has been created.
            //
            // prEmployee__c                 = theContact.Id,
            
            RecordTypeId                  = NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
            
            // Mix null and non-null fields.
            prFirst_Name__c               = rndStr(),
            prLastName__c                 = null,
            prPosition_Title__c           = rndStr(),
            prPersonal_Email__c           = null,
            prBudget_Line_Item__c         = rndStr(),
            prDepartment__c               = null,
            prLocation__c                 = rndStr(),
            prReports_To__c               = null,
            prPayroll_Department_Code__c  = rndStr(),
            prFull_Time_Part_Time__c      = null,
            prPersonal_Phone__c           = '+1 345-678-9012',
            prEmployment_Status__c        = null,
            prSigning_Limit__c            = 222.22,
            Salesforce_Business_Role__c   = rndStr(),
            prDivision__c                 = null,
            prCell_Phone_Reimbursement__c = rndStr(),
            prDesk_Assignment__c          = null
        );

        insert theCasePreInsert;        
        theCasePreInsert.prEmployee__c = theContact.Id;
        update theCasePreInsert;
        
        
        // Re-query the Case so that the controller has to 
        // requery data.  
        theCasePostInsert = [
            select Id from Case where Id = :theCasePreInsert.Id];
        
        Test.setCurrentPage(Page.UpdateContact);
        
        // Initialize the controller.
        controller = 
            new UpdateContactOnCaseExtensions(
                new ApexPages.StandardController(theCasePostInsert));
        
        // Run the method.
        controller.updateContact();
        
        // Query the results
        
        contactPostUpdate = [
            select
                FirstName,
                LastName,
                Title,
                Personal_Email__c,
                Budget_Line_Item__c,
                torDepartment__c,
                Office_Location__c,
                ReportsToId,
                Billing_Code__c,
                Full_Time_Part_Time__c,
                HomePhone,
                Employment_Status__c,
                Signing_Limit__c,
                Salesforce_Business_Role__c,
                Division__c,
                Cell_Phone_Reimbursement__c,
                Desk_Assignment__c
            from Contact
            where Id = :theContact.Id
        ];
        
        // Check values
        
        System.assertEquals(theCasePreInsert.prFirst_Name__c,contactPostUpdate.FirstName,
            'Contact.FirstName does not match Case.prFirst_Name__c.');
        
        System.assertEquals(theContact.LastName,contactPostUpdate.LastName,
            'The Contact.LastName field changed even though its corresponding Case value was null.');
        
        System.assertEquals(theCasePreInsert.prPosition_Title__c,contactPostUpdate.Title,
            'Contact.Title does not match Case.prPosition_Title__c.');
        
        System.assertEquals(theContact.Personal_Email__c,contactPostUpdate.Personal_Email__c,
            'The Contact.Personal_Email__c field changed even though its corresponding Case value was null.');
        
        System.assertEquals(theCasePreInsert.prBudget_Line_Item__c,contactPostUpdate.Budget_Line_Item__c,
            'Contact.Budget_Line_Item__c does not match Case.prBudget_Line_Item__c.');
        
        System.assertEquals(theContact.torDepartment__c,contactPostUpdate.torDepartment__c,
            'The Contact.torDepartment__c field changed even though its corresponding Case value was null.');
        
        System.assertEquals(theCasePreInsert.prLocation__c,contactPostUpdate.Office_Location__c,
            'Contact.Office_Location__c does not match Case.prLocation__c.');
        
        System.assertEquals(theContact.ReportsToId,contactPostUpdate.ReportsToId,
            'The Contact.ReportsToId field changed even though its corresponding Case value was null.');
        
        System.assertEquals(theCasePreInsert.prPayroll_Department_Code__c,contactPostUpdate.Billing_Code__c,
            'Contact.Billing_Code__c does not match Case.prPayroll_Department_Code__c.');
        
        System.assertEquals(theContact.Full_Time_Part_Time__c,contactPostUpdate.Full_Time_Part_Time__c,
            'The Contact.Full_Time_Part_Time__c field changed even though its corresponding Case value was null.');
        
        System.assertEquals(theCasePreInsert.prPersonal_Phone__c,contactPostUpdate.HomePhone,
            'Contact.HomePhone does not match Case.prPersonal_Phone__c.');
        
        System.assertEquals(theContact.Employment_Status__c,contactPostUpdate.Employment_Status__c,
            'The Contact.Employment_Status__c field changed even though its corresponding Case value was null.');
        
        System.assertEquals(theCasePreInsert.prSigning_Limit__c,contactPostUpdate.Signing_Limit__c,
            'Contact.Signing_Limit__c does not match Case.prSigning_Limit__c.');
        
        System.assertEquals(theContact.Division__c,contactPostUpdate.Division__c,
            'The Contact.Division__c field changed even though its corresponding Case value was null.');
        
        System.assertEquals(theCasePreInsert.prCell_Phone_Reimbursement__c,contactPostUpdate.Cell_Phone_Reimbursement__c,
            'Contact.Cell_Phone_Reimbursement__c does not match Case.prCell_Phone_Reimbursement__c.');
        
        System.assertEquals(theContact.Desk_Assignment__c,contactPostUpdate.Desk_Assignment__c,
            'The Contact.Desk_Assignment__c field changed even though its corresponding Case value was null.'); 
        
                
    }
    
    /**
    * NotUpdateContact
    * - No changes are made.
    * - Return value forwards to the Case detail page.
    */
    @isTest
    public static void testNotUpdateContact()
    {
        Account theAccount = new Account(Name=rndStr());
        insert theAccount;
        
        Contact bossContact1 = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact bossContact2 = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        insert new sObject[]{bossContact1,bossContact2};
        
        Contact theContact = new Contact(
                AccountId                   = theAccount.Id,
                
                // These values will be replaced by the ones on the Case
                FirstName                   = rndStr(),
                LastName                    = rndStr(),
                Title                       = rndStr(),
                Personal_Email__c           = (rndStr()+'@example.com').toLowercase(),
                Budget_Line_Item__c         = rndStr(),
                torDepartment__c            = rndStr(),
                Office_Location__c          = rndStr(),
                ReportsToId                 = bossContact1.Id,
                Billing_Code__c             = rndStr(),
                Full_Time_Part_Time__c      = rndStr(),
                HomePhone                   = '+1 234-567-8901',
                Employment_Status__c        = rndStr(),
                Signing_Limit__c            = 111.11,
                Division__c                 = rndStr(),
                Cell_Phone_Reimbursement__c = rndStr(),
                Desk_Assignment__c          = rndStr()
            );
        
        insert theContact;
        
        // These values will be pushed onto the Contact.
        Case theCasePreInsert = new Case(
        
            // If we set the employee upon creation,the 
            // CaseAutocreateContact trigger will overwrite 
            // our test values with those from the Contact.
            // to avoid this, we will use an update to set 
            // prEmployee__c after the Case has been created.
            //
            // prEmployee__c                 = theContact.Id,
            
            RecordTypeId                  = NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
            
            // These values will replace the corresponding ones on the Contact.
            prFirst_Name__c               = rndStr(),
            prLastName__c                 = rndStr(),
            prPosition_Title__c           = rndStr(),
            prPersonal_Email__c           = (rndStr()+'@example.com').toLowercase(),
            prBudget_Line_Item__c         = rndStr(),
            prDepartment__c               = rndStr(),
            prLocation__c                 = rndStr(),
            prReports_To__c               = bossContact2.Id,
            prPayroll_Department_Code__c  = rndStr(),
            prFull_Time_Part_Time__c      = rndStr(),
            prPersonal_Phone__c           = '+1 345-678-9012',
            prEmployment_Status__c        = rndStr(),
            prSigning_Limit__c            = 222.22,
            prDivision__c                 = rndStr(),
            prCell_Phone_Reimbursement__c = rndStr(),
            prDesk_Assignment__c          = rndStr()
        );

        insert theCasePreInsert;        
        theCasePreInsert.prEmployee__c = theContact.Id;
        update theCasePreInsert;
        
        
        // Re-query the Case so that the controller has to 
        // requery data.  
        Case theCasePostInsert = [
            select Id,RecordTypeId from Case where Id = :theCasePreInsert.Id];
        
        Test.setCurrentPage(Page.UpdateContact);
        
        // Initialize the controller.
        UpdateContactOnCaseExtensions controller = 
            new UpdateContactOnCaseExtensions(
                new ApexPages.StandardController(theCasePostInsert));
        
        // Run the method.
        PageReference nextPage = controller.notUpdateContact();
        
        // Check the next page reference
        System.assertEquals(false,nextPage.getRedirect(), 
            'Unexpected value for nextPage.getRedirect()');     
        System.assertEquals('/'+theCasePostInsert.Id,nextPage.getUrl(),
            'Unexpected URL for next page.');
        
        // Query the results
        
        Contact contactPostUpdate = [
            select
                FirstName,
                LastName,
                Title,
                Personal_Email__c,
                Budget_Line_Item__c,
                torDepartment__c,
                Office_Location__c,
                ReportsToId,
                Billing_Code__c,
                Full_Time_Part_Time__c,
                HomePhone,
                Employment_Status__c,
                Signing_Limit__c,
                Division__c,
                Cell_Phone_Reimbursement__c,
                Desk_Assignment__c
            from Contact
            where Id = :theContact.Id
        ];
        
        // Check values
        
        System.assertEquals(theContact.FirstName,contactPostUpdate.FirstName,
            'The Contact.FirstName field was changed.');
        
        System.assertEquals(theContact.LastName,contactPostUpdate.LastName,
            'The Contact.LastName field was changed.');
        
        System.assertEquals(theContact.Title,contactPostUpdate.Title,
            'The Contact.Title field was changed.');
        
        System.assertEquals(theContact.Personal_Email__c,contactPostUpdate.Personal_Email__c,
            'The Contact.Personal_Email__c field was changed.');
        
        System.assertEquals(theContact.Budget_Line_Item__c,contactPostUpdate.Budget_Line_Item__c,
            'The Contact.Budget_Line_Item__c field was changed.');
        
        System.assertEquals(theContact.torDepartment__c,contactPostUpdate.torDepartment__c,
            'The Contact.torDepartment__c field was changed.');
        
        System.assertEquals(theContact.Office_Location__c,contactPostUpdate.Office_Location__c,
            'The Contact.Office_Location__c field was changed.');
        
        System.assertEquals(theContact.ReportsToId,contactPostUpdate.ReportsToId,
            'The Contact.ReportsToId field was changed.');
        
        System.assertEquals(theContact.Billing_Code__c,contactPostUpdate.Billing_Code__c,
            'The Contact.Billing_Code__c field was changed.');
        
        System.assertEquals(theContact.Full_Time_Part_Time__c,contactPostUpdate.Full_Time_Part_Time__c,
            'The Contact.Full_Time_Part_Time__c field was changed.');
        
        System.assertEquals(theContact.HomePhone,contactPostUpdate.HomePhone,
            'The Contact.HomePhone field was changed.');
        
        System.assertEquals(theContact.Employment_Status__c,contactPostUpdate.Employment_Status__c,
            'The Contact.Employment_Status__c field was changed.');
        
        System.assertEquals(theContact.Signing_Limit__c,contactPostUpdate.Signing_Limit__c,
            'The Contact.Signing_Limit__c field was changed.');
        
        System.assertEquals(theContact.Division__c,contactPostUpdate.Division__c,
            'The Contact.Division__c field was changed.');
        
        System.assertEquals(theContact.Cell_Phone_Reimbursement__c,contactPostUpdate.Cell_Phone_Reimbursement__c,
            'The Contact.Cell_Phone_Reimbursement__c field was changed.');
        
        System.assertEquals(theContact.Desk_Assignment__c,contactPostUpdate.Desk_Assignment__c,
            'The Contact.Desk_Assignment__c field was changed.');   
        
        // Check the Case
        Case theCasePostUpdate = [
            select 
                Id,
                RecordTypeId
            from Case 
            where Id = :theCasePostInsert.Id
        ];
        
        System.assertEquals(theCasePostInsert.RecordTypeId, theCasePostUpdate.RecordTypeId,
            'The Case.RecordTypeId was changed.');
        
    }

}