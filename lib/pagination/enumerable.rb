Enumerable.module_eval do
  def paginate(options = {})
    self[options[:offset]..(options[:offset] + options[:limit] - 1)] || []
  end
end