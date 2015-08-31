/**
@ name          Result
@ author        Aslam Bari
@ date          17 July, 2011
@ description   contains the results by query the soap query to sfdc instance
*/
public class Result{
    public List<Record> records{get;set;}
    public Set<string> fields {get;set;}
    public Result(){
        records = new List<Record>();
        fields = new Set<string>();
    }    
}