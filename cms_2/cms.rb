require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

root = File.expand_path("..", __FILE__)
data_path = root + '/data/'

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

before do
  @files = Dir.glob(data_path + '*').map { |path| File.basename(path) }
end

before '/:file*' do
  @file = params[:file]
  @file_path = data_path + @file
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

# Access list of files
get '/' do
  erb :index
end

# View a specific file
get '/:file' do
  if @files.include?(@file)
    load_file_content(@file_path)
  else
    session['message'] = "#{@file} does not exist."
    status = 404
  end
end

# Edit a file
get '/:file/edit' do
  @content = File.read(@file_path)
  erb :edit
end

# Save changes to a file
post '/:file' do
  File.write(@file_path, params[:content])

  session['message'] = "#{@file} has been updated."
  redirect '/'
end

# 404
not_found do
  redirect '/'
end