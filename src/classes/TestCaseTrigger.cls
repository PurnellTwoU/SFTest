/**
 * @description Provides test coverage for CaseTrigger/CaseHandler.  
 *              Additional test coverage for this trigger can be found in:
 *                  TestPopulateX2tor_Program
 *                  TestOutboundEmailOnDelete
 */
@isTest 
private class TestCaseTrigger {
    private static testmethod void testTeamInsert() {
		TestUtilHub.generateCases();
        for(Case c : TestUtilHub.testCases) {
            c.prLocation__c = 'NYC';
            c.RecordTypeId = NewHireUtil.RECORDTYPE_PROVISIONING_CASE;
        }

        insert TestUtilHub.testCases;

        List<Case> currentCases = new List<Case>([select Case_Team_Assignment__c from Case where Id in :TestUtilHub.testCases]);
        
        // Should be NYC Office Contact Case Team
        System.debug('**print cases: ' + currentCases.get(0).Case_Team_Assignment__c);

        // verify that case teams were created for the test cases
        List<CaseTeamTemplateRecord> caseTeams = new List<CaseTeamTemplateRecord>([select Id, ParentId from CaseTeamTemplateRecord
                where ParentId in :currentCases]);

        System.assertNotEquals(0, caseTeams.size());

        // nothing should happen when we update cases and the field values haven't changed
        update TestUtilHub.testCases;

	}

    private static testmethod void testTeamUpdate() {
        TestUtilHub.createCases();
        TestUtilHub.generateCases();
        for(Case c : TestUtilHub.testCases) {
            c.prLocation__c = 'LDR';
            c.RecordTypeId = NewHireUtil.RECORDTYPE_PROVISIONING_CASE;
        }

        update TestUtilHub.testCases;

        // verify that case teams were created when the cases were updated
        List<CaseTeamTemplateRecord> caseTeams = new List<CaseTeamTemplateRecord>([select Id, ParentId from CaseTeamTemplateRecord
                where ParentId in :TestUtilHub.testCases]);
        
        System.assertNotEquals(0, caseTeams.size());

    }

}