public class SortedCaseCommentsController{
    public Case c { get; set; } //The case specified by 'value' in the custom component.
    public Boolean sortDescending { get; set; } //If true comments are sorted in descending order by 'CreatedDate'
    public Boolean hidePrivate { get; set; } //If true non-public comments are not included in the returned list of comments.
    public Integer f { get; set; } //An integer indicating on which item in the list repeat should start on.
    public Integer r { get; set; } //An integer indicating how many items to display.
    
    //This method gets a sorted list of comments associated with the given case.
    public CaseComment[] getSorted(){
        Set<Id> ccIds = new Set<Id>(); //This will contain all the IDs of comments associated with the given case.
        
        //Checks to see if the case or the case's comments are null to avoid a null pointer exception
        if (c == null || c.caseComments == null){
            return null;
        }
        
        //Ensures that sortDescending has a value. This allows sortDescending to be false by default.
        if (sortDescending == null){
            sortDescending = false;
        }
        
        //Ensures that hidePrivate has a value. This allows hidePrivate to be false by default.
        if (hidePrivate == null){
            hidePrivate = false;
        }
       
       if(c.CaseComments.size() == 0)
        {
            //For test class and other apex executions the CaseComments are explicitly retrieved from SOQL.
            List<Case> caseList = [select Id, (select Id from CaseComments) from Case where Id =: c.Id];      
            if(caseList.size() > 0)
            {
                Case Case1 = caseList.get(0);
                //Populates the set of IDs associated with the given case. 
                for (CaseComment item : Case1.CaseComments){
                    ccIds.add(item.Id);
                }
            }
        }
        else
        {
        //Populates the set of IDs associated with the given case. 
            for (CaseComment item : c.CaseComments){
                ccIds.add(item.Id);
            }
        }
        
        //Checks if the comments should be sorted in ascending or descending order.
        if (sortDescending){
            //Checks whether public comments should be displayed.
            if(hidePrivate){
                return [SELECT commentBody, createdDate, createdBy.name, isPublished FROM CaseComment WHERE Id in : ccIds AND IsPublished = True order by createdDate desc];
            }
            else{
                return [SELECT commentBody, createdDate, createdBy.name, isPublished FROM CaseComment WHERE Id in : ccIds order by createdDate desc];
            }
        }
        else{
            //Checks whether public comments should be displayed.
            if (hidePrivate){
                return [SELECT commentBody, createdDate, createdBy.name, isPublished FROM CaseComment WHERE Id in : ccIds AND IsPublished = True order by createdDate asc];
            }
            else{
                return [SELECT commentBody, createdDate, createdBy.name, isPublished FROM CaseComment WHERE Id in : ccIds order by createdDate asc];
            }
        }
    }
    
    //Ensures f is not null and passes it back to <apex:repeat> in the custom component
    public Integer getF(){
        if ( f == null){
            return 0;
        }
        else{
            return f;
        }
    }
    
    //Ensures r is not null and passes it back to <apex:repeat> in the custom component
    public Integer getR(){
        if ( r == null){
            return 1000; //This is the maximum number of repeates allowed by <apex:repeat>
        }
        else{
            return r;
        }
    }
}