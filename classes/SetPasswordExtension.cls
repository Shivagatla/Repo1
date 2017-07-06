public with sharing class SetPasswordExtension {
    private ApexPages.StandardController c;
    
    // Getter methods you can call from your Visualforce page, e.g. {! viewingMyProfile }
    public String userID { get; set; }
    public String newPassword { get; set; } 
    public String userIDforAssign {get; set; }
    
    
    // Constructor method for the controller
    public SetPasswordExtension (ApexPages.StandardController stdController) {
        c = stdController;  
    }
    
    public void setPassword() {
        try{
            Profile adminId = [SELECT Id from Profile where Name='System Administrator' LIMIT 1];
            
            if (UserInfo.getProfileId() != adminId.Id ){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must have System Administrator access to perform this action'));
                
            }
            else {
                String username = '';
                if (userID.indexOf('@')<0)
                    username = userID + '@%';
                else
                    username = userID;
                List<User> usersL = [SELECT Id, FirstName, LastName FROM User WHERE isActive = true AND Username like :username LIMIT 1];
                if (usersL.isEmpty() || usersL.size() != 1 ){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'A unique user was not found for:' + userID));
                    
                    
                }
                else {
                    User users = usersL[0];
                    System.setPassword(users.Id,newPassword);    
                    String message = 'User password changed.  Please notify ' + users.FirstName + ' ' + users.LastName + ' of the new password.';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, message));
                    
                    
                    userID = '';
                    newPassword = '';
                }
            }
        }
        catch(Exception e){
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an error changing the password.  ' + e.getMessage()));
            
            
        }
    }
    
  
    public PageReference cancel(){
        return c.cancel();
    }

}