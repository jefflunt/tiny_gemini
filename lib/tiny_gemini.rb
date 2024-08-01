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
    api_key: ENV['TINY_GEMINI_KEY'],
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
  def prompt(messages)
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

    # response and error handling
    parsed_response = JSON.parse(response.body)
    raise(TinyGeminiModelError, "No condidates in Gemini response") unless parsed_response['candidates']

    first_candidate_response = parsed_response['candidates'].first
    raise(TinyGeminiModelError, "No first candidate response in Gemini response") unless first_candidate_response

    text_response = first_candidate_response&.dig('content', 'parts')&.first&.dig('text')&.strip
    raise(TinyGeminiModelError, "Text response is nil or empty: `#{text_response.inspect}`") if text_response.nil? || text_response.length == 0

    text_response
  end
end

class TinyGeminiModelError < StandardError; end
