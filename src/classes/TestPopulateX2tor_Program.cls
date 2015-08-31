public class TestPopulateX2tor_Program{
    
    @IsTest
    public static void testPopulateMAT(){
        Case c1 = new Case( Origin = 'Email MAT');
        insert c1;
        Case insertedCase = [SELECT X2tor_Program__c FROM Case WHERE Id = :c1.Id];
        System.AssertEquals( 'MAT', insertedCase.X2tor_Program__c );
    }
    
    @IsTest
    public static void testPopulateMSW(){
        Case c2 = new Case( Origin = 'Email MSW');
        insert c2;
        Case insertedCase = [SELECT X2tor_Program__c FROM Case WHERE Id = :c2.Id];
        System.AssertEquals( 'MSW', insertedCase.X2tor_Program__c );
    }
    
    @IsTest
    public static void testPopulateMSN(){
        Case c3 = new Case( Origin = 'Email MSN');
        insert c3;
        Case insertedCase = [SELECT X2tor_Program__c FROM Case WHERE Id = :c3.Id];
        System.AssertEquals( 'MSN', insertedCase.X2tor_Program__c );
    }
    
    @IsTest
    public static void testPopulateMBA(){
        Case c4 = new Case( Origin = 'Email MBA');
        insert c4;
        Case insertedCase = [SELECT X2tor_Program__c FROM Case WHERE Id = :c4.Id];
        System.AssertEquals( 'MBA', insertedCase.X2tor_Program__c );
    }
    
    @IsTest
    public static void testPopulateCRM(){
        Case c5 = new Case( Origin = 'Email crm@');
        insert c5;
        Case insertedCase = [SELECT X2tor_Program__c FROM Case WHERE Id = :c5.Id];
        System.AssertEquals( 'MAT;MSW;MSN;MBA;MPA;LLM', insertedCase.X2tor_Program__c );
    }
    
    @IsTest
    public static void testPopulateMPA(){
        Case c6 = new Case( Origin = 'Email MPA');
        insert c6;
        Case insertedCase = [SELECT X2tor_Program__c FROM Case WHERE Id = :c6.Id];
        System.AssertEquals( 'MPA', insertedCase.X2tor_Program__c );
    }
    
    @IsTest
    public static void testPopulateLLM(){
        Case c7 = new Case( Origin = 'Email LLM');
        insert c7;
        Case insertedCase = [SELECT X2tor_Program__c FROM Case WHERE Id = :c7.Id];
        System.AssertEquals( 'LLM', insertedCase.X2tor_Program__c );
    }
    
    @IsTest
    public static void testPopulateHub(){
        Case c8 = new Case( Origin = 'Email Hub');
        insert c8;
        Case insertedCase = [SELECT X2tor_Program__c FROM Case WHERE Id = :c8.Id];
        System.AssertEquals( 'Hub', insertedCase.X2tor_Program__c );
        
    }
}