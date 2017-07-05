/**
 * An apex page controller that exposes the site forgot password functionality
 */
public with sharing class ForgotPasswordController {
    public String username {get; set;}   
       
    public ForgotPasswordController() {}
    
    public PageReference forgotPassword() {
        PageReference pr = Page.EMSForgotPasswordConfirm;
        pr.setRedirect(true);
        boolean ok = Site.forgotPassword(username);
        return ok ? pr : null;
    }
}