require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
require 'yaml'
require 'bcrypt'

root = File.expand_path("..", __FILE__)

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

before do
  @files = Dir.glob(File.join(path('data'), '*')).map { |path| File.basename(path) }
end

before '/:file*' do
  @file = params[:file]
  @file_path = File.join(path('data'), @file)
end

def path(file)
  path = ENV['RACK_ENV'] == 'test' ? "../test/#{file}" : "../#{file}"
  File.expand_path(path, __FILE__)
end

def render_markdown(markdown_text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(markdown_text)
end

def load_file_content(file)
  content = File.read(file)

  case File.extname(file)
  when '.txt'
    headers["Content-Type"] = "text/plain"
    content
  when '.md'
    erb render_markdown(content)
  end
end

def error_message_for_incorrect_name(file)
  if file.empty?
    "A name is required."
  elsif File.extname(file).empty?
    "A file must have an extension (.txt or .md)"
  end
end

def signed_in?
  session.key?(:username)
end

def require_signed_in_user
  unless signed_in?
    session[:message] = "You must be signed in to do that."
    redirect '/'
  end
end

def load_user_credentials
  path = ENV['RACK_ENV'] == 'test' ? '../test/users.yml' : '../users.yml'
  credentials_path = File.expand_path(path, __FILE__)
  YAML.load_file(credentials_path)
end

def valid_credentials?(username, password)
  credentials = load_user_credentials

  credentials.key?(username) && \
  BCrypt::Password.new(credentials[username]) == params[:password]
end

def error_for_invalid_subscription(username, password)
  if signed_in?
    "You already have an account."
  elsif username.empty?
    "Your name must not be empty."
  elsif password.empty?
    "Your password must not be empty."
  end
end

def copy_filename(file)
  base_name = File.basename(file, '.*')
  extension = File.extname(file)
  base_name + '-copy' + extension
end

# Access list of files
get '/' do
  erb :index
end

# New document
get '/new' do
  require_signed_in_user
  erb :new
end

# Create new document
post '/create' do
  require_signed_in_user

  name = params[:name].to_s
  session[:message] = error_message_for_incorrect_name(name)

  if session[:message]
    status 422
    erb :new
  else
    File.write(File.join(path('data'), name), "")
    session[:message] = "#{name} was created."
    redirect '/'
  end
end

# Duplicate document
post '/:file/copy' do
  require_signed_in_user

  new_file = copy_filename(@file)
  content = File.read(@file_path)

  File.write(File.join(path('data'), new_file), content)
  session[:message] = "#{@file} was duplicated."
  redirect '/'
end

# Delete a document
post '/:file/destroy' do
  require_signed_in_user

  File.delete(@file_path)
  session[:message] = "#{@file} was deleted."
  redirect '/'
end

# View a specific file
get '/:file' do
  if @files.include?(@file)
    load_file_content(@file_path)
  else
    session[:message] = "#{@file} does not exist."
    status 404
  end
end

# Edit a file
get '/:file/edit' do
  require_signed_in_user
  @content = File.read(@file_path)
  erb :edit
end

# Save changes to a file
post '/:file' do
  require_signed_in_user
  File.write(@file_path, params[:content])

  session[:message] = "#{@file} has been updated."
  redirect '/'
end

# Form to log-in
get '/users/signin' do
  erb :signin, layout: :layout
end

# Sends credentials to log in
post '/users/signin' do
  username = params[:username]

  if valid_credentials?(username, params[:password])
    session[:username] = username
    session[:message]  = "Welcome!"
    redirect '/'
  else
    session[:message]  = "Invalid credentials"
    status 422
    erb :signin
  end
end

# Logs out a user
post '/users/signout' do
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect '/'
end

# Sign up form
get '/users/new' do
  erb :signup
end

# Create user account
post '/users/create' do
  yaml_file = path('users.yml')
  users = YAML::load_file(yaml_file)

  username = params[:username]
  password = params[:password]
  encrypted_password = BCrypt::Password.create(password)
  users[username] = encrypted_password

  session[:message] = error_for_invalid_subscription(username, password)

  unless session[:message]
    File.write(yaml_file, users.to_yaml)
    session[:username] = username
    session[:message] = "Welcome, #{username}!"
  end

  redirect '/'
end

# 404
not_found do
  redirect '/'
end