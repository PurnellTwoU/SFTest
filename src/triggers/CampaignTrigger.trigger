/**
 * @description Trigger on Campaign object.      
 */

trigger CampaignTrigger on Campaign (after delete, after undelete,after insert,  
        after update, before delete, before insert, before update) {
  TriggerFactory.createHandler(Campaign.sObjectType); 
}