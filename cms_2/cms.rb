require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

root = File.expand_path("..", __FILE__)
data = root + '/data/'

get '/' do
  @files = Dir.glob(data + '*').map { |path| File.basename(path) }
  erb :index
end

get '/:file' do
  file = params[:file]
  headers["Content-Type"] = "text/plain"
  File.read(data + file)
end