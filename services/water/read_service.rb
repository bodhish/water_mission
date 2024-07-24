module Water
  class ReadService
    def initialize(url)
      @url = url
      @result = nil
    end

    def execute
      find_reading(@url)
      @result
    end

    def find_reading(url)
      # More detailed prompt
      prompt = <<-PROMPT
      Given an image of a water meter find the reading.
      If the meter is unclear or obscured, describe the issue preventing an accurate reading.
      PROMPT

      messages = [
        { "type": "text", "text": prompt },
        {
          "type": "image_url",
          "image_url": {
            "url": url,
          }
        }
      ]

      response =
        client.chat(
          parameters: {
            model: "gpt-4o",
            messages: [{ role: "user", content: messages}],
            tools: [meter_reading_function],
            tool_choice: tool_choice
          }
        )

      message = response.dig("choices", 0, "message")

      if message["role"] == "assistant" && message["tool_calls"]
        message["tool_calls"].each do |tool_call|
          tool_name = tool_call.dig("function", "name")
          args =
            JSON.parse(
              tool_call.dig("function", "arguments"),
              symbolize_names: true
            )

          case tool_name
          when "meter_reading"
            store_meter_reading(**args)
          else
            raise "Unknown tool_name: #{tool_name}, Response from OpenAI: #{response}"
          end
        end
      else
        raise "Tool Call Failed: Response from OpenAI: #{response}"
      end
    end

    def tool_choice
      {
        type: "function",
        function: {name: "meter_reading"}
      }
    end

    def store_meter_reading(value:, units:, notes:)
      # Store the meter reading in the database
      puts "Meter Reading: #{value} #{units}"
      puts "Notes: #{notes}"
      @result = {
        value: value,
        units: units,
        notes: notes
      }
    end

    def meter_reading_function
      {
        type: "function",
        function: {
          name: "meter_reading",
          description: "Create the water meter reading given an image of the water meter",
          parameters: {
            type: :object,
            properties: {
              value: {
                type: :string,
                description:
                  "The reading of the water meter, if the meter is unclear or obscured, return nil"
              },
              units: {
                type: :string,
                description: "The units of the water meter reading"
              },
              notes: {
                type: :string,
                description: "Any notes about the water meter reading"
              },
            },
            required: ["reading", "units", "notes"],
          }
        }
      }
    end

    def client
      @client ||= OpenAI::Client.new(
        access_token: Rails.application.credentials.dig(:open_ai, :access_token),
        organization_id: Rails.application.credentials.dig(:open_ai, :organization_id)
      )
    end
  end
end
