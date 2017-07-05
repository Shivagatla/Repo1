global without sharing class ExternalRequestCntrl {
    
    public ExternalRequestCntrl() {
    }
    
    public ExternalRequestCntrl(EMSHomeCntrl controller) {
    }
    
    @RemoteAction
    global static List<AccountWrapper> fetchAccountsForRequest(String appId, String cUserId){
        if(cUserId == null || String.isBlank(cUserId)){
            cUserId = UserInfo.getUserId();
        }
        List<AccountWrapper> accts = new List<AccountWrapper>();
        Id connAppId = [SELECT Connected_App_Id__c from Application__c where Id=:appId].Connected_App_Id__c;
        ApplicationHelper ah = new ApplicationHelper(connAppId);
        for(Account acc : ah.getFineGrainAccounts(cUserId,false)) {
            String accNo = String.isNotBlank(ah.getAppGUIDValue(acc)) ? ah.getAppGUIDValue(acc) : Constants.EMPTY;
            String addrs = (acc.BillingAddress != null) ? getAddressString(acc.BillingAddress) : Constants.EMPTY;
            accts.add(new AccountWrapper(acc.Name,addrs,accNo));
        }
        return accts;
    }
    
    @RemoteAction
    global static List<RequestField> prepopRequestFields(String appId,String cUserId){
        if(cUserId == null || String.isBlank(cUserId)){
            cUserId = UserInfo.getUserId();
        }
        List<RequestField> rfs = new List<RequestField>();
        List<Request_Field__c> rfcs = [SELECT Field_Label__c,Save_To_Object__c,Field_Type__c,Required__c,Field_Name__c FROM Request_Field__c WHERE Application__c =:appId ORDER BY Order__c];
        
        SObject soUser = [SELECT Ag2Ag_ID__c,Alias,BYOID__c,City,CommunityNickname,Manager_Email__c,Manager_Name__c,Manager_Phone__c, 
                          CompanyName,ContactId,Corporate__c,Country,Department,Email,Email_Verified__c,
                          Extension,Fax,FirstName,Grower__c,Id,JobClassification__c,LastName,lol__c,ManagerId,
                          MobilePhone,Name,Phone,PostalCode,purina__c,seed__c,State,Street,Title,
                          Username
                          FROM User where Id=:cUserId];
        
        SObject soContact = [SELECT Ag2Ag_ID__c,AssistantName,AssistantPhone,Birthdate,Department,Manager_Email__c,Manager_Name__c,Manager_Phone__c, 
                             Description,Email,MailingAddress,MailingCity,MailingCountry,MailingPostalCode,MailingState,MailingStreet,
                             Manager__c,MobilePhone,Phone,Salutation,Title 
                             FROM Contact where Id =:(Id)soUser.get('ContactId')];
        for(Request_Field__c rfc:rfcs){
            RequestField rf = new RequestField();
            rf.value = '';
            if( rfc.Save_To_Object__c != null && rfc.Save_To_Object__c.equalsIgnoreCase('User')){
                rf.value = (String)soUser.get(rfc.Field_Name__c);
            } else if( rfc.Save_To_Object__c != null && rfc.Save_To_Object__c.equalsIgnoreCase('Contact')){
                rf.value = (String)soContact.get(rfc.Field_Name__c);
            }
            if(rf.value == null) rf.value = Constants.EMPTY;
            rf.Id = rfc.Field_Label__c;
            rf.rfId = rfc.Id;
            rf.fieldType = rfc.Field_Type__c;
            rf.required = rfc.Required__c;
            rfs.add(rf);
        }
        return rfs;
    }
    
    public static SObject getNewSobject(String gett,String objId) {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Schema.SObjectType st = gd.get(gett);
        Sobject s = st.newSobject((ID)objId);
        return s;
    }
    
    @RemoteAction
    global static void submitRequest(String appId, List<AccountWrapper> accounts, List<RequestField> requestInfo, String comments, String cUserId){
        if(cUserId == null || String.isBlank(cUserId)){
            cUserId = UserInfo.getUserId();
        }
        Application__c app  = [SELECT Children_allowed__c,ApproverType__c,Migrated__c,Connected_App_ID__c,Queue_Name__c,Group_Designation__c,Home_Page__c,Approver__c,
                               DA_Approval_Required__c,Internal_Delegated_Bypass__c,Description__c,App_Code__c,Connected_App__c,Id,IsDeleted,Name,OwnerId,Requires_Approval__c,Needs_Role__c,
                               FG_Default_user_acct__c,FG_Filter_prefix__c,FG_Instructions__c,FG_Max_Ents__c,FG_mgmt__c,FG_Search_Filter__c 
                               FROM Application__c WHERE Id=:appId LIMIT 1];
        User targetUser = [SELECT Id, FirstName, LastName,External_fed_id__c,Ag2Ag_ID__c FROM User WHERE isActive = true AND Id = :cUserId LIMIT 1];
        if (!Boolean.valueOf(app.Migrated__c)) {
            UserProvisioningService ups = new UserProvisioningService();
            try{
                ups.entitleUser(targetUser,app,null,requestInfo+''); 
            }catch(Exception e){
            }
        } else{
            ID jobID = System.enqueueJob(new EMSCreateUPRQueueable(app,targetuser,comments,requestInfo,accounts,cUserId,'Create'));
        }
    }
    public static String getAddressString(Address addy){
        String assignedTo = (String.isNotBlank(addy.getStreet()) ? addy.getStreet()+ Constants.COMMA + Constants.SPACE : Constants.EMPTY) + 
            (String.isNotBlank(addy.getCity()) ? addy.getCity()+ Constants.COMMA + Constants.SPACE : Constants.EMPTY) + 
            (String.isNotBlank(addy.getState()) ? addy.getState()+ Constants.SPACE : Constants.EMPTY) + 
            (String.isNotBlank(addy.getPostalCode()) ? String.valueOf(addy.getPostalCode())+ Constants.COMMA + Constants.SPACE : Constants.EMPTY) +
            (String.isNotBlank(addy.getCountry()) ? addy.getCountry() : Constants.EMPTY);
        assignedTo = assignedTo.trim().removeEnd(',');
        return assignedTo;
    }
}