public class NewUsersMassUploadValidateBatch implements Database.Batchable<NewUsersWrapper>, Database.AllowsCallouts, Database.Stateful {
    
    public List<NewUsersWrapper> recList = new List<NewUsersWrapper>();
    public List<ErrorRow> errorList = new List<ErrorRow>();
    public List<SuccessRow> successList = new List<SuccessRow>();
    public MassUploadUtil utilObj = new MassUploadUtil();
    public String profileId {get;set;}
    
    public NewUsersMassUploadValidateBatch(List<NewUsersWrapper> scope){
        recList = scope;
        profileId = [SELECT Id FROM Profile WHERE Name =: Constants.EMS_EXTERNAL_USER LIMIT 1].Id;
    }
    
    public Iterable<NewUsersWrapper> start(Database.BatchableContext BC){
        return recList;
    }
    
    public void execute(Database.BatchableContext BC, List<NewUsersWrapper> finalListToBeInserted){
        for(NewUsersWrapper uw : finalListToBeInserted) {
            if(uw.acc.Name != Constants.PENDINGACCOUNT){
                // In EMS.
                if(validateEmail(uw.usr.Email)){
                    // In AD.
                    Map<Boolean, String> mapIsValidateWithMessage = validateEmailInAD(uw.usr.Email);
                    List<boolean> listOfResponses = new List<boolean>(mapIsValidateWithMessage.keySet());
                    
                    if(mapIsValidateWithMessage != null && listOfResponses[0]){
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
                            comments += (userToInsert.seed__c?'\n Business unit: Winfield. Customer Number: ' + uw.winfieldUnit + '.':'');
                            comments += (String.isNotBlank(uw.rtrName.trim())?'\n Retailer Name: ' + uw.rtrName + '. Retailer City: ' + uw.rtrCity + '. Retailer State: ' + uw.rtrState + '.':'');
                            comments += (userToInsert.purina__c?'\n Business unit: Purina. AIMS Number: ' + uw.purinaUnit + '.':'');
                            comments += (userToInsert.corporate__c?'\n Business unit: Corporate. Farm ID/PAES #: ' + uw.corpUnit + '.':'');            
                            comments += (userToInsert.lol__c?'\n Business unit: Dairy Foods (LoL Maiden). Company: '+uw.lolUnit + '.':'');            
                            if (String.isNotBlank(uw.mgrName.trim())) {            
                                comments += '\n Registrant\'s Manager: ' 
                                    + ((String.isNotBlank(uw.mgrName.trim())) ? uw.mgrName: '')
                                    + ' (' + ((String.isNotBlank(uw.mgrPhone.trim())) ? ' ' + uw.mgrPhone : '')             
                                    + ((String.isNotBlank(uw.mgrEmail.trim())) ? ', ' + uw.mgrEmail.trim().toLowerCase() : '') + ')';               
                            }
                            userToInsert.Registration_Info__c = comments;
                            //New fields added for mass upload.
                            userToInsert.IsMassLoaded__c = true;
                            userToInsert.Status__c = 'Validated';
                            userToInsert.Registration_Date__c = System.Now();
                            
                            Database.saveresult sr = Database.insert(userToInsert,dlo);
                            String userId = sr.getId();
                            if(userId != null) {
                                //Set the default password to the user.
                                System.setPassword(userId,'M2n!' + utilObj.generateRandomString(5));
                                successList.add(new SuccessRow(uw, 'User is successfully validated and uploaded in EMS.'));
                            } else {
                                errorList.add(new ErrorRow(uw, 'Failed to register user in EMS'));
                            }
                        } catch (Exception e) {
                            errorList.add(new ErrorRow(uw, e.getMessage()));
                        }
                    }else
                        errorList.add(new ErrorRow(uw, mapIsValidateWithMessage.get(false)));                
                }else
                    errorList.add(new ErrorRow(uw, 'Email Id already exist in EMS or is landolakes Id.'));
            }else
                errorList.add(new ErrorRow(uw, 'User can\'t be associated with Pending Registration account.'));
        }
    }
    
    public void finish(Database.BatchableContext BC){
        String finalstrError = '';
        String finalstrSuccess = '';
        if(errorList.isEmpty()) {
            finalstrError = null;
        } else {
            finalstrError = 'FirstName,LastName,Email,Phone,Job,MgrName,MgrEmail,MgrPhone,RetailerName,RetailerCity,RetailerState,IsWinfield,RetailerNo,IsPurina,AccountNo,IsCorporate,FarmOrCoopName,IsDairy,CompanyName,IsFGI,AccountNo,IsMassLoad,Status,Error Comment'+Constants.NEWLINE;
            finalstrError = finalstrError + processErrorLists();
        }
        if(successList.isEmpty()) {
            finalstrSuccess = null;
        } else {
            finalstrSuccess = 'FirstName,LastName,Email,Phone,Job,MgrName,MgrEmail,MgrPhone,RetailerName,RetailerCity,RetailerState,IsWinfield,RetailerNo,IsPurina,AccountNo,IsCorporate,FarmOrCoopName,IsDairy,CompanyName,IsFGI,AccountNo,IsMassLoad,Status,Success Comment'+Constants.NEWLINE;
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
                ER.uw.usr.JobClassification__c+Constants.COMMA+ER.uw.mgrName+Constants.COMMA+ER.uw.mgrEmail+Constants.COMMA+ER.uw.mgrPhone+Constants.COMMA+
                ER.uw.rtrName+Constants.COMMA+ER.uw.rtrCity+Constants.COMMA+ER.uw.rtrState+Constants.COMMA+
                ER.uw.usr.seed__c+Constants.COMMA+ER.uw.winfieldUnit+Constants.COMMA+ER.uw.usr.purina__c+Constants.COMMA+ER.uw.purinaUnit+Constants.COMMA+
                ER.uw.usr.Corporate__c+Constants.COMMA+ER.uw.corpUnit+Constants.COMMA+ER.uw.usr.lol__c+Constants.COMMA+ER.uw.lolUnit+Constants.COMMA+
                Constants.COMMA+Constants.COMMA+Constants.COMMA+Constants.COMMA+ER.message+Constants.NEWLINE;
        }
        return finalstr;
    }
    
    private String processSuccessList() {
        String finalstr = '';
        for(SuccessRow ER : successList) {
            finalstr = finalstr+ER.uw.usr.FirstName+Constants.COMMA+ER.uw.usr.LastName+Constants.COMMA+ER.uw.usr.Email+Constants.COMMA+ER.uw.usr.Phone+Constants.COMMA+
                ER.uw.usr.JobClassification__c+Constants.COMMA+ER.uw.mgrName+Constants.COMMA+ER.uw.mgrEmail+Constants.COMMA+ER.uw.mgrPhone+Constants.COMMA+
                ER.uw.rtrName+Constants.COMMA+ER.uw.rtrCity+Constants.COMMA+ER.uw.rtrState+Constants.COMMA+
                ER.uw.usr.seed__c+Constants.COMMA+ER.uw.winfieldUnit+Constants.COMMA+ER.uw.usr.purina__c+Constants.COMMA+ER.uw.purinaUnit+Constants.COMMA+
                ER.uw.usr.Corporate__c+Constants.COMMA+ER.uw.corpUnit+Constants.COMMA+ER.uw.usr.lol__c+Constants.COMMA+ER.uw.lolUnit+Constants.COMMA+
                Constants.COMMA+Constants.COMMA+Constants.ISMASSLOADED+Constants.COMMA+Constants.STATUS+Constants.COMMA+ER.message+Constants.NEWLINE;
        }
        return finalstr;
    }
    
    private boolean validateEmail(String emailId){
        boolean isValid = true;
        if (emailId.containsIgnoreCase('@landolakes.com')){
            return false;
        }
        try{
            User userId = [Select Id from User where Email =: emailId AND ProfileId =: profileId limit 1];
            
            if(userId != null)
                isValid = false;
        }
        catch(Exception e){}
        
        return isValid;
    }
    
    public Map<boolean, String> validateEmailInAD(String emailId){
        Map<boolean, String> mapBoolWithString = new Map<boolean, String>();
        
        try{
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:LoL_Web_Services/api/idm/getloginid');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(Json.serialize(new EmailJSONObject(emailId)));
            Http http = new Http();
            HTTPResponse res;
            if(!Test.isRunningTest()){
                res = http.send(req);
            }else{
                res = new HTTPResponse();
                res.setStatus('Internal Error');
                res.setStatusCode(500);
            }
            
            if(res != null){
                if(res.getStatusCode() == 200){
                    mapBoolWithString.put(false, 'Email id already exist in AD');
                }
                else if(res.getStatusCode() == 401){
                    mapBoolWithString.put(false, 'There is an Unauthorized Access error when validating email in AD.');
                }else if(res.getStatusCode() == 400){
                    Map<String,String> response = (Map<String,String>)JSON.deserialize(res.getBody(),Map<String,String>.class);
                    if(response.get('errorCode') == 'User_Not_Found'){
                        mapBoolWithString.put(true, 'Email id doesn\'t exist in AD.');
                    }else{
                        mapBoolWithString.put(false, 'Multiple user with the same email id exist in AD.');
                    }
                }else if(res.getStatusCode() == 500){
                    mapBoolWithString.put(true, 'Email id doesn\'t exist in AD.');
                }
            }
        }
        catch(Exception e){
            mapBoolWithString.put(false, e.getMessage());
        }
        
        return mapBoolWithString;
    }
    
    class ErrorRow {
        NewUsersWrapper uw {get;set;}
        String message {get;set;}
        ErrorRow (NewUsersWrapper uw, String message) {
            this.uw = uw;
            this.message = message;
        }
    }
    
    class SuccessRow {
        NewUsersWrapper uw {get;set;}
        String message {get;set;}
        SuccessRow (NewUsersWrapper uw, String message) {
            this.uw = uw;
            this.message = message;
        }
    }
    
    class EmailJSONObject {
        String Email{get;set;}
        
        EmailJSONObject(String Email){
            this.Email = Email;
        }
    }
}