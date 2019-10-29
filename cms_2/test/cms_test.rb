ENV["RACK_ENV"] = "test"

require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use!
require 'rack/test'
require_relative '../cms'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get '/'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    %w(about.md changes.txt history.txt).each do |file|
      assert_includes last_response.body, file
    end
  end

  def test_access_history
    get '/history.txt'
    assert_equal 200, last_response.status
    assert_equal 'text/plain', last_response["Content-Type"]
    assert_includes last_response.body, "Color Me Barbra"
  end

  def test_not_found
    get '/invalid.txt'
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "invalid.txt does not exist."
 
    get '/'
    refute_includes last_response.body, 'invalid.txt does not exist.'
  end

  def test_viewing_markdown_document
    get '/about.md'

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<strong>Barbara Joan"
  end
end