/**
@ name          SFXmlParser
@ author        Aslam Bari
@ date          17 July, 2011
@ description   contains the logic for parsing the sfdc soap query results and stores the 
                result in models
*/
public class SFXmlParser{   
    public Result parseXML(String xmlString, set<string> fields){
        SFXMLDom xmlDomObj = new SFXMLDom(xmlString);     
        
        List <SFXMLDom.Element> lstRecordElements = xmlDomObj.getElementsByTagName('records');
        Result res = new Result();
        res.fields = fields;
        for(SFXMLDom.Element  elementRecord: lstRecordElements){
            Record row = new Record();
            for(SFXMLDom.Element  childElementRecord: elementRecord.childNodes){            
                if(fields.contains(childElementRecord.nodeName.toLowerCase())){
                    row.fields.add(new Field(childElementRecord.nodeName, ChildElementRecord.nodeValue));
                }
            }
            res.records.add(row);
        }
        return res;
    }
}