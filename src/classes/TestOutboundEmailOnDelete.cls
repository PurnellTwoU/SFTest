/**
 * @description Provides test coverage for OutboundEmailOnDelete class which is called by the Case and Asset__c trigger
 *              after delete.
 */
@isTest 
private class TestOutboundEmailOnDelete {

    private static testmethod void testNoEmailAddress() {
        // Create some assets and then delete them
        TestUtilHub.createAssets();
        delete TestUtilHub.testAssets;

        //Verify that there are no email addresses since we didn't create any custom settings
        System.assertEquals(OutboundEmailOnDelete.toAddresses.size(), 0);

        //Verify that the error string was populated
        System.assertNotEquals(OutboundEmailOnDelete.noEmailError, '');
        if(!GlobalUtil.isSandbox()) {
            System.assertNotEquals(0, OutboundEmailOnDelete.emailMessagesForSend.size());
        }
        
    }

    private static testmethod void testAssetOnDelete() {
        // create custom setting so email addresses are available to test with
        TestUtilHub.createITEmailSetting();

        TestUtilHub.createAssets();

        List<Asset__c> currentAssets = new List<Asset__c>([select Name, Id from Asset__c where Id = :TestUtilHub.testAssets.get(0).Id]);

        String assetNumber = currentAssets.get(0).Name;
        delete TestUtilHub.testAssets[0];

        // verify that an email is created when an asset is deleted
        Messaging.SingleEmailMessage testMessage = OutboundEmailOnDelete.emailMessagesForSend.get(0);

        // verify that the email text contains the asset number (Name) of the deleted asset
        System.assert(String.valueOf(testMessage).contains(assetNumber));

        System.assertNotEquals(0, OutboundEmailOnDelete.emailMessagesForSend.size());
        
    }

    private static testmethod void testCaseOnDelete() {
        // create custom setting so email addresses are available to test with
        TestUtilHub.createITEmailSetting();

        TestUtilHub.generateCases();
        for(Case c :TestUtilHub.testCases) {
            c.RecordTypeId = RecordTypeUtil.findByName('Case.Help_Desk').Id;
        }

        insert TestUtilHub.testCases;

        List<Case> currentCases = new List<Case>([select CaseNumber from Case where Id = :TestUtilHub.testCases.get(0).Id]);
        String caseNumber = currentCases.get(0).CaseNumber;

        delete TestUtilHub.testCases[0];

        // verify that an email is created when a case is deleted
        Messaging.SingleEmailMessage testMessage = OutboundEmailOnDelete.emailMessagesForSend.get(0);

        // verify that the email text contains the case number of the deleted case
        System.assert(String.valueOf(testMessage).contains(caseNumber));

        System.assertNotEquals(0, OutboundEmailOnDelete.emailMessagesForSend.size());
    }
}