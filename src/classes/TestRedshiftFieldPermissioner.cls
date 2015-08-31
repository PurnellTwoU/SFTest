@isTest
public class TestRedshiftFieldPermissioner
{
    public static ApexClass TESTED_CLASS 
    {
        get
        {
            if(null == TESTED_CLASS)
            {
                 TESTED_CLASS = [
                    select 
                        Id, Name 
                    from ApexClass 
                    where Name = 'RedshiftFieldPermissioner'
                    and NamespacePrefix = null];
            }
            return TESTED_CLASS;
        }
    }
    
    /**
    * Salesforce presents two difficulties with permissionsets:
    * 1. All of the production data is visible to this class
    * 2. We cannot modify org Metadata (e.g. add new fields)
    *
    * To work around this, we used the RedshiftFieldPermissioner.DatabaseAdapter 
    * interface to wrap all access to the Database or Schema info.
    *
    * Here, we create a mock implementation of that interface, for testing 
    * purposes.
    * 
    * Instead of pushing and pulling changes to/from the database, this class 
    * feeds our RedshiftFieldPermissioner fake data and records its attempts to 
    * change the database without actually making those changes.
    *
    * This allows us to test for correctness without the target class touching 
    * or seeing any production data.
    *
    * Note: Take care that the records generated here contain all necessary 
    * data.
    *
    * Simulated State:
    * This class fakes four Object names:
    * A - Is readable
    * B - Is readable
    * C - Is readable
    * D - Is not readable
    *
    * Field names on these objects follow the following conventions:
    * "readable"   => there exists a FieldPermissions record with PermissionsRead = true; leave alone
    * "unreadable" => there exists a FieldPermissions record with PermissionsRead = false; update to true
    * "missing"    => there exists no FieldPermissions record for this field.; Create a new record.
    *
    */
    public class MockDatabaseAdapter implements RedshiftFieldPermissioner.DatabaseAdapter
    {
        public Map<String, FieldPermissions> fieldsUpdated  = new Map<String, FieldPermissions>();
        public Map<String, FieldPermissions> fieldsInserted = new Map<String, FieldPermissions>();
        
        /**
        *
        */
        public Iterable<sObject> getStartingDataset()
        {
            return new List<FieldPermissions>{
                new FieldPermissions(
                    Field           = 'A.readable', 
                    PermissionsRead = true, 
                    sObjectType     = 'A'
                ),
                new FieldPermissions(
                    Field           = 'A.nonreadable', 
                    PermissionsRead = false, 
                    sObjectType     = 'A'
                ),
                new FieldPermissions(
                    Field           = 'B.readable1', 
                    PermissionsRead = true, 
                    sObjectType     = 'B'
                ),
                new FieldPermissions(
                    Field           = 'B.readable2', 
                    PermissionsRead = true, 
                    sObjectType     = 'B'
                ),
                new FieldPermissions(
                    Field           = 'C.nonreadable1', 
                    PermissionsRead = false, 
                    sObjectType     = 'C'
                ),
                new FieldPermissions(
                    Field           = 'C.nonreadable2', 
                    PermissionsRead = false, 
                    sObjectType     = 'C'
                ),
                new FieldPermissions(
                    Field           = 'D.nonreadable', 
                    PermissionsRead = false, 
                    sObjectType     = 'D'
                )
            };
        }
        
        public List<ObjectPermissions> getReadableObjectPermissions(Set<String> objTypesToAdd)
        {
            return new List<ObjectPermissions>
            {
                new ObjectPermissions(
                    sObjectType     = 'A',
                    PermissionsRead = true
                ),
                new ObjectPermissions(
                    sObjectType     = 'B',
                    PermissionsRead = true
                ),
                new ObjectPermissions(
                    sObjectType     = 'C',
                    PermissionsRead = true
                )
                // D is missing because it does not have "Read" permissions.
            };
        }
        
        public List<String> getPermissionableFields(String objType)
        {
            return (new Map<String, List<String>>{
                'A' => new List<String>
                {
                    'A.readable',
                    'A.nonreadable',
                    'A.missing'
                },
                'B' => new List<String>
                {
                    'B.readable1',
                    'B.readable2',
                    'B.missing'
                },
                'C' => new List<String>
                {
                    'C.nonreadable1',
                    'C.nonreadable2',
                    'C.missing'
                },
                'D' => new List<String>
                {
                    'D.nonreadable',
                    'D.missing'
                }
            }).get(objType);
        }
        
        public void updatePermissions(List<FieldPermissions> fieldRecords)
        {
            for(FieldPermissions fieldRecord : fieldRecords)
            {
                this.fieldsUpdated.put(fieldRecord.Field, fieldRecord);
            }
        }
        
        public void insertPermissions(List<FieldPermissions> fieldrecords)
        {
            for(FieldPermissions fieldRecord : fieldRecords)
            {
                this.fieldsInserted.put(fieldRecord.Field, fieldRecord);
            }
        }
    }
    
    /**
    * Use our MockDatabaseAdapter and the simulateBatch function to make sure 
    * that our class is attempting the correct changes, regardless of the 
    * target org's data.
    */
    @isTest
    public static void testBatchOnMockState()
    {
        RedshiftFieldPermissioner rfp = new RedshiftFieldPermissioner();
        rfp.dbAdapter = new MockDatabaseAdapter();
        simulateBatchRun(rfp);
        
        MockDatabaseAdapter mockData = (MockDatabaseAdapter)rfp.dbAdapter;
        
        Map<String, FieldPermissions> updatedRecords  = mockData.fieldsUpdated;
        
        System.assertEquals(
            new Set<String>{
                'A.nonreadable',
                'C.nonreadable1',
                'C.nonreadable2'
            },
            updatedRecords.keySet(),
            'Did not update the expected set of records.'
        );
        
        for(FieldPermissions fieldRecord : updatedRecords.values())
        {
            System.assertEquals(
                true,
                fieldRecord.PermissionsRead,
                'Bad FieldPermissions.PermissionsRead value on an updated record.'
            );
        }
        
        Map<String, FieldPermissions> insertedRecords  = mockData.fieldsInserted;
        System.assertEquals(
            new Set<String>{
                'A.missing',
                'B.missing',
                'C.missing'
            },
            insertedRecords.keySet(),
            'Did not insert the expected set of records.'
        );
        
        for(FieldPermissions fieldRecord : insertedRecords.values())
        {
            System.assertEquals(
                true, fieldRecord.PermissionsRead,
                'Bad value for PermissionsRead on a new FieldPermissions record.'
            );
            System.assertEquals(
                RedshiftFieldPermissioner.PERMISSION_SET.Id, fieldRecord.ParentId,
                'Bad value for PermissionsRead on a new FieldPermissions record.'
            );
            System.assert(
                null != fieldRecord.Field,
                'Null value for Field on a new FieldPermissions record.'
            );
            System.assertEquals(
                2,
                fieldRecord.Field.split('\\.',2).size(),
                'Bad value for FieldPermissions.Field.split(\'\\\\.\',2) on a new Record'
            );
            System.assertEquals(
                fieldRecord.sObjectType,
                fieldRecord.Field.split('\\.',2)[0],
                'On a new record, Field prefix and sObjectType do not specify the same sObjectType.'
            );
        }
    }
    
    /**
    * Simulate the steps taken in a batch run.
    */
    public static void simulateBatchRun(RedshiftFieldPermissioner permissioner)
    {
        // Step 1: Call the start method.
        Iterable<sObject> startOutput = permissioner.start(null);
        
        // Compile a list for our execute method.
        List<FieldPermissions> executeInput = new List<FieldPermissions>();
        Iterator<sObject> execInputIter = startOutput.iterator();
        while(execInputIter.hasNext())
        {
            executeInput.add((FieldPermissions)execInputIter.next());
        }
        
        // Step 2: Pass our records in as a single batch.
        permissioner.execute(null, executeInput);
        
        // Step 3:
        permissioner.finish(null);
    }
    
    /**
    * Make sure that the target environment actually has a PermissionSet with 
    * the expected name.
    */
    @isTest
    public static void testSetup()
    {
        PermissionSet parentSet = RedshiftFieldPermissioner.PERMISSION_SET;

        System.assert(
            null != RedshiftFieldPermissioner.PERMISSION_SET,
            'RedshiftFieldPermissioner.PERMISSION_SET returned null. Expecting one with Name= "'+RedshiftFieldPermissioner.PERMISSION_SET_API_NAME+'"'
        );
        
        System.assertEquals(
            RedshiftFieldPermissioner.PERMISSION_SET_API_NAME,
            parentSet.Name,
            'RedshiftFieldPermissioner.PERMISSION_SET returned a PermissionSet with the wrong Name.'
        );
    }
    
    /**
    * Do a scheduled run on this class.
    * This gets us code coverage, but we cannot test for 
    * correctness since production data is visible and we are limited to only
    * one batch.
    */
    @isTest
    public static void testSchedule()
    {
        String cronExpression = DateTime.now().addHours(1).format('s m H d M ? yyyy');

        Test.startTest();
        Id jobId = System.schedule(
            'TestRedshiftFieldPermissioner',
            cronExpression,
            new RedshiftFieldPermissioner()
        );
        Test.stopTest();

        // Query for the last Batch job.
        AsyncApexJob lastBatchJobAfter = getLastBatchJob();
        
        System.assert(
            lastBatchJobAfter != null,
            'The batch job was not run.'
        );
    }
    
    
    public static AsyncApexJob getLastBatchJob()
    {
        // Query for the last Batch job. We will repeat this query after the 
        // test and compare IDs to detect if a new Batch Job was not created.
        AsyncApexJob[] lastBatchJob = [
            select
                Id,
                Status,
                NumberOfErrors,
                ExtendedStatus
            from AsyncApexJob
            where ApexClassID = :TESTED_CLASS.Id
            order by CompletedDate desc 
            limit 1
        ];
        
        if(lastBatchJob.size() > 0)
        {
            return lastBatchJob[0];
        }
        else
        {
            return null;
        }
    }

}