ActiveRecord::Base.class_eval do
  class << self
    VALID_FIND_OPTIONS = VALID_FIND_OPTIONS + [:eager]
                           
    def find_every_with_scope(options)
      if options.delete(:eager)
        find_every_without_scope(options)
      else
        scoped(options)
      end
    end
    alias_method_chain :find_every, :scope
    
    def find_initial_with_eager_loading(options)
      find_initial_without_eager_loading(options.merge(:eager => true))
    end
    alias_method_chain :find_initial, :eager_loading
  end
end