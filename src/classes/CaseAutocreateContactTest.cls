public class CaseAutocreateContactTest {
    
    public static testMethod void testBulkContactsGetCreated() {
        List<Case> newCases = new List<Case>();
        for (Integer i = 0; i<100; i++) {
            Case c = new Case(SuppliedEmail='jdoe_test_test@doe.com' + i,
                                SuppliedName='John Doe' + i,
                                Subject='Feedback - Something' + i);
            newCases.add(c);
        }
        insert newCases;
        
        System.debug('here');
        List<Id> newCaseIds = new List<Id>();
        for (Case caseObj:newCases) {
            newCaseIds.add(caseObj.Id);    
        }
        
        List<Case> updatedCases = [Select ContactId From Case Where Id in :newCaseIds];
        
        for (Case caseObj:updatedCases) {
            System.debug(caseObj.Id + ' ' + caseObj.ContactId);
            System.assert(caseObj.ContactId!=null,'There should be no null contacts');
        }
    }

    public static testMethod void testContactGetsCreated() {
        Case c = new Case(SuppliedEmail='jdoe_test_test@doe.com',
                            SuppliedName='John Doe',
                            Subject='Feedback - Something');
        insert c;

        List<Contact> johnDoes = [select Id from Contact where Email='jdoe_test_test@doe.com'];

        //there should be only 1 -- the trigger should not have created another
        System.assert(johnDoes.size()==1, 'There should be one John Doe!');
        
        Case caseObj = [select ContactId from Case where Id=:c.Id];
        System.assert(caseObj.ContactId!=null,'There should be no null contact on the case');
    }
    
    public static testMethod void testEduContactGetsCreated() {
        Case c = new Case(SuppliedEmail='jdoe_test_test@doe.edu',
                            SuppliedName='John Doe',
                            Subject='Feedback - Something');
        insert c;

        List<Contact> johnDoes = [select Id from Contact where University_Email__c='jdoe_test_test@doe.edu'];

        //there should be only 1 -- the trigger should not have created another
        System.assert(johnDoes.size()==1, 'There should be one John Doe!');
        
        Case caseObj = [select ContactId from Case where Id=:c.Id];
        System.assert(caseObj.ContactId!=null,'There should be no null contact on the case');
    }

    public static testMethod void testNoDupesAreCreated() {
        Contact cnt1 = new Contact(FirstName = 'John',
                                LastName = 'Doe',
                                Email='jdoe_test_test@doe.com');

        insert cnt1;

        Case case1 = new Case(SuppliedEmail='jdoe_test_test@doe.com',
                            SuppliedName='John Doe',
                            Subject='Feedback - Something');

        insert case1;

        List<Contact> johnDoes = [select Id from Contact where Email='jdoe_test_test@doe.com'];

        //there should be only 1 -- the trigger should not have created another
        System.assert(johnDoes.size()==1, 'There should be only one John Doe!');
    }
    
    public static testMethod void testEduNoDupesAreCreated() {
        Contact cnt1 = new Contact(FirstName = 'John',
                                LastName = 'Doe',
                                Email='jdoe_test_test@doe.com',
                                University_Email__c='jdoe_test_test@doe.edu');

        insert cnt1;

        Case case1 = new Case(SuppliedEmail='jdoe_test_test@doe.edu',
                            SuppliedName='John Doe',
                            Subject='Feedback - Something');

        insert case1;

        List<Contact> johnDoes = [select Id from Contact where University_Email__c='jdoe_test_test@doe.edu'];

        //there should be only 1 -- the trigger should not have created another
        System.assert(johnDoes.size()==1, 'There should be only one John Doe!');
    }
/*removed this criteria since some 2tor staff use MSW@USC in their names
    public static testMethod void testEmailNameDoesntGetCreated() {
        Case c = new Case(SuppliedEmail='testEmailNameDoesntGetCreated@doe.com',
                            SuppliedName='testEmailNameDoesntGetCreated@doe.com',
                            Subject='Feedback - Something');
        insert c;

        List<Contact> johnDoes = [select Id from Contact where Email='testEmailNameDoesntGetCreated@doe.com'];

        //there should be only 1 -- the trigger should not have created another
        System.assert(johnDoes.size()==0, 'There should be no John Does!');
    }
*/    
    public static testMethod void testThrowContactCreateException() {
        Case c = new Case(SuppliedEmail='abcef@doe.c0m',
                            SuppliedName='AbcdeAbcdeAbcdeAbcdeAbcdeAbcdeAbcdeAbcdeAbcde Xyz',
                            Subject='Feedback - Something');
        insert c;

        List<Contact> johnDoes = [select Id from Contact where Email='abcef@doe.c0m'];
        
        //there should be none -- the trigger should not have created a Contact
        System.assert(johnDoes.size()==0, 'There should be no John Does!');
    }
    
    }