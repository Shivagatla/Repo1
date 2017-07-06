public without sharing class EMS_DA_UserList {
    
    public EMS_DA_UserList() {
    }
    
    public PageReference redir() {
        String JobClassification = [Select JobClassification__c From User Where Id =: UserInfo.getUserId()][0].JobClassification__c;
        if (JobClassification != null && JobClassification.equalsIgnoreCase('Farmer')) {
            PageReference newPage = new PageReference('/ems/EMSProfilePage');
            return newPage;
        }
        return null;
    }
    
    public Class AccessWrapper{
        public String fullName{get;set;}
        public String businessLinkId{get;set;}
        public String userId{get;set;}
        public String applicationName{get;set;}
        public String appcode{get;set;}
        public String roleEnts{get;set;}
        public String accountEnts{get;set;}
        public AccessWrapper(String fn, String blid, String useridIn, String appname, String appcodeIn, String  roleEntsIn, String acctEntsIn){
            fullname = fn;
            businessLinkId = blid;  
            userId = useridIn;
            applicationName = appName;
            appCode = appcodeIn;
            roleEnts = roleEntsIn;
            accountEnts = acctEntsIn;      
        }
    }
    
      public Class UserWrapper{
      public User userInfo{get;set;}
      public String accountName{get;set;}
      public String accountGUID{get;set;}
      public UserWrapper(User u, String aName, String aGUID){
        userInfo = u;
        accountName = aName;
        accountGUID = aGUID;
      }
    }
    
     public List<UserWrapper> getAllUsers(){
        Set<Id> acctIds = new Set<Id>();
        for(UserProvFineEntitlement__c upfe: [SELECT Entitled_Account__c,ParentApp__c,Related_SF_User__c,UPA_Parent__c 
                                                  FROM UserProvFineEntitlement__c
                                                  WHERE UPA_Parent__r.Status = 'Active' and 
                                                  ParentApp__r.app_code__c = :EMSConstants.DELEGATED_ADMIN_APPCODE 
                                                  and Related_SF_User__c =: UserInfo.getUserId()]){
            acctIds.add(upfe.Entitled_Account__c);
        }
        
        System.debug('the number of account is: ' + acctIds.size() + ' and they are: ' + acctIds);

        List<UserWrapper> uw = new List<UserWrapper>();
        for (User u: [SELECT FirstName, LastName,IsActive,Ag2Ag_ID__c,JobClassification__c,Contact.Account.Name,Contact.Account.GUID__C,Account.Name,Account.GUID__c FROM User 
                WHERE AccountId in :acctIds ORDER By LastName LIMIT 1000]){
          uw.add(new UserWrapper(u,u.Account.Name,u.Account.GUID__c));
        }
        return uw;
    }
    
    public List<AccessWrapper> getGrantedAccessForAllUsers(){
    
        Set<Id> acctIds = new Set<Id>();
        for(UserProvFineEntitlement__c upfe: [SELECT Entitled_Account__c,ParentApp__c,Related_SF_User__c,UPA_Parent__c 
                                                  FROM UserProvFineEntitlement__c
                                                  WHERE UPA_Parent__r.Status = 'Active' and 
                                                  ParentApp__r.app_code__c = :EMSConstants.DELEGATED_ADMIN_APPCODE 
                                                  and Related_SF_User__c =: UserInfo.getUserId()]){
            acctIds.add(upfe.Entitled_Account__c);
        }

        
        List<AccessWrapper> aws = new List<AccessWrapper>();
        Map<Id,User> userMap = new Map<Id,User>([SELECT Id FROM User WHERE IsActive = true and AccountId in :acctIds LIMIT 1000]);
        
        Map<String,Application__c> appMap = new Map<String,Application__c>();
        for(Application__c app:[SELEcT Id, Name,App_Code__c,Connected_App_Id__c from Application__c where System_Application__c=:false]){
            appMap.put(app.Connected_App_Id__c,app);
        }
        List<UserProvAccount> upas = [SELECT Id,ConnectedAppId,SalesforceUser.FirstName, SalesforceUser.LastName,
                                      SalesforceUserId,SalesforceUser.Ag2Ag_ID__c,
                                      (Select Entitlement_Code__r.Name from User_Provision_Entitlements__r),
                                      (Select Entitled_Account__r.Name,Entitled_Account__r.GUID__c FROM Fine_Grained_Entitlements__r)
                                      FROM UserProvAccount 
                                      WHERE SalesforceUserId in :userMap.keySet() and Status='Active' LIMIT 1000];
        
        for (UserProvAccount upa:upas){
            if(upa.ConnectedAppId != null && appMap.get(upa.ConnectedAppId) != null){
                aws.add(new AccessWrapper(upa.SalesforceUser.LastName+Constants.COMMA+Constants.SPACE+upa.SalesforceUser.FirstName,upa.SalesforceUser.Ag2Ag_ID__c,upa.SalesforceUserId,
                                          appMap.get(upa.ConnectedAppId).Name,
                                          appMap.get(upa.ConnectedAppId).App_Code__c,
                                          getRoleDisplay(upa.User_Provision_Entitlements__r),
                                          getAccountDisplay(upa.Fine_Grained_Entitlements__r)
                                         ));
            }
        }
        return aws;
    }
    
    public List<UserProvisioningRequest> getPendingRequests(){
        Set<Id> acctIds = new Set<Id>();
        for(UserProvFineEntitlement__c upfe: [SELECT Entitled_Account__c,ParentApp__c,Related_SF_User__c,UPA_Parent__c 
                                                  FROM UserProvFineEntitlement__c
                                                  WHERE UPA_Parent__r.Status = 'Active' and 
                                                  ParentApp__r.app_code__c = :EMSConstants.DELEGATED_ADMIN_APPCODE 
                                                  and Related_SF_User__c =: UserInfo.getUserId()]){
            acctIds.add(upfe.Entitled_Account__c);
        }

        List<AccessWrapper> aws = new List<AccessWrapper>();
        Map<Id,User> userMap = new Map<Id,User>([SELECT Id FROM User WHERE IsActive = true and AccountId in :acctIds LIMIT 1000]);
        
        return [SELECT Id,Name,Delegated_Admin__c,Delegated_admin_2__c,Current_step__c,SalesforceUser.FirstName,SalesforceUser.LastName,SalesforceuserId,AppName,
                CreatedDate,CreatedBy.Name,ConnectedAppId,Operation from UserProvisioningRequest where SalesforceUserId in :userMap.keySet() and ApprovalStatus='Required' LIMIT 1000];
    }
    
    @RemoteAction
    public static String inactivateuser(String userId){

      if (userId == UserInfo.getUserId()){
        return 'User cannot inactivate themselves.';
      }
        Set<Id> acctIds = new Set<Id>();
        for(UserProvFineEntitlement__c upfe: [SELECT Entitled_Account__c,ParentApp__c,Related_SF_User__c,UPA_Parent__c 
                                                  FROM UserProvFineEntitlement__c
                                                  WHERE UPA_Parent__r.Status = 'Active' and 
                                                  ParentApp__r.app_code__c = :EMSConstants.DELEGATED_ADMIN_APPCODE 
                                                  and Related_SF_User__c =: UserInfo.getUserId()]){
            acctIds.add(upfe.Entitled_Account__c);
        }


        List<AccessWrapper> aws = new List<AccessWrapper>();
        Map<Id,User> userMap = new Map<Id,User>([SELECT Id,ContactId,Registration_Status__c,IsActive,InactiveDate__c,Email,External_Fed_Id__c
                                                 FROM User WHERE IsActive = true and AccountId in :acctIds and Id=:userId LIMIT 1000]);
        if (!userMap.keySet().contains(userId)) return 'User does not have access to this user.';
        Datetime nowDate = Datetime.now();
        String dateOutput = nowDate.format('yyyyMMddHHmmss');
        User usr = userMap.get(userId);
        usr.Registration_Status__c = 'Denied';
        usr.IsActive = false;
        usr.InactiveDate__c = System.now();
        usr.Email = 'DIS_'+dateOutput+'_'+usr.Email;
        usr.External_Fed_Id__c = '';
        try{
            Database.SaveResult results = Database.update(usr, false);
        } catch(Exception ex) {
            System.debug('##########Exception################ => ' + ex.getCause());
            System.debug('##########Exception################ => ' + ex.getLineNumber());
            System.debug('##########Exception################ => ' + ex.getMessage());
            System.debug('##########Exception################ => ' + ex.getStackTraceString());
        }
        updateUpas(usr.Id);
        inactiveFuture(usr.Id);
        scrambleContactEmail(usr.ContactId);
        return 'SUCCESS';
    }
    
    @future
    private static void updateUpas(String userId) {
        List<UserProvAccount> finalListToBeUpdated = new List<UserProvAccount>();
        for(UserProvAccount upa : [Select SalesforceUserId,Status from UserProvAccount where SalesforceUserId =: userId]) {
            if('Active'.equalsIgnoreCase(upa.Status))
                upa.Status = 'Deactivated';
            finalListToBeUpdated.add(upa);
        }
        Database.update(finalListToBeUpdated);
    }
    
    @future(callout=true)
    private static void inactiveFuture(String userId) {
        User usr = [SELECT Id, Ag2Ag_ID__c,Email, Registration_Status__c,IsActive,IsPortalEnabled FROM User WHERE Id =: userId LIMIT 1];
        if(usr != null) {
            ID jobID = System.enqueueJob(new UserProvisioningServiceQueuable(EMSConstants.DISABLEUSER_ACT, usr,null));   
        }
    }
    
    @future
    private static void scrambleContactEmail(String conId) {
        Datetime nowDate = Datetime.now();
        String dateOutput = nowDate.format('yyyyMMddHHmmss');
        Contact dbCon = [Select email from Contact where Id =: conId LIMIT 1];
        dbCon.Email = 'DIS_'+dateOutput+'_'+dbCon.Email;
        Database.SaveResult results = Database.update(dbCon, false);
    }
    
    @RemoteAction
    public static AccessWrapper getAccessForUser(String userId, String appCode){
        Set<Id> acctIds = new Set<Id>();
        for(UserProvFineEntitlement__c upfe: [SELECT Entitled_Account__c,ParentApp__c,Related_SF_User__c,UPA_Parent__c 
                                                  FROM UserProvFineEntitlement__c
                                                  WHERE UPA_Parent__r.Status = 'Active' and 
                                                  ParentApp__r.app_code__c = :EMSConstants.DELEGATED_ADMIN_APPCODE 
                                                  and Related_SF_User__c =: UserInfo.getUserId()]){
            acctIds.add(upfe.Entitled_Account__c);
        }

        List<AccessWrapper> aws = new List<AccessWrapper>();
        Map<Id,User> userMap = new Map<Id,User>([SELECT Id FROM User WHERE IsActive = true and AccountId in :acctIds LIMIT 1000]);
        if (!userMap.keySet().contains(userId)) return null;
        
        Map<String,Application__c> appMap = new Map<String,Application__c>();
        Application__c app = [SELEcT Id, Name,App_Code__c,Connected_App_Id__c from Application__c where app_code__c =:appCode LIMIT 1];
        
        UserProvAccount upa = [SELECT Id,ConnectedAppId,SalesforceUser.FirstName, SalesforceUser.LastName,
                               SalesforceUserId,SalesforceUser.Ag2Ag_ID__c,
                               (Select Entitlement_Code__r.Name from User_Provision_Entitlements__r),
                               (Select Entitled_Account__r.Name,Entitled_Account__r.GUID__c FROM Fine_Grained_Entitlements__r)
                               FROM UserProvAccount 
                               WHERE SalesforceUserId = :userId and connectedAppId=:app.Connected_App_Id__c and Status='Active' LIMIT 1];
                              
        
        return (new AccessWrapper(upa.SalesforceUser.LastName +', ' + upa.SalesforceUser.FirstName,upa.SalesforceUser.Ag2Ag_ID__c,upa.SalesforceUserId,
                                  app.Name,
                                  app.App_Code__c,
                                  getRoleDisplay(upa.User_Provision_Entitlements__r),
                                  getAccountDisplay(upa.Fine_Grained_Entitlements__r)
                                 ));
        
        
    }
    
      @RemoteAction
    public static void removeAccessFromUser(String userId, String appcode, String comments){
      ApplicationHelper ah = new ApplicationHelper(appcode,true);
      User userForRequest = [SELECT FirstName, LastName,IsActive,Ag2Ag_ID__c,JobClassification__c,Account.Name,Account.GUID__c,External_Fed_Id__c 
      from user where Id=:userId LIMIT 1];


      ID jobID = System.enqueueJob(new EMSCreateUPRQueueable(ah.getApplication(),userForRequest,comments,UserInfo.getName(),(new Set<Entitlements__c>(ah.getProvisionedEnts(userId, ah.getApplication().Id))),'Deactivate'));

    }
    public static String getRoleDisplay(List<UserProvisionEntitlement__c> ents){
        String entNames = '';
        Integer count=1;
        if (ents != null){
          for (UserProvisionEntitlement__c ent:ents){
              if (count < ents.size())
                  entNames += ent.Entitlement_Code__r.Name+', ';
              else
                  entNames += ent.Entitlement_Code__r.Name;
              count++;
          }
        }
        return entNames;
    }
    
    public static String getAccountDisplay(List<UserProvFineEntitlement__c> provAccounts){
        String entNames = '';
        Integer count=1;
        Integer maxCount = 2;
        if (provAccounts != null){
          for (UserProvFineEntitlement__c ent:provAccounts){ //
              if (count < provAccounts.size() && count <= maxCount)
                  entNames = entNames +  ent.Entitled_Account__r.Name+' ('+ent.Entitled_Account__r.GUID__c +'), ';
              else if (count == provAccounts.size() && count <= maxCount)
                  entNames = entNames +  ent.Entitled_Account__r.Name+' ('+ent.Entitled_Account__r.GUID__c +')';
              else if (count == (maxCount+1)) entNames = entNames +' ... and ' + (provAccounts.size()-count+1) + ' more';
              count++;
          }
        }
        System.debug('Ent list of entitlement/accounts is: ' + entNames);
        return entNames;
    }

    public static Id[] getDelegatedAdmin(Id acctId){
        Id[] users = new Id[]{};
            for(UserProvFineEntitlement__c upfe: [SELECT Entitled_Account__c,ParentApp__c,Related_SF_User__c,UPA_Parent__c 
                                                  FROM UserProvFineEntitlement__c
                                                  WHERE UPA_Parent__r.Status = 'Active' and ParentApp__r.app_code__c = :EMSConstants.DELEGATED_ADMIN_APPCODE and Entitled_Account__c = :acctId]){
                                                      users.add(upfe.Related_SF_User__c);
                                                  }
        return users;
    }
}