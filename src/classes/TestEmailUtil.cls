/**
 * Provides test coverage for EmailUtil global class (deployed across multiple orgs)
 */
@isTest 
private class TestEmailUtil {
    private static testmethod void testEmailUtil() {
        List<Messaging.SingleEmailMessage> emailMessagesForSend = new List<Messaging.SingleEmailMessage>(); 

        List<Attachment> testAttachments = new List<Attachment>();

        String subject = 'test subject';
        String replyEmail = 'test@test.com';
        String senderDisplayName = 'Unit Tester';
        String plainTextBody = 'Plain text \n tester';

        TestGlobalUtil.createAccounts();
        if(TestGlobalUtil.testAccounts.size() > 0) {
            for(Integer i = 0; i < 3; i++) {
                Attachment testAttachment = new Attachment();
                testAttachment.ParentId = TestGlobalUtil.testAccounts.get(0).Id;
                testAttachment.Body = Blob.valueOf('Some Text');
                testAttachment.Description = 'Test Description';
                testAttachment.Name = 'Test' + i + '.txt';
          
                testAttachments.add(testAttachment);
            } 
            insert testAttachments;
        }
        
        // Verify that buildFileAttachments returns a list of email attachments
        System.assert(EmailUtil.buildFileAttachments(testAttachments).size() > 0);

        Messaging.SingleEmailMessage testMessage = EmailUtil.newEmailMessage(subject, replyEmail, senderDisplayName,
            new String[]{'test@test.com'}, new String[]{'test@test.com'}, plainTextBody, testAttachments);

        // Verify that test message was created
        System.assert(testMessage != null);

        emailMessagesForSend.add(testMessage);

        System.assert(emailMessagesForSend.size() > 0);
        
        EmailUtil.sendEmail(emailMessagesForSend);
        
    }
}