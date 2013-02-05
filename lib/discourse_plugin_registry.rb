#
#  A class that handles interaction between a plugin and the Discourse App.
#
class DiscoursePluginRegistry

  class << self
    attr_accessor :javascripts
    attr_accessor :server_side_javascripts
    attr_accessor :stylesheets
  end

  def register_js(filename, options={})
    self.class.javascripts ||= Set.new
    self.class.server_side_javascripts ||= Set.new

    # If we have a server side option, add that too.
    self.class.server_side_javascripts << options[:server_side] if options[:server_side].present?

    self.class.javascripts << filename
  end

  def register_css(filename)
    self.class.stylesheets ||= Set.new
    self.class.stylesheets << filename
  end

  def stylesheets
    self.class.stylesheets || Set.new
  end

  def register_archetype(name, options={})
    Archetype.register(name, options)
  end

  def server_side_javascripts
    self.class.javascripts || Set.new
  end

  def javascripts
    self.class.javascripts || Set.new
  end

  def self.clear
    self.stylesheets = Set.new
    self.server_side_javascripts = Set.new
    self.javascripts = Set.new
  end

  def self.setup(plugin_class)    
    registry = DiscoursePluginRegistry.new
    plugin = plugin_class.new(registry)
    plugin.setup
  end



end
