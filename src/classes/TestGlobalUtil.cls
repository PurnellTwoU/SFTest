/**@description Generic utility class to help with writing unit test classes.  Generic enough to deploy
                across orgs.  Add methods to this which deal with standard objects, or custom objects which
                are deployed across all orgs.  Org specific variables and methods should NOT be included in
                this class.
                
                Commented out test that calls CreateLeads due to apparent Salesforce bug reported in SF-7428
*/
@isTest
public class TestGlobalUtil {
    
    //Used in test classes to create an exception when set to true.
    public static Boolean TEST_EXCEPTION = false;
    
    public static List<Lead> testLeads = new List<Lead>();
    public static List<Contact> testContacts = new List<Contact>();
    public static List<Task> testTasks = new List<Task>();
    public static List<User> users = new List<User>();
    public static List<Account> testAccounts = new List<Account>();
    
    /**
    * @description Generates some leads to test with
    */
    public static void generateLeads() {
        if(testLeads.size() == 0) {
            for (Integer i = 0; i < 5; i++) {
                Lead l = new Lead(FirstName = 'FirstName ' + i,
                        LastName = 'LastName' + i, Company = 'Test Co.');
                testLeads.add(l);
            }
        }
    }

    /**
    * @description Inserts the generated leads
    */
    public static void createLeads() {
        generateLeads();
        if(testLeads.size() > 0 && testLeads[0].Id == null) {
            insert testLeads;
        }
    }
    
    /**
    * @description Generates some contacts to test with
    */
    public static void generateContacts() {
        if(testContacts.size() == 0) {
            if(testAccounts.size() == 0) {
                createAccounts();
            }
            for (Integer i = 0; i < 5; i++) {
                Contact c = new Contact(FirstName = 'FirstName ' + i,
                        LastName = 'LastName' + i, AccountId = testAccounts.get(i).Id);
                testContacts.add(c);
            }
        }
    }
    
    /**
    * @description Inserts the generated contacts
    */
    public static void createContacts() {
        generateContacts();
        if(testContacts.size() > 0 && testContacts[0].Id == null) {
            insert testContacts;
        }
    }
    
    /**
    * @description Insert a couple of test users to test with
    */
    public static void createUsers() {
        List<Profile> profiles = new List<Profile>([SELECT Id FROM profile WHERE name LIKE '%Student Support%' or name LIKE '%System Administrator%']);
        if (users.size() == 0 && profiles.size() > 0) {
            User u0 = new User(Username='Test_User0' + UserInfo.getOrganizationId() + '@2tor.com', 
            Email='test_user_1234@2tor.com', LastName='Test_LastName0', Alias='alias', ProfileId=profiles.get(0).Id, LocaleSidKey='en_US', 
            LanguageLocaleKey='en_US', EmailEncodingKey='ISO-8859-1', TimeZoneSidKey = 'GMT', IsActive = true);
            users.add(u0);
            if(profiles.size() > 1) {
                User u1 = new User(Username='Test_User1' + UserInfo.getOrganizationId() + '@2tor.com', 
                Email='test_user_4567@2tor.com', LastName='Test_LastName1', Alias='alias', ProfileId=profiles.get(1).Id, LocaleSidKey='en_US', 
                LanguageLocaleKey='en_US', EmailEncodingKey='ISO-8859-1', TimeZoneSidKey = 'GMT', IsActive = true);
                users.add(u1);
            }
            insert users;
        }
    }
    
    /**
    * @description Create a couple of tasks without inserting them
    */
    public static void generateTasks() {
        if(testTasks.size() == 0) {
            for (Integer i = 0; i < 2; i++) {
                Task t = new Task(Subject = 'subject ' + i, Priority = 'Normal');
                testTasks.add(t);
            }
        }
    }
    
    /**
    * @description Inserts the tasks generated
    */
    public static void createTasks() {
        generateTasks();
        if(testTasks.size() > 0 && testTasks.get(0).Id == null) {
            insert testTasks;
        }
    }
    /**
    * @description Generates some accounts
    */
    public static void generateAccounts() {
        if(testAccounts.size() == 0) {
            for (Integer i = 0; i < 5; i++) {
                Account a = new Account(Name = 'TestAccount ' + i);
                testAccounts.add(a);
            }
        }
    }
    
    /**
    * @description Inserts the accounts generated
    */
    public static void createAccounts() {
        generateAccounts();
        if(testAccounts.size() > 0 && testAccounts.get(0).Id == null) {
            insert testAccounts;
        }
    }
    /** 
    * @description Provide code coverage for test utility
    */
    public static testMethod void testTestGlobalUtil() {
        TestGlobalUtil.createUsers();
        TestGlobalUtil.createContacts();
        //TestGlobalUtil.createLeads(); Commented out due to bug described in SF-7428
        TestGlobalUtil.generateTasks();
        TestGlobalUtil.createAccounts();
        TestGlobalUtil.createTasks();
      }

}