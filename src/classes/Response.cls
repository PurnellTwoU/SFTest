/**
@ name          Response
@ author        Aslam Bari
@ date          17 July, 2011
@ description   contains the soap response for fetched query request
*/
public class Response{
    public string result {get;set;}
    public string status {get;set;}
    public integer statusCode {get;set;}
    public Result data {get;set;}
    public boolean isError {get;set;}
    public string message {get;set;}
    
    public Response(){
        isError = false;
        result = '';
        status = '';
        message = '';
        statusCode = 0;
        data = new Result();
    }
}