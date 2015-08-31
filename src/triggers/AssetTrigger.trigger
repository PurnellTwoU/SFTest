trigger AssetTrigger on Asset__c (after delete, after undelete,after insert,
        after update, before delete, before insert, before update) {
    TriggerFactory.createHandler(Asset__c.sObjectType);
}