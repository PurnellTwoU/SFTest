/* Purpose: Case trigger to assign a contact to a web to case, provisioning case. New contact is created if none existed.
*
* This Trigger performs contains code for two separate features: 
* - A Web-to-Case feature
* - The New Hires Application
*
* Web-to-Case
* -----------
* TODO: Need documentation for this feature
*
* New Hires Application
* ---------------------
* This feature handles various implicit tasks following the 
* creation of a various types of Provisioning Cases. This Trigger
* addresses the following types of cases (based on RecordTypeId):
*
* - Add Cases (RecordTypeId=NewHireUtil.RECORDTYPE_PROVISIONING_ADD)
* - Update Cases (RecordTypeId=NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE)
* - Drop Cases (RecordTypeId=NewHireUtil.RECORDTYPE_PROVISIONING_DROP)
* - Suspend Cases (RecordTypeId=NewHireUtil.RECORDTYPE_PROVISIONING_SUSPENSION)
*
* After making changes for each Case, this trigger changes each Case's 
* RecordTypeId to NewHireUtil.RECORDTYPE_PROVISIONING_CASE.
*
* Each type of case is handled as follows:
*
* Add Case
* --------
* 1. Case.prPersonal_Email__c is looked up in the database.
* 2. If a Contact already exists with Email = Case.prPersonal_Email__c, 
*    the Case is failed. Otherwise, a new Contact is and associated with 
*    the Case.
*
* Update Case
* -----------
* 1. Information is pulled from the fields on the Contact.
* 2. The information from the Contact is placed into corresponding 
*    fields in the Case (e.g. Case.prFirst_Name__c=Contact.FirstName).
* 3. The Case is updated. 
* 
* Drop Case
* ---------
* 1. For each of the Contact's User_Account__c records,
*    a User_Account_Case__c record with Type__c=NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE.
* 2. For each of the Contact's Asset__c records,
*    an Asset_Case__c record with Type__c=NewHireUtil.ASSET_CASE_TYPE_RECLAIM.
*
* Suspend Case
* ------------
* 1. For each of the Contact's User_Account__c records,
*    a User_Account_Case__c record with Type__c=NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE.
* 2. For each of the Contact's Asset__c records,
*    an Asset_Case__c record with Type__c=NewHireUtil.ASSET_CASE_TYPE_RECLAIM.
* 3. An additional Case is created to reactivate the employee on the date indicated by 
*    Case.prReturn_Date__c.
*
* Quirks/Issues:
* 
* - If multiple Cases in this trigger relate to the same Contact (as might occur 
*   in a batch API or Data Loader operation), all but the last Case will be ignored.
*
* - If an Add case is created for an email address with multiple Contacts,
*   the error message provides a link only to the last Contact queried.
*
* - Update, Drop, and Suspend Cases where prEmployee__c is null, 
*   but prPersonal_Email__c is not will behave like Add cases with regard to 
*   the Contact. That is, a Contact will be created if the email does not match 
*   an existing Contact, and the Case creation will fail if the Contact already 
*   exists.
*
* - Suspend Cases where prEmployee__c is null will not generate a 
*   Provisioning case to reactivate the employee, even though a new Contact may 
*   be created is these cases (see above).
*
*
* EDIT: DWBI-292 - 2014-04-06: Account assignmend depends on Case.Emaployee_Type__c. 
*                              Effective after insert and after update.
*/
trigger CaseAutocreateContact on Case (before insert, after insert, after update) {
    
    List<String> emailAddresses = new List<String>();
    List<String> personalEmailAddresses = new List<String>();    
    Map<String, Contact> emailToContatcMap = new Map<String,Contact>();
    Map<String,Contact> provCaseContactsMap = new Map<String,Contact>();
    List<Case> provCasesToUpdate = new List<Case>();
    
    /////////////////////////////
    // BEGIN WEB-TO_CASE CODE  //
    /////////////////////////////
    //
    // The code in the following "if" clause belongs to a 
    // feature unrelated to the New Hires application.
    // It is included here to reduce the number of Triggers 
    // in the org and should be placed in its own Trigger 
    // if the New Hires app is ever packaged for distribution 
    // to another org.
    //
    // See below the following "if" clause for code related to 
    // the New Hires application.
    //    
    if(Trigger.isBefore && Trigger.isInsert)
    {
        //First exclude any cases where the contact is set
        for (Case caseObj:Trigger.new) {
            if (caseObj.ContactId==null &&
                caseObj.SuppliedEmail!='')
            {
                emailAddresses.add(caseObj.SuppliedEmail);
            }           
                 
        }
         //Now we have a nice list of all the email addresses.  Let's query on it and see how many contacts already exist.
         // 
        List<Contact> listContacts = [Select Id,Email From Contact Where Email in :emailAddresses];
        List<Contact> listEduContacts = [Select Id,Email,University_Email__c From Contact Where University_Email__c in :emailAddresses];
        
        Set<String> takenEmails = new Set<String>();
        Map<String, Contact> univEmailCtntMap = new Map<String, Contact>();
        for (Contact c:listContacts) {
            takenEmails.add(c.Email);
        }
        for (Contact c:listEduContacts) {       
            univEmailCtntMap.put(c.University_Email__c, c); // Map contains the university email ids of the contacts which might be assigned to the cases.
        }
        
        Map<String,Contact> emailToContactMap = new Map<String,Contact>();
        List<Case> casesToUpdate = new List<Case>();
        Set<String> univEmails = univEmailCtntMap.keySet();
        //List<CaseOriginSetting__c> caseOriginList = CaseOriginSetting__c.getAll().values();
        for (Case caseObj:Trigger.new) {        
            
            if(caseObj.ContactId==null &&
                caseObj.SuppliedEmail!=null &&
                univEmails.contains(caseObj.SuppliedEmail)) 
            {
                caseObj.ContactId = univEmailCtntMap.get(caseObj.SuppliedEmail).Id; //Assign the contact to the case to a contact with matching email Id 
            }
            
            else if (caseObj.ContactId==null &&
                caseObj.SuppliedName!=null &&
                caseObj.SuppliedEmail!=null &&
                caseObj.SuppliedName!='' &&
                //!caseObj.SuppliedName.contains('@') && //removed this criteria since some 2tor staff use MSW@USC in their names
                caseObj.SuppliedEmail!='' &&
                !takenEmails.contains(caseObj.SuppliedEmail))
            {
                //The case was created with a null contact
                //Let's make a contact for it
                String[] nameParts = caseObj.SuppliedName.split(' ',2);
                String email =  caseObj.SuppliedEmail;
                String univEmail = '';
                String accId = null;
                if(email.endsWith('.edu'))
                {
                    univEmail = email;
                    email = '';
                }
                if(caseObj.Origin != null)
                {
                    //Getting the account details from the custom setting based on the case origin.
                    CaseOriginSetting__c cO = CaseOriginSetting__c.getValues(caseObj.Origin);
                    if(cO != null)
                        accId = cO.AccountId__c;
                    else
                        accId = '001G000000g135M';
                    System.debug('The account Id from the custom setting...' + accId );
                }
                if (nameParts.size() == 2)
                {
                    Contact cont = new Contact(
                    FirstName=nameParts[0],
                    LastName=nameParts[1],
                    University_Email__c=univEmail,
                    Email=email,
                    AccountId = accId
                    );
                    //Program__c = caseObj.Origin
                   // Email=caseObj.SuppliedEmail);                                        
                    emailToContactMap.put(caseObj.SuppliedEmail,cont);
                    casesToUpdate.add(caseObj);
                }
                else 
                {
                    Contact cont = new Contact(               
                    LastName=caseObj.SuppliedName,
                    University_Email__c=univEmail,
                    Email=email,
                    AccountId = accId
                    );
                    //Program__c = caseObj.Origin
                    //Email=caseObj.SuppliedEmail);                                        
                    emailToContactMap.put(caseObj.SuppliedEmail,cont);
                    casesToUpdate.add(caseObj);
                }
            }
        }
        
        List<Contact> newContacts = emailToContactMap.values();   
        try {
            if(newContacts.size() > 0)
            {
                insert newContacts;
            }           
            
        } catch(Exception e) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {'nsnyder@2tor.com','lukec@2tor.com'};
            mail.setToAddresses(toAddresses);
            mail.setReplyTo('lukec@2tor.com');
            mail.setSenderDisplayName('Salesforce Error Logging');
            mail.setSubject('Error in Hub Contact Creat : ' + case.Id);
            mail.setPlainTextBody(e.getMessage());
            mail.setHtmlBody(e.getMessage());
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });    
        }
        
        for (Case caseObj:casesToUpdate) {
            Contact newContact = emailToContactMap.get(caseObj.SuppliedEmail);
            
            caseObj.ContactId = newContact.Id;
        }
    }
    
    
    //////////////////////////
    // BEGIN NEW HIRES CODE //
    //////////////////////////
    //
    // The code in the following "if" statement belongs 
    // to the New Hires application.
    // 
    if(Trigger.isAfter)
    {
        if(Trigger.isInsert)
        {
            // Map relating Contacts to their associated Update, Drop, or Suspension cases. 
            Map<Id,Case> contactIdToCaseMap =  new Map<Id,Case>(); 
            
            // For each Suspension case, we insert an additional Provisioning case for 
            // reactivating the Contact later. Map the "Suspend" Contacts to their 
            // associated Reactivation cases.
            //
            Map<Id,Case> contactIdToCaseMapForSuspension =  new Map<Id,Case>(); 
            
            // New Provisioning Cases which we will insert at the end of this Trigger.
            List<Case> newProvCases = new List<Case>();
            
            // Pre-existing Cases which we will update at the end of this Trigger.
            List<Case> casesToUpdate = new List<Case>();
            
            // For each case we are inserting ...
            for(Case caseObj : Trigger.new)
            {
                // If Transfer the related user accounts and related assets of the contact to the transfer case. 
                if(
                    // If the RecordType relates this Case to an existing Contact (employee) ...
                   (   caseObj.RecordTypeId == NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE 
                    || caseObj.RecordTypeId == NewHireUtil.RECORDTYPE_PROVISIONING_DROP
                    || caseObj.RecordTypeId == NewHireUtil.RECORDTYPE_PROVISIONING_SUSPENSION) 
                    // ... and the existing Contact is specified ...
                   && caseObj.prEmployee__c != null)
                {
                    // ... Map the Contact to its Case.
                    contactIdToCaseMap.put(caseObj.prEmployee__c, caseObj);
                    
                    // If the case is a Suspension Case ...
                    if(caseObj.RecordTypeId == NewHireUtil.RECORDTYPE_PROVISIONING_SUSPENSION)
                    {
                        // ... create a new Case for re-provisioning the employee 
                        // once the suspension period has ended, ...
                        Case nCase = new Case(
                            prEmployee__c          = caseObj.prEmployee__c, 
                            RecordTypeId           = NewHireUtil.RECORDTYPE_PROVISIONING_CASE, 
                            Type                   = NewHireUtil.CASE_TYPE_UPDATE,
                            Due_Date__c            = caseObj.prReturn_Date__c, 
                            prEmployment_Status__c = NewHireUtil.EMPLOYMENT_STATUS_ACTIVE, 
                            Origin                 = NewHireUtil.CASE_AUTOCREATE_ORIGIN);
                        
                        // ... map the Contact to its new Provisioning case, ...
                        contactIdToCaseMapForSuspension.put(caseObj.prEmployee__c, nCase);  
                        // ... and save the Case for later insertion.
                        newProvCases.add(nCase);
                    }
                    
                }
                
                // We cannot add an employee if the DB already contains a Contact
                // for that person. We use the email address to check for this.
                // So, ...
                //
                if(   // ... if the Employee IS NOT specified ...
                      caseObj.prEmployee__c == null 
                      // ... but the email address IS specified ...
                   && caseObj.prPersonal_Email__c != ''
                   && caseObj.prPersonal_Email__c != null 
                      // ... and the Case says to add an employee ...
                   && caseObj.RecordTypeId == NewHireUtil.RECORDTYPE_PROVISIONING_ADD)
                {
                    // ... save the email address so we can use it to query for 
                    // pre-existing Contacts.
                    personalEmailAddresses.add(caseObj.prPersonal_Email__c);            
                }
            }
            
            // If we have email addresses to check (see above) ...
            if(personalEmailAddresses.size() > 0)
            {
                // ... look for Contacts with the email addresses we are checking...
                List<Contact> listProvContacts = [
                        select 
                            Id, 
                            Name, 
                            Personal_Email__c 
                        from Contact 
                        where Personal_Email__c in :personalEmailAddresses
                    ];
                
                // Associate each email address with its Contact. 
                for(Contact con : listProvContacts)
                { emailToContatcMap.put(con.Personal_Email__c, con); }
                
                // For all cases in this trigger ...
                for(Case caseObj : Trigger.new)
                {
                    // Look up which Contact (if any) has this Case's email address.
                    Contact c =  emailToContatcMap.get(caseObj.prPersonal_Email__c);
                    
                    // If the Case specifies an email address for an employee who 
                    // already has a Contact in the DB ...
                    if(c != null)
                    {
                        // ... fail the creation of this Case.
                        caseObj.addError(
                            'At least one Contact already exists for '+
                            '<a href = \'/' + c.Id + '\'>' + c.Name + '</a>' + 
                            '. Click the employee\'s name for details on the last Contact found.');
                    }
                    // ... otherwise ...
                    else 
                    {               
                        try
                        {   
                            // ... create a new Contact to be associated with this Case.
                            c = new Contact(AccountId = NewHireUtil.getAccountIdForNewContact(caseObj),
                                            FirstName = caseObj.prFirst_Name__c,
                                             Personal_Email__c = caseObj.prPersonal_Email__c,
                                             LastName = caseObj.prLastName__c,
			    						 Employment_Status__c = NewHireUtil.EMPLOYMENT_STATUS_NEW
                                             );
                            // Map this Case's email address to the Contact which we will
                            // associate with the Case.
                            provCaseContactsMap.put(caseObj.prPersonal_Email__c, c);
                            
                            // Save the associated Case for updating later.
                            provCasesToUpdate.add(caseObj);     
                        } 
                        // If the getAccountIdForNewContact(...) call above throws an Exception ...
                        catch(NewHireUtil.IdNotFoundException e)
                        {
                            // ... the DB does not contain a properly named default 
                            // account to which we can assign our new Contact. Fail 
                            // this Case creation. 
                            caseObj.addError('Cannot find a default record to assign to the new Contact: '+e.getMessage());             
                        }
                    }
                }
            }
            
            // Insert the new Provisioning Cases, which we created earlier to reactivate
            // the subjects of Suspension Cases.
            // 
            if(newProvCases.size() > 0)
            {
                insert newProvCases;
            }
            
            // A list of User Account Requests which we will insert later.
            List<User_Account_Case__c> uacInsertList = new List<User_Account_Case__c>();
            
            // A list of Asset requests which we will insert later.
            List<Asset_Case__c> acInsertList = new List<Asset_Case__c>();
            

            if(contactIdToCaseMap.size() > 0)
            {
                // As needed, generate new Activate/Deactivate requests for each of 
                // the Contacts' User_Account_Case__c records and Asset_Case__c records. 
                uacInsertList = NewHireUtil.createUserAccounts(contactIdToCaseMap); 
                acInsertList = NewHireUtil.createAssetCases(contactIdToCaseMap);            
                
                // As needed, transfer information from each Contact to its 
                // associated Case record.
                casesToUpdate.addAll(NewHireUtil.updateCasesWithContactAndCaseInfo(contactIdToCaseMap)); 
            }
            if(contactIdToCaseMapForSuspension.size() > 0)
            {
                // As needed, generate new Activate/Deactivate requests for each of 
                // the Contacts' User_Account_Case__c records and Asset_Case__c records. 
                uacInsertList.addAll(NewHireUtil.createUserAccounts(contactIdToCaseMapForSuspension));
                acInsertList.addAll(NewHireUtil.createAssetCases(contactIdToCaseMapForSuspension));
                
                // As needed, transfer information from each Contact to its 
                // associated Case record. Add the Cases to our update list.
                casesToUpdate.addAll(NewHireUtil.updateCasesWithContactAndCaseInfo(contactIdToCaseMapForSuspension));  
            }
            
            // Insert the Contacts we created for our Provisioning Cases
            List<Contact> provNewContacts = provCaseContactsMap.values();
            if(provNewContacts.size() > 0)
            {
                insert provNewContacts;
            }
            
            // Visit each Case for which we just inserted a new Contact.
            //
            for(Case caseObj : provCasesToUpdate)
            {
                // Change the Case record so that is points top the Contact we just inserted.
                
                String subject = caseObj.prFirst_Name__c + ' ' + caseObj.prLastName__c + ' - ' + String.valueOf(caseObj.Due_Date__c);
                Contact newContact = provCaseContactsMap.get(caseObj.prPersonal_Email__c);        
                casesToUpdate.add(new Case(
                    Id=caseObj.Id, 
                    prEmployee__c = newContact.Id, 
                    recordTypeId =  NewHireUtil.RECORDTYPE_PROVISIONING_CASE,
                    prEmployment_Status__c = NewHireUtil.EMPLOYMENT_STATUS_ACTIVE, 
                    subject = NewHireUtil.CASE_SUBJECT_ADD + subject));
            }
            
            // Insert our newly created User_Account_Case__c records.
            if(uacInsertList.size() > 0)
            {
                insert uacInsertList;
            }
                
            // Insert our newly created Asset_Case__c records.
            if(acInsertList.size() > 0)
            {
                insert acInsertList;
            }
            
            // Update Cases which have new Contacts or info pulled from Contacts.
            if(casesToUpdate.size() > 0)
            {
                update casesToUpdate;
            }
        
        } else if(Trigger.isUpdate)
        {
            Map<Id,Case> caseForContactId = new Map<Id,Case>();

            // Find out which Cases changed in a way which require our attention.
            for(Case newCase : Trigger.new)
            {
                Case oldCase = Trigger.oldMap.get(newCase.Id);
               
                if( // If this is a Provisioning Add Case ...
                    (newCase.RecordTypeId == NewHireUtil.RECORDTYPE_PROVISIONING_ADD
                  || (newCase.RecordTypeId == NewHireUtil.RECORDTYPE_PROVISIONING_CASE
                   && newCase.Type         == NewHireUtil.CASE_TYPE_ADD))
                // ... and either ...
                //   ... RecordTypeId has changed (this Case has just become a Add Case) ...
                 && (newCase.RecordTypeId     != oldCase.RecordTypeId
                //   ... or the Employee_Type__c has changed.
                  || newCase.Employee_Type__c != oldCase.Employee_Type__c))
                {
                    if(null != newCase.prEmployee__c)
                    {
                        caseForContactId.put(newCase.prEmployee__c, newCase);
                    }
                }
            }
            
            // Pull the AccountId for each contact of interest.
            List<Contact> contactsToCheck = [
                select 
                    Id, AccountId
                from Contact 
                where Id in :caseForContactId.keySet()
            ];
            
            // Re-assign AccountId for each Contact requiring it.
            //
            List<Contact> contactsToUpdate = new List<Contact>();
            for(Contact thisContact : contactsToCheck)
            {
                Case newCase        = caseForContactId.get(thisContact.Id);
                Id correctAccountId = NewHireUtil.getAccountIdForNewContact(newCase);
               
                if(thisContact.AccountId != correctAccountId)
                {
                    thisContact.AccountId = correctAccountId;
                    contactsToUpdate.add(thisContact);
                }
            }

            // Update any newly changed Contacts.
            //
            if(contactsToUpdate.size() > 0)
            {
                update contactsToUpdate;
            }
        }
        
    }
    
    
}