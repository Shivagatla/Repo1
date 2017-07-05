public without sharing class ModifyAccessPopupCntrl {

    public SelectOption[] selectedEntitlements { get; set; }
    public SelectOption[] allEntitlements { get; set; }
    public SelectOption[] selectedAccts { get; set; }
    public SelectOption[] allAccts { get; set; }
    private String userId;
    private String applicationId;
    public User userForRequest{get;set;}
    public Application__c app{get;set;}
    public String comments{get;set;}
    ApplicationHelper ah;
    public Contact newContact{get;set;}
    public String message{get;set;}
    public Integer maxEnts{get;set;}
    

    public ModifyAccessPopupCntrl() {
        message = '';
        userId = System.currentPageReference().getParameters().get('userId');
        applicationId = System.currentPageReference().getParameters().get('appId'); // we are getting the app name
        selectedEntitlements =  new List<SelectOption>();
        allEntitlements = new List<SelectOption>();
        selectedAccts =  new List<SelectOption>();
        allAccts = new List<SelectOption>();
        newContact = new Contact();

        //get user information
        //userForRequest = [SELECT Id, Name from User where Id=:userId LIMIT 1];
        userForRequest = [Select Id,Name,Username,External_Fed_Id__c,FirstName,LastName,Email,Ag2Ag_ID__c from User where Id = :userId LIMIT 1];

        //get application information
        ah = new ApplicationHelper(applicationId);
        app = ah.getApplication();
        maxEnts = ah.getMaxEnts();

        List<Entitlements__c> availableEnts = ah.getAvailableEnts(userId, app.Id);
        List<Entitlements__c> provEnts = ah.getProvisionedEnts(userId, app.Id);
        for(Entitlements__c ent:availableEnts){
            allEntitlements.add(new SelectOption(ent.Id,ent.Name));
        }
        for(Entitlements__c ent:provEnts){
            selectedEntitlements.add(new SelectOption(ent.Id,ent.Name));
        }
        if (app!= null){
            List<Account> availableAccts = ah.getFineGrainAccounts(userId);
            List<Account> provAccts = ah.getProvisionedFEnts(userId);

           

           
            for(Account ent:provAccts){
                selectedAccts.add(new SelectOption(ent.Id,getAccountDesc(ah,ent)));
            }
            for(Account ent:availableAccts){
                if (!containsSO(selectedAccts,ent))
                    allAccts.add(new SelectOption(ent.Id,getAccountDesc(ah,ent)));
            }
        } else System.debug('applicationId is:' + applicationId + ' and app is:' + app);
    
    }

    public boolean containsSO(List<SelectOption> tocheck, Account objToCheck){

        boolean found = false;

        for (SelectOption ew:tocheck){
            if (ew.getValue()== objToCheck.Id) return true;
        }
        return found;

    }

    public void submitRequest(){
        List<Entitlements__c> ents = new List<Entitlements__c>();
        Set<Id> entIds = new Set<Id>();
        for ( SelectOption so : selectedEntitlements ) {
            entIds.add(so.getValue());
        }
        List<Account> accts = new List<Account>();
        Set<Id> acctIds = new Set<Id>();
        for ( SelectOption so2 : selectedAccts ) {
            acctIds.add(so2.getValue());
        }
        ents = [SELECT AD_Group_Optional__c,AD_Group__c,Approver__c,Ent_Code__c,Id,Name,ParentApp__c,Requires_Approval__c FROM Entitlements__c where Id in :entIds];
        accts = [SELECT BillingAddress,GUID__c,Id,Customer_number__c, PAES_Number__c, AIMS_NUmber__c,IsDeleted,Name,OwnerId,ParentId FROM Account where Id in :acctIds];
        System.debug('About to submit a modify request.');      
        ID jobID = System.enqueueJob(new EMSCreateUPRQueueable(ah.getApplication(),userForRequest,comments,UserInfo.getName(),(new Set<Entitlements__c>(ents)),(new Set<Account>(accts)),'Update'));
     }

    public void cancel(){


    }

    public void addAccount(){
         if (newContact != null && newContact.AccountId!=null){
            System.debug('Contact info:' + newContact.AccountId);

            if ((selectedAccts.size() +1)>ah.getMaxEnts()){
                //need to add page messages.
                message = 'This application is only allowed ' + ah.getMaxEnts() + ' account(s) to be assigned to the user.  Please unselect some accounts to add others.';

            }
            else{
                Account acct = [SELECT GUID__c,Name, PAES_Number__c, Customer_Number__c,AIMS_Number__c, BillingAddress From Account where id=:newContact.AccountId limit 1];
                selectedAccts.add(new SelectOption(acct.Id,getAccountDesc(ah,acct)));
                message = '';
            }
        }

    }

    private static String getAccountDesc(ApplicationHelper ah, Account acct){
        String appGuid = getAppGUID(ah,acct);
        String desc2;
            if (ah.getAcctFieldName().equalsIgnoreCase('GUID__c'))
                desc2 = acct.Name+' ('+acct.GUID__c +') ' + (acct.BillingAddress == null ? '' : ', '+getAddressString(acct.BillingAddress));
            else 
                desc2 = acct.Name+' ('+acct.GUID__c +', ' + appGuid +') ' + (acct.BillingAddress == null ? '' : ', '+getAddressString(acct.BillingAddress));
        return desc2;

    }

    public static String getAddressString(Address addy){
        if (addy==null) return null;
        String assignedTo = (String.isNotBlank(addy.getStreet()) ? addy.getStreet()+ Constants.COMMA + Constants.SPACE : Constants.EMPTY) + 
            (String.isNotBlank(addy.getCity()) ? addy.getCity()+ Constants.COMMA + Constants.SPACE : Constants.EMPTY) + 
            (String.isNotBlank(addy.getState()) ? addy.getState()+ Constants.SPACE : Constants.EMPTY) + 
            (String.isNotBlank(addy.getPostalCode()) ? String.valueOf(addy.getPostalCode())+ Constants.COMMA + Constants.SPACE : Constants.EMPTY) +
            (String.isNotBlank(addy.getCountry()) ? addy.getCountry() : Constants.EMPTY);
        assignedTo = assignedTo.trim().removeEnd(',');
        return assignedTo;
    }

     public static String getAppGUID(ApplicationHelper ah,Account acct){
        String fieldName = ah.getAcctFieldName();
                if (fieldName.equalsIgnoreCase('GUID__C') && !String.isBlank(acct.GUID__c))
                    return 'Global ID:'+ acct.GUID__c;
                else if (fieldName.equalsIgnoreCase('Customer_Number__c') && !String.isBlank(acct.Customer_Number__c))
                    return 'Customer #:' +acct.Customer_Number__c; 
                else if (fieldName.equalsIgnoreCase('PAES_Number__c') && !String.isBlank(acct.PAES_Number__c))
                    return 'PAES #:'+acct.PAES_Number__c; 
                else if (fieldName.equalsIgnoreCase('AIMS_Number__c') && !String.isBlank(acct.AIMS_Number__c))
                    return 'AIMS #:'+acct.AIMS_Number__c;
        return fieldName + ' is null';
    }


    
}