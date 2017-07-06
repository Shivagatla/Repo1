@RestResource(urlMapping='/ems/v1/user/*/app/*/fineents')
global with sharing class UserFineEntService {

    @HttpGet
    global static ResponseContainer doGet() {
   		RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
 	String userId = req.requestURI.substring(req.requestURI.indexOf('/user')+5).substringBetween('/');  
    String appcode = req.requestURI.substring(req.requestURI.indexOf('/app')+4).substringBetween('/'); 
        if (userId == null || userId == '' || EncodingUtil.urlDecode(userId,'UTF-8').trim().length() < 1) {
            return new ResponseContainer('User ID not found in the request',400);
        }
        
        List<User> users = [SELECT Id FROM User WHERE Ag2Ag_ID__c = :userId];
        if (users.size() < 1)
         return new ResponseContainer('No such user: ' + userId,404);
        else if (users.size() > 1)
         return new ResponseContainer('More than one user found: ' + userId,404);
        try{

            ApplicationHelper ah = new ApplicationHelper(appcode,true);

            List<Account> accts = ah.getProvisionedFEnts(users[0].Id);

            List<FineEnt> ents = new List<FineEnt>();
            for (Account acct:accts){
                String fieldName = ah.getAcctFieldName();
                if (fieldName.equalsIgnoreCase('GUID__C'))
                    ents.add(new FineEnt(userId,appcode,acct.GUID__c));
                else if (fieldName.equalsIgnoreCase('Customer_Number__c'))
                    ents.add(new FineEnt(userId,appcode,acct.Customer_Number__c)); 
                else if (fieldName.equalsIgnoreCase('PAES_Number__c'))
                    ents.add(new FineEnt(userId,appcode,acct.PAES_Number__c)); 
                else if (fieldName.equalsIgnoreCase('AIMS_Number__c'))
                    ents.add(new FineEnt(userId,appcode,acct.AIMS_Number__c)); 


            }


          	return new ResponseContainer(ents);  
        }
        catch(Exception e){
			return new ResponseContainer(e.getMessage(),500);
        }


    }

    global class ResponseContainer {
        String message;

        List<FineEnt> fineEnts;
    
     
       
        ResponseContainer(String message, Integer responseCode) {
            this.message = message;
            RestContext.response.statusCode = responseCode;
        }

        ResponseContainer(List<FineEnt> records){
            this.fineEnts = records;
        }

    }

    global class FineEnt {
        String ag2ag;
        String appcode;
        String acctguid;

        FineEnt(String ag2ag, String appcode, String acctguid){
            this.ag2ag = ag2ag;
            this.appcode = appcode;
            this.acctguid = acctguid;
        }
    }
}