module Lita
  module Handlers
    class BingImage < Handler
      attr_accessor :connection

      URL = "https://api.datamarket.azure.com/Bing/Search/Image"

      route(/(?:image|img)(?:\s+me)? (.+)/i, :fetch_image, command: true, help: {
        "image QUERY" => "Find images from Bing."
      })

      route(/(?:animate|gif|anim)(?:\s+me)? (.+)/i, :fetch_gif, command: true, help: {
        "animate QUERY" => "Try to find gif form Bing"
      })

      def connection
        return @connection if @connection
        connection = Faraday::Connection.new
        connection.basic_auth(ENV["MS_ACCOUNT_KEY"], ENV["MS_ACCOUNT_KEY"])
        @connection = connection
      end

      def fetch_image(response)
        query = response.matches[0][0]

        http_response = connection.get(
          URL,
          "Query" => "'#{query}'",
          "Adult" => "'moderate'",
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

      def fetch_gif(response)
        query = response.matches[0][0]

        http_response = connection.get(
          URL,
          "Query" => "'#{query} gif'",
          "Adult" => "'moderate'",
          "$format" => "json"
        )

        if http_response.status == 200
          data = MultiJson.load(http_response.body)
          all_results = data["d"]["results"]
          gif_results = data["d"]["results"].select{|r| ["image/animatedgif", "image/gif"].include?(r["ContentType"])}

          choice = if (gif_results.length > 0) 
            gif_results.sample
          else
            all_results.sample
          end
          response.reply "#{choice["MediaUrl"]}"
        else
          Lita.logger.warn(
            "Couldn't get gif, returned with status: #{http_response.status}"
          )
        end
      end
    end

    Lita.register_handler(BingImage)
  end
end
