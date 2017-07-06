/**
 * An apex page controller that exposes the site forgot password functionality
 */
public with sharing class EMSForgotPasswordCntrl {

    public String username {get; set {username = value == null ? value : value.trim(); }}   
    
    public PageReference forgotPassword() {
        if (username == null || username.length() < 1) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a username');
            ApexPages.addMessage(msg);
            return null;
        }
        System.DEBUG('Attempting to locate user based on entered sign-in name of ' + username);
        List<User> users = [SELECT Id, Username, FederationIdentifier,External_fed_Id__C, Email FROM User WHERE External_fed_Id__C = :username LIMIT 1];
        if (users != null && users.size() == 1) {
            User user = users.get(0);
            System.DEBUG('Located user ' + user.Username + ' based on entered sign-in name of ' + username);
            sendEmail(user, user.Username);
            PageReference pr = Page.EMSForgotPasswordConfirm;
            pr.setRedirect(true);
            return pr;
        }
        System.DEBUG('Failed to locate user based on entered sign-in name of ' + username);
        ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'No such user');
        ApexPages.addMessage(msg);
          
        return null;
    }
    
    
    public static void sendEmail(User user, String username) {
        List<Messaging.SendEmailResult> listEmailResult = null;
        List<Messaging.Singleemailmessage> listSingleEmailMessages = new List<Messaging.SingleEmailMessage>();
        //EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'Custom_Forgot_Password_HTML']; 
         EmailTemplate emailTemplate = [SELECT Id, Subject, Body FROM EmailTemplate WHERE DeveloperName = 'Custom_Forgot_Password_Plaintext']; 
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSenderDisplayName('Land O\'Lakes Customer Access Portal'); 
        mail.setReplyTo('noreply@salesforce.com');
        mail.setTargetObjectId(user.id);
        
        // String htmlBody = emailTemplate.HtmlValue;
        String plainBody = emailTemplate.Body;
            
        String resetUrl = Site.getBaseUrl() + '/EMSSetPassword?token=' + issueJWT(username, 1800);
        Map<String, String> mapBodyParams = new Map<String, String> {
               '{!resetUrl}' => resetUrl
        };            
        for (String key : mapBodyParams.keySet()) {
            // htmlBody = htmlBody.replace(key, (mapBodyParams.get(key) == null) ? '' : mapBodyParams.get(key));
            plainBody = plainBody.replace(key, (mapBodyParams.get(key) == null) ? '' : mapBodyParams.get(key));
        }
        // mail.setHtmlBody(htmlBody);
        mail.setSaveAsActivity(false);
        mail.setPlainTextBody(plainBody);
        mail.setSubject(emailTemplate.subject);
        listSingleEmailMessages.add(mail);
        listEmailResult = Messaging.sendEmail(listSingleEmailMessages);
    }

    
    public static String issueJWT(String subject, Integer validFor) {
        JSONGenerator claim = JSON.createGenerator(false);
        claim.writeStartObject();
        claim.writeStringField('sub', subject);
        Long rightNow = (dateTime.now().getTime()/1000)+1;
        claim.writeNumberField('exp', (rightNow + validFor));
        claim.writeEndObject();
        String jwt = base64URLencode(Blob.valueOf(claim.getAsString()));
        Blob key = EncodingUtil.base64Decode('Ysllowklal2l4l12l0kkk1lKhh222kk2');
        Blob signature = Crypto.generateMac('hmacSHA1',Blob.valueof(jwt),key);
        jwt += '.' + base64URLencode(signature);  
        return jwt;
    
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