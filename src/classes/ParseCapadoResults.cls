/** 
  * @Outline 	07/27/2015 - ParseCapadoUnitTest was created as a solution to Ticket SF-13694
  * 			Capado runs unit tests on all the orgs on a specified timer. Currently the results are saved
  *				and sent as a JSON file which proves to be more work than its worth to manually sort and make sense
  *				of what failed and what passed for each org. This class retrieves all of the unit test results, parses
  *				it into a custom object, formats it then displays it for the user. It will eventally be used as a template
  *				For the emails.
  *
  * @Author 	Purnell Anthony panthony@2u.com
  * @Required 	
  * @Trigger
  * @ChangeLog	(Please append all changes here)
*/


public with sharing class ParseCapadoResults 
{
	public void RetrieveTestResults()
	{
		//Date dtToday = Date.newInstance(2015,10,8);
		Date dtToday = Date.today();

		list<string> AllOrgs = new list<string>();
		list<string> OrgAttatchments = new list<string>();
		list<unitTestMap> objUnitTestMaps = new list<unitTestMap>();
		string sJsonBlob;

		for(string OrgName : AllOrgs)
		{
			OrgAttatchments = ListOfAttachments(OrgName, dtToday);
			for(string sAttachment: OrgAttatchments)
			{
				sJsonBlob = AttachmentBlob(sAttachment);
				objUnitTestMaps.add(ParseBlobToObject(sJsonBlob, OrgName));
			}
		}
	}
	
	//The following functions retrieve lists (Put better description)
	private list<string> ListOfOrgs()
	{
		//string sSOQLstatement;
		list<string> sOrgs = new list<string>();
		list<AggregateResult> copadoOrgs = [SELECT 		copado__Org__r.name, 
														Count_DISTINCT(name) 
											FROM 		copado__Apex_Test_Result__c 
										   	GROUP BY 	copado__Org__r.name];

		if(copadoOrgs.size() > 0)	
		{						   
			For(AggregateResult org: copadoOrgs)
			{
				sOrgs.add((string)org.get('name'));
			}
		}

	    //list<string> sOrgs = new list<string>(sSOQLstatement);

		return  sOrgs;
	}

	private list<string> ListOfAttachments(string sOrgName, date dtDesireDate)
	{
		//string sSOQLstatement;
		
		list<string> sAttachments = new list<string>();
		DateTime dtStartDate = DateTime.newInstance(dtDesireDate.year(), 
													dtDesireDate.month(), 
													dtDesireDate.day(), 0, 0, 0);

		DateTime dtEndDate = dtStartDate.addDays(1);

		list<copado__Apex_Test_Result__c> objAttachments =	   [SELECT 	copado__Org__r.name,
																		(SELECT Name, id FROM Attachments)
																FROM 	copado__Apex_Test_Result__c 
																WHERE 	copado__Org__r.name =: sOrgName	
																AND   	createddate > : dtStartDate
																AND 	createddate < : dtEndDate
																LIMIT	1];

	    //list<string> sAttachments = new list<string>(sSOQLstatement);
	    for(copado__Apex_Test_Result__c objAtt: objAttachments)
	    {
	    	sAttachments.add((string)objAtt.get('ID'));
	    }

		return  sAttachments;
	}

	private string AttachmentBlob(string sAttachmentID)
	{
		string sSOQLstatement;
		string sBlob;

		list<attachment> sAttachmentBlobs =  [SELECT 	id, 
														name, 
														body 
											  FROM 		attachment 
											  WHERE 	id = : sAttachmentID];

	    //list<string> sAttachmentBlobs = new list<string>(sSOQLstatement);

	    For(Attachment att: sAttachmentBlobs)
		{
		    sBlob = att.body.tostring();
		}

		return  sBlob;
	}

	private unitTestMap ParseBlobToObject(string sBlob, string sOrgName)
	{
		map<String, Object> JsonMap = (Map<String, Object>)JSON.deserializeUntyped(sBlob);
		map<String, Object> results = (Map<String, Object>)JsonMap.Get('testClassResults');

		UnitTestMap ParsedUnitTestMap = new UnitTestMap();
		list<string> sClsNames = new list<string>();
		list<list<string>> sMethNames = new list<list<string>>();
		list<list<string>> sResultMsgs = new list<list<string>>();
		list<list<string>> sSuccess = new list<list<string>>();

		integer intClasses = 0;

		for(string objClass: results.keyset())
		{
			map<string,object> subCls = (map<string,object>)results.get(objClass);
		    
		    list<object> objMethods = (list<object>)subCls.get('methods');
			sClsNames.add((string)objClass);

		    for(integer i = 0; i < objMethods.size(); i++)
		    {
		        map<string,object> m = (map<string,object>)objMethods[i];
		        
		        sMethNames[intClasses].add((string)m.get('name'));
		        sResultMsgs[intClasses].add((string)m.get('message'));
		        sSuccess[intClasses].add((string)m.get('success'));

		        //System.Debug('NAME: ' + m.get('name'));
		        //System.Debug('MESSAGE: ' + m.get('message'));
		        //System.Debug('SUCCESS: ' + m.get('success'));
		    }
		    intClasses++;
		}

		//ParsedUnitTestMap(sOrgName, sClsNames, sMethNames, sResultMsgs, sSuccess);

		ParsedUnitTestMap.OrgName = sOrgName;
		ParsedUnitTestMap.ClassNames = sClsNames;
		ParsedUnitTestMap.MethodNames = sMethNames;
		ParsedUnitTestMap.ResultMessages = sResultMsgs;
		ParsedUnitTestMap.Success = sSuccess;

		return ParsedUnitTestMap;
	}

	//Currently NOT in use
	private void FormattedResults()
	{
		//Formatting goes here
		//Select what information is displayed and what information is not displayed.

	}

	//Currently NOT in use
	private void OPTIONS()
	{
		//I believe I need some options for what is going to be reported.
	    //Most likely regarding how it should be formatted. 

	}

	private class UnitTestMap
	{
		private String OrgName {get;set;}
		private list<string> ClassNames {get;set;}
		private list<list<string>> MethodNames {get;set;}
		private list<list<string>> ResultMessages {get;set;}
		private list<list<string>> Success {get;set;}

		UnitTestMap(String sOrgsName, list<string> sClassNames, list<list<string>> sMethodNames, list<list<string>> sResultMessages, list<list<string>> sSuccessful)
		{
			OrgName = sOrgsName;
			ClassNames = sClassNames;
			MethodNames = sMethodNames;
			ResultMessages = sResultMessages;
			Success = sSuccessful;
		}
	    
	    UnitTestMap()
		{

		}
	}

}