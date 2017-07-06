public class EMSUPRHelper {
    
    private Id uprId {get;set;}
    private Application__c targetApp {get;set;}
    private Set<Entitlements__c> targetEnts {get;set;}
    private UserProvisioningRequest upr {get;set;}
    private List<Cart_Entitlement__c> cartEntsList {get;set;}
    private Set<Account> targetAccts {get;set;}
    
    public EMSUPRHelper(Id uprId, Id appId) {
        uprId = uprId;
        cartEntsList = new List<Cart_Entitlement__c>();
        this.upr = [SELECT connectedAppId, User_Reason__c,SalesforceUserId,operation,state, UserProvAccount.Id,Overall_Status__c FROM UserProvisioningRequest WHERE id = :uprId LIMIT 1];
        targetApp = [Select Id,Name,App_Code__c,Connected_App_ID__c,Connected_App__c,Use_AD_Role_Name__c,DA_Approval_Required__c,Internal_Delegated_Bypass__c,EMS_Application_Object_Name__c,EMS_Application_Type__c,EMS_Application__c,Home_Page__c,Migrated__c,FG_Web_Service__c,FG_mgmt__c,FG_Account_Field__c,Group_Designation__c, Provisioning_Queue__c, Approver__c  from Application__c where Connected_App_ID__c=:appId LIMIT 1];
        Cart_Application__c[] cartApps = [Select Name, Catalog_App__c, (SELECT Id, Ent_Code__c,Account__c,Ent_Code__r.ParentApp__c,RecordType.DeveloperName from Cart_Entitlements__r) from Cart_Application__c where UPR_Number__c=:uprId LIMIT 1];
        if (cartApps != null && cartApps.size()>0){
            Cart_Application__c cartApp = cartApps[0];
            
            targetEnts = new Set<Entitlements__c>();
            targetAccts = new Set<Account>();
            
            Set<Id> cartEntIds = new Set<Id>();
            Set<Id> acctIds = new Set<Id>();
            for (Cart_Entitlement__c cartEnt : cartApp.Cart_Entitlements__r){
                System.debug('Record type:' + cartEnt.RecordType.DeveloperName);
                if (cartEnt.RecordType.DeveloperName != EMSConstants.CART_FG_RT){ //this takes care of the old requests and nulls -- which are coarse grained.
                    cartEntIds.add(cartEnt.Ent_Code__c);
                    
                }
                else{
                    acctIds.add(cartEnt.Account__c);
                }
                cartEntsList.add(cartEnt);
                
            }
            
            for( Entitlements__c targetEnt:[SELECT Description__c,AD_Group_Optional__c,ParentApp__c,AD_Group__c,Ent_Code__c,Id,Name FROM Entitlements__c where Id in :cartEntIds]){
                targetEnts.add(targetEnt);
                
            }
            
            for (Account acct: [SELECT AccountNumber,Active__c,AIMS_Number__c,
            BillingAddress,BillingCity,BillingCountry,BillingPostalCode,BillingState,BillingStreet,
            Business_Unit_Key__c,Customer_Number__c,GUID__c,Id,PAES_Number__c,Name FROM Account where Id in: acctIds]){
                targetAccts.add(acct);
            }
            
        }
        
    }
    
    public UserProvisioningRequest getUPR(){
        return upr;
    }
    
    public String getUserReason(){
        return upr.User_Reason__c;
    }
    
    public String getOperation(){
        return upr.Operation;
    }
    
    public String getState(){
        return upr.State;
    }
    
    public  UserProvAccount getProvisionedAccount(){
        UserProvAccount upa;
        UserProvAccount[] upaList = [SELECT name, externalUserId, externalUsername, externalEmail, externalFirstname, externalLastname, linkState, status FROM UserProvAccount WHERE salesforceUserId = :upr.SalesforceUserId  AND linkState = 'Linked' and ConnectedAppId=:upr.ConnectedAppId];
        if(upaList.size() > 0)
            upa = upaList[0];
        return upa;
    }
    
    public  boolean isEntitlementProvisioned(Id upaId, Id entId){
        UserProvisionEntitlement__c[] provEnts = [SELECT Id from  UserProvisionEntitlement__c where Entitlement_Code__c=:entId and UPA_Parent__c =:upaId];
        if(provEnts.size() >0)
            return true;
        else 
            return false;
        
    }

     public  boolean isAccountProvisioned(Id upaId, Id acctId){
        UserProvFineEntitlement__c[] provEnts = [SELECT Id from UserProvFineEntitlement__c where Entitled_Account__c=:acctId and UPA_Parent__c =:upaId];
        if(provEnts.size() >0)
            return true;
        else 
            return false;
        
    }
    
    public Application__c getUPRApplication(){
        return targetApp;
    }
    
    public Set<Entitlements__c> getUPREntitlements(){ //these are coarse grained entitlements
        return targetEnts;
    }
    
    public Set<Account> getUPRFGEntitlements(){ //these are coarse grained entitlements
        return targetAccts;
    }
    
    public List<Cart_Entitlement__c> getCartEntitlements(){
        return cartEntsList;
    }
    public String getReason(){
        return upr.User_Reason__c;
    }
    
}