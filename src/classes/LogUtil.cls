/** 
 * @description Log method is overloaded 4 times in this class in order to be help with a variety  
 *              exception and message logging situations.
 *              Class can be called from exception catch statements in any class and will log the
 *              exception in the Error_Message__c object.
 *              Alternate use is to log email failures, logging outbound/inbound soap/rest messages
 *              or any other kind of generic logging.
 * Unit Test Coverage: TestLogUtil
 */
public without sharing class LogUtil {
    /**
     * Exception logging method with (optional) list of related object ids
     * @param String dot qualified class name and method
     * @param Exception object
     * @param List of related ids in string format
     * @param String any notes passed by developer when catching exception
     * @return Error_Log__c id or null
     */
    public static Id log(String classMethod, Exception e, List<String> relatedIds, String devNotes) {
        Error_Log__c logEntry = new Error_Log__c(
            Type__c = 'Exception',
            Developer_Notes__c = devNotes,
            Object_Ids__c = GlobalUtil.listToString(relatedIds),
            Error_Message__c = e.getMessage(),
            Exception_Type__c = e.getTypeName(),
            Stack_Trace__c = e.getStackTraceString(),
            Line_Number__c = e.getLineNumber(),
            Failed_DML_Rows__c = (isExceptionDMLEmail(e) ? e.getNumDml() : 0));
        return insertLog(logEntry, classMethod);
    }

    /**
     * Basic message logging with (optional) list of related object id strings
     * @param String dot qualified class name and method
     * @param String value of email message or error message
     * @param List of related ids in string format
     * @return Error_Log__c id or null
     */
    public static Id log(String classMethod, String message, List<String> relatedIds) {
        Error_Log__c logEntry = new Error_Log__c(
            Type__c = 'Message',
            Error_Message__c = message,
            Object_Ids__c = GlobalUtil.listToString(relatedIds));
        return insertLog(logEntry, classMethod);
    }

    /**
     * Task-specific logging to allow us to log exceptions with what and who ids
     * @param String dot qualified class name and method
     * @param Exception object
     * @param String of comma delimited WhatIds (from Task obj)
     * @param String of comma delimited WhoIds (from Task obj)
     * @return Error_Log__c id or null
     */
    public static Id log(String classMethod, Exception e, String whatIds, String whoIds) {
        Error_Log__c logEntry = new Error_Log__c(
            Type__c = 'Exception',
            WhatIds__c = whatIds,
            WhoIds__c = whoIds,
            Error_Message__c = e.getMessage(),
            Exception_Type__c = e.getTypeName(),
            Stack_Trace__c = e.getStackTraceString(),
            Line_Number__c = e.getLineNumber(),
            Failed_DML_Rows__c = (isExceptionDMLEmail(e) ? e.getNumDml() : 0));
        return insertLog(logEntry, classMethod);
    }

    /**
     * Task-specific logging to allow us to log basic messages with what and who ids
     * @param String dot qualified class name and method
     * @param String value of email message or error message
     * @param String of comma delimited WhatIds (from Task obj)
     * @param String of comma delimited WhoIds (from Task obj)
     * @return Error_Log__c id or null
     */
    public static Id log(String classMethod, String message, String whatIds, String whoIds) {
        Error_Log__c logEntry = new Error_Log__c(
            Type__c = 'Message',
            Error_Message__c = message,
            WhatIds__c = whatIds,
            WhoIds__c = whoIds);
        return insertLog(logEntry, classMethod);
    }

    /**
     * Return true of the exception is a dml or email exception, else return false
     */
    private static Boolean isExceptionDMLEmail(Exception e) {
        return (e instanceof System.DmlException || e instanceof System.EmailException);        
    }

    /**
     * Inserts error log record.  Called by each of the 4 overloaded log methods.
     * @param Error_Log__c object reference
     * @param String dot qualified class name and method
     * @param String any notes passed by the developer
     * @return Error_Log__c id or null
     */
    private static Id insertLog(Error_Log__c logEntry, String classMethod) {
        if(logEntry != null) {
            logEntry.Class_Method__c = classMethod;
            logEntry.Running_User__c = UserInfo.getUserId();
            logEntry.DML_Rows__c = Limits.getDmlRows();
            logEntry.Limits_DML_Rows__c = Limits.getLimitDMLRows();
            logEntry.Queries__c = Limits.getQueries();
            logEntry.Limits_Queries__c = Limits.getLimitQueries();
            logEntry.Script_Statements__c = Limits.getScriptStatements();
            logEntry.Limits_Script_Statements__c = Limits.getLimitScriptStatements();
            logEntry.Query_Rows__c = Limits.getQueryRows();
            logEntry.Limits_Query_Rows__c = Limits.getLimitQueryRows();
            logEntry.Heap_Size__c = Limits.getHeapSize();
            logEntry.Limits_Heap_Size__c = Limits.getLimitHeapSize();

            Database.DMLOptions options = new Database.DMLOptions();
            options.allowFieldTruncation = true;
            Database.insert(new SObject[] { logEntry }, options);
            return logEntry.Id;
        } else {
            return null;
        }
    }
}