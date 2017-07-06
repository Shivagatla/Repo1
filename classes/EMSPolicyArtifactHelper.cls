public class EMSPolicyArtifactHelper {

    private Map<Application__c,Set<Entitlements__c>> policyArtifacts {get;set;}
    private Map<Id,Application__c> appList {get;set;}
    private Map<Id,Entitlements__c> entList {get;set;}
    private AP_Rule__c policyId;


    public EMSPolicyArtifactHelper() {

        this.policyArtifacts = new Map<Application__c,Set<Entitlements__c>>();
        this.appList = new Map<Id,Application__c>();
        this.entList = new Map<Id,Entitlements__c>();
        
    }

  public EMSPolicyArtifactHelper(AP_Rule__c policyIdIn) {

        this.policyArtifacts = new Map<Application__c,Set<Entitlements__c>>();
        this.appList = new Map<Id,Application__c>();
        this.entList = new Map<Id,Entitlements__c>();
        this.policyId =policyIdIn;
    }

    public void addPolicyArtifact(Policy_Artifacts__c polArt){

        Application__c app = appList.get(polArt.App_Code__r.Id);
        Entitlements__c ent;
        if (app == null){
            app = [Select ApproverType__c,Queue_Name__c,Name,App_Code__c,Internal_Delegated_Bypass__c,Connected_App_ID__c,Home_Page__c,Migrated__c,Group_Designation__c, Needs_Role__c,
            DA_Approval_Required__c,EMS_Application_Object_Name__c,EMS_Application_Type__c,EMS_Application__c,
            FG_Default_user_acct__c,FG_Filter_prefix__c,FG_Instructions__c,FG_Max_Ents__c,FG_mgmt__c,FG_Search_Filter__c,FG_Account_Field__c, FG_Web_service__c,
            Approver__c,Requires_Approval__c  from Application__c where App_Code__c=:polArt.App_Code__r.App_Code__c LIMIT 1];
            appList.put(app.Id, app);
            policyArtifacts.put(app,null);
        }
        if (polArt.Entitlement_Code__c != null){
            ent = entList.get(polArt.Entitlement_Code__c);
            System.debug('The entitlement code is: '+ polArt.Entitlement_Code__c);
            if (ent == null){
                ent = [SELECT AD_Group_Optional__c,AD_Group__c,Approver__c,Ent_Code__c,Id,Name,ParentApp__c,Requires_Approval__c FROM Entitlements__c where Id=:polArt.Entitlement_Code__c LIMIT 1];
                entList.put(ent.Id,ent);
            }

            Set<Entitlements__c> setEnts = policyArtifacts.get(app);
            if (setEnts == null){
                setEnts = new Set<Entitlements__c>();
            }
            setEnts.add(ent);
            policyArtifacts.put(app,setEnts);
        }

    }

    public Set<Entitlements__c> getEntsforPolicyApp(Id appId){
        Application__c app = appList.get(appId);
        return policyArtifacts.get(app);
        
    }

    public Set<Id> getAppIdsForPolicy(){
        return appList.keySet();
    }

    public Application__c getApp(Id appId){
        return appList.get(appId);
    }

    public AP_Rule__c getPolicyId(){
        return policyId;
    }

}