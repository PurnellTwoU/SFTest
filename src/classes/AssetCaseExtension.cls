/* 
* Controller extension for the AssetCase VisualForce Page.
* This page is used to view, create, an cancel requests related 
* to Asset provisioning and reclamation.
*
* Terminology
* -----------
*
* Asset:
* Stored in DB as an Asset__c record. Represents a tangible asset,
* such as a Laptop. For example, if the org has ten laptops, the DB 
* will contain ten corresponding Asset__c records, one for each laptop. 
* An Asset can be allocated to a specific employee (represented by a 
* Contact record) or reclaimed if the employee no longer needs the 
* Asset.
* 
* Asset Request: 
* AKA "Asset Case", "Asset Event", or (within 
* the scope of this Apex class) simply "Request". 
* Stored in DB as an Asset_Case__c record. Represents an action 
* to be taken in regard to an Asset (Asset__c) and Contact 
* (e.g. "provision a Laptop for John Doe" or "reclaim John 
* Doe's Laptop"). 
*
* Each Provisioning Case has its own set of Asset Requests and 
* only deals with those Asset Requests. This extension ignores 
* Asset Requests related to other Cases. The Contact in question is
* obtained from the Case's prEmployee__c field.
*
* Open/Complete/Canceled Requests:
* As appropriate departments work on the Request, the 
* Asset_Case__c.Status__c field shows the request's progress as 
* one of several string values defined as static constants in 
* NewHireUtil. See "Constants" below.
*
* Constants
* ---------
* This documentation may refer to certain fields having constant 
* values such as a Status of "Open" or a type of "Reclaim". The 
* string values used in this documentation are used only as a 
* literal reference. The actual in-code string values
* are defined as static constants in NewHireUtil.cls. 
*
* By convention, the constants include the Object name, 
* variable name, and value name. Specifically, the following 
* constants are relevant to this class:
* 
* - NewHireUtil.ASSET_CASE_TYPE_NONE
* - NewHireUtil.ASSET_CASE_TYPE_PROVISION
* - NewHireUtil.ASSET_CASE_TYPE_RECLAIM
* - NewHireUtil.ASSET_CASE_STATUS_OPEN
* - NewHireUtil.ASSET_CASE_STATUS_COMPLETE
* - NewHireUtil.ASSET_CASE_STATUS_CANCEL
* - NewHireUtil.ASSET_CASE_STATUS_NONE
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
* 3. Viewing a list of Assets currently allocated to the Contact.
* 
* Note that this controller extension does not support viewing a list of 
* canceled requests. These are ignored.
*
* Implemented Actions
* -------------------
* This controller extension explicitly implements the following actions:
* 1. Canceling a request.
* 2. Creating a request to reclaim an Asset.
* 
* Forwarded Actions
* -----------------
* This controller extension supports the following actions by
* forwarding the user to another page, where the action is implemented:
* 1. Creating a request to allocate an Asset (forwards to AddAsset.page).
*
* AssetCaseExtension Class Design
* -------------------------------
* This controller extension conceptualizes each Viewing Task 
* as a table, with one row for each Asset_Case__c or Asset__c record. 
* Each row may or may not include buttons and/or fields related to 
* actions that can be taken on that record.
*
* The AssetCaseExtension class has two nested "row classes", AssetCaseRow and 
* AssetRow (one for each Object that might be displayed in a table). A row class 
* is instantiated once for each record displayed in the table. Each instance 
* offers accessors for the record, as well as a Boolean function for each possible 
* action. Each boolean function tells whether or not the action should be made 
* available for that record.
*
* Some actions constitute the creation of a new record. For example, reclaiming 
* an asset requires creating a new Asset_Case__c record. For such situations,
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
* - The current list of Asset rows
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
public class AssetCaseExtension
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
	transient private Map<Id,AssetCaseRow> openAssetCaseRows = null;
	transient private Map<Id,AssetCaseRow> completeAssetCaseRows = null;
	transient private Map<Id,AssetRow> assetRows = null;
	transient protected Case theCase = null;
	
	// The requestPrototypes hold user input data, so we do not mark them as transient.
	// This allows them to persist between requests.
	//
	protected Map<Id,Asset_Case__c> requestPrototypes = new Map<Id,Asset_Case__c>(); 
	
	
	/**
	* Basic constructor.
	* @param controller the controller that this instance is extending.
	*/
	public AssetCaseExtension(ApexPages.StandardController controller)
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
    * @return true if the user is allowed to create a new Asset_Case__c 
    *         record for this Case.
    */ 
    public Boolean getCanRequestAsset()
    {
    	// 
    	// We cannot request assets if this is supposed to be 
    	// a "Drop" case.
    	// 
    	return this.getTheCase().Type != NewHireUtil.CASE_TYPE_DROP;
    }
    
    /*
    * Discard cached information about this page's display state.
    * Call this method after records are inserted/changed, so that the 
    * potentially changed AssetRow and AssetCaseRow records 
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
    	this.openAssetCaseRows = null;
    	this.completeAssetCaseRows = null;
    	this.assetRows = null;    	
    }
    
	/**
	* Get a request prototype for the given asset. For each given Asset, 
	* the request is lazy-loaded upon the first call to this method and 
	* cached for subsequent calls. The complete list of cached requests 
	* is stored in the client-side page state and thus persists between 
	* page loads.
	*
	* This method pre-populates the Asset_Case__c fields whose values 
	* are relevant to this extension's features but not action-specific. 
	* Other variables may or may not be pre-populated
	*
	* @param asset The Asset__c record for which we need a request prototype
	*              The given Asset__c must have a valid, non-null ID value.
	* @return The request prototype, an Asset_Case__c record.   
	*  
	*/
    public Asset_Case__c getRequestPrototype(Asset__c asset)
    {
    	
    	if(!this.requestPrototypes.containsKey(asset.Id))
    	{
    		Id empId = this.getTheCase().prEmployee__c;
    		this.requestPrototypes.put(asset.Id,new Asset_Case__c(	
								
					Type__c         = NewHireUtil.ASSET_CASE_TYPE_RECLAIM,
					Status__c       = NewHireUtil.ASSET_CASE_STATUS_OPEN,					
					Date_Needed__c  = this.getTheCase().Due_Date__c,
					Employee__c     = (empId==null?asset.Contact__c:empId),
					Asset__c        = asset.Id,					
					Case__c         = this.getTheCase().Id,
					
					// Owner will be assigned automatically, in SetupAssetCase.trigger.
					// The Id used is looked up based on the name specified in 
					// Asset__c.Service__r.Provisioning_Queue__c 
					//
					// Owner        = <...>
					
					Asset_Classification__c = asset.Asset_Classification__c		
				));						
    	}

    	Asset_Case__c theReq = this.requestPrototypes.get(asset.Id);
    	
    	// Make sure the userAccount info is current.
    	theReq.Asset_Classification__c = asset.Asset_Classification__c;
    	
    	return theReq;
	    	    	
    }
    
    /*
    * @return the number of open Asset_Case__c records for this Case.
    */
    public Integer getOpenAssetCaseCount()
    { return this.getOpenAssetCaseRows().size(); }
    
    /**
    * @return a list of this AssetCaseRow instances, one for each 
    *         of this Case's open Asset_Case__c records. 
    */
    public List<AssetCaseRow> getOpenAssetCaseRows()
    { 
    	if(null == this.openAssetCaseRows)
    	{
    		this.openAssetCaseRows = this.queryAssetCaseRows(NewHireUtil.ASSET_CASE_STATUS_OPEN);
    	}    	
    	return this.openAssetCaseRows.values();    	 
    }
    
    /**
    * @return the number of complete Asset_Case__c records for this Case.
    */
    public Integer getCompleteAssetCaseCount()
    { return this.getCompleteAssetCaseRows().size(); }
    
    /**
    * @return a list of AssetCaseRow instances, one for each 
    *         of this Case's complete Asset_Case__c records. 
    */
    public List<AssetCaseRow> getCompleteAssetCaseRows()
    { 
    	if(null == this.completeAssetCaseRows)
    	{
    		this.completeAssetCaseRows = this.queryAssetCaseRows(NewHireUtil.ASSET_CASE_STATUS_COMPLETE);
    	}    	
    	return this.completeAssetCaseRows.values(); 
    }
    
    /**
    * Get a Map from Asset_Case__c IDs to AssetCaseRow instances, one for each Asset_Case__c
    * where the following are true:
    * 
    * Asset_Case__c.Case__c = the ID of this.getTheCase().Id
    * Asset_Case__c.Status__c contains the full value of statusFilter (case-insensitive).
	* 
    * @param statusFilter the value which must appear in the status values.
    * @return a Map<Id,AssetCaseRow> containing one AssetCaseRow instance 
    *         for each relevant Asset_Case__c record, keyed by that record's ID.
    */ 
    public Map<Id,AssetCaseRow> queryAssetCaseRows(String statusFilter)
    {
    	Map<Id,AssetCaseRow> output = new Map<Id,AssetCaseRow>();   	
    	for(Asset_Case__c ac : [
    		select
    			Id, 
    			Status_Summary__c,
    			Asset_Classification__c,
    			Asset_Classification__r.Name,
    			Asset__c,
    			Asset__r.Name,
    			Detail_Summary__c,
    			Date_Needed__c,
    			Date_Complete__c,    			
    			Status__c, 
    			Type__c
    		from Asset_Case__c
    		where 
    			Case__c = :this.getTheCase().Id 
    			and Status__c like :'%'+statusFilter+'%'
    		order by Date_Complete__c desc nulls first, Date_Needed__c desc nulls last
    	])
    	{
    		output.put(ac.Id,new AssetCaseRow(ac));    		
    	}
    	return output;
    }
    
    /**
    * @return the total number of Asset__c records related to this Case's prEmployee__c.
    */ 
    public Integer getAssetCount()
    { return this.getAssetRows().size(); }
    
    /**
    * @return a list of AssetRow instances, one for each Asset__c record related to 
    *         this Case's prEmployee__c.
    */ 
    public List<AssetRow> getAssetRows()
    {
    	return this.getAssetRowMap().values();    	
    }
    
    /**
    * 
    * @return an AssetRow for each Asset__c record related to 
    *         this Case's prEmployee__c. Each 
    *         returned record's Asset_Cases__r relation will also 
    *         contain (if it exists) the most recent open Asset_Case__c 
    *         with Type__c=NewHireUtil.ASSET_CASE_TYPE_RECLAIM. 
    *         Asset_Case__c records unrelated to the current Case 
    *         are ignored.   
    */ 
    public Map<Id,AssetRow> getAssetRowMap()
    {
    	if(null == this.assetRows)
    	{    	
	    	this.assetRows = new Map<Id,AssetRow>();
	    	
	    	// Query Asset__c records related to this Case's
	    	// prEmployee__c.
	    	// 
	    	// Also, query the most recent open reclamation 
	    	// Asset_Case__c record relating the Asset__c to 
	    	// the current Case. The AssetRow class will use 
	    	// this info to determine whether the user should 
	    	// be able to request a Activation/Deactivation for 
	    	// this Asset__c	    	 
	    	//
	    	Map<Id,Asset__c> assetMap = new Map<Id,Asset__c>([
	    		select
	    			Id,
	    			Name,
	    			Asset_Classification__c,
	    			Asset_Classification__r.Name,
	    			Detail_Summary__c,
	    			
	    			// The AssetRow class will use the output
	    			// of this nested query.
	    			(select 
	    				Id,
	    				Status__c,
	    				Type__c,
	    				Case__c
	    			from Assets_Cases__r
	    			where 
	    				// The Asset_Case__c relates this 
	    				// Asset__c to the current Case.
	    				Case__c   = :this.getTheCase().Id
	    				
	    				// The Asset_Case__c is open. 
	    				and Status__c   like :'%'+NewHireUtil.ASSET_CASE_STATUS_OPEN+'%'
	    				
	    				// The Asset_Case__c is an Activate case.
	    				// Deactivate cases will be pulled in a separate 
	    				// query (see below)
	    				and Type__c = :NewHireUtil.ASSET_CASE_TYPE_RECLAIM
	    				
	    			// Only pull the most recently modified record.
	    			order by LastModifiedDate asc nulls last  
	    			limit 1)
	    				    			
	    		from Asset__c
	    		where 
	    			Contact__c != null 
	    			and Contact__c = :getTheCase().prEmployee__c
	    		order by LastModifiedDate desc
	    	]);
	    	
	    	for(Asset__c asset : assetMap.values())
	    	{
	    		// Instantiate our AssetRow instances.
	    		this.assetRows.put(asset.Id, new AssetRow(asset,this));  
	    	}

	    	// Clean out our requestPrototype cache; remove entries 
	    	// for Assets which are no longer on our list. 
	    	// 
	    	for(Id assetId : this.requestPrototypes.keySet())
	    	{
	    		if(!this.assetRows.containsKey(assetId))
	    		{
	    			this.requestPrototypes.remove(assetId);
	    		}
	    	}
    	}
    	
    	return this.assetRows;
    }
    
    /**
    * A VisualForce action method to do the following.
    * 
    * 1. Query the Asset_Case__c record whose ID matches the value of the 
    *    "editid" GET/POST parameter. 
    * 2. Change the record's Status__c value to NewHireUtil.ASSET_CASE_STATUS_CANCEL
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
    	AssetCaseRow row = this.queryAssetCaseRows(NewHireUtil.ASSET_CASE_STATUS_OPEN).get(editid);
    	
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
    	
    	Asset_Case__c theRequest = [
        		select Id 
        		from Asset_Case__c
        		where Id = :editid        			
        	];
        	
    	theRequest.Status__c = NewHireUtil.ASSET_CASE_STATUS_CANCEL;
    	update theRequest;
    	    	
    	this.invalidate();    	
    	return null;
    }    
    
    /**
    * A VisualForce action method forwarding the user to the 
    * AddAsset page with the "id" URL parameter set to this Case's ID.
    */
    public PageReference requestAsset()
    {
    	PageReference page = new PageReference('/apex/AddAsset?id=' + this.getTheCase().Id);
    	return page.setRedirect(true);
    }
    
    /**
    * A VisualForce action method to do the following.
    * 
    * 1. Query the Asset__c record whose ID matches the value of the 
    *    "editid" GET/POST parameter. 
    * 2. Pull the requestPrototype record corresponding to the asset 
    *    and set Type__c value to NewHirUtil.ASSET_CASE_TYPE_RECLAIM.
    * 3. Insert the prototype record into the DB and remove it from 
    *    our list of prototypes.
    * 4. Invalidate all display lists for this controller extension.
    * 5. Reload the page.
    *  
    */
    public PageReference requestReclamation()
    {
    	Id assetId = (Id)ApexPages.currentPage().getParameters().get('editid');
    	    	
    	// Make sure that the record still belongs to our list 
    	// of actionable items
    	//
    	AssetRow row = this.getAssetRowMap().get(assetId);
    	
    	// Make sure that no changes since the last page load
    	// have prevented us from deactivating the record.
    	// 
    	if(null == row || !row.getCanReclaim())
    	{
    		ApexPages.addMessage(
    			new ApexPages.Message(
    				ApexPages.Severity.ERROR, 
    				'The Asset which you are trying to reclaim has changed or is no longer available. Please reload the page and try again.'
    			)
    		);
    		return null;
    	}
    	
    	// Extract and modify the prototype.
    	Asset_Case__c proto = row.getRequestPrototype();
    	proto.Type__c = NewHireUtil.ASSET_CASE_TYPE_RECLAIM;
    	
    	// Insert the prototype.
    	insert proto; 
    	
    	// The prototype record now has an ID value, so we cannot re-use it
    	// for a later insertion. Remove it from our cache, to prevent it 
    	// from being re-used.
    	//
    	this.requestPrototypes.remove(assetId);
    	
    	this.invalidate();  
    	return null;
    }
    
       
    /*
	* Encapsulates row-specific logic for an Asset_Case__c.
	* An instance of this class represents a single Asset_Case__c 
	* record and offers access to the following information:
	*
	* - The Asset_Case__c record itself.
	* - Whether the user should be allowed to cancel the Asset_Case__c.
	*/
	public class AssetCaseRow
	{
		private Asset_Case__c obj = null;
		
		public AssetCaseRow(Asset_Case__c obj)
		{
			this.obj = obj;						
		}
		
		public Asset_Case__c getObj()
		{
			return this.obj;
		}
		
		/**
		* @return true iff the user should be allowed to cancel this row's Asset_Case__c
		*/
		public Boolean getCanCancel()
		{
			// We can cancel the request if ...
			return
				// The Status__c is non-empty ... 
				this.obj.Status__c != null
				
				// ... and the Status__c is "Open" ...
			 && this.obj.Status__c.toLowercase().contains(NewHireUtil.ASSET_CASE_STATUS_OPEN.toLowercase())
			 
			 && // ... and the the Asset_Case__c is either ...
			   ( // ... a provisioning request ...
			     this.obj.Type__c==NewHireUtil.ASSET_CASE_TYPE_PROVISION
			     // ... or a reclamation request. 
			  || this.obj.Type__c==NewHireUtil.ASSET_CASE_TYPE_RECLAIM); 
		}		
	}
	
	/*
	* Encapsulates row-specific logic for an Asset__c.
	* An instance of this class represents a single Asset__c 
	* record and offers access to the following information:
	*
	* - The Asset__c record itself.
	* - An Asset_Request__c prototype* pre-populated to correspond to this Asset__c
	* - Whether the user should be allowed to reclaim the Asset__c.
	* - Whether the Asset__c case has any open Asset_Case__c records** related to this Case
	*
	* * The prototypes are actually cached in and pulled from the controller given 
	*   in the constructor. This allows the prototypes to persist beyond the life 
	*   of this AssetRow instance.
	*
	* ** This class assumes that if a relevant record exists, it will 
	*    reside in the Asset__c.Assets_Cases__r relationship list. The list will not be 
	*    re-queried, but simply searched as-provided. 
	*/
	public class AssetRow
	{	
		// The record represented on this row.
		private Asset__c obj = null;	
		
		// Teh controller to which this row belongs.
		private AssetCaseExtension controller = null;
		
		/**
		* @param obj the Asset__c record which this AssetRow represents.
		*    
		* @param controller the AssetCaseExtension instance 
		*        to which this AssetCaseRow belongs. Provides context for 
		*        some of the information that this class provides.
		*/
		public AssetRow(Asset__c obj, AssetCaseExtension controller)
		{			
			this.obj = obj;
			this.controller = controller;									
		}
		
		/**
		* @return the Asset__c record that this instance describes.
		*/					
		public Asset__c getObj()
		{ return this.obj; }
		
		/**
		* @return the prototype Asset_Case__c record for this Asset__c. 
		*         The prototypes are actually cached in and pulled from 
		*         the controller so that they can persist beyond the life
		*         of this AssetRow instance.
		*/
		public Asset_Case__c getRequestPrototype()
		{ return this.controller.getRequestPrototype(this.obj); }
		
		/**
		* @return true iff this record's Asset__c.Assets_Cases__r 
		*         relationship contains an open request related to 
		*         the controller's Case. This method simply searches 
		*         the Asset__c.Assets_Cases__r relationship without 
		*         re-querying it. Querying the relevant records is 
		*         up to the instantiator of this AssetRow. 
		*/
		public Boolean getHasOpenReclaimCase()
		{
			for(Asset_Case__c ac : this.obj.Assets_Cases__r)
			{
				// We found a record if ...
				if(// ... the Status__c is non-blank ...
					ac.Status__c != null
					// ... and the Status__c is open ... 
					&& ac.Status__c.toLowercase().contains(NewHireUtil.ASSET_CASE_STATUS_OPEN.toLowercase())
					
					// ... and the record is related to the controller's case.
					&& ac.Case__c == this.controller.getTheCase().Id
				  )
					
				{
					return true;
				}
			}
			return false;
		}
		
		/**
		* @return true if the user should be allowed to reclaim the Asset__c.
		*/
		public Boolean getCanReclaim()
		{ return !this.getHasOpenReclaimCase(); }

		/**
		* @return true if the case has a pending reclamation.
		*/
		public Boolean getHasPendingReclamation()
		{ return  this.getHasOpenReclaimCase(); }
		
	}
    
}