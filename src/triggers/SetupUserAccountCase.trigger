/**
* Perform the following changes on a User_Account_Case__c:
*
* - Upon creation or change to the User_Account_Case__c.Service__c field, 
*   assign Owner to the Queue whose name exactly matches the value of 
*   User_Account_Case__c.Service__c.Provisioning_Queue__c
*
* - Upon creation or change to the User_Account_Case__c.Service__c field, 
*   assign to User_Account_Case__c.Case__c the CaseTeamTemplate ("Pre-defined Case Team") 
*   team whose name exactly matches the value of User_Account_Case__c.Service__r.Pre_Defined_Case_Team__c
*   (if the CaseTeamTemplate is not already Assigned).
*
* Note the following edge case behaviors:
*
* - If Asset_Case__c.Asset_Classification__c specifies a valid Case Team but Asset_Case__c.Case__c 
*   is null, the operation fails with an error message. 
*
* - Queues not enabled for use with User_Account_Case__c records
*   will be ignored.
*
* - If Service__c.Provisioning_Queue__c or Service__c.Pre_Defined_Case_Team__c 
*   is null, the corresponding field has no effect. 
*
* - If Service__c.Provisioning_Queue__c or Service__c.Pre_Defined_Case_Team__c 
*   specify a Queue/Case Team that could not be found, the insert is failed and an 
*   error message is attached to the Service__c field.
*
* - If multiple usable queues/Case Teams exist with the same name, the record most recently changed 
*   (according to LastModifiedDate) will be used.
*
* - While this trigger handles cases where the User_Account_Case__c.Service__c value is 
*   re-assigned, it does not automatically run when the Service__c.Provisioning_Queue__c 
*   value is changed.
*
* - This trigger would overflow its Query limit if:
*   S + Qn*Q > Lq
*   where 
*   S = Number of Service__c records queried (max 1 per User_Account_Case__c, or 200)
*   Qn = Number of unique Queue names in this trigger (max = S)
*   Q = Average number of  User_Account_Case__c-enabled queues per unique queue name
*       (technically unbounded, but will only exceed Qn in improper setup cases)
*   Lq = The max number of rows that can be queried in this trigger.
*
*/
trigger SetupUserAccountCase on User_Account_Case__c (before insert, before update)
{		
	List<User_Account_Case__c> ofInterest = null;
	Set<Id> serviceIds = new Set<Id>();
	
	// For insert triggers ...
	if(Trigger.isInsert)
	{
		// ... we care about all records.
		ofInterest = Trigger.new;
		
		// For each record of interest ...		
		for(User_Account_Case__c obj : ofInterest)
		{
			// ... save the Service__c value.
			if(obj.Service__c != null)
			{
				serviceIds.add(obj.Service__c);
			}						
		}
	} 
	// For update triggers ...
	else if(Trigger.isUpdate)		
	{	
		// ... we only care about certain records, where ...
		ofInterest = new List<User_Account_Case__c>();
		for(User_Account_Case__c obj : Trigger.new)
		{
			// ... the value of Service__c has changed.
			if(Trigger.oldMap.get(obj.Id).Service__c != obj.Service__c)
			{				
				ofInterest.add(obj);
				
				// For each record of interest, save the Service__c value.
				if(obj.Service__c != null)
				{
					serviceIds.add(obj.Service__c);
				} 
			}
		}		
	}
	
	// Pull relevant Service__c records.
	// Map Service__c.Id to Queue name and Service__c.Id. 
	// Map Service__c.Id to to CaseTeamTemplate name.
	Map<Id,String> queueNameForServiceId = new Map<Id,String>();
	Map<Id,String> caseTeamNameForServiceId = new Map<Id,String>();
	Set<Id> servicesWithNoQueue = new Set<Id>();
	Set<Id> servicesWithNoCaseTeam = new Set<Id>();
	
	for(Service__c obj : [
		select 
			Id, 
			Provisioning_Queue__c,
			Pre_Defined_Case_Team__c
		from Service__c
		where Id in :serviceIds
	])
	{
		if(obj.Provisioning_Queue__c == null)
		{
			servicesWithNoQueue.add(obj.Id);
		}
		else
		{
			queueNameForServiceId.put(obj.Id, obj.Provisioning_Queue__c);			
		}
		
		if(obj.Pre_Defined_Case_Team__c == null)
		{
			servicesWithNoCaseTeam.add(obj.Id);	
		}
		else
		{
			caseTeamNameForServiceId.put(obj.Id,obj.Pre_Defined_Case_Team__c);
		}
	}  
	
	// Pull relevant Queue info and map Queue 
	// name to Queue ID
	Map<String,Id> queueIdForQueueName = new Map<String,Id>();
	for(QueueSObject q : [
		select Queue.Id,Queue.DeveloperName
		from QueueSObject
		where 
			Queue.DeveloperName in :queueNameForServiceId.values()
			and SObjectType = 'User_Account_Case__c'
		// Note: If multiple Queues exist with the same name, 
		// the most recently changed Queue will be used.
		order by Queue.DeveloperName asc nulls first, Queue.LastModifiedDate asc nulls first
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
			Name in :caseTeamNameForServiceId.values()
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
	
	// Map Case Team Assignment indices to their Usr_Account_Case__c records.
	// We will use this to attach errors later. 
	Map<Integer,User_Account_Case__c> uacForCtaIndex = new Map<Integer,User_Account_Case__c>();
	 
	for(User_Account_Case__c obj : ofInterest)
	{
		if(obj.Service__c == null) { continue; }
		
		Id queueId = queueIdForQueueName.get(queueNameForServiceId.get(obj.Service__c));
		Id caseTeamId = caseTeamIdForCaseTeamName.get(caseTeamNameForServiceId.get(obj.Service__c));
		
		// Note: If a Queue ID was not specified, no change is made.
		if(!servicesWithNoQueue.contains(obj.Service__c))
		{
			if(queueId == null)
			{
				obj.Service__c.addError('Service specifies a bad Provisioning Queue. Could not find a Queue named "'+
					queueNameForServiceId.get(obj.Service__c)
				+'" enabled for use with User_Account_Case__c records.');			
			}
			{
				obj.OwnerId = queueId;
			}
		}
		
		// Note: If a CaseTeamTemplate was not specified, no change is made.
		if(!servicesWithNoCaseTeam.contains(obj.Service__c))
		{
			if(caseTeamId == null)
			{
				obj.Service__c.addError('Service specifies a bad Pre Defined Case Team. Could not find a Case Team named "'+
					caseTeamNameForServiceId.get(obj.Service__c)
				+'"');								
			}
			else if(obj.Case__c == null)
			{
				obj.Service__c.addError('Cannot assign Case Team: The Service specifies a Pre Defined Case Team ("'+
					caseTeamNameForServiceId.get(obj.Service__c)
				+'") but the User Account Event does not specify a Case.');
			}
			else
			{	
				caseTeamAssignments.add(new CaseTeamTemplateRecord(
					ParentId=obj.Case__c,
					TeamTemplateId=caseTeamId
				));	
				
				uacForCtaIndex.put(caseTeamAssignments.size()-1,obj);
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
					uacForCtaIndex.get(ctaIndex).Service__c.addError(
						'Could not assign the Service\'s Case Team: '+err.getStatusCode()+': '+err.getMessage());													
				}	
			}
			++ctaIndex;
		}		
	}
	
}