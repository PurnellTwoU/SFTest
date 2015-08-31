/*
 * @description Generic email utility class which can be used to send emails with or without attachments.
 *              Should be deployed across all orgs.
 *              Unit test: TestEmailUtil
 */
public class EmailUtil {
    /*
     * @param String email subject
     * @param String replyTo email
     * @param String senderDisplayName
     */
	public static Messaging.SingleEmailMessage newEmailMessage(String subject, String replyEmail, String senderDisplayName,
            String[] toAddresses, String[] ccAddresses, String plainTextBody, List<Attachment> attachments) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject(subject);
        mail.setReplyTo(replyEmail);
        mail.setSenderDisplayName(senderDisplayName);
        mail.setToAddresses(toAddresses);
        mail.setCcAddresses(ccAddresses);
        mail.setPlainTextBody(plainTextBody);
        if (attachments != null) {
            if (attachments.size() > 0) {
                mail.setFileAttachments(buildFileAttachments(attachments));
            }    
        }
        return mail;
    }

    public static void sendEmail(List<Messaging.SingleEmailMessage> emailMessagesForSend) {
        if(emailMessagesForSend.size() > 0) {
            List<Messaging.SendEmailResult> sendResults = Messaging.sendEmail(emailMessagesForSend);

            // Loop through results to log errors
            for(Messaging.SendEmailResult m : sendResults) {
                if(!m.isSuccess()) {
                    System.debug('**Print email error: + ' + m.getErrors());
                    //TODO log errors to error obj
                }
            }
        }
    }

    /*
     * @param List of email attachment objects
     */
    public static List<Messaging.EmailFileAttachment> buildFileAttachments(List<Attachment> attachmentList) {
        // return List of email attachments from list of attachments
        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
    
        for (Attachment thisAttachment : attachmentList) {
            Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
            fileAttachment.setBody(thisAttachment.Body);
            fileAttachment.setFileName(thisAttachment.Name);
            emailAttachments.add(fileAttachment);
        }
        return emailAttachments;
    }
}