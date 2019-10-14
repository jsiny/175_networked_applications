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
  @file = params[:file]

  if @files.include? @file
    load_file_content("data/#{@file}")
    # headers["Content-Type"] = "text/plain"
    # File.read("data/#{@file}")
  else
    session[:message] = "#{@file} does not exist."
    redirect "/"
  end
end
