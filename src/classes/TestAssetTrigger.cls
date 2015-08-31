/**
 * @description Meets the test coverage required for the AssetHandler class (called by AssetTrigger)
 *              Additional and more specific on-delete coverage is provided in TestOutboundEmailOnDelete.cls
 */
@isTest 
private class TestAssetTrigger {

    private static testmethod void testAssetHandler() {
        TestUtilHub.createAssets();
        if(TestUtilHub.testAssets.size() > 0) {
            update TestUtilHub.testAssets;

            delete TestUtilHub.testAssets;

            // Verify that no assets exist with the ids that were deleted
            List<Asset__c> currentAssets = new List<Asset__c>([select Id from Asset__c
                    where Id in :TestUtilHub.testAssets]);
            System.assert(currentAssets.size() == 0);


            undelete TestUtilHub.testAssets;

            // Verify that the assets have been undeleted and can be queried
            List<Asset__c> undeletedAssets = new List<Asset__c>([select Id from Asset__c
                    where Id in :TestUtilHub.testAssets]);
            System.assert(undeletedAssets.size() > 0);
        }
	}
}