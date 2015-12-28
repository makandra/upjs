##
# Installs a before_filter into all controllers which echoes the
# request's method as a cookie named `_up_request_method`.
#
# The Up.js requires this cookie to detect whether the initial page
# load was requested using a non-GET method. In this case the Up.js
# framework will prevent itself from booting until it was loaded
# from a GET request. For the terrible reasons behind this see:

# - <https://github.com/rails/turbolinks/search?q=request_method&ref=cmdform>
# - <https://github.com/rails/turbolinks/blob/83d4b3d2c52a681f07900c28adb28bc8da604733/README.md#initialization>
module Upjs
  module Rails
    module RequestMethod

      COOKIE_NAME = '_up_request_method'

      def self.included(base) # :nodoc:
        base.before_filter :set_up_request_method_cookie
      end

      private

      def set_up_request_method_cookie
        if request.get?
          cookies.delete(COOKIE_NAME)
        else
          cookies[COOKIE_NAME] = request.request_method
        end
      end

      ActionController::Base.send(:include, self)

    end
  end
end
