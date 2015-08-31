/**
 * @description Provides unit test coverage for the LogUtil class, should be deployed across all
 *              orgs and kept up-to-date in the Core repo in GitHub.
 *              This class has a series of methods to test the 4 overloaded log methods in the 
 *              LogUtil class.
 */
@isTest
private class TestLogUtil {

    // create a basic exception class to test with
    private class LogUtilTestBasicException extends Exception {}

	private static final String TEST_LOG_MESSAGE = 'TEST SYSTEM LOG MESSAGE';

    private static final String TEST_CLASS_METHOD = 'TestClass.TestMethod';

    private static String accId = '';

    /**
     * Test logging a basic message
     */
    private static testMethod void testLogMessage() {
        Test.startTest();
        LogUtil.log('TestClass.TestMethod', TEST_LOG_MESSAGE, null);   
        Test.stopTest();

        List<Error_Log__c> testErrorLogs = new List<Error_Log__c>([select Error_Message__c from Error_Log__c 
                where Class_Method__c = :TEST_CLASS_METHOD]);

        System.assertNotEquals(0, testErrorLogs.size());

        List<Id> errorLogIds = new List<Id>();

        // gotta do it this way because long text areas are not filterable in a query
        for(Error_Log__c e : testErrorLogs) {
            if(e.Error_Message__c == TEST_LOG_MESSAGE) {
                errorLogIds.add(e.Id);
            }
        }

        System.assertNotEquals(0, testErrorLogs.size());
    }

    /**
     * Force a DML exception and make sure that it's logged correctly.
     */
    private static testMethod void testLogDMLException() {
        Test.startTest();

        Account badAccount;
        // Force a dml exception by trying to set the account id in an insert call
        try {
            badAccount = new Account(Id = '001000000000000AAA');
            insert badAccount;
        } catch (System.DMLException e) {
            LogUtil.log(TEST_CLASS_METHOD, e, new String[] { badAccount.Id }, 'TEST DEV NOTE');
        }
        Test.stopTest();

        List<Error_Log__c> testErrorLogs = new List<Error_Log__c>([select Error_Message__c, Exception_Type__c,
            Object_Ids__c from Error_Log__c where Class_Method__c = :TEST_CLASS_METHOD and Type__c = 'Exception']);

        System.assertNotEquals(0, testErrorLogs.size());

        for(Error_Log__c e : testErrorLogs) {
            if(e.Object_Ids__c == badAccount.Id) {
                System.assert(e.Exception_Type__c.toLowerCase().contains('dml'));
                System.assertNotEquals(null, e.Error_Message__c);
            }
        }
    }

    /**
     * Create a generic exception and make sure that it's logged correctly.
     */
    private static testMethod void testLogException() {
        Exception testException = new LogUtilTestBasicException(TEST_LOG_MESSAGE);

        Test.startTest();
        LogUtil.log(TEST_CLASS_METHOD, testException, new String[] {}, 'TEST CUSTOM EXCEPTION');
        Test.stopTest();

        List<Error_Log__c> testErrorLogs = new List<Error_Log__c>([select Error_Message__c, Exception_Type__c,
            Object_Ids__c from Error_Log__c where Class_Method__c = :TEST_CLASS_METHOD and Type__c = 'Exception'
            and Exception_Type__c like '%LogUtilTestBasicException%']);

        System.assertNotEquals(0, testErrorLogs.size());
    }

    /**
     * Create a generic exception and log it with an account id for the WhatIds__c field.  
     * Make sure that it's logged correctly.
     */
    private static testMethod void testLogTaskException() {
        Exception testException = new LogUtilTestBasicException(TEST_LOG_MESSAGE);

        TestGlobalUtil.createAccounts();

        if(TestGlobalUtil.testAccounts.size() > 0) {
            accId = TestGlobalUtil.testAccounts.get(0).Id != null ? String.valueOf(TestGlobalUtil.testAccounts.get(0).Id) : '';
        }

        Test.startTest();
        LogUtil.log(TEST_CLASS_METHOD, testException, accId, '');
        Test.stopTest();

        List<Error_Log__c> testErrorLogs = new List<Error_Log__c>([select Error_Message__c, Exception_Type__c,
            Object_Ids__c from Error_Log__c where Class_Method__c = :TEST_CLASS_METHOD and Type__c = 'Exception'
            and Exception_Type__c like '%LogUtilTestBasicException%' and WhatIds__c = :accId]);

        System.assertNotEquals(0, testErrorLogs.size());
    }
    
    /**
     * Submit a dummy message and an account id for the WhatIds__c field to the logging utility and make 
     * sure that it's logged correctly.
     */
    public static testMethod void testLogTaskMessage() {
        TestGlobalUtil.createAccounts();

        if(TestGlobalUtil.testAccounts.size() > 0) {
            accId = TestGlobalUtil.testAccounts.get(0).Id != null ? String.valueOf(TestGlobalUtil.testAccounts.get(0).Id) : '';
        }
        Test.startTest();
        LogUtil.log(TEST_CLASS_METHOD, TEST_LOG_MESSAGE, accId, null);
        Test.stopTest();

        List<Error_Log__c> testErrorLogs = new List<Error_Log__c>([select Error_Message__c from Error_Log__c 
                where Class_Method__c = :TEST_CLASS_METHOD and Type__c = 'Message']);

        System.assertNotEquals(0, testErrorLogs.size());

        List<Id> errorLogIds = new List<Id>();

        // gotta do it this way because long text areas are not filterable in a query
        for(Error_Log__c e : testErrorLogs) {
            if(e.Error_Message__c == TEST_LOG_MESSAGE) {
                errorLogIds.add(e.Id);
            }
        }

        System.assertNotEquals(0, testErrorLogs.size());
    }

}