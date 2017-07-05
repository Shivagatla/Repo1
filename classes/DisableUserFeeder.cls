global class DisableUserFeeder implements Iterator<User>, Iterable<User> {
    List<User> source;
    
    global Iterator<User> iterator() {
        return this;
    }
    
    public DisableUserFeeder(List<User> source) {
        this.source = source;
    }
    
    public User next() {
        return source.remove(0);
    }
    
    global boolean hasNext() {
        return source!=null && !source.isempty();
    }
}