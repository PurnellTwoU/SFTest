/**
* This class defines static constants and global utility methods for the
* New Hires application.
*
* Some constants in this class require a database query.
* In these cases, the query is not made until the constant's first access.
* Once queried the values are cached and re-used until the end of execution.
*
* At most (if all constants are accessed), this will cost 9 
* SOQL queries, with 11 SOQL rows retrieved.
* 
* See in-code comments for more details.
*/
public class NewHireUtil
{   
    // 
    // Constants
    //
    // In most cases, variable names conventionally contain
    // the Object and Field to which the value applies.
    //
    /////////////////////////////////////////////////////////
    
    // Apply to Case.Origin
    //    
    public static final String CASE_AUTOCREATE_ORIGIN = 'Human Resources Portal';
    
    // Apply to Service__c.Field_Set__c
    //
    public static final String UAC_FIELD_SET_SALESFORCE = 'Salesforce Account';
    public static final String UAC_FIELD_SET_GENERIC    = 'Generic User Account';
    public static final String UAC_FIELD_SET_GENERIC_WITH_PROFILE = 'Generic User Account with Profile';
    
    // Apply to Asset_Classification__c.Field_Set__c
    //
    public static final String ASSET_FIELD_SET_GENERIC           = 'Generic Asset';
    public static final String ASSET_FIELD_SET_GENERIC_WITH_SPEC = 'Generic Asset with Specifications';
    
    // Apply to: 
    // - Contact.Employment_Status__c
    // - Case.prEmployment_Status__c
    // 
    public static final String EMPLOYMENT_STATUS_NEW = 'New Hire';
    public static final String EMPLOYMENT_STATUS_ACTIVE = 'Active';
    public static final String EMPLOYMENT_STATUS_INACTIVE = 'Terminated';
    public static final String EMPLOYMENT_STATUS_TEMPORARILY_SUSPENDED = 'Leave of Absence'; 
    
    // Apply to Asset_Case_Type__c 
    //  
    public static final String ASSET_CASE_TYPE_ACTIVATE = 'Activate';
    public static final String ASSET_CASE_TYPE_DEACTIVATE = 'Deactivate';
    public static final String ASSET_CASE_TYPE_NONE = '';
    public static final String ASSET_CASE_TYPE_PROVISION = 'Provision';
    public static final String ASSET_CASE_TYPE_RECLAIM = 'Reclaim';
    
    // Apply to User_Account_Case__c.Type__c
    //
    public static final String USER_ACCOUNT_CASE_TYPE_ACTIVATE = 'Activate';
    public static final String USER_ACCOUNT_CASE_TYPE_DEACTIVATE = 'Deactivate';
    public static final String USER_ACCOUNT_CASE_TYPE_NONE = '';
    public static final String USER_ACCOUNT_CASE_TYPE_PROVISION = 'Provision';
    public static final String USER_ACCOUNT_CASE_TYPE_RECLAIM = 'Reclaim';
    
    // Apply to User_Account_Case__c.Notes__c
    //
    public static final String USER_ACCOUNT_CASE_NOTES_PROVISIONING_ACTIVE = 
        'Reactivate after temporary suspension';
    public static final String USER_ACCOUNT_CASE_NOTES_SUSPENSION_ACTIVE =
        'Temporarily deactivate';
    
    // Apply to Asset_Case__c.Notes__c
    //
    public static final String ASSET_CASE_NOTES_PROVISIONING = 
        'Return after temporary suspension';
    public static final String ASSET_CASE_NOTES_SUSPENSION =
        'Temporarily reclaim';
    
    // Apply to Case.Status
    //
    public static final String CASE_STATUS_CANCEL = 'Closed - Cancelled';    
    
    // Apply to Case.Subject
    //
    public static final String CASE_SUBJECT_ADD          = 'Add ';
    public static final String CASE_SUBJECT_UPDATE       = 'Update ';
    public static final String CASE_SUBJECT_DROP         = 'Drop ';
    public static final String CASE_SUBJECT_SUSPENSION   = '(1/2) Temporarily Suspend ';
    public static final String CASE_SUBJECT_PROVISIONING = '(2/2) Reactivate ';
    
    // Apply to Case.Type
    //
    public static final String CASE_TYPE_DROP = 'Drop';
    public static final String CASE_TYPE_ADD = 'Add';
    public static final String CASE_TYPE_UPDATE = 'Update';

    // Apply to Case.Employee_Type__c
    //
    public static final String CASE_EMPLOYEE_TYPE_EMPLOYEE   = '2U Employee';
    public static final String CASE_EMPLOYEE_TYPE_CONTRACTOR = '2U Contractor';
    
    // Apply to Asset_Case.Status__c
    //
    public static final String ASSET_CASE_STATUS_OPEN = 'Open';
    public static final String ASSET_CASE_STATUS_COMPLETE = 'Complete';
    public static final String ASSET_CASE_STATUS_CANCEL = 'Cancelled';
    public static final String ASSET_CASE_STATUS_NONE = '';
    
    // Apply to User_Account_Case__c.Status__c
    //
    public static final String USER_ACCOUNT_CASE_STATUS_OPEN = 'Open';
    public static final String USER_ACCOUNT_CASE_STATUS_COMPLETE = 'Complete';
    public static final String USER_ACCOUNT_CASE_STATUS_CANCEL = 'Cancelled';
    public static final String USER_ACCOUNT_CASE_STATUS_NONE = '';
    
    // 
    // Queried Constants ("pseudo-constants")
    //
    // The below pseudo-constants return ID values.
    // Since ID values may differ from one org to the next, the ID values 
    // are queried dynamically based on some query criterion specified here. 
    // The criterion usually involves the record's name or some similar variant.
    //
    // Attempting to access these values in an org lacking a record which
    // matches the criterion will cause an NewHireUtil.IdNotFoundException to be 
    // thrown. 
    //
    
    // The default Account record, to which the New Hires app will 
    // assign all new Contacts representing employees of this org.
    //
    public static String DEFAULT_ACCOUNT_NAME = '2tor, Inc.'; 
    public static String DEFAULT_ACCOUNT {
        get{ return getId('Account where Name = \''+DEFAULT_ACCOUNT_NAME+'\' and IsDeleted=false',0); } }

    // The default Account record, to which the New Hires app will 
    // assign all new Contacts representing employees of this org.
    //
    public static String CONTRACTOR_ACCOUNT_NAME = '2U - Contractors'; 
    public static String CONTRACTOR_ACCOUNT {
        get{ return getId('Account where Name = \''+CONTRACTOR_ACCOUNT_NAME+'\' and IsDeleted=false',0); } }

    // Apply to Case.RecordTypeId
    //  
    public static String RECORDTYPE_PROVISIONING_ADD { // '012G0000000mtG1';
        get{ return getId('RecordType where DeveloperName = \'Provisioning_Add\'',1); } }
    public static String RECORDTYPE_PROVISIONING_DROP {  // '012G0000000mtG3';
        get{ return getId('RecordType where DeveloperName = \'Provisioning_Drop\'',2); } }
    public static String RECORDTYPE_PROVISIONING_UPDATE { // '012G0000000mtG5';
        get{ return getId('RecordType where DeveloperName = \'Provisioning_Update\'',3); } }
    public static String RECORDTYPE_PROVISIONING_SUSPENSION { // '012G0000000mtG4';
        get{ return getId('RecordType where DeveloperName = \'Provisioning_Suspension\'',4); }  }
    public static String RECORDTYPE_PROVISIONING_CASE { // '012G0000000mtG0';
        get{ return getId('RecordType where DeveloperName = \'Provisioning\'',5); } }
    public static String RECORDTYPE_PROVISIONING_CASE_COMPLETE { // '012G0000000mtG2';
        get{ return getId('RecordType where DeveloperName = \'Provisioning_Complete\'',6); } }
        
    // Apply to User_Account_Case__c.RecordTypeId
    //
    public static String RECORDTYPE_PROVISIONING_TASK { // ''012G0000000mtGB'';
        get{ return getId('RecordType where DeveloperName = \'Provisioning_Request\'',7); } }
    public static String RECORDTYPE_PROVISIONING_TASK_WITH_PROFILE { // '012G0000000mtG9';
        get{ return getId('RecordType where DeveloperName = \'Provisioning_Request_with_Profile\'',8); } }
    public static String RECORDTYPE_SALESFORCE_PROVISIONING_TASK { // '012G0000000mtGA';
        get{ return getId('RecordType where DeveloperName = \'Salesforce_Provisioning_Request\'',9); } }
    
    // Apply to User_Account__c.RecordTypeId
    //
    public static String RECORDTYPE_SALESFORCE_USER_ACCOUNT { // ''012G0000000mtGB'';
        get{ return getId('RecordType where DeveloperName = \'Salesforce_User_Account\'',10); } }
    public static String RECORDTYPE_USER_ACCOUNT { // '012G0000000mtG9';
        get{ return getId('RecordType where DeveloperName = \'User_Account\'',11); } }
    public static String RECORDTYPE_USER_ACCOUNT_WITH_PROFILE { // '012G0000000mtGA';
        get{ return getId('RecordType where DeveloperName = \'User_Account_with_Profile\'',12); } }
            
    // Apply to Asset_Case__c.RecordTypeId
    //
    public static String RECORDTYPE_ASSET_CASE_PROVISIONING_REQUEST {  // '012G0000000mtFv';
        get{ return getId('RecordType where DeveloperName = \'Asset_Provisioning_Request\'',13); } }
    
    // 
    // When User_Account_Case__c records are created in regard to an existing
    // User_Account__c record, their RecordType depends on that of the associated 
    // User_Account__c record.
    //
    // This pseudo-constant maps User_Account__c record types to 
    // User_Account_Case__c record types. The map is specified here using 
    // RecordType.DeveloperName values, but the returned result uses 
    // IDs instead of their corresponding DeveloperNames.
    //    
    public static Map<String,String> USER_ACCOUNT_TO_USER_ACCOUNT_CASE_RECORD_TYPE {
        get{return getRecordTypeMap(new Map<String,String>{
                // RecordType.DeveloperName values ...
                // ----------------------------------------------------------------
                // ... for the User_Account__c  | ... for the User_Account_Case__c
                // ----------------------------------------------------------------
                    'Salesforce_User_Account'   => 'Salesforce_Provisioning_Request',
                    'User_Account'              => 'Provisioning_Request',
                    'User_Account_with_Profile' => 'Provisioning_Request_with_Profile'
            },true,0); 
        }    
    } 
    
    // When User_Account_Case__c records are created to request a new 
    // User_Account__c their RecordType depends on the Service__c.Field_Set__c 
    // value of the associated Service__c record.
    //
    // This pseudo-constant maps Service__c.Field_Set__c values to 
    // User_Account_Case__c record types. The map is specified here mapping 
    // Service__c.Field_Set__c values to User_Account_Case__c.RecordType.DeveloperName
    // values, but the returned result uses User_Account__c.RecordType.Id values 
    // instead of their corresponding DeveloperNames.
    //    
    public static Map<String,String> UACASE_RTYPE_FOR_SRV_FIELDSET {
        get{return getRecordTypeMap(new Map<String,String>{
                // ----------------------------------------------------------------
                //  Service__c.Field_Set__c  | User_Account_Case__c.RecordType.DeveloperName
                // ----------------------------------------------------------------
                    UAC_FIELD_SET_SALESFORCE           => 'Salesforce_Provisioning_Request',
                    UAC_FIELD_SET_GENERIC              => 'Provisioning_Request',
                    UAC_FIELD_SET_GENERIC_WITH_PROFILE => 'Provisioning_Request_with_Profile'
            },false,1); 
        }    
    }
    
    
    // When Asset_Case__c records are created to request a new 
    // Asset__c, their RecordType depends on the Asset_Classification__c.Field_Set__c 
    // value of the associated Asset_Classification__c record.
    //
    // This pseudo-constant maps Asset_Classification__c.Field_Set__c values to 
    // Asset_Case__c record types. The map is specified here mapping 
    // Asset_Classification__c.Field_Set__c values to Asset_Case__c.RecordType.DeveloperName
    // values, but the returned result uses Asset_Case__c.RecordType.Id values 
    // instead of their corresponding DeveloperNames.
    //    
    public static Map<String,String> ACASE_RTYPE_FOR_ACLASS_FIELDSET {
        get{return getRecordTypeMap(new Map<String,String>{
                // -------------------------------------------------------------------------------
                //  Asset_Classification__c.Field_Set__c  | Asset_Case__c.RecordType.DeveloperName
                // -------------------------------------------------------------------------------
                    ASSET_FIELD_SET_GENERIC           => 'Asset_Provisioning_Request',
                    ASSET_FIELD_SET_GENERIC_WITH_SPEC => 'Asset_Provisioning_Request_with_Specifications'
            },false,2); 
        }    
    } 
    
    // An exception class for Id values that could not be found.
    //
    public class IdNotFoundException extends Exception {}    
    
    /**
    * A cache for Maps queried dynamically.
    * Should not be accessed outside of the getRecordTypeMap() method.
    */
    public static Map<Integer,Map<String,String>> MAP_CACHE = new Map<Integer,Map<String,String>>();
    /**
    * Replace the values in inMap with RecordType.Id values, where 
    * RecordType.DeveloperName matches the original value.
    *
    * If queryKeys is true, this method replaces the keys of inMap
    * in the same manner.
    *
    * All queried values (keys and values) are combined into a single 
    * query and the resulting map is cached (according to cacheKey) 
    * so that the query is run at most once per execution scope.   
    *
    * All values that you specify to be replaced with IDs are required to 
    * be in the database. Any not found will cause an IDNotFoundException 
    * to be thrown.  
    * 
    */ 
    public static Map<String,String> getRecordTypeMap(Map<String,String> inMap, Boolean queryKeys, Integer cacheKey)
    {
        // If we already have a cached value ...
        if(MAP_CACHE.containsKey(cacheKey))
        {
            // ... return the cached value.
            return MAP_CACHE.get(cacheKey);
        }
        
        // RecordType.DeveloperName values by which we will filter
        // our RecordType query.
        List<String> developerNames = new List<String>();
        
        // Find IDs for the given values.
        developerNames.addAll(inMap.values());   
        
        // If needed, find IDs for the given keys.
        if(queryKeys)   { developerNames.addAll(inMap.keySet()); }
        
        // Query for our RecordType records.
        RecordType[] recordTypes = [
            select
                Id, 
                DeveloperName 
            from RecordType
            where DeveloperName in :developerNames
        ];
        
        // Build a map for converting DeveloperName values
        // to their corresponding IDs
        Map<String,Id> idForDeveloperName = new Map<String,Id>();
        for(RecordType rt : recordTypes)
        {
            idForDeveloperName.put(rt.DeveloperName,rt.Id);         
        }
        
        // Our clone the input to avoid side-effects.
        Map<String,String> outMap = inMap.clone();
        
        // For each given key ...
        for(String key : outMap.keySet())
        {
            // ... pull the current value, which we will replace.
            String originalValue = outMap.get(key);
            
            // If we have an ID value for the current value ...
            if(idForDeveloperName.containsKey(originalValue))
            {
                // ... replace the value with its corresponding ID ...
                outMap.put(key,idForDeveloperName.get(originalValue));              
            } 
            // ... otherwise ...
            else
            {
                // ... fail.
                throw new IdNotFoundException('Could not find an ID for "RecordType where DeveloperName = \''+originalValue+'\'"');
            }
        }
        
        // If we have been asked to replace keys ...
        if(queryKeys)
        {
            // ... for each key ...
            for(String originalKey : outMap.keySet())
            {
                // ... find the value, which we will associate with the new Key
                String value = outMap.get(originalKey);
                
                // If we have an ID for the current key ...
                if(idForDeveloperName.containsKey(originalKey))
                {
                    // ... remove the original key
                    outMap.remove(originalKey);
                    // ... and associate the value with the new key (now an ID).
                    outMap.put(idForDeveloperName.get(originalKey),value);              
                }
                // ... otherwise ...
                 else
                {
                    // ... fail.
                    throw new IdNotFoundException('Could not find an ID for "RecordType where DeveloperName = \''+originalKey+'\'"');
                }
            }       
        }
        
        // Cache our result.
        MAP_CACHE.put(cacheKey,outMap);
                
        return outMap;  
                
    }
    
    
    // Cache for our queried constants, so we do not 
    // need to query them on every use.
    // 
    // This variable should never be directly accessed directly
    // outside of the getId() method. The variable is only
    // public because Apex does not allow protected static class 
    // variables or static variables inside of static methods.
    //
    public static Map<Integer,Id> ID_CACHE = new Map<Integer,Id>();
    
    /**
    * Utility method for resolving queried constants.
    * Values found are cached (within a single execution scope),
    * and accessed by the given cacheKey.
    * 
    * Does the following:
    * 1. Check ID_CACHE for a value keyed at cacheKey
    * 2. If found, return the cached value.
    *    Otherwise, use queryClause to query the record.
    * 3. Cache the record found above.
    * 4. Return the Id of the newly found record.
    * 
    * @param queryClause the table name and where clause of an 
    *        SOQL query for the record whose ID should be returned.
    *        (e.g. 'Account where Name="2Tor, Inc."')
    *
    * @param cacheKey The key value that will be used to reference 
    *        this variable in the cache. Should be the same for all
    *        calls for the same variable.
    *
    * @throws NewHireUtil.IdNotFoundException if the ID of the requested 
    *         record is not in the cache and is not in the DB.
    * 
    */        
    public static Id getId(String queryClause,Integer cacheKey)
    {
        
        if(ID_CACHE.containsKey(cacheKey))
        {
            return ID_CACHE.get(cacheKey);      
        }
        
        List<sObject> results = Database.query('select Id from '+queryClause+' limit 1');
        if(results.size() > 0)
        {
            ID_CACHE.put(cacheKey,(Id)results[0].get('Id'));
            return ID_CACHE.get(cacheKey);
        } else
        {
            throw new IdNotFoundException('Could not find an ID for "'+queryClause+'"');        
        }       
    }
    
    /*
    public static Map<String, String> UserAccountToUserAccountCaseRecordType()
    {
        Map<String, String> uatouacRcrdType = new Map<String, String>();
        uatouacRcrdType.put('012G0000000mtGC','012G0000000mtGB');
        uatouacRcrdType.put('012G0000000mtGD','012G0000000mtG9');
        uatouacRcrdType.put('012G0000000mtGE','012G0000000mtGA');
        return uatouacRcrdType;
    }*/
    
    /**
    * Given a provisioning Case (assumed to be a RECORDTYPE_PROVISIONING_ADD Case),
    * Determine the ID of the Account to which the Case's newly created Contact should be assigned.
    */
    public static Id getAccountIdForNewContact(Case provisioningCase)
    {
        if(CASE_EMPLOYEE_TYPE_CONTRACTOR == provisioningCase.Employee_Type__c)
        {
            return (Id)CONTRACTOR_ACCOUNT;
        }
        else
        {
            return (Id)DEFAULT_ACCOUNT;
        }
    }

    /**
    * Create Asset_Case__c records corresponding 
    * to the given map of Case records.
    *
    * Looks up all Asset__c records for all Contact Ids
    * in the Map's keySet. Creates at most one Asset_Case__c 
    * per Asset__c. The data in the Asset_Case depends on the 
    * RecordType of the corresponding Contact's Case, as follows:
    *
    * Update Case: 
    * No Asset_Case__c created.
    *
    * Drop Case: 
    * Creates a Reclamation request
    *
    * Suspend Case: 
    * Creates a Reclamation request with "Temporarily reclaim" in the notes.
    *
    * Provisioning Case:
    * In a suspension, this represents the case corresponding to the future 
    * re-activation of a temporarily suspended Contact.
    * Creates a Provision request, with "Return after temporary suspension"
    * in the notes.
    *
    * @param contactIdToCaseMap A map of cases, indexed by their prEmployee__c values
    * @return the list of Asset_Case__c records created.
    * 
    */
    public static List<Asset_Case__c> createAssetCases(Map<Id,Case> contactIdToCaseMap)
    {
        List<Asset_Case__c> assetInsertList = new List<Asset_Case__c>();
        //Get the the list existing assets for the contacts of the transfer case.
        List<Asset__c> assetsOfProvCases = [
            select 
                Id, 
                Contact__c, 
                Asset_Classification__c,
                Installed_On__c, 
                License_Number__c,
                RecordTypeId
            from  Asset__c 
            where Contact__c in :contactIdToCaseMap.keySet()];
             
        String type = '';   
        String status = '';     
        Date acDate;
        String notes = '';
        for(Asset__c asset : assetsOfProvCases)
        {
            //Create asset+ cases for the new transfer case     
            Case c =  contactIdToCaseMap.get(asset.Contact__c);
            if(c.RecordTypeId == RECORDTYPE_PROVISIONING_UPDATE)
            {
                // Per Ticket SF-438: 
                // Asset_Case__c records for Update cases will be 
                // created via user interaction with AddService.page 
                // instead of being automatically created here.
                //  
                continue;
                // type = NewHireUtil.ASSET_CASE_TYPE_NONE;
                // status = NewHireUtil.ASSET_CASE_STATUS_NONE;
            }
            else if(c.RecordTypeId == RECORDTYPE_PROVISIONING_DROP)
            {
                type = NewHireUtil.ASSET_CASE_TYPE_RECLAIM;
                status = NewHireUtil.ASSET_CASE_STATUS_OPEN;
                acDate = c.Due_Date__c;
            }
            // Suspension case update
            // SF-3364 required dividing _DROP and _SUSPENSION into separate conditions.  
            else if(c.RecordTypeId == RECORDTYPE_PROVISIONING_SUSPENSION)
            {
                type = NewHireUtil.ASSET_CASE_TYPE_RECLAIM;
                status = NewHireUtil.ASSET_CASE_STATUS_CANCEL;
                acDate = c.Due_Date__c;
                    notes = ASSET_CASE_NOTES_SUSPENSION;              
            }
            
            else if(c.RecordTypeId == RECORDTYPE_PROVISIONING_CASE)
            {
                type   = NewHireUtil.ASSET_CASE_TYPE_PROVISION;
                status = NewHireUtil.ASSET_CASE_STATUS_OPEN;
                notes  = ASSET_CASE_NOTES_PROVISIONING;     
                acDate = c.Due_Date__c; 
            }   
            
            // Create the new record.
            Asset_Case__c newAC =  new Asset_Case__c(
                Case__c = c.Id, 
                Status__c = status, 
                Asset__c = asset.Id, 
                Asset_Classification__c = asset.Asset_Classification__c,
                RecordTypeId = RECORDTYPE_ASSET_CASE_PROVISIONING_REQUEST, 
                Type__c = type, Employee__c = c.prEmployee__c,
                Notes__c = notes, Date_Needed__c = acDate);
                                            
            assetInsertList.add(newAC);
            type = '';  
            status = '';
            acDate = null;
            notes = ''; 
            
        }
        return  assetInsertList;                        
    }
    
    /**
    * Create User_Account_Case__c records corresponding 
    * to the given map of Case records.
    *
    * Looks up all User_Account__c records for all Contact Ids
    * in the Map's keySet. Creates at most one User_Account_Case__c 
    * per User_Account__c. The data in the User_Account_Case__c depends 
    * on the RecordType of the corresponding Contact's Case, as follows:
    *
    * Update Case: 
    * No User_Account_Case__c created.
    *
    * Drop Case: 
    * Creates a Deactivation request
    *
    * Suspend Case: 
    * If the User_Account__c is inactive, creates a User_Account_Case__c 
    * with the "None" RecordType. If active, creates a Deactivate request 
    * with "Temporarily deactivate" in the notes.
    *
    * Provisioning Case:
    * In a suspension, this represents the case corresponding to the future 
    * re-activation of a temporarily suspended Contact.
    * If the User_Account__c is inactive, creates a User_Account_Case__c 
    * with the "None" RecordType. If active, creates a Deactivate request 
    * with "Temporarily deactivate" in the notes.
    *
    * @param contactIdToCaseMap A map of cases, indexed by their prEmployee__c values
    * @return the list of User_Account_Case__c records created.
    * 
    */
    public static List<User_Account_Case__c> createUserAccounts(Map<Id, Case> contactIdToCaseMap)
    {
        List<User_Account_Case__c> uacInsertList = new List<User_Account_Case__c>();
        //Get the the list existing user accounts for the contacts of the transfer case.
        List<User_Account__c> usrAccOfProvCases = [
            select 
                Id, 
                Contact__c, 
                //Type__c,
                // Start_Date__c, 
                // Needs_Geopoint__c,
                Service_Profile__c, 
                Service_Role__c, 
                Service__c, 
                RecordTypeId, 
                Active__c
            from  User_Account__c 
            where Contact__c in :contactIdToCaseMap.keySet()
        ]; 
        String type = '';   
        String status = '';
        Date acDate;
        String notes = '';
        Map<String, String> uatouacRcrdType = NewHireUtil.USER_ACCOUNT_TO_USER_ACCOUNT_CASE_RECORD_TYPE;

        for(User_Account__c uac : usrAccOfProvCases)
        {
            //Create user accounts + cases for the new transfer case
            //List<User_Account_Case__c> usrAccCases =  ua.User_Accounts_Cases__r;
            Case c =  contactIdToCaseMap.get(uac.Contact__c);
            if(c.RecordTypeId == RECORDTYPE_PROVISIONING_UPDATE)
            {
                // Per Ticket SF-438: 
                // User_Account_Case__c records for Update cases will be 
                // created via user interaction with AddService.page 
                // instead of being automatically created here.
                //  
                continue;
                
                // type = NewHireUtil.USER_ACCOUNT_CASE_TYPE_NONE;
                // status = NewHireUtil.USER_ACCOUNT_CASE_STATUS_NONE;
            }
            else if(c.RecordTypeId == RECORDTYPE_PROVISIONING_DROP) 
            { 
                // If the User Account is inactive, we do not need to 
                // request a deactivation for it.
                if(!uac.Active__c) { continue; }
                                
                type = NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE;
                status = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN;
                acDate = c.Due_Date__c;
            }
            else if(c.RecordTypeId == RECORDTYPE_PROVISIONING_SUSPENSION)
            {
                if(uac.Active__c)
                {
                    type = NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE;
                    status = NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN;
                    acDate = c.Due_Date__c;
                    notes = USER_ACCOUNT_CASE_NOTES_SUSPENSION_ACTIVE;
                }
                else
                {
                    type = NewHireUtil.USER_ACCOUNT_CASE_TYPE_NONE;
                    status = NewHireUtil.USER_ACCOUNT_CASE_STATUS_NONE;
                }
            }
            else if(c.RecordTypeId == RECORDTYPE_PROVISIONING_CASE)
            {
                if(uac.Active__c)
                {
                    type = NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE;
                    status = NewHireutil.USER_ACCOUNT_CASE_STATUS_OPEN;
                    acDate = c.Due_Date__c;
                    notes = 'Reactivate after temporary suspension';
                }
                else
                {
                    type = NewHireUtil.USER_ACCOUNT_CASE_TYPE_NONE;
                    status = NewHireUtil.USER_ACCOUNT_CASE_STATUS_NONE;
                }
                
            }
            String recordType =  uac.RecordTypeId;
            //recordType = recordType.substring(0,15);

            User_Account_Case__c newUA =  new User_Account_Case__c(
                Case__c = c.Id, 
                Status__c = status, 
                //Account_Type__c = uac.Type__c,
                Profile__c = uac.Service_Profile__c, 
                Role__c = uac.Service_Role__c,
                Service__c = uac.Service__c, 
                User_Account__c = uac.Id,
                RecordTypeId = uatouacRcrdType.get(recordType), 
                Type__c = type, 
                Employee__c = c.prEmployee__c,
                Date__c = acDate, 
                Notes__c = notes);
                                        
            uacInsertList.add(newUA);
            type = '';  
            status = '';
            acDate = null;
            notes = ''; 
            
        }
        return  uacInsertList;                                       
    }
    
    /**
    * Pulls all of the Contacts whose Id's are specified in the given Map's 
    * keySet and moves information from fields on the Contact to corresponding 
    * fields on the Case (e.g. Case.prLast_Name__c = Case.prEmployee__r.LastName).
    *
    * The Case.prEmployment_Status__c and Case.Subject fields depend on the 
    * Case type.
    *
    * @param contactIdToCaseMap a map of Cases, keyed by their prEmployee__c values.
    * @return a list of new Case records with the same Ids as the given Cases, but 
    *         containing only the data from the specified contacts.
    *
    */
    public static List<Case> updateCasesWithContactAndCaseInfo(Map<Id, Case> contactIdToCaseMap)
    {
        List<Case> casesToUpdate = new List<Case>();
        Map<Id,Contact> contactMap = new Map<Id,Contact>([select 
            Id, 
            FirstName, 
            LastName, 
            Title, 
            Personal_Email__c, 
            Budget_Line_Item__c, 
            Department,
            torDepartment__c,
            Office_Location__c, 
            ReportsToId, 
            Billing_Code__c, 
            Full_Time_Part_Time__c,
            HomePhone,
            Signing_Limit__c,
            Salesforce_Business_Role__c,
            Division__c,
            Cell_Phone_Reimbursement__c,
            Desk_Assignment__c,
            Employment_Status__c
            from Contact where Id in: contactIdToCaseMap.keySet()]);
  
        for(Case ca : contactIdToCaseMap.values())
        {            
            Contact c = contactMap.get(ca.prEmployee__c);
            Case caseObj = new Case(Id = ca.Id);
            caseObj.prFirst_Name__c = c.FirstName;
            caseObj.prLastName__c = c.LastName;
            caseObj.prPosition_Title__c = c.Title;
            caseObj.prPersonal_Email__c = c.Personal_Email__c;
            caseObj.prBudget_Line_Item__c = c.Budget_Line_Item__c;
            caseObj.prDepartment__c = c.torDepartment__c;
            caseObj.prLocation__c = c.Office_Location__c;
            caseObj.prReports_To__c = c.ReportsToId;
            caseObj.prPayroll_Department_Code__c = c.Billing_Code__c;
            caseObj.prFull_Time_Part_Time__c = c.Full_Time_Part_Time__c;
            caseObj.prPersonal_Phone__c = c.HomePhone;
            caseObj.prSigning_Limit__c = c.Signing_Limit__c;
            caseObj.Salesforce_Business_Role__c = c.Salesforce_Business_Role__c;
            caseObj.prDivision__c = c.Division__c;
            caseObj.prCell_Phone_Reimbursement__c = c.Cell_Phone_Reimbursement__c;
            caseObj.prDesk_Assignment__c = c.Desk_Assignment__c;
            //caseObj.prEmployment_Status__c = c.Employment_Status__c;
            String subject = c.FirstName + ' ' + c.LastName + ' - ' + String.valueOf(ca.Due_Date__c);
            if(ca.RecordTypeId == RECORDTYPE_PROVISIONING_UPDATE)
            {
                caseObj.prEmployment_Status__c = c.Employment_Status__c;
                caseObj.Subject = CASE_SUBJECT_UPDATE + subject;
            }
            if(ca.RecordTypeId == RECORDTYPE_PROVISIONING_DROP)
            {
                caseObj.prEmployment_Status__c = EMPLOYMENT_STATUS_INACTIVE;
                caseObj.Subject = CASE_SUBJECT_DROP + subject;
                
            }
            if(ca.RecordTypeId == RECORDTYPE_PROVISIONING_SUSPENSION)
            {
                caseObj.prEmployment_Status__c = EMPLOYMENT_STATUS_TEMPORARILY_SUSPENDED;
                caseObj.Subject = CASE_SUBJECT_SUSPENSION + subject;
                // MMT - adding drop type for the original suspension case
                caseObj.Type = CASE_TYPE_DROP;
            }
            if(ca.RecordTypeId == RECORDTYPE_PROVISIONING_CASE) //Update Case of suspended case
            {
                caseObj.prEmployment_Status__c = EMPLOYMENT_STATUS_ACTIVE;
                caseObj.Subject = CASE_SUBJECT_PROVISIONING + subject;
            }
            caseObj.RecordTypeId = RECORDTYPE_PROVISIONING_CASE;

            casesToUpdate.add(caseObj);
        }

        return casesToUpdate;
    }
}