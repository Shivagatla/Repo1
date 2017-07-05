/**
 * An apex page controller that exposes the site login functionality
 */
global with sharing class SiteLoginController {
    global String username {get; set;}
    global String password {get; set;}

    global PageReference login() {
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        System.debug('Username is:'+username+'@landolakes.com.ems.predev');
        return Site.login(username+'@landolakes.com.ems.predev', password, startUrl);
    }
    
   	global SiteLoginController () {}
}