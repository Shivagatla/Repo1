/**********************************
Class Name: ChangePasswordController
Description: An apex page controller that exposes the change password functionality
Version: 1.0
***********************************/
public with sharing class ChangePasswordController {
    public String oldPassword {get; set;}
    public String newPassword {get; set;}
    public String verifyNewPassword {get; set;}        
    
    public PageReference changePassword() {
    	
        PageReference forwardPage;
        try{
        	forwardPage = Site.changePassword(newPassword, verifyNewPassword, oldpassword); 
        	//System.debug(forwardPage.getParameters());
        	
        }
        catch(Exception e){
        	System.debug('There was an error changing the password.  Please try again.');
        	return forwardPage;
      
        }
        //only if SF successful in changing the password, put in the job to change the password AD.
        if(Test.isRunningTest()==false){
          ID jobID = System.enqueueJob(new UserProvisioningServiceQueuable('CHANGEPASSWORD',UserInfo.getUserId(), newPassword));
        }
         return forwardPage;
      
    }     
    
   	public ChangePasswordController() {}

   	public PageReference cancel(){

   		oldPassword='';
   		newPassword='';
   		verifyNewPassword='';
   		return null;
   	}
}