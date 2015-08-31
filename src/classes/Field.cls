/**
@ name          Field
@ author        Aslam Bari
@ date          17 July, 2011
@ description   contains the field name and its value
*/
public class Field{
    public string name {get;set;}
    public string value {get;set;}
    
    public Field(string name, string value){
        this.name = name;
        this.value = value;
    }    
}