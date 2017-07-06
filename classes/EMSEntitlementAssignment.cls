public class EMSEntitlementAssignment {
    
    
    public EMSEntitlementAssignment(){
        
    }
    
    
    @InvocableMethod(label='Assign Entitlements' description='Assigns entitlements to a user based on job classification and business unit.')
    public static void assignEntitlements(List<User> aList){
        //for every new user, find the permission sets needed based on job classification and business unit
        //
        for(User targetUser: aList){
            assignEntitlements(targetUser.Id+'',false);
            
        } 
    }
    
    
    
    
    @future(callout=true)  public static void assignEntitlements(String userId, boolean baseline){
        //for every new user, find the permission sets needed based on job classification and business unit
        
        System.debug('About to evaluate user: ' + userId);
        User targetUser = [SELECT Ag2Ag_ID__c,Name,External_fed_id__c,jobClassification__c,purina__c,lol__c,corporate__c,seed__c,FGI__c,id from User where Id=:userId];
        String jobClass = targetUser.JobClassification__c;
        boolean purina = targetUser.purina__c;
        boolean dairy = targetUser.lol__c;
        boolean winfield = targetUser.seed__c;
        boolean corporate = targetUser.corporate__c;
        boolean fgi = targetUser.FGI__c;
        System.debug('Running the trigger on user ' + targetUser.Name +' with job class: ' + jobClass);
        
        List<AP_Rule__c> appliedRules = [SELECT Id,Business_Unit__c,(select Id, App_Code__r.Name,App_Code__r.App_Code__c, Entitlement_Code__c from Policy_Artifacts__r) from AP_Rule__c where active__c=true and baseline__c =:baseline and Job_Classification__c includes ('Any',:jobClass)];
        List<EMSPolicyArtifactHelper> appsToAssign = new List<EMSPolicyArtifactHelper>();
        for (AP_Rule__c entRule: appliedRules){
            String[] acceptBUs = entRule.Business_Unit__c.split(';');
            String permSet = entRule.Id;
            boolean provision = false;
            for (String bu : acceptBUs){
                System.debug('Accepted bu is: '+bu);
                
                
                if ((bu.equalsIgnoreCase('Any'))
                    || (bu.equalsIgnoreCase('winfield') && winfield)
                    || (bu.equalsIgnoreCase('dairy') && dairy)
                    || (bu.equalsIgnoreCase('purina') && purina)
                    || (bu.equalsIgnoreCase('corporate') && corporate)
                    || (bu.equalsIgnoreCase('fgi') && fgi))
                {    
                    provision=true;
                }
            }
            
            if (provision) {
                  EMSPolicyArtifactHelper polHelper = new EMSPolicyArtifactHelper(entRule);

                for (Policy_Artifacts__c pli : entRule.Policy_Artifacts__r){
                    System.debug('Connected App Name: '+pli.App_Code__r.App_Code__c); 
                    //AppMenuItem appId = [Select ApplicationId from AppMenuitem where Name=:pli.App_Code__r.App_Code__c LIMIT 1];
                    polHelper.addPolicyArtifact(pli);
                   
                    
                }
                 appsToAssign.add(polHelper);

                for (Id polAppId : polHelper.getAppIdsForPolicy()) {
                    Application__c targetApp = polHelper.getApp(polAppId);

                    if (!Boolean.valueOf(targetApp.Migrated__c)) {
                        UserProvisioningService ups = new UserProvisioningService();
                        ups.entitleUser(targetUser,targetApp,polHelper.getEntsforPolicyApp(polAppId));    
                    }         
                  
                   
                } 
            }//end of provision



            
        }//ent of all policies

        ID jobID = System.enqueueJob(new EMSCreateUPRQueueable(appsToAssign,targetUser));
        
    }   


  
    
    public static void assignEntitlementsByUsername(String userId,boolean baseline){
        //for every new user, find the permission sets needed based on job classification and business unit
        //
        System.debug('About to evalutate user: ' + userId);
        
        User targetUser = [SELECT Name,jobClassification__c,External_fed_Id__c,purina__c,lol__c,seed__c,corporate__c,FGI__c,id,Ag2Ag_ID__c from User where username=:userId];
        String jobClass = targetUser.JobClassification__c;
        boolean purina = targetUser.purina__c;
        boolean dairy = targetUser.lol__c;
        boolean winfield = targetUser.seed__c;
        boolean corporate = targetUser.corporate__c;
        boolean fgi = targetUser.FGI__c;
        System.debug('Running the trigger on user ' + targetUser.Name +' with job class: ' + jobClass);
        
        List<AP_Rule__c> appliedRules = [SELECT Id,Business_Unit__c,(select Id, App_Code__r.Name,  App_Code__r.App_Code__c,Entitlement_Code__c from Policy_Artifacts__r) from AP_Rule__c where active__c=true and baseline__c=:baseline and Job_Classification__c includes ('Any',:jobClass)];
        List<EMSPolicyArtifactHelper> appsToAssign = new List<EMSPolicyArtifactHelper>();
        for (AP_Rule__c entRule: appliedRules){
            String[] acceptBUs = entRule.Business_Unit__c.split(';');
            String permSet = entRule.Id;
            boolean provision = false;
            for (String bu : acceptBUs){
                System.debug('Accepted bu is: '+bu);
                
                
                if ((bu.equalsIgnoreCase('Any'))
                    || (bu.equalsIgnoreCase('winfield') && winfield)
                    || (bu.equalsIgnoreCase('dairy') && dairy)
                    || (bu.equalsIgnoreCase('purina') && purina)
                    || (bu.equalsIgnoreCase('corporate') && corporate)
                    || (bu.equalsIgnoreCase('fgi') && fgi))
                {    
                    provision=true;
                }
                
            }

            if (provision) {
                  EMSPolicyArtifactHelper polHelper = new EMSPolicyArtifactHelper(entRule);

                for (Policy_Artifacts__c pli : entRule.Policy_Artifacts__r){
                    System.debug('Connected App Name: '+pli.App_Code__r.App_Code__c); 
                    //AppMenuItem appId = [Select ApplicationId from AppMenuitem where Name=:pli.App_Code__r.App_Code__c LIMIT 1];
                    polHelper.addPolicyArtifact(pli);
                   
                    
                }
                 appsToAssign.add(polHelper);

                for (Id polAppId : polHelper.getAppIdsForPolicy()) {
                    Application__c targetApp = polHelper.getApp(polAppId);

                    if (!Boolean.valueOf(targetApp.Migrated__c)) {
                        UserProvisioningService ups = new UserProvisioningService();
                        ups.entitleUser(targetUser,targetApp,polHelper.getEntsforPolicyApp(polAppId));    
                    }         
                  
                   
                } 
            }//end of provision
         }//for
            ID jobID = System.enqueueJob(new EMSCreateUPRQueueable(appsToAssign,targetUser));
            
        
        
    }   
    
    
}