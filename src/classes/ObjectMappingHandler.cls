/**
 * @description SF-1471 This class maps fields from a child record to a field on the parent record based on
 *              the mappings specified in the Child_Parent_Object_Mappings__c custom setting.  Currently called by
 *              UserAccountTrigger and AssetTrigger (or their trigger handlers).  Main method is processObjMappings
 */
//TODO
// * Move UserAccountTrigger into trigger factory structure

public with sharing class ObjectMappingHandler {

    private static final List<Child_Parent_Object_Mappings__c> OBJ_MAPPINGS = new List<Child_Parent_Object_Mappings__c>(
            [select Id, From_Object__c, From_Field__c, To_Object__c, To_Field__c, Criteria_Object__c, Criteria_Field_Id__c
            from Child_Parent_Object_Mappings__c]);

    /**
     * @description Main method
     * @param String which object?  Asset__c or User_Account__c
     * @param List of sobjects (Trigger.new) of object type listed in "which"
     * @param Old version of sobjects (Trigger.oldMap) of object type listed in "which"
     */
    public static void processObjMappings(String which, List<SObject> objList, Map<Id, SObject> oldMap) {
        List<Child_Parent_Object_Mappings__c> thisObjMappings = filteredObjMapping(which);
        Map<String, String> toMapStrings = new Map<String, String>();

        Map<String, Map<String, String>> objectToMapStrings = new Map<String, Map<String, String>>();
        List<SObject> objsToUpdate = new List<SObject>();

        if(thisObjMappings.size() > 0) {
            for(SObject so : objList) {
                for(Child_Parent_Object_Mappings__c mp : thisObjMappings) {
                    
                    // Can't do relationships by reference (e.g. __r), so we have to compare by lookup ids
                    // Substring to allow matching on the 15 character id
                    if(so.get(mp.Criteria_Object__c) != null 
                        && (String.valueOf(so.get(mp.Criteria_Object__c)).substring(0, 15) == mp.Criteria_Field_Id__c.substring(0, 15))) {
                        

                        //Query all ToObject where Id in contactId
                        // loop through them and update based on map
                        String cleanedToObjString = !String.valueOf(mp.To_Object__c).contains('__c') ? String.valueOf(mp.To_Object__c) + '__c'
                                : String.valueOf(mp.To_Object__c);
     
                        toMapStrings = !objectToMapStrings.containsKey(mp.To_Object__c) ? new Map<String, String>() 
                                : objectToMapStrings.get(mp.To_Object__c);

                        if(so.get(cleanedToObjString) != null) {
                            String toObjRecId = String.valueOf(so.get(cleanedToObjString));
                            String fromFieldVal = String.valueOf(so.get(mp.From_Field__c));

                            // Get values from oldMap; only continue if values are changing
                            String oldFromFieldVal = oldMap != null && oldMap.get(String.valueOf(so.get('Id'))).get(mp.From_Field__c) != null 
                                    ? String.valueOf(oldMap.get(String.valueOf(so.get('Id'))).get(mp.From_Field__c)) : '';
                            String oldToObjRecId = oldMap != null && oldMap.get(String.valueOf(so.get('Id'))).get(cleanedToObjString) != null 
                                    ? String.valueOf(oldMap.get(String.valueOf(so.get('Id'))).get(cleanedToObjString)) : '';

                            if(fromFieldVal != oldFromFieldVal || toObjRecId != oldToObjRecId) {
                                //Build a map of contactId, ToObject :: ToField :: FromFieldValue where :: is the delimitor     
                                toMapStrings.put(toObjRecId, mp.To_Object__c + '::' + mp.To_Field__c + '::' + fromFieldVal);
                                // To make this as bulk friendly as possible, we need a map of maps where the key is the sObject name
                                objectToMapStrings.put(mp.To_Object__c, toMapStrings);
                            }
                        }
                    }
                }
            }
            // To make the process more bulk friendly, group the queries that we need to run by SObject
            // by building a string of all of the fields to query for that object
            for(String s : objectToMapStrings.keySet()) {
                String thisObjSoqlString = 'select Id';
                Set<Id> toObjIds = new Set<Id>();
                for(String m : objectToMapStrings.get(s).keySet()) {
                    thisObjSoqlString += ', ' + objectToMapStrings.get(s).get(m).split('::')[1];
                    
                    if(!toObjIds.contains(m)) {
                        toObjIds.add(m);
                    }
                }
                
                thisObjSoqlString += ' from ' + s + ' where Id in :toObjIds';
                System.debug('**print thisObjSoqlString: ' + thisObjSoqlString);

                List<SObject> toObjs = new List<SObject>();
                try {
                    toObjs = Database.query(thisObjSoqlString);
                } catch (Exception e) {
                    System.debug('Exception: ' + e.getMessage());
                    //TODO Log exception
                }
                if(toObjs.size() > 0) {
                    for(SObject so : toObjs) {
                        String toField = objectToMapStrings.get(s).get(String.valueOf(so.get('Id'))).split('::')[1];
                        String toValue = objectToMapStrings.get(s).get(String.valueOf(so.get('Id'))).split('::')[2];
                        System.debug('**print toField: ' + toField + '; ' + toValue);
                        so.put(toField, toValue);
                    }
                    objsToUpdate.addAll(toObjs);
                }
            }

            if(objsToUpdate.size() > 0) {
                try {
                    update objsToUpdate;
                } catch (Exception e) {
                    System.debug('Exception: ' + e.getMessage());
                    //TODO Log exceptions
                }
            }
        }
    }

    /**
     * @description Filters custom settings to just show the ones relating to the object in context.
     * @param String SObject API name
     */
    private static List<Child_Parent_Object_Mappings__c> filteredObjMapping(String fromObj) {
        List<Child_Parent_Object_Mappings__c> filteredList = new List<Child_Parent_Object_Mappings__c>();
        for(Child_Parent_Object_Mappings__c mp : OBJ_MAPPINGS) {
            if(mp.From_Object__c == fromObj) {
                filteredList.add(mp);
            }
        }
        return filteredList;
    }
}