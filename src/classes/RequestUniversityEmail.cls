public class RequestUniversityEmail {
    public String subject {get; set;}
    public String body {get; set;}
    public List<Attachment> attachments {get; set;}
    
    private final User_Account_Case__c uae;
    private final Case c;
    private final Contact employee;
    private final Service__c service;
    private final User current_user;
    private final Integer number_of_attachments;
    
    //Create a constructor that populates the related objects
    public RequestUniversityEmail(ApexPages.StandardController controller){
        uae = [select id, Case__c, Employee__c, Service__c, Status__c, Type__c, Date__c from User_Account_Case__c where id = :ApexPages.currentPage().getParameters().get('id')];
        c = [select id, prFirst_Name__c, prLastName__c, prReports_To__r.name, prDepartment__c, prPosition_Title__c, prLocation__c from Case where id = :uae.Case__c];
        employee = [select id, email, phone from Contact where id = :uae.Employee__c];
        service = [select id, name, External_Contacts__c from Service__c where id = :uae.Service__c];
        current_user = [select name, email from User where id= :UserInfo.getUserId()] ;
        attachments = new List<Attachment>();
        
        number_of_attachments = 3;
        for(Integer i = 0; i < number_of_attachments; i++){
            attachments.add(new Attachment());
        }
        
        if(service.name == 'Rossier Email'){
            subject =
                'Please issue USC ID for 2U Employee';
            body =
                'Greetings,'
                 + '\n'
                 + '\nPlease issue a new university email account/ID for the 2U employee(s) in the attached spreadsheet. \n'
                 + '\n'
                 + '\nThank you.';                    
        }
        else if(service.name == 'MSW Email'){
            subject =
                'Please issue USC ID for 2U Employee';
            body =
                'Greetings,'
                 + '\n'
                 + '\nPlease issue a university email account/ID for the following new 2U employee:\n'
                 + '\n'
                 + '\nName: ' + c.prFirst_Name__c + ' ' + c.prLastName__c
                 + '\nDOB: (blank)'
                 + '\nOffice Phone: ' + employee.phone
                 + '\nOffice Address: ' + c.prLocation__c
                 + '\n2U Email: ' + employee.email
                 + '\nEmergency Contact: (blank)'
                 + '\nThank you.'; 
        }
        else if(service.name == 'MBA Email'){
            subject =
                'Please issue Kenan-Flagler Business Network Account for 2U Employee';
            body =
                'Greetings,'
                 + '\n'
                 + '\nPlease issue a university email account/ID for the following new 2U employee:\n'
                 + '\n'
                 + '\n' + c.prFirst_Name__c + ' ' + c.prLastName__c
                 + '\nMiddle Initial: (blank) '
                 + '\nPreferred Name: ' + c.prFirst_Name__c
                 + '\nDOB: (blank)'
                 + '\nGender: (blank) ' 
                 + '\n2U Email: ' + employee.email
                 + '\n2U Phone: ' + employee.phone
                 + '\nHome Address: (blank) '
                 + '\n'
                 + '\nTitle: ' + c.prPosition_Title__c
                 + '\nManager: ' + c.prReports_To__r.name
                 + '\nReason for account: (blank)'
                 + '\nOffice Address: (blank)'
                 + '\n'
                 + '\nI will follow up with the SSN via phone after receipt of this email is confirmed.'
                 + '\nThank you.';      
        }
        else if(service.name == 'MSN Email'){
            subject =
                'Please issue GU ID for 2U Employee';
            body =
                'Greetings,'
                 + '\n'
                 + '\nPlease issue a university email account/ID for the following new 2U employee:\n'
                 + '\n'
                 + c.prFirst_Name__c + ' ' + c.prLastName__c
                 + '\n'
                 + '\nThank you.';      
        }
    }
    
    public List<String> getToAddresses(){
        return service.External_Contacts__c.split(';', 0);
    }
    
    public String getCCAddresses(){
        return current_user.email;
    }
   
    public PageReference send(){
        //Define the email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        String[] toAddresses = service.External_Contacts__c.split(';', 0);
        String[] ccAddresses = new List<String> {current_user.email};
        
        
        //Creates the attachements
        List<Messaging.EmailFileAttachment> efaList = new List<Messaging.EmailFileAttachment>();
        for (Attachment a : attachments ){
            if(a.name != '' && a.ContentType != '' && a.body != null){
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(a.Name);
                efa.setBody(a.Body);
                efa.setContentType(a.ContentType);
                efaList.add(efa);
            }
        }

        //Sets the paramaters of the email
        email.setSubject( subject );
        email.setToAddresses( toAddresses );
        email.setCcAddresses( ccAddresses );
        email.setPlainTextBody( body );
        if( efaList <> null ){
            email.setFileAttachments(efaList);
        }
        //Sends the email
        Messaging.SendEmailResult [] r =
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});

        Task t = new Task(
                OwnerId      = current_user.id,
                Subject      = 'Sent email to ' + service.External_Contacts__c,
                ActivityDate = System.today(),
                Status       = 'Completed',
                Type         = 'Email',
                WhatId       = uae.id,
                IsRecurrence = false
                );
        insert t;
        return new PageReference('/' + uae.id);
    }
}