/**
 * @description The sole purpose of this class is to provide dummy tests with empty methods to the TriggerFactory class
 *              in case there are no handler registered for any sObjects (e.g. when setting up a new org).
 */
public without sharing class TestHelperHandler implements ITrigger {
    
    
    // Constructor
    public TestHelperHandler() {
    }

    public void bulkbeforeDelete(List<SObject> oldList, Map<Id, SObject> oldMap) {
        
    }
    
    public void bulkBeforeInsert(List<SObject> newList) {

    }

    public void bulkBeforeUpdate(Map<Id, SObject> newMap, List<SObject> newList, Map<Id, SObject> oldMap) {
        
    }

    public void bulkAfterDelete(List<SObject> oldList, Map<Id, SObject> oldMap) {
        
    }
    
    public void bulkAfterInsert(List<SObject> newList) {
          
    }
    
    public void bulkAfterUpdate(Map<Id, SObject> newMap, List<SObject> newList, Map<Id, SObject> oldMap) {

    }

    public void bulkAfterUndelete(List<SObject> newList) {
        
    }
    
    public void andFinally() {
        
    }
}