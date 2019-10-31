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
    FileUtils.mkdir_p(path('data'))

    create_document("about.md", "<strong>Barbara Joan")
    create_document "changes.txt"
    create_document("history.txt", "Color Me Barbra")

    create_users_yaml
  end

  def create_document(name, content = '')
    File.open(File.join(path('data'), name), 'w') do |file|
      file.write(content)
    end
  end

  def create_users_yaml
    users = { "admin" => "$2a$12$RlM1PDStokQMrciKxb1l0.C/1Uf/xRTirQ0kpiIq5S0erW0yTSiHm" }

    File.open(path('users.yml'), 'w') do |file|
      file.write(users.to_yaml)
    end
  end

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => { username: 'admin' } }
  end

  def test_index
    get '/'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    %w(about.md changes.txt history.txt).each do |file|
      assert_includes last_response.body, file
      assert_includes last_response.body, "<a href=\"/#{file}/edit\">"
      assert_includes last_response.body, "action='/#{file}/destroy'"
      assert_includes last_response.body, "action='/#{file}/copy'"
    end
    assert_includes last_response.body, "New Document</a>"
    assert_includes last_response.body, "Sign In"
    assert_includes last_response.body, "Sign Up"
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
    assert_equal "invalid.txt does not exist.", session[:message]
  end

  def test_viewing_markdown_document
    get '/about.md'

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<strong>Barbara Joan"
  end

  def test_access_edit_page_signed_in
    get '/changes.txt/edit', {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_access_edit_page_signed_out
    get '/changes.txt/edit'
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_update_content_signed_in
    post 'changes.txt', { content: "new content" }, admin_session
    assert_equal 302, last_response.status
    assert_equal "changes.txt has been updated.", session[:message]
    
    get '/changes.txt'
    assert_includes last_response.body, "new content"
  end

  def test_update_content_signed_out
    post 'changes.txt', content: "new content"
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_new_document_page_signed_in
    get '/new', {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "Add a new document:"
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_new_document_page_signed_out
    get '/new'
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_create_new_document_signed_in
    post '/create', { name: 'new_file.txt' }, admin_session
    assert_equal 302, last_response.status
    assert_equal "new_file.txt was created.", session[:message]

    get '/'
    assert_includes last_response.body, "new_file.txt</a>"
  end

  def test_create_new_document_signed_out
    post '/create', { name: 'new_file.txt' }
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_attempt_to_create_empty_document
    post '/create', { name: '' }, admin_session
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A name is required"
  end

  def test_attempt_to_create_document_without_extension
    post '/create', { name: 'file' }, admin_session
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A file must have an extension"
  end

  def test_delete_document_signed_in
    post '/changes.txt/destroy', {}, admin_session
    assert_equal 302, last_response.status
    assert_equal "changes.txt was deleted.", session[:message]

    get '/'
    refute_includes last_response.body, "changes.txt</a>"
  end

  def test_delete_document_signed_out
    post '/changes.txt/destroy'
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_signin_form
    get '/users/signin'

    assert_equal 200, last_response.status
    assert_includes last_response.body, "Username:"
    assert_includes last_response.body, "<input type='password'"
    assert_includes last_response.body, %q(<button type="submit">Sign In)
  end

  def test_signing_in
    post '/users/signin', username: 'admin', password: 'secret'
    assert_equal 302, last_response.status
    assert_equal "Welcome!", session[:message]
    assert_equal "admin", session[:username]
    
    get last_response["Location"]
    assert_includes last_response.body, "Signed in as admin"
    assert_includes last_response.body, "Sign Out"
    refute_includes last_response.body, "Sign In"
  end

  def test_signing_in_with_invalid_credentials
    post '/users/signin', username: 'invalid_username', password: 'foobar'

    assert_equal 422, last_response.status
    assert_nil session[:username]
    assert_includes last_response.body, "Invalid credentials"
    assert_includes last_response.body, "invalid_username"
  end

  def test_signout
    get '/', {}, admin_session
    
    post '/users/signout'
    assert_equal 302, last_response.status
    assert_nil session[:username]
    
    get last_response['Location']
    assert_includes last_response.body, "You have been signed out."
    assert_includes last_response.body, "Sign In"
    assert_includes last_response.body, "Sign Up"
    refute_includes last_response.body, "Sign Out"    
  end

  def test_duplicating_document_signed_in
    post '/changes.txt/copy', {}, admin_session
    assert_equal 302, last_response.status
    assert_equal "changes.txt was duplicated.", session[:message]

    get '/'
    assert_includes last_response.body, "changes-copy.txt"
  end

  def test_duplicating_document_signed_out
    post '/changes.txt/copy'
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_access_signup_form
    get '/users/new'
    assert_equal 200, last_response.status
    assert_includes last_response.body, "action=\"/users/create\">"
    assert_includes last_response.body, "Create account</button>"
  end

  def test_create_user_account
    post 'users/signin', { username: 'test', password: 'secret' }
    assert_nil session[:username]

    post 'users/create', { username: 'test', password: 'secret' }
    assert_equal 302, last_response.status
    assert_equal "test", session[:username]
    assert_equal "Welcome, test!", session[:message]
  end

  def teardown
    FileUtils.rm_rf(path('data'))
    FileUtils.rm(path('users.yml'))
  end
end