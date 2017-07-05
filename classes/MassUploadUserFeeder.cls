/**
* @author Gurditta Garg
* @date March 2016
* @description This class is for feeding Payloads to batch for Mass Upload Functionality
*/

global class MassUploadUserFeeder implements Iterator<PayLoadUser>, Iterable<PayLoadUser> {
    List<PayLoadUser> source;
    
    global Iterator<PayLoadUser> iterator() {
        return this;
    }
    
    public MassUploadUserFeeder(List<PayLoadUser> source) {
        this.source = source;
    }
    
    public PayLoadUser next() {
        return source.remove(0);
    }
    
    global boolean hasNext() {
        return source!=null && !source.isempty();
    }
}