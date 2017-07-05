/**
* @author Gurditta Garg
* @date March 2016
* @description This class is for Payload which would be passed in the POST body while hitting the AD APIs
*/

public class Payload {
    public String Ag2agId{get;set;}
    public String AppCode{get;set;}
    public Integer IsDefaultHomePage{get;set;}
    public String ApplicationMigrationStatus{get;set;}
    public String Comments{get;set;}
    public List<String> ADGroup{get;set;}
    public String AppRole{get;set;}
    
    public Payload (String Ag2agId, String AppCode, Integer IsDefaultHomePage, String ApplicationMigrationStatus,String Comments, List<String> ADGroup, String AppRole) {
        this.Ag2agId = Ag2agId;
        this.AppCode = AppCode;
        this.IsDefaultHomePage = IsDefaultHomePage;
        this.ApplicationMigrationStatus = ApplicationMigrationStatus;
        this.Comments = Comments;
        this.ADGroup = ADGroup;
        this.AppRole = AppRole;
    }
}