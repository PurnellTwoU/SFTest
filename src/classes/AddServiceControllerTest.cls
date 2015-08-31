/**
 * Unit tests for the AddServiceController class:
 * 
 * Assertions as follows:
 *
 * Constructor
 * - The new instance has a Case instance with the same ID as the one used
 *   to construct the ApexPages.StandardController we are using.
 * - The Case instance variable has all of the necessary data available.
 *
 * CanAddService
 * - The getCanAddService returns false if the Case is a Drop case, true otherwise.
 *
 * SetServices
 * - The serviceList member variable is populated with a list of services.
 * - Services with Available_on_provisioning_case_c__c == false are excluded.
 * - Each Service__c.Salesforce_Profiles__r relationship contains a list of 
 *   the Service_Profile__c records tied to that Service__c, excluding the ones where
 *   Available_on_Provisioning_Case__c is false
 * - Each Service__c.Salesforce_Roles__r relationship contains a list of 
 *   the Service_Role__c records tied to that Service__c, excluding the ones where
 *   Available_on_Provisioning_Case__c is false.
 *
 * GetServices
 * - The wrapperList member variable is populated with a list of ServiceWrapper 
 *   instances
 * - A ServiceWrapper exists for every item in the serviceList member.
 * - Each ServiceWrapper contains a list of SelectOption with one entry for 
 *   each record in the Service__c.Salesforce_Roles__r relationship.
 * - Each ServiceWrapper contains a list of SelectOption with one entry for 
 *   each record in the Service__c.Salesforce_Profiles__r relationship.
 * - Each Select Option has a Record Id as its value and Record Name as its Label
 * - Each ServiceWrapper contains correct values for the corresponding service's 
 *   Name, Id, and Field_Set__c variables.
 * - After calling getServices() the getServicesSize() function returns the 
 *   size of the getServices() output.
 *
 *
 * GetServicesNoAccessPackages
 * Like GetServices, but with each Service__c.Offer_Access_Packages__c = false.
 * - The wrapperList member variable is populated with a list of ServiceWrapper 
 *   instances
 * - A ServiceWrapper exists for every item in the serviceList member.
 * - Each ServiceWrapper contains a null SelectOption list.
 * - Each ServiceWrapper contains correct values for the corresponding service's 
 *   Name, Id, and Field_Set__c variables.
 * - After calling getServices() the getServicesSize() function returns the 
 *   size of the getServices() output.
 *
 * AddServices
 * - A new User_Account_Case__c exists for each selected Service__c
 * - The chosen Profile__c, Role__c, and Date__c values are properly inserted.
 * - Unparsable dates and bad Id values cause the controller to display an 
 *   error message and set the error flag to true.
 * - The correct RecordType is assigned based on the Service__c fieldSet variable.
 * - All other fields on the inserted record have the proper values.
 *
 *
 * Back
 * - The returned PageReference points to the UserAccountCase page.
 * - The returned PageReference has an Id parameter with the ID of the Case.
 * - The returned PageReference has getRedirect()==true.
 * 
 */
@isTest
private class AddServiceControllerTest 
{

	public static final String PARAM_PREFIX     = 'main:theForm:infoPanel:repeat:[i]:';
	
	// The controller we are testing pulls its inputs from the 
	// ApexPages.currentPage().getParameters() map. 
	//
	// We use these parameter names as keys in the aforementioned
	// map when passing inputs to our controller. 
	// 
	// Before using any of these values, use String.replace()
	// to replace '[i]' with an actual number.
	//
	// For example, to get the key name for the Role ID for the
	// third Service (index = 2), use the following value:
	// 
	// PARAM_ROLE_ID.replace('[i]','2');
	// 
	//	
	public static final String PARAM_SERVICE_SELECTED  = PARAM_PREFIX+'service';
    public static final String PARAM_ACCESS_PACKAGE_ID = PARAM_PREFIX+'accesspackage';
	//public static final String PARAM_ROLE_ID         = PARAM_PREFIX+'srole';
	//public static final String PARAM_PROFILE_ID      = PARAM_PREFIX+'sprofile';
	public static final String PARAM_SERVICE_ID        = PARAM_PREFIX+'sid';
	public static final String PARAM_DATE              = PARAM_PREFIX+'sdate';
	public static final String PARAM_FIELDSET          = PARAM_PREFIX+'sfieldset';
	public static final String PARAM_GEOPOINTE         = PARAM_PREFIX+'sgeopointe';
	public static final String PARAM_NOTES             = PARAM_PREFIX+'snotes';
	
		
	// Variable Name Shorthand:
	//
	// srv   => "Service"
	// rl    => "Role"
	// pr    => "Profile"
    // ap    => "Access Package"
	//
	// Rl    => the associated record has Roles
	// Pr    => the associated record has Profiles
    // Ap    => the associate record has Access Packages
	//
	// NoRl  => The Service does not have any Roles.
	// NoPr  => The Service does not have any Profiles
    // NoAp  => The record does not have any access packages
	//
	// Av => Available (Available_on_provisioning_case__c==true)
	// Un => Unavailable (Available_on_provisioning_case__c==false)
	//
	
	// Data Layout (per setup()):
	//
	// - 1 Account
	//
	// - 1 Contact
	//
	// - 1 Case
	//
	// - 1 unavailable Service, with no Access Package.
	//
	// - 4 Available Services, two with Access Packages and two without
	//
	// - Each Service with Access Packages has four of them, two available 
	//   and two unavailable.
	//
	
	public static Account theAccount = null;
	public static Contact theContact = null;
	public static Case    theCase    = null;
	
	// Available Services
	public static Map<Id,Service__c>   srvAllAv       = null;
    public static Service__c           srvAp01        = null;
    public static Service__c           srvAp02        = null;
	public static Service__c           srvNoAp01      = null;
    public static Service__c           srvNoAp02      = null;
    
	//public static Service__c           srvRlPr        = null;
	//public static Service__c           srvRlNoPr      = null;
	//public static Service__c           srvNoRlPr      = null;
	//public static Service__c           srvNoRlNoPr    = null;
	
	// Unavailable Services
	public static Map<Id,Service__c>   srvAllUn       = null;
	public static Service__c           srvUnavailable = null;
    
    // Available Access Packages
	public static Map<Id,Map<Id,Access_Package__c>>   apAllAv = null;
    public static Access_Package__c           apAv01  = null;
    public static Access_Package__c           apAv02  = null;
    public static Access_Package__c           apAv03  = null;
    public static Access_Package__c           apAv04  = null;

	// Unavailable Access Packages
	public static Map<Id,Map<Id,Access_Package__c>>   apAllUn = null;
    public static Access_Package__c           apUn01  = null;
    public static Access_Package__c           apUn02  = null;
    public static Access_Package__c           apUn03  = null;
    public static Access_Package__c           apUn04  = null;

    // Roles
    public static Service_Role__c             rl01    = null;
    public static Service_Role__c             rl02    = null;
    public static Service_Role__c             rl03    = null;
    public static Service_Role__c             rl04    = null;
    public static Service_Role__c             rl05    = null;
    public static Service_Role__c             rl06    = null;
    public static Service_Role__c             rl07    = null;
    public static Service_Role__c             rl08    = null;
    
    // Profiles
    public static Service_Profile__c          pr01    = null;
    public static Service_Profile__c          pr02    = null;
    public static Service_Profile__c          pr03    = null;
    public static Service_Profile__c          pr04    = null;
    public static Service_Profile__c          pr05    = null;
    public static Service_Profile__c          pr06    = null;
    public static Service_Profile__c          pr07    = null;
    public static Service_Profile__c          pr08    = null;
	 
	// Available Roles
	//public static Map<Id,Map<Id,Service_Role__c>> rlAllAv = null;
	//public static Service_Role__c      rlRlPrAv01     = null;
 	//public static Service_Role__c      rlRlPrAv02     = null;
 	//public static Service_Role__c      rlRlNoPrAv01   = null;
 	//public static Service_Role__c      rlRlNoPrAv02   = null;
 	
 	// Unavailable Roles
 	//public static Map<Id,Map<Id,Service_Role__c>> rlAllUn = null;
 	//public static Service_Role__c      rlRlPrUn01     = null;
 	//public static Service_Role__c      rlRlPrUn02     = null;
 	//public static Service_Role__c      rlRlNoPrUn01   = null;
 	//public static Service_Role__c      rlRlNoPrUn02   = null;
 	
 	// Available Profiles
 	//public static Map<Id,Map<Id,Service_Profile__c>> prAllAv = null;
 	//public static Service_Profile__c   prRlPrAv01     = null;
 	//public static Service_Profile__c   prRlPrAv02     = null;
 	//public static Service_Profile__c   prNoRlPrAv01   = null;
 	//public static Service_Profile__c   prNoRlPrAv02   = null;
 	
 	// Unavailable Profiles
 	//public static Map<Id,Map<Id,Service_Profile__c>> prAllUn = null;
  	//public static Service_Profile__c   prRlPrUn01     = null;
  	//public static Service_Profile__c   prRlPrUn02     = null;
  	//public static Service_Profile__c   prNoRlPrUn01   = null;
  	//public static Service_Profile__c   prNoRlPrUn02   = null;
 
 	
	public static String rndStr()
	{
		return 'ASConTest'+Math.random();
	}
	
	public static void setup()
	{
		theAccount = new Account(Name=rndStr());
	 	insert theAccount;
	 	
	 	theContact = new Contact(
	 		AccountId=theAccount.Id,
	 		LastName=rndStr());
	 	insert theContact;
	 	
	 	theCase = new Case(
		 		Type=rndStr(),
		 		prEmployee__c=theContact.Id
	 		);	 	
	 	insert theCase;

 		Service__c srvProto = new Service__c();
 		srvProto.Available_on_provisioning_case_c__c = true;
        srvProto.Offer_Access_Packages__c            = true;
 		
 		// Available Services
 		
        // ... with Access Packages
        srvAp01              = srvProto.clone();
	 	srvAp01.Field_Set__c = NewHireUtil.UAC_FIELD_SET_SALESFORCE;
        srvAp01.Name         = rndStr();
        
        srvAp02              = srvProto.clone();
	 	srvAp02.Field_Set__c = NewHireUtil.UAC_FIELD_SET_SALESFORCE;
        srvAp02.Name         = rndStr();
        
        // ... without Access Packages
        srvNoAp01              = srvProto.clone();
	 	srvNoAp01.Field_Set__c = NewHireUtil.UAC_FIELD_SET_SALESFORCE;
        srvNoAp01.Name         = rndStr();
        
        srvNoAp02              = srvProto.clone();
	 	srvNoAp02.Field_Set__c = NewHireUtil.UAC_FIELD_SET_SALESFORCE;
        srvNoAp02.Name         = rndStr();

	 	//srvRlPr          = srvProto.clone();
	 	//srvRlPr.Field_Set__c = NewHireUtil.UAC_FIELD_SET_SALESFORCE;
	 	//srvRlPr.Name     = rndStr();

	 	//srvRlNoPr        = srvProto.clone();
	 	//srvRlNoPr.Name   = rndStr();
	 	
	 	//srvNoRlPr        = srvProto.clone();
	 	//srvNoRlPr.Field_Set__c = NewHireUtil.UAC_FIELD_SET_GENERIC_WITH_PROFILE;
	 	//srvNoRlPr.Name   = rndStr();
	 	
	 	//srvNoRlNoPr      = srvProto.clone();
	 	//srvNoRlNoPr.Field_Set__c = NewHireUtil.UAC_FIELD_SET_GENERIC;
	 	//srvNoRlNoPr.Name = rndStr();
	 	
	 	// Unavailable Service
	 	
	 	srvUnavailable   = srvProto.clone();
	 	srvUnavailable.Available_on_provisioning_case_c__c = false;
	 	
	 	Service__c[] services = new sObject[]{
	 		srvAp01,
            srvAp02,
            srvNoAp01,
            srvNoAp02,
            //srvRlPr,
	 		//srvRlNoPr,
	 		//srvNoRlPr,
	 		//srvNoRlNoPr,
	 		srvUnavailable
	 	};
	 	insert services;
	 		 	
        
        // Roles
        //
        Service_Role__c rlProto = new Service_Role__c();
        rlProto.Available_on_Provisioning_Case__c = true;
        
        rl01            = rlProto.clone();
        rl01.Name       = rndStr();
        rl01.Service__c = srvAp01.Id;
        
        rl02            = rlProto.clone();
        rl02.Name       = rndStr();
        rl02.Service__c = srvAp01.Id;
        
        rl03            = rlProto.clone();
        rl03.Name       = rndStr();
        rl03.Service__c = srvAp01.Id;
        
        rl04            = rlProto.clone();
        rl04.Name       = rndStr();
        rl04.Service__c = srvAp01.Id;
        
        rl05            = rlProto.clone();
        rl05.Name       = rndStr();
        rl05.Service__c = srvAp02.Id;
        
        rl06            = rlProto.clone();
        rl06.Name       = rndStr();
        rl06.Service__c = srvAp02.Id;
        
        rl07            = rlProto.clone();
        rl07.Name       = rndStr();
        rl07.Service__c = srvAp02.Id;
        
        rl08            = rlProto.clone();
        rl08.Name       = rndStr();
        rl08.Service__c = srvAp02.Id;
        
        // Profiles
        //
        Service_Profile__c prProto = new Service_Profile__c();
        prProto.Available_on_Provisioning_Case__c = true;
        
        pr01            = prProto.clone();
        pr01.Name       = rndStr();
        pr01.Service__c = srvAp01.Id;
        
        pr02            = prProto.clone();
        pr02.Name       = rndStr();
        pr02.Service__c = srvAp01.Id;
        
        pr03            = prProto.clone();
        pr03.Name       = rndStr();
        pr03.Service__c = srvAp01.Id;
        
        pr04            = prProto.clone();
        pr04.Name       = rndStr();
        pr04.Service__c = srvAp01.Id;
        
        pr05            = prProto.clone();
        pr05.Name       = rndStr();
        pr05.Service__c = srvAp02.Id;
        
        pr06            = prProto.clone();
        pr06.Name       = rndStr();
        pr06.Service__c = srvAp02.Id;
        
        pr07            = prProto.clone();
        pr07.Name       = rndStr();
        pr07.Service__c = srvAp02.Id;
        
        pr08            = prProto.clone();
        pr08.Name       = rndStr();
        pr08.Service__c = srvAp02.Id;
        
	 	// Role prototypes
	 	// We will clone these to create our test records.
	 	//	 	
	 	//Service_Role__c rlAvProto = new Service_Role__c();
	 	//rlAvProto.Available_on_Provisioning_Case__c=true;
	 	
	 	//Service_Role__c rlUnProto = rlAvProto.clone();
	 	//rlUnProto.Available_on_provisioning_case__c = false;
	 	
	 	// Available Roles
	 	//
	 	//rlRlPrAv01              = rlAvProto.clone();
	 	//rlRlPrAv01.Name         = rndStr();
	 	//rlRlPrAv01.Service__c   = srvRlPr.Id;
	 	
	 	//rlRlPrAv02              = rlAvProto.clone();
	 	//rlRlPrAv02.Name         = rndStr();
	 	//rlRlPrAv02.Service__c   = srvRlPr.Id;
	 	
	 	//rlRlNoPrAv01            = rlAvProto.clone();
	 	//rlRlNoPrAv01.Name       = rndStr();
	 	//rlRlNoPrAv01.Service__c = srvRlNoPr.Id;
	 	
	 	//rlRlNoPrAv02            = rlAvProto.clone();
	 	//rlRlNoPrAv02.Name       = rndStr();
	 	//rlRlNoPrAv02.Service__c = srvRlNoPr.Id;
	 	
	 	
	 	// Unavailable Roles
	 	//
	 	//rlRlPrUn01              = rlUnProto.clone();
	 	//rlRlPrUn01.Name         = rndStr();
	 	//rlRlPrUn01.Service__c   = srvRlPr.Id;
	 		 		
	 	//rlRlPrUn02              = rlUnProto.clone();
	 	//rlRlPrUn02.Name         = rndStr();
	 	//rlRlPrUn02.Service__c   = srvRlPr.Id;
	 	
	 	//rlRlNoPrUn01            = rlUnProto.clone();
	 	//rlRlNoPrUn01.Name       = rndStr();
	 	//rlRlNoPrUn01.Service__c = srvRlNoPr.Id;
	 	
	 	//rlRlNoPrUn02            = rlUnProto.clone();
	 	//rlRlNoPrUn02.Name       = rndStr();
	 	//rlRlNoPrUn02.Service__c = srvRlNoPr.Id;
	 	
	 	// Profile prototypes
	 	// We will clone these to create our test records.
	 	//	
	 	//Service_Profile__c prAvProto = new Service_Profile__c();
	 	//prAvProto.Available_on_provisioning_case__c = true;
	 	
	 	//Service_Profile__c prUnProto = prAvProto.clone();
	 	//prUnProto.Available_on_provisioning_case__c = false;
	 	
	 	// Available Profiles
	 	//
	 	//prRlPrAv01              = prAvProto.clone();
	 	//prRlPrAv01.Name         = rndStr();
	 	//prRlPrAv01.Service__c   = srvRlPr.Id;
	 	
	 	//prRlPrAv02              = prAvProto.clone();
	 	//prRlPrAv02.Name         = rndStr();
	 	//prRlPrAv02.Service__c   = srvRlPr.Id;
	 	
	 	//prNoRlPrAv01            = prAvProto.clone();
	 	//prNoRlPrAv01.Name       = rndStr();
	 	//prNoRlPrAv01.Service__c = srvNoRlPr.Id;
	 	
	 	//prNoRlPrAv02            = prAvProto.clone();
	 	//prNoRlPrAv02.Name       = rndStr();
	 	//prNoRlPrAv02.Service__c = srvNoRlPr.Id;
	 		 		 	
	 	// Unavailable Profiles
	 	//
	 	//prRlPrUn01              = prUnProto.clone();
	 	//prRlPrUn01.Name         = rndStr();
	 	//prRlPrUn01.Service__c   = srvRlPr.Id;
	 	
	 	//prRlPrUn02              = prUnProto.clone();
	 	//prRlPrUn02.Name         = rndStr();
	 	//prRlPrUn02.Service__c   = srvRlPr.Id;
	 	
	 	//prNoRlPrUn01            = prUnProto.clone();
	 	//prNoRlPrUn01.Name       = rndStr();
	 	//prNoRlPrUn01.Service__c = srvNoRlPr.Id;
	 	
	 	//prNoRlPrUn02            = prUnProto.clone();
	 	//prNoRlPrUn02.Name       = rndStr();
	 	//prNoRlPrUn02.Service__c = srvNoRlPr.Id;
	 	
	 	sObject[] rolesAndProfiles = new sOBject[]
	 	{
	 		// rlRlPrAv01,
	 		// rlRlPrAv02,
	 		// rlRlNoPrAv01,
	 		// rlRlNoPrAv02,
	 		// rlRlPrUn01,
	 		// rlRlPrUn02,
	 		// rlRlNoPrUn01,
	 		// rlRlNoPrUn02,
	 		// prRlPrAv01,
	 		// prRlPrAv02,
	 		// prNoRlPrAv01,
	 		// prNoRlPrAv02,
	 		// prRlPrUn01,
	 		// prRlPrUn02,
	 		// prNoRlPrUn01,
	 		// prNoRlPrUn02
            rl01,
            rl02,
            rl03,
            rl04,
            rl05,
            rl06,
            rl07,
            rl08,
            pr01,
            pr02,
            pr03,
            pr04,
            pr05,
            pr06,
            pr07,
            pr08
	 	};
	 	insert rolesAndProfiles;
        
        // Available Access Packages
        Access_Package__c apAvProto                 = new Access_Package__c();
        apAvProto.Available_on_Provisioning_Case__c = true;
        
        apAv01                      = apAvProto.clone();        
        apAv01.Service__c           = srvAp01.Id;
        apAv01.Service_Role__c      = rl01.Id;
        apAv01.Service_Profile__c   = pr01.Id;
        apAv01.Name                 = rndStr();
        
        apAv02                      = apAvProto.clone();        
        apAv02.Service__c           = srvAp01.Id;
        apAv02.Service_Role__c      = rl02.Id;
        apAv02.Service_Profile__c   = pr02.Id;
        apAv02.Name                 = rndStr();
        
        apAv03                      = apAvProto.clone();        
        apAv03.Service__c           = srvAp02.Id;
        apAv03.Service_Role__c      = rl05.Id;
        apAv03.Service_Profile__c   = pr05.Id;
        apAv03.Name                 = rndStr();
        
        apAv04                      = apAvProto.clone();        
        apAv04.Service__c           = srvAp02.Id;
        apAv04.Service_Role__c      = rl06.Id;
        apAv04.Service_Profile__c   = pr06.Id;
        apAv04.Name                 = rndStr();       
        
        
        // Unavailable Access Packages
        //
        Access_Package__c apUnProto                 = apAvProto.clone();
        apUnProto.Available_on_Provisioning_Case__c = false;        
        
        apUn01                      = apUnProto.clone(); 
        apUn01.Service__c           = srvAp01.Id;
        apUn01.Service_Role__c      = rl03.Id;
        apUn01.Service_Profile__c   = pr03.Id;
        apUn01.Name                 = rndStr();
        
        apUn02                      = apUnProto.clone();
        apUn02.Service__c           = srvAp01.Id;
        apUn02.Service_Role__c      = rl04.Id;
        apUn02.Service_Profile__c   = pr04.Id;
        apUn02.Name                 = rndStr();
        
        apUn03                      = apUnProto.clone(); 
        apUn03.Service__c           = srvAp02.Id;
        apUn03.Service_Role__c      = rl07.Id;
        apUn03.Service_Profile__c   = pr07.Id;
        apUn03.Name                 = rndStr();
        
        apUn04                      = apUnProto.clone();   
        apUn04.Service__c           = srvAp02.Id;        
        apUn04.Service_Role__c      = rl08.Id;
        apUn04.Service_Profile__c   = pr08.Id;
        apUn04.Name                 = rndStr();
        
        Access_Package__c[] accessPackages = new Access_Package__c[]
        {
            apAv01,
            apAv02,
            apAv03,
            apAv04,
            apUn01,
            apUn02,
            apUn03,
            apUn04
        };
        insert accessPackages;

	 	// Populate our convenience aggregations.
	 	//
	 	srvAllAv = new Map<Id,Service__c>();
	 	srvAllUn = new Map<Id,Service__c>();
	 	//rlAllAv  = new Map<Id,Map<Id,Service_Role__c>>();
	 	//rlAllUn  = new Map<Id,Map<Id,Service_Role__c>>();
	 	//prAllAv  = new Map<Id,Map<Id,Service_Profile__c>>();
	 	//prAllUn  = new Map<Id,Map<Id,Service_Profile__c>>();
        
        apAllAv = new Map<Id, Map<Id,Access_Package__c>>();
        apAllUn = new Map<Id, Map<Id,Access_Package__c>>();
	 		
	 	for(Service__c srv : services)
	 	{
	 		if(srv.Available_on_provisioning_case_c__c)
	 		{
	 			srvAllAv.put(srv.Id,srv);
	 		} else
	 		{
	 			srvAllUn.put(srv.Id,srv);
	 		}
            apAllAv.put(srv.Id,new Map<Id,Access_Package__c>());
            apAllUn.put(srv.Id,new Map<Id,Access_Package__c>());
	 		//rlAllAv.put(srv.Id,new Map<Id,Service_Role__c>());
	 		//rlAllUn.put(srv.Id,new Map<Id,Service_Role__c>());
	 		//prAllAv.put(srv.Id,new Map<Id,Service_Profile__c>());
	 		//prAllUn.put(srv.Id,new Map<Id,Service_Profile__c>());
	 	}
        
        for(Access_Package__c ap : accessPackages)
        {
            if(ap.Available_on_Provisioning_Case__c)
            {
                apAllAv.get(ap.Service__c).put(ap.Id, ap);
            }
            else
            {
                apAllUn.get(ap.Service__c).put(ap.Id, ap);
            }
        }
	 	
	 	// for(sObject obj : rolesAndProfiles)
	 	// {
	 		// if(obj instanceof Service_Role__c)
	 		// {
	 			// Service_Role__c rl = (Service_Role__c)obj;

	 			// if(rl.Available_on_Provisioning_Case__c)
	 			// {
	 				// rlAllAv.get(rl.Service__c).put(rl.Id,rl);
	 			// }
	 			// else
	 			// {
	 				// rlAllUn.get(rl.Service__c).put(rl.Id,rl);	 					 				
	 			// }	 				 			
	 		// } 
	 		// else if(obj instanceof Service_Profile__c)
	 		// {
	 			// Service_Profile__c pr = (Service_Profile__c)obj;

	 			// if(pr.Available_on_Provisioning_Case__c)
	 			// {
	 				// prAllAv.get(pr.Service__c).put(pr.Id,pr);
	 			// }
	 			// else
	 			// {
	 				// prAllUn.get(pr.Service__c).put(pr.Id,pr);	 					 				
	 			// }
	 			
	 		// }
	 	// }
	 	
	 	
	 	// Set the current page
	 	Test.setCurrentPage(Page.AddService);
	}
		
	 /**
	 * Constructor
	 * - The new instance has a Case instance with the same ID as the one used
	 *   to construct the ApexPages.StandardController we are using.
	 * - The Case instance variable has all of the necessary data available.
	 */
	 @isTest
	 public static void testConstructor()
	 {
	 	// Set up our data.
	 	setup();
	 	
	 	// Run the constructor.
	 	AddServiceController controller = 
	 	new AddServiceController(new ApexPages.StandardController(theCase));
	 	
	 	// Test the output.
	 	
	 	Case outCase = controller.getCase();
	 	
	 	System.assert(null!=outCase, 
	 		'The controller returned a null Case after constructing the controller.');
	 	
	 	System.assertEquals(theCase.Id,outCase.Id, 
	 		'After constructing the controller, the controller\'s Case has the wrong ID.');
	 	
	 	System.assertEquals(theCase.Id,outCase.Id, 
	 		'The controller\'s Case has the wrong ID.');
	 	
	 	System.assertEquals(theCase.Type,outCase.Type, 
	 		'The controller\'s Case has the wrong Type.');
	 		
	 	System.assertEquals(theCase.prEmployee__c,outCase.prEmployee__c, 
	 		'The controller\'s Case has the wrong prEmployee__c.');
	 	
	 }
	 
	 /**
	 * CanAddService
	 * - The getCanAddService returns false if the Case is a Drop case, true otherwise.
	 */
	 @isTest
	 public static void testCanAddService()
	 {
	 	// Set up our data.	 	
	 	setup();
	 	
	 	Case nonDropCase = theCase;
	 	
	 	// Add a drop case to our setup.
	 	Case dropCase = nonDropCase.clone();
	 	dropCase.Type = NewHireUtil.CASE_TYPE_DROP;
	 	insert dropCase;
		 	
	 	// Run the constructor on our non-drop Case.
	 	AddServiceController controller = 
	 	new AddServiceController(new ApexPages.StandardController(nonDropCase));
	 	
	 	// Assert correct output.
	 	System.assertEquals(true,controller.getCanAddService(),
	 	'The getCanAddService() method returned false, even though the Case is not a Drop Case.');
	 	
	 	// Run the constructor again on our drop Case.
	 	controller = new AddServiceController(
	 		new ApexPages.StandardController(dropCase));
	 	
	 	// Assert correct output.
	 	System.assertEquals(false,controller.getCanAddService(),
	 	'The getCanAddService() method returned false, even though the Case is a Drop Case.');
	 		
	 }
	 	 	 
	 /**
	 * SetServices
	 * - The serviceList member variable is populated with a list of services.
	 * - Services with Available_on_provisioning_case_c__c == false are excluded.
	 * - Each Service__c.Salesforce_Profiles__r relationship contains a list of 
	 *   the Service_Profile__c records tied to that Service__c, excluding the ones where
	 *   Available_on_Provisioning_Case__c is false
	 * - Each Service__c.Salesforce_Roles__r relationship contains a list of 
	 *   the Service_Role__c records tied to that Service__c, excluding the ones where
	 *   Available_on_Provisioning_Case__c is false.
	 */
	 @isTest
	 public static void testSetServices()
	 {	
	 	// Set up our data.
		setup();
		
		// Set up the controller.
		AddServiceController controller = 
		new AddServiceController(new ApexPages.StandardController(theCase));
		
		// Run the method.
		controller.setServices();
		
		// Test our output.
		List<Service__c> output = controller.serviceList;
			
		System.assert(null!=output,
		'The Service__c list was null after calling setServices()');
		
		// Check each Service__c.
		//
		Set<Id> serviceIds = new Set<Id>();
		for(Service__c service : output)
		{
			System.assert(null != service.Id, 
				'Found a Service__c with Id=null.');
			
			System.assert(!srvAllUn.containsKey(service.Id),
				'Found a Service__c from a group of records that had '
	 			+'Available_on_provisioning_case_c__c=false upon setup.');
			
			System.assertEquals(srvAllAv.get(service.Id).Name,service.Name,
				'Found an unexpected value for Service__c.Name');
				
			System.assertEquals(srvAllAv.get(service.Id).Field_Set__c,service.Field_Set__c,
				'Found an unexpected value for Service__c.Field_Set__c');
 			
			// Check each Service_Role__c
			//
			
			System.assert(null != service.Access_Packages__r,
				'An Access_Packages__r relationship returned a null result.');
				
			Set<Id> apIds = new Set<Id>();
			for(Access_Package__c ap : service.Access_Packages__r)
			{
				System.assert(null != ap.Id,
					'Found a Service__c.Access_Packages__r[i] record with Id=null.');
				
				System.assert(!apAllUn.get(service.Id).containsKey(ap.Id),
					'Found a Service__c.Access_Packages__r[i] record from a group of records '
					+'that had Available_on_provisioning_case__c=false upon setup.'
				);	
				
				System.assertEquals(apAllAv.get(service.Id).get(ap.Id).Name,ap.Name,
					'Found an unexpected value for Service__c.Access_Packages__r[i].Name');
				
				apIds.add(ap.Id);
			}
			System.assert(apIds.containsAll(apAllAv.get(service.Id).keySet()),
				'Found a Service__c.Access_Packages__r which was missing some expected records.');
            
            // System.assert(null != service.Salesforce_Roles__r,
	 			// 'A Salesforce_Roles__r relationship returned a null result.');
	 			
	 		// Set<Id> roleIds = new Set<Id>();
	 		// for(Service_Role__c role : service.Salesforce_Roles__r)
	 		// {
	 			// System.assert(null != role.Id,
	 				// 'Found a Service__c.Salesforce_Roles__r[i] record with Id=null.');
	 			
	 			// System.assert(!rlAllUn.get(service.Id).containsKey(role.Id),
	 				// 'Found a Service__c.Salesforce_Roles__r[i] record from a group of records '
	 				// +'that had Available_on_provisioning_case__c=false upon setup.'
	 			// );	
	 			
	 			// System.assertEquals(rlAllAv.get(service.Id).get(role.Id).Name,role.Name,
	 				// 'Found an unexpected value for Service__c.Salesforce_Roles__r[i].Name');
	 			
	 			// roleIds.add(role.Id);
	 		// }
	 		// System.assert(roleIds.containsAll(rlAllAv.get(service.Id).keySet()),
	 			// 'Found a Service__c.Salesforce_Roles__r which was missing some expected records.');
	 			
	 		
	 		// // Check each Service_Profile__c
	 		// //
	 		// Set<Id> profileIds = new Set<Id>();
	 		// for(Service_Profile__c profile : service.Salesforce_Profiles__r)
	 		// {
	 			// System.assert(null != profile.Id,
	 				// 'Found a Service__c.Salesforce_Profiles__r[i] record with Id=null.');
	 			
	 			// System.assert(!rlAllUn.get(service.Id).containsKey(profile.Id),
	 				// 'Found a Service__c.Salesforce_Profiles__r[i] record from a group of records '
	 				// +'that had Available_on_provisioning_case__c=false upon setup.'
	 			// );
	 			
	 			// System.assertEquals(prAllAv.get(service.Id).get(profile.Id).Name,profile.Name,
	 				// 'Found an unexpected value for Service__c.Salesforce_Profiles__r[i].Name');
	 			
	 			// profileIds.add(profile.Id);	 				 			
	 		// }	 		
	 		// System.assert(profileIds.containsAll(prAllAv.get(service.Id).keySet()),
	 			// 'Found a Service__c.Salesforce_Profiles__r which was missing some expected records.');

	 	}
	 	
	 }

     /**
     * GetServicesNoAccessPackages
     * Like GetServices, but with each Service__c.Offer_Access_Packages__c = false.
     * - The wrapperList member variable is populated with a list of ServiceWrapper 
     *   instances
     * - A ServiceWrapper exists for every item in the serviceList member.
     * - Each ServiceWrapper contains a null SelectOption list.
     * - Each ServiceWrapper contains correct values for the corresponding service's 
     *   Name, Id, and Field_Set__c variables.
     * - After calling getServices() the getServicesSize() function returns the 
     *   size of the getServices() output.
     */
     @isTest
     public static void testGetServicesNoAccessPackages()
     {
        // Set up our data.     
        setup();
        
        // Set up the controller.
        AddServiceController controller = 
        new AddServiceController(new ApexPages.StandardController(theCase));
        
        // setServices() must be run before getServices() will work. 
        // See testSetServices for unit tests on this method's output
        controller.setServices();

        // Before calling getServices, make sure that each Service has 
        // Offer_Access_Packages__c = false.
        //
        for(Service__c service : controller.serviceList)
        {
            service.Offer_Access_Packages__c = false;
        }
        
        List<AddServiceController.ServiceWrapper> allWrappers = controller.getServices();
        
        // For each Service ...
        for(Service__c service : controller.serviceList)
        {
            System.assert(null != service.Id, 
                'Found a Service__c with Id==null. See testSetServices() test results to troubleshoot.');
            
            // ... look for a wrapper.
            AddServiceController.ServiceWrapper wrapper = null;
            for(AddServiceController.ServiceWrapper checkWrapper : allWrappers)
            {
                System.assert(null != checkWrapper.serviceId,
                    'Found a ServiceWrapper with a null serviceId');
                    
                if(checkWrapper.serviceId == service.Id)
                {
                    wrapper = checkWrapper;
                    break;
                }
            }
            
            System.assert(null != wrapper,
                'Found an available Service__c for which there is no wrapper with a matching serviceId.');

            System.assertEquals(service.Name,wrapper.serviceName,
                'Found an unexpected value for ServiceWrapper.serviceName.');
            
            System.assertEquals(service.Field_Set__c, wrapper.fieldSet,
                'Found an unexpected value for ServiceWrapper.fieldSet');

            System.assertEquals(
                    service.Offer_Access_Packages__c,
                    wrapper.accessPackages != null,
                    'ServiceWrapper\'s non-null status does not match the Service\'s Offer_Access_Package__c field.'
            );
            

            System.assertEquals(
                null, wrapper.accessPackages,
                'Wrapper class contained a non-null list of Access Packages, even though Offer_Access_Packages__c was false on the Service__c.'
            );
        }
        
        System.assertEquals(controller.serviceList.size(),allWrappers.size(),
            'Wrong number of ServiceWrappers, compared to this controller\'s serviceList');
        
     }
	 
	/**
	 * GetServices
	 * - The wrapperList member variable is populated with a list of ServiceWrapper 
	 *   instances
	 * - A ServiceWrapper exists for every item in the serviceList member.
	 * - Each ServiceWrapper contains a list of SelectOption with one entry for 
	 *   each record in the Service__c.Salesforce_Roles__r relationship.
	 * - Each ServiceWrapper contains a list of SelectOption with one entry for 
	 *   each record in the Service__c.Salesforce_Profiles__r relationship.
	 * - Each Select Option has a Record Id as its value and Record Name as its Label
	 * - Each ServiceWrapper contains correct values for the corresponding service's 
	 *   Name, Id, and Field_Set__c variables.
	 * - After calling getServices() the getServicesSize() function returns the 
	 *   size of the getServices() output.
	 */
	 @isTest
	 public static void testGetServices()
	 {
	 	// Set up our data.		
		setup();
		
		// Set up the controller.
	 	AddServiceController controller = 
	 	new AddServiceController(new ApexPages.StandardController(theCase));
	 	
	 	// setServices() must be run before getServices() will work. 
	 	// See testSetServices for unit tests on this method's output
	 	controller.setServices();
	 	
	 	List<AddServiceController.ServiceWrapper> allWrappers = controller.getServices();
	 	
	 	// For each Service ...
	 	for(Service__c service : controller.serviceList)
	 	{
	 		System.assert(null != service.Id, 
	 			'Found a Service__c with Id==null. See testSetServices() test results to troubleshoot.');
	 		
	 		// ... look for a wrapper.
	 		AddServiceController.ServiceWrapper wrapper = null;
	 		for(AddServiceController.ServiceWrapper checkWrapper : allWrappers)
	 		{
	 			System.assert(null != checkWrapper.serviceId,
	 				'Found a ServiceWrapper with a null serviceId');
	 				
	 			if(checkWrapper.serviceId == service.Id)
	 			{
	 				wrapper = checkWrapper;
	 				break;
	 			}
	 		}
	 		
	 		System.assert(null != wrapper,
	 			'Found an available Service__c for which there is no wrapper with a matching serviceId.');

	 		System.assertEquals(service.Name,wrapper.serviceName,
	 			'Found an unexpected value for ServiceWrapper.serviceName.');
	 		
	 		System.assertEquals(service.Field_Set__c, wrapper.fieldSet,
	 			'Found an unexpected value for ServiceWrapper.fieldSet');

            System.assertEquals(
                    service.Offer_Access_Packages__c,
                    wrapper.accessPackages != null,
                    'ServiceWrapper\'s non-null status does not match the Service\'s Offer_Access_Package__c field.'
            );
	 		

            // For each Access_Package__c on this Service ... 
	 		for(Access_Package__c ap : service.Access_Packages__r)
	 		{
	 			System.assert(null != ap.Id, 
	 			'Found a Service__c.Access_Packages__r[i] record with Id==null. See testSetServices() test results to troubleshoot.');
	 			
	 			System.assert(null != wrapper.accessPackages,
	 				'Found a ServiceWrapper with a null accessPackages list.');
	 				
	 			SelectOption apOption = null;
	 			
	 			// ... look for a matching SelectOption.
	 			for(SelectOption option : wrapper.accessPackages)
	 			{
	 				System.assert(null != option.getValue(),
	 					'Found a SelectOption with a null value.');
	 				if(option.getValue()==ap.Id)
	 				{
	 					apOption = option;
	 					break;
	 				}
	 			}
	 			
	 			// ... and compare the role to its matching option.
	 			System.assert(null != apOption,
	 				'Found a Service__c.Access_Packages__r[i] record for which there is no SelectOption whose '
	 				+'ID matches Access_Package__c.Id ('+ap.Id+')');
	 			
	 			
	 			System.assertEquals(ap.Name,apOption.getLabel(),
	 				'Found unexpected value for the SelectOption.getLabel() corresponding to a Service__c.Access_Packages__r[i] record.');
	 		}
	 		
	 		System.assertEquals(service.Access_Packages__r.size(),wrapper.accessPackages.size(),
	 			'Wrong number of role SelectOptions for this ServiceWrapper.');
            
            
	 		// // For each Role on this Service ... 
	 		// for(Service_Role__c role : service.Salesforce_Roles__r)
	 		// {
	 			// System.assert(null != role.Id, 
	 			// 'Found a Service__c.Salesforce_Roles__r[i] record with Id==null. See testSetServices() test results to troubleshoot.');
	 			
	 			// System.assert(null != wrapper.serRoles,
	 				// 'Found a ServiceWrapper with a null serRoles list.');
	 				
	 			// SelectOption roleOption = null;
	 			
	 			// // ... look for a matching SelectOption.
	 			// for(SelectOption option : wrapper.serRoles)
	 			// {
	 				// System.assert(null != option.getValue(),
	 					// 'Found a SelectOption with a null value.');
	 				// if(option.getValue()==role.Id)
	 				// {
	 					// roleOption = option;
	 					// break;	 					
	 				// }
	 			// }
	 			
	 			// // ... and compare the role to its matching option.
	 			// System.assert(null != roleOption,
	 				// 'Found a Service__c.Salesforce_Roles__r[i] record for which there is no SelectOption whose '
	 				// +'ID matches Service_Role__c.Id ('+role.Id+')');
	 			
	 			
	 			// System.assertEquals(role.Name,roleOption.getLabel(),
	 				// 'Found unexpected value for the SelectOption.getLabel() corresponding to a Service__c.Salesforce_Roles__r[i] record.');
	 		// }
	 		
	 		// System.assertEquals(service.Salesforce_Roles__r.size(),wrapper.serRoles.size(),
	 			// 'Wrong number of role SelectOptions for this ServiceWrapper.');
	 		
	 		// // For each Profile on this Service ... 
	 		// for(Service_Profile__c profile : service.Salesforce_Profiles__r)
	 		// {
	 			// System.assert(null != profile.Id, 
	 			// 'Found a Service__c.Salesforce_Profiles__r[i] record with Id==null. See testSetServices() test results to troubleshoot.');
	 			
	 			// System.assert(null != wrapper.serProfiles,
	 				// 'Found a ServiceWrapper with a null serProfiles list.');
	 				
	 			// SelectOption profileOption = null;
	 			
	 			// // ... look for a matching SelectOption.
	 			// for(SelectOption option : wrapper.serProfiles)
	 			// {
	 				// System.assert(null != option.getValue(),
	 					// 'Found a SelectOption with a null value.');
	 				// if(option.getValue()==profile.Id)
	 				// {
	 					// profileOption = option;
	 					// break;	 					
	 				// }
	 			// }
	 			
	 			// // ... and compare the profile to its matching option.
	 			// System.assert(null != profileOption,
	 				// 'Found a Service__c.Salesforce_Profiles__r[i] record for which there is no SelectOption whose '
	 				// +'ID matches Service_Profile__c.Id ('+profile.Id+')');
	 			
	 			
	 			// System.assertEquals(profile.Name,profileOption.getLabel(),
	 				// 'Found unexpected value for the SelectOption.getLabel() corresponding to a Service__c.Salesforce_Profiles__r[i] record.');
	 		// }
	 		// System.assertEquals(service.Salesforce_Profiles__r.size(),wrapper.serProfiles.size(),
	 			// 'Wrong number of profile SelectOptions for this ServiceWrapper.');	 		
	 	} 	
	 	
	 	System.assertEquals(controller.serviceList.size(),allWrappers.size(),
	 		'Wrong number of ServiceWrappers, compared to this controller\'s serviceList');
	 	
	 }
	 
	 /**
	 * AddServices
	 * - A new User_Account_Case__c exists for each selected Service__c
	 * - The chosen Profile__c, Role__c, and Date__c values are properly inserted.
	 * - Unparsable dates and bad Id values cause the controller to display an 
 	 *   error message and set the error flag to true.
	 * - Unsavable input causes an exception and prevents DB changes from being made.
	 * - The correct RecordType is assigned based on the Service__c fieldSet variable.
	 * - All other fields on the inserted record have the proper values.
	 */
	 @isTest
	 public static void testAddServices()
	 {
	 	
	 	// Set up our data.
		setup();
		
		// Set up the controller.
	 	AddServiceController controller = 
	 	new AddServiceController(new ApexPages.StandardController(theCase));
	 	
	 	// Setup our choices.
	 	controller.setServices();
	 	controller.getServices();
	 	
	 	// Prepare our input.
	 	Map<String,String> input = ApexPages.currentPage().getParameters();
	 		 	
	 	Date d1 = Date.today().addDays(24);
	 	String notes1 = rndStr();
	 	
	 	// First record selected, with user input
	 	input.put(PARAM_SERVICE_SELECTED .replace('[i]','0'),'on');
        input.put(PARAM_ACCESS_PACKAGE_ID.replace('[i]','0'),apAv01.Id);
		//input.put(PARAM_ROLE_ID          .replace('[i]','0'),rlRlPrAv02.Id);
		//input.put(PARAM_PROFILE_ID       .replace('[i]','0'),prRlPrAv02.Id);
		input.put(PARAM_SERVICE_ID       .replace('[i]','0'),srvAp01.Id);
		input.put(PARAM_DATE             .replace('[i]','0'),d1.month()+'/'+d1.day()+'/'+d1.year());
		input.put(PARAM_FIELDSET         .replace('[i]','0'),srvAp01.Field_Set__c);
		input.put(PARAM_GEOPOINTE        .replace('[i]','0'),'on');
		input.put(PARAM_NOTES            .replace('[i]','0'),notes1);
		
		// Second record not selected.
	 	input.put(PARAM_SERVICE_SELECTED .replace('[i]','1'),null);
        input.put(PARAM_ACCESS_PACKAGE_ID.replace('[i]','1'),apAv03.Id);
		//input.put(PARAM_ROLE_ID          .replace('[i]','1'),rlRlNoPrAv02.Id);
		//input.put(PARAM_PROFILE_ID       .replace('[i]','1'),null);
		input.put(PARAM_SERVICE_ID       .replace('[i]','1'),srvAp02.Id);
		input.put(PARAM_DATE             .replace('[i]','1'),d1.month()+'/'+d1.day()+'/'+d1.year());
		input.put(PARAM_FIELDSET         .replace('[i]','1'),srvAp02.Field_Set__c);
		input.put(PARAM_GEOPOINTE        .replace('[i]','1'),'on');
		input.put(PARAM_NOTES            .replace('[i]','1'),notes1);
		
		Date d2 = Date.today().addDays(15);
	 	String notes2 = rndStr();
	 	
		// Third record selected, with user input
		input.put(PARAM_SERVICE_SELECTED .replace('[i]','2'),'on');
        input.put(PARAM_ACCESS_PACKAGE_ID.replace('[i]','2'), null);
		//input.put(PARAM_ROLE_ID          .replace('[i]','2'),null);
		//input.put(PARAM_PROFILE_ID       .replace('[i]','2'),null);
		input.put(PARAM_SERVICE_ID       .replace('[i]','2'),srvNoAp01.Id);
		input.put(PARAM_DATE             .replace('[i]','2'),d2.month()+'/'+d2.day()+'/'+d2.year());
		input.put(PARAM_FIELDSET         .replace('[i]','2'),srvNoAp01.Field_Set__c);
		input.put(PARAM_GEOPOINTE        .replace('[i]','2'),null);
		input.put(PARAM_NOTES            .replace('[i]','2'),notes2);
		
		// Fourth record not selected
		input.put(PARAM_SERVICE_SELECTED .replace('[i]','3'),null);
        input.put(PARAM_ACCESS_PACKAGE_ID.replace('[i]','3'),null);
		//input.put(PARAM_ROLE_ID          .replace('[i]','3'),null);
		//input.put(PARAM_PROFILE_ID       .replace('[i]','3'),prNoRlPrAv01.Id);
		input.put(PARAM_SERVICE_ID       .replace('[i]','3'),srvNoAp02.Id);
		input.put(PARAM_DATE             .replace('[i]','3'),d2.month()+'/'+d2.day()+'/'+d2.year());
		input.put(PARAM_FIELDSET         .replace('[i]','3'),srvNoAp02.Field_Set__c);
		input.put(PARAM_GEOPOINTE        .replace('[i]','3'),null);
		input.put(PARAM_NOTES            .replace('[i]','3'),notes2);
		
		// Run the method we are testing.
		controller.addServices();
		
		// Get results for the first option (selected).
		//
		
		User_Account_Case__c[] uacLst = [
			select
				Id,
				Employee__c,
				RecordTypeId,
				Case__c,
                //Profile__c,
                //Role__c,
                Business_Role__c,
                Service__c,
                Needs_Geopoint__c,
                Status__c,
				Type__c,
				Notes__c,
				Date__c                
			from User_Account_Case__c
			
			where Service__c  = :srvAp01.Id
			  and Case__c     = :theCase.Id
			  and Employee__c = :theCase.prEmployee__c
		];
		
		System.assert(uacLst.size() > 0,
			'No User_Account_Case__c was created for this Service__c, Contact, and Case.');
			
		User_Account_Case__c uac = uacLst[0];
		
		System.assertEquals(NewHireUtil.UACASE_RTYPE_FOR_SRV_FIELDSET.get(srvAp01.Field_Set__c),uac.RecordTypeId,
			'Wrong RecordTypeId on the new User_Account_Case__c');
		
        System.assertEquals(apAv01.Id, uac.Business_Role__c, 
			'Wrong Business_Role__c on the new User_Account_Case__c');
        
		//System.assertEquals(prRlPrAv02.Id, uac.Profile__c, 
		//	'Wrong Profile__c on the new User_Account_Case__c');
		
		//System.assertEquals(rlRlPrAv02.Id, uac.Role__c, 
		//	'Wrong Role__c on the new User_Account_Case__c');
		
		System.assertEquals(srvAp01.Id, uac.Service__c, 
			'Wrong Service__c on the new User_Account_Case__c');
		
		System.assertEquals(true,uac.Needs_Geopoint__c,
			'Wrong Needs_Geopoint__c on the new User_Account_Case__c');
		
		System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN,uac.Status__c,
			'Wrong Status__c on the new User_Account_Case__c');
		
		System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE,uac.Type__c,
			'Wrong Type__c on the new User_Account_Case__c');
		
		System.assertEquals(notes1,uac.Notes__c,
			'Wrong Notes__c on the new User_Account_Case__c');	
		
		System.assertEquals(d1,uac.Date__c,
			'Wrong Date__c on the new User_Account_Case__c');
			
		
		// Get results for the second option (not selected).
		//
		
		uacLst = [
			select Id
			from User_Account_Case__c
			where Service__c  = :srvAp02.Id
			  and Case__c     = :theCase.Id
			  and Employee__c = :theCase.prEmployee__c
		];
		
		System.assert(uacLst.size() == 0,
			'A User_Account_Case__c was created for a Service__c that was not selected.');
			
		
		// Get results for the third option (selected).
		//
		
		uacLst = [
			select
				Id,
				Employee__c,
				RecordTypeId,
				Case__c,
                //Profile__c,
                //Role__c,
                Business_Role__c,
                Service__c,
                Needs_Geopoint__c,
                Status__c,
				Type__c,
				Notes__c,
				Date__c
			from User_Account_Case__c
			
			where Service__c  = :srvNoAp01.Id
			  and Case__c     = :theCase.Id
			  and Employee__c = :theCase.prEmployee__c
		];
		
		System.assert(uacLst.size() > 0,
			'No User_Account_Case__c was create for this Service__c, Contact, and Case.');
			
		uac = uacLst[0];
		
		System.assertEquals(NewHireUtil.UACASE_RTYPE_FOR_SRV_FIELDSET.get(srvNoAp01.Field_Set__c),uac.RecordTypeId,
			'Wrong RecordTypeId on the new User_Account_Case__c. (Field_Set__c="'+srvNoAp01.Field_Set__c+'")');
		
        System.assertEquals(null, uac.Business_Role__c, 
			'Wrong Business_Role__c on the new User_Account_Case__c');
        
		//System.assertEquals(null, uac.Profile__c, 
		//	'Wrong Profile__c on the new User_Account_Case__c');
		
		//System.assertEquals(null, uac.Role__c, 
		//	'Wrong Role__c on the new User_Account_Case__c');
		
		System.assertEquals(srvNoAp01.Id, uac.Service__c, 
			'Wrong Service__c on the new User_Account_Case__c');
		
		System.assertEquals(false,uac.Needs_Geopoint__c,
			'Wrong Needs_Geopoint__c on the new User_Account_Case__c');
		
		System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_STATUS_OPEN,uac.Status__c,
			'Wrong Status__c on the new User_Account_Case__c');
		
		System.assertEquals(NewHireUtil.USER_ACCOUNT_CASE_TYPE_ACTIVATE,uac.Type__c,
			'Wrong Type__c on the new User_Account_Case__c');
		
		System.assertEquals(notes2,uac.Notes__c,
			'Wrong Notes__c on the new User_Account_Case__c');	
			
		System.assertEquals(d2,uac.Date__c,
			'Wrong Date__c on the new User_Account_Case__c');
		
        // Remove this User_Account_Case__c so we can delete the associated 
        // Service_Profile in a later test.
		delete uacLst;
		
		// Get results for the fourth option (not selected).
		//
		
		uacLst = [
			select Id
			from User_Account_Case__c
			where Service__c  = :srvNoAp02.Id
			  and Case__c     = :theCase.Id
			  and Employee__c = :theCase.prEmployee__c
		];
		
		System.assert(uacLst.size() == 0,
			'A User_Account_Case__c was created for a Service__c that was not selected.');
			
		
		// Try again with unparsable data in a selected option.
		//
		
		// Deselect the previous two selections.
		input.put(PARAM_SERVICE_SELECTED .replace('[i]','0'),null);
		input.put(PARAM_SERVICE_SELECTED .replace('[i]','2'),null);
		
		// Select the second service.
		input.put(PARAM_SERVICE_SELECTED .replace('[i]','1'),'on');
		
		// Enter an unparsable Date
		input.put(PARAM_DATE             .replace('[i]','1'),'XXXXXXXX');
		
		try
		{
			// Run the controller.
			controller.addServices();
		} 
		catch(Exception e)
		{
			System.assert(false, 
				'When given an unparsable Date value, threw an uncaught '
				+'exception instead of reloading the page with an error message.');			
		}
		
		// Query results.
		uacLst = [
			select Id
			from User_Account_Case__c			
			where Service__c  = :srvAp02.Id
			  and Case__c     = :theCase.Id
			  and Employee__c = :theCase.prEmployee__c
		];
		
		System.assert(uacLst.size()==0,
			'Created a User_Account_Case__c record even though unparsable data was given.');
			
		System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),
			'Given unparsable input, did not generate any messages with ApexPages.Severity.ERROR.');
		
		System.assertEquals(true,controller.error,
			'The error flag on the Controller was not set after unparsable data was given.');	 	
	 	
	 	// Try an error condition resulting in a DML exception	 	
	 	
        // Leave the second service selected.
         
	 	// Deselect the second service
		input.put(PARAM_SERVICE_SELECTED .replace('[i]','1'),null);
		
		// Select the third service.
		input.put(PARAM_SERVICE_SELECTED .replace('[i]','2'),'on');
		
		// Invalidate the Service ID by deleting the record.
		delete srvNoAp01;
		
		try
		{
			// Run the controller.
			controller.addServices();
			System.assert(false, 
				'When given an unsavable Service__c ID, failed to throw an uncaught Exception.');	
		} 
		catch(Exception e)
		{
			System.assert(true);					
		}
		
		// Query results.
		uacLst = [
			select Id
			from User_Account_Case__c			
			where Service__c  = :srvNoAp01.Id
			  and Case__c     = :theCase.Id
			  and Employee__c = :theCase.prEmployee__c
		];
		
		System.assert(uacLst.size()==0,
			'Created a User_Account_Case__c record even though unsavable data was given.');
	 
	 	
	 }
	 
	 
	/**
	* Back
	* - The returned PageReference points to the UserAccountCase page.
	* - The returned PageReference has an Id parameter with the ID of the Case.
	* - The returned PageReference has getRedirect()==true.
	*/
	@isTest
	public static void testBack()
	{
		// Set up our data.		
		setup();
		
		// Set up the controller.
	 	AddServiceController controller = 
	 	new AddServiceController(new ApexPages.StandardController(theCase));
		
		PageReference nextPage = controller.back();
		
		String url = nextPage.getUrl();			
		System.assert(null != url, 'Next page URL is null.');
		
		// Normalize the URLs so we can compare them.
		String expectedUrl = Page.UserAccountCase.getUrl().replaceAll('\\\\','/').toLowercase();
		url = url.replaceall('\\\\','/').toLowercase().split('[?]')[0];
		
		System.assertEquals(expectedUrl,url,'Wrong URL for next page.');
		
		System.assert(nextPage.getParameters().containsKey('id'),
		'The next page URL does not include an ID parameter.');
		
		System.assertEquals(theCase.Id,nextPage.getParameters().get('id'),
		'The the ID parameter in the next page URL does not contain the current Case\'s ID.');
		
		System.assertEquals(true,nextPage.getRedirect(),'Wrong value for nextPage.getRedirect().');
	}
	 
}