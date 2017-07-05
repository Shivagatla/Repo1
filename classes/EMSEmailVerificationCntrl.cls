public class EMSEmailVerificationCntrl {

    public String hash {get;set;}
    public Boolean verified {get; set;}
    public String uid {get;set;}
    public String email{get;set;}
    public Boolean hasRun {get;private set;}


    public EMSEmailVerificationCntrl() {
        this.hash = ApexPages.currentPage().getParameters().get('key');
        //pluses get replaced with %20 and then they become spaces.  need to undo this.
        if (this.hash != null)
            this.hash = this.hash.replaceAll( '\\s+', '+');
        this.uid = ApexPages.currentPage().getParameters().get('uid');
        if (this.uid != null)
            this.uid = this.uid.replaceAll( '\\s+', '+');

        this.email = ApexPages.currentPage().getParameters().get('em');

        if (this.email != null)
            this.email = this.email.replaceAll( '\\s+', '+');

        hasRun = false;
        verified = false;
    }


    public PageReference verify(){
        verified = verifyHash();
        hasRun = true;
        System.debug('The user has been verified:'+verified);
        return null;
    }


    public Boolean verifyHash() {

        try {
             User[] users = [SELECT Id, Email,Email_Verified__c,FirstName,LastName,ContactId, Verify_hash__c FROM User WHERE Username=:this.uid and Email=:this.email LIMIT 1];

             if (users == null || users.size() != 1) {
                 String msg = 'Failed to verify user\'s email: unable to locate a user. uid = ' + this.uid + ' email = ' + this.email;
                 System.debug(msg);
                 notifyOnFailure(msg);
                 return false;
             }
         
             User user = users[0];
             if (user.Email_Verified__c == true) {   
                hasRun = true;
                return true;
             }
         
            System.debug('The user fn is:' + user.FirstName + ' and the user last name is:' + user.LastName);
             String generatedHash = generateHash(user.FirstName + user.LastName);
             System.debug('Comparing hashes. Hash from email verification link = ' + this.hash + ' versus generated ' + generatedHash);
             
             if (!this.hash.equalsIgnoreCase(generatedHash) && !this.hash.startsWith(generatedHash) && user.Verify_hash__c <> this.hash && !generatedHash.equalsIgnoreCase(this.hash.trim())) {
                if (generatedHash.endsWith('=')){
                    if ((this.hash+'=').equalsIgnoreCase(generatedHash)){
                        //everything is good
                    }
                    else{
                         String msg = 'Failed to verify user\'s email: hashes do not match. uid = ' + this.uid + ' Incoming: ' + this.hash + ' generated: ' + generatedHash;
                         msg = msg + '\n generatedhiash length: ' + generatedhash.length() +', incoming length:' + this.hash.length();
                         System.debug(msg);
                         notifyOnFailure(msg);
                         return false;
                    }
                }
                else{
                     String msg = 'Failed to verify user\'s email: hashes do not match. uid = ' + this.uid + ' Incoming: ' + this.hash + ' generated: ' + generatedHash;
                     msg = msg + '\n generatedhiash length: ' + generatedhash.length() +', incoming length:' + this.hash.length();
                     System.debug(msg);
                     notifyOnFailure(msg);
                     return false;
                 }
             }   
             
            Contact[] contacts = [SELECT Id,Email_Verified__c from Contact where Id=:user.ContactId LIMIT 1];
            
            if (contacts == null || contacts.size() != 1) {
                 String msg = 'Failed to verify user\'s email: unable to locate a contact. uid = ' + this.uid + ' contact Id of ' + user.ContactId;
                 System.debug(msg);
                 notifyOnFailure(msg);
                 return false;
            }
            Contact c = contacts[0];
            c.Email_Verified__c = true;
            update c;
          
        }
        catch(Exception e) {
            String msg = 'Failed to verify user\'s email due to an Exception. uid =  ' + this.uid + ' Error: ' + e.getMessage();
            notifyOnFailure(msg);
            System.debug(msg);
            return false;
        }
        return true;
    }
    
    private void notifyOnFailure(String msg) {
        String body = 'User-Agent: ' + ApexPages.currentPage().getHeaders().get('User-Agent') + '\n' + msg;
    
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{'ems@identigral.com'});
        mail.setSenderDisplayName('Land O\'Lakes Customer Access Portal'); 
        mail.setReplyTo('noreply@salesforce.com');
        mail.setPlainTextBody(body);
        mail.setSubject('ERROR: Email verification failed for ' + this.uid);
        
        List<Messaging.SingleEmailMessage> payload= new List<Messaging.SingleEmailMessage>();
        payload.add(mail);
        Messaging.sendEmail(payload,false);
    }

    public static String generateHash(String string2Hash) {
    
        Blob targetBlob = Blob.valueOf(string2Hash);
        Blob hashSHA1 = Crypto.generateDigest('SHA1', targetBlob);
        // For Rackspace Compatiblity encode the binary into BASE 64
        // this will result in 28 chars long string 
        return base64URLencode (hashSHA1);    
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