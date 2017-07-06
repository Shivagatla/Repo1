/**
* An apex class that keeps updates of a portal user in sync with its corresponding contact.
*/
public without sharing class EMSMyProfileCntrl {
    
    private User user;
    private boolean isEdit = false;
    public String fedId{get;set;}
    public String byoidmessage {get;set;}
    public boolean isFarmerUser {get;set;}
    
    public User getUser() {
        return user;
    }
    
    public EMSMyProfileCntrl() {
        user = [SELECT id,External_Fed_Id__c, email, username, usertype, communitynickname, timezonesidkey, languagelocalekey, firstname, lastname, phone, title,
                street, city, country, postalcode, state, localesidkey, BYOID__c,mobilephone, extension, fax, contact.email,Ag2Ag_Id__C,jobclassification__c
                FROM User
                WHERE id = :UserInfo.getUserId()];
        if(user.JobClassification__c != null) {
            if(!user.JobClassification__c.equalsIgnoreCase('Farmer')) {
                isFarmerUser = true;
            }
        } else {
            isFarmerUser = true;
        }
        // guest users should never be able to access this page
        if (user.usertype == 'GUEST') {
            throw new NoAccessException();
        }
        this.fedId = user.External_Fed_Id__c;
        byoidmessage = '';
    }
    
    public Boolean getIsEdit() {
        return isEdit;
    }
    
    public void edit() {
        isEdit=true;
    }
    
    public static boolean doesUserExist(String anEmail){
        List<User> suers = [SELECT email FROM User WHERE id =: UserInfo.getUserId()];
        List<User> users = [SELECT Id FROM User WHERE email = :anEmail and email != :suers.get(0).email];
        boolean userFound = (users !=null && users.size() > 0);
        return userFound;
    }
    public void save() {
        /*if(doesUserExist(user.email)) {
            isEdit=true;
            PageMessages.addMessage(new PageMessages.PageMessage(PageMessages.Severity.ERROR, 
                                                                 'This email already exists, please try different email'));
        } else {*/
            try {
                if (user.BYOID__c == true && this.fedId != user.email) {
                    byoidmessage = 'Your portal login will be modified since you modified your email address.';
                    user.External_Fed_Id__c = user.email;
                }
                
                UserProvisioningService ups = new UserProvisioningService();
                setContactFields(user.contact, user); 
                // Contact c = [select Id,Ag2Ag_Id__C,firstname,related_external_user__c,Related_External_User__r.Id,Related_External_User__r.BYOID__c,lastname,email,phone from Contact where Id=:user.contact.Id LIMIT 1];
                if(Test.isRunningTest()==false){
                    boolean ok = ups.changeContact(user.Ag2Ag_id__c,user.contact);
                    
                    if (ok && user.contact != null) {
                        
                        update user;
                        update user.contact;
                        
                        // ID jobID = System.enqueueJob(new UserProvisioningServiceQueuable('UPDATECONTACt',user,null));
                        
                    }    
                }   
                isEdit=false;
            } 
            catch(DmlException e) {
                ApexPages.addMessages(e);
            }
        //}
    }
    
    public PageReference changePassword() {
        return Page.EMSChangePasswordPage;
    }
    
    public void cancel() {
        isEdit=false;
        user = [SELECT id, email, username, communitynickname, timezonesidkey, languagelocalekey, firstname, lastname, phone, title,
                street, city, country, postalcode, state, localesidkey, mobilephone, extension, fax, contact.email,External_Fed_id__c,Ag2Ag_Id__C
                FROM User
                WHERE id = :UserInfo.getUserId()];
        this.fedId = user.External_Fed_Id__c;
    }
    
    public static void setContactFields(Contact c, User u) {
        c.title = u.title;
        c.firstname = u.firstname;
        c.lastname = u.lastname;
        c.email = u.email;
        c.phone = u.phone;
        c.mobilephone = u.mobilephone;
        c.fax = u.fax;
        c.mailingstreet = u.street;
        c.mailingcity = u.city;
        c.mailingstate = u.state;
        c.mailingpostalcode = u.postalcode;
        c.mailingcountry = u.country;
    }
}