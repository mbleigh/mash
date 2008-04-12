# Mash allows you to create pseudo-objects that have method-like
# accessors for hash keys. This is useful for such implementations
# as an API-accessing library that wants to fake robust objects
# without the overhead of actually doing so. Think of it as OpenStruct
# with some additional goodies.
#
# == Basic Example
#    
#   mash = Mash.new
#   mash.name? # => false
#   mash.name = "Bob"
#   mash.name # => "Bob"
#   mash.name? # => true
#
# == Hash Conversion  Example
#   
#   hash = {:a => {:b => 23, :d => {:e => "abc"}}, :f => [{:g => 44, :h => 29}, 12]}
#   mash = Mash.new(hash)
#   mash.a.b # => 23
#   mash.a.d.e # => "abc"
#   mash.f.first.g # => 44
#   mash.f.last # => 12
#
class Mash < Hash
  VERSION = '0.0.1'
  
  # If you pass in an existing hash, it will
  # convert it to a Mash including recursively
  # descending into arrays and hashes, converting
  # them as well.
  def initialize(source_hash = nil)
    mash_a_hash(source_hash) if source_hash
    super(nil)
  end
  
  def id #:nodoc:
    self["id"] ? self["id"] : super
  end
  
  def [](key) #:nodoc:
    key = key.to_s
    return Mash.new unless key?(key)    
    super
  end
  
  def []=(key,value) #:nodoc:
    key = key.to_s
    super
  end
  
  # Prints out a pretty object-like string of the
  # defined attributes.
  def inspect
    ret = "<#{self.class.to_s}"
    keys.sort.each do |key|
      ret << " #{key}=#{self[key].inspect}"
    end
    ret << ">"
    ret
  end
  
  alias :to_s :inspect
  
  def method_missing(method_name, *args) #:nodoc:
    if (match = method_name.to_s.match(/(.*)=$/)) && args.size == 1
      self[match[1]] = args.first
    elsif (match = method_name.to_s.match(/(.*)\?$/)) && args.size == 0
      key?(match[1])
    elsif keys.include?(method_name.to_s)
      self[method_name]
    elsif match = method_name.to_s.match(/^([a-z][a-z0-9A-Z_]+)$/)
      Mash.new
    else
      super
    end
  end
  
  private
  
  def mash_a_hash(hash) #:nodoc:
    hash.each do |k,v|
      case v
        when Hash
          v = Mash.new(v) if v.is_a?(Hash)
        when Array
          v = collect_mashed_hashes_in(v) if v.is_a?(Array)
      end
      
      self[k] = v
    end
  end
  
  def collect_mashed_hashes_in(array) #:nodoc:
    array.collect do |value|
      case value
        when Hash
          Mash.new(value)
        when Array
          collect_mashed_hashes_in(value)
        else
          value
      end
    end
  end
end