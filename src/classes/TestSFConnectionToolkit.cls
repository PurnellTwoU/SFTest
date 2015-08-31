@isTest
private class TestSFConnectionToolkit{
    @isTest
    private static void testclasses(){
        SFConnectionController cont = new SFConnectionController();
        LoginResult loginResult = cont.login('test@aaa.com','test','');
        Response res = cont.query('select name, email, phone from contact', loginResult);
        Field fld = new Field('name','value');
        Record rc = new Record();
        rc.fields.add(fld);
        rc.getFieldValue('name');        
        SFConnectionDemoController demo = new SFConnectionDemoController();
        demo.username = 'test';
        demo.password = 'test';
        demo.securityToken = '';
        demo.search();
        SFConnectionUtility.getLoginSoapAction();
        SFConnectionUtility.getQuerySoapAction('test');
        SFConnectionUtility.getLoginSoapBody('test','test','');
        SFConnectionUtility.getQuerySoapBody('test','test');
        SFConnectionUtility.getFields('select id, name from contact');
        SFXmlParser parser = new SFXmlParser();
        set<string> flds = new set<string>();
        flds.add('id');
        flds.add('name');
        string xml = '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns="urn:partner.soap.sforce.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:sf="urn:sobject.partner.soap.sforce.com"><soapenv:Body><queryResponse><result xsi:type="QueryResult"><done>true</done><queryLocator xsi:nil="true"/><records xsi:type="sf:sObject"><sf:type>Contact</sf:type><sf:Id>00390000005oCcSAAU</sf:Id><sf:Id>00390000005oCcSAAU</sf:Id><sf:Name>Sean Forbes</sf:Name><sf:OwnerId>00590000000KRhTAAW</sf:OwnerId><sf:Email>sean@edge.com</sf:Email><sf:HomePhone xsi:nil="true"/><sf:MobilePhone> 4353454 </sf:MobilePhone></records></records><size>19</size></result></queryResponse></soapenv:Body></soapenv:Envelope>';
        parser.parseXml(xml,flds);
        SFXMLDom xmlDomObj = new SFXMLDom(xml);  
        xmlDomObj.getElementsByTagName('records');
        xmlDomObj.getElementByTagName('records');
        xmlDomObj.toXmlString();
    }

}