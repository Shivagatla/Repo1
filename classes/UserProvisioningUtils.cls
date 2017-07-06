public class UserProvisioningUtils {
    public static final String PARAM_DEBUG_LOGGING = 'debugLogging';
    public static final String PARAM_UPR_ID = 'userProvisioningRequestId';
    public static final String PARAM_USERID = 'userId';
    public static final String PARAM_STATUS = 'Status';
    public static final String PARAM_DETAILS = 'Details';
    public static final String PARAM_EXTERNAL_USERID = 'ExternalUserId';
    public static final String PARAM_EXTERNAL_USERNAME = 'ExternalUserName';
    public static final String PARAM_EXTERNAL_EMAIL = 'ExternalEmail';
    public static final String PARAM_EXTERNAL_FIRSTNAME = 'ExternalFirstName';
    public static final String PARAM_EXTERNAL_LASTNAME = 'ExternalLastName';
    public static final String PARAM_RECON_FILTER = 'reconFilter';
    public static final String PARAM_RECON_OFFSET = 'reconOffset';
    public static final String PARAM_NEXT_RECON_OFFSET = 'nextReconOffset';

    public static final Integer MAX_LOG_LEN = 1300;
    
    public static String uprId = '';
    public static boolean isDebug = false;
    public static List<String> pendingLogs = new List<String>();
    public static UserProvisioningRequest upr;
    public static UserProvisioningConfig upc;
    public static NamedCredential namedCredential;
    
    
    public static void init(String uprIdStr) {
        uprId = uprIdStr;
        upr = [SELECT connectedAppId, User_Reason__c,UserProvConfigId, salesforceUserId FROM UserProvisioningRequest WHERE id = :uprId LIMIT 1];
        upc = [SELECT namedCredentialId, reconFilter FROM UserProvisioningConfig where id = :upr.UserProvConfigId LIMIT 1];
        namedCredential = [SELECT developerName FROM NamedCredential where id = :upc.namedCredentialId LIMIT 1];        
    }
    
    public static String getNamedCredential() {
        return namedCredential.developerName;
    }
    
    public static String getConnectedAppId() {
        return upr.connectedAppId;
    }
    
    public static String getReconFilter() {
    	return upc.reconFilter;
    }

    public static UserProvAccount getLinkedUserProvAccount() {
    	UserProvAccount upa;
    	UserProvAccount[] upaList = [SELECT name, externalUserId, SalesforceUserId,externalUsername, externalEmail, externalFirstname, externalLastname, linkState, status FROM UserProvAccount WHERE salesforceUserId = :upr.salesforceUserId AND linkState = 'Linked'];
        if(upaList.size() > 0)
        	upa = upaList[0];
        return upa;
    }

    public static UserProvAccount getLinkedUserProvAccount(Id appId) {
        UserProvAccount upa;
        UserProvAccount[] upaList = [SELECT name, externalUserId, SalesforceUserId, externalUsername, externalEmail, externalFirstname, externalLastname, linkState, status FROM UserProvAccount WHERE ConnectedappId=:appid and salesforceUserId = :upr.salesforceUserId AND linkState = 'Linked'];
        if(upaList.size() > 0)
            upa = upaList[0];
        return upa;
    }

  
    public static boolean areParamsBlank(Map<String,String> paramsMap, Map<String,Object> result) {
        boolean isBlank = false;
        String paramStr = 'Input parameters: ';
        String logStr = '';
        for (String key: paramsMap.keySet()) {
            String value = paramsMap.get(key);
            if(String.isBlank(value)){
                isBlank = true;
                logStr += '[' + key + ']';
            }
            if(isDebug) {
                paramStr = paramStr + key + '=[' + value + '],';
            }
        }
        debug(paramStr);
        if(isBlank) {
            String logStr2 = 'These plugin input parameters should not be blank: ' + logStr;
            log(logStr2);
            result.put('Status', 'Failed');
            result.put('Details', logStr2);
        }
        return isBlank;
    }

    public static void debug(Object details) {
        if(isDebug)
            log(details); 
    }

    public static void log(Object details) {
        String detailsStr = String.valueOf(details);
        System.debug(detailsStr);
        String detailsStr2 = detailsStr.abbreviate(MAX_LOG_LEN);
        pendingLogs.add(detailsStr2);
    }
    
    public static void insertLogs() {
        for(String logStr : pendingLogs) {
            UserProvisioning.UserProvisioningLog.log(uprId, logStr); 
        }
    }

    public static void updateManualStatusOnUPR(Boolean updateValue){
        upr.Needed_ManualProv__c=updateValue;
        update upr;
    }
    
    public static void handleException(Map<String,Object> result, String s, Exception e) {
        result.put('Status', 'Failed');
        String s1 = 'Exception in plugin:' + e + ', StackTrace:' + e.getStackTraceString();
        result.put('Details', s1.abbreviate(255));
        String s2 = s + e + ', StackTrace:' + e.getStackTraceString();
        log(s2);
    }    
}