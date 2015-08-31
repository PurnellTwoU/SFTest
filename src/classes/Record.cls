/**
@ name          Record
@ author        Aslam Bari
@ date          17 July, 2011
@ description   contains the one row for fetched query
*/
public class Record{
    public List<Field> fields {get;set;}
    public Record(){
        fields = new List<Field>();
    }
    public string getFieldValue(string fieldName){
        for(Field fld: fields){
            if(fld.name.toLowerCase() == fieldName.toLowerCase()){
                return fld.value;
            }
        }
        return '';
    }
}