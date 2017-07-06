public class SetPasswordCntrl {
  
    // Getter methods you can call from your Visualforce page, e.g. {! viewingMyProfile }
    public String userID { get; set; }
    public String newPassword { get; set; } 
    public String messages{get;set;}
    public Contact cont {get;set;}
    
    
    // Constructor method for the controller
    public SetPasswordCntrl () {
        messages ='';

      }
    
    public void setPassword() {
        messages='';
        try{
            List<Profile> adminIds = [SELECT Id from Profile where (Name='System Administrator' or Name = 'EMS Internal Community Plus') and Id=:UserInfo.getProfileId() LIMIT 1];
            
            if (adminIds == null || adminIds.size() == 0 ){
                messages = messages + 'You must have the appropriate  access to perform this action. Please call the EMS Project Team.\n';
             
                
            }
            else {
                String username = '';
                if (userID.indexOf('@')<0)
                    username = userID + '@%';
                else
                    username = userID;
                List<User> usersL = [SELECT Id, FirstName, LastName FROM User WHERE isActive = true AND External_fed_Id__c like :userId LIMIT 1];
                if (usersL.isEmpty() || usersL.size() != 1 ){
                    messages = messages+'A unique user was not found for:' + userID;
                    
                    
                }
                else {
                    User users = usersL[0];
                    System.setPassword(users.Id,newPassword);   
                     ID jobID = System.enqueueJob(new UserProvisioningServiceQueuable('CHANGEPASSWORD',users.Id, newPassword)); 
                    messages = messages + 'User password changed.  Please notify ' + users.FirstName + ' ' + users.LastName + ' of the new password.\n';
                  userID = '';
                    newPassword = '';
                }
            }
        }
        catch(Exception e){
            
            messages=messages+ 'There was an error changing the password.  ' + e.getMessage();
            
            
        }
    }
    
  
    public PageReference cancel(){
    	userID = '';
        newPassword = '';
        messages='';
        return null;
	}
}