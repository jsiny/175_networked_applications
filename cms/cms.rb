require 'sinatra'
require "sinatra/reloader"
require 'tilt/erubis'
require "redcarpet"
require "yaml"
require "bcrypt"

configure do
  enable :sessions
  set :session_secret, 'secret_cms'
end

before do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map { |file| File.basename(file) }
end

before "/:file*" do
  @file = params[:file]
  @file_path = File.join(data_path, @file)
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)

  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    erb render_markdown(content)
  end
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/users.yml", __FILE__)
  else
    File.expand_path("../users.yml", __FILE__)
  end

  YAML.load_file(credentials_path)
end

def valid_credentials?(username, password)
  credentials = load_user_credentials
  
  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password
  else
    false
  end
end

def data_path
  if ENV["RACK_ENV"] == 'test'
    File.expand_path('../test/data', __FILE__)
  else
    File.expand_path('../data', __FILE__)
  end
end

def error_for_invalid_filename(name)
  return "A name is required." if name.size.zero?

  split = name.split(".")
  if split.size != 2 || !split.last =~ /(txt|md)/
    return "The file name must end with .txt or .md"
  end
end

def signed_in_user?
  session.key?(:username)
end

def require_signed_in_user
  unless signed_in_user?
    session[:message] = "You must be signed in to do that."
    redirect "/"
  end
end

# Access the index
get "/" do
  erb :index
end

# Create new document
get "/new" do
  require_signed_in_user
  erb :new
end

# Save this new document
post "/create" do
  require_signed_in_user

  @filename = params[:filename].to_s
  session[:message] = error_for_invalid_filename(@filename)

  if session[:message]
    status 422
    erb :new
  else 
    FileUtils.touch(File.join(data_path, @filename))
    session[:message] = "#{@filename} was created."
    redirect "/"
  end
end

# Delete a document
post "/:file/destroy" do
  require_signed_in_user

  File.delete(@file_path)

  session[:message] = "#{@file} was deleted"
  redirect "/"
end

# Login page
get "/users/signin" do
  erb :signin
end

# Login
post "/users/signin" do
  username = params[:username]

  if valid_credentials?(username, params[:password])
    session[:username] = username
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid credentials"
    status 422
    erb :signin
  end
end

# Logout
post "/users/signout" do
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect "/"
end

# View a specific file
get "/:file" do
  if @files.include? @file
    load_file_content(@file_path)
  else
    session[:message] = "#{@file} does not exist."
    redirect "/"
  end
end

# Edit a file (form)
get "/:file/edit" do
  require_signed_in_user

  @content = File.read(@file_path)

  erb :edit
end

# Edit a file (submit)
post "/:file" do
  require_signed_in_user

  File.write(@file_path, params[:content])

  session[:message] = "#{@file} has been updated."
  redirect "/"
end
