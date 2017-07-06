/**
* @author Gurditta Garg
* @date March 2016
* @description This class is for Payload which would be passed in the POST body while hitting the AD APIs
*/

public class PayLoadUser {
    public Payload payload{get;set;}
    public String connectedAppId{get;set;}
    public String userId{get;set;}
    public String userName{get;set;}
    public String entId{get;set;}
    public String appId{get;set;}
    public String email{get;set;}
    public String firstname{get;set;}
    public String lastname{get;set;}
    
    public PayLoadUser(Payload payload,String connectedAppId,String userId,String userName,String entId,String appId,String email,String firstname,String lastname) {
        this.payload = payload;
        this.connectedAppId = connectedAppId;
        this.userId = userId;
        this.userName = userName;
        this.entId = entId;
        this.appId = appId;
        this.email = email;
        this.firstname = firstname;
        this.lastname = lastname;
    }
}