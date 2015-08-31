/**
 * The sole purpose of the TestHelper__c object and this trigger is to provide dummy test coverage for the TriggerFactory class.
 * This is useful when first setting up a new org and to provide test coverage for unused events. 
 * The trigger handler for this object is set to only fire inside test methods (isTest is set to true in TestHelperTrigger),
 * so nothing will happen if you actually create/update a TestHelper__c record.
 */
trigger TestHelperTrigger on TestHelper__c (after delete, after undelete,after insert,  
        after update, before delete, before insert, before update) {

    if(TriggerFactory.isTest) {
        System.debug('Begin running test handler...');
        TriggerFactory.createHandler(TestHelper__c.sObjectType);
    }   
}