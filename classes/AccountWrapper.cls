global class AccountWrapper{
        public String Name{get;set;}
        public String Address{get;set;}
        public String AcctNo{get;set;}
        public AccountWrapper(String Name,String Address,String AcctNo) {
            this.Name = Name;this.Address = Address;this.AcctNo = AcctNo;
        }
    }