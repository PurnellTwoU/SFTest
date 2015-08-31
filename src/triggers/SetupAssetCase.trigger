/**
* Perform the following changes on a Asset_Case__c:
*
* - Upon creation or change to the Asset_Case__c.Asset_Classification__c field, 
*   assign Owner to the Queue whose name matches the value of 
*   Asset_Case__c.Asset_Classification__c.Provisioning_Queue__c
*
* - Upon creation or change to the Asset_Case__c.Asset_Classification__c field, 
*   assign to Asset_Case__c.Case__c the CaseTeamTemplate ("Pre-defined Case Team") 
*   team whose name exactly matches the value of Asset_Case__c.Asset_Classification__c.Pre_Defined_Case_Team__c
*   (if the CaseTeamTemplate is not already Assigned).
*
* Note the following edge case behaviors:
*
* - If Asset_Case__c.Asset_Classification__c specifies a valid Case Team but Asset_Case__c.Case__c 
*   is null, the operation fails with an error message. 
*
* - Queues not enabled for use with Asset_Case__c records
*   will be ignored.
*
* - If Asset_Classification__c.Provisioning_Queue__c or Asset_Classification__c.Pre_Defined_Case_Team__c 
*   is null, the corresponding field has no effect. 
*
* - If Asset_Classification__c.Provisioning_Queue__c or Asset_Classification__c.Pre_Defined_Case_Team__c 
*   specify a Queue/Case Team that could not be found, the insert is failed and an 
*   error message is attached to the Asset_Classification__c field.
*
* - If multiple usable queues/Case Teams exist with the same name, the record most recently changed 
*   (according to LastModifiedDate) will be used.
*
* - While this trigger handles cases where the Asset_Case__c.Asset_Classification__c value is 
*   re-assigned, it does not automatically run when the Asset_Classification__c.Provisioning_Queue__c 
*   value is changed.
*
* - This trigger would overflow its Query limit if:
*   S + Qn*Q > Lq
*   where 
*   S = Number of Asset_Classification__c records queried (max 1 per Asset_Case__c, or 200)
*   Qn = Number of unique Queue names in this trigger (max = S)
*   Q = Average number of  Asset_Case__c-enabled queues per unique queue name
*       (technically unbounded, but will only exceed Qn in improper setup cases)
*
*/
trigger SetupAssetCase on Asset_Case__c (before insert, before update)
{		
	List<Asset_Case__c> ofInterest = null;
	Set<Id> assetClassificationIds = new Set<Id>();
	
	// For insert triggers ...
	if(Trigger.isInsert)
	{
		// We care about all records.
		ofInterest = Trigger.new;
		
		// For each record of interest ...		
		for(Asset_Case__c obj : ofInterest)
		{
			// ... save the Asset_Classification__c value.
			if(obj.Asset_Classification__c != null)
			{
				assetClassificationIds.add(obj.Asset_Classification__c);
			}						
		}
	} 
	else if(Trigger.isUpdate)
	// For update triggers ...
	{	
		// ... we only care about certain records, where ...
		ofInterest = new List<Asset_Case__c>();
		for(Asset_Case__c obj : Trigger.new)
		{
			// ... the value of Asset_Classification__c has changed.
			if(Trigger.oldMap.get(obj.Id).Asset_Classification__c != obj.Asset_Classification__c)
			{				
				ofInterest.add(obj);
				
				// For each record of interest, save the Asset_Classification__c value.
				if(obj.Asset_Classification__c != null)
				{
					assetClassificationIds.add(obj.Asset_Classification__c);
				} 
			}
		}		
	}
	
	// Pull relevant Asset_Classification__c records.
	// Map Asset_Classification__c.Id to Queue name and Asset_Classification__c.Id. 
	// Map Asset_Classification__c.Id to to CaseTeamTemplate name.
	Map<Id,String> queueNameForAssetClassificationId = new Map<Id,String>();
	Map<Id,String> caseTeamNameForAssetClassificationId = new Map<Id,String>();
	Set<Id> assetClassificationsWithNoQueue = new Set<Id>();
	Set<Id> assetClassificationsWithNoCaseTeam = new Set<Id>();
	
	for(Asset_Classification__c obj : [
		select 
			Id, 
			Provisioning_Queue__c,
			Pre_Defined_Case_Team__c
		from Asset_Classification__c
		where Id in :assetClassificationIds
	])
	{
		if(obj.Provisioning_Queue__c == null)
		{
			assetClassificationsWithNoQueue.add(obj.Id);
		}
		else
		{
			queueNameForAssetClassificationId.put(obj.Id, obj.Provisioning_Queue__c);			
		}
		if(obj.Pre_Defined_Case_Team__c == null)
		{
			assetClassificationsWithNoCaseTeam.add(obj.Id);			
		}
		{
			caseTeamNameForAssetClassificationId.put(obj.Id,obj.Pre_Defined_Case_Team__c);
		}
	}  
	
	// Pull relevant Queue info and map Queue 
	// name to Queue ID
	Map<String,Id> queueIdForQueueName = new Map<String,Id>();
	for(QueueSObject q : [
		select Queue.Id,Queue.DeveloperName
		from QueueSObject
		where 
			Queue.DeveloperName in :queueNameForAssetClassificationId.values()
			and SObjectType = 'Asset_Case__c'
		// Note: If multiple Queues exist with the same name, 
		// the most recently changed Queue will be used.
		order by Queue.DeveloperName asc, Queue.LastModifiedDate asc
	])
	{
		queueIdForQueueName.put(q.Queue.DeveloperName, q.Queue.Id);						
	}
	
	// Pull relevant CaseTeamTemplate info and map CaseTeamTemplate  
	// name to CaseTeamTemplate Id.
	Map<String,Id> caseTeamIdForCaseTeamName = new Map<String,Id>();
	for(CaseTeamTemplate ct : [
		select 
			Id,Name
		from CaseTeamTemplate
		where 
			Name in :caseTeamNameForAssetClassificationId.values()
		// Note: If multiple CaseTeamTemplates exist with the same name, 
		// the most recently changed CaseTeamTemplate will be used.
		order by Name asc nulls first, LastModifiedDate asc nulls first
	])
	{
		caseTeamIdForCaseTeamName.put(ct.Name, ct.Id);				
	}
	
	// Finally, assign Queue Ids to our records of interest
	// and attach Case Teams to our Cases.
	List<CaseTeamTemplateRecord> caseTeamAssignments = new List<CaseTeamTemplateRecord>();
	
	// Map Case Team Assignment indices to their Asset_Case__c records.
	// We will use this to attach errors later. 
	Map<Integer,Asset_Case__c> acForCtaIndex = new Map<Integer,Asset_Case__c>();
	
	for(Asset_Case__c obj : ofInterest)
	{
		if(obj.Asset_Classification__c == null) { continue; }
		
		Id queueId = queueIdForQueueName.get(queueNameForAssetClassificationId.get(obj.Asset_Classification__c));
		Id caseTeamId = caseTeamIdForCaseTeamName.get(caseTeamNameForAssetClassificationId.get(obj.Asset_Classification__c));
			
		// Note: If a Queue ID was not specified, no change is made.
		if(!assetClassificationsWithNoQueue.contains(obj.Asset_Classification__c))
		{
			if(queueId == null)
			{
				obj.Asset_Classification__c.addError('Asset Classification specifies a bad Provisioning Queue. Could not find a Queue named "'+
					queueNameForAssetClassificationId.get(obj.Asset_Classification__c)
				+'"');			
			}
			{
				obj.OwnerId = queueId;
			}
		}
		
		// Note: If a CaseTeamTemplate was not specified, no change is made.
		if(!assetClassificationsWithNoCaseTeam.contains(obj.Asset_Classification__c))
		{
			if(caseTeamId == null)
			{
				obj.Asset_Classification__c.addError('Asset Classification specifies a bad Pre Defined Case Team. Could not find a Case Team named "'+
					caseTeamNameForAssetClassificationId.get(obj.Asset_Classification__c)
				+'"');								
			}
			else if(obj.Case__c == null)
			{
				obj.Asset_Classification__c.addError('Cannot assign Case Team: The Asset Classification specifies a Pre Defined Case Team ("'+
					caseTeamNameForAssetClassificationId.get(obj.Asset_Classification__c)
				+'") but the Asset Event does not specify a Case.');
			}
			else
			{
				caseTeamAssignments.add(new CaseTeamTemplateRecord(
					ParentId=obj.Case__c,
					TeamTemplateId=caseTeamId
				));	
				acForCtaIndex.put(caseTeamAssignments.size()-1,obj);
			}		
		}
	}
	
	// Assign our Case Teams
	if(caseTeamAssignments.size() > 0)
	{	
		// We use a method call here so that we can selectively ignore
		// erroneous save results resulting from duplicate records.
		//
		Database.SaveResult[] results = Database.insert(caseTeamAssignments,false);
		
		// If the insert fails because the Case Team has 
		// already been assigned to a given Case, ignore 
		// the failue. Doing this is much cheaper and simpler 
		// than pre-emptively checking for duplicates. 
		//
		// Other errors, however, should cause a failure
		// so we must check for them and manually attach any that 
		// we find.
		//		
		Integer ctaIndex = 0;
		for(Database.SaveResult result : results)
		{			
			if(result.isSuccess()) { continue; }
			
			// Check each error.
			for(Database.Error err : result.getErrors())
			{
				// If the error is a Duplicate Value error, ignore it.
				if(err.getStatusCode()==StatusCode.DUPLICATE_VALUE)
				{
					continue;					
				} 
				// Otherwise, fail the insertion for that record.
				else
				{
					acForCtaIndex.get(ctaIndex).Asset_Classification__c.addError(
						'Could not assign the Asset Classification\'s Case Team: '+err.getStatusCode()+': '+err.getMessage());													
				}	
			}
			++ctaIndex;
		}		
	}
	
}