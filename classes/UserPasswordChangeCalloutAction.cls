public class UserPasswordChangeCalloutAction implements Queueable, Database.AllowsCallouts {
    
    User user;
    String newPassword;
    UserProvisioningService ups = new UserProvisioningService();
    
    public UserPasswordChangeCalloutAction(User user,String newPassword) {
        this.user = user;
        this.newPassword = newPassword;
    }
    public void execute(QueueableContext context) {
        ups.changePassword(user,newPassword);
    }
}