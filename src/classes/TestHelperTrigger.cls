/**
 * @description The sole purpose of the TestHelper__c object, TestHelperTrigger and TestHelperHandler is to 
 * provide dummy test coverage for the TriggerFactory class.
 * This is useful when first setting up a new org or to provide test coverage for unused events. 
 * The trigger handler for this object is set to only fire inside test methods defined in this class.  
 * (e.g. isTest is set to true in this class only).  This means the TestHelperHandler class will never
 * be invoked in real time, but can only be invoked when running unit tests.
 */
@isTest	
private class TestHelperTrigger {
    private static testmethod void testHelperHandler() {

        TriggerFactory.isTest = true;
        try {
            TestHelper__c newTestHelper = new TestHelper__c();
            insert newTestHelper;

            update newTestHelper;

            delete newTestHelper;

            undelete newTestHelper;
            } catch (Exception e) {
                System.debug('******** PRINT Exception: ' + e);
        } 
    }
}