ENV["RACK_ENV"] = "test"

require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use!
require 'rack/test'
require 'fileutils'
require_relative '../cms'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
    create_document("about.md", "<strong>Barbara Joan")
    create_document "changes.txt"
    create_document("history.txt", "Color Me Barbra")
  end

  def create_document(name, content = '')
    File.open(File.join(data_path, name), 'w') do |file|
      file.write(content)
    end
  end

  def test_index
    get '/'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    %w(about.md changes.txt history.txt).each do |file|
      assert_includes last_response.body, file
    end
    assert_includes last_response.body, "Edit</a>"
    assert_includes last_response.body, "New Document</a>"
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

  def test_access_edit_page
    get '/changes.txt/edit'

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_update_content
    post 'changes.txt', content: "new content"
    assert_equal 302, last_response.status
    
    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "changes.txt has been updated."

    get '/changes.txt'
    assert_includes last_response.body, "new content"
  end

  def test_new_document_page
    get '/new'

    assert_equal 200, last_response.status
    assert_includes last_response.body, "Add a new document:"
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_create_new_document
    post '/new', name: 'new_file.txt'
    assert_equal 302, last_response.status

    get last_response['Location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new_file.txt was created."

    get '/'
    assert_includes last_response.body, "new_file.txt"
  end

  def test_attempt_to_create_empty_document
    post '/new', name: ''
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A name is required"
  end

  def test_attempt_to_create_document_without_extension
    post '/new', name: 'file'
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A file must have an extension"
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end
end