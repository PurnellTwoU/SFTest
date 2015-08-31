/**
 * @description Provides test coverage for ProgramTrigger (which references ProgramHandler).
 */
@isTest
private class TestProgramTrigger {

    private static List<State__c> testStates = new List<State__c>();
    /**
     * @description Insert some State__c records to test with
     */
    private static void createStates() {
        if(testStates.size() == 0) {
            for(Integer i = 0; i < 5; i++) {
                State__c s = new State__c();
                testStates.add(s);
            }
            insert testStates;
        }
    }

    /**
     * @description Test that Operating Status records are created for all applicable programs.
     *              E.g. If there are 50 State Records, 50 Operating Status records should be created for each 
     *              Program.  The exception to this is if the Program record has Block_Op_Status__c set to true.
     *              This field will prevent any Op Status records from being created on Program insert.
     */
	private static testmethod void testOpStatusInserts() {
        TestProgramTrigger.createStates();

        Test.startTest();
        List<Program__c> testPrograms = new List<Program__c>();
        for(Integer i=0; i<2; i++) {
            Program__c p = new Program__c(Name='Test Program' + i);
            if(i == 0) {
                p.Block_Op_Status_Creation__c = true;
            }
            testPrograms.add(p);
        }
        insert testPrograms;
        Test.stopTest();

        List<State__c> currentStates = new List<State__c>([select Id from State__c]);
        List<Program__c> unblockedPrograms = new List<Program__c>([select Id from Program__c where Block_Op_Status_Creation__c != true]);
        System.assert(unblockedPrograms.size() < testPrograms.size());

        List<Operating_Status__c> currentOpsStats = new List<Operating_Status__c>([select Id, Program__c, State__c 
                from Operating_Status__c where Program__c in :unblockedPrograms]);

        /** 
         *  By default, all programs should create an Op Status record for each state.  
         *  But since we're setting the Block_Op_Status field to true for a program, that program should not
         *  create any Op Status records.  So we expect the created number of op status records to equal
         *  unblocked programs multiplied by the number of states, rather than all programs times states.
         */
        Integer potentialTotal = (testPrograms.size() * currentStates.size());
        Integer expectedOpStats = (unblockedPrograms.size() * currentStates.size());

        // There should be as many op statuses created as unblocked programs multipled by states
        System.assertEquals(expectedOpStats, currentOpsStats.size());
        System.assert(expectedOpStats < potentialTotal);
    }
}