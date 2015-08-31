/**
 * @description Trigger Handler for the Case SObject. This class implements the ITrigger
 *              interface to help ensure the trigger code is bulkified and all in one place.
 * Associated Unit Test Classes:
 *          TestPopulateX2tor_Program
 *          TestCaseTrigger
 *          TestOutboundEmailOnDelete
 */
public without sharing class CaseHandler implements ITrigger {
    
    private Map<String, CaseTeamTemplate> caseTeamMap = new Map<String, CaseTeamTemplate>();
    
    private List<CaseTeamTemplateRecord> caseTeamsToInsert = new List<CaseTeamTemplateRecord>();
    
    // Constructor
    public CaseHandler() {
    }

    // Called from bulkBeforeInsert and bulkBeforeUpdate to precache case team map
    private void queryCaseTeam() {
        // Query CaseTeamTemplate to get names with ids
        if(caseTeamMap.isEmpty()) {
            for(CaseTeamTemplate caseTeam: [select Id, Name from CaseTeamTemplate]) {
                caseTeamMap.put(caseTeam.Name.trim().toUpperCase(), caseTeam);
            }  
        } 
    }
    
    /******************* BEGIN BEFORE TRIGGER EVENT METHODS *************/
    
    /**@description This method is called for a full list of all of the BEFORE DELETE triggers.
     *              Iterate through the list here or farm the full list of triggers to another class.
     * @param List of old sObjects (Trigger.old)
     * @param Map of old sObjects (Trigger.oldMap)
     */
    public void bulkbeforeDelete(List<SObject> oldList, Map<Id, SObject> oldMap) {
        
    }
    
    /**@description This method is called for a full list of all of the BEFORE INSERT triggers.
     *              Iterate through the list here or farm the full list of triggers to another class.
     * @param List of new sObjects (Trigger.new)
     */
    public void bulkBeforeInsert(List<SObject> newList) {
        for(Sobject so : newList) {
            Case newCase = (Case) so;
            if(newCase.origin != null) {
                // Incorporating logic from PopulateX2tor_Program trigger into handler
                if( newCase.origin == 'Email MAT' || newCase.origin == 'Case MAT' ){
                    newCase.X2tor_Program__c = 'MAT';
                } else if( newCase.origin == 'Email MSW' || newCase.origin == 'Case MSW' ){
                    newCase.X2tor_Program__c = 'MSW';
                } else if( newCase.origin == 'Email MBA' || newCase.origin == 'Case MBA' ){
                    newCase.X2tor_Program__c = 'MBA';
                } else if( newCase.origin == 'Email MSN' || newCase.origin == 'Case MSN' ){
                    newCase.X2tor_Program__c = 'MSN';
                } else if( newCase.origin == 'Email MPA' || newCase.origin == 'Case MPA' ){
                    newCase.X2tor_Program__c = 'MPA';
                } else if( newCase.origin == 'Email LLM' || newCase.origin == 'Case LLM' ){
                    newCase.X2tor_Program__c = 'LLM';
                } else if( newCase.origin == 'Email Hub' || newCase.origin == 'Case Hub' ){
                    newCase.X2tor_Program__c = 'Hub';
                } else if( newCase.origin == 'Email crm@' ){
                    newCase.X2tor_Program__c = 'MAT;MSW;MBA;MSN;MPA;LLM';
                }
            }
        }
    }
    /**@description This method is called for a full list of all of the BEFORE UPDATE triggers.
     *              Iterate through the list here or farm the full list of triggers to another class.
     * @param Map of new sObjects (Trigger.newMap)
     * @param List of new sObjects (Trigger.new)
     * @param Map of old sObjects (Trigger.oldMap) (if needed, oldList can be recreated with oldMap.values())
     */
    public void bulkBeforeUpdate(Map<Id, SObject> newMap, List<SObject> newList, Map<Id, SObject> oldMap) {
        
    }
    /******************* END BEFORE TRIGGER EVENT METHODS *************/
    
    
    /******************* BEGIN AFTER TRIGGER EVENT METHODS *************/
    
    /**
     * @description This method is called once for the full list of records during an AFTER DELETE
     *              trigger.
     * @param List of old sObjects (Trigger.old)
     * @param Map of old sObjects (Trigger.oldMap)
     */
    public void bulkAfterDelete(List<SObject> oldList, Map<Id, SObject> oldMap) {

        List<SObject> sObjectsToEmail = new List<SObject>();
        // if record type is Help Desk Case
        for(SObject so : oldList) {
            Case oldCase = (Case) so;
            if(oldCase.RecordTypeId == RecordTypeUtil.findByName('Case.Help_Desk').Id) {
                sObjectsToEmail.add(so);                
            }
        }

        if(sObjectsToEmail.size() > 0) {
            OutboundEmailOnDelete.buildEmailMain(sObjectsToEmail);
        }
        
    }
    
    /**
     * @description This method is called once for the full list of records inserted during an AFTER INSERT
     *              trigger. Always put field validation in the 'After' methods in case another trigger
     *              has modified any values. The record is 'read only' by this point.
     * @param List of new sObjects (Trigger.new)
     */
    public void bulkAfterInsert(List<SObject> newList) {
        queryCaseTeam();

        for(SObject so : newList) {
            Case newCase = (Case) so;
            List<String> caseTeamNames = new List<String>();
            // Only do this if Case_Assignment is not null
            if(newCase.Case_Team_Assignment__c != null) {
                // split by comma and put in list
                caseTeamNames = newCase.Case_Team_Assignment__c.split(',');
                
                // Now loop through them and add to case team member list
                for(String teamName : caseTeamNames) {
                    if(caseTeamMap.containsKey(teamName.trim().toUpperCase())) {
                        caseTeamsToInsert.add(new CaseTeamTemplateRecord(ParentId = newCase.Id, 
                            TeamTemplateId=caseTeamMap.get(teamName.trim().toUpperCase()).Id));
                    }
                }
            }
        }           
    }
    
    /**
     * @description This method is called once for the full list of records during an AFTER UPDATE
     *              trigger. Always put field validation in the 'After' methods in case another trigger
     *              has modified any values. The record is 'read only' by this point.
     * @param Map of new sObjects (Trigger.newMap)
     * @param List of new sObjects (Trigger.new)
     * @param Map of old sObjects (Trigger.oldMap) (if needed, oldList can be recreated with oldMap.values())
     */
    public void bulkAfterUpdate(Map<Id, SObject> newMap, List<SObject> newList, Map<Id, SObject> oldMap) {
        queryCaseTeam();

        for(SObject so : newList) {
            Case newCase = (Case) so;
            Case oldCase = (Case) oldMap.get(so.Id);
            List<String> caseTeamNames = new List<String>();
            // Only do this if Case_Assignment is not null and is changing
            if(newCase.Case_Team_Assignment__c != null 
               && newCase.Case_Team_Assignment__c != oldCase.Case_Team_Assignment__c) {
                // split by comma and put in list
                caseTeamNames = newCase.Case_Team_Assignment__c.split(',');
                
                // Now loop through them and add to case team member list
                for(String teamName : caseTeamNames) {
                    if(caseTeamMap.containsKey(teamName.trim().toUpperCase())) {
                        caseTeamsToInsert.add(new CaseTeamTemplateRecord(ParentId = newCase.Id, 
                            TeamTemplateId=caseTeamMap.get(teamName.trim().toUpperCase()).Id));
                    }
                }
            }
        }
    }

    /**
     * @description This method is called once for the full list of records during an AFTER UNDELETE
     *              trigger.
     * @param List of old sObjects (Trigger.new)
     */
    public void bulkAfterUndelete(List<SObject> newList) {
        
    }
    
    /******************* END AFTER TRIGGER EVENT METHODS *************/
    
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this 
     * method to accomplish any final operations such as creation or updates of other records.
     * e.g. Accomplish tasks for lists created in after update and after insert methods without
     *      having to copy/paste the code.
     */
    public void andFinally() {
        
        //MAY WANT TO QUERY EXISTING RECORDS AND JUST INSERT?
        if(caseTeamsToInsert.size() > 0) {
            Database.SaveResult[] dbResults = Database.insert(caseTeamsToInsert, false);
            for(Integer i = 0 ; i < dbResults.size(); i++) {
                if(!dbResults[i].isSuccess()) {
                    // Loop through errors
                    for(Database.Error err : dbResults[i].getErrors()) {
                        if(err.getStatusCode() == StatusCode.DUPLICATE_VALUE) {
                            continue;
                        } else {
                            // Add error to case?
                            System.debug('Failed to add case team ' + err.getMessage());
                        }
                    }
                }
                
            }
        }
    }
}