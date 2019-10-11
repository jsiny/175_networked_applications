require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  session[:lists] ||= []
  @lists = session[:lists]
end

before "/lists/:list_id*" do
  @list_id = params[:list_id].to_i
  @list    = load_list(@list_id)
  @todos   = @list[:todos]
end

before "/lists/:list_id/todos/:todo_id*" do
  @list_id = params[:list_id].to_i
  @list    = load_list(@list_id)
  @todos   = @list[:todos]
  @todo_id = params[:todo_id].to_i
  @todo    = @todos[@todo_id]
end

helpers do
  def list_complete?(list)
    todos_count(list) > 0 && todos_remaining_count(list).zero?
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def todos_count(list)
    list[:todos].size
  end

  def todos_remaining_count(list)
    list[:todos].reject { |todo| todo[:completed] }.size
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each   { |list| yield list, lists.index(list) }
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each   { |todo| yield todo, todos.index(todo) }
  end
end

def load_list(index)
  return @lists[@list_id] if @lists[@list_id]

  session[:error] = "The specified list was not found"
  redirect "/lists"
end

get "/" do
  redirect "/lists"
end

# View list of lists
get "/lists" do
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif @lists.any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :new_list
  else
    @lists << { name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

get "/lists/:id" do
  erb :list
end

# Edit an existing todo list
get "/lists/:id/edit" do
  erb :edit_list
end

# Update an existing todo list
post "/lists/:id" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :edit_list
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{@list_id}"
  end
end

# Delete an existing todo list
post "/lists/:id/destroy" do
  @lists.delete_at(@list_id)
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

# Add a new todo to a list
post "/lists/:list_id/todos" do
  text = params[:todo].strip
  error = error_for_todo(text)

  if error
    session[:error] = error
    erb :list
  else  
    @todos << { name: text, completed: false }
    session[:success] = "The to-do was added."
    redirect "/lists/#{@list_id}"
  end
end

# Return an error message if the todo is invalid. Return nil if name is valid.
def error_for_todo(name)
  if !(1..100).cover? name.size
    "To-do must be between 1 and 100 characters."
  end
end

# Delete a todo from a list
post "/lists/:list_id/todos/:id/destroy" do
  @todos.delete_at @todo_id

  session[:success] = "The to-do has been deleted."
  redirect "/lists/#{@list_id}"
end

# Update the status of a todo
post "/lists/:list_id/todos/:id" do
  is_completed = params[:completed] == "true"

  @todo[:completed] = is_completed
  session[:success] = "The to-do has been updated."
  redirect "/lists/#{@list_id}"
end

# Mark all todos as complete for a list
post "/lists/:id/complete_all" do
  @todos.each do |todo|
    todo[:completed] = true
  end

  session[:success] = "All the to-dos have been completed."
  redirect "/lists/#{@list_id}"
end