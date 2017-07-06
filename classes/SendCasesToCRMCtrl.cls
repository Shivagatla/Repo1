public Class SendCasesToCRMCtrl{
    @TestVisible
    private static String oauth;
    
    public class EMSCaseObject{
        Public String Id;Public String RetailerName;Public String RetailerCustomerNo;Public String RetailerCity;Public String RetailerState;Public String GrowerName;
        Public String GrowerPhone;Public String GrowerEmail;Public String GrowerAg2AgId;Public String ContactName;Public String Status;Public String Origin;
        Public String CaseNumber;Public String Description;Public String Priority;Public Boolean isAgTechSigned;
        
        public EMSCaseObject(String Id,String RetailerName,String RetailerCustomerNo,String RetailerCity,String RetailerState,String GrowerName
        ,String GrowerPhone,String GrowerEmail,String GrowerAg2AgId,String ContactName,String Status,String Origin
        ,String CaseNumber,String Description,String Priority,Boolean isAgTechSigned){
            this.Id=Id;this.RetailerName=RetailerName;this.RetailerCustomerNo=RetailerCustomerNo;this.RetailerCity=RetailerCity;this.RetailerState=RetailerState;this.GrowerName=GrowerName;
            this.GrowerPhone=GrowerPhone;this.GrowerEmail=GrowerEmail;this.GrowerAg2AgId=GrowerAg2AgId;this.ContactName=ContactName;this.Status=Status;this.Origin=Origin;
            this.CaseNumber=CaseNumber;this.Description=Description;this.Priority=Priority;this.isAgTechSigned=isAgTechSigned;
        }
    }
    
    public Class JsonResponse{
        public String access_token;public String instance_url;public String id;public String token_type;public String issued_at;public String signature;
    }
    
    public static String oauthLogin(){
        CalloutSettings__c callOut = CalloutSettings__c.getValues('Focus');
        HttpRequest req = new HttpRequest();        
        req.setMethod('POST');
        req.setEndpoint(callOut.Salesforce_Instance__c+'/services/oauth2/token');
        req.setBody('grant_type=password' +
            '&client_id=' + callOut.Customer_Key__c +
            '&client_secret=' + callOut.Customer_Secret_Key__c +
            '&username=' + callOut.Username__c +
            '&password=' + callOut.Password__c);
    
        Http http = new Http();
        
        if(!Test.isRunningTest()){
            HTTPResponse res = http.send(req);    
            return JSON.serializePretty(res.getBody());
        }
        else
        {
            return oauth;
        }        
    }
    
    public static String sendCasesList(List<Case> caseList) {
        List<EMSCaseObject> listOfEMSCases = new List<EMSCaseObject>();
    
        oauth = oauthLogin();
        String jsonStr = oauth.substring(1, oauth.length() - 1).replace('\\', '');
        JsonResponse jres = (JsonResponse) System.JSON.deserialize(jsonStr, JsonResponse.class);
        
        for(Case c : caseList){
            listOfEMSCases.add(new EMSCaseObject(c.Id,c.Contact.Account.Name, c.Contact.Account.Customer_Number__c, c.Contact.Account.BillingCity, c.Contact.Account.BillingState, 
            c.Related_External_User__r.Name, c.Related_External_User__r.Phone, c.Related_External_User__r.Email, 
            c.Related_External_User__r.Ag2Ag_ID__c, c.Contact.Name, c.Status, c.Origin, c.CaseNumber, c.Description, 
            c.Priority,c.Ag_Tech_Agreement__c));
        }
        
        String jsonString = JSON.serializePretty(listOfEMSCases);

        HttpRequest req = new HttpRequest(); 
 
        req.setMethod('POST');
        req.setEndpoint(jres.instance_url+'/services/apexrest/SendCasesToCRM');
        req.setHeader('Authorization', 'OAuth '+jres.access_token);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonString);

        Http http = new Http();
        
        if(!Test.isRunningTest()){
            HTTPResponse res = http.send(req);
            return res.getBody();
        }
        return 'Success';
    }
}