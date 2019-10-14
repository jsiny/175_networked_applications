ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use!
require "rack/test"
require "fileutils"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)

    create_document("about.md", "# David Attenborough")
    create_document("changes.txt", "Africa, the world's wildest continent.")
    create_document("history.md")
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def test_index
    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.md" 
  end

  def test_viewing_text_document
    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "Africa, the world's wildest continent."
  end

  def test_document_not_found
    get "/notafile.txt"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "notafile.txt does not exist"
    assert_includes last_response.body, %q(class="message")

    get "/"
    refute_includes last_response.body, "notafile.txt does not exist"
  end

  def test_viewing_markdown_document
    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>David Attenborough</h1>"
  end

  def test_editing_document
    get "/changes.txt/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea "
    assert_includes last_response.body, "<button type=\"submit\">"
  end

  def test_updating_document
    post "/changes.txt", content: "new content"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "changes.txt has been updated."

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end
end
