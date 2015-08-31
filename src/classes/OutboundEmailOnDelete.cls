/**
 * @description Class is called after delete when Help Desk cases or Assets are deleted.
 *              Called by CaseHandler and AssetHandler classes.
 */
public with sharing class OutboundEmailOnDelete {

    public static List<Messaging.SingleEmailMessage> emailMessagesForSend = new List<Messaging.SingleEmailMessage>(); 
    
    private static List<IT_Email_To_Addresses__c> emailAddresses = IT_Email_To_Addresses__c.getAll().values();

    public static String[] toAddresses = new String[]{};


    // static initializer which builds email addresses list based on the environment (sandbox or prod)
    // in sandbox, email addresses are only added if the Email in Sandbox checkbox is checked
    static {
        for(IT_Email_To_Addresses__c e : emailAddresses) {
            if(!GlobalUtil.isSandbox()) {
                toAddresses.add(e.Email__c);   
            } else {
                if(e.Email_in_Sandbox__c) {
                    toAddresses.add(e.Email__c);
                }
            }
        }
    }

    // Lazy-loaded map of asset classifications
    public static Map<Id, Asset_Classification__c> assetClassifications {
        get {
            if (assetClassifications == null) {
                assetClassifications = generateAssetClasses();
            }
            return assetClassifications;
        }
        private set;
    }

    private static Map<Id, Asset_Classification__c> generateAssetClasses() {
        Map<Id, Asset_Classification__c> assetClasses = new Map<Id, Asset_Classification__c>();
        for (Asset_Classification__c a : [select Id, Name from Asset_Classification__c]) {
            assetClasses.put(a.Id, a);
        }
        return assetClasses;
    }

    public static String noEmailError = '';

    /**
     * @description Builds emails for each sObject and then mails the whole list
     * @param List of sobjects
     */
	public static void buildEmailMain(List<SObject> soList) {
        if(toAddresses.size() > 0) {
            // build set of created by ids to that will be used to query users  
            Set<Id> createdByIds = new Set<Id>();

            for(sObject so : soList) {
                String createdByIdString = String.valueOf(so.get('CreatedById'));
                if(so.getSObjectType() == Case.sObjectType && !createdByIds.contains(createdByIdString)) {
                    createdByIds.add(createdByIdString);
                }
            }

            // Map of String value of User Id and User Name
            Map<String, String> createdByMap = new Map<String, String>();
            for(User u : [select Id, Name from User where Id in :createdByIds]) {
                createdByMap.put(String.valueOf(u.Id), u.Name);
            }

            for(SObject so : soList) {   
                String senderDisplayName = 'Salesforce Administrator';
                String subject = so.getSObjectType() == Case.sObjectType ? 'Help Desk Case Deleted' : 'Asset Deleted';
                String plainTextBody = 'Type: ' + so.getSObjectType()
                        + '\nDeleted By: ' + UserInfo.getName();

                // Case specific content to include in email: subject, name of submitter
                if(so.getSObjectType() == Case.sObjectType) {
                    String createdByName = createdByMap.containsKey(String.valueOf(so.get('CreatedById'))) ? 
                            createdByMap.get(String.valueOf(so.get('CreatedById'))) : String.valueOf(so.get('CreatedById'));

                    plainTextBody += '\nCase Number: ' + so.get('CaseNumber')
                        + '\nSubject: ' + so.get('Subject')
                        + '\nCreated By: ' + createdByName;

                } else if(so.getSObjectType() == Asset__c.sObjectType) {
                    //cast to Asset__c, mostly for readability since there are many fields
                    Asset__c deletedAsset = (Asset__c) so;

                    String thisAssetClass = assetClassifications.containsKey(deletedAsset.Asset_Classification__c) ?
                            assetClassifications.get(deletedAsset.Asset_Classification__c).Name : deletedAsset.Asset_Classification__c;
                    plainTextBody += '\nAsset Number: ' + deletedAsset.Name
                        + '\nRecord Type: ' + RecordTypeUtil.findById(deletedAsset.RecordTypeId).Name
                        + '\nAsset Classification: ' + thisAssetClass
                        + '\nMake: ' + deletedAsset.Make__c
                        + '\nModel: ' + deletedAsset.Model__c
                        + '\nMAC Address:' + deletedAsset.MAC_Address__c
                        + '\nSerial Number: ' + deletedAsset.Serial_Number__c
                        + '\nLicense Number: ' + deletedAsset.License_Number__c
                        + '\nOffice: ' + deletedAsset.Office__c;

                }
                
                Messaging.SingleEmailMessage thisMail = EmailUtil.newEmailMessage(subject, null, senderDisplayName, 
                        toAddresses, null, plainTextBody, null);
                emailMessagesForSend.add(thisMail);           
            }

            if(emailMessagesForSend.size()  > 0) {
                EmailUtil.sendEmail(emailMessagesForSend);
            }
        } else {
            //if there are no email addresses in custom settings, send error email to primary org contact (in prod only)
                
            if(!GlobalUtil.isSandbox()) {

                // TODO change this to org primary contact
                String[] errorEmailAddress = new String[]{'mthomas@2u.com'};

                String errorMsgBody = 'Warning: Deletion notification emails cannot be sent.'
                    + '\nReason: No email addresses listed in the IT Email To Addresses custom setting.';
                Messaging.SingleEmailMessage errorMail = EmailUtil.newEmailMessage('Configuration Missing', 
                        null, 'Salesforce Administrator', errorEmailAddress, null, errorMsgBody, null);
                emailMessagesForSend.add(errorMail);

                if(emailMessagesForSend.size()  > 0) {
                    EmailUtil.sendEmail(emailMessagesForSend);
                }
            } 
            noEmailError = 'No emails sent';
            System.debug('**Print ' + noEmailError);
        }
		
	}
}