require 'sinatra'

get '/' do
  erb :index
end

get '/advice' do
  "An apple a day keeps the doctor away!"
end

get '/time' do
  time = "Current time is: <%= Time.now %>"
  erb time
end

get '/hello/:name' do
  "Hello #{params['name']}"
end

get '/resume/:name' do |n|
  "#{n}'s Resume"
end

get '/posts' do
  title = params['title']
  author = params['author']
  "#{author} wrote #{title}"
end

get '/old' do
  redirect to('/')
end

not_found do
  'This is nowhere to be found'
end
