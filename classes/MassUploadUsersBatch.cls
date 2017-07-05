/**
* @author Gurditta Garg
* @date March 2016
* @description This is batch class for Mass Upload
*/

global class  MassUploadUsersBatch implements Database.Batchable<PayLoadUser>, Database.AllowsCallouts, Database.Stateful {
    
    @TestVisible private List<PayLoadUser> recList = new List<PayLoadUser>();
    @TestVisible private List<ExcelRow> errorList = new List<ExcelRow>();
    @TestVisible private List<PayLoadUser> successList = new List<PayLoadUser>();
    @TestVisible private MassUploadUtil utilObj = new MassUploadUtil();
    
    public MassUploadUsersBatch(List<PayLoadUser> scope){
        recList = scope;
    }
    
    public Iterable<PayLoadUser> start(Database.BatchableContext BC){
        MassUploadUserFeeder bf = new MassUploadUserFeeder(recList);
        return bf;
    }
    
    public void execute(Database.BatchableContext BC, List<PayLoadUser> finalListToBeInserted){
        for(PayLoadUser payload : finalListToBeInserted) {
            if (!Test.isRunningTest())
                callService(payload);  
        }
    }
    
    public void finish(Database.BatchableContext BC){
        String finalstrError = '';
        String finalstrSuccess = '';
        if(errorList.isEmpty()) {
            finalstrError = null;
        } else {
            finalstrError = 'ID,Application,Entitlement,Error Code'+Constants.NEWLINE;
            finalstrError = finalstrError + processErrorLists();
        }
        if(successList.isEmpty()) {
            finalstrSuccess = null;
        } else {
            finalstrSuccess = 'ID,Application,Entitlement'+Constants.NEWLINE;
            finalstrSuccess = finalstrSuccess + processSuccessList();
            //System.debug('##############successList################ => ' + JSON.serializePretty(successList));
            new MassUploadInsertOnlySuccesses().insertRecords(successList);
        }
        if(finalstrError == null && finalstrSuccess != null) {
            utilObj.sendEmail(null,null, finalstrSuccess, 'Mass Upload Add Access Success','Mass Upload Add Access Batch Completed', utilObj.createEmailBody(bc.getJobId()));
        } else if(finalstrError != null && finalstrSuccess == null) {
            utilObj.sendEmail(finalstrError,'Mass Upload Add Access Failed',null,null,'Mass Upload Add Access Batch Completed', utilObj.createEmailBody(bc.getJobId()));
        } else if(finalstrError != null && finalstrSuccess != null) {
            utilObj.sendEmail(finalstrError,'Mass Upload Add Access Failed',finalstrSuccess,'Mass Upload Add Access Success','Mass Upload Add Access Batch Completed', utilObj.createEmailBody(bc.getJobId()));
        }
    }
    
    private void callService(PayLoadUser payload) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:LoL_Web_Services/api/idm/createuseraccess');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload.payload));
        Http http = new Http();
        
        HTTPResponse res = http.send(req);
        Map<String,String> response = (Map<String,String>)JSON.deserialize(res.getBody(),Map<String,String>.class);
        //System.debug('##############response################ => ' + JSON.serializePretty(response));
        if (res.getStatusCode() != 200) {
            String errorCode = response.get('errorCode');
            errorList.add(new ExcelRow(payload, errorCode));
            String msg = 'ERROR: Failed to execute service callout:LoL_Web_Services/api/idm/createuseraccess Payload -> ' + payload.payload + ' Response -> ' + res.getBody();
            System.DEBUG(msg);
        } else {
            successList.add(payload);
        }
    }
    
    private String processSuccessList() {
        String finalstr = '';
        for(PayLoadUser payload : successList) {
            finalstr = finalstr + payload.payload.Ag2agId + Constants.COMMA +  payload.payload.AppCode + Constants.COMMA + payload.payload.AppRole + Constants.NEWLINE;
        }
        //System.debug('##############successList############### => '+ JSON.serializePretty(successList));
        return finalstr;
    }    
    private String processErrorLists() {
        String finalstr = '';
        for(ExcelRow ER : errorList) {
            finalstr = finalstr + ER.payload.payload.Ag2agId + Constants.COMMA +  ER.payload.payload.AppCode + Constants.COMMA + ER.payload.payload.AppRole + + Constants.COMMA + ER.message + Constants.NEWLINE;
        }
        return finalstr;
    }
    
    public class ExcelRow {
        public PayLoadUser payload {get;set;}
        public String message {get;set;}
        public ExcelRow (PayLoadUser payload, String message) {
            this.payload = payload;
            this.message = message;
        }
    }
}