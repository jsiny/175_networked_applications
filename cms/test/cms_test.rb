ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use!
require "rack/test"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.md"
    assert_includes last_response.body, "history.md" 
  end

  # def test_viewing_text_document
  #   get "/changes.txt"
  #   assert_equal 200, last_response.status
  #   assert_equal "text/plain", last_response["Content-Type"]
  #   assert_includes last_response.body, "Africa, the world's wildest continent."
  # end

  def test_document_not_found
    get "/notafile.txt"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "notafile.txt does not exist"

    get "/"
    refute_includes last_response.body, "notafile.txt does not exist"
  end

  def test_viewing_markdown_document
    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>David Attenborough</h1>"
  end
end
