/**
@ name          LoginResult
@ author        Aslam Bari
@ date          17 July, 2011
@ description   contains the soap response data for login
*/
public class LoginResult{
    public boolean isError {get;set;}
    public string sessionId {get;set;}
    public string serverUrl {get;set;}
    public string message {get;set;}
    public LoginResult(){
        isError = false;
        sessionId = '';
        serverUrl = '';
        message = '';
    }
}