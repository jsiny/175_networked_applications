require 'sinatra'
require "sinatra/reloader"
require 'tilt/erubis'
require "redcarpet"

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

def data_path
  if ENV["RACK_ENV"] == 'test'
    File.expand_path('../test/data', __FILE__)
  else
    File.expand_path('../data', __FILE__)
  end
end

# Access the index
get "/" do
  erb :index
end

# Create new doc
get "/new" do
  erb :new
end

post "/create" do
  @filename = params[:filename]

  if @filename.empty?
    session[:message] = "A name is required."
    status 422
    erb :new
  else
    FileUtils.touch(File.join(data_path, @filename))
    session[:message] = "#{@filename} was created."
    redirect "/"
  end
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
  @content = File.read(@file_path)

  erb :edit
end

# Edit a file (submit)
post "/:file" do
  File.write(@file_path, params[:content])

  session[:message] = "#{@file} has been updated."
  redirect "/"
end
