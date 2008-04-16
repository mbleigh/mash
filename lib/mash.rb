# Mash allows you to create pseudo-objects that have method-like
# accessors for hash keys. This is useful for such implementations
# as an API-accessing library that wants to fake robust objects
# without the overhead of actually doing so. Think of it as OpenStruct
# with some additional goodies.
#
# A Mash will look at the methods you pass it and perform operations
# based on the following rules:
# 
# * No punctuation: Returns the value of the hash for that key, or nil if none exists.
# * Assignment (<tt>=</tt>): Sets the attribute of the given method name.
# * Existence (<tt>?</tt>): Returns true or false depending on whether that key has been set.
# * Bang (<tt>!</tt>): Forces the existence of this key, used for deep Mashes. Think of it as "touch" for mashes.
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
# == Bang Example
#
#   mash = Mash.new
#   mash.author # => nil
#   mash.author! # => <Mash>
#   
#   mash = Mash.new
#   mash.author!.name = "Michael Bleigh"
#   mash.author # => <Mash name="Michael Bleigh">
#
class Mash < Hash
  VERSION = '0.0.3'
  
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
  
  alias_method :regular_reader, :[]
  alias_method :regular_writer, :[]=
  
  # Retrieves an attribute set in the Mash. Will convert
  # any key passed in to a string before retrieving.
  def [](key)
    key = convert_key(key)
    regular_reader(key)
  end
  
  # Sets an attribute in the Mash. Key will be converted to
  # a string before it is set.
  def []=(key,value) #:nodoc:
    key = key.to_s
    regular_writer(key,value)
  end
  
  # This is the bang method reader, it will return a new Mash
  # if there isn't a value already assigned to the key requested.
  def initializing_reader(key)
    return self[key] if key?(key)
    self[key] = Mash.new
  end
  
  alias_method :regular_inspect, :inspect
  
  alias_method :picky_key?, :key?
  def key?(key)
    picky_key?(convert_key(key))
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
  
  alias_method :to_s, :inspect
  
  def method_missing(method_name, *args) #:nodoc:
    if (match = method_name.to_s.match(/(.*)=$/)) && args.size == 1
      self[match[1]] = args.first
    elsif (match = method_name.to_s.match(/(.*)\?$/)) && args.size == 0
      key?(match[1])
    elsif (match = method_name.to_s.match(/(.*)!$/)) && args.size == 0
      initializing_reader(match[1])
    elsif keys.include?(method_name.to_s)
      self[method_name]
    elsif match = method_name.to_s.match(/^([a-z][a-z0-9A-Z_]+)$/)
      nil
    else
      super
    end
  end
  
  protected
  
  def convert_key(key) #:nodoc:
    key.to_s
  end
  
  def mash_a_hash(hash) #:nodoc:
    hash.each do |k,v|
      case v
        when Hash
          v = Mash.new(v) if v.is_a?(Hash)
        when Array
          v = collect_mashed_hashes_in(v) if v.is_a?(Array)
      end
      
      # we use the method call instead of []= here so that
      # it can be easily overridden for custom behavior in
      # inheriting objects
      self.send "#{k.to_s}=", v
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

class Hash
  # Returns a new Mash initialized from this Hash.
  def to_mash
    mash = Mash.new(self)
    mash.default = default
    mash
  end
end