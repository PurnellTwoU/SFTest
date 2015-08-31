/**
* This controller extension backs the AddAsset.page VisualForce page.
* A user uses the AddAsset page to create one or more requests to 
* allocate an Asset to a particular employee, represented as a
* Contact.
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
* Asset Classification:
* (Occasionally referred to as an "Asset", though not the same thing)
* Stored in DB as an Asset_Classification__c record. Represents a particular 
* classification of Asset. The Asset_Classification__c.Specification_Picklist_Values__c
* field further qualifies the types of Asset with a newline-delimited set of values.
* 
* For example, a company with three desktop computers, five laptops, and four Photoshop 
* software licenses might have two Asset_Classification__c records, one for "Computer" 
* and one for "Software License". The Computer Asset_Classification__c might have a 
* Specification_Picklist_Values__c value including "Laptop" and "Desktop".
* 
* Asset Request: 
* AKA "Asset Case", "Asset Event", or (within 
* the scope of this Apex class) simply "Request". 
* Stored in DB as an Asset_Case__c record. Represents an action 
* to be taken in regard to an Asset (Asset__c) and Contact 
* (e.g. "provision a Laptop for John Doe" or "reclaim John 
* Doe's Laptop"). This controller only deals with Asset Requests
* for provisioning Assets.
*
* The Asset_Classification__c.Available_on_Provisioning_Case__c field determines 
* whether the Asset_Classification__c can be offered for account creation. 
* If this field is false, this controller ignores that Asset_Classification__c 
* record. 
*
* Constants
* ---------
* The following constants are relevant to this class:
* - NewHireUtil.USER_ACCOUNT_CASE_TYPE_DROP
* - NewHireUtil.ASSET_CASE_TYPE_PROVISION
* - NewHireUtil.ASSET_CASE_STATUS_OPEN
* - NewHireUtil.NewHireUtil.ACASE_RTYPE_FOR_ACLASS_FIELDSET
*
* URL Parameters
* -------------- 
* "id" - The Salesforce ID of a provisioning Case (henceforth, 
*        "the Case" or "theCase"). theCase.prEmployee__c should 
*        point to a Contact record for the person to whom the user is 
*        requesting Assets (henceforth, "the Contact" or 
*        "theContact"). 
*
* Supported Viewing Tasks
* -----------------------
*
* This controller extension implements the following viewing tasks:
* 1. Viewing a list of available Asset Classifications, with their available 
*    Specification_Picklist_Values__c (if any exist).
*
* Implemented Actions
* -------------------
* This controller extension explicitly implements the following actions:
* 1. Going to the AssetCase page (via a button labeled "Back").
* 2. Creating a request to allocate to the Contact a particular Asset.
*
* AddAssetController Class Design
* ---------------------------------
* When setAssets is called, this page queries a list of appropriate 
* Asset_Classification__c records and saves them in a private list.
*
* When getAssets is called, this controller creates a list of AssetWrapper 
* instances from the list of Asset_Classification__c records and saves the 
* AssetWrapper instances in a list as well. The new AssetWrapper instances 
* are returned to be displayed in the table.
*
* The nested AssetWrapper class is a value holder for the 
* information to be displayed/collected from an Asset_Classification__c 
* record. Newline-delimited values from the Specification_Picklist_Values__c 
* field are used to generate lists of SelectOptions, to be displayed with the 
* AssetWrapper.
*
* When the user submits an action, via the addAssets() action method,
* the user's inputs (which Assets are being requested, due dates, and selected 
* Specification_Picklist_Values__c) are retrieved from the HTTP request using 
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
*   any clients other than those submitting through the AddAsset 
*   page. A malicious coder could theoretically spoof such a request, 
*   but not without a valid Salesforce login token.
* 
*/
public class AddAssetController
{
    // The Case in relation to which this controller creates User Account Requests
	//
    private Case theCase;
    
    // The list of AssetWrapper instances that we will 
	// display to the user, one instance for each Asset_Classification__c we offer.
    List<AssetWrapper> wrapperList{get;set;}
    
    // The list of Asset_Classification__c records on which the wrapperList is based.
    public List<Asset_Classification__c> assetList = new List<Asset_Classification__c>();
    
    // The size of the above assetList
    Integer asstSize;
    
    // Whether or not there was an error on this page.
    // Determines whether messages will display for this page.
    public Boolean error{get;set;}
    
    /**
    * Initialize this instance with the given controller.
    * Query information for the case pointed to by controller.getRecord()
    */ 
    public AddAssetController(ApexPages.StandardController controller)
    {
        this.theCase = (Case)controller.getRecord();
        
        this.theCase = [
        	select 
        		Id, 
        		type, 
        		prEmployee__c,
        		Due_Date__c 
        	from Case 
        	where Id = :this.theCase.Id
        ];        
    }
  
    /**
    * Return true if the user should be allowed to add an Asset
    * Request to this controller's Case.
    */
    public Boolean getCanAddAsset()
    {
    	return this.theCase.Type != NewHireUtil.CASE_TYPE_DROP;    
    }  
        
    
    /**
    * Find a list of Asset_Classification__c records. Populate the 
    * serviceList with the found records.
    *
    * The Asset Classifications found here will be wrapped in AssetWrapper 
    * instances (via getAssets()) and displayed to the user when the 
    * user is asked to choose an Asset_Classification__c for which to request 
    * an Asset__c. 
    * 
    */
    public void setAssets()
    {   
        List<Asset_Classification__c> assetList = [
	        	select 
	        		Id, 
	        		Name, 
	        		Available_on_provisioning_case__c, 
	        		Specification_Picklist_Values__c, 
	        		Field_Set__c
				from Asset_Classification__c 
				where 
					Available_on_provisioning_case__c = true
				order by Field_Set__c desc
			];
			       
        this.assetList = assetList;
    }
    
    /**
    * Wrap each Asset_Classification__c record from the current 
    * assetList (found via setAssets()) in an 
    * AssetWrapper instance and return a list of the 
    * newly created wrappers.
    *
    * If an Asset_Classification__c has a value in the 
    * Specification_Picklist_Values__c field, this will be 
    * parsed treated as a newline-delimited list of values 
    * and the values included in the AssetWrapper as a list 
    * of SelectOption instances.
    *
    * The serviceWrappers returned here are displayed when the 
    * user is asked to choose for which Asset_Classification__c 
    * a new Asset__c should be requested.
    * 
    */ 
    public List<AssetWrapper> getAssets()
    {
        List<SelectOption> specificationOptions;  
             
        List<Asset_Classification__c>  assets = assetList;  
        setAsstSize(assets.size());  
        wrapperList = new List<AssetWrapper>();
                   
        for(Asset_Classification__c asset : assets)
        {
           specificationOptions = new List<SelectOption>(); 
           if(asset.Specification_Picklist_Values__c != null)
           {
               List<String> specifications = asset.Specification_Picklist_Values__c.split('\n');
               for(String str : specifications)
               {
               		str = str.trim();
                    specificationOptions.add(new SelectOption(str,str));                
               }
           } 
           wrapperList.add(
           	new AssetWrapper(
           		asset.Name, 
           		specificationOptions, 
           		asset.Field_Set__c, 
           		asset.Id));
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
    * main:theForm:infoPanel:repeat:i:asset
    * - If 'on', an Asset_Case__c will be created.
    *
    * main:theForm:infoPanel:repeat:i:aspec
    * - Populates Asset_Case__c.Specifications__c
    *
    * main:theForm:infoPanel:repeat:i:aid
    * - Populates Asset_Case__c.Asset_Classification__c
    *
    * main:theForm:infoPanel:repeat:i:adate
    * - Populates Asset_Case__c.Date_Needed__c
    *
    * main:theForm:infoPanel:repeat:i:afieldset
    * - Converted to an ID via the NewHireUtil.ASSET_RECORD_TYPE_FOR_ASSET_CLASSIFICATION_FIELD_SET map.
    * - ID populates Asset_Case__c.RecordTypeId
    *
    * main:theForm:infoPanel:repeat:i:anotes
    * - Populates User_Account_Case__c.Notes__c
    *
    */
    public void addAssets()
    {       
        String paramString = 'main:theForm:infoPanel:repeat:';
        Map<String,String> currParameters = System.currentPagereference().getParameters();      
        Set<String> keySet = currParameters.keySet();
        
        Map<String, String> fieldSetRcrdMap = NewHireUtil.ACASE_RTYPE_FOR_ACLASS_FIELDSET;
        List<Asset_Case__c> acList = new List<Asset_Case__c>();
        
        // For each Asset_Classification__c we offer ...
        for(Integer i = 0; i < getAsstSize(); i++)
        {
        	// ... find out whether the user wants to request that Asset_Classification__c.
            String serviceFlag = currParameters.get(paramString + i + ':asset');            
            if(serviceFlag == 'on')
            {
                try
                {
                	// ... Extract the user-selected information for this Asset_Classification__c ...
                	//
                    String spec = currParameters.get(paramString + i + ':aspec');                   
                    //String name = currParameters.get(paramString + i + ':sname');
                    String aId = currParameters.get(paramString + i + ':aid');
                    String adate = currParameters.get(paramString + i + ':adate');  
                    String afieldset = currParameters.get(paramString + i + ':afieldset');              
                    String notes = currParameters.get(paramString + i + ':anotes'); 
         
                    // Place the user-selected information into a new 
                    // Asset_Case__c record.
                    //
                    Asset_Case__c ac = 
                    	new Asset_Case__c(
                    		Employee__c = this.theCase.prEmployee__c,
                    		RecordTypeId = fieldSetRcrdMap.get(afieldset), 
                    		Asset_Classification__c = aId, 
                    		Case__c = this.theCase.Id,
                    		Type__c = NewHireUtil.ASSET_CASE_TYPE_PROVISION, 
                    		Status__c = NewHireUtil.ASSET_CASE_STATUS_OPEN,
                    		Specifications__c = spec,
                    		Notes__c = notes);
                    
                    // Parse the date from a string into a Date.
                    Date dateNeeded;
                    if(adate != null && adate != '')
                    {
                         String[] stringDate = adate.split('/');
                         Integer m =  Integer.valueOf(stringDate[0]);
                         Integer d = Integer.valueOf(stringDate[1]);
                         Integer y = Integer.valueOf(stringDate[2]);
                         dateNeeded =  date.newInstance(y,m,d);
                         
                         // Use the date (if provided) to populate the Date_Needed__c 
                         // field on our new Asset_Case__c. 
                         ac.Date_Needed__c = dateNeeded;
                    }     
                    
                    // Add the new Asset_Case__c to our list.                                                 
                    acList.add(ac);
                }
                catch(Exception e)
                {
                	// Set the error flag so the UI knows to render the message display.
                	error = true;
                	// Add a message to be displayed.
                	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while adding the service. Please try again.'));
                    return;
                }
            }               
        }
        if(acList.size() > 0)
            insert acList;
    }
    
    public PageReference back()
    {
        PageReference page = new PageReference('/apex/AssetCase?id=' + this.theCase.Id);
        return page.setRedirect(true);
    }
    
    /**
    * Set the asstSize variable, intended to represent the number of 
    * Asset_Classification__c's available to the user.
    */
    public void setAsstSize(Integer size)
    {
        this.asstSize = size;
    }
    
    /**
    * @return the current Case.
    */
    public Case getCase()
    {
    	return this.theCase;    	
    }
    
    /**
    * @return the value of the asstSize variable. 
    */
    public Integer getAsstSize()
    {
        return asstSize;
    }
    
    
    /**
    *  Wrapper class for each Asset_Classification__c that we will offer the user.
    *  A list of instances of this calss will typically be displayed in 
    *  a table, allowing the user to choose an Asset_Classification__c for which the user
    *  wants to request an Asset__c.
    */
    public class AssetWrapper
    {
    	// Normally from Asset_Classification__c.Name
    	//
        public String assetName{get;set;}
        
        // Normally from the newline-delimited set of values
        // in the Asset_Classification__c.Specification_Picklist_Values__c
        // field.
        //
        public List<SelectOption> asstSpecifications{get;set;}
        
        // Normally from Asset_Classification__c.Field_Set__c
        //
        public String fieldSet{get;set;}
        
        // Normally from Asset_Classification__c.Id
        //
        public String assetId{get;set;}
        
        /**
        * Basic constructor. Populates all member variables.
        */
        public AssetWrapper(String assetName, List<SelectOption> asstSpecifications, String fieldSet, String assetId)
        {
            this.assetName = assetName;
            this.asstSpecifications = asstSpecifications;           
            this.fieldSet = fieldSet;
            this.assetId = assetId;
        }
    }

}