@isTest
public class TestAutoProvision {

    private static Case create_case(Id contact_id){
        Case c = new Case(
                            Subject = 'Test Case',
                            Description = 'Test Case',
                            prEmployee__c = contact_id
                         );

        insert c;

        return c;
    }

    private static Contact create_contact(String email){
        Contact c = new Contact(
                                    FirstName = 'Test',
                                    LastName = 'Contact',
                                    Email = email
                                );
        insert c;

        return c;
    }

    private static Service__c create_service(Id rt_id, String domain){
        Service__c svc = new Service__c(
                                            Name = 'Test Service',
                                            Domain__c = domain,
                                            RecordTypeId = rt_id
                                       );
        insert svc;

        return svc;
    }

    private static User_Account__c create_user_account(Id contact_id, Id svc_id){
        User_Account__c usr_acct = new User_Account__c(
                                                        Contact__c = contact_id,
                                                        Service__c = svc_id
                                                    );

        insert usr_acct;

        return usr_acct;
    }

    private static AutoProvision.APRequest create_ap_request(String domain, Id case_id){
        return new AutoProvision.APRequest(domain, case_id);
    }



	public static testMethod void test_ap_dopost_sf_successful() {
        /*** 
            Test a successful call of the do post function to create a sf user_account event
        ***/

        RecordType sf_rt = [SELECT Id FROM RecordType WHERE Name = 'Salesforce Org' LIMIT 1];
        Service__c svc = create_service(sf_rt.Id, 'tst-abc');

        Contact con = create_contact('test@2u.com');

        Case c = create_case(con.Id);
        User_Account__c usr_acct = create_user_account(con.Id, svc.Id);

        AutoProvision.APRequest req = create_ap_request('tst-abc', c.Id);

        AutoProvision.APResponse resp = AutoProvision.doPost(req);

        system.assertEquals(resp.status_code, 200);
        system.assertEquals([SELECT count() FROM User_Account__c], 1);
        system.assertEquals([SELECT Id FROM User_Account_Case__c Limit 1].Id, resp.new_id);
	}

    public static testMethod void test_ap_dopost_fail_no_user_account(){
        /***
            Test a failed call to the do post function for a  sf user_account event because no user_account exists
        ***/ 
        
        RecordType sf_rt = [SELECT Id FROM RecordType WHERE Name = 'Salesforce Org' LIMIT 1];
        Service__c svc = create_service(sf_rt.Id, 'tst-abc');

        Contact con = create_contact('test@2u.com');

        Case c = create_case(con.Id);

        AutoProvision.APRequest req = create_ap_request('tst-abc', c.Id);

        AutoProvision.APResponse resp = AutoProvision.doPost(req);

        system.assertEquals(resp.status_code, 200);
        system.assertEquals(resp.message, 'User account not found');
        system.assertEquals([SELECT count() FROM User_Account_Case__c], 0);

    }

    public static testMethod void test_ap_dopost_fail_no_contact_email(){
        /***
            Test a failed call to the do post function for a sf_user acct event because the contact has no email
        ***/

        RecordType sf_rt = [SELECT Id FROM RecordType WHERE Name = 'Salesforce Org' LIMIT 1];
        Service__c svc = create_service(sf_rt.Id, 'tst-abc');

        Contact con = create_contact('');

        Case c = create_case(con.Id);
        User_Account__c usr_acct = create_user_account(con.Id, svc.Id);

        AutoProvision.APRequest req = create_ap_request('tst-abc', c.Id);

        AutoProvision.APResponse resp = AutoProvision.doPost(req);

        system.assertEquals(resp.status_code, 200);
        system.assertEquals(resp.message, 'Case contact has no email address');
        system.assertEquals([SELECT count() FROM User_Account_Case__c], 0);

    }
}