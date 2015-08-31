/**
 * Unit Test: TestProgramTrigger
 */
trigger ProgramTrigger on Program__c (after insert) {
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            // Cast to generic sobj list since this is what we'll be doing with the trigger factory later.
            List<SObject> newSobjList = (List<SObject>) Trigger.new;
            ProgramHandler.bulkAfterInsert(newSobjList);
        }
    }
}