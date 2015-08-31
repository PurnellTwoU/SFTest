/**
@ name          SFConnectionDemoController
@ author        Aslam Bari
@ date          17 July, 2011
@ description   contains the login for the SFConnectionDemo page to demo the
                functionality of Apex Toolkit
*/
public class SFConnectionDemoController{
    public string username {get;set;}
    public string password {get;set;}
    public string securityToken {get;set;}
    
    public list<Record> records{get;set;}
    public SFConnectionDemoController(){
        records = new list<Record>();
    }
    public pageReference Search(){
        records = new list<Record>();
        SFConnectionController controller = new SFConnectionController();
        LoginResult loginResult = controller.login(username, password, securityToken);
        if(!loginResult.isError){
            Response response = controller.query('select Name, Email, Phone, MailingCity, MailingCountry from Contact', loginResult);
            if(!response.isError){
                records = response.data.records;
            }else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,response.message));
            }
        }else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,loginResult.message));
        }
        return null;
    }
}