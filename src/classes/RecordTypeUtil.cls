/**
 * @description Utility class for caching record types.  Generic enough to be deployed
*               across all orgs.  Only use this class to reference methods and variables
*               which are not specific to any org.
 * @author mthomas
 */ 
 
public class RecordTypeUtil {

    private static final Map<ID, RecordType> BY_ID_MAP = new Map<ID, RecordType>();
    private static final Map<String, RecordType> BY_NAME_MAP = new Map<String, RecordType>();
    private static final Map<String, Schema.SObjectField> FIELD_DESCRIBE_MAP;
    
    /**
     * @description Static initializer to build the RecordType query
     */
    static {
        Schema.DescribeSObjectResult describe = RecordType.getSObjectType().getDescribe();
        FIELD_DESCRIBE_MAP = describe.fields.getMap();
        String soql = 'select ';
        List<String> fieldNames = new List<String>(FIELD_DESCRIBE_MAP.keySet());
        for(Integer i = 0; i < fieldNames.size(); i++) {
            String fieldName = fieldNames[i];
            soql += fieldName;
            if (i < fieldNames.size() - 1) {
                soql += ', ';
            }
        }
        soql += ' from RecordType';
        for(RecordType rt : Database.query(soql)) {
            BY_ID_MAP.put(rt.Id, rt);
            BY_NAME_MAP.put((rt.SobjectType + '.' + rt.DeveloperName).toUpperCase(), rt);
        }
    }
    
    /**
     * @description Finds a RecordType that matches the ID provided.
     * @param ID The ID of the RecordType to locate
     * @return The matching RecordType, or null if not found
     */
    public static RecordType findById(ID recordTypeId) {
        return BY_ID_MAP.get(recordTypeId);
    }
    
    /**
     * @description Finds a RecordType that matches the developer name.
     * @param String The name of the RecordType to locate
     * @return The matching RecordType, or null if not found
     */
    public static RecordType findByName(String developerName) {
        return BY_NAME_MAP.get(developerName.toUpperCase());
    }
}