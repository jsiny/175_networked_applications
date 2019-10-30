require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
require 'yaml'

root = File.expand_path("..", __FILE__)

def data_path
  path = ENV['RACK_ENV'] == 'test' ? '../test/data/' : '../data/'
  File.expand_path(path, __FILE__)
end

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

before do
  @files = Dir.glob(File.join(data_path, '*')).map { |path| File.basename(path) }
end

before '/:file*' do
  @file = params[:file]
  @file_path = File.join(data_path, @file)
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
    File.write(File.join(data_path, name), "")
    session[:message] = "#{name} was created."
    redirect '/'
  end
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
  credentials = load_user_credentials
  username = params[:username]

  if credentials.key?(username) && credentials[username] == params[:password]
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

# 404
not_found do
  redirect '/'
end