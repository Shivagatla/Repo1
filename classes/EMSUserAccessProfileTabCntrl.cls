global without sharing class EMSUserAccessProfileTabCntrl {

  public List<Application__c> allApps {get;set;}
    public List<Application__c> provisionedApps {get;set;}
   
    public String selectedApp {get;set;}
    public List<CatalogWrapper> provAppEnts{get;set;}
    public List<CatalogWrapper> pendingApps{get;set;}
    private User user;
    public Id userToRequest{get;set;}
    
  
    
    public EMSUserAccessProfileTabCntrl(){
 
      
  
      
        ApplicationHelper appHelp = new ApplicationHelper();
        allApps = new List<Application__c>();
        provisionedApps = new List<Application__c>();
              allApps = [SELECT Id, Name,Description__c,Connected_App_ID__c from Application__c where isDeleted = false ];
        String message = 'There are ' + allApps.size() + ' applications in all.';
     
        System.debug('user id: '+getCurrentUser());
        userToRequest = getCurrentUser();
        try{
            provAppEnts = appHelp.getProvisionedAppsEntsAsCataLogWrapper(getCurrentUser(),false);
            pendingApps = getPendingRequests();



       // avalAppEnts = appHelp.getAvailableSFAppsAsCataLogWrapper(UserInfo.getUserId());
        }
        catch(Exception e){

             ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'There was a problem initializing the page.'+ e);
            ApexPages.addMessage(msg);
        }
      
  
    }
    
   
    public String getCurrentUser(){
        return ApexPages.currentPage().getParameters().get('sfdc.userId');

    }
    

	public List<CatalogWrapper> getPendingRequests(){
		Set<String> ids2 = new Set<String>();
		Set<String> ids = new Set<String>();
		  List<CatalogWrapper> cwList = new List<CatalogWrapper>();
          Map<Id,String> uprToOperationMap = new Map<Id,String>();
    	List<UserProvisioningRequest> uprs = [SELECT Id, ConnectedAppId,Operation from UserProvisioningRequest where SalesforceUserId=:getCurrentUser()  
            and (overall_status__c = 'Processing' or overall_status__c = 'New' or State='New') and State <> 'Failed' and Application__r.Name <> 'LoL Active Directory'];
    	for (UserProvisioningRequest urp: uprs){
    		ids2.add(urp.Id);
    		ids.add(urp.ConnectedAppId);
            uprToOperationMap.put(urp.Id,urp.Operation);

    	}

    	List<Application__c> apps = [SELECT ApproverType__c,Queue_Name__c,Id, Name,Description__c,App_Code__c,Connected_App_ID__c,Home_Page__c,Group_Designation__c,Connected_App__c,Migrated__c,Approver__c,Requires_Approval__c from Application__c where isDeleted = false and Connected_App_Id__c  in:ids ORDER BY Name ASC NULLS FIRST];
    
    	System.debug('Found ' + apps.size() + ' apps for the user.');
    	for (Application__c app: apps){

    		Cart_Application__C parentCApp = [SELECT ID,UPR_Number__C from Cart_Application__C where Catalog_App__c =:app.Id and UPR_Number__c in:ids2 LIMIT 1];
            System.debug('found parentid: '+ parentCApp.Id);
       		Entitlements__c[] provEnts = [SELECT Id,Ent_Code__c,Name from  Entitlements__c where Id in (SELECT Ent_Code__c from Cart_Entitlement__c where Parent_App__c=:parentCApp.Id and RelatedUPR__c in:ids2)];
         List<Account> accts = [sELECT AccountNumber,Active__c,AIMS_Number__c,AnnualRevenue,
            BillingAddress,BillingCity,BillingCountry,BillingPostalCode,BillingState,BillingStreet,
            Business_Unit_Key__c,Customer_Number__c,GUID__c,Id,PAES_Number__c,Name 
            FROM Account 
            where Id in (SELECT Account__c from Cart_Entitlement__c where Parent_App__c=:parentCApp.Id and RelatedUPR__c in:ids2)];  
   
       		List<Entitlements__c> nullEnts = new List<Entitlements__c>();
            CatalogWrapper cw = new CatalogWrapper(app,provEnts,nullEnts,uprToOperationMap.get(parentCApp.UPR_Number__c));
            cw.provAccounts = accts;
            cw.isGranted = true;
            cw.requestName = parentCApp.UPR_Number__c;
            cwList.add(cw);
        }
        return cwList;


    }

    
@remoteAction
    global static String cancelRequest(String uprNumber){
        
        System.debug('about to cancel request:'+uprNumber);
        UserProvisioningRequest upr = [SELECT Id, Name, State, Other_Details__c from UserProvisioningRequest where id=:uprNumber LIMIT 1];
        upr.Other_Details__c = upr.Other_Details__c +'\n Request has been cancelled by ' + UserInfo.getName() + ' on ' + system.today().format();
        upr.State = 'Completed';
        update upr;

        return 'Successfully cancelled Request# ' + upr.Name;
    }

@remoteAction
    global static String deleteRequest(String uprNumber){
        
        System.debug('about to cancel request:'+uprNumber);

        Cart_Application__c[] cartApps = [Select Name, Catalog_App__c, (SELECT Id, Ent_Code__c,Ent_Code__r.ParentApp__c from Cart_Entitlements__r) from Cart_Application__c where UPR_Number__c=:uprNumber LIMIT 1];
        if (cartApps != null && cartApps.size()>0){
            Cart_Application__c cartApp = cartApps[0];
            
            
            Cart_Entitlement__c[] cartEnts = cartApp.Cart_Entitlements__r;
            if (cartEnts != null && cartEnts.size()>0) delete cartEnts;
            delete cartApps;
        }

        UserProvisioningRequest upr = [SELECT Id, Name, State, Other_Details__c from UserProvisioningRequest where id=:uprNumber LIMIT 1];
       
        delete upr;

        return 'Successfully deleted Request# ' + upr.Name;
    }

    public PageReference reset(){
  
        return null;
    }
}