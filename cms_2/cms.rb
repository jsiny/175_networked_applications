require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

root = File.expand_path("..", __FILE__)
data = root + '/data/'

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

before do
  @files = Dir.glob(data + '*').map { |path| File.basename(path) }
end

get '/' do
  erb :index
end

get '/:file' do
  file = params[:file]
  if @files.include?(file)
    headers["Content-Type"] = "text/plain"
    File.read(data + file)
  else
    session['message'] = "#{file} does not exist."
    status = 404
  end
end

not_found do
  redirect '/'
end