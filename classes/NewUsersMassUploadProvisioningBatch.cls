public class NewUsersMassUploadProvisioningBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Username,Ag2Ag_ID__c,Name,External_fed_id__c,jobClassification__c,purina__c,lol__c,corporate__c,seed__c,id,IsMassLoaded__c,Status__c,Verify_Hash__c from User where isActive = true AND IsMassLoaded__c = true AND Status__c = \'Validated\'';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        for(User targetUser : (List<User>)scope){
            try{
                String jobClass = targetUser.JobClassification__c;
                boolean purina = targetUser.purina__c;
                boolean dairy = targetUser.lol__c;
                boolean winfield = targetUser.seed__c;
                boolean corporate = targetUser.corporate__c;
                system.debug('=== jobClass ===' + jobClass);
                List<AP_Rule__c> appliedRules = [SELECT Id,Business_Unit__c,(select Id, App_Code__r.Name,App_Code__r.App_Code__c, Entitlement_Code__c from Policy_Artifacts__r) from AP_Rule__c where active__c=true and baseline__c=true and Job_Classification__c includes ('Any',:jobClass)];
                system.debug('=== appliedRules ===' + appliedRules);
                List<EMSPolicyArtifactHelper> appsToAssign = new List<EMSPolicyArtifactHelper>();
                for (AP_Rule__c entRule: appliedRules){
                    String[] acceptBUs = entRule.Business_Unit__c.split(';');
                    String permSet = entRule.Id;
                    boolean provision = false;
                    for (String bu : acceptBUs){
                        if ((bu.equalsIgnoreCase('Any'))
                            || (bu.equalsIgnoreCase('winfield') && winfield)
                            || (bu.equalsIgnoreCase('dairy') && dairy)
                            || (bu.equalsIgnoreCase('purina') && purina)
                            || (bu.equalsIgnoreCase('corporate') && corporate))
                        {    
                            provision=true;
                        }
                    }
                    
                    if (provision) {
                        EMSPolicyArtifactHelper polHelper = new EMSPolicyArtifactHelper(entRule);
                        for (Policy_Artifacts__c pli : entRule.Policy_Artifacts__r){
                            polHelper.addPolicyArtifact(pli);
                        }
                        appsToAssign.add(polHelper);
                        system.debug('=== appsToAssign ===' + appsToAssign);
                        for (Id polAppId : polHelper.getAppIdsForPolicy()) {
                            Application__c targetApp = polHelper.getApp(polAppId);
                            system.debug('=== targetApp ===' + targetApp);
                            if (!Boolean.valueOf(targetApp.Migrated__c)) {
                                UserProvisioningService ups = new UserProvisioningService();
                                if(!Test.isRunningTest())
                                    ups.entitleUser(targetUser,targetApp,polHelper.getEntsforPolicyApp(polAppId));    
                            }         
                        } 
                    }//end of provision
                }//ent of all policies
                if(!Test.isRunningTest()){
                    System.enqueueJob(new EMSCreateUPRQueueable(appsToAssign,targetUser));
                }
                
                targetUser.Status__c = 'Provisioned';
                
                Database.update(targetUser);
            }
            catch(Exception e){}
        }
    }

    public void finish(Database.BatchableContext BC){}    
}