public class NewUsersMassUploadCtrl {
    public transient Blob csvFileBodyImportNew {get;set;}
    public Integer fileSizeImportNew {get;set;}
    public transient String contentTypeImportNew {get;set;}
    private MassUploadUtil utilObj = new MassUploadUtil();
    
    private List<NewUsersWrapper> createNewUserWrappers(List<List<String>> rowList) {
        Map<Integer, List<String>> mapCountWithRows = new Map<Integer, List<String>>();
        Map<Integer, String> mapCountWithWinfieldAcc = new Map<Integer, String>();
        Map<Integer, String> mapCountWithRtNCS = new Map<Integer, String>();
        Map<Integer, String> mapCountWithPurinaAcc = new Map<Integer, String>();
        Map<Integer, String> mapCountWithCorporateAcc = new Map<Integer, String>();
        Map<Integer, String> mapCountWithDairyAcc = new Map<Integer, String>();
        
        for(Integer i = 0; i<rowList.size(); i++){
            mapCountWithRows.put(i, rowList[i]);
            
            List<String> rList = rowList[i];
            
            if(String.isNotBlank(rList[11]) && rList[11].toLowerCase().trim() == 'true'){
                if(String.isNotBlank(rList[12].trim())){
                    mapCountWithWinfieldAcc.put(i, rList[12].trim());
                }
                if(String.isNotBlank(rList[8].trim()) && String.isNotBlank(rList[9].trim()) && String.isNotBlank(rList[10].trim())){
                    mapCountWithRtNCS.put(i, rList[8].trim()+Constants.HASH+rList[9].trim()+Constants.HASH+rList[10].trim());
                }
            }
            if(String.isNotBlank(rList[13]) && rList[13].toLowerCase().trim() == 'true' && String.isNotBlank(rList[14].trim())){
                mapCountWithPurinaAcc.put(i, rList[14].trim());
            }
            if(String.isNotBlank(rList[15]) && rList[15].toLowerCase().trim() == 'true' && String.isNotBlank(rList[16].trim())){
                mapCountWithCorporateAcc.put(i, rList[16].trim());
            }
            if(String.isNotBlank(rList[17]) && rList[17].toLowerCase().trim() == 'true' && String.isNotBlank(rList[18].trim())){
                mapCountWithDairyAcc.put(i, rList[18].trim());
            }        
        }
        
        Map<Integer, Account> mapCountWithAccId = fetchAccountIds(mapCountWithRows.keySet(), mapCountWithWinfieldAcc, mapCountWithRtNCS, mapCountWithPurinaAcc, mapCountWithCorporateAcc, 
                                                                 mapCountWithDairyAcc);
        
        return createNewUsers(mapCountWithRows, mapCountWithAccId);
    }
    
    private List<NewUsersWrapper> createNewUsers(Map<Integer, List<String>> mapCountWithRows, Map<Integer, Account> mapCountWithAccId){
        String profileId = [SELECT Id FROM Profile WHERE Name =: Constants.EMS_EXTERNAL_USER LIMIT 1].Id;
        Environment__c env = Environment__c.getInstance(Constants.EMS);
        List<NewUsersWrapper> toBeReturnList = new List<NewUsersWrapper>();
        
        for(Integer i : mapCountWithRows.keySet()){
            List<String> rList = mapCountWithRows.get(i);
            Account acc = mapCountWithAccId.get(i);
            
            User newUser = new User();
            String accountId = acc.Id;
            String usernameBase = utilObj.generateRandomString(10);
            newUser.Username = usernameBase + env.Username_Suffix__c;
            newUser.Initial_password__c = 'M2n!' + utilObj.generateRandomString(5);
            newUser.CommunityNickname = usernameBase;
            newUser.ProfileId = profileId;
            newUser.Email = rList[2].trim();
            newUser.Phone = rList[3].trim();
            newUser.FirstName = rList[0].trim();
            newUser.LastName = rList[1].trim();
            newUser.JobClassification__c = rList[4].trim();
            if(rList[4].trim() == 'Farmer')
                newUser.Grower__c = true;
            newUser.Registration_Status__c = Constants.APPROVED;
            if(rList[11].toLowerCase().trim() == 'true') {
                newUser.seed__c = true;
            }
            if (rList[13].toLowerCase().trim() == 'true') {
                newUser.purina__c = true;
            }
            if(rList[17].toLowerCase().trim() == 'true') {
                newUser.lol__c = true;
            }
            if (rList[15].toLowerCase().trim() == 'true') {
                newUser.Corporate__c = true;
            }
            // Include FGI later.
            Contact newUserContact = new Contact(
                FirstName = rList[0].trim(),
                Lastname = rList[1].trim(),
                AccountId = acc.Id,
                Email = rList[2].trim(),
                Registration_Denied__c = false,
                Manager_Name__c = rList[5].trim(),
                Manager_Email__c = rList[6].trim(),
                Manager_Phone__c = rList[7].trim(),
                Retailer_Name__c = rList[8].trim(),
                Retailer_City__c = rList[9].trim(),
                Retailer_State__c = rList[10].trim()
            );
            if(rList[11].toLowerCase().trim() == 'true') {
                newUserContact.Retailer_Number__c = rList[12].trim();
            }
            toBeReturnList.add(new NewUsersWrapper(newUser, newUserContact, acc, rList[12].trim(),rList[14].trim(),rList[18].trim(),rList[16].trim(),
                                               rList[5].trim(),rList[6].trim(),rList[7].trim(),rList[8].trim(), rList[9].trim(),rList[10].trim()));
        }
        
        return toBeReturnList;
    } 
    
    private Map<Integer, Account> fetchAccountIds(Set<integer> counts, Map<Integer, String> mapCountWithWinfieldAcc, Map<Integer, String> mapCountWithRtNCS, Map<Integer, String> mapCountWithPurinaAcc, 
                                                 Map<Integer, String> mapCountWithCorporateAcc, Map<Integer, String> mapCountWithDairyAcc)
    {
        Map<Integer, Account> mapCountWithAccs = new Map<Integer, Account>();
        Map<String, Account> mapCustomerNoWithAccs = new Map<String, Account>();
        Map<String, Account> mapAIMSNoWithAccs = new Map<String, Account>();
        Map<String, Account> mapFarmIdWithAccs = new Map<String, Account>();
        Map<String, Account> mapNameWithAccs = new Map<String, Account>();
        
        List<String> rNList = new List<String>();
        List<String> rCList = new List<String>();
        List<String> rSList = new List<String>();        
        
        //For winfield
        for(Account acc: [Select id, Name, Business_Unit_Key__c, Customer_Number__c, BillingState From Account WHERE Customer_Number__c =: mapCountWithWinfieldAcc.values()]){
            mapCustomerNoWithAccs.put(acc.Customer_Number__c, acc);
        }
        //For purina
        for(Account acc: [Select id, Name, Business_Unit_Key__c, Customer_Number__c, AIMS_Number__c, BillingState From Account WHERE AIMS_Number__c = : mapCountWithPurinaAcc.values() and Business_Unit_Key__c ='FEED']){
            mapAIMSNoWithAccs.put(acc.AIMS_Number__c, acc);
        }
        //For corporate
        for(Account acc: [Select id, Name, Business_Unit_Key__c, Customer_Number__c, Farm_ID__c, PAES_Number__c, BillingState FROM Account WHERE (Farm_ID__c=: mapCountWithCorporateAcc.values() OR PAES_Number__c =: mapCountWithCorporateAcc.values()) AND (recordTypeID in (SELECT Id FROM RecordType WHERE Name = 'Corporate'))]){
            if(acc.Farm_ID__c != null)
                mapFarmIdWithAccs.put(acc.Farm_ID__c, acc);
            else
                mapFarmIdWithAccs.put(acc.PAES_Number__c, acc);
        }
        //For dairy
        for(Account acc: [Select id, Name, Business_Unit_Key__c, Customer_Number__c, BillingState FROM Account WHERE Name = : mapCountWithDairyAcc.values()]){
            mapNameWithAccs.put(acc.Name, acc);
        }
        //For pending account
        Account accPR = [Select id, Name, Business_Unit_Key__c, Customer_Number__c, BillingState FROM Account WHERE Name = 'Pending Registrations' limit 1];
        
        for(Integer i : mapCountWithWinfieldAcc.keySet()){
            if(mapCustomerNoWithAccs.containsKey(mapCountWithWinfieldAcc.get(i))){
                mapCountWithAccs.put(i, mapCustomerNoWithAccs.get(mapCountWithWinfieldAcc.get(i)));
            }
        }
        
        for(Integer i : mapCountWithRtNCS.keySet()){
            if(!mapCountWithAccs.containsKey(i)){
                String str = mapCountWithRtNCS.get(i);
                List<String> strList = str.split(Constants.HASH);
                
                rNList.add(strList[0]);
                rCList.add(strList[1]);
                rSList.add(strList[2]);
            }
        }
        
        //When customer no doesn't matches for winfield.
        if(!rNList.isEmpty() && !rCList.isEmpty() && !rSList.isEmpty()){
            for(Account a : [SELECT Id, Name, Business_Unit_Key__c, Customer_Number__c, BillingCity, BillingState FROM Account WHERE Name =:rNList AND BillingCity =:rCList AND BillingState =:rSList]){
                for(Integer i : mapCountWithRtNCS.keySet()){
                    if(mapCountWithRtNCS.get(i).contains(a.Name) && mapCountWithRtNCS.get(i).contains(a.BillingCity) && mapCountWithRtNCS.get(i).contains(a.BillingCity)){
                        mapCountWithAccs.put(i, a);
                    }
                }
            }
        }
        
        for(Integer i : mapCountWithPurinaAcc.keySet()){
            if(mapAIMSNoWithAccs.containsKey(mapCountWithPurinaAcc.get(i)) && !mapCountWithAccs.containsKey(i)){
                mapCountWithAccs.put(i, mapAIMSNoWithAccs.get(mapCountWithPurinaAcc.get(i)));
            }
        }
        
        for(Integer i : mapCountWithCorporateAcc.keySet()){
            if(mapFarmIdWithAccs.containsKey(mapCountWithCorporateAcc.get(i)) && !mapCountWithAccs.containsKey(i)){
                mapCountWithAccs.put(i, mapFarmIdWithAccs.get(mapCountWithCorporateAcc.get(i)));
            }
        }
        
        for(Integer i : mapCountWithDairyAcc.keySet()){
            if(mapNameWithAccs.containsKey(mapCountWithDairyAcc.get(i)) && !mapCountWithAccs.containsKey(i)){
                mapCountWithAccs.put(i, mapNameWithAccs.get(mapCountWithDairyAcc.get(i)));
            }
        }
        
        // The left overs are for Pending Account.
        for(Integer ii : counts){
            if(!mapCountWithAccs.containsKey(ii)){
                mapCountWithAccs.put(ii, accPR);
            }
        }
        return mapCountWithAccs;
    }
    
    public PageReference doValidateAndUpload() {
        PageReference partnerAccountAssignmentPage = new PageReference('/apex/MassUploadNewUsersPage');
        partnerAccountAssignmentPage.setRedirect(true);
        try {            
            if(csvFileBodyImportNew != null && fileSizeImportNew > 0 && contentTypeImportNew != null && contentTypeImportNew.contains(Constants.CSV)) {
                List<List<String>> rows = utilObj.parseCSV(utilObj.blobToString(csvFileBodyImportNew,Constants.BLOB_ENCODE), true);
                
                if(rows.size() <= 0 || rows == null) {
                    return utilObj.uploadingFalied();
                }
                
                // remove duplicate rows and rows with blank FirstName,LastName and Email columns.
                Map<String, List<String>> incomingRecords = new Map<String, List<String>>();
                List<String> doNotProcess = new List<String>();
                Set<String> accNumberList = new Set<String>();
                Set<String> mgrIdList = new Set<String>();
                for (List<String> row : rows) {
                    if (row.size() > 0 && checkMandatoryColumns(row)) 
                    {
                        incomingRecords.put(
                            row[0].trim()+Constants.HASH+row[1].trim()+Constants.HASH+
                            row[2].trim()+Constants.HASH+row[3].trim()+Constants.HASH+
                            row[4].trim()+Constants.HASH+row[5].trim()+Constants.HASH+
                            row[6].trim()+Constants.HASH+row[7].trim()+Constants.HASH+
                            row[8].trim()+Constants.HASH+row[9].trim()+Constants.HASH+
                            row[10].trim()+Constants.HASH+row[11].trim()+Constants.HASH+
                            row[12].trim()+Constants.HASH+row[13].trim()+Constants.HASH+
                            row[14].trim()+Constants.HASH+row[15].trim()+Constants.HASH+
                            row[16].trim()+Constants.HASH+row[17].trim()+Constants.HASH+
                            row[18].trim()+Constants.HASH+row[19].trim()+Constants.HASH+
                            row[20].trim(), row);
                    } else {
                        doNotProcess.add(String.join(row, Constants.COMMA));
                    }
                }
                
                if(doNotProcess.size() > 0) {
                    String finalstr = 'FirstName,LastName,Email,Phone,Job,MgrName,MgrEmail,MgrPhone,RetailerName,RetailerCity,RetailerState,IsWinfield,RetailerNo,IsPurina,AccountNo,IsCorporate,FarmOrCoopName,IsDairy,CompanyName,IsMassLoad,Status,Reason'+Constants.NEWLINE;
                    for(String error : doNotProcess) {
                        error = error.replace('\r\n', '');
                        error = error.replace('\n', '');
                        error = error.replace('\r', '');
                        finalstr = finalstr + error +',One of the mandatory field is missing.'+ Constants.NEWLINE;
                    }
                    MassUploadUtil utilObj = new MassUploadUtil();
                    utilObj.sendEmail(finalstr,'Mass Upload Errors',null,null,'Mass Upload New User Failed', createEmailBody());
                }
                
                if(incomingRecords != null){
                    List<NewUsersWrapper> toBeSendToBatch = createNewUserWrappers(incomingRecords.values());
                    
                    NewUsersMassUploadValidateBatch massBatch = new NewUsersMassUploadValidateBatch(toBeSendToBatch);
                    if(!Test.isRunningTest()){                        
                        Database.executeBatch(massBatch, 1);
                    }
                }
            } else {
                PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'Either file is blank/not selected or incorrect format!!'));
                return null;
            }
        } catch(Exception e) {
            return utilObj.uploadingFalied();
        }
        return partnerAccountAssignmentPage;
    }
    
    public PageReference doMassProvisioning() {
        PageReference partnerAccountAssignmentPage = new PageReference('/apex/MassUploadNewUsersPage');
        partnerAccountAssignmentPage.setRedirect(true);
        
        try{
            List<User> listOfNewUsers = [SELECT Id from User where isActive = true AND IsMassLoaded__c = true AND Status__c = 'Validated' limit 1];
            
            if(listOfNewUsers.size() > 0){
                NewUsersMassUploadProvisioningBatch massBatch = new NewUsersMassUploadProvisioningBatch();
                if(!Test.isRunningTest()){                    
                    Database.executeBatch(massBatch, 1);
                }                
            }
            else{
                return utilObj.validateProvisioning();
            }            
        }
        catch(Exception e){
            return utilObj.validateProvisioning();
        }
        
        return partnerAccountAssignmentPage;
    }
    
    public PageReference doMassEmailing() {
        PageReference partnerAccountAssignmentPage = new PageReference('/apex/MassUploadNewUsersPage');
        partnerAccountAssignmentPage.setRedirect(true);
        
        try{
            List<User> listOfProvisionedUsers = [SELECT Id from User where isActive = true AND IsMassLoaded__c = true AND Status__c = 'Provisioned' limit 1];
            
            if(listOfProvisionedUsers.size() > 0){
                NewUsersUploadEmailNotifyingBatch massBatch = new NewUsersUploadEmailNotifyingBatch();
                if(!Test.isRunningTest()){                    
                    Database.executeBatch(massBatch, 200);
                }                
            }
            else{
                return utilObj.validateEmailNotification();
            }            
        }
        catch(Exception e){
            return utilObj.validateEmailNotification();
        }
        return partnerAccountAssignmentPage;
    }
    
    private boolean checkMandatoryColumns(List<String> row){
        Boolean isCorrect = true;
        
        if(String.isNotBlank(row[0].trim()) && String.isNotBlank(row[1].trim()) && String.isNotBlank(row[2].trim())){
            if(String.isNotBlank(row[11].trim())){
                if(row[11].toLowerCase().trim() == 'true' && (String.isBlank(row[8].trim()) && String.isBlank(row[12].trim()))){
                    isCorrect = false;
                }
            }
            if(String.isNotBlank(row[13].trim())){
                if(row[13].toLowerCase().trim() == 'true' && String.isBlank(row[14].trim())){
                    isCorrect = false;
                }
            }
            if(String.isNotBlank(row[15].trim())){
                if(row[15].toLowerCase().trim() == 'true' && String.isBlank(row[16].trim())){
                    isCorrect = false;
                }
            }
            if(String.isNotBlank(row[17].trim())){
                if(row[17].toLowerCase().trim() == 'true' && String.isBlank(row[18].trim())){
                    isCorrect = false;
                }
            }
        }else
            isCorrect = false;
        return isCorrect;
    }
    
    public String createEmailBody() {
        String finalstr = Constants.HI+Constants.SPACE+UserInfo.getFirstName()+Constants.SPACE+UserInfo.getLastName()+Constants.NEWLINE+Constants.NEWLINE;
        finalstr = finalstr +'Mass Upload Users has finished. Please see attached file for more details and try again.'+Constants.COLON+Constants.NEWLINE+Constants.NEWLINE;
        finalstr = finalstr +Constants.TASK_STATUS+Constants.COLON+Constants.SPACE+Constants.FAILED+Constants.NEWLINE;
        return finalstr;
    }
}