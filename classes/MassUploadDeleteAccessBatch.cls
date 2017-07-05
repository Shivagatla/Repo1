/**
* @author Gurditta Garg
* @date March 2016
* @description This is batch class for Mass Delete Access
*/

global class MassUploadDeleteAccessBatch implements Database.Batchable<Payload>, Database.AllowsCallouts, Database.Stateful {
    
    private List<Payload> recList = new List<Payload>();
    @TestVisible private Set<ExcelRow> errorList = new Set<ExcelRow>();
    @TestVisible private Set<Payload> successList = new Set<Payload>();
    @TestVisible private MassUploadUtil utilObj = new MassUploadUtil();
    private Map<String,String> p_failedList;
    
    public MassUploadDeleteAccessBatch(List<Payload> scope, Map<String,String> failedList){
        recList = scope;
        p_failedList = failedList;
    }
    
    public Iterable<Payload> start(Database.BatchableContext BC){
        MassUploadDeleteAccessrFeeder bf = new MassUploadDeleteAccessrFeeder(recList);
        return bf;
    }
    
    public void execute(Database.BatchableContext BC, List<Payload> finalListToBeInserted){
        for(Payload payload : finalListToBeInserted) {
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
            finalstrError = 'ID,Application,Error Code'+Constants.NEWLINE;
            finalstrError = finalstrError + processErrorLists();
        }
        if(successList.isEmpty()) {
            finalstrSuccess = null;
        } else {
            finalstrSuccess = 'ID,Application'+Constants.NEWLINE;
            finalstrSuccess = finalstrSuccess + processSuccessList();
        }
        if(finalstrError == null && finalstrSuccess != null) {
            utilObj.sendEmail(null,null, finalstrSuccess, 'Mass Upload Delete Access Success','Mass Upload Delete Access Batch Completed', utilObj.createEmailBody(bc.getJobId()));
        } else if(finalstrError != null && finalstrSuccess == null) {
            utilObj.sendEmail(finalstrError,'Mass Upload Delete Access Failed',null,null,'Mass Upload Delete Access Batch Completed', utilObj.createEmailBody(bc.getJobId()));
        } else if(finalstrError != null && finalstrSuccess != null) {
            utilObj.sendEmail(finalstrError,'Mass Upload Delete Access Failed',finalstrSuccess,'Mass Upload Delete Access Success','Mass Upload Delete Access Batch Completed', utilObj.createEmailBody(bc.getJobId()));
        }
    }
    
    private void callService(Payload payload) {
        System.debug('############payload############## => ' + payload);
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:LoL_Web_Services/api/idm/disableuseraccess');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        System.debug('###########payload.AppRole############ = > ' + payload.AppRole);
        List<String> approles = payload.AppRole.split('~');
        System.debug('###########approles############ = > ' + approles);
        req.setBody(JSON.serialize(new PayloadDelete(payload.Ag2agId,payload.AppCode,payload.ApplicationMigrationStatus,payload.ADGroup,approles)));
        Http http = new Http();
        System.debug('############getBody############## => ' + req.getBody());
        HTTPResponse res = http.send(req);
        Map<String,String> response = (Map<String,String>)JSON.deserialize(res.getBody(),Map<String,String>.class);
        System.debug('############response############## => ' + response);
        if (res.getStatusCode() != 200) {
            String errorCode = response.get('errorCode');
            errorList.add(new ExcelRow(payload, errorCode));
        } else {
            successList.add(payload);
        }
    }
    
    private String processSuccessList() {
        String finalstr = '';
        for(Payload payload : successList) {
            finalstr = finalstr + payload.Ag2agId + Constants.COMMA +  payload.AppCode + Constants.NEWLINE;
        }
        //System.debug('##############successList############### => '+ JSON.serializePretty(successList));
        return finalstr;
    }    
    private String processErrorLists() {
        String finalstr = '';
        for(ExcelRow ER : errorList) {
            finalstr = finalstr + ER.payload.Ag2agId + Constants.COMMA +  ER.payload.AppCode + Constants.COMMA + ER.message + Constants.NEWLINE;
        }
        for(String str : p_failedList.values()) {
            finalstr = finalstr + str + Constants.COMMA + 'Could not update UPA' + Constants.NEWLINE;
        }
        return finalstr;
    }
    public class ExcelRow {
        Payload payload {get;set;}
        String message {get;set;}
        public ExcelRow (Payload payload, String message) {
            this.payload = payload;
            this.message = message;
        }
    }
    public class PayloadDelete {
        public String Ag2agId{get;set;}
        public String AppCode{get;set;}
        public String ApplicationMigrationStatus{get;set;}
        public List<String> ADGroup{get;set;}
        public List<String> AppRole{get;set;}
        
        public PayloadDelete (String Ag2agId, String AppCode, String ApplicationMigrationStatus, List<String> ADGroup, List<String> AppRole) {
            this.Ag2agId = Ag2agId;
            this.AppCode = AppCode;
            this.ApplicationMigrationStatus = ApplicationMigrationStatus;
            this.ADGroup = ADGroup;
            this.AppRole = AppRole;
        }        
    }
}