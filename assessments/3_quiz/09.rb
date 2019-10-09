require 'sinatra'
require 'sinatra/reloader'

get "/" do
  @words = ["blubber", "beluga", "galoshes", "mukluk", "narwhal"]
  erb :index
end

get "/course/:course/instructor/:instructor" do |course, instructor|
  @course_id = params['course']
  @instructor_id = params['instructor']
  erb :course_roster
end
