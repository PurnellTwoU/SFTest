/**
* Unit Tests for the NewHireUtil class.
*
* GetId
* - Query clause for an object which exists yields that object's ID.
* - Second request with same cache key returns the same result and does not 
*   generate a SOQL query.
* - Request for a record that does not exist throws a 
*   NewHireUtil.IdNotFoundException with a message mentioning the queryClause
*
* GetRecordTypeMap
* - If all given objects exist, the returned map mirrors the input, with 
*   all values and all keys (if queryKeys is enabled) with the correct IDs.
* - A successful result generates only one SOQL query.
* - Second request with same cache key returns the same result and does not 
*   generate a SOQL query.
* - Request for a record that does not exist throws a 
*   NewHireUtil.IdNotFoundException with a message mentioning the queryClause
*
* Queried Constants
* Each queried constant gets its own test method, which fails
* if the needed record is not installed. This way, the tester
* gets a list of needed records in the test results instead of 
* discovering the missing records incrementally.
*
* CreateAssetCases
* - No Asset_Case__c records are created for Update cases.
* - Drop, Provisioning, Suspension and any other Case type besides Update
*   cause creation of an Asset_Case__c record for each of the Contact's Assets
* - Each of the fields on the Case and Asset_Case__c records is populated correctly
*
* CreateUserAccounts
* - No User_Account_Case__c records are created for Update cases.
* - No User_Account_Case__c records are created for inactive User_Account__c under Drop Cases. 
* - Drop, Provisioning, Suspension and any other Case type besides Update
*   cause creation of an User_Account_Case__c record for each of the Contact's 
*   User_Account_Case__c records.
* - Each of the fields on the Case and User_Account_Case__c records is populated correctly
*
* UpdateCasesWithContactAndCaseInfo
* - The correct fields are pulled from the Contact onto the Case,
* based on the Case's recordType.
*  
* 
*/
@isTest
private class NewHireUtilTest 
{

    // Unit Tests for all queried constants.
    // Assertions for each constant:
    // - No IDNotFoundException is thrown.
    // - A non-null value is returned.  
    //
    
    @isTest(SeeAllData=true)
    public static void testConstDEFAULT_ACCOUNT()
    { try
      { System.assert(null!=NewHireUtil.DEFAULT_ACCOUNT, 'Missing record for DEFAULT_ACCOUNT.'); }
      catch(NewHireUtil.IDNotFoundException e)
      { System.assert(false,'Missing record for DEFAULT_ACCOUNT.'); }
    }

    @isTest(SeeAllData=true)
    public static void testConstCONTRACTOR_ACCOUNT()
    { try
      { System.assert(null!=NewHireUtil.CONTRACTOR_ACCOUNT, 'Missing record for CONTRACTOR_ACCOUNT.'); }
      catch(NewHireUtil.IDNotFoundException e)
      { System.assert(false,'Missing record for CONTRACTOR_ACCOUNT.'); }
    }
    
    @isTest(SeeAllData=true)
    public static void testConstRECORDTYPE_PROVISIONING_ADD()
    { try
      { System.assert(null!=NewHireUtil.RECORDTYPE_PROVISIONING_ADD, 'Missing record for RECORDTYPE_PROVISIONING_ADD.'); }
      catch(NewHireUtil.IDNotFoundException e)
      { System.assert(false,'Missing record for RECORDTYPE_PROVISIONING_ADD.'); }
    }
    
    @isTest(SeeAllData=true)
    public static void testConstRECORDTYPE_PROVISIONING_DROP()
    { try
      { System.assert(null!=NewHireUtil.RECORDTYPE_PROVISIONING_DROP, 'Missing record for RECORDTYPE_PROVISIONING_DROP.'); }
      catch(NewHireUtil.IDNotFoundException e)
      { System.assert(false,'Missing record for RECORDTYPE_PROVISIONING_DROP.'); }
    }
    
    @isTest(SeeAllData=true)
    public static void testConstRECORDTYPE_PROVISIONING_UPDATE()
    { try
      { System.assert(null!=NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE, 'Missing record for RECORDTYPE_PROVISIONING_UPDATE.'); }
      catch(NewHireUtil.IDNotFoundException e)
      { System.assert(false,'Missing record for RECORDTYPE_PROVISIONING_UPDATE.'); }
    }
    
    @isTest(SeeAllData=true)
    public static void testConstRECORDTYPE_PROVISIONING_SUSPENSION()
    { try
      { System.assert(null!=NewHireUtil.RECORDTYPE_PROVISIONING_SUSPENSION, 'Missing record for RECORDTYPE_PROVISIONING_SUSPENSION.'); }
      catch(NewHireUtil.IDNotFoundException e)
      { System.assert(false,'Missing record for RECORDTYPE_PROVISIONING_SUSPENSION.'); }
    }
    
    @isTest(SeeAllData=true)
    public static void testConstRECORDTYPE_PROVISIONING_CASE()
    { try
      { System.assert(null!=NewHireUtil.RECORDTYPE_PROVISIONING_CASE, 'Missing record for RECORDTYPE_PROVISIONING_CASE.'); }
      catch(NewHireUtil.IDNotFoundException e)
      { System.assert(false,'Missing record for RECORDTYPE_PROVISIONING_CASE.'); }
    }
    
    @isTest(SeeAllData=true)
    public static void testConstRECORDTYPE_PROVISIONING_CASE_COMPLETE()
    { try
      { System.assert(null!=NewHireUtil.RECORDTYPE_PROVISIONING_CASE_COMPLETE, 'Missing record for RECORDTYPE_PROVISIONING_CASE_COMPLETE.'); }
      catch(NewHireUtil.IDNotFoundException e)
      { System.assert(false,'Missing record for RECORDTYPE_PROVISIONING_CASE_COMPLETE.'); }
    }
    
    @isTest(SeeAllData=true)
    public static void testConstRECORDTYPE_PROVISIONING_TASK()
    { try
      { System.assert(null!=NewHireUtil.RECORDTYPE_PROVISIONING_TASK, 'Missing record for RECORDTYPE_PROVISIONING_TASK.'); }
      catch(NewHireUtil.IDNotFoundException e)
      { System.assert(false,'Missing record for RECORDTYPE_PROVISIONING_TASK.'); }
    }
    
    @isTest(SeeAllData=true)
    public static void testConstRECORDTYPE_PROVISIONING_TASK_WITH_PROFILE()
    { try
      { System.assert(null!=NewHireUtil.RECORDTYPE_PROVISIONING_TASK_WITH_PROFILE, 'Missing record for RECORDTYPE_PROVISIONING_TASK_WITH_PROFILE.'); }
      catch(NewHireUtil.IDNotFoundException e)
      { System.assert(false,'Missing record for RECORDTYPE_PROVISIONING_TASK_WITH_PROFILE.'); }
    }
    
    @isTest(SeeAllData=true)
    public static void testConstRECORDTYPE_SALESFORCE_PROVISIONING_TASK()
    { try
      { System.assert(null!=NewHireUtil.RECORDTYPE_SALESFORCE_PROVISIONING_TASK, 'Missing record for RECORDTYPE_SALESFORCE_PROVISIONING_TASK.'); }
      catch(NewHireUtil.IDNotFoundException e)
      { System.assert(false,'Missing record for RECORDTYPE_SALESFORCE_PROVISIONING_TASK.'); }
    }
        
    @isTest(SeeAllData=true)
    public static void testConstRECORDTYPE_SALESFORCE_USER_ACCOUNT()
    { try
      { System.assert(null!=NewHireUtil.RECORDTYPE_SALESFORCE_USER_ACCOUNT, 'Missing record for RECORDTYPE_SALESFORCE_USER_ACCOUNT.'); }
      catch(NewHireUtil.IDNotFoundException e)
      { System.assert(false,'Missing record for RECORDTYPE_SALESFORCE_USER_ACCOUNT.'); }
    }
    
    @isTest(SeeAllData=true)
    public static void testConstRECORDTYPE_USER_ACCOUNT()
    { try
      { System.assert(null!=NewHireUtil.RECORDTYPE_USER_ACCOUNT, 'Missing record for RECORDTYPE_USER_ACCOUNT.'); }
      catch(NewHireUtil.IDNotFoundException e)
      { System.assert(false,'Missing record for RECORDTYPE_USER_ACCOUNT.'); }
    }
    
    @isTest(SeeAllData=true)
    public static void testConstRECORDTYPE_USER_ACCOUNT_WITH_PROFILE()
    { try
      { System.assert(null!=NewHireUtil.RECORDTYPE_USER_ACCOUNT_WITH_PROFILE, 'Missing record for RECORDTYPE_USER_ACCOUNT_WITH_PROFILE.'); }
      catch(NewHireUtil.IDNotFoundException e)
      { System.assert(false,'Missing record for RECORDTYPE_USER_ACCOUNT_WITH_PROFILE.'); }
    }   
    
    @isTest(SeeAllData=true)
    public static void testConstRECORDTYPE_ASSET_CASE_PROVISIONING_REQUEST()
    { try
      { System.assert(null!=NewHireUtil.RECORDTYPE_ASSET_CASE_PROVISIONING_REQUEST, 'Missing record for RECORDTYPE_ASSET_CASE_PROVISIONING_REQUEST.'); }
      catch(NewHireUtil.IDNotFoundException e)
      { System.assert(false,'Missing record for RECORDTYPE_ASSET_CASE_PROVISIONING_REQUEST.'); }
    }
    
    @isTest(SeeAllData=true)
    public static void testConstUSER_ACCOUNT_TO_USER_ACCOUNT_CASE_RECORD_TYPE()
    { try
      { System.assert(null!=NewHireUtil.USER_ACCOUNT_TO_USER_ACCOUNT_CASE_RECORD_TYPE, 'Missing record for USER_ACCOUNT_TO_USER_ACCOUNT_CASE_RECORD_TYPE.'); }
      catch(NewHireUtil.IDNotFoundException e)
      { System.assert(false,'Missing record for USER_ACCOUNT_TO_USER_ACCOUNT_CASE_RECORD_TYPE.'); }
    }
    
    @isTest(SeeAllData=true)
    public static void testConstUACASE_RTYPE_FOR_SRV_FIELDSET()
    { try
      { System.assert(null!=NewHireUtil.UACASE_RTYPE_FOR_SRV_FIELDSET, 'Missing record for UACASE_RTYPE_FOR_SRV_FIELDSET.'); }
      catch(NewHireUtil.IDNotFoundException e)
      { System.assert(false,'Missing record for UACASE_RTYPE_FOR_SRV_FIELDSET.'); }
    }
    
    @isTest(SeeAllData=true)
    public static void testConstACASE_RTYPE_FOR_ACLASS_FIELDSET()
    { try
      { System.assert(null!=NewHireUtil.ACASE_RTYPE_FOR_ACLASS_FIELDSET, 'Missing record for ACASE_RTYPE_FOR_ACLASS_FIELDSET.'); }
      catch(NewHireUtil.IDNotFoundException e)
      { System.assert(false,'Missing record for ACASE_RTYPE_FOR_ACLASS_FIELDSET.'); }
    }
    
    
    

    /**
    * Generate a random string for testing purposes.
    */
    public static String rndStr()
    {
        return 'NHUTest'+Math.random();     
    }

    /**
    * GetId
    * - Query clause for an object which exists yields that object's ID.
    * - Second request with same cache key returns the same result and does not 
    *   generate a SOQL query.
    * - Request for a record that does not exist throws a 
    *   NewHireUtil.IdNotFoundException with a message mentioning the queryClause
    */
    @isTest
    static void testGetId()
    {
        // Clear the cache so it does not interfere with our tests.
        NewHireUtil.ID_CACHE.clear();
        Integer cacheKey1 = -10;
        Integer cacheKey2 = -20;
        
        Account testAccount = new Account(Name=rndStr());
        insert testAccount;
        
        String queryClause = 'Account where Name = \''+testAccount.Name+'\'';
        
        Id firstId = null;
        try
        {
            firstId = NewHireUtil.getId(queryClause, cacheKey1);
            
        } catch(NewHireUtil.IDNotFoundException e)
        {
            System.assert(false, 'Threw a NewHireUtil.IDNotFoundException for a record which exists.');         
        }
        
        
        System.assertEquals(testAccount.Id, firstId,
        'The ID returned did not match that of the test record.');
        
        
        Id secondId = null;
        Integer queriesBefore = Limits.getQueries();
        try
        {
            secondId = NewHireUtil.getId(queryClause, cacheKey1);
            
        } catch(NewHireUtil.IDNotFoundException e)
        {
            System.assert(false, 'Threw an ID not found exception for a record which exists.');         
        }
        Integer queriesAfter = Limits.getQueries();
        
        System.assertEquals(firstId,secondId,
            'A second call with same queryId and cache key yielded a different ID.');
        
        System.assertEquals(0,queriesAfter-queriesBefore,
            'Second call with same cache key generated another SOQL query.');
            
        // Test for an IDNotFoundException
        //
        String badQueryClause = 'Account where Name = \''+rndStr()+'\'';        
        try
        {
            Id thirdId = NewHireUtil.getId(badQueryClause, cacheKey2);
            System.assert(false, 
                'Failed to throw a NewHireUtil.IDNotFoundException when given a queryClause for a record which does not exist.');
        } 
        catch(NewHireUtil.IDNotFoundException e)
        {
            System.assert(e.getMessage().contains(badQueryClause),
                'Threw a NewHireUtil.IDNotFoundException which does not mention the bad query clause.');            
        }
        
        // Clear the cache so it does not interfere with other functionality test.
        NewHireUtil.ID_CACHE.clear();       
    }
    
    /**
    * GetRecordTypeMap
    * - If all given objects exist, the returned map mirrors the input, with 
    *   all values and all keys (if queryKeys is enabled) with the correct IDs.
    * - A successful result generates only one SOQL query.
    * - Second request with same cache key returns the same result and does not 
    *   generate a SOQL query.
    * - Request for a record that does not exist throws a 
    *   NewHireUtil.IdNotFoundException with a message mentioning the queryClause
    */
    @isTest
    public static void testGetRecordTypeMap()
    {
        // Clear the cache so it does not interfere with our tests.
        NewHireUtil.MAP_CACHE.clear();
        Integer cacheKey1 = -10;
        Integer cacheKey2 = -20;
        
        // Since we cannot user DML to insert RecordTypes, we will 
        // use some of the RecordTypes that should already be installed.
        //
        // Which ones we use is not important, but records with different 
        // DeveloperNames are preferable. 
        
        Map<Id,RecordType> rtMap = new Map<Id,RecordType>([
            select 
                Id,
                DeveloperName
            from RecordType
            where Id in :new Id[]{
                NewHireUtil.RECORDTYPE_PROVISIONING_ADD,
                NewHireUtil.RECORDTYPE_PROVISIONING_DROP,
                NewHireUtil.RECORDTYPE_PROVISIONING_SUSPENSION,
                NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
                NewHireUtil.RECORDTYPE_PROVISIONING_CASE,
                NewHireUtil.RECORDTYPE_PROVISIONING_CASE_COMPLETE,
                NewHireUtil.RECORDTYPE_PROVISIONING_TASK,
                NewHireUtil.RECORDTYPE_PROVISIONING_TASK_WITH_PROFILE,
                NewHireUtil.RECORDTYPE_SALESFORCE_PROVISIONING_TASK
            }
        ]);
        
        System.assert(rtMap.size() > 3,
            'At least four unique RecordTypes are needed for this test. '
            +'Cannot complete test because not enough of the required '
            +'RecordTypes installed in your org.');
        
        RecordType[] rtList = rtMap.values(); 
        
        RecordType rtKey1 = rtList[0];
        RecordType rtVal1 = rtList[1];
        RecordType rtKey2 = rtList[2];      
        RecordType rtVal2 = rtList[3];
        
        String rndName1 = rndStr();
        String rndName2 = rndStr();
        
        Map<String,String> nameToIdInput = new Map<String,String>
        {
            rndName1 => rtVal1.DeveloperName,
            rndName2 => rtVal2.DeveloperName 
        };
        
        Map<String,String> idToIdInput = new Map<String,String>
        {
            rtKey1.DeveloperName => rtVal1.DeveloperName,
            rtKey2.DeveloperName => rtVal2.DeveloperName 
        };
        
        Map<String,String> rndMap = new Map<String,String>{
            rndStr()=>rndStr(),
            rndStr()=>rndStr()
        };
        
        // Try to query for records that do not exist.
        
        try
        {
            NewHireUtil.getRecordTypeMap(rndMap, false, cacheKey1);
            System.assert(false,'Failed to throw a NewHireUtil.IDNotFoundException when given a map naming non-existent records.');
        } 
        catch(NewHireUtil.IDNotFoundException e)
        {
            // Make sure that the error message mentions at least one of 
            // the Name values it could not find.
            //
            Set<String> toFind = new Set<String>();         
            toFind.addAll(rndMap.keySet());
            toFind.addAll(rndMap.values());
            
            Boolean foundMention = false;       
            for(String val : toFind)
            {
                if(e.getMessage().contains(val))
                {
                    foundMention = true;
                    break;
                }               
            }
            System.assert(foundMention, 
                'The NewHireUtil.IDNotFoundException thrown fails to mention the '
                +'names of any of the records that were not found: '+e);                        
        }
        
        // We must use runAs to be able to insert RecordTypes.
        // We need a User record to pass into runAs. We will use the 
        // current user. The current user must have permission to insert 
        // RecordTypes.
        //
        User user = [select Id from User where Id=:UserInfo.getUserId()];  
                
        // Test with queryKeys=false
        //
        
        Map<String,String> nameToIdOutput = null;    
        Integer queriesBefore = Limits.getQueries();    
        try
        {
            nameToIdOutput = NewHireUtil.getRecordTypeMap(nameToIdInput, false, cacheKey1);
        } 
        catch(NewHireUtil.IDNotFoundException e)
        {   
            for(String name : nameToIdInput.keySet())
            {
                if(e.getMessage().contains(name))
                {
                    System.assert(false, 'Attempted to query for by a key when queryKeys was false.');                  
                }               
            }
            System.assert(false,'Threw an unexpected NewHireUtil.IDNotFoundException [queryKeys=false]: '+e);           
        }
        Integer queriesAfter = Limits.getQueries();
        
        System.assertEquals(1,queriesAfter-queriesBefore, 
            'Wrong number of queries was used.');
        
        System.assertEquals(rtVal1.Id,nameToIdOutput.get(rndName1),
            'Output map gave the wrong value for one of its keys [queryKeys=false].');
        
        System.assertEquals(rtVal2.Id,nameToIdOutput.get(rndName2),
            'Output map gave the wrong value for one of its keys [queryKeys=false].');
        
        
        // Test with queryKeys=true
        //
        
        Map<String,String> idToIdOutput = null; 
        queriesBefore = Limits.getQueries();    
        try
        {
            idToIdOutput = NewHireUtil.getRecordTypeMap(idToIdInput, true, cacheKey2);
        } 
        catch(NewHireUtil.IDNotFoundException e)
        {   
            System.assert(false,'Threw an unexpected NewHireUtil.IDNotFoundException [queryKeys=true]: '+e);            
        }
        queriesAfter = Limits.getQueries();
        
        System.assertEquals(1,queriesAfter-queriesBefore, 
            'Wrong number of queries was used.');
        
        System.assertEquals(rtVal1.Id,idToIdOutput.get(rtKey1.Id),
            'Output map gave the wrong value for one of its keys [queryKeys=true].');
        
        System.assertEquals(rtVal2.Id,idToIdOutput.get(rtKey2.Id),
            'Output map gave the wrong value for one of its keys [queryKeys=true].');
        
        
        // Test the cache
        //
        
        queriesBefore = Limits.getQueries(); 
        Map<String,String> idToIdCachedOutput = null;   
        try
        {
            // We use the nameToId map with the idToId cache key.
            // This should return the idToIdOutput, even though the input was different.
            idToIdCachedOutput = NewHireUtil.getRecordTypeMap(nameToIdInput, true, cacheKey2);
        } 
        catch(NewHireUtil.IDNotFoundException e)
        {   
            System.assert(false,'Threw an unexpected NewHireUtil.IDNotFoundException when requesting a cached record [queryKeys=true]: '+e);            
        }
        queriesAfter = Limits.getQueries();
        
        System.assertEquals(0,queriesAfter-queriesBefore,
            'Wrong number of queries issued when make a request whose output should have been cached.');
        
        System.assert(null != idToIdCachedOutput,
            'Returned null when asked for a cached record.');
        
        System.assert(idToIdCachedOutput.keySet().containsAll(idToIdOutput.keySet()),
            'Return the wrong record when asked for a cached value.');
        
        
        // Clear the Map cache so our test records don't interfere with other 
        // code in this scope.
        NewHireUtil.MAP_CACHE.clear();
    }
    
    
    /**
    * CreateAssetCases
    * - No Asset_Case__c records are created for Update cases.
    * - Drop, Provisioning, Suspension and any other Case type besides Update
    *   cause creation of an Asset_Case__c record for each of the Contact's Assets
    * - Each of the fields on the Case and Asset_Case__c records is populated correctly
    */
    @isTest
    public static void testCreateAssetCases()
    {
        
        Account theAccount = new Account(Name=rndStr());
        insert theAccount;
        
        Contact contactUpdate  = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact contactDrop    = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact contactSuspend = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact contactGeneric = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact contactOther   = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        
        insert new sObject[]
        {
            contactUpdate,
            contactDrop,
            contactSuspend,
            contactGeneric,
            contactOther
        };
        
        Asset_Classification__c aclUpdate1  = new Asset_Classification__c(Name=rndStr());
        Asset_Classification__c aclUpdate2  = new Asset_Classification__c(Name=rndStr());
        Asset_Classification__c aclDrop1    = new Asset_Classification__c(Name=rndStr());
        Asset_Classification__c aclDrop2    = new Asset_Classification__c(Name=rndStr());
        Asset_Classification__c aclSuspend1 = new Asset_Classification__c(Name=rndStr());
        Asset_Classification__c aclSuspend2 = new Asset_Classification__c(Name=rndStr());
        Asset_Classification__c aclGeneric1 = new Asset_Classification__c(Name=rndStr());
        Asset_Classification__c aclGeneric2 = new Asset_Classification__c(Name=rndStr());
        Asset_Classification__c aclOther1   = new Asset_Classification__c(Name=rndStr());
        Asset_Classification__c aclOther2   = new Asset_Classification__c(Name=rndStr());
        
        insert new sObject[]
        {
            aclUpdate1,
            aclUpdate2,
            aclDrop1,
            aclDrop2,
            aclSuspend1,
            aclSuspend2,
            aclGeneric1,
            aclGeneric2,
            aclOther1,
            aclOther2           
        };
        
        Asset__c assetUpdate1  = new Asset__c(Contact__c=contactUpdate.Id,  Asset_Classification__c=aclUpdate1.Id);
        Asset__c assetUpdate2  = new Asset__c(Contact__c=contactUpdate.Id,  Asset_Classification__c=aclUpdate2.Id);
        Asset__c assetDrop1    = new Asset__c(Contact__c=contactDrop.Id,    Asset_Classification__c=aclDrop1.Id);
        Asset__c assetDrop2    = new Asset__c(Contact__c=contactDrop.Id,    Asset_Classification__c=aclDrop2.Id);
        Asset__c assetSuspend1 = new Asset__c(Contact__c=contactSuspend.Id, Asset_Classification__c=aclSuspend1.Id);
        Asset__c assetSuspend2 = new Asset__c(Contact__c=contactSuspend.Id, Asset_Classification__c=aclSuspend2.Id);
        Asset__c assetGeneric1 = new Asset__c(Contact__c=contactGeneric.Id, Asset_Classification__c=aclGeneric1.Id);
        Asset__c assetGeneric2 = new Asset__c(Contact__c=contactGeneric.Id, Asset_Classification__c=aclGeneric2.Id);
        Asset__c assetOther1   = new Asset__c(Contact__c=contactOther.Id,   Asset_Classification__c=aclOther1.Id);
        Asset__c assetOther2   = new Asset__c(Contact__c=contactOther.Id,   Asset_Classification__c=aclOther2.Id);
        
        Asset__c[] aAllWithAc = new Asset__c[]
        {
            //assetUpdate1,
            //assetUpdate2,
            assetDrop1,
            assetDrop2,
            assetSuspend1,
            assetSuspend2,
            assetGeneric1,
            assetGeneric2,
            assetOther1,
            assetOther2
        };
        Asset__c[] allAssets = new Asset__c[]{};
        allAssets.addAll(aAllWithAc);
        allAssets.add(assetUpdate1);
        allAssets.add(assetUpdate2);
        insert allAssets;
        
        Case caseUpdate   = new Case(
            Due_Date__c   = Date.today().addDays(1),
            prEmployee__c = contactUpdate.Id, 
            RecordTypeId  = NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE);
        Case caseDrop     = new Case(
            Due_Date__c   = Date.today().addDays(2),
            prEmployee__c = contactDrop.Id,   
            RecordTypeId  = NewHireUtil.RECORDTYPE_PROVISIONING_DROP);
        Case caseSuspend  = new Case(
            Due_Date__c   = Date.today().addDays(3),
            prEmployee__c = contactSuspend.Id,
            RecordTypeId  = NewHireUtil.RECORDTYPE_PROVISIONING_SUSPENSION);
        Case caseGeneric  = new Case(
            Due_Date__c   = Date.today().addDays(4),
            prEmployee__c = contactGeneric.Id,
            RecordTypeId  = NewHireUtil.RECORDTYPE_PROVISIONING_CASE);
        Case caseOther    = new Case(
            Due_Date__c   = Date.today().addDays(5),
            prEmployee__c = contactOther.Id,  
            RecordTypeId  = NewHireUtil.RECORDTYPE_PROVISIONING_ADD);
        
        insert new sObject[]
        {
            caseUpdate,
            caseDrop,
            caseSuspend,
            caseGeneric,
            caseOther
        };
        
        Map<Id,Case> caseForContact = new Map<Id,Case>{
            contactUpdate.Id => caseUpdate,
            contactDrop.Id   => caseDrop,
            contactSuspend.Id => caseSuspend,
            contactGeneric.Id => caseGeneric,
            contactOther.Id   => caseOther
        };
                
        // Run our test.        
        List<Asset_Case__c> assetCases = NewHireUtil.createAssetCases(caseForContact);
        
        
        Map<Id,Asset_Case__c> acForAsset = new Map<Id,Asset_Case__c>();     
        for(Asset_Case__c ac : assetCases)
        {
            System.assert(null != ac.Asset__c, 
                'Found an Asset_Case__c with no Asset__c specified.');
            acForAsset.put(ac.Asset__c,ac);                                 
        }
        
        // Make sure all of the expected Asset_Case__c records exist.
        
        System.assert(!acForAsset.containsKey(assetUpdate1.Id),
            'Found an Asset_Case__c attached to an asset belonging to '
            +'a Contact associated with an Update Case.');
        
        System.assert(!acForAsset.containsKey(assetUpdate2.Id),
            'Found an Asset_Case__c attached to an asset belonging to '
            +'a Contact associated with an Update Case.');
        
        System.assert(acForAsset.containsKey(assetDrop1.Id),
            'Missing an Asset_Case__c associated with a Drop Case.');
        
        System.assert(acForAsset.containsKey(assetDrop2.Id),
            'Missing an Asset_Case__c associated with a Drop Case.');
        
        System.assert(acForAsset.containsKey(assetSuspend1.Id),
            'Missing an Asset_Case__c associated with a Suspend Case.');
        
        System.assert(acForAsset.containsKey(assetSuspend2.Id),
            'Missing an Asset_Case__c associated with a Suspend Case.');
        
        System.assert(acForAsset.containsKey(assetGeneric1.Id),
            'Missing an Asset_Case__c associated with a generic provisioning Case.');
        
        System.assert(acForAsset.containsKey(assetGeneric2.Id),
            'Missing an Asset_Case__c associated with a generic profisioning Case.');
        
        System.assert(acForAsset.containsKey(assetOther1.Id),
            'Missing an Asset_Case__c associated with a Case of arbitrary type.');
        
        System.assert(acForAsset.containsKey(assetOther2.Id),
            'Missing an Asset_Case__c associated with a Case or arbitrary type.');
        
        // Enforce rules common to all Asset_Case__c records 
        // (regardless of Case RecordTypeId)
        for(Asset__c asset : aAllWithAc)
        {           
            Asset_Case__c assetCase = acForAsset.get(asset.Id);
            Case theCase = caseForContact.get(asset.Contact__c);
            
            System.assertEquals(theCase.Id,assetCase.Case__c,
                'Asset_Case__c.Case__c does not match Case.Id');
            
            System.assertEquals(asset.Id,assetCase.Asset__c,
                'Asset_Case__c.Asset__c does not match the correct Asset__c.Id');
            
            System.assertEquals(asset.Asset_Classification__c,assetCase.Asset_Classification__c,
                'Asset_Case__c.Asset_Classification__c does not match the correct Asset__c.Asset_Classification__c');
            
            System.assertEquals(NewHireUtil.RECORDTYPE_ASSET_CASE_PROVISIONING_REQUEST, assetCase.RecordTypeId,
                'Wrong value for Asset_Case__c.RecordTypeId');

            System.assertEquals(theCase.prEmployee__c,assetCase.Employee__c,
                'Asset_Case__c.Employee__c does not match Case.prEmployee__c');
            
        }
        
        
        // User one asset per Case to check that fields are populated properly
          
        
        // Asset 1 under a Drop Case.

        System.assert(acForAsset.containsKey(assetDrop1.Id), 
            'Missing an Asset_Case__c for a Drop Case');
        Asset_Case__c assetCase = acForAsset.get(assetDrop1.Id);
        
        System.assertEquals(NewHireUtil.ASSET_CASE_TYPE_RECLAIM, assetCase.Type__c, 
            'Wrong Type__c for Asset_Case__c related to a Drop case.');
        System.assertEquals(NewHireutil.ASSET_CASE_STATUS_OPEN, assetCase.Status__c,
            'Wrong Asset_Case__c.Status__c value related to a Drop case.');
        System.assertEquals(caseDrop.Due_Date__c,assetCase.Date_Needed__c,
            'Asset_Case__c.Date_Needed__c does not match Case__c.Due_Date__c');
        System.assertEquals('',assetCase.Notes__c,
            'Wrong Asset_Case__c.Notes__c related to a Drop Case');
            
        // Asset 1 under a Suspension Case.
        
        System.assert(acForAsset.containsKey(assetSuspend1.Id), 
            'Missing an Asset_Case__c related to Suspension');
        assetCase = acForAsset.get(assetSuspend1.Id);
        
        System.assertEquals(NewHireUtil.ASSET_CASE_TYPE_RECLAIM, assetCase.Type__c, 
            'Wrong Type__c for Asset_Case__c related to Suspension');
        // SF-3364 Changed Suspension Cases to default status of Cancelled.
        System.assertEquals(NewHireutil.ASSET_CASE_STATUS_CANCEL, assetCase.Status__c,
            'Wrong Asset_Case__c.Status__c related to Suspension');
        System.assertEquals(caseSuspend.Due_Date__c,assetCase.Date_Needed__c,
            'Asset_Case__c.Date_Needed__c does not match Case__c.Due_Date__c related to Suspension');
        System.assertEquals(NewHireUtil.ASSET_CASE_NOTES_SUSPENSION,assetCase.Notes__c,
            'Wrong Asset_Case__c.Notes__c related to Suspension');
        
        // Asset 1 under a generic provisioning Case.
        
        System.assert(acForAsset.containsKey(assetGeneric1.Id), 
            'Missing an Asset_Case__c related to a generic provisioning Case');
        assetCase = acForAsset.get(assetGeneric1.Id);
        
        System.assertEquals(NewHireUtil.ASSET_CASE_TYPE_PROVISION, assetCase.Type__c, 
            'Wrong Type__c for Asset_Case__c related to a generic provisioning Case');
        System.assertEquals(NewHireutil.ASSET_CASE_STATUS_OPEN, assetCase.Status__c,
            'Wrong Asset_Case__c.Status__c related to a generic provisioning Case');
        System.assertEquals(caseGeneric.Due_Date__c,assetCase.Date_Needed__c,
            'Asset_Case__c.Date_Needed__c does not match Case__c.Due_Date__c related to a generic provisioning Case');
        System.assertEquals(NewHireUtil.ASSET_CASE_NOTES_PROVISIONING,assetCase.Notes__c,
            'Wrong Asset_Case__c.Notes__c related to a generic provisioning Case');
            
        // Asset 1 under a Case of arbitrary type.
        
        System.assert(acForAsset.containsKey(assetOther1.Id), 
            'Missing an Asset_Case__c related to a generic provisioning Case');
        assetCase = acForAsset.get(assetOther1.Id);
        
        System.assertEquals('', assetCase.Type__c, 
            'Wrong Type__c for Asset_Case__c related to a Case of arbitrary type');
        System.assertEquals('', assetCase.Status__c,
            'Wrong Asset_Case__c.Status__c related to a Case of arbitrary type');
        System.assertEquals(null,assetCase.Date_Needed__c,
            'Asset_Case__c.Date_Needed__c does not match Case__c.Due_Date__c related to a Case of arbitrary type');
        System.assertEquals('',assetCase.Notes__c,
            'Wrong Asset_Case__c.Notes__c related to a Case of arbitrary type');
        
        
    }
    
    /**
    * CreateUserAccounts
    * - No User_Account_Case__c records are created for Update cases.
    * - No User_Account_Case__c records are created for inactive User_Account__c under Drop Cases. 
    * - Drop, Provisioning, Suspension and any other Case type besides Update
    *   cause creation of an User_Account_Case__c record for each of the Contact's 
    *   User_Account_Case__c records.
    * - Each of the fields on the Case and User_Account_Case__c records is populated correctly
    */
    @isTest 
    public static void testCreateUserAccounts()
    {
        Account theAccount = new Account(Name=rndStr());
        insert theAccount;
        
        Contact contactUpdate  = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact contactDrop    = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact contactSuspend = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact contactGeneric = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact contactOther   = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        
        insert new sObject[]
        {
            contactUpdate,
            contactDrop,
            contactSuspend,
            contactGeneric,
            contactOther
        };
        
        Service__c serviceUpdateActive    = new Service__c(Name=rndStr());
        Service__c serviceUpdateInactive  = new Service__c(Name=rndStr());
        Service__c serviceDropActive      = new Service__c(Name=rndStr());
        Service__c serviceDropInactive    = new Service__c(Name=rndStr());
        Service__c serviceSuspendActive   = new Service__c(Name=rndStr());
        Service__c serviceSuspendInactive = new Service__c(Name=rndStr());
        Service__c serviceGenericActive   = new Service__c(Name=rndStr());
        Service__c serviceGenericInactive = new Service__c(Name=rndStr());
        Service__c serviceOtherActive     = new Service__c(Name=rndStr());
        Service__c serviceOtherInactive   = new Service__c(Name=rndStr());
        
        insert new sObject[]
        {
            serviceUpdateActive,
            serviceUpdateInactive,
            serviceDropActive,
            serviceDropInactive,
            serviceSuspendActive,
            serviceSuspendInactive,
            serviceGenericActive,
            serviceGenericInactive,
            serviceOtherActive,
            serviceOtherInactive            
        };
        
        Service_Role__c roleUpdateActive    = new Service_Role__c(Name=rndStr(),Service__c=serviceUpdateActive.Id);
        Service_Role__c roleUpdateInactive  = new Service_Role__c(Name=rndStr(),Service__c=serviceUpdateInactive.Id);
        Service_Role__c roleDropActive      = new Service_Role__c(Name=rndStr(),Service__c=serviceDropActive.Id);
        Service_Role__c roleDropInactive    = new Service_Role__c(Name=rndStr(),Service__c=serviceDropInactive.Id);
        Service_Role__c roleSuspendActive   = new Service_Role__c(Name=rndStr(),Service__c=serviceSuspendActive.Id);
        Service_Role__c roleSuspendInactive = new Service_Role__c(Name=rndStr(),Service__c=serviceSuspendInactive.Id);
        Service_Role__c roleGenericActive   = new Service_Role__c(Name=rndStr(),Service__c=serviceGenericActive.Id);
        Service_Role__c roleGenericInactive = new Service_Role__c(Name=rndStr(),Service__c=serviceGenericInactive.Id);
        Service_Role__c roleOtherActive     = new Service_Role__c(Name=rndStr(),Service__c=serviceOtherActive.Id);
        Service_Role__c roleOtherInactive   = new Service_Role__c(Name=rndStr(),Service__c=serviceOtherInactive.Id);
        
        
        Service_Profile__c profileUpdateActive    = new Service_Profile__c(Name=rndStr(),Service__c=serviceUpdateActive.Id);
        Service_Profile__c profileUpdateInactive  = new Service_Profile__c(Name=rndStr(),Service__c=serviceUpdateInactive.Id);
        Service_Profile__c profileDropActive      = new Service_Profile__c(Name=rndStr(),Service__c=serviceDropActive.Id);
        Service_Profile__c profileDropInactive    = new Service_Profile__c(Name=rndStr(),Service__c=serviceDropInactive.Id);
        Service_Profile__c profileSuspendActive   = new Service_Profile__c(Name=rndStr(),Service__c=serviceSuspendActive.Id);
        Service_Profile__c profileSuspendInactive = new Service_Profile__c(Name=rndStr(),Service__c=serviceSuspendInactive.Id);
        Service_Profile__c profileGenericActive   = new Service_Profile__c(Name=rndStr(),Service__c=serviceGenericActive.Id);
        Service_Profile__c profileGenericInactive = new Service_Profile__c(Name=rndStr(),Service__c=serviceGenericInactive.Id);
        Service_Profile__c profileOtherActive     = new Service_Profile__c(Name=rndStr(),Service__c=serviceOtherActive.Id);
        Service_Profile__c profileOtherInactive   = new Service_Profile__c(Name=rndStr(),Service__c=serviceOtherInactive.Id);
        
        insert new sOBject[]
        {
             roleUpdateActive,
             roleUpdateInactive,
             roleDropActive,
             roleDropInactive,
             roleSuspendActive,
             roleSuspendInactive,
             roleGenericActive,
             roleGenericInactive,
             roleOtherActive,
             roleOtherInactive,
             profileUpdateActive,
             profileUpdateInactive,
             profileDropActive,
             profileDropInactive,
             profileSuspendActive,
             profileSuspendInactive,
             profileGenericActive,
             profileGenericInactive,
             profileOtherActive,
             profileOtherInactive
        };
        
        User_Account__c userAcctUpdateActive    = new User_Account__c(
            RecordTypeId       = NewHireUtil.RECORDTYPE_SALESFORCE_USER_ACCOUNT,
            Active__c          = true, 
            Contact__c         = contactUpdate.Id,  
            Service__c         = serviceUpdateActive.Id,    
            Service_Role__c    = roleUpdateActive.Id,    
            Service_Profile__c = profileUpdateActive.Id);
            
        User_Account__c userAcctUpdateInactive  = new User_Account__c(
            RecordTypeId       = NewHireUtil.RECORDTYPE_SALESFORCE_USER_ACCOUNT,
            Active__c          = false,
            Contact__c         = contactUpdate.Id,  
            Service__c         = serviceUpdateInactive.Id,  
            Service_Role__c    = roleUpdateInactive.Id,  
            Service_Profile__c = profileUpdateInactive.Id);
            
        User_Account__c userAcctDropActive      = new User_Account__c(
            RecordTypeId       = NewHireUtil.RECORDTYPE_USER_ACCOUNT,
            Active__c          = true, 
            Contact__c         = contactDrop.Id,    
            Service__c         = serviceDropActive.Id,      
            Service_Role__c    = roleDropActive.Id,      
            Service_Profile__c = profileDropActive.Id);
        
        User_Account__c userAcctDropInactive    = new User_Account__c(
            RecordTypeId       = NewHireUtil.RECORDTYPE_USER_ACCOUNT,
            Active__c          = false,
            Contact__c         = contactDrop.Id,    
            Service__c         = serviceDropInactive.Id,    
            Service_Role__c    = roleDropInactive.Id,    
            Service_Profile__c = profileDropInactive.Id);
        
        User_Account__c userAcctSuspendActive   = new User_Account__c(
            RecordTypeId       = NewHireUtil.RECORDTYPE_USER_ACCOUNT_WITH_PROFILE,
            Active__c          = true, 
            Contact__c         = contactSuspend.Id, 
            Service__c         = serviceSuspendActive.Id,   
            Service_Role__c    = roleSuspendActive.Id,   
            Service_Profile__c = profileSuspendActive.Id);
        
        User_Account__c userAcctSuspendInactive = new User_Account__c(
            RecordTypeId       = NewHireUtil.RECORDTYPE_USER_ACCOUNT_WITH_PROFILE,
            Active__c          = false,
            Contact__c         = contactSuspend.Id, 
            Service__c         = serviceSuspendInactive.Id, 
            Service_Role__c    = roleSuspendInactive.Id, 
            Service_Profile__c = profileSuspendInactive.Id);
        
        User_Account__c userAcctGenericActive   = new User_Account__c(
            RecordTypeId       = NewHireUtil.RECORDTYPE_SALESFORCE_USER_ACCOUNT,
            Active__c          = true, 
            Contact__c         = contactGeneric.Id, 
            Service__c         = serviceGenericActive.Id,   
            Service_Role__c    = roleGenericActive.Id,   
            Service_Profile__c = profileGenericActive.Id);
        
        User_Account__c userAcctGenericInactive = new User_Account__c(
            RecordTypeId       = NewHireUtil.RECORDTYPE_SALESFORCE_USER_ACCOUNT,
            Active__c          = false,
            Contact__c         = contactGeneric.Id, 
            Service__c         = serviceGenericInactive.Id, 
            Service_Role__c    = roleGenericInactive.Id, 
            Service_Profile__c = profileGenericInactive.Id);
        
        User_Account__c userAcctOtherActive     = new User_Account__c(
            RecordTypeId       = NewHireUtil.RECORDTYPE_USER_ACCOUNT,
            Active__c          = true, 
            Contact__c         = contactOther.Id,   
            Service__c         = serviceOtherActive.Id,     
            Service_Role__c    = roleOtherActive.Id,     
            Service_Profile__c = profileOtherActive.Id);
        
        User_Account__c userAcctOtherInactive   = new User_Account__c(
            RecordTypeId       = NewHireUtil.RECORDTYPE_USER_ACCOUNT,
            Active__c          = false,
            Contact__c         = contactOther.Id,   
            Service__c         = serviceOtherInactive.Id,   
            Service_Role__c    = roleOtherInactive.Id,   
            Service_Profile__c = profileOtherInactive.Id);
        
        User_Account__c[] uaAllWithUac = new User_Account__c[]
        {
            //userAcctUpdateActive,
            //userAcctUpdateInactive,
            userAcctDropActive,
            //userAcctDropInactive,
            userAcctSuspendActive,
            userAcctSuspendInactive,
            userAcctGenericActive,
            userAcctGenericInactive,
            userAcctOtherActive,
            userAcctOtherInactive
        };
        User_Account__c[] allUserAccts = new User_Account__c[]{};
        allUserAccts.addAll(uaAllWithUac);
        allUserAccts.add(userAcctUpdateActive);
        allUserAccts.add(userAcctUpdateInactive);
        allUserAccts.add(userAcctDropInactive);
        insert allUserAccts;
        
        Case caseUpdate   = new Case(
            Due_Date__c   = Date.today().addDays(1),
            prEmployee__c = contactUpdate.Id, 
            RecordTypeId  = NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE);
        Case caseDrop     = new Case(
            Due_Date__c   = Date.today().addDays(2),
            prEmployee__c = contactDrop.Id,   
            RecordTypeId  = NewHireUtil.RECORDTYPE_PROVISIONING_DROP);
        Case caseSuspend  = new Case(
            Due_Date__c   = Date.today().addDays(3),
            prEmployee__c = contactSuspend.Id,
            RecordTypeId  = NewHireUtil.RECORDTYPE_PROVISIONING_SUSPENSION);
        Case caseGeneric  = new Case(
            Due_Date__c   = Date.today().addDays(4),
            prEmployee__c = contactGeneric.Id,
            RecordTypeId  = NewHireUtil.RECORDTYPE_PROVISIONING_CASE);
        Case caseOther    = new Case(
            Due_Date__c   = Date.today().addDays(5),
            prEmployee__c = contactOther.Id,  
            RecordTypeId  = NewHireUtil.RECORDTYPE_PROVISIONING_ADD);
        
        insert new sObject[]
        {
            caseUpdate,
            caseDrop,
            caseSuspend,
            caseGeneric,
            caseOther
        };
        
        Map<Id,Case> caseForContact = new Map<Id,Case>{
            contactUpdate.Id  => caseUpdate,
            contactDrop.Id    => caseDrop,
            contactSuspend.Id => caseSuspend,
            contactGeneric.Id => caseGeneric,
            contactOther.Id   => caseOther
        };
                
        // Run our test.        
        List<User_Account_Case__c> userAcctCases = NewHireUtil.createUserAccounts(caseForContact);
        
        
        Map<Id,User_Account_Case__c> uacForUserAcct = new Map<Id,User_Account_Case__c>();       
        for(User_Account_Case__c uac : userAcctCases)
        {
            System.assert(null != uac.User_Account__c, 
                'Found a User_Account_Case__c with no User_Account__c specified.');
            uacForUserAcct.put(uac.User_Account__c,uac);                                    
        }
        
        // Make sure all of the expected User_Account_Case__c records exist.
        
        System.assert(!uacForUserAcct.containsKey(userAcctUpdateActive.Id),
            'Found an User_Account_Case__c attached to a User Account belonging to '
            +'a Contact associated with an Update Case.');
        
        System.assert(!uacForUserAcct.containsKey(userAcctUpdateInactive.Id),
            'Found an User_Account_Case__c attached to a User Account belonging to '
            +'a Contact associated with an Update Case.');
        
        System.assert(uacForUserAcct.containsKey(userAcctDropActive.Id),
            'Missing an User_Account_Case__c associated with a Drop Case.');
        
        System.assert(!uacForUserAcct.containsKey(userAcctDropInactive.Id),
            'Found an User_Account_Case__c attached to an Active User Account belonging to '
            +'a Contact associated with a Drop Case.');
        
        System.assert(uacForUserAcct.containsKey(userAcctSuspendActive.Id),
            'Missing an User_Account_Case__c associated with a Suspend Case.');
        
        System.assert(uacForUserAcct.containsKey(userAcctSuspendInactive.Id),
            'Missing an User_Account_Case__c associated with a Suspend Case.');
        
        System.assert(uacForUserAcct.containsKey(userAcctGenericActive.Id),
            'Missing an User_Account_Case__c associated with a generic provisioning Case.');
        
        System.assert(uacForUserAcct.containsKey(userAcctGenericInactive.Id),
            'Missing an User_Account_Case__c associated with a generic profisioning Case.');
        
        System.assert(uacForUserAcct.containsKey(userAcctOtherActive.Id),
            'Missing an User_Account_Case__c associated with a Case of arbitrary type.');
        
        System.assert(uacForUserAcct.containsKey(userAcctOtherInactive.Id),
            'Missing an User_Account_Case__c associated with a Case or arbitrary type.');
        
        // Enforce rules common to all User_Account_Case__c records 
        // (regardless of Case RecordTypeId)
        for(User_Account__c userAccount : uaAllWithUac)
        {           
            User_Account_Case__c userAccountCase = uacForUserAcct.get(userAccount.Id);
            Case theCase = caseForContact.get(userAccountCase.Employee__c);
            
            System.assert(userAccountCase.Case__c!=null, 'User_Account_Case__c.Case__c is null.');
            System.assert(userAccountCase.Case__c==theCase.Id, 
                'User_Account_Case__c.Case__c does not match Case.Id');
            
            System.assert(userAccountCase.User_Account__c!=null, 'User_Account_Case__c.User_Account__c is null.');
            System.assert(userAccountCase.User_Account__c==userAccount.Id, 
                'User_Account_Case__c.User_Account__c does not match User_Account__c.Id');
            
            System.assert(userAccountCase.Service__c!=null, 'User_Account_Case__c.Service__c is null.');
            System.assert(userAccountCase.Service__c==userAccount.Service__c,
                'User_Account_Case__c.Service__c does not match User_Account__c.Service__c');
            
            System.assert(userAccountCase.Profile__c!=null, 'User_Account_Case__c.Profile__c is null.');
            System.assert(userAccountCase.Profile__c==userAccount.Service_Profile__c,
                'User_Account_Case__c.Profile__c does not match User_Account__c.Service_Profile__c');
            
            System.assert(userAccountCase.Role__c!=null, 'User_Account_Case__c.Role__c is null.');
            System.assert(userAccountCase.Role__c==userAccount.Service_Role__c,
                'User_Account_Case__c.Role__c does not match User_Account__c.Service_Role__c');
            
            Id expected = NewHireUtil.USER_ACCOUNT_TO_USER_ACCOUNT_CASE_RECORD_TYPE.get(userAccount.RecordTypeId);
            System.assertEquals(expected,userAccountCase.RecordTypeId,
                'Wrong value for User_Account_Case__c.RecordTypeId');
            
            System.assert(userAccountCase.Employee__c!=null, 'User_Account_Case__c.Employee__c is null.');
            System.assert(userAccountCase.Employee__c==theCase.prEmployee__c,
                'User_Account_Case__c.Employee__c does not match Case__c.prEmployee__c');   
            
        }
        
        
        // Check that all fields are populated properly.
        
        
        // Active User_Account__c, Update case
        //
        // No User_Account_Case__c created.
        
        
        // Inactive User_Account__c, Update case
        //
        // No User_Account_Case__c created.
        
        
        // Active User_Account__c, Drop case
        //
        System.assert(uacForUserAcct.containsKey(userAcctDropActive.Id), 
            'Missing an User_Account_Case__c for a Drop Case');
        User_Account_Case__c userAccountCase = uacForUserAcct.get(userAcctDropActive.Id);
        
        System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE, userAccountCase.Type__c, 
            'Wrong Type__c for User_Account_Case__c with Active__c=true');
        System.assertEquals(NewHireutil.USER_ACCOUNT_CASE_STATUS_OPEN, userAccountCase.Status__c,
            'Wrong Status__c for a User_Account_Case__c with Active__c=true');
        System.assertEquals(caseDrop.Due_Date__c,userAccountCase.Date__c,
            '[User_Account_Case__c.Active__c=true]: User_Account_Case__c.Date__c does not match Case__c.Due_Date__c');

        
        // Inactive User_Account__c, Drop case
        //
        // No User_Account_Case__c created.
        
        
        // Active User_Account__c, Suspension case
        //
        System.assert(uacForUserAcct.containsKey(userAcctSuspendActive.Id), 
            'Missing an User_Account_Case__c related to a Suspension Case');
        userAccountCase = uacForUserAcct.get(userAcctSuspendActive.Id);
        
        System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_TYPE_DEACTIVATE, userAccountCase.Type__c, 
            'Wrong Type__c for User_Account_Case__c with Active__c=true');
        System.assertEquals(NewHireutil.USER_ACCOUNT_CASE_STATUS_OPEN, userAccountCase.Status__c,
            'Wrong Status__c for a User_Account_Case__c with Active__c=true');
        System.assertEquals(caseSuspend.Due_Date__c,userAccountCase.Date__c,
            '[User_Account_Case__c.Active__c=true]: User_Account_Case__c.Date__c does not match Case__c.Due_Date__c');
        System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_NOTES_SUSPENSION_ACTIVE,userAccountCase.Notes__c,
            'Wrong Notes__c value for User_Account_Case__c with Active__c == true');
            
        // Inactive User_Account__c, Suspension case
        //
        System.assert(uacForUserAcct.containsKey(userAcctSuspendInactive.Id), 
            'Missing an User_Account_Case__c related to a Suspension Case');
        userAccountCase = uacForUserAcct.get(userAcctSuspendInactive.Id);
        
        System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_TYPE_NONE, userAccountCase.Type__c==null?'':userAccountCase.Type__c,
            'Wrong Type__c value on a User_Account_Case__c with Active__c=false');
        System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_STATUS_NONE, userAccountCase.Status__c==null?'':userAccountCase.Status__c,
            'Wrong Status__c value on a User_Account_Case__c with Active__c=false');
        
        
        // Active User_Account__c, generic provisioning case
        //
        System.assert(uacForUserAcct.containsKey(userAcctGenericActive.Id), 
            'Missing an User_Account_Case__c related to a generic provisioning Case');
        userAccountCase = uacForUserAcct.get(userAcctGenericActive.Id);
        
        System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE, userAccountCase.Type__c, 
            'Wrong Type__c for User_Account_Case__c with Active__c=true');
        System.assertEquals(NewHireutil.USER_ACCOUNT_CASE_STATUS_OPEN, userAccountCase.Status__c,
            'Wrong Status__c for a User_Account_Case__c with Active__c=true');
        System.assertEquals(caseGeneric.Due_Date__c,userAccountCase.Date__c,
            '[User_Account_Case__c.Active__c=true]: User_Account_Case__c.Date__c does not match Case__c.Due_Date__c');
        System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_NOTES_PROVISIONING_ACTIVE,userAccountCase.Notes__c,
            'Wrong Notes__c value for User_Account_Case__c with Active__c == true');
            
        // Inactive User_Account__c, generic provisioning case
        //
        System.assert(uacForUserAcct.containsKey(userAcctGenericInactive.Id), 
            'Missing an User_Account_Case__c related to a generic provisioning Case');
        userAccountCase = uacForUserAcct.get(userAcctGenericInactive.Id);
        
        System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_TYPE_NONE, userAccountCase.Type__c==null?'':userAccountCase.Type__c,
            'Wrong Type__c value on a User_Account_Case__c with Active__c=false');
        System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_STATUS_NONE, userAccountCase.Status__c==null?'':userAccountCase.Status__c,
            'Wrong Status__c value on a User_Account_Case__c with Active__c=false');
                    
                    
        // Active User_Account__c, provisioning case of arbitrary type
        //
        System.assert(uacForUserAcct.containsKey(userAcctOtherActive.Id), 
            'Missing an User_Account_Case__c related to a Case of arbitrary type');
        userAccountCase = uacForUserAcct.get(userAcctOtherActive.Id);
                
        System.assertEquals('', userAccountCase.Type__c, 
            'Wrong Type__c for User_Account_Case__c related to a Case of arbitrary type');
        System.assertEquals('', userAccountCase.Status__c,
            'Wrong User_Account_Case__c.Status__c related to a Case of arbitrary type');
        System.assertEquals(null,userAccountCase.Date__c,
            'User_Account_Case__c.Date__c does not match Case__c.Due_Date__c related to a Case of arbitrary type');
        System.assertEquals('',userAccountCase.Notes__c,
            'Wrong User_Account_Case__c.Notes__c related to a Case of arbitrary type');
        
        // Inactive User_Account__c, provisioning case of arbitrary type
        //
        System.assert(uacForUserAcct.containsKey(userAcctOtherInactive.Id), 
            'Missing an User_Account_Case__c related to a Case of arbitrary type');
        userAccountCase = uacForUserAcct.get(userAcctOtherInactive.Id);
                
        System.assertEquals('', userAccountCase.Type__c, 
            'Wrong Type__c for User_Account_Case__c related to a Case of arbitrary type');
        System.assertEquals('', userAccountCase.Status__c,
            'Wrong User_Account_Case__c.Status__c related to a Case of arbitrary type');
        System.assertEquals(null,userAccountCase.Date__c,
            'User_Account_Case__c.Date__c does not match Case__c.Due_Date__c related to a Case of arbitrary type');
        System.assertEquals('',userAccountCase.Notes__c,
            'Wrong User_Account_Case__c.Notes__c related to a Case of arbitrary type');
        
    }
    
    
    /**
    *
    * UpdateCasesWithContactAndCaseInfo
    * - The correct fields are pulled from the Contact onto the Case,
    * based on the Case's recordType.
    */
    @isTest
    public static void testUpdateCasesWithContactAndCaseInfo()
    {
        Account defaultAccount = new Account(Name=NewHireUtil.DEFAULT_ACCOUNT_NAME);
        Account theAccount = new Account(Name=rndStr());
        insert new sObject[]{theAccount,defaultAccount};
        
        Contact bossContact1 = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact bossContact2 = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact bossContact3 = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact bossContact4 = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact bossContact5 = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact bossContact6 = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact bossContact7 = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact bossContact8 = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact bossContact9 = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        Contact bossContact10 = new Contact(LastName=rndStr(),AccountId=theAccount.Id);
        
        insert new sObject[]
            {
                bossContact1,
                bossContact2,
                bossContact3,
                bossContact4,
                bossContact5,
                bossContact6,
                bossContact7,
                bossContact8,
                bossContact9,
                bossContact10
            };
        
        Contact contactUpdate  = new Contact(
            AccountId                   = theAccount.Id,
            FirstName                   = rndStr(),
            LastName                    = rndStr(),
            Title                       = rndStr(),
            Personal_Email__c           = rndStr()+'@example.com1',
            Budget_Line_Item__c         = rndStr(),
            torDepartment__c            = rndStr(),
            Office_Location__c          = rndStr(),
            ReportsToId                 = bossContact1.Id,
            Billing_Code__c             = rndStr(),
            Full_Time_Part_Time__c      = rndStr(),
            HomePhone                   = '+1 234-567-8901',
            Signing_Limit__c            = 111.11,
            Salesforce_Business_Role__c = rndStr(),
            Division__c                 = rndStr(),
            Cell_Phone_Reimbursement__c = rndStr(),
            Desk_Assignment__c          = rndStr(),
            Employment_Status__c        = rndStr());
        Contact contactDrop    = new Contact(
            AccountId                   = theAccount.Id,
            FirstName                   = rndStr(),
            LastName                    = rndStr(),
            Title                       = rndStr(),
            Personal_Email__c           = rndStr()+'@example.com2',
            Budget_Line_Item__c         = rndStr(),
            torDepartment__c            = rndStr(),
            Office_Location__c          = rndStr(),
            ReportsToId                 = bossContact2.Id,
            Billing_Code__c             = rndStr(),
            Full_Time_Part_Time__c      = rndStr(),
            HomePhone                   = '+1 345-678-9012',
            Signing_Limit__c            = 222.22,
            Salesforce_Business_Role__c = rndStr(),
            Division__c                 = rndStr(),
            Cell_Phone_Reimbursement__c = rndStr(),
            Desk_Assignment__c          = rndStr(),
            Employment_Status__c        = rndStr());
        Contact contactSuspend = new Contact(
            AccountId                   = theAccount.Id,
            FirstName                   = rndStr(),
            LastName                    = rndStr(),
            Title                       = rndStr(),
            Personal_Email__c           = rndStr()+'@example.com3',
            Budget_Line_Item__c         = rndStr(),
            torDepartment__c            = rndStr(),
            Office_Location__c          = rndStr(),
            ReportsToId                 = bossContact3.Id,
            Billing_Code__c             = rndStr(),
            Full_Time_Part_Time__c      = rndStr(),
            HomePhone                   = '+1 456-789-0123',
            Signing_Limit__c            = 333.33,
            Salesforce_Business_Role__c = rndStr(),
            Division__c                 = rndStr(),
            Cell_Phone_Reimbursement__c = rndStr(),
            Desk_Assignment__c          = rndStr(),
            Employment_Status__c        = rndStr());
        Contact contactGeneric = new Contact(
            AccountId                   = theAccount.Id,
            FirstName                   = rndStr(),
            LastName                    = rndStr(),
            Title                       = rndStr(),
            Personal_Email__c           = rndStr()+'@example.com4',
            Budget_Line_Item__c         = rndStr(),
            torDepartment__c            = rndStr(),
            Office_Location__c          = rndStr(),
            ReportsToId                 = bossContact4.Id,
            Billing_Code__c             = rndStr(),
            Full_Time_Part_Time__c      = rndStr(),
            HomePhone                   = '+1 567-890-1234',
            Signing_Limit__c            = 444.44,
            Salesforce_Business_Role__c = rndStr(),
            Division__c                 = rndStr(),
            Cell_Phone_Reimbursement__c = rndStr(),
            Desk_Assignment__c          = rndStr(),
            Employment_Status__c        = rndStr());
        Contact contactOther   = new Contact(
            AccountId                   = theAccount.Id,
            FirstName                   = rndStr(),
            LastName                    = rndStr(),
            Title                       = rndStr(),
            Personal_Email__c           = rndStr()+'@example.com5',
            Budget_Line_Item__c         = rndStr(),
            torDepartment__c            = rndStr(),
            Office_Location__c          = rndStr(),
            ReportsToId                 = bossContact5.Id,
            Billing_Code__c             = rndStr(),
            Full_Time_Part_Time__c      = rndStr(),
            HomePhone                   = '+1 678-901-2345',
            Signing_Limit__c            = 555.55,
            Salesforce_Business_Role__c = rndStr(),
            Division__c                 = rndStr(),
            Cell_Phone_Reimbursement__c = rndStr(),
            Desk_Assignment__c          = rndStr(),
            Employment_Status__c        = rndStr());
        
        insert new sObject[]
        {
            contactUpdate,
            contactDrop,
            contactSuspend,
            contactGeneric,
            contactOther
        };
        
        Case caseUpdate   = new Case(
            RecordTypeId                  = NewHireUtil.RECORDTYPE_PROVISIONING_UPDATE,
            Due_Date__c                   = Date.today().addDays(1),
            prEmployee__c                 = contactUpdate.Id,           
            prFirst_Name__c               = rndStr(),
            prLastName__c                 = rndStr(),
            prPosition_Title__c           = rndStr(),
            prPersonal_Email__c           = rndStr()+'@example.com6',
            prBudget_Line_Item__c         = rndStr(),
            prDepartment__c               = rndStr(),
            prLocation__c                 = rndStr(),
            prReports_To__c               = bossContact6.Id,
            prPayroll_Department_Code__c  = rndStr(),
            prFull_Time_Part_Time__c      = rndStr(),
            prPersonal_Phone__c           = '+1 890-123-4567',
            prSigning_Limit__c            = 666.66,
            Salesforce_Business_Role__c   = rndStr(),
            prDivision__c                 = rndStr(),
            prCell_Phone_Reimbursement__c = rndStr(),
            prDesk_Assignment__c          = rndStr(),
            prEmployment_Status__c        = rndStr());
        Case caseDrop     = new Case(
            RecordTypeId                  = NewHireUtil.RECORDTYPE_PROVISIONING_DROP,
            Due_Date__c                   = Date.today().addDays(2),
            prEmployee__c                 = contactDrop.Id,             
            prFirst_Name__c               = rndStr(),
            prLastName__c                 = rndStr(),
            prPosition_Title__c           = rndStr(),
            prPersonal_Email__c           = rndStr()+'@example.com7',
            prBudget_Line_Item__c         = rndStr(),
            prDepartment__c               = rndStr(),
            prLocation__c                 = rndStr(),
            prReports_To__c               = bossContact7.Id,
            prPayroll_Department_Code__c  = rndStr(),
            prFull_Time_Part_Time__c      = rndStr(),
            prPersonal_Phone__c           = '+1 901-234-5678',
            prSigning_Limit__c            = 777.77,
            Salesforce_Business_Role__c   = rndStr(),
            prDivision__c                 = rndStr(),
            prCell_Phone_Reimbursement__c = rndStr(),
            prDesk_Assignment__c          = rndStr(),
            prEmployment_Status__c        = rndStr());
        Case caseSuspend  = new Case(
            RecordTypeId                  = NewHireUtil.RECORDTYPE_PROVISIONING_SUSPENSION,
            Due_Date__c                   = Date.today().addDays(3),
            prEmployee__c                 = contactSuspend.Id,          
            prFirst_Name__c               = rndStr(),
            prLastName__c                 = rndStr(),
            prPosition_Title__c           = rndStr(),
            prPersonal_Email__c           = rndStr()+'@example.com8',
            prBudget_Line_Item__c         = rndStr(),
            prDepartment__c               = rndStr(),
            prLocation__c                 = rndStr(),
            prReports_To__c               = bossContact8.Id,
            prPayroll_Department_Code__c  = rndStr(),
            prFull_Time_Part_Time__c      = rndStr(),
            prPersonal_Phone__c           = '+1 112-345-6789',
            prSigning_Limit__c            = 888.88,
            Salesforce_Business_Role__c   = rndStr(),
            prDivision__c                 = rndStr(),
            prCell_Phone_Reimbursement__c = rndStr(),
            prDesk_Assignment__c          = rndStr(),
            prEmployment_Status__c        =  rndStr());
        Case caseGeneric  = new Case(
            RecordTypeId                  = NewHireUtil.RECORDTYPE_PROVISIONING_CASE,
            Due_Date__c                   = Date.today().addDays(4),
            prEmployee__c                 = contactGeneric.Id,          
            prFirst_Name__c               = rndStr(),
            prLastName__c                 = rndStr(),
            prPosition_Title__c           = rndStr(),
            prPersonal_Email__c           = rndStr()+'@example.com9',
            prBudget_Line_Item__c         = rndStr(),
            prDepartment__c               = rndStr(),
            prLocation__c                 = rndStr(),
            prReports_To__c               = bossContact9.Id,
            prPayroll_Department_Code__c  = rndStr(),
            prFull_Time_Part_Time__c      = rndStr(),
            prPersonal_Phone__c           = '+1 212-345-6789',
            prSigning_Limit__c            = 999.99,
            Salesforce_Business_Role__c   = rndStr(),
            prDivision__c                 = rndStr(),
            prCell_Phone_Reimbursement__c = rndStr(),
            prDesk_Assignment__c          = rndStr(),
            prEmployment_Status__c        =  rndStr());
        Case caseOther    = new Case(
            RecordTypeId                  = NewHireUtil.RECORDTYPE_PROVISIONING_ADD,
            Due_Date__c                   = Date.today().addDays(5),
            prEmployee__c                 = contactOther.Id,            
            prFirst_Name__c               = rndStr(),
            prLastName__c                 = rndStr(),
            prPosition_Title__c           = rndStr(),
            prPersonal_Email__c           = rndStr()+'@example.com10',
            prBudget_Line_Item__c         = rndStr(),
            prDepartment__c               = rndStr(),
            prLocation__c                 = rndStr(),
            prReports_To__c               = bossContact10.Id,
            prPayroll_Department_Code__c  = rndStr(),
            prFull_Time_Part_Time__c      = rndStr(),
            prPersonal_Phone__c           = '+1 223-456-7890',
            prSigning_Limit__c            = 1111.11,
            Salesforce_Business_Role__c   = rndStr(),
            prDivision__c                 = rndStr(),
            prCell_Phone_Reimbursement__c = rndStr(),
            prDesk_Assignment__c          = rndStr(),
            prEmployment_Status__c        = rndStr());
        
        insert new sObject[]
        {
            caseUpdate,
            caseDrop,
            caseSuspend,
            caseGeneric,
            caseOther
        };
        
        Map<Id,Contact> contactForCase = new Map<Id,Contact>
        {
            caseUpdate.Id  => contactUpdate,
            caseDrop.Id    => contactDrop,
            caseSuspend.Id => contactSuspend,
            caseGeneric.Id => contactGeneric,
            caseOther.Id   => contactOther
        };
        
        Map<Id,Case> caseForContact = new Map<Id,Case>{
            contactUpdate.Id  => caseUpdate,
            contactDrop.Id    => caseDrop,
            contactSuspend.Id => caseSuspend,
            contactGeneric.Id => caseGeneric,
            contactOther.Id   => caseOther
        };
        
        Map<Id,Case> casesBefore = new Map<Id,Case>
        {
            caseUpdate.Id  => caseUpdate,
            caseDrop.Id    => caseDrop,
            caseSuspend.Id => caseSuspend,
            caseGeneric.Id => caseGeneric,
            caseOther.Id   => caseOther
        }.deepClone();
        
        // Call the function we are testing
        //
        List<Case> caseOutputs = NewHireUtil.updateCasesWithContactAndCaseInfo(caseForContact);
        
        Map<Id,Case> casesAfter = new Map<Id,Case>();
                
        // Make assertions common to all Contacts (regardless of type)
        //      
        for(Case theCase : caseOutputs)
        {
            casesAfter.put(theCase.Id,theCase);
            
            Contact theContact = contactForCase.get(theCase.Id);
            Case    caseBefore = caseForContact.get(theContact.Id);
            
            System.assertEquals(NewHireUtil.RECORDTYPE_PROVISIONING_CASE,theCase.RecordTypeId, 
                'Wrong value for Case.RecordTypeId');
            
            System.assertEquals(theContact.FirstName,theCase.prFirst_Name__c,
                'Case.prFirst_Name__c does not match Case.prEmployee__r.FirstName');
            
            System.assertEquals(theContact.LastName,theCase.prLastName__c,
                'Case.prLastName__c does not match Case.prEmployee__r.LastName');
                
            System.assertEquals(theContact.Title,theCase.prPosition_Title__c,
                'Case.prPosition_Title__c does not match Case.prEmployee__r.Title');
                
            System.assertEquals(theContact.Personal_Email__c,theCase.prPersonal_Email__c,
                'Case.prPersonal_Email__c does not match Case.prEmployee__r.Personal_Email__c');
                
            System.assertEquals(theContact.Budget_Line_Item__c,theCase.prBudget_Line_Item__c,
                'Case.prBudget_Line_Item__c does not match Case.prEmployee__r.Budget_Line_Item__c');
                
            System.assertEquals(theContact.torDepartment__c,theCase.prDepartment__c,
                'Case.prDepartment__c does not match Case.prEmployee__r.torDepartment__c');
                
            System.assertEquals(theContact.Office_Location__c,theCase.prLocation__c,
                'Case.prLocation__c does not match Case.prEmployee__r.Office_Location__c');
                
            System.assertEquals(theContact.ReportsToId,theCase.prReports_To__c,
                'Case.prReports_To__c does not match Case.prEmployee__r.ReportsToId');
                
            System.assertEquals(theContact.Billing_Code__c,theCase.prPayroll_Department_Code__c,
                'Case.prPayroll_Department_Code__c does not match Case.prEmployee__r.Billing_Code__c');
                
            System.assertEquals(theContact.Full_Time_Part_Time__c,theCase.prFull_Time_Part_Time__c,
                'Case.prFull_Time_Part_Time__c does not match Case.prEmployee__r.Full_Time_Part_Time__c');
                
            System.assertEquals(theContact.HomePhone,theCase.prPersonal_Phone__c,
                'Case.prPersonal_Phone__c does not match Case.prEmployee__r.HomePhone');
                
            System.assertEquals(theContact.Signing_Limit__c,theCase.prSigning_Limit__c,
                'Case.prSigning_Limit__c does not match Case.prEmployee__r.Signing_Limit__c');

            System.assertEquals(theContact.Salesforce_Business_Role__c,theCase.Salesforce_Business_Role__c,
                'Case.Salesforce_Business_Role__c does not match Case.Salesforce_Business_Role__c');
                                
            System.assertEquals(theContact.Division__c,theCase.prDivision__c,
                'Case.prDivision__c does not match Case.prEmployee__r.Division__c');
                
            System.assertEquals(theContact.Cell_Phone_Reimbursement__c,theCase.prCell_Phone_Reimbursement__c,
                'Case.prCell_Phone_Reimbursement__c does not match Case.prEmployee__r.Cell_Phone_Reimbursement__c');
                
            System.assertEquals(theContact.Desk_Assignment__c,theCase.prDesk_Assignment__c,
                'Case.prDesk_Assignment__c does not match Case.prEmployee__r.Desk_Assignment__c');
                
            //System.assertEquals(theContact.Employment_Status__c,theCase.prEmployment_Status__c,
            //  'Case.prEmployment_Status__c does not match Case.prEmployee__r.Employment_Status__c');
            
        }
        
        
        // Update our Case variables.
        //      
        caseUpdate  = casesAfter.get(caseUpdate.Id);
        caseDrop    = casesAfter.get(caseDrop.Id);
        caseSuspend = casesAfter.get(caseSuspend.Id);
        caseGeneric = casesAfter.get(caseGeneric.Id);
        caseOther   = casesAfter.get(caseOther.Id);
        
        // Make type-specific assertions
        
        
        // Update
        //
        System.assertEquals(contactUpdate.Employment_Status__c,caseUpdate.prEmployment_Status__c,
            '[Update]: Case.prEmployment_Status__c does not match Contact.Employment_Status__c');       
        System.assertEquals(            
            NewHireUtil.CASE_SUBJECT_UPDATE
            +contactUpdate.FirstName + ' ' 
            +contactUpdate.LastName + ' - '
            +String.valueOf(casesBefore.get(caseUpdate.Id).Due_Date__c),            
            caseUpdate.Subject,
            '[Update]: Wrong output for Case.Subject');
        
        // Drop
        //
        System.assertEquals(NewHireUtil.EMPLOYMENT_STATUS_INACTIVE,caseDrop.prEmployment_Status__c,
            '[Drop]: Case.prEmployment_Status__c does not match Contact.Employment_Status__c');     
        System.assertEquals(
            NewHireUtil.CASE_SUBJECT_DROP
            +contactDrop.FirstName + ' ' 
            +contactDrop.LastName + ' - '
            +String.valueOf(casesBefore.get(caseDrop.Id).Due_Date__c),          
            caseDrop.Subject,
            '[Drop]: Wrong output for Case.Subject');
        
        // Suspend
        //
        System.assertEquals(NewHireUtil.EMPLOYMENT_STATUS_TEMPORARILY_SUSPENDED,caseSuspend.prEmployment_Status__c,
            '[Suspend]: Case.prEmployment_Status__c does not match Contact.Employment_Status__c');      
        System.assertEquals(
            NewHireUtil.CASE_SUBJECT_SUSPENSION
            +contactSuspend.FirstName + ' ' 
            +contactSuspend.LastName + ' - '
            +String.valueOf(casesBefore.get(caseSuspend.Id).Due_Date__c),           
            caseSuspend.Subject,
            '[Suspend]: Wrong output for Case.Subject');
        
        // Generic provisioning
        //
        System.assertEquals(NewHireUtil.EMPLOYMENT_STATUS_ACTIVE,caseGeneric.prEmployment_Status__c,
            '[Provisioning]: Case.prEmployment_Status__c does not match Contact.Employment_Status__c');     
        System.assertEquals(
            NewHireUtil.CASE_SUBJECT_PROVISIONING
            +contactGeneric.FirstName + ' ' 
            +contactGeneric.LastName + ' - '
            +String.valueOf(casesBefore.get(caseGeneric.Id).Due_Date__c),           
            caseGeneric.Subject,
            '[Provisioning]: Wrong output for Case.Subject');
        
        // Arbitrary type
        //
        System.assertEquals(null,caseOther.prEmployment_Status__c,
            'Case.prEmployment_Status__c changed, even though the Case type was not a relevant type.');     
        System.assertEquals(null,caseOther.Subject,
            'Case.Subject changed, even though the Case type was not a relevant type.');
 
    }


    @isTest(SeeAllData=true)
    public static void testGetAccountIdForNewContact()
    {
        Case employeeCase        = new Case(Employee_Type__c = NewHireUtil.CASE_EMPLOYEE_TYPE_EMPLOYEE);
        Case contractorCase      = new Case(Employee_Type__c = NewHireUtil.CASE_EMPLOYEE_TYPE_CONTRACTOR);
        Case nullEmployeeType    = new Case(Employee_Type__c = null);
        Case unknownEmployeeType = new Case(Employee_Type__c = rndStr());


        try
        {
            Id employeeAccountId     = NewHireutil.getAccountIdForNewContact(employeeCase);
            Id contractorAccountId   = NewHireutil.getAccountIdForNewContact(contractorCase);
            Id nullAccoundId         = NewHireutil.getAccountIdForNewContact(nullEmployeeType);
            Id unknownEmployeeTypeId = NewHireUtil.getAccountIdForNewContact(unknownEmployeeType);

            System.assertEquals(
                NewHireutil.DEFAULT_ACCOUNT,
                employeeAccountId,
                'Wrong Account ID returned for a Case with Employee_Type__c='+NewHireUtil.CASE_EMPLOYEE_TYPE_EMPLOYEE
            );

            System.assertEquals(
                NewHireutil.CONTRACTOR_ACCOUNT,
                contractorAccountId,
                'Wrong Account ID returned for a Case with Employee_Type__c='+NewHireUtil.CASE_EMPLOYEE_TYPE_CONTRACTOR
            );

            System.assertEquals(
                NewHireutil.DEFAULT_ACCOUNT,
                nullAccoundId,
                'Wrong Account ID returned for a Case with a null Employee_Type__c.'
            );

            System.assertEquals(
                NewHireutil.DEFAULT_ACCOUNT,
                unknownEmployeeTypeId,
                'Wrong Account ID returned for a Case with an unfamiliar Employee_Type__c.'
            );

        } catch(NewHireutil.IdNotFoundException e)
        {
            System.assert(false, 
                'Got an IdNotFoundException while running this test. Make sure that all org data is in place for this feature. Error: '+e.getMessage());
        }


    }
    
}