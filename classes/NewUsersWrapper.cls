public class NewUsersWrapper {
	public User usr{get;set;}
    public Contact con{get;set;}
    public Account acc{get;set;}
    public String winfieldUnit{get;set;}
    public String purinaUnit{get;set;}
    public String lolUnit{get;set;}
    public String corpUnit{get;set;}
    public String mgrName{get;set;}
    public String mgrEmail{get;set;}
    public String mgrPhone{get;set;}
    public String rtrName{get;set;}
    public String rtrCity{get;set;}
    public String rtrState{get;set;}
    
    public NewUsersWrapper(User usr, Contact con, Account acc, String winfieldUnit, String purinaUnit, String lolUnit, String corpUnit,
                           String mgrName, String mgrEmail, String mgrPhone, String rtrName, String rtrCity, String rtrState) {
        this.usr = usr;
        this.con = con;
        this.acc = acc;
        this.winfieldUnit = winfieldUnit;
        this.purinaUnit = purinaUnit;
		this.lolUnit = lolUnit;
		this.corpUnit = corpUnit;
		this.mgrName = mgrName;
		this.mgrEmail = mgrEmail;
		this.mgrPhone = mgrPhone;
        this.rtrName = rtrName;
        this.rtrCity = rtrCity;
        this.rtrState = rtrState;
    }
}