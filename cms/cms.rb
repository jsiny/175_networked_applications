require 'sinatra'
require "sinatra/reloader"
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret_cms'
end

before do
  @root = File.expand_path("..", __FILE__)
  @files = Dir.glob(@root + "/data/*").map { |file| File.basename(file) }
end

get "/" do
  erb :index
end

get "/:file" do
  @file = params[:file]

  if @files.include? @file
    headers["Content-Type"] = "text/plain"
    File.read("data/#{@file}")
  else
    session[:message] = "#{@file} does not exist."
    redirect "/"
  end
end
