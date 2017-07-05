//Initial Version: Deb Volk
//Modification Log: Request for others- Ag2Ag id is should not be null

public class EMSRequest {
    
    
    public Id connectedApp {get;set;}
    public String notes {get;set;}
    public List<UserProvisioningRequest> requests{get;set;}
    public Id curUser {get;set;}
    public String comments {get;set;}
    public integer requestFor {get;set;}
    public Id requestUser {get;set;}
    public list<SelectOption> items;
    public list<SelectOption> users;
    public boolean submitted {get;set;}
    
    public UserProvisioningRequest upr{get;set;}
    public Contact requestedUser{get;set;}
    public boolean migrated {get;set;}

    
    
    public EMSRequest(){
        curUser = UserInfo.getUserId();
        requests = [SELECT AppName,ApprovalStatus,ConnectedAppId,CreatedById,CreatedDate,ExternalUserId,Id,IsDeleted,
            LastModifiedById,LastModifiedDate,ManagerId,Name,Operation,
            OwnerId,Responsible_Rule__c,SalesforceUserId,ScheduleDate,State,SystemModstamp,UserProvAccountId,
            UserProvConfigId FROM UserProvisioningRequest WHERE SalesforceUserId =:curUser];
        requestUser = UserInfo.getUserId();
        requestFor = 1;
        submitted=false;
        requesteduser = new Contact();
    }
    
    
    public Boolean showList(){
        
        return false;
    }    
    public PageReference createRequest(){
        try{
            //List<User> reqUsers = [Select Id,Username,External_Fed_Id__c,FirstName,LastName,Email,Ag2Ag_ID__c from User where Id = :requestedUser.Related_External_User__c];
            List<User> reqUsers = [Select Id,Username,External_Fed_Id__c,FirstName,LastName,Email,Ag2Ag_ID__c from User where Id = :requestedUser.Related_External_User__c and Ag2Ag_ID__c != null];            
            User reqUser = null;
            if (reqUsers.size() != 1){
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Your request was unable to be processed at this time.  Please try again later.');
                ApexPages.addMessage(msg);
                return null;
                
            }
            else {
                reqUser = reqUsers.get(0); 
            }
            ApplicationHelper ah = new ApplicationHelper(connectedApp);
            migrated = Boolean.valueOf(ah.getApplication().Migrated__c);
            if (!Boolean.valueOf(ah.getApplication().Migrated__c)) {
                        UserProvisioningService ups = new UserProvisioningService();
                        ups.entitleUser(reqUser,ah.getApplication(),null);    
                         ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'Your request has been submitted.  Please check the Green Screens for more information.');
                ApexPages.addMessage(msg);
            }         
            else {
                 ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'Your request has been submitted.  Please check the pending UPRs for more information.  It may take a moment to be created.');
            ApexPages.addMessage(msg);
                ID jobID = System.enqueueJob(new EMSCreateUPRQueueable(ah.getApplication(),reqUser,comments,UserInfo.getName()));
            }
        
          
        
        }
        catch(Exception e){
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Your request was unable to be processed at this time.  Please try again later.');
            ApexPages.addMessage(msg);
          
        }
        requesteduser = new Contact();
        connectedApp = null;
        return null;  
    } 
    
    
    
    
    public PageReference cancel(){
        
        comments = '';
        submitted=false;
        return null;
    }
    
    public List<SelectOption> getItems(){
        List<SelectOption> plValues = new List<SelectOption>();
        try{
            ApplicationHelper ah = new ApplicationHelper();
            List<Application__c> apps = (requestedUser.Related_External_User__c!=null)?ah.getAvailableSFApps(requestedUser.Related_External_User__c,true):ah.getAvailableSFApps(curUser, true);
            for (Application__c app : apps) {
                // plValues.add(new SelectOption(value, label, isDisabled));
                plValues.add(new SelectOption(app.Connected_App_ID__c,app.Name, false));
                
            }
        }
        catch(Exception e){
            
        }
        return plValues;
    }
    
    public List<SelectOption> getUsers(){
        List<SelectOption> plValues = new List<SelectOption>();
        List<User> users = [SELECT Id, Username,FirstName, LastName FROM User where isActive=true];
        for (User us : users) {
            
            plValues.add(new SelectOption(us.Id,us.FirstName + ' '+ us.LastName, false));
            
        }
        
        return plValues;
    }
    
    public PageReference trackRequest(){
        Id requestId = [Select Id from UserProvisioningRequest where SalesforceUserId=:requestedUser.Related_External_User__c and ConnectedAppId=:connectedApp and state='New' Limit 1].Id;
           PageReference requestpage = new PageReference('/' + requestId);
        requestpage.setRedirect(true);
        return requestpage;
      
    }
}