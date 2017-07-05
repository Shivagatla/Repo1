/**********************************
Class Name: ApplicationHelper
Description:This class makes it easy for other classes to get information about an application.
Version: 1.0
***********************************/
public without sharing class ApplicationHelper {
    
    Application__C application = null;
    Map<Application__c,List<Entitlements__c>> appCatalogList {get;set;}
   
    
    

    //passes in the Application Name
    public ApplicationHelper(String app_name){
        
        Application__C[] apps = [SELECT ApproverType__c,Migrated__c,Connected_App_ID__c,Queue_Name__c,Group_Designation__c,Home_Page__c,Approver__c,
        DA_Approval_Required__c,Internal_Delegated_Bypass__c,EMS_Application_Object_Name__c,EMS_Application_Type__c,EMS_Application__c, 
        Use_AD_Role_Name__c,Description__c,App_Code__c,Connected_App__c,Id,IsDeleted,Name,OwnerId,Requires_Approval__c,Needs_Role__c,FG_Web_service__c,
        FG_Default_user_acct__c,FG_Filter_prefix__c,FG_Instructions__c,FG_Max_Ents__c,FG_mgmt__c,FG_Search_Filter__c,FG_Account_Field__c,FG_Admin_Instructions__c,Children_allowed__c
        FROM Application__c where Name=:app_name ORDER BY Name ASC NULLS FIRST];
        if (apps!= null && apps.size()>0){
            application = apps[0];
        }  
        
        
    }

        //passes in the Application Name
    public ApplicationHelper(String app_name, boolean appcode){
        
        Application__C[] apps = (appcode)?[SELECT ApproverType__c,Migrated__c,Connected_App_ID__c,Queue_Name__c,Group_Designation__c,Home_Page__c,Approver__c,
        Use_AD_Role_Name__c,Description__c,App_Code__c,Connected_App__c,Id,IsDeleted,Name,OwnerId,Requires_Approval__c,Needs_Role__c,FG_Web_service__c,
        DA_Approval_Required__c,Internal_Delegated_Bypass__c,EMS_Application_Object_Name__c,EMS_Application_Type__c,EMS_Application__c,
        FG_Default_user_acct__c,FG_Filter_prefix__c,FG_Instructions__c,FG_Max_Ents__c,FG_mgmt__c,FG_Search_Filter__c,FG_Account_Field__c,Children_allowed__c 
        FROM Application__c where App_Code__c=:app_name ORDER BY Name ASC NULLS FIRST]:[SELECT ApproverType__c,Migrated__c,Connected_App_ID__c,Queue_Name__c,Group_Designation__c,Home_Page__c,Approver__c,
        Use_AD_Role_Name__c,Description__c,App_Code__c,Connected_App__c,Id,IsDeleted,Name,OwnerId,Requires_Approval__c,Children_allowed__c,Needs_Role__c,FG_Web_service__c,
        DA_Approval_Required__c,Internal_Delegated_Bypass__c,EMS_Application_Object_Name__c,EMS_Application_Type__c,EMS_Application__c,
        FG_Default_user_acct__c,FG_Filter_prefix__c,FG_Instructions__c,FG_Max_Ents__c,FG_mgmt__c,FG_Search_Filter__c,FG_Account_Field__c,FG_Admin_Instructions__c 
        FROM Application__c where Connected_App_ID__c=:app_name ORDER BY Name ASC NULLS FIRST];
        if (apps!= null && apps.size()>0){
            application = apps[0];
        }  
        
        
    }
    
    public ApplicationHelper(Id app_id){
        System.debug('In here');
        Application__C[] apps = [SELECT ApproverType__c,Queue_Name__c,Group_Designation__c,Connected_App_ID__c,Approver__c,Home_Page__c,Migrated__c,
        DA_Approval_Required__c,Internal_Delegated_Bypass__c,EMS_Application_Object_Name__c,EMS_Application_Type__c,EMS_Application__c,
        Use_AD_Role_Name__c,Description__c,App_Code__c,Connected_App__c,Id,IsDeleted,Name,OwnerId,Requires_Approval__c,Children_allowed__c,Needs_Role__c,FG_Web_service__c,
        FG_Default_user_acct__c,FG_Filter_prefix__c,FG_Instructions__c,FG_Max_Ents__c,FG_mgmt__c,FG_Search_Filter__c,FG_Account_Field__c,FG_Admin_Instructions__c 
        FROM Application__c where Connected_App_ID__C=:app_id ORDER BY Name ASC NULLS FIRST];
        if (apps.size()>0){
            application = apps[0];
        }   
        System.debug('found ' + apps.size() +' apps.');
    }

    public ApplicationHelper(Application__c app){
        application = app;

    }
    
    public ApplicationHelper(){
        appCatalogList = new Map<Application__c,List<Entitlements__c>>();
        
    }
    
    public boolean hasFineGrainEnts(){
        System.debug('has fine grain ents:'+application.FG_mgmt__c);
        if (application == null)
            return false;
        return application.FG_mgmt__c;
    }

    public boolean needsApproval(){
        if (application == null)
            return false;
        return application.Requires_Approval__c;
    }
    
public integer getMaxEnts(){
        if (application.FG_Max_Ents__c <> null)
            return Integer.valueOf(application.FG_Max_Ents__c);
        else return 100;
    }
    
    public String getName(){
        if (application == null)
            return '';
        return application.Name;
    }

     public String getAcctFieldName(){
        return application.FG_Account_Field__c;
    }

    public Application__c getApplication(){
        return application;
    }

    public boolean isApproverQueue(){
        return application.ApproverType__c.equalsIgnoreCase('QUEUE');
    }

    public boolean isApproverUser(){
        return application.ApproverType__c.equalsIgnoreCase('USER');

    }

    public String getQueueName(){
        return application.Queue_Name__c;
    }
    
    
    public List<Application__c> getAvailableSFApps(Id userId){ 
        List<UserProvAccount> upas = [SELECT ConnectedAppId FROM UserProvAccount WHERE SalesforceUserId = :userId];
        Set<String> ids2 = new Set<String>();
        for (UserProvAccount upa:upas){
            ids2.add(upa.ConnectedAppId);
        }
        
        List<Application__c> apps = [SELECT ApproverType__c,Queue_Name__c,Approver__c,Use_AD_Role_Name__c,Description__c,App_Code__c,Needs_Role__c,
        DA_Approval_Required__c,Internal_Delegated_Bypass__c,EMS_Application_Object_Name__c,EMS_Application_Type__c,EMS_Application__c,
        Group_Designation__c,Home_Page__c,Connected_App__c,Connected_App_ID__c,Id,IsDeleted,Name,OwnerId,Migrated__c,Requires_Approval__c,
        FG_Default_user_acct__c,FG_Filter_prefix__c,FG_Instructions__c,FG_Max_Ents__c,FG_mgmt__c,FG_Search_Filter__c,Children_allowed__c,FG_Account_Field__c,FG_Admin_Instructions__c 
        from Application__c where isDeleted = false  and System_Application__c=false and Connected_App_Id__c not in:ids2 ORDER BY Name ASC NULLS FIRST];
       
        
        return apps;
        
    }

     public List<Application__c> getAvailableSFApps(Id userId, boolean allApps){ 
        List<UserProvAccount> upas = [SELECT ConnectedAppId FROM UserProvAccount WHERE SalesforceUserId = :userId];
        Set<String> ids2 = new Set<String>();
        for (UserProvAccount upa:upas){
            ids2.add(upa.ConnectedAppId);
        }
        
        List<Application__c> apps = allApps?[SELECT ApproverType__c,Queue_Name__c,Approver__c,Use_AD_Role_Name__c,Description__c,App_Code__c,Needs_Role__c,FG_Web_service__c,
        Group_Designation__c,Home_Page__c,Connected_App__c,Connected_App_ID__c,Id,IsDeleted,Name,OwnerId,Migrated__c,Requires_Approval__c,
        DA_Approval_Required__c,Internal_Delegated_Bypass__c,EMS_Application_Object_Name__c,EMS_Application_Type__c,EMS_Application__c,
        FG_Default_user_acct__c,FG_Filter_prefix__c,FG_Instructions__c,FG_Max_Ents__c,FG_mgmt__c,FG_Search_Filter__c,Children_allowed__c,FG_Account_Field__c,FG_Admin_Instructions__c 
        from Application__c where isDeleted = false  and Connected_App_Id__c not in:ids2 ORDER BY Name ASC NULLS FIRST]:
        [SELECT ApproverType__c,Queue_Name__c,Approver__c,Use_AD_Role_Name__c,Description__c,App_Code__c,Needs_Role__c,FG_Web_service__c,
        DA_Approval_Required__c,Internal_Delegated_Bypass__c,EMS_Application_Object_Name__c,EMS_Application_Type__c,EMS_Application__c,
        Group_Designation__c,Home_Page__c,Connected_App__c,Connected_App_ID__c,Id,IsDeleted,Name,OwnerId,Migrated__c,Requires_Approval__c,
        FG_Default_user_acct__c,FG_Filter_prefix__c,FG_Instructions__c,FG_Max_Ents__c,FG_mgmt__c,FG_Search_Filter__c,Children_allowed__c,FG_Account_Field__c,FG_Admin_Instructions__c 
        from Application__c where isDeleted = false  and System_Application__c=:false and Connected_App_Id__c not in:ids2 ORDER BY Name ASC NULLS FIRST];
       
        
        return apps;
        
    }


    public List<Application__c> getProvisionedApps(Id userId){
         List<UserProvAccount> upas = [SELECT ConnectedAppId FROM UserProvAccount WHERE SalesforceUserId = :userId];
        Set<String> ids2 = new Set<String>();
        for (UserProvAccount upa:upas){
            ids2.add(upa.ConnectedAppId);
        }
        
        List<Application__c> apps = [SELECT Id, Name,Use_AD_Role_Name__c,Description__c,Connected_App_ID__c,App_Code__c,Home_Page__c,
        DA_Approval_Required__c,Internal_Delegated_Bypass__c,EMS_Application_Object_Name__c,EMS_Application_Type__c,EMS_Application__c,
        Group_Designation__c,Connected_App__c,Approver__c,Requires_Approval__c,Migrated__c,Needs_Role__c,FG_Web_service__c,
        FG_Default_user_acct__c,FG_Filter_prefix__c,FG_Instructions__c,FG_Max_Ents__c,FG_mgmt__c,FG_Search_Filter__c,Children_allowed__c,FG_Account_Field__c,FG_Admin_Instructions__c 
        from Application__c where isDeleted = false and System_Application__c=false and Connected_App_Id__c in:ids2 ORDER BY Name ASC NULLS FIRST];
       
        
        return apps;
        

    }
    
      public List<CatalogWrapper> getAvailableSFAppsAsCataLogWrapper(Id userId){ 
        List<CatalogWrapper> cwList = new List<CatalogWrapper>();
          List<UserProvAccount> upas = [SELECT ConnectedAppId FROM UserProvAccount WHERE SalesforceUserId = :userId];
        Set<String> ids2 = new Set<String>();
        for (UserProvAccount upa:upas){
            ids2.add(upa.ConnectedAppId);
        }
        //get pending requests

            List<Application__c> apps = [SELECT ApproverType__c,Queue_Name__c,Id, Name,Use_AD_Role_Name__c,Description__c,App_Code__c,Connected_App_ID__c,Home_Page__c,
            Group_Designation__c,Connected_App__c,Migrated__c,Approver__c,Requires_Approval__c,Needs_Role__c,FG_Web_service__c,
            DA_Approval_Required__c,Internal_Delegated_Bypass__c,EMS_Application_Object_Name__c,EMS_Application_Type__c,EMS_Application__c,
            FG_Default_user_acct__c,FG_Filter_prefix__c,FG_Instructions__c,FG_Max_Ents__c,FG_mgmt__c,FG_Search_Filter__c,Children_allowed__c,FG_Admin_Instructions__c,FG_Account_Field__c,
            (SELECT AD_Group_Optional__c,AD_Group__c,Ent_Code__c,Id,Name FROM Entitlements__r) 
            from Application__c 
            where isDeleted = false and System_Application__c=false and Connected_App_Id__c not in:ids2 
            ORDER BY Name 
            ASC NULLS FIRST];
    
        for (Application__c app: apps){
            List<Entitlements__c> availableEnts =  app.Entitlements__r;
            CatalogWrapper cw = new CatalogWrapper(app,availableEnts);
             cw.migrated = app.Migrated__c;
            System.debug('Found entitlements:'+availableEnts);
            cwList.add(cw);
        }
        return cwList;
        
    }

    public List<CatalogWrapper> getProvisionedAppsAsCataLogWrapper(Id userId){
        List<CatalogWrapper> cwList = new List<CatalogWrapper>();
        List<UserProvAccount> upas = [SELECT ConnectedAppId FROM UserProvAccount WHERE SalesforceUserId = :userId and status='Active'];

        Set<String> ids2 = new Set<String>();
        Set<String> upaIds = new Set<String>();
        integer count = 0;
        for (UserProvAccount upa:upas){
            ids2.add(upa.ConnectedAppId);
            upaIds.add(upa.Id);
            count++;
        }


        List<Application__c> apps = [SELECT ApproverType__c,Queue_Name__c,Id, Name,Use_AD_Role_Name__c,Description__c,Needs_Role__c,
        FG_Web_service__c,DA_Approval_Required__c,Internal_Delegated_Bypass__c,EMS_Application_Object_Name__c,EMS_Application_Type__c,EMS_Application__c,
        Connected_App_ID__c,App_Code__c,Home_Page__c,Group_Designation__c,FG_Admin_Instructions__c,Connected_App__c,Migrated__c,
        Approver__c,Requires_Approval__c from Application__c 
        where isDeleted = false and System_Application__c=false and Connected_App_Id__c in:ids2 ORDER BY Name ASC NULLS FIRST];
     
        for (Application__c app: apps){
            //get provisioned ents

            Entitlements__c[] provEnts = [SELECT Id,AD_Group_Optional__c,AD_Group__c,Ent_Code__c,Name from  Entitlements__c where Id in (SELECT Entitlement_Code__c from UserProvisionEntitlement__c where ParentApp__c=:app.Id and UPA_Parent__c in:upaIds)];
            Set<String> provEntIds = new Set<String>();
            for (Entitlements__c ent:provEnts){
                provEntIds.add(ent.Id);
            }
            //get available ents

            List<Entitlements__c> availableEnts =  [SELECT AD_Group_Optional__c,AD_Group__c,Ent_Code__c,Id,Name FROM Entitlements__c where ParentApp__c=:app.Id and Id not in:provEntIds];
            CatalogWrapper cw = new CatalogWrapper(app,provEnts,availableEnts);
             cw.migrated =   app.Migrated__c;
            cwList.add(cw);
        }
        return cwList;

    }
      public List<CatalogWrapper> getProvisionedAppsAsCataLogWrapper(Id userId, boolean systemApps){
        List<CatalogWrapper> cwList = new List<CatalogWrapper>();
        List<UserProvAccount> upas = [SELECT ConnectedAppId FROM UserProvAccount WHERE SalesforceUserId = :userId and status='Active'];

        Set<String> ids2 = new Set<String>();
        Set<String> upaIds = new Set<String>();
        integer count = 0;
        for (UserProvAccount upa:upas){
            ids2.add(upa.ConnectedAppId);
            upaIds.add(upa.Id);
            count++;
        }


        List<Application__c> apps = null;
        if (systemApps == true)
            apps= [SELECT ApproverType__c,Queue_Name__c,Id, Name,Use_AD_Role_Name__c,Description__c,Connected_App_ID__c,App_Code__c,Home_Page__c,Needs_Role__c,
            Group_Designation__c,Connected_App__c,Migrated__c,Approver__c,Requires_Approval__c,FG_Web_service__c,
            DA_Approval_Required__c,Internal_Delegated_Bypass__c,EMS_Application_Object_Name__c,EMS_Application_Type__c,EMS_Application__c,
            FG_Default_user_acct__c,FG_Filter_prefix__c,FG_Instructions__c,FG_Max_Ents__c,FG_mgmt__c,FG_Search_Filter__c,Children_allowed__c,FG_Account_Field__c,FG_Admin_Instructions__c 
            from Application__c where isDeleted = false and System_Application__c=false and Connected_App_Id__c in:ids2 ORDER BY Name ASC NULLS FIRST];
        else
           apps= [SELECT ApproverType__c,Queue_Name__c,Id, Name,Use_AD_Role_Name__c,Description__c,Connected_App_ID__c,App_Code__c,Home_Page__c,Needs_Role__c,
           Group_Designation__c,Connected_App__c,Migrated__c,Approver__c,Requires_Approval__c,
           DA_Approval_Required__c,Internal_Delegated_Bypass__c,EMS_Application_Object_Name__c,EMS_Application_Type__c,EMS_Application__c,
           FG_Default_user_acct__c,FG_Filter_prefix__c,FG_Instructions__c,FG_Max_Ents__c,FG_mgmt__c,FG_Search_Filter__c,FG_Account_Field__c
           from Application__c where isDeleted = false  and Connected_App_Id__c in:ids2 ORDER BY Name ASC NULLS FIRST];
     
        for (Application__c app: apps){
            //get provisioned ents
            Entitlements__c[] provEnts = [SELECT Id,AD_Group_Optional__c,AD_Group__c,Ent_Code__c,Name from  Entitlements__c where Id in (SELECT Entitlement_Code__c from UserProvisionEntitlement__c where ParentApp__c=:app.Id and UPA_Parent__c in:upaIds)];
            Set<String> provEntIds = new Set<String>();
            for (Entitlements__c ent:provEnts){
                provEntIds.add(ent.Id);
            }
            //get available ents
            List<Account> accts = [sELECT AccountNumber,Active__c,AIMS_Number__c,AnnualRevenue,
            BillingAddress,BillingCity,BillingCountry,BillingPostalCode,BillingState,BillingStreet,
            Business_Unit_Key__c,Customer_Number__c,GUID__c,Id,PAES_Number__c,Name 
            FROM Account 
            where Id in (SELECT Entitled_Account__c from UserProvFineEntitlement__c where ParentApp__c=:app.Id and UPA_Parent__c in:upaIds)];
            List<Entitlements__c> availableEnts =  [SELECT AD_Group_Optional__c,AD_Group__c,Ent_Code__c,Id,Name FROM Entitlements__c where ParentApp__c=:app.Id and Id not in:provEntIds];
            CatalogWrapper cw = new CatalogWrapper(app,provEnts,availableEnts);
            cw.provAccounts = accts;
             cw.migrated =   app.Migrated__c;
            cwList.add(cw);
        }
        return cwList;

    }

    public List<CatalogWrapper> getProvisionedAppsEntsAsCataLogWrapper(Id userId, boolean systemApps){
        List<CatalogWrapper> cwList = new List<CatalogWrapper>();
        List<UserProvAccount> upas = [SELECT ConnectedAppId FROM UserProvAccount WHERE SalesforceUserId = :userId and status='Active'];

        Set<String> ids2 = new Set<String>();
        Set<String> upaIds = new Set<String>();
        integer count = 0;
        for (UserProvAccount upa:upas){
            ids2.add(upa.ConnectedAppId);
            upaIds.add(upa.Id);
            count++;
        }


        List<Application__c> apps = null;
        if (systemApps == true)
        apps= [SELECT ApproverType__c,Queue_Name__c,Id, Name,Use_AD_Role_Name__c,Description__c,Connected_App_ID__c,DA_Approval_Required__c,Internal_Delegated_Bypass__c,EMS_Application_Object_Name__c,EMS_Application_Type__c,EMS_Application__c,App_Code__c,Needs_Role__c,FG_Web_service__c,Home_Page__c,Group_Designation__c,FG_Admin_Instructions__c,Connected_App__c,Migrated__c,Approver__c,Requires_Approval__c,Children_allowed__c from Application__c where isDeleted = false and System_Application__c=false and Connected_App_Id__c in:ids2 ORDER BY Name ASC NULLS FIRST];
        else
           apps= [SELECT ApproverType__c,Queue_Name__c,Id, Name,Use_AD_Role_Name__c,Description__c,Connected_App_ID__c,DA_Approval_Required__c,Internal_Delegated_Bypass__c,EMS_Application_Object_Name__c,EMS_Application_Type__c,EMS_Application__c,App_Code__c,Needs_Role__c,FG_Web_service__c,Home_Page__c,Group_Designation__c,FG_Admin_Instructions__c,Connected_App__c,Children_allowed__c,Migrated__c,Approver__c,Requires_Approval__c from Application__c where isDeleted = false  and Connected_App_Id__c in:ids2 ORDER BY Name ASC NULLS FIRST];
     
        for (Application__c app: apps){
            //get provisioned ents
            Entitlements__c[] provEnts = [SELECT Id,AD_Group_Optional__c,AD_Group__c,Ent_Code__c,Name from  Entitlements__c where Id in (SELECT Entitlement_Code__c from UserProvisionEntitlement__c where ParentApp__c=:app.Id and UPA_Parent__c in:upaIds)];
            Set<String> provEntIds = new Set<String>();
           // for (Entitlements__c ent:provEnts){
            //    provEntIds.add(ent.Id);
           // }
            //get available ents
           List<Account> accts = [sELECT AccountNumber,Active__c,AIMS_Number__c,AnnualRevenue,
            BillingAddress,BillingCity,BillingCountry,BillingPostalCode,BillingState,BillingStreet,
            Business_Unit_Key__c,Customer_Number__c,GUID__c,Id,PAES_Number__c,Name 
            FROM Account 
            where Id in (SELECT Entitled_Account__c from UserProvFineEntitlement__c where ParentApp__c=:app.Id and UPA_Parent__c in:upaIds)];

            //List<Entitlements__c> availableEnts =  [SELECT AD_Group_Optional__c,AD_Group__c,Ent_Code__c,Id,Name FROM Entitlements__c where ParentApp__c=:app.Id and Id not in:provEntIds];
           List<Entitlements__c> nullEnts = new List<Entitlements__c>();
            CatalogWrapper cw = new CatalogWrapper(app,provEnts,nullEnts);
            System.debug('the number of accounts is:' + accts.size());
            cw.provAccounts = accts;
            cw.isGranted = true;
            cw.migrated =   app.Migrated__c;
            cwList.add(cw);
        }
        return cwList;

    }


    public List<Entitlements__c> getProvisionedEnts(Id userId, Id appId){
  List<UserProvAccount> upas = [SELECT ConnectedAppId FROM UserProvAccount WHERE SalesforceUserId = :userId and status='Active'];

        Set<String> ids2 = new Set<String>();
        Set<String> upaIds = new Set<String>();
        integer count = 0;
        for (UserProvAccount upa:upas){
            ids2.add(upa.ConnectedAppId);
            upaIds.add(upa.Id);
            count++;
        }

        return [SELECT Id,AD_Group_Optional__c,AD_Group__c,Ent_Code__c,Name from  Entitlements__c where Id in (SELECT Entitlement_Code__c from UserProvisionEntitlement__c where ParentApp__c=:appId and UPA_Parent__c in:upaIds)];
          

    }


    public List<Account> getProvisionedFEnts(Id userId){
        List<UserProvAccount> upas = [SELECT Id FROM UserProvAccount WHERE SalesforceUserId = :userId and status='Active' and ConnectedAppId=:application.Connected_App_ID__c];

        Set<Id> ids2 = new Set<Id>();
  
        integer count = 0;
        for (UserProvAccount upa:upas){
            ids2.add(upa.Id);
      
            count++;
        }

         return [SELECT AccountNumber,Active__c,AIMS_Number__c,AnnualRevenue,
            BillingAddress,BillingCity,BillingCountry,BillingPostalCode,BillingState,BillingStreet,
            Business_Unit_Key__c,Customer_Number__c,GUID__c,Id,PAES_Number__c,Name 
            FROM Account 
            where Id in (SELECT Entitled_Account__c from UserProvFineEntitlement__c where ParentApp__c=:application.Id and UPA_Parent__c in:ids2) ORDER BY Name];
 

    }





      public List<Entitlements__c> getAvailableEnts(Id userId, Id appId){
        List<UserProvAccount> upas = [SELECT ConnectedAppId FROM UserProvAccount WHERE SalesforceUserId = :userId and status='Active'];

        Set<String> ids2 = new Set<String>();
        Set<String> upaIds = new Set<String>();
        integer count = 0;
        for (UserProvAccount upa:upas){
            ids2.add(upa.ConnectedAppId);
            upaIds.add(upa.Id);
            count++;
        }

        Entitlements__c[] provEnts = [SELECT Id,AD_Group_Optional__c,AD_Group__c,Ent_Code__c,Name from  Entitlements__c where Id in (SELECT Entitlement_Code__c from UserProvisionEntitlement__c where ParentApp__c=:appId and UPA_Parent__c in:upaIds)];
        Set<String> provEntIds = new Set<String>();
        for (Entitlements__c ent:provEnts){
            provEntIds.add(ent.Id);
        }
        //get available ents

        return  [SELECT AD_Group_Optional__c,AD_Group__c,Ent_Code__c,Id,Name FROM Entitlements__c where ParentApp__c=:appId and Id not in:provEntIds];

    }

      public List<Entitlements__c> getAllEnts(Id appId){
       

        return  [SELECT AD_Group_Optional__c,AD_Group__c,Ent_Code__c,Id,Name FROM Entitlements__c where ParentApp__c=:appId];

    }

    public List<Account> getFineGrainAccounts(Id userId){
        return getFineGrainAccounts(userId, true);
    }

    public List<Account> getFineGrainAccounts(Id userId, boolean getChildren){
        System.debug('getting fine grain ents...');
        if (!application.FG_mgmt__c) return new List<Account>();

        List<Account> accts = new List<Account>();
        User c = [SELECT Contact.AccountId,Contact.Account.Name,Contact.Account.GUID_Prefix__c,Contact.Account.GUID__c,Contact.Account.PAES_Number__c,Contact.Account.Customer_Number__c,Contact.Account.AIMS_Number__c,Contact.Account.ParentId,Contact.Account.Parent.GUID__c,
        Contact.Account.Parent.AIMS_Number__c, Contact.Account.Parent.GUID_Prefix__c, Contact.Account.Parent.Customer_Number__c,Contact.Account.Parent.PAES_Number__c FROM User where Id =:userId LIMIT 1];
        if (c==null)
            return accts;
        boolean isTop = false;
        if (c.Contact.Account.ParentId == null) isTop=true;
        System.debug('the account guid is:'+ c.Contact.Account.GUID__c);
        System.debug('the contacts account is: ' + c.Contact.Account.Name + ' and the search filter is:'+ 
            getSearchFilter(c.Contact.Account.GUID_Prefix__c,(isTop?c.Contact.Account.GUID_Prefix__c:c.Contact.Account.Parent.GUID_Prefix__c)));
        AccountHierarchy ah = new AccountHierarchy(c.Contact.AccountId,getSearchFilter(c.Contact.Account.GUID_Prefix__c,(isTop?c.Contact.Account.GUID_Prefix__c:c.Contact.Account.Parent.GUID_Prefix__c)),(application.FG_Search_Filter__c != 'No Validation'));
        if (application.Children_allowed__c && getChildren) accts = ah.getChildren(true);
        if (application.FG_Default_user_acct__c) accts.add(ah.getSelf());
        
        if (application.FG_Search_Filter__c=='User Parent Account Search Filter') accts.add(ah.getParent());

        System.debug('Accounts'+accts);
        return accts;
    }

    public String getSearchFilter(String userGUID, String parentGUID){

        //FG_Search_Filter__c;
        if (application.FG_Search_Filter__c == 'Use User Account Search Filter'){        
            return userGUID;
        }
        else if (application.FG_Search_Filter__c == 'Use Parent Account Search Filter'){
            return parentGUID;
        }
        //FG_Filter_prefix__c;
        return '';
    }

      public static String getAppGUIDValue(Application__c app, Account acct){
        String fieldName = String.ISBLANK(app.FG_Account_field__c)?'GUID__c':app.FG_Account_Field__c;
                if (fieldName.equalsIgnoreCase('GUID__C') && !String.isBlank(acct.GUID__c))
                    return acct.GUID__c;
                else if (fieldName.equalsIgnoreCase('Customer_Number__c') && !String.isBlank(acct.Customer_Number__c))
                    return acct.Customer_Number__c; 
                else if (fieldName.equalsIgnoreCase('PAES_Number__c') && !String.isBlank(acct.PAES_Number__c))
                    return acct.PAES_Number__c; 
                else if (fieldName.equalsIgnoreCase('AIMS_Number__c') && !String.isBlank(acct.AIMS_Number__c))
                    return acct.AIMS_Number__c;
        return null;
    }

    public boolean hasDelegatedAdminApproval(){
        return Boolean.valueOf(application.DA_Approval_Required__c);
    }

    public boolean canBypassDelegate(){
        return Boolean.valueOf(application.Internal_Delegated_Bypass__c);
    }


    public  String getAppGUIDValue(Account acct){
        String fieldName = String.ISBLANK(application.FG_Account_field__c)?'GUID__c':application.FG_Account_Field__c;
                if (fieldName.equalsIgnoreCase('GUID__C') && !String.isBlank(acct.GUID__c))
                    return acct.GUID__c;
                else if (fieldName.equalsIgnoreCase('Customer_Number__c') && !String.isBlank(acct.Customer_Number__c))
                    return acct.Customer_Number__c; 
                else if (fieldName.equalsIgnoreCase('PAES_Number__c') && !String.isBlank(acct.PAES_Number__c))
                    return acct.PAES_Number__c; 
                else if (fieldName.equalsIgnoreCase('AIMS_Number__c') && !String.isBlank(acct.AIMS_Number__c))
                    return acct.AIMS_Number__c;
        return null;
    }


}