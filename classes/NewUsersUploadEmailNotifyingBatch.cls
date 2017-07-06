public class NewUsersUploadEmailNotifyingBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    private List<ErrorRow> errorList = new List<ErrorRow>();
    private List<SuccessRow> successList = new List<SuccessRow>();
    public MassUploadUtil utilObj = new MassUploadUtil();
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id,FirstName,LastName,Name,Username,Ag2Ag_ID__c,External_fed_id__c,Email,Grower__c,Status__c,jobClassification__c,purina__c,lol__c,corporate__c,seed__c,IsMassLoaded__c from User where isActive = true AND IsMassLoaded__c = true AND Status__c = \'Provisioned\'';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        Map<String, User> mapUserIDWithUser = new Map<String, User>();
        for(User targetUser : (List<User>)scope){
            mapUserIDWithUser.put(targetUser.Id, targetUser);
        }
        
        if(mapUserIDWithUser != null){
            Set<String> setOfUIDds = validateUPAForUsers(mapUserIDWithUser.keySet());
        
            for(String uId : mapUserIDWithUser.keySet()){
                if(setOfUIDds.contains(uId)){
                    successList.add(new SuccessRow(mapUserIDWithUser.get(uId), 'UPA for the user exist in EMS. Email notification has been send to the user.'));
                }
                else{
                    errorList.add(new ErrorRow(mapUserIDWithUser.get(uId), 'User may not have got provisioning to Baseline application or UPA is not created for the user.'));
                }
            }
            
            if(!successList.isEmpty()){
                List<User> lUsers = new List<User>();
                for(SuccessRow sr : successList){
                    sr.uw.Status__c = 'Uploaded';
                    lUsers.add(sr.uw);
                }
                
                if(!lUsers.isEmpty())
                    Database.update(lUsers);
            }
        }        
    }
    
    public void finish(Database.BatchableContext BC){
        String finalstrError = '';
        String finalstrSuccess = '';
        
        if(!successList.isEmpty()){
            Map<boolean,EmailTemplate> mapBooleanWithEmailTemp = new Map<boolean,EmailTemplate>();
            List<Messaging.SendEmailResult> listEmailResult = null;
            List<User> lUser = new List<User>();
            List<Messaging.Singleemailmessage> listSingleEmailMessages = new List<Messaging.SingleEmailMessage>();
            
            for(EmailTemplate e : [SELECT Id, Subject, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName IN ('Mass_New_Users_Email_Notification', 'EMS_Mass_Grower_Upload')]){
                if(e.DeveloperName == 'Mass_New_Users_Email_Notification')
                    mapBooleanWithEmailTemp.put(false,e);
                else
                    mapBooleanWithEmailTemp.put(true,e);
            }
            
            EmailNotificationUrl__c enu = EmailNotificationUrl__c.getInstance(Constants.EMS);
            String siteUrl = enu.Url__c;
            
            for(SuccessRow sr : successList){
                lUser.add(sr.uw);
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setSenderDisplayName('Land O\'Lakes Customer Access Portal'); 
                mail.setReplyTo('noreply@salesforce.com');
                mail.setTargetObjectId(sr.uw.id);
                
                EmailTemplate emailTemplate;
                
                if(sr.uw.Grower__c)
                    emailTemplate = mapBooleanWithEmailTemp.get(true);
                else
                    emailTemplate = mapBooleanWithEmailTemp.get(false);
                
                String userName = sr.uw.FirstName+' '+sr.uw.LastName;
                String userId = '';
                String plainBody = emailTemplate.Body;  
                
                if(sr.uw.Grower__c){
                    userId = sr.uw.Email;
                }else{
                    userId = sr.uw.Ag2Ag_ID__c;
                }
                 
                String resetUrl = siteUrl + '/EMSEmailNotificationPage?key='+EMSForgotPasswordCntrl.issueJWT(sr.uw.Username, 259200);
                
                Map<String, String> mapBodyParams = new Map<String, String> {
                    '{!userName}' => userName,
                    '{!userId}' => userId,
                    '{!resetUrl}' => resetUrl
                };
                    
                for (String key : mapBodyParams.keySet()) {
                    plainBody = plainBody.replace(key, (mapBodyParams.get(key) == null) ? '' : mapBodyParams.get(key));
                }
                mail.setSaveAsActivity(false);
                mail.setPlainTextBody(plainBody);
                mail.setSubject(emailTemplate.subject);
                listSingleEmailMessages.add(mail);
            }
            
            if(!listSingleEmailMessages.isEmpty())
                listEmailResult = Messaging.sendEmail(listSingleEmailMessages);
        }
        
        if(errorList.isEmpty()) {
            finalstrError = null;
        } else {
            finalstrError = 'Id,Name,Job,isPurina,islol,isCorporate,isWinfield,IsMassLoaded,Status,Error Comment'+Constants.NEWLINE;
            finalstrError = finalstrError + processErrorLists();
        }
        if(successList.isEmpty()) {
            finalstrSuccess = null;
        } else {
            finalstrSuccess = 'Id,Name,Job,isPurina,islol,isCorporate,isWinfield,IsMassLoaded,Status,Success Comment'+Constants.NEWLINE;
            finalstrSuccess = finalstrSuccess + processSuccessList();
        }
       
        if(finalstrError == null && finalstrSuccess != null) {
            utilObj.sendEmail(null,null, finalstrSuccess, 'Mass Email Notification Success','Mass Email Notification New Users Batch Completed', utilObj.createEmailBody(bc.getJobId()));
        } else if(finalstrError != null && finalstrSuccess == null) {
            utilObj.sendEmail(finalstrError,'Mass Email Notification Failed',null,null,'Mass Email Notification New Users Batch Completed', utilObj.createEmailBody(bc.getJobId()));
        } else if(finalstrError != null && finalstrSuccess != null) {
            utilObj.sendEmail(finalstrError,'Mass Email Notification Failed',finalstrSuccess,'Mass Email Notification Success','Mass Email Notification New Users Batch Completed', utilObj.createEmailBody(bc.getJobId()));
        }
    }
    
    private String processErrorLists() {
        String finalstr = '';
        for(ErrorRow ER : errorList) {
            finalstr = finalstr+ER.uw.Id+Constants.COMMA+ER.uw.Name+Constants.COMMA+ER.uw.jobClassification__c+Constants.COMMA+
                ER.uw.purina__c+Constants.COMMA+ER.uw.lol__c+Constants.COMMA+ER.uw.corporate__c+Constants.COMMA+
                ER.uw.seed__c+Constants.COMMA+ER.uw.IsMassLoaded__c+Constants.COMMA+ER.uw.Status__c+Constants.COMMA+ER.message+Constants.NEWLINE;
        }
        return finalstr;
    }
    
    private String processSuccessList() {
        String finalstr = '';
        for(SuccessRow ER : successList) {
            finalstr = finalstr+ER.uw.Id+Constants.COMMA+ER.uw.Name+Constants.COMMA+ER.uw.jobClassification__c+Constants.COMMA+
                ER.uw.purina__c+Constants.COMMA+ER.uw.lol__c+Constants.COMMA+ER.uw.corporate__c+Constants.COMMA+
                ER.uw.seed__c+Constants.COMMA+ER.uw.IsMassLoaded__c+Constants.COMMA+ER.uw.Status__c+Constants.COMMA+ER.message+Constants.NEWLINE;
        }
        return finalstr;
    }
    
    Set<String> validateUPAForUsers(Set<String> uIds){
        Set<String> setOfUIds = new Set<String>();
        for(UserProvAccount upa : [Select Id, SalesforceUserId from UserProvAccount where SalesforceUserId =: uIds AND Status = 'Active']){
            setOfUIds.add(upa.SalesforceUserId);
        }
        
        return setOfUIds;
    }
    
    class ErrorRow {
        User uw {get;set;}
        String message {get;set;}
        ErrorRow (User uw, String message) {
            this.uw = uw;
            this.message = message;
        }
    }
    
    class SuccessRow {
        User uw {get;set;}
        String message {get;set;}
        SuccessRow (User uw, String message) {
            this.uw = uw;
            this.message = message;
        }
    }
}