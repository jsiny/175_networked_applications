require "sinatra"
require "sinatra/reloader"

configure do
  enable :sessions
end

helpers do 
  def get_all_animals
    %w(Giraffe Elephant Lion)
  end
end

get "/" do
  redirect "/index.html"
end

get "/index.html" do
  "Hello World"
end

get "/animals" do
  @animals = get_all_animals
  # location 1
  erb :animals, layout: :layout
end

post "/animals" do
  # validation happens here and sets "error" if there are problems
  if error
    # location 2
    session[:error] = error
    erb :animals, layout: :layout
  else
    animal = { id: params[:id], type: params[:type], name: params["name"] }
    add_to_animals(animal)
    # location 3
    redirect "/animals"
  end
  # location 4
end