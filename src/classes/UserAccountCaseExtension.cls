/* 
* Controller extension for the UserAccountCase VisualForce Page.
* This page is used to view, create, an cancel requests related 
* to User Account creation, deactivation, and reactivation.
*
* Terminology
* -----------
*
* User Account:
* Stored in DB as a User_Account__c record. Represents a user account,
* such as 2tor email account or salesforce login. For example, if the 
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
* Doe's MSE Salesforce login"). 
*
* Each Provisioning Case has its own set of User Account Requests and 
* only deals with those User Account Requests. This extension ignores 
* User Account Requests related to other Cases. The Contact in question is
* obtained from the Case's prEmployee__c field.
*
* Open/Complete/Canceled Requests:
* As appropriate departments work on the Request, the 
* User_Account_Case__c.Status__c field shows the request's progress as 
* one of several string values defined as static constants in 
* NewHireUtil. See "Constants" below.
*
* Constants
* ---------
* This documentation may refer to certain fields having constant 
* values such as a Status of "Open" or a type of "Deactivate". The 
* string values used in this documentation are used only as a 
* literal reference. The actual in-code string values are defined 
* as static constants in NewHireUtil.cls. 
*
* By convention, the constants include the Object name, 
* variable name, and value name. Specifically, the following 
* constants are relevant to this class:
* 
* - NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE
* - NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE
* - NewHireUtil.USER_ACCOUNT_CASE_TYPE_NONE
* - NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN
* - NewHireUtil.USER_ACCOUNT_CASE_STATUS_COMPLETE
* - NewHireUtil.USER_ACCOUNT_CASE_STATUS_CANCEL
* - NewHireUtil.USER_ACCOUNT_CASE_STATUS_NONE
*
* URL Parameters
* -------------- 
* "id" - The Salesforce ID of a provisioning Case (henceforth, 
*        "the Case" or "theCase"). theCase.prEmployee__c should 
*        point to a Contact record for the person to whom this Case's 
*        requests should be related (henceforth, "the Contact" or 
*        "theContact"). 
*
* Supported Viewing Tasks
* -----------------------
*
* This controller extension implements the following viewing tasks:
* 1. Viewing a list of open (AKA "Pending") requests.
* 2. Viewing a list of complete requests.
* 3. Viewing a list of User Accounts currently belonging to the Contact.
* 
* Note that this controller extension does not support viewing a list of 
* canceled requests. These are ignored.
*
* Implemented Actions
* -------------------
* This controller extension explicitly implements the following actions:
* 1. Canceling a request.
* 2. Creating a request to deactivate a User Account.
* 3. Creating a request to (re)activate a User Account.
* 
* Forwarded Actions
* -----------------
* This controller extension supports the following actions by
* forwarding the user to another page, where the action is implemented:
* 1. Creating a request to create a new User Account (forwards to AddService.page).
*
* UserAccountCaseExtension Class Design
* -------------------------------
* This controller extension conceptualizes each Viewing Task 
* as a table, with one row for each User_Account_Case__c or User_Account__c record. 
* Each row may or may not include buttons and/or fields related to actions that 
* can be taken on that record.
*
* The UserAccountCaseExtension class has two nested "row classes", 
* UserAccountCaseRow and UserAccountRow (one for each Object that might be displayed 
* in a table). A row class is instantiated once for each record displayed in the table. 
* Each instance offers accessors for the record, as well as a Boolean function for 
* each possible action. Each boolean function tells whether or not the action 
* should be made available for that record.
*
* Some actions constitute the creation of a new record. For example, deactivating 
* a User Account requires creating a new User_Account_Case__c record. For such situations,
* a prototype for the new record is generated, and the row class provides an 
* accessor for this prototype. The prototype may be used to collect input from 
* the user (usually as an inline field on the table itself), before the action 
* is completed. To complete the action, the prototype is modified (as needed)
* and then inserted into the database.
*
* Page State
* ----------
* To save on SOQL queries, all rows and prototypes are lazy-loaded. That is, 
* they are created or queried once upon first use, then cached for subsequent 
* uses.
*
* To keep data current and cut back on page size, some data is stored 
* in a transient state, thus excluding it from the client's pageState variable. 
* This means that the lazy-loading optimization described above anly applies 
* to multiple uses within the same page load**. Values cached in the current 
* page load will be forgotten when the server finishes and then re-queried 
* on the next page load. This applies to the following:
*
* - The Case and its associated Contact
* - The current list of open request rows
* - The current list of complete request rows
* - The current list of User Account rows
*
* Sometimes the above cached data must be reset, even though the current server 
* execution has not yet finished. An invalidate() method is supplied for this 
* purpose.
* 
* Other data is saved in the pageState. This means it is lazy-loaded once, 
* then remains persistent, even across multiple page loads. This
* applies to the following:
*
* - All prototype records.
* 
* ** In this context, an Ajax invocation counts as a single "page load", 
*    even though the whole page may not be getting a refresh. A more accurate 
*    (though less intuitive) description would be "server execution" instead 
*    of "page load".
*  
*/
public class UserAccountCaseExtension
{
	// The controller that this instance is extending.
	//
	protected final ApexPages.StandardController controller = null;
	
	// These variables are transient to protect against cases where the 
	// database contents change in between requests.
	// 
	// Because they are transient, you should never access them directly. 
	// Always use their respective get* methods, which will lazy-load the values 
	// and cache them in these variables within the lifespan of a single request.
	// 	
	transient private Map<Id,UserAccountCaseRow> openUserAccountCaseRows = null;
	transient private Map<Id,UserAccountCaseRow> completeUserAccountCaseRows = null;
	transient private Map<Id,UserAccountRow> userAccountRows = null;
	transient protected Case theCase = null;
	
	// The requestPrototypes hold user input data, so we do not mark them as transient.
	// This allows them to persist between requests.
	//
	protected Map<Id,User_Account_Case__c> requestPrototypes = new Map<Id,User_Account_Case__c>(); 
	
	
	/**
	* Basic constructor.
	* @param controller the controller that this instance is extending.
	*/
	public UserAccountCaseExtension(ApexPages.StandardController controller)
	{
		this.controller = controller; 
	}
    
    /**
    * Get the case on which this page operates. Newly queries and caches the record 
    * the upon the first call in each server request. Subsequently, the cached value 
    * is used until the server has finished its execution. 
    * 
    * @return A Case instance with the same ID as the record returned by the 
    *         getRecord() method of this page's ApexPages.StandardController 
    *         instance.  The instance returned by this method should be guaranteed 
    *         to have queried all fields necessary for this page's operation.  
    */
    public Case getTheCase()
    {
    	if(null == this.theCase)
    	{
    		Case c1 = (Case)controller.getRecord();
     		
    		this.theCase = [
        	select 
        		Id, 
        		Type, 
        		Due_Date__c,
        		prEmployee__c 
        	from Case 
        	where Id =: c1.Id
        	];
    	}
    	
    	return this.theCase;
    }
    
    /**
    * @return true if the user is allowed to create a new User_Account_Case__c 
    *         record for this Case.
    */ 
    public Boolean getCanRequestUserAccount()
    {
    	// We cannot request a User Account if this is 
    	// supposed to be a "Drop" case.
    	return this.getTheCase().Type != NewHireUtil.CASE_TYPE_DROP;
    }
    
    /*
    * Discard cached information about this page's display state.
    * Call this method after records are inserted/changed, so that the 
    * potentially changed UserAccountRow and UserAccountCaseRow records 
    * are re-queried when the page tries to re-render its tables.
    *
    * This method is necessary because when the client executes a 
    * command with the option to "rerender" parts of the page dynamically,
    * both the command itself as well as the data necessary to "rerender" 
    * the new display state are obtained in a single server-side execution.
    *
    * Since this class caches state within the scope of a single execution (see 
    * this class's "transient" member variables), this means that the values 
    * used to rerender the page are the cached values from before the command's 
    * execution. This method solves the problem by clearing the "cache".
    */
    public void invalidate()
    {
    	this.openUserAccountCaseRows = null;
    	this.completeUserAccountCaseRows = null;
    	this.userAccountRows = null;    	
    }
    
    /**
	* Get a request prototype for the given User Account. For each given 
	* User Account, a request is lazy-loaded upon the first call to 
	* this method and cached for subsequent calls. The complete list of 
	* cached requests is stored in the client-side page state and thus 
	* persists between page loads.
	*
	* This method pre-populates the User_Account_Case__c fields whose values 
	* are relevant to this extension's features but not action-specific. 
	* Other variables may or may not be pre-populated
	*
	* @param userAccount the User_Account__c record for which we need 
	*        a request prototype. The given User_Account__c must have a valid, 
	*        non-null ID value.
	* @return The request prototype, a User_Account_Case__c record.   
	*  
	*/
    public User_Account_Case__c getRequestPrototype(User_Account__c userAccount)
    {
    	if(!this.requestPrototypes.containsKey(userAccount.Id))
    	{
    		this.requestPrototypes.put(userAccount.Id,new User_Account_Case__c(
    			Date__c         = this.getTheCase().Due_Date__c,
    			Status__c       = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN,
				Employee__c     = this.getTheCase().prEmployee__c,
				User_Account__c = userAccount.Id,
				Case__c         = this.getTheCase().Id
				
				// Owner will be assigned automatically, in SetupUserAccountCase.trigger.
				// The Id used is looked up based on the name specified in 
				// User_Account__c.Service__r.Provisioning_Queue__c 
				//
				// Owner        = <...>
    		));						
    	}

    	User_Account_Case__c theReq = this.requestPrototypes.get(userAccount.Id);
    	
    	// Make sure the info is current.		
		theReq.Role__c         = userAccount.Service_Role__c;
		theReq.Profile__c      = userAccount.Service_Profile__c;
		theReq.Service__c      = userAccount.Service__c;
    	    	
    	return theReq;
	    	    	
    }
    
    /*
    * @return the number of open User_Account_Case__c records for this Case.
    */
    public Integer getOpenUserAccountCaseCount()
    { return this.getOpenUserAccountCaseRows().size(); }
    
    /**
    * @return a list of this UserAccountCaseRow instances, one for each 
    *         of this Case's open User_Account_Case__c records. 
    */
    public List<UserAccountCaseRow> getOpenUserAccountCaseRows()
    { 
    	if(null == this.openUserAccountCaseRows)
    	{
    		this.openUserAccountCaseRows = this.queryUserAccountCaseRows(NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN);
    	}    	
    	return this.openUserAccountCaseRows.values();    	 
    }
    
    /**
    * @return the number of complete User_Account_Case__c records for this Case.
    */
    public Integer getCompleteUserAccountCaseCount()
    { return this.getCompleteUserAccountCaseRows().size(); }
    
    /**
    * @return a list of UserAccountCaseRow instances, one for each 
    *         of this Case's complete User_Account_Case__c records. 
    */
    public List<UserAccountCaseRow> getCompleteUserAccountCaseRows()
    { 
    	if(null == this.completeUserAccountCaseRows)
    	{
    		this.completeUserAccountCaseRows = this.queryUserAccountCaseRows(NewHireUtil.USER_ACCOUNT_CASE_STATUS_COMPLETE);
    	}    	
    	return this.completeUserAccountCaseRows.values(); 
    }
    
    /**
    * Get a Map from User_Account_Case__c IDs to UserAccountCaseRow 
    * instances, one for each User_Account_Case__c where the following are true:
    * 
    * User_Account_Case__c.Case__c = the ID of this.getTheCase().Id
    * User_Account_Case__c.Status__c = the full value of statusFilter (case-insensitive).
	* 
    * @param statusFilter the value which must equal the status values.
    * @return a Map<Id,UserAccountCaseRow> containing one AssetCaseRow instance 
    *         for each relevant User_Account_Case__c record, keyed by that record's ID.
    */ 
    public Map<Id,UserAccountCaseRow> queryUserAccountCaseRows(String statusFilter)
    {
    	Map<Id,UserAccountCaseRow> output = new Map<Id,UserAccountCaseRow>();   	
    	for(User_Account_Case__c uac : [
    		select
    			Id, 
    			Name, 
    			//Account_Type__c, 
    			Case__c, 
    			Date__c, 
    			Needs_Geopoint__c,
    			Notes__c, 
    			Profile__c, 
    			Role__c, 
    			Service__c, 
    			Status__c, 
    			Type__c, 
    			User_Account__c,
    			User_Account__r.Name, 
    			Action__c, 
    			Service__r.Name, 
    			Detail_Summary__c, 
    			Status_Summary__c,
    			Date_Complete__c
    		from User_Account_Case__c
    		where 
    			Case__c = :this.getTheCase().Id 
    			and Status__c = :statusFilter
    		order by Date_Complete__c desc nulls first, Date__c desc nulls last
    	])
    	{
    		output.put(uac.Id,new UserAccountCaseRow(uac));    		
    	}
    	return output;
    }
    
    /**
    * @return the total number of User_Account__c records related to this Case's prEmployee__c.
    */ 
    public Integer getUserAccountCount()
    { return this.getUserAccountRows().size(); }
    
    /**
    * @return a list of UserAccountRow instances, one for each User_Account__c record related to 
    *         this Case's prEmployee__c.
    */ 
    public List<UserAccountRow> getUserAccountRows()
    {
    	return this.getUserAccountRowMap().values();    	
    }
    
    /**
    * 
    * @return a UserAccountRow for each User_Account__c record related to 
    *         this Case's prEmployee__c. Each returned record's 
    *         User_Accounts_Cases__r relation will also contain (if they 
    *         exist) the most recent open User_Account_Case__c with 
    *         Type__c=Activate and the most recent open User_Account_Case__c
    *         with Type__c=Deactivate. Only User_Account_Case__c records 
    *         related to the current Case will be considered.   
    */ 
    public Map<Id,UserAccountRow> getUserAccountRowMap()
    {
    	if(null == this.userAccountRows)
    	{    	
	    	this.userAccountRows = new Map<Id,UserAccountRow>();
	    	
	    	// Query User_Account__c records related to this Case's
	    	// employee.
	    	// 
	    	// Also, query certain User_Account_Case__c records 
	    	// relating the User_Account__c to the current Case. The
	    	// UserAccountRow class will use this info to determine 
	    	// whether the user should be able to request an 
	    	// Activation/Deactivation for this User_Account__c	    	 
	    	//
	    	Map<Id,User_Account__c> uaWithActivateMap = new Map<Id,User_Account__c>([
	    		select
	    			Id,
	    			Name,
	    			Active__c,
	    			Service__c,
	    			Service__r.Name,
	    			Detail_Summary__c,
	    			Service_Role__c,
	    			Service_Profile__c,
	    			
	    			// The UserAccountRow class will use the output
	    			// of this nested query.
	    			(select 
	    				Id,
	    				Status__c,
	    				Case__c,
	    				Type__c
	    			from User_Accounts_Cases__r
	    			where 
	    				// The User_Account_Case__c relates this 
	    				// User_Account__c to the current Case.
	    				Case__c   = :this.getTheCase().Id
	    				
	    				// The User_Account_Case__c is open. 
	    				and Status__c   = :NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN
	    				
	    				// The User_Account_Case__c is an Activate case.
	    				// Deactivate cases will be pulled in a separate 
	    				// query (see below)
	    				and Type__c = :NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE
	    				
	    			// Only pull the most recently modified record.
	    			order by LastModifiedDate asc nulls last  
	    			limit 1)
	    				    			
	    		from User_Account__c
	    		where 
	    			Contact__c != null 
	    			and Contact__c = :getTheCase().prEmployee__c
	    		order by LastModifiedDate desc
	    	]);
	    	
	    	// We want to obtain, at most, the following:
	    	//
	    	// - one User_Account_Case__c record per 
	    	//   User_Account__c with User_Account_Case__c.Type__c=Activate
	    	//
	    	// - ... and one with  User_Account_Case__c.Type__c=Deactivate.
	    	// 
	    	// We queried the "Activate" records in the previous query, above. 
	    	// This next query will pull the "Deactivate" records.
	    	//
	    	// We obtain the User_Account_Case__c records in nested User_Account__c 
	    	// queries so that we can limit number of queried rows to one record per 
	    	// User_Account__c record.
	    	//
	    	// We should not merge this query with the one above because, while a 
	    	// nested query does give us means to limit the query output to one 
	    	// User_Account_Case__c record per User_Account__c, we cannot further 
	    	// limit the output to one per User_Account_Case__c.Type__c value. 
	    	//
	    	// Thus, keeping the queries separate prevents the total number of rows from 
	    	// scaling up with the total number (possibly quite large) of 
	    	// User_Account_Case__c records related to this User_Account__c, even 
	    	// though we are only interested in a single record per 
	    	// User_Account_Case__c.Type__c value per User_Account__c.  
	    	//   
	    	Map<Id,User_Account__c> uaWithDeactivateMap = new Map<Id,User_Account__c>([
	    		select Id,
	    		(select
	    				Id,
	    				Status__c,
	    				Case__c,
	    				Type__c
	    			from User_Accounts_Cases__r
	    			where 
	    				// The User_Account_Case__c relates this 
	    				// User_Account__c to the current Case.
	    				Case__c   = :this.getTheCase().Id
	    				
	    				// The User_Account_Case__c is open. 
	    				and Status__c   = :NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN
	    				
	    				// The User_Account_Case__c is a Deactivate case.
	    				and Type__c = :NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE
	    				
	    			// Only pull the most recently modified record.
	    			order by LastModifiedDate asc nulls last  
	    			limit 1	    	
	    		)
	    		from User_Account__c
	    		where Id in :uaWithActivateMap.keySet()
	    	]);
	    	
	    	// Query for open User_Account_Case__c records that are neither 
	    	// "Activate" nor "Deactivate" requests.
	    	Map<Id,User_Account__c> uaWithOtherMap = new Map<Id,User_Account__c>([
	    		select Id,
	    		(select
	    				Id,
	    				Status__c,
	    				Case__c,
	    				Type__c
	    			from User_Accounts_Cases__r
	    			where 
	    				// The User_Account_Case__c relates this 
	    				// User_Account__c to the current Case.
	    				Case__c   = :this.getTheCase().Id
	    				
	    				// The User_Account_Case__c is open. 
	    				and Status__c   = :NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN
	    				
	    				// The User_Account_Case__c is not an Deactivate case.
	    				and Type__c != :NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE
	    				
	    				// The User_Account_Case__c is not a Deactivate case.
	    				and Type__c != :NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE
	    				
	    			// Only pull the most recently modified record.
	    			order by LastModifiedDate asc nulls last  
	    			limit 1	    	
	    		)
	    		from User_Account__c
	    		where Id in :uaWithActivateMap.keySet()
	    	]);
	    	
	    	for(User_Account__c uaWithActivate : uaWithActivateMap.values())
	    	{
	    		User_Account__c uaWithDeactivate = uaWithDeactivateMap.get(uaWithActivate.Id);
	    		User_Account__c uaWithOther      = uaWithOtherMap.get(uaWithActivate.Id);
	    		
	    		// Combine outputs from our User_Account_Case__c nested queries above.
	    		this.userAccountRows.put(uaWithActivate.Id,
	    			new UserAccountRow(uaWithActivate,new UserAccountRowContext(
	    			// The controller
	    			this,
	    			// Whether or not the User_Account__c has any open "Activation" requests
	    			(uaWithActivate.User_Accounts_Cases__r.size()>0),
	    			// Whether the User_Account__c has any open "Deactivation" requests
	    			(null != uaWithDeactivate && uaWithDeactivate.User_Accounts_Cases__r.size()>0),
	    			// Whether the User_Account__c has any open requests other than "Activate"
	    			// or "Deactivate" requests.
	    			(null != uaWithOther      && uaWithOther.User_Accounts_Cases__r.size()>0))
	    		));  
	    	}

	    	// Clean out our requestPrototype cache. Remove entries 
	    	// for User Accounts which are no longer on our list. 
	    	// 
	    	for(Id uaId : this.requestPrototypes.keySet())
	    	{
	    		if(!this.userAccountRows.containsKey(uaId))
	    		{
	    			this.requestPrototypes.remove(uaId);
	    		}
	    	}
    	}
    	
    	return this.userAccountRows;
    }
    
    /**
    * A VisualForce action method to do the following.
    * 
    * 1. Insert an Activation request for the ID given by the value of the 
    *    "editid" GET/POST parameter (see makeActivationChangeRequest()).
    * 2. Invalidate all display lists for this controller extension.
    * 3. Reload the page.
    *  
    */        
    public PageReference requestDeactivation()
    {
    	Id editid = (Id)ApexPages.currentPage().getParameters().get('editid');
    	makeActivationChangeRequest(editid, false);
    	
    	this.invalidate();
    	return null;
    }
    
    /**
    * A VisualForce action method to do the following.
    * 
    * 1. Insert a Deactivation request for the ID given by the value of the 
    *    "editid" GET/POST parameter (see makeActivationChangeRequest()).
    * 2. Invalidate all display lists for this controller extension.
    * 3. Reload the page.
    *  
    */  
    public PageReference requestActivation()
    {
    	Id editid = (Id)ApexPages.currentPage().getParameters().get('editid');
    	makeActivationChangeRequest(editid, true);  
    	
    	this.invalidate();  	
    	return null;
    }
    
    /**
    * A VisualForce action method to do the following.
    * 
    * 1. Query the User_Account_Case__c record whose ID matches the value of the 
    *    "editid" GET/POST parameter. 
    * 2. Change the record's Status__c value to NewHireUtil.USER_ACCOUNT_CASE_STATUS_CANCEL
    * 3. Invalidate all display lists for this controller extension.
    * 4. Reload the page.
    *  
    */
    public PageReference cancelRequest()
    {
    	Id editid = (Id)ApexPages.currentPage().getParameters().get('editid');
    	
    	// Make sure that the record still belongs to our list 
    	// of actionable items
    	//
    	UserAccountCaseRow row = this.queryUserAccountCaseRows(NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN).get(editid);
    	
    	// Make sure that no changes since the last page load
    	// have prevented us from canceling the record.
    	// 
    	if(null == row || !row.getCanCancel())
    	{
    		ApexPages.addMessage(
    			new ApexPages.Message(
    				ApexPages.Severity.ERROR, 
    				'The User Account which you are trying to cancel has changed or is no longer available. Please reload the page and try again.'));
    		return null;
    	}
    	
    	User_Account_Case__c theRequest = [
        		select Id 
        		from User_Account_Case__c
        		where Id = :editid        			
        	];
        	
    	theRequest.Status__c = NewHireUtil.USER_ACCOUNT_CASE_STATUS_CANCEL;
    	update theRequest;
    	    	
    	this.invalidate();    	
    	return null;
    }    
    
    /**
    * A VisualForce action method forwarding the user to the 
    * AddService page with the "id" URL parameter set to this Case's ID.
    */
    public PageReference requestUserAccount()
    {
    	PageReference page = new PageReference('/apex/AddService?id=' + this.getTheCase().Id);
    	return page.setRedirect(true);
    }
    
    /**
    * A VisualForce action method to do the following.
    * 
    * 1. Query the User_Account__c record whose ID matches the value of userAccountId. 
    * 2. Pull the requestPrototype record corresponding to the User Account 
    *    and set Type__c value to NewHirUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE or 
    *    NewHirUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE, depending on makeActive.
    * 3. Insert the prototype record into the DB and remove it from 
    *    our list of prototypes.
    *  
    */
    public void makeActivationChangeRequest(Id userAccountId, Boolean makeActive)
    {    	
    	// Make sure that the record still belongs to our list 
    	// of actionable items
    	//
    	UserAccountRow row = this.getUserAccountRowMap().get(userAccountId);
    	
    	// Make sure that no changes since the last page load
    	// have prevented us from deactivating the record.
    	// 
    	if(null == row  
    	|| ( makeActive && !row.getCanReactivate())
    	|| (!makeActive && !row.getCanDeactivate()))
    	{
    		ApexPages.addMessage(
    			new ApexPages.Message(
    				ApexPages.Severity.ERROR, 
    				'The User Account which you are trying to '+(makeActive?'re-':'de')+'activate has changed or is no longer available. Please reload the page and try again.'));
    		return;
    	}
    	
    	// Extract and modify the prototype.
    	User_Account_Case__c proto = row.getRequestPrototype();
    	proto.Type__c = makeActive
    		?NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE
    		:NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE;
    	
    	// Insert the prototype.
    	insert proto; 
    	
    	// The prototype record now has an ID value, so we cannot re-use it
    	// for a later insertion. Remove it from our cache, to prevent it 
    	// from being re-used.
    	//
    	this.requestPrototypes.remove(userAccountId);
    }
    
       
     /*
	* Encapsulates row-specific logic for a User_Account_Case__c.
	* An instance of this class represents a single User_Account_Case__c 
	* record and offers access to the following information:
	*
	* - The User_Account_Case__c record itself.
	* - Whether the user should be allowed to cancel the User_Account_Case__c.
	*/
	public class UserAccountCaseRow
	{
		private User_Account_Case__c obj = null;
		
		public UserAccountCaseRow(User_Account_Case__c obj)
		{
			this.obj = obj;						
		}
		
		public User_Account_Case__c getObj()
		{
			return this.obj;
		}
		
		/**
		* @return true iff the user should be allowed to cancel this row's User_Account_Case__c
		*/
		public Boolean getCanCancel()
		{
			// We can cancel the request if ...
			return
				// ... The Status__c is Open ... 
				this.obj.Status__c == NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN
				// ... and the User_Account_Case__c is either ...  
				&& (// ... an activation request ...
				    this.obj.Type__c==NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE
				    // ... or a deactivation request. 
				 || this.obj.Type__c==NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE); 
		}		
	}
	
	/**
	* Encapsulates context relevant to a UserAccountRow instance.
	*
	* Context for a record includes the controller to which the UserAccountRow,
	* as well as information about the User_Account__c that was calculated 
	* prior to instantiating the UserAccountRow.
	*
	* Note that the information in an instance of this class may be 
	* invalid if the values entered at instantiation are inaccurate or 
	* if changes are made to the corresponding User_Account__c record
	* subsequent to instantiation.  
	*/
	public class UserAccountRowContext
	{
		// The page controller for the page to which this row belongs.
		private UserAccountCaseExtension controller = null;
		public UserAccountCaseExtension getController() { return this.controller; }
		
		// Whether or not at least one User_Account_Case__c record 
		// exists related to this User_Account__c/Case, with Type__c = NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE. 
		private Boolean hasOpenActivateCase = null;
		public Boolean getHasOpenActivateCase() { return this.hasOpenActivateCase; }
		
		// Whether or not at least one User_Account_Case__c record 
		// exists related to this User_Account__c/Case, with Type__c = NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE. 
		private boolean hasOpenDeactivateCase = null;
		public Boolean getHasOpenDeactivateCase() { return this.hasOpenDeactivateCase; }
		
		// Whether or not at least one open User_Account_Case__c record 
		// exists related to this User_Account__c/Case, with Type__c != NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE
		// and Type != NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE. 
		private Boolean hasOpenOtherCase = null;
		public Boolean getHasOpenOtherCase() { return this.hasOpenOtherCase; }
		
		/*
		* @return true iff the User_Account__c has any open User_Account_Case__c records. 
		*/
		public Boolean getHasAnyOpenCase()
		{
			return this.hasOpenActivateCase || this.hasOpenDeactivateCase || this.hasOpenOtherCase;
		}
		
		/**
		* Create a UserAccountRowContext instance.
		* @param controller the UserAccountCaseExtension instance to which 
		*        this User_Account__c instance belongs.
		* @param hasOpenActivateCase whether or not the User_Account__c has any open "Activation" requests
		* @param hasOpenDeactivateCase  whether the User_Account__c has any open "Deactivation" requests
		* @param hasOpenOtherCase whether the User_Account__c has any open requests other than "Activate"
		*           or "Deactivate" requests.
		*/
		public UserAccountRowContext(
			UserAccountCaseExtension controller, 
			Boolean hasOpenActivateCase, 
			Boolean hasOpenDeactivateCase,
			Boolean hasOpenOtherCase)
		{
			this.controller = controller;			
			this.hasOpenActivateCase = hasOpenActivateCase;
			this.hasOpenDeactivateCase = hasOpenDeactivateCase;
			this.hasOpenOtherCase = hasOpenOtherCase;			
		}
	}
	
	/*
	* Encapsulates row-specific logic for a User_Account__c.
	* An instance of this class represents a single User_Account__c 
	* record and offers access to the following information:
	*
	* - The User_Account__c record itself.
	* - A User_Account_Request__c prototype* pre-populated to correspond to this User_Account__c
	* - Whether the user should be allowed to reactivate the User_Account__c.
	* - Whether the user should be allowed to deactivate the User_Account__c. 
	* - Whether the User_Account__c case has any open Deactivation requests 
	*   related to this Case.**
	* - Whether the User_Account__c case has any open Reactivation requests 
	*   related to this Case.**
	*
	* * The prototypes are actually cached in and pulled from the controller given 
	*   in the constructor. This allows the prototypes to persist beyond the life 
	*   of this AssetRow instance.
	*
	* ** According to the values contained in the UserAccountRowContext instance 
	*    given at instantiation. 
	*/
	public class UserAccountRow
	{	
		// The record represented on this row.
		private User_Account__c obj = null;	
		
		// Additional information relevant to this row.
		private UserAccountRowContext context = null;
		
		/**
		* @param obj the User_Account__c record which this UserAccountRow represents.
		*    
		* @param context additional information related to this UserAccountCaseRow,
		*        including the UserAccountCaseExtension instance to which this 
		*        UserAccountCaseRow belongs.
		*/
		public UserAccountRow(User_Account__c obj, UserAccountRowContext context)
		{			
			this.obj = obj;
			this.context = context;									
		}
							
		/**
		* @return the User_Account__c record that this instance describes.
		*/	
		public User_Account__c getObj()
		{ return this.obj; }
		
		/**
		* @return the prototype User_Account_Case__c record for this User_Account__c. 
		*         The prototypes are actually cached in and pulled from 
		*         the controller so that they can persist beyond the life
		*         of this AssetRow instance.
		*/
		public User_Account_Case__c getRequestPrototype()
		{ return this.context.getController().getRequestPrototype(this.obj); }
		
		/**
		* @return true if the user should be allowed to reactivate the User_Account__c.
		*/
		public Boolean getCanReactivate()
		{ // We can reactivate this User_Account__c if ...
		  return
		  	  // ... the User_Account__c has no open User_Account_Case__c instances related to this Case.
			   !this.context.getHasAnyOpenCase()
			  // ... and the User_Account__c is not Active.
			&& !this.obj.Active__c; }
		
		public Boolean getCanDeactivate()
		{ // We can deactivate this User_Account__c if ...
		  return
		  	  // ... the User_Account__c has no open User_Account_Case__c instances related to this Case.
			   !this.context.getHasAnyOpenCase() 
			  // ... and the User_Account__c is Active.
			&&  this.obj.Active__c; }
		
		/**
		* @return true if the case has a pending activation.
		*/
		public Boolean getHasPendingReactivation()
		{ return  this.context.getHasOpenActivateCase(); }
		
		/**
		* @return true if the case has a pending deactivation.
		*/
		public Boolean getHasPendingDeactivation()
		{ return  this.context.getHasOpenDeactivateCase(); }		
		
	}
    
}