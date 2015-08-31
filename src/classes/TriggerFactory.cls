/**
 * @description Used to instantiate and execute Trigger Handlers associated with sObjects.
 * All Components involved:
 *      ITrigger.cls
 *      TriggerFactory.cls
 *      TriggerException.cls
 * One trigger per sobject for all events involved (e.g. CaseTrigger.trigger)
 * One handler class per sobject with all logic to be executed (e.g. CaseHandler.cls)
 *
 * Full unit test coverage is provided through the use of a dummy TestHelper__c object.  This prevents
 * any unit test dependencies on "real" objects with handlers when deploying to brand new orgs.
 * Components used to provide unit test coverage:
 *      TestHelperTrigger.trigger
 *      TestHelperTrigger.cls
 *      TestHelper__c object
 */
public without sharing class TriggerFactory {

    /**
     * @description Creates and executes a trigger handler. Throws a 
     *              TriggerException if no handler has been coded.
     * @param Schema.sObjectType Object type to process
     */
    public static void createHandler(Schema.sObjectType soType) {
        // Get a handler appropriate to the object being processed
        ITrigger handler = getHandler(soType);
        
        // Make sure we have a handler registered, new handlers must be registered in the getHandler method.
        if (handler == null) {
            throw new TriggerException('No Trigger Handler registered for Object Type: ' + soType);
        }
        
        // Execute the handler to fulfil the trigger
        execute(handler);
    }
    
    /**
     * @description Controls the execution of the handler
     * @param ITrigger (the interface class) Trigger handler to execute
     */ 
    private static void execute(ITrigger handler) {
        // Before Trigger
        if (Trigger.isBefore) {

            if (Trigger.isDelete) {
                handler.bulkbeforeDelete(Trigger.old, Trigger.oldMap);

            } else if (Trigger.isInsert) {
                handler.bulkBeforeInsert(Trigger.new);

            } else if (Trigger.isUpdate) {
                handler.bulkBeforeUpdate(Trigger.newMap, Trigger.new, Trigger.oldMap);
            }

          // After triggers  
        } else {
            
            if (Trigger.isDelete) {
                handler.bulkAfterDelete(Trigger.old, Trigger.oldMap);
                
            } else if (Trigger.isInsert) {
                handler.bulkAfterInsert(Trigger.new);
                
            } else if (Trigger.isUpdate) {
                handler.bulkAfterUpdate(Trigger.newMap, Trigger.new, Trigger.oldMap);  

            } else if (Trigger.isUndelete) {
                handler.bulkAfterUndelete(Trigger.new);
            }

        }
        
        // Perform any post processing (e.g. Insert/update other objects for after triggers)
        /* If you have the same updates for before insert and before update events, you should write the DML here
         * to avoid copy/paste blocks of the same code.
         */
        handler.andFinally();
    }
    
    /**
     * @description Gets the handler for the object type.  Add handlers for additional sobjects here.
     * @param Schema.sObjectType Object type to locate
     * @return ITrigger Trigger handler if one exists or null.
     */
    private static ITrigger getHandler(Schema.sObjectType soType) {
        // Call handler here as we start adding triggers in the format below.  
        
       
        if (isTest && soType == TestHelper__c.sObjectType) {
            return new TestHelperHandler();
        } else if (soType == Case.sObjectType) {
            return new CaseHandler();
        } else if(soType == Asset__c.sObjectType) {
            return new AssetHandler();
        }
        else if (soType == Campaign.sObjectType) {
          return new CampaignHandler();
        }

        if (isTest && soType == TestHelper__c.sObjectType) {
            return new TestHelperHandler();
        }
        // Name handler classes by SobjectnameHandler (e.g. CaseHandler)
        /*else if (soType == Case.sObjectType) {
            return new CaseHandler();
        }*/
        return null;
    }

    public static Boolean isTest = false;

    /**
     * @description Tests invalid SObject handler.
     */
    private static testMethod void testInvalidSObjectType() {
        try {
            createHandler(null);
            System.assert(false, 
                    'Invalid SObjectType did not throw an exception.');
        } catch (TriggerException te) {
            System.assert(true);
        }

    }
    
}