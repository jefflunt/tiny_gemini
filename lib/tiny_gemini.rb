require 'net/http'
require 'json'

# tiny, not very robust, HTTP client the Google Gemini API
# see also: https://ai.google.dev/api/rest
class TinyGemini
  # a good rule of thumb would be to have a .tiny_gemini.yml config in your
  # project, to parse that as YAML, and pass the parsed reulst into here.
  def initialize(
    model: 'gemini-1.5-flash',
    host: 'generativelanguage.googleapis.com',
    path: '/v1beta/models',
    action: 'generateContent',
    api_key: ENV['GEMINI_KEY'],
    system_instruction: nil
  )

    @model = model
    @host = host
    @path = path
    @action = action
    @api_key = api_key
    @system_instruction = system_instruction
  end

  # sends a request to POST generateContent
  #
  # messages: an array of hashes in the following format:
  # [
  #     {
  #         "parts": [
  #             {
  #                 "text": "hi, how are you?"
  #             }
  #         ],
  #         "role": "user"
  #     },
  #     {
  #         "parts": [
  #             {
  #                 "text": "I am an AI language model, so I don't have feelings or experiences like humans do. However, I am here to assist you with any questions or tasks you may have! How can I help you today??"
  #             }
  #         ],
  #         "role": "model"
  #     },
  #     {
  #         "parts": [
  #             {
  #                 "text": "oh, you don't have feelings? I guess I didn't realize that - you seem so ... real!"
  #             }
  #         ],
  #         "role": "user"
  #     },
  # ]
  #
  # NOTE: if you want the model to impersonate a character (i.e. a talking cat)
  # you need to have set the `system_instruction` parameter when initializing
  # this class to make that work
  def chat(messages)
    body = { contents: messages }
    body.merge!(system_instruction: { parts: { text: @system_instruction } }) if @system_instruction
    request_body = body.to_json

    uri = URI("https://#{@host}#{@path}/#{@model}:#{@action}?key=#{@api_key}")
    headers = { 'Content-Type' => 'application/json; charset=UTF-8' }
    response = Net::HTTP.post(uri, request_body, headers)

    # Handle potential errors (e.g., non-200 responses)
    unless response.is_a?(Net::HTTPSuccess)
      raise TinyGeminiModelError, "Gemini API Error: #{response.code}\n#{JSON.pretty_generate(response.body)}"
    end

    JSON.parse(response.body)['candidates'].first.dig('content', 'parts').first['text']
  end
end

class TinyGeminiModelError < StandardError; end
