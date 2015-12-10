module Lita
  module Handlers
    class BingImage < Handler
      URL = "https://api.datamarket.azure.com/Bing/Search/Image"

      route(/(?:image|img)(?:\s+me)? (.+)/i, :fetch, command: true, help: {
        "image QUERY" => "Find images from Bing."
      })

      def self.connection
        return @@connection if @@connection
        connection = Faraday::Connection.new
        connection.basic_auth(ENV["MS_ACCOUNT_KEY"], ENV["MS_ACCOUNT_KEY"])
        @@connection = connection
      end

      def fetch(response)
        query = response.matches[0][0]

        http_response = self.connection.get(
          URL,
          "Query" => "'#{query}'",
          "Adult" => "'#{safe_value}'",
          "$format" => "json"
        )

        if http_response.status == 200
          data = MultiJson.load(http_response.body)
          choice = data["d"]["results"].sample
          response.reply "#{choice["MediaUrl"]}"
        else
          Lita.logger.warn(
            "Couldn't get image, returned with status: #{http_response.status}"
          )
        end
      end

      private

      def safe_value
        safe = Lita.config.handlers.bing_image.safe_search.to_s.downcase
        safe = "moderate" unless ["strict", "moderate", "off"].include?(safe)
        safe
      end
    end

    Lita.register_handler(self)
  end
end
