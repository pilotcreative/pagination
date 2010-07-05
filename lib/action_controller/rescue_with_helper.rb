# When an exception happens inside a view, it is wrapped with an
# ActionView::TemplateError. The lookup for the rescue_with_handler
# then fails to find the handle for the original exception. This solution
# special cases the template error to look also at the wrapped exception
# and if there is a handler for that exception, then call it and ignore
# the wrapping.
module RescueWithHelper
  def rescue_with_handler(exception)
    if ((exception.class == ActionView::TemplateError) &&
      (orig_exception = exception.original_exception) &&
      (orig_handler = handler_for_rescue(orig_exception)))
      exception = orig_exception
    end
    super(exception)
  end
end