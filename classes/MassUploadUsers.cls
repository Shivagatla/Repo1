/**
* @author Gurditta Garg
* @date March 2016
* @description This Controller class is for getting the file input from VF page and parsing this file and does validation
*/

public class MassUploadUsers {
    
    public transient Blob csvFileBodyImport {get;set;}
    public transient String contentTypeImport {get;set;}
    public Integer fileSizeImport {get;set;}
    private MassUploadUtil utilObj = new MassUploadUtil();
    public transient Blob csvFileBodyImportNew {get;set;}
    public transient String contentTypeImportNew {get;set;}
    public Integer fileSizeImportNew {get;set;}
    public transient Blob csvFileBodyImportDelete {get;set;}
    public transient String contentTypeImportDelete {get;set;}
    public Integer fileSizeImportDelete {get;set;}
    public String MassUploadUsersPage {get;set;}
    public String MassUploadsDeleteAccess {get;set;}
    public String urlSuffix {get;set;}
    public MassUploadUsers() {
        String fullFileURL = URL.getSalesforceBaseUrl().toExternalForm();
        String proName = [Select Name from profile where id = :UserInfo.getProfileId()].get(0).Name;
        if(proName.equalsIgnoreCase('EMS Internal Community Plus')) {urlSuffix = 'ems';} else if(proName.equalsIgnoreCase('System Administrator')) {urlSuffix = 'apex';}
        MassUploadUsersPage = fullFileURL + '/'+urlSuffix+'/MassUploadUsersPage';
        MassUploadsDeleteAccess = fullFileURL + '/'+urlSuffix+'/MassUploadsDeleteAccess';
    }
    
    public PageReference importCSVFile() {
        PageReference partnerAccountAssignmentPage = new PageReference('/'+urlSuffix+'/MassUploadUsersPage');
        partnerAccountAssignmentPage.setRedirect(true);
        try {
            if(csvFileBodyImport != null && fileSizeImport > 0 && contentTypeImport != null && contentTypeImport.contains(Constants.CSV)) {
                List<List<String>> rows = utilObj.parseCSV(utilObj.blobToString(csvFileBodyImport,Constants.BLOB_ENCODE), true);
                if(rows.size() <= 0 || rows == null) {
                    return utilObj.uploadingFalied();
                }
                List<PayLoadUser> payloadList = fetchPayloadUsersList(rows);
                if(payloadList != null && !payloadList.isEmpty()) {
                    MassUploadUsersBatch massBatch = new MassUploadUsersBatch(payloadList);
                    Database.executeBatch(massBatch, 10);
                } else {
                    return null;   
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
    public PageReference importDeleteAccessCSVFile() {
        PageReference partnerAccountAssignmentPage = new PageReference('/'+urlSuffix+'/MassUploadsDeleteAccess');
        partnerAccountAssignmentPage.setRedirect(true);
        try {
            if(csvFileBodyImportDelete != null && fileSizeImportDelete > 0 && contentTypeImportDelete != null && contentTypeImportDelete.contains(Constants.CSV)) {
                List<List<String>> rows = utilObj.parseCSV(utilObj.blobToString(csvFileBodyImportDelete,Constants.BLOB_ENCODE), true);
                if(rows.size() <= 0 || rows == null) {
                    System.debug('############rows############# => ' + rows);
                    return utilObj.uploadingFalied();
                }
                //List<PayLoadUser> payloadList = fetchPayloadUsersList(rows);
                Set<String> incomingUsers = new Set<String>();
                Set<String> incomingApps = new Set<String>();
                Map<String, List<String>> incomingRecords = new Map<String, List<String>>();
                for (List<String> row : rows) {
                    if (row.size() > 2 || row.size() < 2) {
                        PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'Columns values can not exceed 2 OR less than 2'));
                        return null;
                    } else if (String.isBlank(row[0]) || String.isBlank(row[1])) {
                        PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'All Columns values are mandatory'));
                        return null;
                    } else if (row.size() > 0 && String.isNotBlank(row[0]) && String.isNotBlank(row[1])) {
                        incomingRecords.put(row[0].trim()+Constants.COMMA+row[1].trim(), row);
                        incomingUsers.add(row[0].trim());incomingApps.add(row[1].trim());
                    }
                }
                Map<String, Application__c> appDbMap = new Map<String, Application__c>();
                Map<String, String> conAppCodeMap = new Map<String, String>();
                for(Application__c app : [SELECT App_Code__c,Connected_App_Id__c,Home_Page__c,Migrated__c,Group_Designation__c 
                                          FROM Application__c WHERE App_Code__c IN: incomingApps]) {
                                              appDbMap.put(app.App_Code__c, app);
                                              conAppCodeMap.put(app.Connected_App_Id__c, app.App_Code__c);
                                          }
                //System.debug('########appDbMap######## => '+ appDbMap);
                
                Map<String, User> usersDbMap = new Map<String, User>();
                Map<String, String> userIdAg2AgMap = new Map<String, String>();
                for(User user : [SELECT Ag2Ag_ID__c,Username,Email,Firstname,Lastname 
                                 FROM User WHERE Ag2Ag_ID__c IN: incomingUsers AND IsActive = true]) {
                                     usersDbMap.put(user.Ag2Ag_ID__c, user);
                                     userIdAg2AgMap.put(user.Id, user.Ag2Ag_ID__c);
                                 }
                
                List<AppUserEntWrapper> validData = new List<AppUserEntWrapper>();
                Map<String,String> errorData = new Map<String,String>();
                Set<String> conAppIds = new Set<String>();
                Set<String> userids = new Set<String>();
                for(String mapKey : incomingRecords.keySet()) {
                    List<String> parts = mapKey.split(Constants.COMMA);
                    if(usersDbMap.get(parts.get(0)) != null && appDbMap.get(parts.get(1)) != null) {
                        validData.add(new AppUserEntWrapper(appDbMap.get(parts.get(1)),usersDbMap.get(parts.get(0))));
                        conAppIds.add(appDbMap.get(parts.get(1)).Connected_App_Id__c);
                        userids.add(usersDbMap.get(parts.get(0)).Id);
                    } else {
                        errorData.put(parts.get(0).trim()+ Constants.COMMA +parts.get(1).trim(), parts.get(0).trim()+ Constants.COMMA +parts.get(1).trim()
                                      +',Failed because one of the column values does not exist in DB.');
                    }
                }
                if(errorData != null && !errorData.isEmpty()) {
                    PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, errorData.size() + ' Errors found in the file, check the email and retry.'));
                    String finalstr = 'ID,Application,Status'+Constants.NEWLINE;
                    for(String hashKey : incomingRecords.keySet()) {
                        if(errorData.get(hashKey) != null) {
                            finalstr = finalstr + errorData.get(hashKey) + Constants.NEWLINE;                            
                        } else {
                            finalstr = finalstr + hashKey + Constants.NEWLINE;     
                        }
                    }
                    MassUploadUtil utilObj = new MassUploadUtil();
                    utilObj.sendEmail(finalstr,'Mass Upload Errors',null,null,'Mass Upload Delete Access Failed', createEmailBody());
                    return null;
                }
                System.debug('########userids######## => '+ userids);
                System.debug('########conAppIds######## => '+ conAppIds);
                
                Map<String, UserProvAccount> hashUPA = new Map<String, UserProvAccount>();
                Set<String> upaids = new Set<String>();
                for(UserProvAccount upa : [Select Id,SalesforceUserId,Status,ConnectedAppId from UserProvAccount where SalesforceUserId IN: userids AND ConnectedAppId IN: conAppIds]) {
                    if(incomingRecords.get(userIdAg2AgMap.get(upa.SalesforceUserId)+Constants.COMMA+conAppCodeMap.get(upa.ConnectedAppId)) != null) {
                        hashUPA.put(upa.SalesforceUserId+Constants.HASH+upa.ConnectedAppId, upa);
                        upaids.add(upa.Id);
                    }
                }
                System.debug('########hashUPA######## => '+ hashUPA);
                
                Map<String, List<GroupANDEnt>> upaUPEMap = new Map<String, List<GroupANDEnt>>();
                Map<String, List<UserProvisionEntitlement__c>> upaUPEListMap = new Map<String, List<UserProvisionEntitlement__c>>();
                for(UserProvisionEntitlement__c upe : [Select UPA_Parent__r.SalesforceUserId,UPA_Parent__r.ConnectedAppId,
                                                       Entitlement_Code__r.Name,Entitlement_Code__r.AD_Group__c,Entitlement_Code__r.Ad_Group_Optional__c,
                                                       ParentApp__r.Group_Designation__c 
                                                       From UserProvisionEntitlement__c where UPA_Parent__c IN: upaids]) 
                {
                    Set<String> groups = new Set<String>();
                    Set<String> appEntitlements = new Set<String>();
                    String aGroup1 = upe.Entitlement_Code__r.AD_Group__c;
                    String aGroup2 = upe.Entitlement_Code__r.Ad_Group_Optional__c;
                    String entCode = upe.Entitlement_Code__r.Name; 
                    String groupDes = upe.ParentApp__r.Group_Designation__c;
                    String hashKey = upe.UPA_Parent__r.SalesforceUserId+Constants.HASH+upe.UPA_Parent__r.ConnectedAppId;
                    if (aGroup1 != null)
                        groups.add(formatADGroupName(aGroup1));
                    if (aGroup2 != null)
                        groups.add(formatADGroupName(aGroup2));
                    if (entCode != null)
                        appEntitlements.add(entCode);    
                    if (groupDes != null)
                        groups.add(formatADGroupName(groupDes));
                    if(upaUPEMap.get(hashKey) != null){
                        upaUPEMap.get(hashKey).add(new GroupANDEnt(groups,appEntitlements));
                    } else {
                        List<GroupANDEnt> listOfValues = new List<GroupANDEnt>();
                        listOfValues.add(new GroupANDEnt(groups,appEntitlements));
                        upaUPEMap.put(hashKey, listOfValues);
                    }
                    if(upaUPEListMap.get(hashKey) != null){
                        upaUPEListMap.get(hashKey).add(upe);
                    } else {
                        List<UserProvisionEntitlement__c> listOfValues = new List<UserProvisionEntitlement__c>();
                        listOfValues.add(upe);
                        upaUPEListMap.put(hashKey, listOfValues);
                    }
                }
                System.debug('########upaUPEMap######## => '+ upaUPEMap);
                System.debug('########upaUPEListMap######## => '+ upaUPEListMap);
                
                List<UserProvAccount> upaList = new List<UserProvAccount>();
                List<UserProvisionEntitlement__c> upeLists = new List<UserProvisionEntitlement__c>();
                for (String hashKey : hashUPA.keySet()) {
                    UserProvAccount upa = hashUPA.get(hashKey);
                    if(upa.Status != 'Deactivated') {
                        upa.Status = 'Deactivated';
                        upaList.add(upa);
                        System.debug('########upaList######## => '+ upaList);
                    } 
                    List<UserProvisionEntitlement__c> upes = upaUPEListMap.get(hashKey);
                    if(upes!= null && !upes.isEmpty()) {
                        upeLists.addAll(upes);   
                    }
                }
                Map<String,String> successList = new Map<String,String>();
                Map<String,String> failedList = new Map<String,String>();
                Database.SaveResult[] drList = Database.update(upaList, false);
                System.debug('########drList######## => '+ drList);
                integer i = 0;
                for(Database.SaveResult dr : drList) {
                    String hashKey = upaList.get(i).SalesforceUserId+Constants.HASH+upaList.get(i).ConnectedAppId;
                    String reportKey = upaList.get(i).SalesforceUserId+Constants.COMMA+upaList.get(i).ConnectedAppId;
                    if (dr.isSuccess()) {
                        successList.put(hashKey,reportKey);
                    } else {
                        failedList.put(hashKey,reportKey);
                    }
                }
                System.debug('########successList######## => '+ successList);
                System.debug('########failedList######## => '+ failedList);
                System.debug('########upeLists######## => '+ upeLists);
                if(!upeLists.isEmpty()) {
                    Database.delete(upeLists, false);   
                }
                List<Payload> payloadList = new List<Payload>();
                for(AppUserEntWrapper aue : validData) {
                    String hashKey = aue.usr.Id+Constants.HASH+aue.app.Connected_App_Id__c;
                    if(upaUPEMap.get(hashKey) != null && upaUPEMap.get(hashKey) != null) {
                        Integer IsDefaultHomePage = Boolean.valueOf(aue.app.Home_Page__c) ? 1 : 0;
                        String ApplicationMigrationStatus = Boolean.valueOf(aue.app.Migrated__c) ? 'Migrated' : 'NonMigrated';
                        List<String> groupsList = new List<String>();
                        List<String> entCodes = new List<String>();
                        for(GroupANDEnt GE : upaUPEMap.get(hashKey)) {
                            groupsList.addAll(GE.groups);
                            entCodes.addAll(GE.appEntitlements);
                        }
                        System.debug('##########groupsList########### => ' + JSON.serializePretty(groupsList));
                        System.debug('##########entCodes########### => ' + JSON.serializePretty(entCodes));
                        payloadList.add(new PayLoad(aue.usr.Ag2Ag_ID__c,aue.app.App_Code__c,IsDefaultHomePage,ApplicationMigrationStatus,
                                                    'Mass Delete Access by ' + Userinfo.getName(),groupsList,String.join(entCodes,'~')));   
                    }
                }
                System.debug('##########payloadList########### => ' + JSON.serializePretty(payloadList));
                if(!payloadList.isEmpty()) {
                    MassUploadDeleteAccessBatch massBatch = new MassUploadDeleteAccessBatch(payloadList,failedList);
                    Database.executeBatch(massBatch, 10);   
                }
            } else {
                PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'Either file is blank/not selected or incorrect format!!'));
                return null;
            }
        } catch (Exception e) {
            System.debug('##########getCause################## => ' + e.getCause());
            System.debug('##########getCause################## => ' + e.getCause());
            System.debug('##########getStackTraceString################## => ' + e.getStackTraceString());
            return utilObj.uploadingFalied();
        }
        return partnerAccountAssignmentPage;
    }
    private List<PayLoadUser> fetchPayloadUsersList(List<List<String>> rows) {
        // remove duplicate rows, columns and blanks
        Map<String, List<String>> incomingRecords = new Map<String, List<String>>();
        for (List<String> row : rows) {
            if (row.size() > 3 || row.size() < 3) {
                PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'Columns values can not exceed 3 OR less than 3'));
                return null;
            } else if (String.isBlank(row[0]) || String.isBlank(row[1]) || String.isBlank(row[2])) {
                PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'All Columns values are mandatory'));
                return null;
            } else if (row.size() > 0 && String.isNotBlank(row[0]) && String.isNotBlank(row[1]) && String.isNotBlank(row[2])) {
                incomingRecords.put(row[0].trim()+Constants.COMMA+row[1].trim()+Constants.COMMA+row[2].trim(), row);
            }
        }
        // map for appcodes and user#appcode
        Map<String, List<String>> appUsersMap = new Map<String, List<String>>();
        Set<String> incomingUsers = new Set<String>();
        Set<String> incomingGroupsCodes = new Set<String>();
        for (List<String> row : incomingRecords.values()) {
            if(appUsersMap.get(row[1].trim()) != null){
                appUsersMap.get(row[1].trim()).add(row[0].trim()+'~'+row[2].trim());
                incomingUsers.add(row[0].trim());incomingGroupsCodes.add(row[2].trim());
            } else {
                List<String> listOfValues = new List<String>();
                listOfValues.add(row[0].trim()+'~'+row[2].trim());
                incomingUsers.add(row[0].trim());incomingGroupsCodes.add(row[2].trim());
                appUsersMap.put(row[1].trim(), listOfValues);
            }
        }        
        Map<String, Application__c> appDbMap = new Map<String, Application__c>();
        for(Application__c app : [SELECT App_Code__c,Connected_App_Id__c,Home_Page__c,Migrated__c,Group_Designation__c FROM Application__c WHERE App_Code__c IN: appUsersMap.keySet()]) {
            appDbMap.put(app.App_Code__c, app);
        }
        Map<String, User> usersDbMap = new Map<String, User>();
        for(User user : [SELECT Ag2Ag_ID__c,Username,Email,Firstname,Lastname FROM User WHERE Ag2Ag_ID__c IN: incomingUsers AND IsActive = true]) {
            usersDbMap.put(user.Ag2Ag_ID__c, user);
        }
        Map<String, Entitlements__c> groupsDbMap = new Map<String, Entitlements__c>();
        for(Entitlements__c ent : [SELECT Name,Ent_Code__c,AD_Group__c,Ad_Group_Optional__c FROM Entitlements__c WHERE Ent_Code__c IN: incomingGroupsCodes AND ParentApp__c IN: appDbMap.values()]) {
            groupsDbMap.put(ent.Ent_Code__c, ent);
        }
        List<AppUserEntWrapper> validData = new List<AppUserEntWrapper>();
        Map<String,String> errorData = new Map<String,String>();
        for(String mapKey : appUsersMap.keySet()) {
            for(String userEntHashKey : appUsersMap.get(mapKey)){
                List<String> parts = userEntHashKey.split('~');
                if(usersDbMap.get(parts.get(0)) != null && groupsDbMap.get(parts.get(1)) != null) {
                    validData.add(new AppUserEntWrapper(appDbMap.get(mapKey),usersDbMap.get(parts.get(0)),groupsDbMap.get(parts.get(1))));
                } else {
                    errorData.put(parts.get(0).trim()+ Constants.COMMA +mapKey.trim()+Constants.COMMA+parts.get(1).trim(), 
                                  parts.get(0).trim()+ Constants.COMMA +mapKey.trim()+Constants.COMMA+parts.get(1).trim()
                                  +',Failed because one of the column values does not exist in DB.');
                }
            }
        }
        if(errorData != null && !errorData.isEmpty()) {
            PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, errorData.size() + ' Errors found in the file, check the email and retry.'));
            String finalstr = 'ID,Application,Entitlement,Status'+Constants.NEWLINE;
            for(String hashKey : incomingRecords.keySet()) {
                if(errorData.get(hashKey) != null) {
                    finalstr = finalstr + errorData.get(hashKey) + Constants.NEWLINE;
                } else {
                    finalstr = finalstr + hashKey + Constants.NEWLINE;   
                }
            }
            MassUploadUtil utilObj = new MassUploadUtil();
            utilObj.sendEmail(finalstr,'Mass Upload Errors',null,null,'Mass Upload Add Access Failed', createEmailBody());
            return null;
        }
        List<PayLoadUser> payloadList = new List<PayLoadUser>();
        for(AppUserEntWrapper aue : validData) {
            Integer IsDefaultHomePage = Boolean.valueOf(aue.app.Home_Page__c) ? 1 : 0;
            String ApplicationMigrationStatus = Boolean.valueOf(aue.app.Migrated__c) ? 'Migrated' : 'NonMigrated';
            
            List<String> groups = new List<String>();
            if (aue.ent.AD_Group__c != null)
                groups.add(formatADGroupName(aue.ent.AD_Group__c));
            if (aue.ent.Ad_Group_Optional__c != null)
                groups.add(formatADGroupName(aue.ent.Ad_Group_Optional__c));
            if (aue.app.Group_Designation__c != null)
                groups.add(formatADGroupName(aue.app.Group_Designation__c));
            payloadList.add(new PayLoadUser(new PayLoad(aue.usr.Ag2Ag_ID__c,aue.app.App_Code__c,IsDefaultHomePage,ApplicationMigrationStatus,
                                                        'Mass Upload by ' + Userinfo.getName(),groups,
                                                        aue.ent.Ent_Code__c.substringAfter('/').trim()), aue.app.Connected_App_Id__c,
                                            aue.usr.Id,aue.usr.username,aue.ent.Id,aue.app.Id,aue.usr.Email,aue.usr.Firstname,aue.usr.Lastname));
        }
        //System.debug('########payloadList######## => '+ Json.serializePretty(payloadList));
        return payloadList;
    }
    /*private List<UserWrapper> createNewUserWrappers(List<NewUserWrapper> newUserWrappers, Set<String> accNumberList) {
        Map<String, Account> accNumIdMap = new Map<String, Account>();
        for(Account acc : [Select GUID__c,Name,AIMS_Number__c,BillingState from Account Where GUID__c IN: accNumberList]) {
            accNumIdMap.put(acc.GUID__c, acc);
        }
        String profileId = [SELECT Id FROM Profile WHERE Name =: Constants.EMS_EXTERNAL_USER LIMIT 1].Id;
        Environment__c env = Environment__c.getInstance(Constants.EMS);
        List<UserWrapper> toBeReturnList = new List<UserWrapper>();
        for(NewUserWrapper newUserW : newUserWrappers) {
            User newUser = new User();
            String accountId = accNumIdMap.get(newUserW.accNum).Id;
            String usernameBase = utilObj.generateRandomString(10);
            newUser.Username = usernameBase + env.Username_Suffix__c;
            newUser.Initial_password__c = Constants.WELCOME1;
            newUser.CommunityNickname = usernameBase;
            newUser.ProfileId = profileId;
            newUser.Email = newUserW.email;
            newUser.Phone = newUserW.primaryPhone;
            newUser.FirstName = newUserW.firstName;
            newUser.LastName = newUserW.lastName;
            newUser.JobClassification__c = newUserW.jobClassification;
            newUser.Email_Verified__c = true;
            newUser.Registration_Status__c = Constants.APPROVED;
            if(newUserW.businessUnit.equalsIgnoreCase(Constants.WINFIELD)) {
                newUser.seed__c = true;
            } else if (newUserW.businessUnit.equalsIgnoreCase(Constants.PURINA)) {
                newUser.purina__c = true;
            } else if(newUserW.businessUnit.equalsIgnoreCase(Constants.LOL)) {
                newUser.lol__c = true;
            } else if (newUserW.businessUnit.equalsIgnoreCase(Constants.CORPORATE)) {
                newUser.Corporate__c = true;
            }
            Contact newUserContact = new Contact(
                FirstName = newUserW.firstName,
                Lastname = newUserW.lastName,
                AccountId = accountId,
                Email = newUserW.email,
                Email_Verified__c = true,
                Registration_Denied__c = false
            );
            toBeReturnList.add(new UserWrapper(newUser, newUserContact, accNumIdMap.get(newUserW.accNum), newUserW.accNum,
                                               newUserW.businessUnit, newUserW.mgrName,newUserW.mgrEmail,newUserW.mgrPhone));
        }
        return toBeReturnList;
    }
    class NewUserWrapper {
        String firstName{get;set;}
        String lastName{get;set;}
        String email{get;set;}
        String primaryPhone{get;set;}
        String accNum{get;set;}
        String mgrName{get;set;}
        String mgrEmail{get;set;}
        String mgrPhone{get;set;}
        String businessUnit{get;set;}
        String jobClassification{get;set;}
        
        NewUserWrapper(String firstName, String lastName, String email, String primaryPhone, String accNum, 
                       String mgrName, String mgrEmail, String mgrPhone, String businessUnit, String jobClassification) 
        {
            this.firstName = firstName;
            this.lastName = lastName;
            this.email = email;
            this.primaryPhone = primaryPhone;
            this.accNum = accNum;
            this.mgrName = mgrName;
            this.mgrEmail = mgrEmail;
            this.mgrPhone = mgrPhone;
            this.businessUnit = businessUnit;
            this.jobClassification = jobClassification;
        }
    }*/
    class AppUserEntWrapper {
        Application__c app{get;set;}
        User usr{get;set;}
        Entitlements__c ent{get;set;}
        
        AppUserEntWrapper (Application__c app, User user, Entitlements__c ent) {
            this.app = app;this.usr = user;this.ent = ent;
        }
        
        AppUserEntWrapper (Application__c app, User user) {
            this.app = app;this.usr = user;
        }
    }
    private String formatADGroupName(String aGroup) {
        if (aGroup.startsWithIgnoreCase(Constants.CN_EQUALS))
            return aGroup.substringBefore(Constants.COMMA).substringAfter(Constants.EQUALS_SIGN);
        return aGroup;
    }
    private String createEmailBody() {
        String finalstr = Constants.HI+Constants.SPACE+UserInfo.getFirstName()+Constants.SPACE+UserInfo.getLastName()+Constants.NEWLINE+Constants.NEWLINE;
        finalstr = finalstr +'Mass Upload Users has finished. Please see attached file for more details and try again.'+Constants.COLON+Constants.NEWLINE+Constants.NEWLINE;
        finalstr = finalstr +Constants.TASK_STATUS+Constants.COLON+Constants.SPACE+Constants.FAILED+Constants.NEWLINE;
        return finalstr;
    }
    private class GroupANDEnt {
        Set<String> groups{get;set;}
        Set<String> appEntitlements{get;set;}
        GroupANDEnt(Set<String> groups, Set<String> appEntitlements) 
        {
            this.groups = groups;
            this.appEntitlements = appEntitlements;
        }
    }
    /*public PageReference importUserCSVFile() {
PageReference partnerAccountAssignmentPage = new PageReference('/apex/MassUploadNewUsersPage');
partnerAccountAssignmentPage.setRedirect(true);
try {
if(csvFileBodyImportNew != null && fileSizeImportNew > 0 && contentTypeImportNew != null && contentTypeImportNew.contains(Constants.CSV)) {
List<List<String>> rows = utilObj.parseCSV(utilObj.blobToString(csvFileBodyImportNew,Constants.BLOB_ENCODE), true);
if(rows.size() <= 0 || rows == null) {
return utilObj.uploadingFalied();
}

// remove duplicate rows, columns and blanks
Map<String, List<String>> incomingRecords = new Map<String, List<String>>();
List<String> doNotProcess = new List<String>();
Set<String> accNumberList = new Set<String>();
Set<String> mgrIdList = new Set<String>();
for (List<String> row : rows) {
if (row.size() > 0 && 
String.isNotBlank(row[0].trim()) && 
String.isNotBlank(row[1].trim()) && 
String.isNotBlank(row[2].trim()) && 
String.isNotBlank(row[3].trim()) && 
String.isNotBlank(row[4].trim()) && 
String.isNotBlank(row[8].trim()) && 
String.isNotBlank(row[9].trim())) 
{
incomingRecords.put(
row[0].trim()+Constants.HASH+
row[1].trim()+Constants.HASH+
row[2].trim()+Constants.HASH+
row[3].trim()+Constants.HASH+
row[4].trim()+Constants.HASH+
row[5].trim()+Constants.HASH+
row[6].trim()+Constants.HASH+
row[7].trim()+Constants.HASH+
row[8].trim()+Constants.HASH+
row[9].trim(), row);
accNumberList.add(row[4].trim());
//mgrIdList.add(row[5].trim());
} else {
//System.debug('#############rowIN############### => ' + row);
doNotProcess.add(String.join(row, Constants.COMMA));
accNumberList.add(row[4].trim());
//mgrIdList.add(row[5].trim());
}
}
//System.debug('############incomingRecords########### => ' + incomingRecords);
//System.debug('############doNotProcess########### => ' + doNotProcess);
if(doNotProcess.size() > 0) {
PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'Errors found in the file, please check the email.'));
String finalstr = 'FirstName,LastName,Email,Phone,Account,MgrName,MgrEmail,MgrPhone,Business Unit,Job,Reason'+Constants.NEWLINE;
for(String error : doNotProcess) {
error = error.replace('\r\n', '');
error = error.replace('\n', '');
error = error.replace('\r', '');
finalstr = finalstr + error +',One of the mandatory field is missing.'+ Constants.NEWLINE;
}
MassUploadUtil utilObj = new MassUploadUtil();
utilObj.sendEmail(finalstr,'Mass Upload Errors',null,null,'Mass Upload New User Failed', createEmailBody());
return null;
} else {
List<NewUserWrapper> userWrappers = new List<NewUserWrapper>();
for(List<String> row : incomingRecords.values()) {
userWrappers.add(
new NewUserWrapper(
row[0].trim(),row[1].trim(),row[2].toLowerCase().trim(),
row[3].trim(),row[4].trim(),row[5].trim(),row[6].trim(),
row[7].trim(),row[8].trim(),row[9].trim())
);
}
List<UserWrapper> toBeSendToBatch = createNewUserWrappers(userWrappers, accNumberList);
MassUploadNewUsersBatch massBatch = new MassUploadNewUsersBatch(toBeSendToBatch);
Database.executeBatch(massBatch, 10);
}
} else {
PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'Either file is blank/not selected or incorrect format!!'));
return null;
}
} catch(Exception e) {
return utilObj.uploadingFalied();
}
return partnerAccountAssignmentPage;
}*/
}