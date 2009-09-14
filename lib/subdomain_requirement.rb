# SubdomainRequirement
#  In a multi-tenant application, there are controllers
#  that may make sense in the context of one subdomain
#  but not others.  ie. an admin subdomain will have
#  functionality that you don't want to expose to other
#  subdomains.
#
#  This allows restricting a controller to a particular subdomain.
#  When attempting access through an unauthorized subdomain,
#  the default action is to return a 402 error.
#

module SubdomainRequirement
  def self.included(klass)
    klass.send :class_inheritable_array, :subdomain_requirements
    klass.send :include, InstanceMethods
    klass.send :extend, ClassMethods
    klass.before_filter(:check_subdomain)

    klass.send :subdomain_requirements=, []
  end

  module ClassMethods
    # options:  TODO.  these aren't recognized yet since I don't need it yet
    # :redirect_on_error => 'path' - sends to a path.  by default respond with a 404
    #  :only=>:subdomain  - the controller only works for the subdomain
    #  :except=>:subdomain - works for all subdomains except those listed
    def require_subdomain(subdomain, options={})
      subdomain = [subdomain] unless Array === subdomain
      options.to_options!

      self.subdomain_requirements ||= []
      self.subdomain_requirements << {:subdomains=>subdomain, :options=>options}

    end
    
    def subdomain_allowed?(subdomain)
      return true if self.subdomain_requirements.empty?
      
      self.subdomain_requirements.each do |subdomain_requirement|
        if subdomain_requirement[:subdomains] .include? subdomain.to_sym
          return true
        end unless subdomain.nil?
      end
      return false
    end
  end

  module InstanceMethods
    def check_subdomain
      if !self.class.subdomain_allowed?(current_subdomain)
        render "#{RAILS_ROOT}/public/404.html", :status=>404
      end
    end
  end

end
