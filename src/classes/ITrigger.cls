/**
 * @description Interface containing methods Trigger Handlers must implement to enforce best practice
 *              of one trigger per object and bulkification of triggers.
 * All Components involved:
 * ITrigger.cls
 * TriggerFactory.cls
 * TriggerException.cls
 * One trigger per sobject for all events involved (e.g. CaseTrigger.trigger)
 * One handler class per sobject with all logic to be executed (e.g. CaseHandler.cls)
 *
 */
public interface ITrigger {
    /**
     * beforeDelete
     *
     * This method is called once for the full list of records during BEFORE DELETE trigger.
     * You can iterate through the list in your handler or farm the full list to another class.
     * @param List of old sObjects (Trigger.old)
     * @param Map of old sObjects (Trigger.oldMap)
     */
    void bulkbeforeDelete(List<SObject> oldList, Map<Id, SObject> oldMap);

    /**
     * beforeInsert
     *
     * This method is called once for the full list of records during a BEFORE INSERT trigger.  
     * You can iterate through the list in your handler or farm the full list to another class.
     * @param List of new sObjects (Trigger.new)
     */
    void bulkBeforeInsert(List<SObject> newList);

    /**
     * beforeUpdate
     *
     * This method is called once for the full list of records during BEFORE UPDATE trigger.
     * You can iterate through the list in your handler or farm the full list to another class.
     * @param Map of new sObjects (Trigger.newMap)
     * @param List of new sObjects (Trigger.new)
     * @param Map of old sObjects (Trigger.oldMap) (if needed, oldList can be recreated with oldMap.values())
     */
    void bulkBeforeUpdate(Map<Id, SObject> newMap, List<SObject> newList, Map<Id, SObject> oldMap);

    /**
     * afterDelete
     *
     * This method is called for the full list of records inserted during an AFTER DELETE
     * trigger. 
     * @param List of old sObjects (Trigger.old)
     * @param Map of old sObjects (Trigger.oldMap)
     */
    void bulkAfterDelete(List<SObject> oldList, Map<Id, SObject> oldMap);

    /**
     * afterInsert
     *
     * This method is called for the full list of records inserted during an AFTER INSERT
     * trigger. Always put field validation in the 'After' methods in case another trigger
     * has modified any values. The record is 'read only' by this point.
     * @param List of new sObjects (Trigger.new)
     */
    void bulkAfterInsert(List<SObject> newList);

    /**
     * afterUpdate
     *
     * This method is called for the full list of records inserted during an AFTER UPDATE
     * trigger. Always put field validation in the 'After' methods in case another trigger
     * has modified any values. The record is 'read only' by this point.
     * @param Map of new sObjects (Trigger.newMap)
     * @param List of new sObjects (Trigger.new)
     * @param Map of old sObjects (Trigger.oldMap) (if needed, oldList can be recreated with oldMap.values())
     */
    void bulkAfterUpdate(Map<Id, SObject> newMap, List<SObject> newList, Map<Id, SObject> oldMap);

    /**
     * afterUndelete
     *
     * This method is called for the full list of records inserted during an AFTER UNDELETE
     * trigger. 
     * @param List of new sObjects (Trigger.new)
     */
    void bulkAfterUndelete(List<SObject> newList);

    
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this 
     * method to accomplish any final operations such as creation or updates of other records.
     * Example use: DML operations that apply to multiple trigger events without having to copy/paste
     * the same code into multiple event methods.
     */
     
    void andFinally();
}