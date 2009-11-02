ActiveRecord::NamedScope::Scope.class_eval do
  def paginate(options = {})
    scoped(:limit => options[:limit], :offset => options[:offset])
  end
end