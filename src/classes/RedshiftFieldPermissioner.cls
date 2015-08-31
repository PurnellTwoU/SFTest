public class RedshiftFieldPermissioner implements Database.Batchable<sObject>, Database.Stateful, Schedulable
{
    /////////////////////////////////////////////////////////////
    // Static Constants                                        //
    /////////////////////////////////////////////////////////////

    public static final String  PERMISSION_SET_API_NAME        = 'API_Redshift';
    public static final Integer FIELD_PERMISSIONS_BATCH_LIMIT  = Limits.getLimitFieldsDescribes() - 10;  
    
    // The permission set corresponding to Redshift.
    public static PermissionSet PERMISSION_SET 
    {
        get
        {
            if(null == PERMISSION_SET)
            {
                PermissionSet[] permSetList = [
                    select 
                        Id, Name 
                    from PermissionSet
                    where Name = :PERMISSION_SET_API_NAME
                ];
                if(permSetList.size() > 0)
                {
                    PERMISSION_SET = permSetList[0];
                }
            }
            return PERMISSION_SET;
        }
    }  
    
    /////////////////////////////////////////////////////////////
    // Instance Variables                                      //
    /////////////////////////////////////////////////////////////
    
    // A list of field names which we will eventually pass off to 
    // a RedshiftFieldPermissioner_Step2.
    // Each field name is of the form "SomeObject.SomeField"
    //
    public Set<String> fieldsOfInterest  = new Set<String>();
    public Set<String> objectsOfInterest = new Set<String>();
    public DatabaseAdapter dbAdapter = new StandardDatabaseAdapter();
    
    /////////////////////////////////////////////////////////////
    // Schedulable Interface                                   //
    /////////////////////////////////////////////////////////////

    public void execute(SchedulableContext context)
    {
        Database.executeBatch(this, FIELD_PERMISSIONS_BATCH_LIMIT);
    }
    
    /////////////////////////////////////////////////////////////
    // Batchable Interface                                     //
    /////////////////////////////////////////////////////////////
    
    /**
    * Query an exhaustive list of existing FieldPermissions objects
    */
    public Iterable<sObject> start(Database.BatchableContext BC) 
    {
        return this.dbAdapter.getStartingDataset();
    }
    
    /**
    * Our fieldsOfInterest set tells us which fields need to be checked.
    *
    * For each FieldPermissions object on our list of fieldsOfInterest, we 
    * make sure that FieldPermissions.PermissionsRead == true.
    *
    * The fieldsOfInterest Set grows when we encounter new sObjectTypes and 
    * shrinks whenever we check on a FieldPermissions object. 
    *
    * In the finish method (see below), the residual fieldsOfInterest will 
    * represent fields for which new FieldPermissions records will need to be 
    * created.
    *
    */
    public void execute(Database.BatchableContext bc, List<FieldPermissions> permissions)
    {
        this.collectItemsOfInterest(permissions);
        
        // Permissions we will be changing.
        //
        List<FieldPermissions> toUpdate = new List<FieldPermissions>();
        
        // For each permission ...
        for(FieldPermissions fieldRecord : permissions)
        {
            // ... if this is a field of interest ...
            if(this.fieldsOfInterest.contains(fieldRecord.Field))
            {
                // Make sure that the FieldPermissions for this field offers 
                // Read access.
                if(!fieldRecord.PermissionsRead)
                {
                    fieldRecord.PermissionsRead = true;
                    toUpdate.add(fieldRecord);
                }
                
                // We have finished checking on this field. It is no longer a 
                // field of interest, so remove it from fieldsOfInterest. 
                // (The objectsOfInterest Set will keep us from adding it back 
                // later).
                //
                this.fieldsOfInterest.remove(fieldRecord.Field);
            }
        }
        
        // Update the FieldPermissions records which are newly marked with 
        // Read permissions.
        //
        // We will insert new FieldPermissions records in the finish() method, 
        // after we have exhaustively searched the existing records.
        //
        this.dbAdapter.updatePermissions(toUpdate);
    }

    public void finish(Database.BatchableContext bc)
    {
        List<FieldPermissions> newPermissions = new List<FieldPermissions>();
        
        // For each field name still in our fields of interest
        //
        for(String fieldName : this.fieldsOfInterest)
        {
            String[] fieldNameParts = fieldName.split('\\.', 2);
            FieldPermissions fieldRecord = 
                new FieldPermissions(
                    parentId        = PERMISSION_SET.Id,
                    Field           = fieldName,
                    sObjectType     = fieldNameParts[0],
                    PermissionsRead = true,
                    PermissionsEdit = false
                );
            
            newPermissions.add(fieldRecord);
        }
        
        this.dbAdapter.insertPermissions(newPermissions);
    }
    
    
    /////////////////////////////////////////////////////////////
    // Utility Methods                                         //
    /////////////////////////////////////////////////////////////
    
    /**
    * Find new objects of interest and new fields of interest from the given 
    * list of records.
    *
    * New Objects of interest:
    * - Have ObjectPermissions.PermissionsRead == true
    * - Are not already in this.objectsOfInterest
    *
    * New fields of interest are all fields (not just the ones in 
    * fieldPermissions) which:
    * - Belong to a new object of interest (see above)
    * - Are permissionable
    * 
    */
    public void collectItemsOfInterest(List<FieldPermissions> fieldPermissions)
    {
        // Collect a set of unique SObject types from our FieldPermissions records
        Set<String> objTypesToAdd = new Set<String>();
        for(FieldPermissions fieldRecord : fieldPermissions)
        {
            String objType = fieldRecord.sObjectType;
            if(!this.objectsOfInterest.contains(objType))
            {
                objTypesToAdd.add(objType);
                this.objectsOfInterest.add(objType);
            }
        }
        
        // Find out which ObjectPermissions indicate object-level 
        // Read permissions.
        //
        ObjectPermissions[] objectPermissions = this.dbAdapter.getReadableObjectPermissions(objTypesToAdd);

        // For each ObjectPermissions ...
        for(ObjectPermissions objRecord : objectPermissions)
        {
            String objType = objRecord.sObjectType;
            
            // Add all of its permissionable fields to our fieldsOfInterest.
            this.fieldsOfInterest.addAll(
                this.dbAdapter.getPermissionableFields(objType)
            );
        }
    }
    
    
    /**
    * Put all of our Database access methods inside of an adapter so we can 
    * re-implement them in our unit tests to simulate metadata changes and 
    * record DB actions.
    */
    public interface DatabaseAdapter
    {
        Iterable<sObject>       getStartingDataset();
        List<ObjectPermissions> getReadableObjectPermissions(Set<String> objTypesToAdd);
        List<String>            getPermissionableFields(String objType);
        void                    updatePermissions(List<FieldPermissions> fieldRecords);
        void                    insertPermissions(List<FieldPermissions> fieldrecords);
    }
    
    /**
    * The standard Database Adapter, which interacts normally with the database.
    */
    public class StandardDatabaseAdapter implements DatabaseAdapter
    {   
        public Iterable<sObject> getStartingDataset()
        {
            Id permissionSetId = PERMISSION_SET.Id;
            String query = 
                'select '+
                    'Id, Field, PermissionsRead, sObjectType '+
                'from FieldPermissions '+
                'where ParentId = :permissionSetId ';
            
            if(Test.isRunningTest())
            {
                query += 'limit ' + FIELD_PERMISSIONS_BATCH_LIMIT;
            }

            return Database.getQueryLocator(query);
        }
        
        public List<ObjectPermissions> getReadableObjectPermissions(Set<String> objTypesToAdd)
        {
            // Find out which ObjectPermissions indicate object-level 
            // Read permissions.
            //
            return [
                select 
                    Id, PermissionsRead, sObjectType
                from ObjectPermissions
                where PermissionsRead = true
                and ParentId = :PERMISSION_SET.Id
                and sObjectType in :objTypesToAdd
            ];
        }
        
        public List<String> getPermissionableFields(String objType)
        {
            // Get our global catalog of sObjectTypes.
            Map<String, Schema.sObjectType> globalDescribe = Schema.getGlobalDescribe();
            List<Schema.SObjectField> fieldList = globalDescribe.get(objType).getDescribe().fields.getMap().values();
            
            List<String> permissionableFields = new List<String>();

            // ... for each field name ...
            for(Schema.SObjectField field : fieldList)
            {
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

                // ... if the field is permissionable ...
                if(fieldDescribe.isPermissionable())
                {
                    // ... add the field to our global list of fields.
                    permissionableFields.add(objType+'.'+fieldDescribe.getName());
                }
            }
            
            return permissionableFields;
        }
        
        public void updatePermissions(List<FieldPermissions> fieldRecords)
        {
            update fieldRecords;
        }

        public void insertPermissions(List<FieldPermissions> fieldrecords)
        {
            Database.SaveResult[] resultList = Database.insert(fieldRecords, false);
            Integer index = 0;
            for(Database.SaveResult result : resultList)
            {
                if(!result.isSuccess())
                {
                    System.debug('Could not grant "Read" permissions on: '+fieldRecords[index].Field);
                }
                ++index;
            }
        }
        
    }
    
}