require 'sinatra'
require "sinatra/reloader"
require 'tilt/erubis'
require "redcarpet"

configure do
  enable :sessions
  set :session_secret, 'secret_cms'
end

before do
  @root = File.expand_path("..", __FILE__)
  @files = Dir.glob(@root + "/data/*").map { |file| File.basename(file) }
end

before "/:file*" do
  @file = params[:file]
  @file_path = "data/#{@file}"
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
    render_markdown(content)
  end
end

get "/" do
  erb :index
end

get "/:file" do
  if @files.include? @file
    load_file_content(@file_path)
  else
    session[:message] = "#{@file} does not exist."
    redirect "/"
  end
end

get "/:file/edit" do
  @content = File.read(@file_path)

  erb :edit_file
end

post "/:file" do
  File.write(@file_path, params[:content])

  session[:message] = "#{@file} has been updated."
  redirect "/"
end
