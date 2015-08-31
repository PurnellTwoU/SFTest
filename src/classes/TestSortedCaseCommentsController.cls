@isTest
private class TestSortedCaseCommentsController{

    @isTest
    public static void testGetF(){
        SortedCaseCommentsController testController = new SortedCaseCommentsController();
        
        //Test for f is null;
        testController.f = null;
        Integer resultF = testController.getF();
        system.assertEquals( resultF, 0 );
        
        //Test for f is not null;
        testController.f = 5;
        resultF = testController.getF();
        system.assertEquals( resultF, 5 );  
    }
    
    @isTest
    public static void testGetR(){
        SortedCaseCommentsController testController = new SortedCaseCommentsController();
        
        //Test for r is null
        testController.r = null;
        Integer resultR = testController.getR();
        system.assertEquals( resultR, 1000 );
        
        //Test for r is not null
        testController.r = 5;
        resultR = testController.getR();
        system.assertEquals( resultR, 5 );
    }
    
    @isTest
    public static void testGetSorted(){
        SortedCaseCommentsController testController = new SortedCaseCommentsController();
        
        Case testCase = new Case(Subject='TestCase', Status='New', Origin='Email MAT');
        insert testCase;
        
        
        CaseComment comment1 = new CaseComment(CommentBody='Test1', ParentID = testCase.ID,IsPublished=True);
        insert comment1;
        
        CaseComment comment2 = new CaseComment(CommentBody='Test2', ParentID = testCase.ID,IsPublished=True);
        insert comment2;
        
        testController.c = null;
        List<CaseComment> results = testController.getSorted();
        system.assertEquals( null, results );
        
        testController.c = testCase;        
        testController.sortDescending = True;
        testController.hidePrivate = True;
        
        results = testController.getSorted();
        
        system.assertEquals( 2, results.size() );
        
        testController.c = testCase;
        testController.sortDescending = null;
        testController.hidePrivate = null;
        
        results = testController.getSorted();
        
        system.assertEquals( 2, results.size() );
        
        
        testController.sortDescending = true;
        testController.hidePrivate = false;
        results = testController.getSorted();
        system.assertEquals( 2, results.size() );
        
        testController.sortDescending = false;
        testController.hidePrivate = true;
        results = testController.getSorted();
        system.assertEquals( 2, results.size() );
        
    }

}