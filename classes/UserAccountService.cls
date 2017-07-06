@RestResource(urlMapping='/ems/v1/acct/*/info')
global with sharing class UserAccountService {

    @HttpGet
    global static ResponseContainer doGet() {
   		RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
 	String acctId = req.requestURI.substring(req.requestURI.indexOf('/acct')+5).substringBetween('/');  
   
        if (acctId == null || acctId == '' || EncodingUtil.urlDecode(acctId,'UTF-8').trim().length() < 1) {
            return new ResponseContainer('Account GUID not found in the request',400);
        }
        
        List<Account> accts = [SELECT Id FROM Account WHERE GUID__c  = :acctId];
        if (accts.size() < 1)
         return new ResponseContainer('No such account: ' + acctId,404);
        else if (accts.size() > 1)
         return new ResponseContainer('More than one account found: ' + acctId,404);
        try{
            Account acct = [SELECT AccountNumber,Active__c,AIMS_Number__c,AnnualRevenue,
            BillingAddress,BillingCity,BillingCountry,BillingPostalCode,BillingState,BillingStreet,
            Business_Unit_Key__c,Customer_Number__c,GUID__c,Id,PAES_Number__c 
            FROM Account 
            ORDER BY Name LIMIT 1];

           	return new ResponseContainer(acct);  
        }
        catch(Exception e){
			return new ResponseContainer(e.getMessage(),500);
        }


    }

    global class ResponseContainer {
        String message;
        Account acct;
    
      
        ResponseContainer(String message, Integer responseCode) {
            this.message = message;
            RestContext.response.statusCode = responseCode;
        }

        ResponseContainer(Account records){
            this.acct = records;
        }

    }

  
}