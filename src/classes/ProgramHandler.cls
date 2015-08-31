/**
 * @description Handler class called from ProgramTrigger.  Does not yet use the TriggerFactory or ITrigger interface.
 *              Currently inserts Op Status records (Operating Status is a junction obj b/w Program and State)
 *              for each state after a Program in inserted.
 *              Op Status record creation can be prevented by setting Block_Op_Status_Creation__c to true.
 *              Unit Test: TestProgramTrigger
 */
public with sharing class ProgramHandler {

    // Lazy-loaded list of states
    public static List<State__c> allStates {
        get {
            if(allStates == null) {
                allStates = new List<State__c>([select Id, Name from State__c]);
            }
            return allStates;
        }
        private set;
    }

	public static void bulkAfterInsert(List<sObject> newList) {	
        // Cast sobjects to Program__c so that field bindings are easier to reference
        List<Program__c> programs = (List<Program__c>) newList;
        List<Operating_Status__c> opStatusesToInsert = new List<Operating_Status__c>();

        // Loop through each program, then create an Op Status record for each state
        // Each Program should then have 51 Operating Status records created for each of the 51 State records
        if(programs.size() > 0 && allStates.size() > 0) {
            for(Program__c p : programs) { 
                //verify that Block checkbox isn't checked; if it is, we don't want to create Op Status records
                if(!p.Block_Op_Status_Creation__c) {
                    for(State__c s : allStates) {
                        Operating_Status__c newOpStatus = new Operating_Status__c(State__c = s.Id, Program__c = p.Id);
                        opStatusesToInsert.add(newOpStatus);
                    }
                }
            }
        }

        if(opStatusesToInsert.size() > 0) {
            //TODO Add try/catch and log exceptions
            insert opStatusesToInsert;
        }
	}
}