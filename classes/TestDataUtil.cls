@isTest
public class TestDataUtil {
	public static User createUser(Integer i, String emailId, String userName, String accId, String profileId){
        User newUser = new User();
        String accountId = accId;
        String usernameBase = userName;
        newUser.Username = usernameBase + '@landolakes.com.ems.dev';
        newUser.Initial_password__c = 'welcome'+i;
        newUser.CommunityNickname = usernameBase;
        newUser.ProfileId = profileId;
        newUser.Email = emailId;
        newUser.Phone = '9999999999';
        newUser.FirstName = 'Test'+i;
        newUser.LastName = 'User'+i;
        newUser.JobClassification__c = 'Farmer';
        newUser.Grower__c = true;
        newUser.Registration_Status__c = 'Approved';
        
        return newUser;
    }
    
    public static Contact createContact(Integer i, String accId){
        Contact newUserContact = new Contact(
            FirstName = 'Test'+i,
            Lastname = 'User'+i,
            AccountId = accId,
            Email = 'test'+i+'@user'+i+'.com',
            Registration_Denied__c = false,
            Manager_Name__c = 'MgrName'+i,
            Manager_Email__c = 'mgr'+i+'@email.com',
            Manager_Phone__c = '88888888888',
            Retailer_Name__c = 'RetailerName'+i,
            Retailer_City__c = 'RetailerCity'+i,
            Retailer_State__c = 'RetailerState'+i
        );
        
        return newUserContact;
    }
}