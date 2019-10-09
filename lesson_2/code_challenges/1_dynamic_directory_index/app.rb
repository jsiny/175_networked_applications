require 'sinatra'
require 'sinatra/reloader'

get '/' do
  @files = Dir.glob("./public/*").map { |file| File.basename(file) }.sort
  @files.reverse! if params[:sort] == 'desc'

  erb :files
end
