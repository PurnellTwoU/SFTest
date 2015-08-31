/**
 * Unit Test: TestObjectMappingHandler
 */
trigger UserAccountTrigger on User_Account__c (before update, after insert) {
    ObjectMappingHandler.processObjMappings('User_Account__c', Trigger.new, Trigger.oldMap);
}