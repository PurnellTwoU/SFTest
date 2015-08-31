/**
* This controller extension backs the AddService.page VisualForce page.
* A user uses the AddService page to create one or more requests to 
* create a new User Account for a particular employee, represented as a
* Contact.
*
* Terminology
* -----------
*
* User Account:
* Stored in DB as a User_Account__c record. Represents a user account,
* such as a 2tor email account or a salesforce login. For example, if the 
* user has a 2Tor email account and a Salesforce login for MSE, the DB 
* will contain two User_Account__c records for that user, one for each 
* login. A User Account can be allocated to a specific employee 
* (represented by Contact record) and subsequently deactivated and 
* reactivated as needed.
* 
* User Account Request: 
* AKA "User Account Case", "User Account Event", or (within 
* the scope of this Apex class) simply "Request". 
* Stored in DB as an User_Account_Case__c record. Represents an action 
* to be taken in regard to a User Account (User_Account__c) and Contact 
* (e.g. "create a 2Tor email account for John Doe" or "deactivate John 
* Doe's MSE Salesforce login"). This controller only deals with User 
* Account Requests creating new User Accounts.
*
* Service:
* Stored in DB as a Service__c record. Represents a service, such as 
* 2Tor email, for which users can request User Accounts. For example, 
* if the company is capable of assigning email logins, salesforce 
* logins, and Google logins, the DB should contain three Service__c 
* records, one for email logins, one for Salesforce logins, and one 
* for Google logins.
*
* The Service__c.Available_on_Provisioning_Case__c field determines 
* whether the Service__c can be offered for account creation. If this 
* field is false, this controller ignores that Service record. 
*
* Role:
* Stored in DB as a Salesforce_Role__c record, a child of a Service__c 
* record, via the Service__c.Salesforce_Roles__r relationship. Particularly
* applies to Service__c records representing logins for Salesforce orgs.
* Tells the creator of the User_Account__c record what role to assign the 
* new user. Not all Service__c records necessarily have Salesforce_Role__c
* records.
*
* Profile:
* Stored in DB as a Salesforce_Profile__c record, a child of a Service__c 
* record, via the Service__c.Salesforce_Profiles__r relationship. Particularly
* applies to Service__c records representing logins for Salesforce orgs.
* Tells the creator of the User_Account__c record what Profile to assign the 
* new user. Not all Service__c records necessarily have associated 
* Salesforce_Profile__c records.
*
* Constants
* ---------
* The following constants are relevant to this class:
* - NewHireUtil.USER_ACCOUNT_CASE_TYPE_DROP
* - NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE
* - NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN
* - NewHireUtil.NewHireUtil.UACASE_RTYPE_FOR_SRV_FIELDSET
*
* URL Parameters
* -------------- 
* "id" - The Salesforce ID of a provisioning Case (henceforth, 
*        "the Case" or "theCase"). theCase.prEmployee__c should 
*        point to a Contact record for the person to whom the user is 
*        requesting User Accounts (henceforth, "the Contact" or 
*        "theContact"). 
*
* Supported Viewing Tasks
* -----------------------
*
* This controller extension implements the following viewing tasks:
* 1. Viewing a list of available Services, with their available Roles 
*    and Profiles (if any exist).
*
* Implemented Actions
* -------------------
* This controller extension explicitly implements the following actions:
* 1. Going to the UserAccountCase page (via a button labeled "Back").
* 2. Creating a request to allocate to the Contact a User Account  
*    for a particular service. A due date, Service, and Role are collected 
*    on the interface.
*
* AddServiceController Class Design
* ---------------------------------
* When setServices is called, this page queries a list of 
* appropriate Service__c records and saves them in a private list.
*
* When getServices is called, a list of ServiceWrapper 
* instaces is created from the list of Service__c records and
* saved in a list as well. The new ServiceWrapper instances are 
* returned to be displayed in the table.
*
* The nested ServiceWrapper class is a value holder for the 
* information to be displayed/collected from a Service__c record.
* Members of the Service__c.Salesforce_Roles__r and 
* Service__c.Salesforce_Profiles__r relationships are used to generate 
* lists of SelectOptions, to be displayed with the ServiceWrapper.
*
* When the user submits an action, via the addServices() action method,
* the user's inputs (which services are being requested, due dates, profile 
* selection, and Role selection ) are retrieved from the HTTP request using 
* the ID values of the respective fields, which are passed as variable names 
* in the HTTP request.
*
* Page State
* ----------
* All member variables in this class are saved in the client-side pageState
* and are thus persistent across multiple page loads. This means that the 
* records queried are only queried once per visit to the AddService page
* is first loaded and not re-queried if this page is re-loaded.
* 
* Quirks
* ------
* - Whole page displays blank (no warnings/errors) if 
*   the Case is a Drop case.
*
* - Since field values are pulled as raw strings, their values 
*   are not validated server-side. They are, however validated 
*   client-side. This is less than ideal but should be sufficient, 
*   since this controller will not be fielding requests from 
*   any clients other than those submitting through the AddService 
*   page. A malicious coder could theoretically spoof such a request, 
*   but not without a valid Salesforce login token.
* 
*/
public class AddServiceController
{	
	// The Case in relation to which this controller creates User Account Requests
	//
    private Case theCase;

	// The list of ServiceWrapper instances that we will 
	// display to the user, one instance for each Service__c we offer.
    public List<ServiceWrapper> wrapperList{get;set;}    
    
    // The list of Service__c records on which the wrapperList is based.
    public List<Service__c> serviceList = new List<Service__c>();
    
    // Map for resolving Access_Package___c Ids.
    public Map<Id,Access_Package__c> accessPackages = new Map<Id, Access_Package__c>();
    
    // The size of the above serviceList
    public Integer servicesSize;    
    
    // Whether or not there was an error on this page.
    // Determines whether messages will display for this page.
    public Boolean error{get;set;}
    
    /**
    * Initialize this instance with the given controller.
    * Query information for the case pointed to by controller.getRecord()
    */ 
    public AddServiceController(ApexPages.StandardController controller) {
        this.theCase = (Case)controller.getRecord();
        
        this.theCase = [
        	select 
        		Id, 
        		type, 
        		prEmployee__c,
        		Due_Date__c
        	from Case 
        	where Id =: theCase.Id
        ];        
    }
    
    /**
    * Return true if the user should be allowed to add a Service
    * Request to this controller's Case.
    */
    public Boolean getCanAddService()
    {
    	return this.theCase.Type != NewHireUtil.CASE_TYPE_DROP;
    }
    
    /**
    * Find a list of Service__c records, along with their Profile__c
    * and Role__c records. Populate the serviceList with the found 
    * Service__c records.
    *
    * The Services found here will be wrapped in ServiceWrapper 
    * instances (via getServices()) and displayed to the user when the 
    * user is asked to choose a Service for which to request a 
    * User_Account__c. 
    * 
    */
    public void setServices()
    {   
        List<Service__c> serviceList = [
        	select 
        		Id, 
        		Name, 
        		Field_Set__c,
                Offer_Access_Packages__c,
                (select
                    Id,
                    Name,
                    Service__c,
                    Service_Role__c,
                    Service_Profile__c
                from Access_Packages__r
                where Available_on_Provisioning_Case__c = true
                order by Name asc)
        	from Service__c 
        	where Available_on_provisioning_case_c__c = true
        	order by Field_Set__c desc
        ];
        
        // Cache all of our Access_Package__c records so we can resolve them later from 
        // the user's selected ID.
        Map<Id,Access_Package__c> accessPackages = new Map<Id, Access_Package__c>();        
        for(Service__c service : serviceList)
        {
            for(Access_Package__c accessPackage : service.Access_Packages__r)
            {
                accessPackages.put(accessPackage.Id, accessPackage);
            }
        }
        
        this.accessPackages = accessPackages;
        this.serviceList = serviceList;
        
    }
    
    /**
    * Wrap each Service__c record from the current 
    * serviceList (found via setServices()) in a 
    * ServiceWrapper instance and return a list of the 
    * newly created wrappers.
    *
    * If a Service__c has nested Service_Profile__c 
    * or Service_Role__c records, these will be wrapped in 
    * SelectOption instances and passed into the ServiceWrapper 
    * instance.
    *
    * The serviceWrappers returned here are displayed when the 
    * user is asked to choose for which services a new 
    * User_Account__c should be requested. 
    */ 
    public List<ServiceWrapper> getServices()
    {
        List<SelectOption> accessPackageOptions = null;
        
        List<Service__c>  services = serviceList;
        setServicesSize(services.size());  
        wrapperList = new List<ServiceWrapper>();
                
        for(Service__c service : services)
        {
            if(service.Offer_Access_Packages__c)
           {
               accessPackageOptions = new List<SelectOption>();
               List<Access_Package__c> accessPackages = service.Access_Packages__r;
           
               for(Access_Package__c accessPackage : accessPackages)
               {
                    accessPackageOptions.add(new SelectOption(accessPackage.ID, accessPackage.Name));
               }
            }
            else
            {
                accessPackageOptions = null;
            }
          
           wrapperList.add(new ServiceWrapper(
           	service.Name, 
            accessPackageOptions,
           	service.Field_Set__c, 
           	service.Id));
        }
                
        return wrapperList;
    }
    
    /**
    * Create a User_Account_Case__c corresponding to each Service 
    * for which the user has requested that a User_Account__c be created.
    *
    * Information is pulled from the request parameters with the following 
    * names, where i is a number from 0 to N-1, where N is the number of 
    * services available:
    *
    * main:theForm:infoPanel:repeat:i:service
    * - If 'on', a User_Account_Case__c will be created.
    *
    * main:theForm:infoPanel:repeat:i:sprofile
    * - Populates User_Account_Case__c.Profile__c
    * 
    * main:theForm:infoPanel:repeat:i:srole
    * - Populates User_Account_Case__c.Role__c
    *
    * main:theForm:infoPanel:repeat:i:sname
    * - (not currently used)
    *
    * main:theForm:infoPanel:repeat:i:sid
    * - Populates User_Account_Case__c.Service__c
    *
    * main:theForm:infoPanel:repeat:i:sdate
    * - Populates User_Account_Case__c.Date__c
    *
    * main:theForm:infoPanel:repeat:i:sfieldset
    * - Converted to an ID via the NewHireUtil.SERVICE_RECORD_TYPE_FOR_SERVICE_FIELD_SET map.
    * - ID populates User_Account_Case__c.RecordTypeId
    *
    * main:theForm:infoPanel:repeat:i:sgeopointe
    * - Populates User_Account_Case__c.Needs_Geopoint__c
    *
    * main:theForm:infoPanel:repeat:i:notes
    * - Populates User_Account_Case__c.Notes__c
    *
    */
    public void addServices()
    {
        String paramString = 'main:theForm:infoPanel:repeat:';
        Map<String,String> currParameters = System.currentPagereference().getParameters();      
        Set<String> keySet = currParameters.keySet();
 
 
        Map<String, String> fieldSetRcrdMap = NewHireUtil.UACASE_RTYPE_FOR_SRV_FIELDSET;
        List<User_Account_Case__c> uaInsertList = new List<User_Account_Case__c>();
        
        try
        {
            // For each Service we offered the user ...
            for(Integer i = 0; i < getServicesSize(); i++)
            {
                
                
                // ... find out whether the user wants to request that service.
                String serviceFlag = currParameters.get(paramString + i + ':service');
                
                // If the user requested the service ...
                if(serviceFlag == 'on')
                {
                        // ... Extract the user-selected information for this Service__c ...
                        //
                        Id accessPackageId = (Id)currParameters.get(paramString + i + ':accesspackage');
                        String sId         = currParameters.get(paramString + i + ':sid');
                        String sdate       = currParameters.get(paramString + i + ':sdate');
                        String sfieldset   = currParameters.get(paramString + i + ':sfieldset');
                        Boolean geopointe  = (currParameters.get(paramString + i + ':sgeopointe') == 'on') ? true : false;
                        String notes       =  currParameters.get(paramString + i + ':snotes');
                        
                        // Place the user-selected information into a new 
                        // User_Account_Case__c record.
                        //
                        User_Account_Case__c ua = 
                            new User_Account_Case__c(
                                Employee__c       = theCase.prEmployee__c,
                                RecordTypeId      = fieldSetRcrdMap.get(sfieldset), 
                                Case__c           = theCase.Id,
                                Business_Role__c = accessPackageId,
                                Service__c        = sId,
                                Needs_Geopoint__c = geopointe, 
                                Status__c         = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN,
                                Type__c           = NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE, 
                                Notes__c          = notes);
                         
                        
                        // Parse the date from a string into a Date.
                        Date dateNeeded;
                        if(sdate != null && sdate != '')
                        {
                             String[] stringDate = sdate.split('/');
                             Integer m =  Integer.valueOf(stringDate[0]);
                             Integer d = Integer.valueOf(stringDate[1]);
                             Integer y = Integer.valueOf(stringDate[2]);
                             dateNeeded =  date.newInstance(y,m,d);
                             
                             // Use the date (if provided) to populate the Date__c
                             // field on our new Asset_Case__c.
                             ua.Date__c = dateNeeded;
                        }

                        // Add the new User_Account_Case__c to our list.
                        uaInsertList.add(ua);
             
                    
                }
            }
            
            
            if(uaInsertList.size() > 0)
            {
                insert uaInsertList;
            }
        
        }
        catch(DmlException e)
        {
            throw e;
        }
        // If there is a problem ...
        catch(Exception e)
        {
            // Set the error flag so the UI knows to render the message display.
           error = true;
            // Add a message to be displayed.
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while adding the service. Please try again.'));
           return;
        }
        
    
    }
    
    /**
  	* Command method for when the user clicks the "Back" button
  	* on the page. Forwards the user to UserAccountCase.page, 
  	* with the "id" URL paramter set to that of the current Case.
  	*/
    public PageReference back()
    {
        PageReference page = new PageReference('/apex/UserAccountCase?id=' + theCase.Id);
        return page.setRedirect(true);
    }
    
    /**
    * Set the servicesSize variable, intended to represent the number of 
    * services available to the user.
    */ 
    public void setServicesSize(Integer size)
    {
        this.servicesSize = size;
    }
    
    /**
    * @return the value of the servicesSize variable. 
    */
    public Integer getServicesSize()
    {
        return servicesSize;
    }
    
    /**
    * @return the current Case.
    */
    public Case getCase()
    {
    	return this.theCase;
    }
    
    /** 
    *  Wrapper class for each Service that we will offer the user. 
    *  A list of instances of this class will typically be displayed in 
    *  a table, allowing the user to choose a Service for which the user 
    *  wants to request a User_Account__c. 
    */
    public class ServiceWrapper
    {
    	// Normally from Service__c.Name
        public String serviceName{get;set;}
        
        // One SelectOption for each Member of the Service__c.Access_Packages__c
        public List<SelectOption> accessPackages{get;set;}
        
        // Normally from Service__c.Field_Set__c
        public String fieldSet{get;set;}
        
        // Normally from Service__c.Id
        public String serviceId{get;set;}
        
        /**
        * Basic constructor. Populates all member variables.
        */
        public ServiceWrapper(
        	String serviceName, 
            List<SelectOption> accessPackages,
			String fieldSet, 
			String serviceId)
        {
            this.serviceName = serviceName;
            this.accessPackages = accessPackages;
            this.fieldSet = fieldSet;
            this.serviceId = serviceId;
        }
    }
}