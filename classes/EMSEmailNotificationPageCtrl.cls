public class EMSEmailNotificationPageCtrl {
    public String subject {get;set;}
    public Integer expires {get;set;}
    public boolean validToken {get;set;}
    public boolean isSuccess {get;set;}
    public boolean isAgThAgreement {get;set;}
    public boolean isGrower {get;set;}
    public String GROWERRECORDTYPE;
    public String agreementDocId;
    public String agTechPDFUrl {get{agTechPDFUrl=Label.AgTechPDFUrl + agreementDocId; return agTechPDFUrl;}set;}
    public String password {get; set {password = value == null ? value : value.trim(); } }
    public String confirmPassword {get; set { confirmPassword = value == null ? value : value.trim(); } }
    
    private boolean isValidPassword() {
        return password == confirmPassword;
    }
    
    public EMSEmailNotificationPageCtrl(){        
        List<Environment_Record_Ids__c> listRecordIds = Environment_Record_Ids__c.getAll().values();
        for(Environment_Record_Ids__c e: listRecordIds){
            if(e.Name.equals('Agreement Document Id'))
                agreementDocId = e.Record_Id__c;
            else if(e.Name.equals('Agreement Grower Record Type'))
                GROWERRECORDTYPE = e.Record_Id__c;
        }
        
        this.isSuccess = false;
        
        String token = System.currentPageReference().getParameters().get('key');
        
        if(String.isNotBlank(token)){
            String[] parts = token.split('\\.');
            Blob key = EncodingUtil.base64Decode('Ysllowklal2l4l12l0kkk1lKhh222kk2');
            Blob signature = Crypto.generateMac('hmacSHA1',Blob.valueof(parts[0]),key);
            String calculatedSignature = base64URLencode(signature);
            if ( calculatedSignature.equals(parts[1]) ) {
                String claim = EncodingUtil.base64Decode(parts[0]).toString();
                JSONParser parser = JSON.createParser(claim);
                while (parser.nextToken() != null) {
                    if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                        String fieldName = parser.getText();
                        parser.nextToken();
                        if(fieldName == 'sub') {
                            this.subject = parser.getText();
                        } else if(fieldName == 'exp'){
                            this.expires = parser.getIntegerValue();
                        }
                    }
                }
                
                Long rightNow = (dateTime.now().getTime()/1000)+1;
                if (expires > rightNow){
                    this.validToken = true;
                }
            }
        }
        
        this.isGrower = checkGrower(this.subject);
        
        if(this.isGrower)
            isAgThAgreement = true;
        else
            isAgThAgreement = false;
    }
    
    public Pagereference submit(){
        boolean success = true;
        try{
            if(isAgThAgreement){
                List<User> users = [select id,Grower__c,seed__c from user where username = :this.subject limit 1];
                
                if (users.size() == 1 && users[0].Grower__c && users[0].seed__c && allowToAccept(users[0].Id)){                    
                    Agreement__c agtObj = new Agreement__c();
                    agtObj.Sign_Date__c = System.today();
                    agtObj.Grower_User__c = users[0].id;
                    agtObj.Type__c = 'Ag Tech Agreement';
                    agtObj.RecordTypeId = GROWERRECORDTYPE;
                    
                    if(isAgThAgreement)
                        agtObj.Sign_Status__c = 'Accepted';
                    else
                        agtObj.Sign_Status__c = 'Declined';
                    
                    Database.insert(agtObj);                    
                }
            }
            
            if (isValidPassword()) {
                List<User> users = [select id from user where username = :this.subject limit 1];
                try {
                    if (users.size() == 1) System.setPassword(users.get(0).id, password);
                } catch (Exception e) {
                    success = false; 
                }
                if (success){
                    if (users.size()==1 && !Test.isRunningTest()){
                        ID jobID = System.enqueueJob(new UserProvisioningServiceQueuable('CHANGEPASSWORD',users.get(0).Id, password));
                    }                
                }
            }
            
            this.isSuccess = true;
        }catch(Exception e){
            String msg = 'Error : ' + e.getMessage();
            PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, msg));
        }
        
        return null;
    }
    
    public boolean allowToAccept(String uId){
        boolean isAllow = true;
        
        List<Agreement__c> aList = [Select id from Agreement__c where Grower_User__c =: uId AND RecordTypeId =: GROWERRECORDTYPE order by createddate DESC limit 1];
        
        if(!aList.isEmpty())
            isAllow = false;
        
        return isAllow;
    }
    
    public boolean checkGrower(String subject){
        boolean isG = false;
        List<User> users = [select id,Grower__c from user where username = :this.subject limit 1];
        
        if(!users.isEmpty() && users[0].Grower__c){
            isG = true;
        }
        
        return isG;
    }
    
    public static String base64URLencode(Blob input){ 
        String output = encodingUtil.base64Encode(input);
        output = output.replace('+', '-');
        output = output.replace('/', '_');
        while ( output.endsWith('=')){
            output = output.subString(0,output.length()-1);
        }
        return output;
    }
}