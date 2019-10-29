require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

root = File.expand_path("..", __FILE__)
data = root + '/data/'

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

before do
  @files = Dir.glob(data + '*').map { |path| File.basename(path) }
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
    render_markdown(content)
  end
end

get '/' do
  erb :index
end

get '/:file' do
  file = params[:file]
  if @files.include?(file)
    load_file_content(data + file)
  else
    session['message'] = "#{file} does not exist."
    status = 404
  end
end

not_found do
  redirect '/'
end