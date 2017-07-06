public class UserProvisioningService {

    private static final String HTTP_METHOD_POST = 'POST';

    public String createUser(String password,String firstName, String lastName, String email,
        String phone, String company,String division,String userType, String customerNumber, String state) 
   {
        
        Boolean useEmailAsLogin = (userType != null && userType.equalsIgnorecase('Farmer'));
        String ag2agID = useEmailAsLogin ?
           provisionUser(password,firstName,lastName,email,phone,company,division,email,customerNumber,state):
           provisionUser(password,firstName,lastName,email,phone,company,division,null,customerNumber,state);
        
        return ag2agID;
    }
    
    private String provisionUser(String password,String firstName, String lastName, 
        String email,String phone, String company,String division,String loginName, String customerNumber,String state) 
    {
    
        Map<String,object> payload = new Map<String,object>();
        payload.put('FirstName',firstName);
        payload.put('LastName',lastName);
        payload.put('Email',email);
        payload.put('Telephone',phone);
        payload.put('Company',company);
        payload.put('Division',division);
        payload.put('StatusCode','active');
        payload.put('UserType','CUSTOMER');
        payload.put('Password',password);
   
        if (loginName != null)
            payload.put('LoginName',loginName);
        if (customerNumber != null)
            payload.put('CustomerNumber',customerNumber);
        if (state != null)
            payload.put('State',state);    
            
        try{
                
            Map<String,String> response = (Test.isRunningTest()==false) ?
                callService('callout:LoL_Web_Services/api/idm/createuser','POST',payload) :
                new Map<String,String>{'Ag2agId' => '_dummy01'};
        
            String ag2agID = response.get('Ag2agId');     
            if (ag2agID == null || ag2AgID.trim().length() < 1)
                throw new EMSException('ERROR -> Failed to generate Ag2Ag ID for ' + email + ' : ' + response);  
        
            System.DEBUG('SUCCESS: created user ' + ag2agID + ' (' + firstName + ' ' + lastName + ') with ' + loginName);      
            return ag2agID;

        }
        catch(Exception e){
            throw new EMSDuplicateUserException('User Login ' + loginName + ' is already in use.');
        }
        return '';
        
    }
    
    public void entitleUser(User user,Application__c app, Set<Entitlements__c> entitlements) {
        entitleUser(user,app,entitlements,null);
    }
    
    public void entitleUser(User user,Application__c app, Set<Entitlements__c> entitlements,String reason) {
    
        entitleUser(user,app,entitlements,(new Set<Account>()),reason);
    }
    
     public void entitleUser(User user,Application__c app, Set<Entitlements__c> entitlements, Set<Account> accounts, String reason) {
    
        List<String> groups = new List<String>();
        List<String> appEntitlements = new List<String>();
        Map<String,object> payload = new Map<String,object>();

  
        if (entitlements != null) {
            for(Entitlements__c entitlement:entitlements) {
                String aGroup1 = entitlement.AD_Group__c;
                String aGroup2 = entitlement.Ad_Group_Optional__c;
                String entCode = entitlement.Name; 
                if (aGroup1 != null)
                    groups.add(formatADGroupName(aGroup1));
                if (aGroup2 != null)
                     groups.add(formatADGroupName(aGroup2));
                if (entCode != null && !Boolean.valueOf(app.Use_AD_Role_Name__c))
                    appEntitlements.add(entCode);   
                else
                    payload.put('ADRoleName',entCode);

            }
        }
    
       

        if (accounts!= null){
            for(Account acct:accounts){
                appEntitlements.add(ApplicationHelper.getAppGUIDValue(app, acct));
            }
        }
        
        if (app.Group_Designation__c != null)
            groups.add(formatADGroupName(app.Group_Designation__c));
             
        
        
        payload.put('Ag2agId',user.Ag2Ag_ID__c);
        payload.put('AppCode',app.App_Code__c);
        payload.put('IsDefaultHomePage',Boolean.valueOf(app.Home_Page__c) ? 1 : 0);
        payload.put('ApplicationMigrationStatus',Boolean.valueOf(app.Migrated__c) ? 'Migrated' : 'NonMigrated');
        if (reason != null)
            payload.put('Comments',reason);
        if (groups.size() > 0)
            payload.put('ADGroup',groups);
        if (appEntitlements.size() > 0)
            payload.put('AppRole',appEntitlements);
               System.debug('The payload is----------------');
        System.debug(payload); 
        if (Test.isRunningTest()==false)
            callService('callout:LoL_Web_Services/api/idm/createuseraccess','POST',payload);  

        System.DEBUG('SUCCESS: entitled user ' + user.Ag2Ag_ID__c + ' to ' + app.App_Code__c);
    }
    
    class EntitlementTuple {
        String appRole;
        String actionCode;
    
        public EntitlementTuple(String aRole, String anActionCode) {
            this.appRole = aRole;
            this.actionCode = anActionCode;
        }
    }
    
    class GroupTuple {
        String cn;
        String actionCode;
    
        public GroupTuple(String aCN, String anActionCode) {
            this.cn = aCN;
            this.actionCode = anActionCode;
        }
    }
    
    public void modifyUserEntitlementsByAction(User user,Application__c app, Set<Entitlements__c> entitlements, String reason, String action) {
        modifyUserEntitlementsByAction(user,app,entitlements,new Set<Account>(),reason,action);
    }

    public void modifyUserEntitlementsByAction(User user,Application__c app, Set<Entitlements__c> entitlements,Set<Account> accounts, String reason,  String action) {
    
        List<GroupTuple> groups = new List<GroupTuple>();
        List<EntitlementTuple> appEntitlements = new List<EntitlementTuple>();
        Map<String,object> payload = new Map<String,object>();
        if (entitlements != null) {
            for(Entitlements__c entitlement:entitlements) {
                String aGroup1 = entitlement.AD_Group__c;
                String aGroup2 = entitlement.Ad_Group_Optional__c;
                String entCode = entitlement.Name; 
                String actionCode = action; // NEW, not part of Entitlement__c class (yet)
                if (aGroup1 != null)
                    groups.add(new GroupTuple(formatADGroupName(aGroup1),actionCode));
                if (aGroup2 != null)
                     groups.add(new GroupTuple(formatADGroupName(aGroup2),actionCode));
                 if (entCode != null && !Boolean.valueOf(app.Use_AD_Role_Name__c))
                     appEntitlements.add(new EntitlementTuple(entCode,actionCode));      
                else
                    payload.put('ADRoleName',entCode);
   
            }
        }
        if (accounts!= null){
            for(Account acct:accounts){
                appEntitlements.add(new EntitlementTuple(ApplicationHelper.getAppGUIDValue(app, acct),action));
            }
        }
                   
        
        
        payload.put('Ag2agId',user.Ag2Ag_ID__c);
        payload.put('AppCode',app.App_Code__c);
        payload.put('IsDefaultHomePage',Boolean.valueOf(app.Home_Page__c) ? 1 : 0);
        payload.put('ApplicationMigrationStatus',Boolean.valueOf(app.Migrated__c) ? 'Migrated' : 'NonMigrated');
        //if (reason != null)
        //    payload.put('Comments',reason);
        if (groups.size() > 0)
            payload.put('ADGroup',groups);
        if (appEntitlements.size() > 0)
            payload.put('AppRole',appEntitlements);
        System.debug('Payload:' + payload);
        if (Test.isRunningTest()==false)
            callService('callout:LoL_Web_Services/api/idm/modifyuseraccess','POST',payload);  
            
        System.debug('SUCCESS: modifed user with action ' + user.Ag2Ag_ID__c + ' to ' + app.App_Code__c + ' with entitlements: ' + appEntitlements);
    }
    
    
    
     public void modifyUserAccess(User user,Application__c app, Set<Entitlements__c> entitlements,String reason) {
    
        List<String> groups = new List<String>();
        List<String> appEntitlements = new List<String>();
       
        if (entitlements != null) {
            for(Entitlements__c entitlement:entitlements) {
                String aGroup1 = entitlement.AD_Group__c;
                String aGroup2 = entitlement.Ad_Group_Optional__c;
                String entCode = entitlement.Name; 
                if (aGroup1 != null)
                    groups.add(formatADGroupName(aGroup1));
                if (aGroup2 != null)
                     groups.add(formatADGroupName(aGroup2));
                if (entCode != null)
                    appEntitlements.add(entCode);    
            }
        }
        
        if (app.Group_Designation__c != null)
            groups.add(formatADGroupName(app.Group_Designation__c));
             
        Map<String,object> payload = new Map<String,object>();
        
        payload.put('Ag2agId',user.Ag2Ag_ID__c);
        payload.put('AppCode',app.App_Code__c);
        payload.put('IsDefaultHomePage',Boolean.valueOf(app.Home_Page__c) ? 1 : 0);
        payload.put('ApplicationMigrationStatus',Boolean.valueOf(app.Migrated__c) ? 'Migrated' : 'NonMigrated');
        //if (reason != null)
        //    payload.put('Comments',reason);
        if (groups.size() > 0)
            payload.put('ADGroup',groups);
        if (appEntitlements.size() > 0)
            payload.put('AppRole',appEntitlements);
        
        if (Test.isRunningTest()==false)
            callService('callout:LoL_Web_Services/api/idm/modifyuseraccess','POST',payload);  
            
        System.DEBUG('SUCCESS: modifed user ' + user.Ag2Ag_ID__c + ' to ' + app.App_Code__c + ' with entitlements: ' + appEntitlements);
    }

    public void disableUserAccess(User user,Application__c app, Set<Entitlements__c> entitlements,String reason) {
        disableUserAccess(user,app,entitlements, new Set<Account>(),reason);
    }
 

    public void disableUserAccess(User user,Application__c app, Set<Entitlements__c> entitlements,Set<Account> accounts, String reason) {
    
        List<String> groups = new List<String>();
        List<String> appEntitlements = new List<String>();
       
        if (entitlements != null) {
            for(Entitlements__c entitlement:entitlements) {
                String aGroup1 = entitlement.AD_Group__c;
                String aGroup2 = entitlement.Ad_Group_Optional__c;
                String entCode = entitlement.Name; 
                if (aGroup1 != null)
                    groups.add(formatADGroupName(aGroup1));
                if (aGroup2 != null)
                     groups.add(formatADGroupName(aGroup2));
                if (entCode != null)
                    appEntitlements.add(entCode);    
            }
        }
        if (accounts!= null){
            for(Account acct:accounts){
                appEntitlements.add(ApplicationHelper.getAppGUIDValue(app, acct));
            }
        }
        if (app.Group_Designation__c != null)
            groups.add(formatADGroupName(app.Group_Designation__c));
             
        Map<String,object> payload = new Map<String,object>();
        
        payload.put('Ag2agId',user.Ag2Ag_ID__c);
        payload.put('AppCode',app.App_Code__c);
        payload.put('ApplicationMigrationStatus',Boolean.valueOf(app.Migrated__c) ? 'Migrated' : 'NonMigrated');
        //if (reason != null)
        //    payload.put('Comments',reason);
        if (groups.size() > 0)
            payload.put('ADGroup',groups);
        if (appEntitlements.size() > 0)
            payload.put('AppRole',appEntitlements);
        
        if (Test.isRunningTest()==false)
            callService('callout:LoL_Web_Services/api/idm/disableuseraccess','POST',payload);  
            
        System.DEBUG('SUCCESS: modifed user ' + user.Ag2Ag_ID__c + ' to ' + app.App_Code__c + ' with entitlements: ' + appEntitlements);
    }

    public void changePassword(User u,String password) {
        if (user.Ag2Ag_ID__c == null)
            throw new EMSException('Change of password for user ' + u.Id + ' failed: Ag2Ag ID is null');
        if (password == null)
            throw new EMSException('Change of password for user ' + u.Ag2Ag_ID__c + ' failed: password is null');
        
        Map<String,object> payload = new Map<String,object>();
        
        payload.put('Ag2agId',u.Ag2Ag_ID__c);
        payload.put('Password',password);
        
        if (!Test.isRunningTest())
            callService('callout:LoL_Web_Services/api/idm/modifyuser','POST',payload);
              
        System.DEBUG('SUCCESS: changed password for user ' + u.Username + '(' + u.Ag2Ag_ID__c + ')');
    }
    
    public boolean changeContact(String ag2agID, Contact c) {
    
         if (ag2agID == null)
            throw new EMSException('Change of personal info for contact ' + c.Id + ' failed: Ag2Ag ID is null');
    
        Map<String,object> payload = new Map<String,object>();
        
        payload.put('Ag2agId',ag2agID);
        payload.put('LastName',c.Lastname);
        payload.put('FirstName',c.FirstName);
        payload.put('Email',c.Email);
        payload.put('Telephone',c.Phone);
        if (c.Related_External_User__r.BYOID__c)
            payload.put('LoginName',c.Email);
            
        try {
            if (!Test.isRunningTest())
                callService('callout:LoL_Web_Services/api/idm/modifyuser','POST',payload);  
                
            System.DEBUG('SUCCESS: changed contact fields ' + (c.Related_External_User__r.BYOID__c ? ' AND username ' : '') + 
                ' for user (' + ag2agID + '): ' + c.Firstname + ' '+ c.Lastname + ' ' + c.Email + ' ' + c.Phone);
            return true;
        }
        catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'Failed to update contact fields for user ' + ag2agID);
            return false;
        }
           
    }
    
    public String findUser(String email) {
    
        Map<String,object> payload = new Map<String,object>();
        payload.put('Email',email);
        
        try {
            Map<String,String> response = !Test.isRunningTest() ?
                callService('callout:LoL_Web_Services/api/idm/getloginid','POST',payload) :
                new Map<String,String>{'LoginID' => '_dummy01'};
                 
            String loginName = response.get('LoginID');     
        
            System.DEBUG('SUCCESS: Found user ' + email + ' -> ' + loginName);         
            return loginName;
        }
        catch (EMSNoSuchUserException e) {
            return null;
        }
    }
    
    public void disableUser(User u) {
    
        Map<String,object> payload = new Map<String,object>();
        
        payload.put('Ag2agId',u.Ag2Ag_ID__c);
        payload.put('StatusCode','inactive');
        
        if (!Test.isRunningTest())
            callService('callout:LoL_Web_Services/api/idm/disableuser','POST',payload); 
             
        System.DEBUG('SUCCESS: disabled user (' + u.Ag2Ag_ID__c + ')');
    }
     
    private Map<String,String> callService(String endpoint,String method,Map<String,object> payload) {
    
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));
        Http http = new Http();
        
        HTTPResponse res = http.send(req);
        Map<String,String> response = (Map<String,String>)JSON.deserialize(res.getBody(),Map<String,String>.class);
        String msg = 'Sending to: ' + endpoint  + ' Payload -> ' + payload ;
        System.DEBUG(msg);
        if (res.getStatusCode() != 200) {
           
            String errorCode = response.get('errorCode');
            if (errorCode != null) {
                if (errorCode.equalsIgnoreCase('LOGIN_MUST_BE_UNIQUE'))
                    throw new EMSDuplicateUserException();
                else if (errorCode.equalsIgnoreCase('USER_NOT_FOUND'))
                    throw new EMSNoSuchUserException();
            }
       
            msg = 'ERROR: Failed to execute service ' + endpoint  + ' Payload -> ' + payload + ' Response -> ' + res.getBody();
            System.DEBUG(msg);
            throw new EMSException();
        }
        
        return response;
    }
    
    // Group name may be a LDAP DN or a simple string. If it's a full DN, extract the value of CN and return that
    private String formatADGroupName(String aGroup) {
        if (aGroup.startsWithIgnoreCase('cn='))
            return aGroup.substringBefore(',').substringAfter('=');
        return aGroup;
    }
}