public  class EMSMainPageCntrl {
    public EMSMainPageCntrl() {
        
    }
    public PageReference Redir() {
        Profile userProfile = [SELECT Id,UserLicense.Name from Profile where Id=:UserInfo.getProfileId() LIMIT 1];
        String JobClassification = [Select JobClassification__c From User Where Id =: UserInfo.getUserId()][0].JobClassification__c;
        PageReference newPage;
        if (userProfile.UserLicense.Name.equalsIgnoreCase('Customer Community Plus') ){
            newPage = new PageReference('/apex/EMSHomePage');
        } else if (userProfile.UserLicense.Name.equalsIgnoreCase('Salesforce User') ){
            newPage = new PageReference('/apex/EMSHomePage');
        } else if (JobClassification != null && JobClassification.equalsIgnoreCase('Farmer')) {
            newPage = new PageReference('/ems/EMSProfilePage');
        } else {
            newPage = new PageReference('/ems/EMSMyAccessPage');
        } 
        return newPage.setRedirect(true);
    }
}