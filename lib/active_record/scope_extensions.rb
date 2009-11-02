ActiveRecord::NamedScope::Scope.class_eval do
  private
  def load_found(*args)
    @found = find(:all, :eager => true)
  end
end