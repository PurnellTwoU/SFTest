/**
* A controller extension for UpdateContact.page, which handles Update cases.
*
* URL parameters:
*
* id - The ID of the Case whose Contact (indicated by prEmployee__c) we 
*      will update. This value will be interpreted by the 
*      ApexPages.StandardController that this class extends.
*
* This extension fits into the update process as follows:
*
* 1. The employer receives new information an employee, requiring changes 
*    to the employee's Contact record.
*
* 2. An administrator creates an Update Case linked to the Contact.
*
* 3. The administrator, fills in fields on the Case to indicate the 
*    new information.
*
* 4. An administrator in another department reviews the information 
*    on the Update Case, and then completes the case by clicking the 
*    "Update Contact" button. The user is asked to confirm the changes ("Yes" or "No").
*
* 5. If "Yes", the updateContact method is called on this controller extension.
*    This extension moves information from the Case onto its Contact 
*    (e.g. Case.prEmployee__r.LastName = Case.prLast_Name__c). 
*    **Fields left blank on the Case have no effect on the Contact.**
*    
*    If "No", this notUpdateContact() method is called on this extension. 
*    This extension forwards the user to the Case's detail page.
*
* Quirks:
*
* - If the Case does not point to a Contact (the prEmployee__c field is null),
*   This extension forwards the user to the Case detail page without making any changes.
*   or displaying any notifications to warn the user that the action had no effect. 
* 
*/
public class UpdateContactOnCaseExtensions
{
    // The case whose Contact (via prEmployee__c) we will be updating.
    //
    Case theCase;

    //public Boolean error{get;set;}
    public UpdateContactOnCaseExtensions(ApexPages.StandardController stdController)
    {
        this.theCase = (Case)stdController.getRecord();         
    }

    public Boolean getNeedsBusinessRole()
    {
        // Skip this logic if there is no Case.
        //
        if(this.theCase != null)
        {
            // Query for answers to the following questions:
            // - What Type of Case is this?
            // - Does this Case have at least one open User_Account_Case__c records for a Salesforce service?
            // - Does this Case have a Salesforce_Business_Role__c filled in?
            // - Does this Case's Contact already have a Salesforce_Business_Role__c filled in?
            //
            Case queriedCase = [
                select
                    Id, 
                    RecordTypeId,
                    Type,
                    prEmployee__c,
                    Salesforce_Business_Role__c,
                    prEmployee__r.Salesforce_Business_Role__c,

                    (select 
                        Id,
                        Service__r.Field_Set__c
                     from User_Accounts_Cases__r

                     where 
                         Service__r.Field_Set__c = :NewHireUtil.UAC_FIELD_SET_SALESFORCE

                     and (Status__c = :NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN
                       or Status__c = :NewHireUtil.USER_ACCOUNT_CASE_STATUS_NONE)

                     and (Type__c = :NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE
                       or Type__c = :NewHireUtil.USER_ACCOUNT_CASE_TYPE_PROVISION)

                     limit 1
                    )
                from Case where Id = :this.theCase.Id
            ];

            // There is a potential need for Salesforce_Business_Role__c if ...
            //
            if( // ... the Case has a Contact ...
                (queriedCase.prEmployee__c != null)
                // ... the Case is a Provisioning Case ...
            &&  (queriedCase.RecordTypeId == NewHireUtil.RECORDTYPE_PROVISIONING_CASE)
                // ... and the Case is either Add or Update ...
            &&  (  queriedCase.Type == NewHireUtil.CASE_TYPE_ADD 
                || queriedCase.Type == NewHireUtil.CASE_TYPE_UPDATE)
                // ... and the Case has at least one open request for a 
                // Salesforce Account
            &&  (queriedCase.User_Accounts_Cases__r.size() > 0)
            )
            {
                // ... The Case needs a Salesforce_Business_Role__c value if ...

                     // ... the Case has no Salesforce_Business_Role__c ...
                return (queriedCase.Salesforce_Business_Role__c == null 
                     // ... and the Contact does not already have a Salesforce_Business_Role__c
                     && queriedCase.prEmployee__r.Salesforce_Business_Role__c == null);
            }
        }
        return false;
    }

    /** 
    * Perform an update on this controller extension's Contact.
    */
    public PageReference updateContact()
    {
        //try
        //{
            // Pull information about the Case.
            //
            // Throws a DmlException if no Case is found.
            Case caseObj = [select 
                Id, 
                ContactId, 
                prFirst_Name__c, 
                prLastName__c,
                prPosition_Title__c, 
                prPersonal_Email__c, 
                prBudget_Line_Item__c,
                prDepartment__c, 
                prLocation__c, 
                prReports_To__c, 
                prPayroll_Department_Code__c,
                prFull_Time_Part_Time__c, 
                prPersonal_Phone__c, 
                prEmployment_Status__c, 
                prEmployee__c,
                prSigning_Limit__c,
                Salesforce_Business_Role__c,
                prDivision__c,
                prCell_Phone_Reimbursement__c,
                prDesk_Assignment__c                 
            from Case 
            where Id =: theCase.Id];    

            // Pull information about the Contact.
            Contact[] contactList =  [
                select 
                    Id, 
                    FirstName, 
                    LastName 
                from Contact 
                where Id =: caseObj.prEmployee__c
            ];

            // If we found a valid Contact ...
            if(contactList.size() > 0)
            {
                Contact cont = contactList[0];
                
                // Change the fields on the Contact record.
                //
                if(caseObj.prFirst_Name__c != null && caseObj.prFirst_Name__c !='')
                    cont.FirstName = caseObj.prFirst_Name__c;
                if(caseObj.prLastName__c != null && caseObj.prLastName__c !='')
                    cont.LastName = caseObj.prLastName__c;
                if(caseObj.prPosition_Title__c != null && caseObj.prPosition_Title__c != '')
                    cont.Title = caseObj.prPosition_Title__c;
                if(caseObj.prPersonal_Email__c != null && caseObj.prPersonal_Email__c != '')
                    cont.Personal_Email__c = caseObj.prPersonal_Email__c;
                if(caseObj.prBudget_Line_Item__c != null && caseObj.prBudget_Line_Item__c != '')
                    cont.Budget_Line_Item__c = caseObj.prBudget_Line_Item__c;
                if(caseObj.prDepartment__c != null && caseObj.prDepartment__c != '')
                    cont.torDepartment__c = caseObj.prDepartment__c;
                if(caseObj.prLocation__c != null && caseObj.prLocation__c != '')
                    cont.Office_Location__c = caseObj.prLocation__c;
                if(caseObj.prReports_To__c != null)
                    cont.ReportsToId  = caseObj.prReports_To__c;
                if(caseObj.prPayroll_Department_Code__c != null && caseObj.prPayroll_Department_Code__c != '')
                    cont.Billing_Code__c = caseObj.prPayroll_Department_Code__c;
                if(caseObj.prFull_Time_Part_Time__c != null && caseObj.prFull_Time_Part_Time__c != '')
                    cont.Full_Time_Part_Time__c = caseObj.prFull_Time_Part_Time__c;
                if(caseObj.prPersonal_Phone__c != null && caseObj.prPersonal_Phone__c != '')
                    cont.HomePhone = caseObj.prPersonal_Phone__c;
                if(caseObj.prEmployment_Status__c != null && caseObj.prEmployment_Status__c != '')
                    cont.Employment_Status__c = caseObj.prEmployment_Status__c;                         
                if(caseObj.prSigning_Limit__c != null)
                    cont.Signing_Limit__c = caseObj.prSigning_Limit__c;
                if(caseObj.Salesforce_Business_Role__c !=null)
                    cont.Salesforce_Business_Role__c = caseObj.Salesforce_Business_Role__c;   
                if(caseObj.prDivision__c != null && caseObj.prDivision__c != '')
                    cont.Division__c = caseObj.prDivision__c;
                if(caseObj.prCell_Phone_Reimbursement__c != null && caseObj.prCell_Phone_Reimbursement__c != '')
                    cont.Cell_Phone_Reimbursement__c = caseObj.prCell_Phone_Reimbursement__c;
                if(caseObj.prDesk_Assignment__c != null && caseObj.prDesk_Assignment__c != '')
                    cont.Desk_Assignment__c = caseObj.prDesk_Assignment__c;
                
                // Change the Case's status.
                caseObj.RecordTypeId = NewHireUtil.RECORDTYPE_PROVISIONING_CASE_COMPLETE;
                
                // Update the Contact.  
                update cont;
                
                // Update the Case.
                update caseObj;
            } 
            PageReference pgRef = new PageReference('/' + this.theCase.Id); 
            pgRef.setRedirect(true);

            return pgRef;
        //}
        //catch(Exception e)
        //{
            //error = true;
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while updating the contact/case.'+ 
            //                                                  'Please make sure the details are correct and try again.'));
            //return null;
        //} 
    }    
    
    /**
    * When asked, the user opted not to update the Contact.
    * Redirect them to the Case's detail page.
    */
    public PageReference notUpdateContact()
    {
        PageReference pgRef = new PageReference('/' + theCase.Id); 
        pgRef.setRedirect(false);
        return pgRef;       
    }
}