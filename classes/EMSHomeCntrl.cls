public without sharing class EMSHomeCntrl{
    
    public AccessPageWrapper APWrapper{get;set;}
    private String userId{get;set;}
    public User userDB {get;set;}
    
    class AccessPageWrapper{
        public Integer pendingSize {get;set;}
        public Integer grantedSize {get;set;}
        public Integer availableSize {get;set;}
        public Map<String, List<Application__c>> pendingAppMap{get;set;}
        public Map<String, List<Application__c>> grantedMap{get;set;}
        public Map<String, List<CatalogWrapper>> avalAppMap{get;set;}
        
        public AccessPageWrapper(Integer pendingSize, Integer grantedSize, Integer availableSize, Map<String, List<Application__c>> pendingAppMap,
                                 Map<String, List<Application__c>> grantedMap, Map<String, List<CatalogWrapper>> avalAppMap) {
                                     this.pendingSize = pendingSize;
                                     this.grantedSize = grantedSize;
                                     this.availableSize = availableSize;
                                     this.pendingAppMap = pendingAppMap;
                                     this.grantedMap = grantedMap;
                                     this.avalAppMap = avalAppMap;
                                 }
    }
    
    public PageReference redir() {
        String JobClassification = [Select JobClassification__c From User Where Id =: UserInfo.getUserId()][0].JobClassification__c;
        if ((JobClassification != null && JobClassification.equalsIgnoreCase('Farmer'))){
            PageReference newPage = new PageReference('/ems/EMSProfilePage');
            return newPage;
        }
        return null;
    }
    
    public EMSHomeCntrl(){
        if (UserInfo.getUserType().equalsIgnoreCase('GUEST')) {
            throw new NoAccessException();
        }
        userId = System.currentPageReference().getParameters().get('userId');
        if(userId == null || String.isBlank(userId)) {
            userId = UserInfo.getUserId();
        }
        userDB = [Select Firstname,Lastname,Corporate__c,lol__c,purina__c,seed__c,FGI__c from User Where Id=:userId LIMIT 1];
        try {
            //pending apps 
            List<Id> pendingConnectedAppIds = new List<Id>();
            for (UserProvisioningRequest urp: [SELECT ConnectedAppId FROM UserProvisioningRequest WHERE 
                                               SalesforceUserId=:userId and State != 'Completed' and State != 'Failed'])
            {
                pendingConnectedAppIds.add(urp.ConnectedAppId);
            }
            List<Application__c> pendingApps = [SELECT Name,Description__c,Short_description__c,Children_allowed__c,Business__c,FG_Instructions__c,FG_Max_Ents__c,FG_mgmt__c from Application__c where isDeleted = false 
                                                and Business__c != null and System_Application__c=false and Connected_App_Id__c IN :pendingConnectedAppIds];
            Map<String, List<Application__c>> pendingAppMap = new Map<String, List<Application__c>>();
            if(pendingApps != null && pendingApps.size() > 0) {
                List<Application__c> tempList3 = new List<Application__c>();
                for(Application__c app : pendingApps) {
                    if(app.Business__c.contains(';')) {
                        tempList3.add(app);
                    } else {
                        List<Application__c> tempList;
                        if (!pendingAppMap.containsKey(app.Business__c)){
                            tempList = new List<Application__c>();
                            tempList.add(app);
                            pendingAppMap.put(app.Business__c, tempList);
                        } else {
                            tempList = pendingAppMap.get(app.Business__c);
                            tempList.add(app);
                            pendingAppMap.put(app.Business__c, tempList);
                        }
                    }
                }
                if(!tempList3.isEmpty()) {
                    pendingAppMap.put('Multiple Business Units', tempList3);   
                }
            }
            //granted apps 
            List<Id> grantedConnectedAppIds = new List<Id>();
            for (UserProvAccount upa : [SELECT ConnectedAppId FROM UserProvAccount WHERE SalesforceUserId = :userId AND Status != 'Deactivated']){
                grantedConnectedAppIds.add(upa.ConnectedAppId);
            }
            List<Application__c> grantedApps = [SELECT Name,Home_Page__c,Description__c,Short_description__c,Business__c,FG_Instructions__c,FG_Max_Ents__c,FG_mgmt__c from Application__c where isDeleted = false 
                                                and Business__c != null and System_Application__c=false and Connected_App_Id__c IN :grantedConnectedAppIds];
            Map<String, List<Application__c>> grantedAppMap = new Map<String, List<Application__c>>();
            Map<String, Boolean> businnesUnitHomePage = new Map<String, Boolean>();
            if(grantedApps != null && grantedApps.size() > 0) {
                List<Application__c> tempList2 = new List<Application__c>();
                for(Application__c app : grantedApps) {
                    if(app.Home_Page__c) {
                        businnesUnitHomePage.put(app.Business__c, app.Home_Page__c);
                    }
                    if(app.Business__c.contains(';')) {
                        tempList2.add(app);
                    } else {
                        List<Application__c> tempList;
                        if (!grantedAppMap.containsKey(app.Business__c)){
                            tempList = new List<Application__c>();
                            tempList.add(app);
                            grantedAppMap.put(app.Business__c, tempList);
                        } else {
                            tempList = grantedAppMap.get(app.Business__c);
                            tempList.add(app);
                            grantedAppMap.put(app.Business__c, tempList);
                        }
                    }
                }
                if(!tempList2.isEmpty()) {
                    grantedAppMap.put('Multiple Business Units', tempList2);   
                }
            }
            
            //available apps 
            List<Id> availableConnectedAppIds = new List<Id>();
            availableConnectedAppIds.addAll(pendingConnectedAppIds);
            availableConnectedAppIds.addAll(grantedConnectedAppIds);
            List<Application__c> availableApps = [SELECT Name,ApproverType__c,Children_allowed__c,Short_description__c,Queue_Name__c,Approver__c,Group_Designation__c,Home_Page__c,App_Code__c,Description__c,Business__c,
                                                  Migrated__c,Connected_App_ID__c,Requires_Approval__c,FG_Instructions__c,FG_Max_Ents__c,FG_mgmt__c,
                                                  (SELECT AD_Group_Optional__c,AD_Group__c,Ent_Code__c,Id,Name FROM Entitlements__r)
                                                  from Application__c where isDeleted = false AND Visible__c = true
                                                  AND Business__c != null AND System_Application__c=false AND Connected_App_Id__c NOT IN :availableConnectedAppIds];
            Map<String, List<CatalogWrapper>> avalAppMap = new Map<String, List<CatalogWrapper>>();
            if(availableApps != null && availableApps.size() > 0) {
                List<CatalogWrapper> tempList1 = new List<CatalogWrapper>();
                List<CatalogWrapper> businessLinks = new List<CatalogWrapper>();
                for(Application__c app : availableApps) {
                    List<Entitlements__c> availableEnts =  app.Entitlements__r;
                    CatalogWrapper cw = new CatalogWrapper(app, availableEnts);
                    if(app.Business__c.contains(';') && isMultiAppShow(businnesUnitHomePage, app.Business__c)  
                        /*&& (businnesUnitHomePage.get(app.Business__c) != null && businnesUnitHomePage.get(app.Business__c))*/) {
                           tempList1.add(cw);
                       } else if(app.Home_Page__c) {
                           businessLinks.add(cw);
                       } else if ((businnesUnitHomePage.get(app.Business__c) != null && businnesUnitHomePage.get(app.Business__c))){
                           List<CatalogWrapper> tempList;
                           if (!avalAppMap.containsKey(app.Business__c)){
                               tempList = new List<CatalogWrapper>();
                               tempList.add(cw);
                               avalAppMap.put(app.Business__c, tempList);
                           } else {
                               tempList = avalAppMap.get(app.Business__c);
                               tempList.add(cw);
                               avalAppMap.put(app.Business__c, tempList);
                           }
                       }
                }
                if(!tempList1.isEmpty()) {
                    avalAppMap.put('Multiple Business Units', tempList1);   
                }
                if(!businessLinks.isEmpty()) {
                    avalAppMap.put('Business Link Home Pages', businessLinks);   
                }
            }
            Integer size = 0;
            for (List<CatalogWrapper> lists : avalAppMap.values())
                size += lists.size();
            APWrapper = new AccessPageWrapper(pendingApps.size(),grantedApps.size(), size, 
                                              pendingAppMap, grantedAppMap, avalAppMap);
        } catch(Exception e){
            System.debug('##############Exception################ => ' + e);
            System.debug('##############Exception################ => ' + e.getLineNumber());
            PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'There was a problem initializing the page.'));
        }
    }
    
    public PageReference requestAccess(){
        List<CatalogWrapper> listTobeSend = new List<CatalogWrapper>();
        for(List<CatalogWrapper> cww : APWrapper.avalAppMap.values()) {
            for(CatalogWrapper cw : cww) {
                if(cw.checked) {
                    listTobeSend.add(cw);
                }
            }
        }
        if(!Test.isRunningTest())
        	System.enqueueJob(new EMSRequestQueuable(listTobeSend, userId));
        
        PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.CONFIRM, 'Your requests have been submitted.  You will receive an email when they have been completed.'));
        return null;
    }
    
    private boolean isMultiAppShow(Map<String, Boolean> businnesUnitHomePage, String businessUnit) {
        boolean flag = false;
        for(String str : businessUnit.split('\\;')) {
            if(businnesUnitHomePage.containsKey(str) && businnesUnitHomePage.get(str)) {
                flag = true;
                break;
            }
        }
        
        return flag;
    }
}