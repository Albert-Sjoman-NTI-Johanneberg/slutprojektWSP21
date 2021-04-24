require 'sinatra'
require 'byebug'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'
require 'fileutils'
require 'securerandom'

enable :sessions

get('/') do
    slim(:"users/login")
end

get('/showregister') do
  slim(:register)

end

get('/users') do
  Userid = session[:id].to_i
  user_data = get_user_data(Userid)
  movie_data = get_user_movie_data(Userid)
  review_data = get_user_review_data(Userid)

  slim(:"users/index", locals:{info:user_data, movie:movie_data, review:review_data})
  #När du hämtar movie data ta med titel m.m från filmen som reviewades
end


get('/movies/new') do

  slim(:"movies/new")
end

get('/reviews/new') do

  slim(:"reviews/new")
end


post("/movie/new") do
  movie_name = params[:movie_name]
  user_id = session[:id]  
  description = params[:description]
  original_filename = params[:file][:filename]
  file_ending = search_file_ending(original_filename)
  filename = SecureRandom.uuid + file_ending 
  save_path = File.join("./public/img/uploaded_pictures/", filename)
  db_path = File.join("/img/uploaded_pictures/", filename)

  FileUtils.cp(params[:file][:tempfile], "./public/img/uploaded_pictures/#{filename}")
  add_movie(movie_name, description, db_path, user_id)
  redirect("/users")
end