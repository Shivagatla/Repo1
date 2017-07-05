global class  MassUploadNewUsersBatch {
/*implements Database.Batchable<UserWrapper>, Database.AllowsCallouts, Database.Stateful {
    
    private List<UserWrapper> recList = new List<UserWrapper>();
    private List<ErrorRow> errorList = new List<ErrorRow>();
    private List<SuccessRow> successList = new List<SuccessRow>();
    private MassUploadUtil utilObj = new MassUploadUtil();
    
    public MassUploadNewUsersBatch(List<UserWrapper> scope){
        recList = scope;
    }
    
    public Iterable<UserWrapper> start(Database.BatchableContext BC){
        MassUploadNewUserFeeder bf = new MassUploadNewUserFeeder(recList);
        return bf;
    }
    
    public void execute(Database.BatchableContext BC, List<UserWrapper> finalListToBeInserted){
        //Map<String, String> usrAg2AgMap = new Map<String, String>();
        for(UserWrapper uw : finalListToBeInserted) {
            try{
                Map<String,String> response = (!Test.isRunningTest()) 
                    ? 
                    callService
                    (
                        new PayloadNewUser
                        (
                            uw.usr.FirstName,uw.usr.LastName,uw.usr.Email,uw.usr.Phone,uw.acc.Name,uw.businessUnit,'active','CUSTOMER',
                            Constants.WELCOME1,uw.usr.username,uw.acc.AIMS_Number__c,uw.acc.BillingState
                        )
                    ) 
                    : new Map<String,String>{'Ag2agId' => '_dummy01'};String ag2agID = response.get('Ag2agId');
                if (String.isBlank(ag2agID)) {
                    errorList.add(new ErrorRow(uw, 'Failed to generate Ag2Ag ID'));
                } else {
                    try {
                        Id newUserContactId;
                        Database.SaveResult srList = Database.insert(uw.con);
                        newUserContactId = srList.getId();
                        User userToInsert = uw.usr;
                        userToInsert.Alias = uw.usr.CommunityNickname.substring(0,7);
                        userToInsert.LocaleSidKey = 'en_US';
                        userToInsert.EmailEncodingKey = 'UTF-8';
                        userToInsert.LanguageLocaleKey = 'en_US';
                        userToInsert.timezonesidkey = 'America/Los_Angeles';
                        userToInsert.ContactId = newUserContactId;
                        Database.DMLOptions dlo = new Database.DMLOptions();
                        dlo.EmailHeader.triggerUserEmail = false;
                        String comments = '\n ';
                        comments = '--- Registration Form ---\n';
                        comments += 'Job classification: ' + userToInsert.JobClassification__c + '\n';
                        comments += (userToInsert.seed__c?'\n Business unit: Winfield. Customer Number: ' + uw.accNum:'');
                        comments += (userToInsert.purina__c?'\n Business unit: Purina. AIMS Number: ' + uw.accNum:'');
                        comments += (userToInsert.corporate__c?'\n Business unit: Corporate. FarmName: '+uw.acc.Name + ', Farm ID/PAES #: ' + uw.accNum:'');            
                        comments += (userToInsert.lol__c?'\n Business unit: Dairy Foods (LoL Maiden). Company: '+uw.acc.Name:'');            
                        if (String.isNotBlank(uw.mgrName.trim())) {            
                            comments += '\n Registrant\'s Manager: ' 
                                + ((String.isNotBlank(uw.mgrName.trim())) ? uw.mgrName: '') 
                                + ' (' + ((String.isNotBlank(uw.mgrPhone.trim())) ? ' ' + uw.mgrPhone : '')             
                                + ((String.isNotBlank(uw.mgrEmail.trim())) ? ', ' + uw.mgrEmail.trim().toLowerCase() : '') + ')';               
                        }
                        userToInsert.Registration_Info__c = comments;
                        Database.saveresult sr = Database.insert(userToInsert,dlo);
                        //System.debug('##########userToInsert#########= > ' + JSON.serializePretty(userToInsert));
                        //System.debug('##########sr#########= > ' + JSON.serializePretty(sr));
                        //String userId = Site.createExternalUser(userToInsert, uw.acc.Id, Constants.WELCOME1);
                        String userId = sr.getId();
                        if(userId != null) {
                            Id caseId = createCase(newUserContactId);
                            //usrAg2AgMap.put(userId, ag2agID);
                            if(!Test.isRunningTest() && caseId != null) {
                                assignEntitlements(userId, true);
                                successList.add(new SuccessRow(uw,ag2agID));
                            }
                        } else {
                            errorList.add(new ErrorRow(uw, 'Failed to register customer: userId returned by Site.createExternalUser is null'));
                        }
                    } catch (Exception e) {
                        errorList.add(new ErrorRow(uw, e.getMessage()));
                    }
                }
            } catch(Exception e){
                errorList.add(new ErrorRow(uw, e.getMessage()));
            }
        }
        /*List<User> usrListToBeUpdated = new List<User>();
for(User usr : [Select Ag2Ag_Id__C from User WHERE Id IN: usrAg2AgMap.keySet()]) {
usr.Ag2Ag_Id__C = usrAg2AgMap.get(usr.Id);
System.setPassword(usr.Id,'welcome1');
usrListToBeUpdated.add(usr);
}
Database.update(usrListToBeUpdated, false);
    }
    
    public void finish(Database.BatchableContext BC){
        String finalstrError = '';
        String finalstrSuccess = '';
        if(errorList.isEmpty()) {
            finalstrError = null;
        } else {
            finalstrError = 'FirstName,LastName,Email,Phone,Account,MgrName,MgrEmail,MgrPhone,Business Unit,Job,Error Code'+Constants.NEWLINE;
            finalstrError = finalstrError + processErrorLists();
        }
        if(successList.isEmpty()) {
            finalstrSuccess = null;
        } else {
            finalstrSuccess = 'FirstName,LastName,Email,Phone,Account,MgrName,MgrEmail,MgrPhone,Business Unit,Job,Success Ag2Ag ID'+Constants.NEWLINE;
            finalstrSuccess = finalstrSuccess + processSuccessList();
        }
        if(finalstrError == null && finalstrSuccess != null) {
            utilObj.sendEmail(null,null, finalstrSuccess, 'Mass Upload Success','Mass Upload New Users Batch Completed', utilObj.createEmailBody(bc.getJobId()));
        } else if(finalstrError != null && finalstrSuccess == null) {
            utilObj.sendEmail(finalstrError,'Mass Upload Failed',null,null,'Mass Upload New Users Batch Completed', utilObj.createEmailBody(bc.getJobId()));
        } else if(finalstrError != null && finalstrSuccess != null) {
            utilObj.sendEmail(finalstrError,'Mass Upload Failed',finalstrSuccess,'Mass Upload Success','Mass Upload New Users Batch Completed', utilObj.createEmailBody(bc.getJobId()));
        }
    }
    
    private String processErrorLists() {
        String finalstr = '';
        for(ErrorRow ER : errorList) {
            finalstr = finalstr+ER.uw.usr.FirstName+Constants.COMMA+ER.uw.usr.LastName+Constants.COMMA+ER.uw.usr.Email+Constants.COMMA+ER.uw.usr.Phone+Constants.COMMA+
                ER.uw.acc.GUID__c+Constants.COMMA+ER.uw.mgrName+Constants.COMMA+ER.uw.mgrEmail+Constants.COMMA+ER.uw.mgrPhone+Constants.COMMA+
                ER.uw.businessUnit+Constants.COMMA+ER.uw.usr.JobClassification__c+Constants.COMMA+ER.message+Constants.NEWLINE;
        }
        return finalstr;
    }
    
    private String processSuccessList() {
        String finalstr = '';
        for(SuccessRow ER : successList) {
            finalstr = finalstr+ER.uw.usr.FirstName+Constants.COMMA+ER.uw.usr.LastName+Constants.COMMA+ER.uw.usr.Email+Constants.COMMA+ER.uw.usr.Phone+Constants.COMMA+
                ER.uw.acc.GUID__c+Constants.COMMA+ER.uw.mgrName+Constants.COMMA+ER.uw.mgrEmail+Constants.COMMA+ER.uw.mgrPhone+Constants.COMMA+
                ER.uw.businessUnit+Constants.COMMA+ER.uw.usr.JobClassification__c+Constants.COMMA+ER.ag2agId+Constants.NEWLINE;
        }
        return finalstr;
    }  
    private Map<String,String> callService(PayloadNewUser payload) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:LoL_Web_Services/api/idm/createuser');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return (Map<String,String>)JSON.deserialize(res.getBody(),Map<String,String>.class);
    }
    class PayloadNewUser {
        String FirstName{get;set;}
        String LastName{get;set;}
        String Email{get;set;}
        String Telephone{get;set;}
        String Company{get;set;}
        String Division{get;set;}
        String StatusCode{get;set;}
        String UserType{get;set;}
        String Password{get;set;}
        String LoginName{get;set;}
        String CustomerNumber{get;set;}
        String State{get;set;}
        
        PayloadNewUser (String FirstName, String LastName, String Email, String Telephone,String Company, String Division, 
                        String StatusCode,String UserType,String Password,String LoginName,String CustomerNumber,String State) 
        {
            this.FirstName = FirstName;
            this.LastName = LastName;
            this.Email = Email;
            this.Telephone = Telephone;
            this.Company = Company;
            this.Division = Division;
            this.StatusCode = StatusCode;
            this.UserType = UserType;
            this.Password = Password;
            this.LoginName = LoginName;
            this.CustomerNumber = CustomerNumber;
            this.State = State;
        }        
    }
    class ErrorRow {
        UserWrapper uw {get;set;}
        String message {get;set;}
        ErrorRow (UserWrapper uw, String message) {
            this.uw = uw;
            this.message = message;
        }
    }
    class SuccessRow {
        UserWrapper uw {get;set;}
        String ag2agId {get;set;}
        SuccessRow (UserWrapper uw, String ag2agId) {
            this.uw = uw;
            this.ag2agId = ag2agId;
        }
    }
    
    private Id createCase(Id contactIdIn){
        List<User> usersL = [SELECT Id, FirstName, LastName,ContactId, Registration_Info__c, Name,corporate__c,purina__c,lol__c,seed__c FROM User WHERE  ContactId = :contactIdIn LIMIT 1];
        integer count = 0;
        Group reviewQueueQ;
        String reviewQueue = 'Default';
        User userC =null;
        String additionalComments ='';
        if(usersL == null || usersL.size() ==0){
            System.debug(LoggingLevel.ERROR, 'No user was associated with this contact:'+Contact.Id);
            additionalComments = ' No Salesforce User was found for this contact.  This needs to be remedied as well.\n';
        } else{
            userC = usersL[0];
            additionalComments = userC.Registration_Info__C+'\n';
            if (userC.corporate__c == true){
                reviewQueue='corp_registrations';
                count++;
            }
            if (userC.purina__c == true) {
                reviewQueue = 'Feed'; count++;
            }
            if (userC.seed__c == true) {
                reviewQueue = 'Winfield'; count++;
            }
            
            if (userC.lol__c == true) {
                reviewQueue = 'LoL_Maiden'; count++;
            }
            
        }
        if (count >1){
            reviewQueue='Default';
            additionalComments = additionalComments+ '\n*More than one business unit was selected.';
            System.debug('More than one business unit was found.');
        }
        if (count == 0){
            System.debug('no business unit was found');
            additionalComments = additionalComments+ '\n*No business unit was found.';
            reviewQueue='Default';
        }
        
        try {
            System.debug('Looking for queue:' + reviewQueue);
            reviewQueueQ = 
                [select Id, Name 
                 from Group 
                 where Type = 'Queue' 
                 and DeveloperName=:reviewQueue
                 limit 1];
        } catch (Exception ex) {
            System.debug('***Could not find Review Queue');
        }
        Case c = new Case(
            Priority = 'Medium',
            Subject = 'New Registration Needs Reviewed.  Queue: '+reviewQueueQ.Name,
            Description = 'Registration request for ' + (userC!=null?userC.Name:'Unknown User') +' needs to be reviewed.  Please review the data and close the case to activate the registration.\n'+((additionalComments!=null) ? (additionalComments) : ('')) ,
            Type='Review',
            Status = 'Reviewed and Accepted',
            ContactId = contactIdIn
        );
        try {
            c.Related_External_User__c = UserC.Id;
            c.RecordTypeId = [select Id from RecordType where DeveloperName = 'RegistrationReview' and SobjectType = 'Case' LIMIT 1].Id;
            c.ownerId = reviewQueueQ.Id;
            insert c;
        } catch (DMLException ex) {
            System.debug(LoggingLevel.ERROR,'Unable to get record type.');
        }
        return c.Id;
    }
    
    private void assignEntitlements(String userId, boolean baseline){
        User targetUser = [SELECT Ag2Ag_ID__c,Name,External_fed_id__c,jobClassification__c,purina__c,lol__c,corporate__c,seed__c,id from User where Id=:userId];
        String jobClass = targetUser.JobClassification__c;
        boolean purina = targetUser.purina__c;
        boolean dairy = targetUser.lol__c;
        boolean winfield = targetUser.seed__c;
        boolean corporate = targetUser.corporate__c;
        
        List<AP_Rule__c> appliedRules = [SELECT Id,Business_Unit__c,(select Id, App_Code__r.Name,App_Code__r.App_Code__c, Entitlement_Code__c from Policy_Artifacts__r) from AP_Rule__c where active__c=true and baseline__c =:baseline and Job_Classification__c includes ('Any',:jobClass)];
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
    }  */
}