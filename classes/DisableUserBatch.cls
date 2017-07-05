public class DisableUserBatch implements Database.Batchable<User>, Database.AllowsCallouts, Database.Stateful {
    
    @TestVisible private List<User> recList = new List<User>();
    @TestVisible private List<User> successList = new List<User>();
    
    public DisableUserBatch(List<User> scope) {
        recList = scope;
    }
    
    public Iterable<User> start(Database.BatchableContext BC) {
        DisableUserFeeder bf = new DisableUserFeeder(recList);
        return bf;
    }
    
    public void execute(Database.BatchableContext BC, List<User> scope) {
        for(User usr : scope) {
            if (!Test.isRunningTest())
                disableUser(usr);
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        List<Id> userids = new List<Id>();
        List<User> finalListToBeUpdated = new List<User>();
        Datetime nowDate = Datetime.now();
        String dateOutput = nowDate.format('yyyyMMddHHmmss');
        System.debug('###########successList############ => ' + successList);
        for(User ur : successList) {
            ur.IsActive = false;
            ur.InactiveDate__c = System.now();
            ur.Email = 'DIS_'+dateOutput+'_'+ur.Email;
            ur.External_Fed_Id__c = '';
            finalListToBeUpdated.add(ur);
            userids.add(ur.Id);
        }
        Database.update(finalListToBeUpdated, false);
        EmailTemplate templateId = [SELECT Id from EmailTemplate where developername = 'Deletion_Notification_Email' LIMIT 1];
        OrgWideEmailAddress owea = [SELECT Id from OrgWideEmailAddress where DisplayName = 'Website Support' LIMIT 1];
        List<Messaging.MassEmailMessage> emailsList = new List<Messaging.MassEmailMessage>();
        List<List<ID>> lstWrapper = new List<List<ID>>();
        if(userids.size() > 250) {
            for(Integer i = 0 ; i < (userids.size()/250)+1 ; i++){
                List<ID> lstTemp = new List<ID>();
                for(Integer j=(i*250);(j<(i*250)+250) && j<userids.size() ; j++){
                    lstTemp.add(userids.get(j));
                }
                lstWrapper.add(lstTemp);
            }
        } else {
            lstWrapper.add(userids);
        }
        for(List<ID> LH : lstWrapper){
            if(owea != null && templateId != null) {
                Messaging.MassEmailMessage email = new Messaging.MassEmailMessage();        
                email.setTargetObjectIds(LH);
                email.setTemplateId(templateId.Id);
                email.setSaveAsActivity(false);
                emailsList.add(email);
            }
        } 
        if(!Test.isRunningTest()) {
            Messaging.sendEmail(emailsList);
        }
        updateUPAs(userids);scrambleContactEmail(userids);
    }
    
    private static void scrambleContactEmail(List<Id> userIds) {
        Datetime nowDate = Datetime.now();
        String dateOutput = nowDate.format('yyyyMMddHHmmss');
        List<Contact> conList = new List<Contact>();
        for(Contact con : [Select email from Contact where Related_External_User__c IN : userIds]) {
            con.Email = 'DIS_'+dateOutput+'_'+con.Email;
            conList.add(con);
        }
        ScrambleContactEmailBatch scb = new ScrambleContactEmailBatch(conList);
        Database.executeBatch(scb, 200);
    }
    
    private static void updateUPAs(List<Id> userIds) {
        List<UserProvAccount> finalListToBeUpdated = new List<UserProvAccount>();
        for(UserProvAccount upa : [Select SalesforceUserId,Status from UserProvAccount where SalesforceUserId IN: userIds]) {
            upa.Status = 'Deactivated';
            finalListToBeUpdated.add(upa);
        }
        if(!Test.isRunningTest()) {
            Database.executeBatch(new DisableUserBatchUPAs(finalListToBeUpdated));   
        }
    }
    
    private void disableUser(User payload) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:LoL_Web_Services/api/idm/disableuser');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('{"Ag2agId":"'+payload.External_Fed_Id__c+'","StatusCode":"inactive"}');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        Map<String,String> response = (Map<String,String>)JSON.deserialize(res.getBody(),Map<String,String>.class);
        System.debug('############response########### => ' + response);
        if (res.getStatusCode() == 200) {
            successList.add(payload);
        }
    }
}