/*********************************************************************
** Initial Version: Deb Volk
** 2/17/2015: Shilpa Bhor, Gurditta Garg.
** S-03873, S-04842 : New Customer Registration Page
**********************************************************************/

global class EMSSelfRegistrationCntrl{
    
    public String email {get; set;}
    public String password {get; set {password = value == null ? value : value.trim(); } }
    public String confirmPassword {get; set { confirmPassword = value == null ? value : value.trim(); } }
    public String primaryPhone {get; set;}
    public String jobClassification {get; set;}
    public String accountNumber {get;set;}
    public String farmId {get;set;}
    public String farmName {get;set;}
    public String firstName {get;set;}
    public String lastName {get; set;}
    public String company{get;set;}
    public String managerName {get;set;}
    public String managerPhone {get;set;}
    public String managerEmail {get;set;}
    //For AG Tech agreement.
    public Boolean isAgThAgreement {get;set;}
    public String retailerNumber {get;set;}
    public String retailerName {get;set;}
    public String retailerCity {get;set;}
    public String retailerState {get;set;}
    public Boolean isWinfield = false;
    public String GROWERRECORDTYPE;
    public String agreementDocId;
    public String agTechPDFUrl {get{agTechPDFUrl=Label.AgTechPDFUrl + agreementDocId + '&embedded=true'; return agTechPDFUrl;}set;}
    public String referredBy {get;set;}
    public String referringApp {get;set;}
    //For FGI
    public String fgiCompany {get;set;}
    public String fgiLicensee {get;set;}
    public String fgiCompanyCity {get;set;}
    public String fgiCompanyState {get;set;}
    public String fgiLicenseeCity {get;set;}
    public String fgiLicenseeState {get;set;}
    public Boolean brand1 {get;set;} 
    public Boolean brand2 {get;set;}
    public Boolean brand3 {get;set;}
    
    public list<SelectOption> items;
    private static SelectOption DEFAULT_JOB_CLASSIFICATION = new SelectOption('', '');
    
    public EMSSelfRegistrationCntrl(){
        isAgThAgreement=true;
        List<Environment_Record_Ids__c> listRecordIds = Environment_Record_Ids__c.getAll().values();
        for(Environment_Record_Ids__c e: listRecordIds){
            if(e.Name.equals('Agreement Document Id'))
                agreementDocId = e.Record_Id__c;
            else if(e.Name.equals('Agreement Grower Record Type'))
                GROWERRECORDTYPE = e.Record_Id__c;
        }
    }
    
    public String getCustomSettings () {
        Map<String, Business_Roles__c> mcs = Business_Roles__c.getAll();
        Map<String, List<Boolean>> returnMap = new Map<String, List<Boolean>>();
        for (String roleName : mcs.keySet()) {
            Business_Roles__c br = mcs.get(roleName);
            if(br.Active__c)
                returnMap.put(roleName, new List<Boolean> {br.Corporate__c, br.Dairy__c, br.Purina__c, br.WinField__c, br.FGI__c, br.ManagerInfo__c});
        }
        return JSON.serialize(returnMap);
    }
    public String getBRDesc () {
        Map<String, Business_Roles__c> mcs = Business_Roles__c.getAll();
        Map<String, String> returnMap = new Map<String, String>();
        for (String roleName : mcs.keySet()) {
            Business_Roles__c br = mcs.get(roleName);
            if(br.Active__c)
                returnMap.put(br.Value__c, br.Description__c);
        }
        return JSON.serialize(returnMap);
    }
    
    public PageReference registerUser() {
        system.debug('===referring app >>>> ' + referringApp);
        Account[] accounts = null;
        Account account = null;
        boolean BUfound = false;
        
        if (isValidBUEntry(accountNumber,'ACCOUNT #')){
            BUfound = true;
            accounts = [SELECT Id, Name FROM Account WHERE AIMS_Number__c = :accountNumber and Business_Unit_Key__c ='FEED' LIMIT 1];
            if (accounts != null && accounts.size() > 0)
                account = accounts[0];
        }
        
        if(String.isNotBlank(retailerNumber) || String.isNotBlank(retailerName)){
            BUfound = true;
            isWinfield = true;
            
            if(isValidBUEntry(retailerNumber,'RETAILER NUMBER') && account==null){
                accounts = [SELECT Id, Name FROM Account WHERE Customer_Number__c =:retailerNumber LIMIT 1];
            }
            else if (isValidBUEntry(retailerName,'RETAILER NAME') && isValidBUEntry(retailerCity,'RETAILER CITY') && isValidBUEntry(retailerState,'RETAILER STATE') && account==null){
                accounts = [SELECT Id, Name FROM Account WHERE Name =:retailerName AND BillingCity =:retailerCity AND BillingState =:retailerState LIMIT 1];
            }
            
            if (accounts != null && accounts.size() > 0)
                account = accounts[0];
        }
        
        if (isValidBUEntry(company,'COMPANY') && account==null){
            BUfound = true;
            accounts = [SELECT Id, Name FROM Account WHERE Name = :company LIMIT 20];
            if (accounts != null && accounts.size() == 1)
                account = accounts[0];
        }
        
        if (isValidBUEntry(farmId,'FARM ID/PAES #') || isValidBUEntry(farmName,'FARM ID/PAES #') && account==null){     
            BUfound = true;
            if (isValidBUEntry(farmId,'FARM ID/PAES #')) {
             String paesNum = farmId.leftPad(7).replace(' ', '0');  
             accounts = [SELECT Id, Name FROM Account WHERE ((Farm_ID__c=:farmId OR PAES_Number__c =:paesNum) and (recordTypeID in (SELECT Id FROM RecordType WHERE Name = 'Corporate'))) LIMIT 20];
             if (accounts != null && accounts.size() == 1)
                 account = accounts[0];
            }
        }
        
        //For FGI
        if(String.isNotBlank(fgiCompany) || String.isNotBlank(fgiLicensee)){
            BUfound = true;
            
            if(isValidBUEntry(fgiCompany,'COMPANY NAME') && isValidBUEntry(fgiCompanyCity,'COMPANY CITY') && isValidBUEntry(fgiCompanyState,'COMPANY STATE')){
                accounts = [Select id, Name from Account where Name =: fgiCompany AND billingCity =: fgiCompanyCity AND billingState =: fgiCompanyState LIMIT 1];
            } else if(isValidBUEntry(fgiLicensee,'LICENSEE NAME') && isValidBUEntry(fgiLicenseeCity,'LICENSEE CITY') && isValidBUEntry(fgiLicenseeState,'LICENSEE STATE')){
                accounts = [Select id, Name from Account where Name =: fgiLicensee AND billingCity =: fgiLicenseeCity AND billingState =: fgiLicenseeState LIMIT 1];
            }
            system.debug('===accounts===' + accounts);
            if (accounts != null && accounts.size() > 0)
                account = accounts[0];
        }
        
        if (!BUFound) {
            String msg = 'Please select at least one business Unit.';
            PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, msg));
            return ApexPages.currentPage();
        }
        
        if (account != null )
            System.DEBUG('Found Account: '+ account.Id + ' -> ' + account.Name);
        else {
            System.DEBUG('Account NOT found. Defaulting to "Pending Registrations" account...');
            account = [SELECT Id,Name FROM Account WHERE Name='Pending Registrations' LIMIT 1];
            if (account == null) {
                System.DEBUG('Account "Pending Registrations" was NOT found');
                PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'System error. Please contact Customer Service'));
                return null;
            }
        }
        
        User u = new User();
        
        try {            
            Environment__c env = Environment__c.getInstance('EMS');
            String usernameBase = generateRandomString(10);
            
            u.Username = usernameBase + env.Username_Suffix__c;
            u.Email = email.toLowerCase();
            u.Phone = primaryPhone;
            u.FirstName = firstName;
            u.LastName = lastName;
            u.CommunityNickname = usernameBase;
            u.JobClassification__c = jobClassification;
            u.ProfileId = [SELECT Id FROM Profile WHERE Name='EMS External User' LIMIT 1].Id;
            u.Verify_Hash__c = generateHash(firstName+lastName);
            
            u.Initial_password__c = password;
            u.seed__c = (isValidBUEntry(retailerNumber,'RETAILER NUMBER') || isValidBUEntry(retailerName,'RETAILER NAME'));
            u.purina__c = isValidBUEntry(accountNumber,'ACCOUNT #');
            u.lol__c = isValidBUEntry(company,'COMPANY');
            u.CompanyName = (company == null) ? account.name : company;            
            u.Corporate__c = (isValidBUEntry(farmId,'FARM ID/PAES #') || isValidBUEntry(farmName,'FARMNAME'));            
            u.FGI__c = (isValidBUEntry(fgiCompany,'COMPANY NAME') || isValidBUEntry(fgiLicensee,'LICENSEE NAME'));
            
            String comments = '\n ';
            comments = '--- Registration Form ---\n\n';
            comments += 'Job classification: ' + jobClassification + '.';
            comments += ((u.seed__c && isValidBUEntry(retailerNumber,'RETAILER NUMBER'))?'\n Business unit: Winfield. \n Retailer Number: ' + retailerNumber + '.':'');
            comments += ((u.seed__c && isValidBUEntry(retailerName,'RETAILER NAME'))?'\n Business unit: Winfield. \n Retailer Name: ' + retailerName + '. \n Retailer City: ' + retailerCity + '. \n Retailer State: ' + retailerState + '.':'');            
            comments += ((u.seed__c && isValidBUEntry(referredBy,'REFERRED BY'))?'\n Referred By: ' + referredBy + '.':'');
            comments += (u.purina__c?'\n Business unit: Purina. AIMS Number: ' + accountNumber:'');
            comments += (u.corporate__c?'\n Business unit: Corporate. FarmName: '+farmName + ', Farm ID/PAES #: ' + farmId:'');
            comments += (u.lol__c?'\n Business unit: Dairy Foods (LoL Maiden). Company: '+company:'');
            comments += (u.FGI__c?isValidBUEntry(fgiCompany,'COMPANY NAME')?'\n Business unit: Forage Genetics International (FGI). Company Name: '+fgiCompany+'. Company City: ' +fgiCompanyCity+'. Company State: '+fgiCompanyState+'.':isValidBUEntry(fgiLicensee,'LICENSEE NAME')?'\n Business unit: Forage Genetics International (FGI). Licensee Name: '+fgiLicensee+'. Licensee City: ' +fgiLicenseeCity+'. Licensee State: '+fgiLicenseeState+'.':'':'');
           
           if(String.isNotBlank(fgiCompany)){ 
               comments +='\n Brand: ';
               if(brand1) comments += Label.brand1 + '; '; if(brand2) comments += Label.brand2 + '; '; if(brand3) comments += Label.brand3 + '; ';
           }
            if (String.isNotBlank(managerName.trim())) {            
                comments += '\n Registrant\'s Manager: ' 
                    + ((String.isNotBlank(managerName.trim())) ? managerName: '') 
                    + ' (' + ((String.isNotBlank(managerPhone.trim())) ? ' ' + managerPhone : '')             
                    + ((String.isNotBlank(managerEmail.trim())) ? ', ' + managerEmail.trim().toLowerCase() : '') + ')';               
            }
            u.Registration_Info__c = comments;
            u.Ag_Tech_Agreement__c = (isWinfield && jobClassification == 'Farmer'? isAgThAgreement? true:false:false);
            system.debug('=== user record ===' + u);
        }
        catch(EMSDuplicateUserException ems){
            System.DEBUG('User already exists: ' + ems.getMessage());
            PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 'You already have a user account. Please use Forgot Username or Forgot Password service if you don\'t remember your credentials'));
            return null;
        }
        catch (Exception e) {
            System.debug('###########LineNumber###########=> ' + e.getLineNumber());
            System.DEBUG('Failed to register customer: ' + e.getMessage());
            PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 
                                                                 'Internal error: ' + e.getMessage() +  ' Please note the error message and contact Customer Support'));
            return null;
        }        
        
        try {
            String userId = Site.createExternalUser(u, account.Id, password);
            system.debug('=== user id ===' + userId);                           
                
            if (userId == null) {
                System.DEBUG('Failed to register customer: userId returned by Site.createExternalUser is null');
                PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 
                                                                     'Internal error: -201. Please note the error message and contact Customer Support'));
                if(!Test.isRunningTest())
                    return null;
            }
            
            if(Test.isRunningTest()){
                List<User> uList = [Select id, ContactId from User where ContactId != '' limit 1];
                
                userId = uList[0].Id;
            }
            
            if(userId != null){
            
                //Update retailer details in contact for registering user.                
                User uRec = [Select Id, ContactId, CreatedDate from User where Id =: userId limit 1];
                if(uRec != null){
                    Contact con = new Contact();
                    con.Id = uRec.ContactId;
                    con.Retailer_Number__c = String.isNotBlank(retailerNumber)?retailerNumber : '';
                    con.Retailer_Name__c = String.isNotBlank(retailerName)?retailerName: '';
                    con.Retailer_City__c = String.isNotBlank(retailerCity)?retailerCity: '';
                    con.Retailer_State__c = String.isNotBlank(retailerState)?retailerState: '';
                    con.Reffered_By__c = String.isNotBlank(referredBy)?referredBy: '';
                    con.Referring_App__c = String.isNotBlank(referringApp)?referringApp: '';
                    con.Manager_Name__c = String.isNotBlank(managerName)?managerName: '';
                    con.Manager_Email__c = String.isNotBlank(managerEmail)?managerEmail: '';
                    con.Manager_Phone__c = String.isNotBlank(managerPhone)?managerPhone: '';
                    
                    con.Related_External_User__c = userId; 
                    
                    DataBase.update(con);
                    updateUserRegDate(uRec.Id);
                }                    
                
                //Create Ag Tech Agreement record for the Grower user.
                if(isWinfield && jobClassification == 'Farmer'){                    
                    Agreement__c agtObj = new Agreement__c();
                    agtObj.Sign_Date__c = System.today();
                    agtObj.Grower_User__c = userId;
                    agtObj.Type__c = 'Ag Tech Agreement';
                    agtObj.RecordTypeId = GROWERRECORDTYPE;
                    
                    if(isAgThAgreement)
                        agtObj.Sign_Status__c = 'Accepted';
                    else
                        agtObj.Sign_Status__c = 'Declined';
                    
                    insert agtObj;
                }
            }
            
            System.DEBUG('New customer: created user ' + userId + ' under Account ' + account.Id);
            PageReference page = System.Page.CommunitiesSelfRegConfirm;
            page.setRedirect(true);
            return page;
        } 
        catch(Site.ExternalUserCreateException ex) {
            if (ex.getMessage().toLowerCase().contains('portal user already exists for contact')) {
                String msg = email + ' is already in use. Please choose another email address';
                PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, msg));
            } 
            else {
                List<String> errors = ex.getDisplayMessages();
                for (String msg : errors)  {
                    PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, msg));
                }
                
            }
            System.DEBUG(ex.getMessage());
        }
        return null;
    }
    
    private boolean isValidBUEntry(String entryIn, String defaultValue){
        return entryIn != null && !entryIn.equalsIgnoreCase(defaultValue) && entryIn.length() >= 1;
    }
    
    public List<SelectOption> getItems() { 
        List<SelectOption> plValues = new List<SelectOption>();
        
        Schema.DescribeFieldResult dfr = User.JobClassification__c.getDescribe();
        plValues.add(DEFAULT_JOB_CLASSIFICATION); // default option is a blank
        for (Schema.PicklistEntry ple : dfr.getPicklistValues()) {
            if (!ple.isActive()) continue;
            plValues.add(new SelectOption(ple.getValue(), ple.getLabel()));
        }
        
        return plValues;
    }
    
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz1234567890';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
    
    @future
    private static void updateUserRegDate(Id userId) {
        List<User> users = [Select CreatedDate from User where Id=: userId];
        if(!users.isEmpty()) {
            User usr = users.get(0);
            usr.Registration_Date__c = usr.CreatedDate;
            Database.update(usr);
        }
    }
    public static String generateHash(String string2Hash){
        Blob hashSHA1 = Crypto.generateDigest('SHA1', Blob.valueOf(string2Hash));
        return base64URLencode (hashSHA1);
    }
    
    public PageReference cancel(){
        return null;
    }
    
    @RemoteAction
    public static boolean doesUserExist(String anEmail){
        if (anEmail.containsIgnoreCase('@landolakes.com')){
            return true;
        }
        List<User> users = [SELECT Id FROM User WHERE email = :anEmail];
        boolean userFound = (users !=null && users.size() > 0);
        return userFound;
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