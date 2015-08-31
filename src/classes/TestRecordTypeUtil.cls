/**
 * @description Unit test for the RecordTypeUtil class
 * @author mthomas
 */
@isTest
private class TestRecordTypeUtil {

    /**
     * @description Tests finding a record type by id
     */
    private static testMethod void testFindById() {
        Test.startTest();
        for (RecordType rt : [select Id, SobjectType, DeveloperName from RecordType]) {
            System.assertEquals(RecordTypeUtil.findById(rt.Id).Id, rt.Id, 'RecordType IDs do not match.');
            System.assertEquals(RecordTypeUtil.findById(rt.Id).SobjectType, rt.SobjectType, 
                    'RecordType SobjectTypes do not match.');
            System.assertEquals(RecordTypeUtil.findById(rt.Id).DeveloperName, rt.DeveloperName, 
                    'RecordType DeveloperNames do not match.');
        }
        Test.stopTest();
    }
    
    /**
     * @description Tests finding a record type by developer name
     */
    private static testMethod void testFindByName() {
        Test.startTest();
        for (RecordType rt : [select Id, SobjectType, DeveloperName from RecordType]) {
            String developerName = rt.SobjectType + '.' + rt.DeveloperName;
            System.assertEquals(RecordTypeUtil.findByName(developerName).Id, rt.Id, 'RecordType IDs do not match.');
            System.assertEquals(RecordTypeUtil.findByName(developerName).SobjectType, rt.SobjectType, 
                    'RecordType SobjectTypes do not match.');
            System.assertEquals(RecordTypeUtil.findByName(developerName).DeveloperName, rt.DeveloperName, 
                    'RecordType DeveloperNames do not match.');
        }
        Test.stopTest();
    }

}