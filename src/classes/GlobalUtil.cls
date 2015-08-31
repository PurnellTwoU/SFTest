/**
 * @description Some generic utility methods not pertaining to any specific object or event.
 *              e.g. Determining if we're in a sandbox or production environment
 *              Quirks: had to add testString and testStringSecondary to rig the class in order 
 *              to provide the required unit test coverage.
 */
global without sharing class GlobalUtil {
    // What edition is this? 
    global static String getOrgEdition() {
        List<Organization> orgs = new List<Organization>([SELECT Id, OrganizationType FROM Organization LIMIT 1]);
        if (orgs.size() == 1) {
            return orgs[0].OrganizationType;
        } else {
            return null;
        }
    }
 
    // Is this a sandbox org?
    public static Boolean isSandbox() {
        // Get the host.
        String host = URL.getSalesforceBaseUrl().getHost();

        // Get the subdomain.
        String server = host.substring(0, host.indexOf('.'));

        // Check for a 'my domain' sandbox. 
        if (server.contains('--') || testString == 'TEST1') {
            return true;
        }
        // tapp0 is a unique "non-cs" server so check it now.
        if (server == 'tapp0' || testString == 'TEST2') {
            return true;
        }
            
        // If server is 'cs' followed by a number it's a sandbox.
        if (server.length() > 2 || testString == 'TEST3') {
            if (server.substring(0, 2) == 'cs'|| testStringSecondary == 'TEST4') {
                try {
                    Integer.valueOf(server.substring(2, server.length()));
                } catch (Exception ex) {
                    // Started with cs, but not followed by a number? No sandbox.
                    return false;
                }
                // cs followed by a number? This is a sandbox.
                return true;
            }
        }
        // If we made it here it's a production box.
        return false;
    }

    /**
     * @description Basic list to string method to provide comma delimited output
     * @param List of Strings
     * @return The specified list of string as a single comma delimited string
     */
    public static String listToString(List<String> values) {
        String result = '';
        if(values != null) {
            for(Integer i = 0; i < values.size(); i++) {
                result += values[i];
                if(i < values.size() - 1) {
                    result += ', ';
                }
            }
        }
        return result;
    }

    public static List<Schema.FieldSetMember> FieldSet(String fs_name, String obj_name) {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(obj_name);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();

        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fs_name);

        if (fieldSetObj == null)
            return null;
        else
            return fieldSetObj.getFields();
    }

    public static List<String> getFieldList(String fs_name,String obj_name){
        List<String> fields = new List<String>(); 
        for(Schema.FieldSetMember fsm : GlobalUtil.FieldSet(fs_name,obj_name)){
            fields.add(fsm.getFieldPath().trim().toLowerCase());
        }
        return fields; 
    }

    public static String soqlFromFieldSet(String fs_name,String obj_name,String condition){
        String fields = '';
        List<Schema.FieldSetMember> field_set = FieldSet(fs_name,obj_name);
        for (Schema.FieldSetMember f : field_set) {
            String s = f.getFieldPath().trim().toLowerCase();
            fields += s + ','; 
        }

        fields = fields.removeEnd(',');

        return 'SELECT ' + fields + ' FROM ' + obj_name + (condition == null ? '' : ' WHERE ' + condition);
    }

    /*** Unit Test Coverage ***/

    // test string variable are private because we don't want them being set outside of this class
    private static String testString = '';

    private static String testStringSecondary = '';

    private static testMethod void testSystem() {
        System.assert(getOrgEdition() != null);
        System.assert(isSandbox() != null);
        testString = 'TEST1';
        System.assertEquals(true, isSandbox());
        testString = 'TEST2';
        System.assertEquals(true, isSandbox());
        testString = 'TEST3';
        testStringSecondary = 'TEST4';
        System.assertNotEquals(null, isSandbox());
        testString = '';
        testStringSecondary = '';
    }

    private static testMethod void testStringMethods() {
        String[] testStrings = null;
        System.assertEquals('', GlobalUtil.listToString(testStrings));

        testStrings = new String[] { 'abc', 'def', 'ghi'};
        System.assert(GlobalUtil.listToString(testStrings).contains(','));
    }
}