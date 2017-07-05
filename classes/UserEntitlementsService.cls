@RestResource(urlMapping='/ems/v1/user/*/apps')
global with sharing class UserEntitlementsService {

    @HttpGet
    global static ResponseContainer doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
      
        String userId = req.requestURI.substring(req.requestURI.indexOf('/user')+5).substringBetween('/');  
        if (userId == null || userId == '' || EncodingUtil.urlDecode(userId,'UTF-8').trim().length() < 1) {
            return new ResponseContainer('User ID not found in the request',400);
        }
        
        List<User> users = [SELECT Id FROM User WHERE Ag2Ag_ID__c = :userId];
        if (users.size() < 1)
         return new ResponseContainer('No such user: ' + userId,404);
        else if (users.size() > 1)
         return new ResponseContainer('More than one user found: ' + userId,404);
        
               
        try {
            List<UserProvAccount> connectedApps = 
                [SELECT ConnectedAppId 
                FROM UserProvAccount 
                WHERE SalesforceUserId IN (SELECT Id FROM User WHERE Ag2Ag_ID__c = :userId) and status='Active'];
                
            Set<Id> connectedAppIDs = new Set<Id>();
            for (UserProvAccount connectedApp: connectedApps ) {
                connectedAppIDs.add(connectedApp.ConnectedAppId);
            }
            
            List<Application__c> apps = 
                    [SELECT Name, Description__c, App_Code__c, App_Portal_URL__c, App_URL__c, Home_Page__c 
                    FROM Application__c 
                    WHERE Connected_App_ID__c IN :connectedAppIDs
                    ORDER BY Name];
                    
            return new ResponseContainer(apps);  
        }
        catch (Exception e) {
            return new ResponseContainer(e.getMessage(),500);
        }                
    }
    
    global class ResponseContainer {
        String message;
        List<Application__c> apps;
    
     
        ResponseContainer(List<Application__c> records) {
            this.apps = records;
        }
        
        ResponseContainer(String message, Integer responseCode) {
            this.message = message;
            RestContext.response.statusCode = responseCode;
        }
    }
}