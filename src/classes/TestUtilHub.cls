/**
 * @description Test utility class to create test data for objects that are specific to the hub org
 *              and cannot safely be included in TestGlobalUtil since it's deployed across all orgs.
 *              Can be used in addition to TestGlobalUtil.
 */
@isTest
public class TestUtilHub {

    public static List<Asset_Classification__c> testAssetClasses = new List<Asset_Classification__c>();
    public static List<Asset__c> testAssets = new List<Asset__c>();
    public static List<Case> testCases = new List<Case>();
    public static List<IT_Email_To_Addresses__c> testITEmails = new List<IT_Email_To_Addresses__c>();
    public static List<Service__c> testServices = new List<Service__c>();
    public static List<Contact> testContacts = new List<Contact>();
    public static List<User_Account__c> testUserActs = new List<User_Account__c>();

    public static void createAssetClasses() {
        if(testAssetClasses.size() == 0) {
            Asset_Classification__c testClass = new Asset_Classification__c(Name = 'Computer');
            testAssetClasses.add(testClass);

            if(testAssetClasses.size() > 0) {
                insert testAssetClasses;
            }
        }
    }

    public static void generateAssets() {
        createAssetClasses();
        createContacts();
        if(testAssets.size() == 0 && testAssetClasses.size() > 0) {
            for (Integer i = 0; i < 3; i++) {
                Asset__c a = new Asset__c(Make__c = 'test make', Model__c = 'test model', Serial_Number__c = '1234' + i,
                    Asset_Classification__c = testAssetClasses.get(0).Id, Contact__c = testContacts.get(0).Id);
                testAssets.add(a);
            }
        }
    }

    public static void createAssets() {
        generateAssets();
        if(testAssets.size() > 0 && testAssets[0].Id == null) {
            insert testAssets;
        }
    }


    public static void generateCases() {
        if(testCases.size() == 0) {
            for (Integer i = 0; i < 2; i++) {
                Case c = new Case();
                testCases.add(c);
            }
        }
    }

    /**
     * @description Inserts the generated cases
     */
    public static void createCases() {
        generateCases();
        if(testCases.size() > 0 && testCases[0].Id == null) {
            insert testCases;
        }
    }

    public static void createITEmailSetting() {
        if(testITEmails.size() == 0) {
            IT_Email_To_Addresses__c testAddress1 = new IT_Email_To_Addresses__c(Email__c = 'mthomas@2u.com',
                    Name = 'Tester1', Email_in_Sandbox__c = true);
            IT_Email_To_Addresses__c testAddress2 = new IT_Email_To_Addresses__c(Email__c = 'tester@tester.com',
                    Name = 'Tester2', Email_in_Sandbox__c = false);
            testITEmails.add(testAddress1);
            testITEmails.add(testAddress2);
            insert testITEmails;
        }
    }

    public static void createServices() {
        if(testServices.size() == 0) {
            testServices.add(new Service__c(Name = 'Google Apps'));
            insert testServices;
        }
    }

    public static void createContacts() {
        if(testContacts.size() == 0) {
            testContacts.add(new Contact(FirstName = 'Contact', LastName = 'Tester', Email = 'testcontact@tester-2u.com'));
            insert testContacts;
        }
    }

    public static void createUserAccounts() {
        createServices();
        createContacts();
        if(testUserActs.size() == 0) {
            testUserActs.add(new User_Account__c(Service__c = testServices.get(0).Id, Contact__c = testContacts.get(0).Id));
            insert testUserActs;
        }
    }

    /** 
     * @description Provide code coverage for test utility
     */
    public static testMethod void testTestGlobalUtil() {
        TestUtilHub.createAssetClasses();
        TestUtilHub.createAssets();
        TestUtilHub.createCases();
        TestUtilHub.createITEmailSetting();
        TestUtilHub.createServices();
        TestUtilHub.createContacts();
        TestUtilHub.createUserAccounts();
      }       
}