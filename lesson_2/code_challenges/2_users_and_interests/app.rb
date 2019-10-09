require 'sinatra'
require 'sinatra/reloader'
require 'yaml'

before do
  @users = YAML.load_file('users.yaml')
end

helpers do
  def count_interests
    @users.reduce(0) do |sum, (user, info)|
      sum + info[:interests].size
    end
  end
end

get '/users' do
  @title = "Users"

  erb :users
end

get '/' do
  redirect '/users'
end

get "/:user" do
  @user_name = params[:user].to_sym
  @email = @users[@user_name][:email]
  @interests = @users[@user_name][:interests]
  @title = "User - #{@user_name.capitalize}"

  erb :user
end