/**
* @author Gurditta Garg
* @date March 2016
* @description This class is for feeding Payloads to batch for Mass Upload Functionality
*/

global class MassUploadDeleteAccessrFeeder implements Iterator<Payload>, Iterable<Payload> {
    List<Payload> source;
    
    global Iterator<Payload> iterator() {
        return this;
    }
    
    public MassUploadDeleteAccessrFeeder(List<Payload> source) {
        this.source = source;
    }
    
    public Payload next() {
        return source.remove(0);
    }
    
    global boolean hasNext() {
        return source!=null && !source.isempty();
    }
}