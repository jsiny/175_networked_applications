require 'sinatra'
require "sinatra/reloader"
require 'tilt/erubis'

get "/" do
  @files = Dir.glob("data/*").map { |file| File.basename(file) }
  erb :index
end

get "/:file" do
  @file = params[:file]
  headers["Content-Type"] = "text/plain"
  File.readlines("data/#{@file}", "\n\n")
end
