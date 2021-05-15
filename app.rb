require 'sinatra'
require 'byebug'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'
require 'fileutils'
require 'securerandom'

enable :sessions

include Model

# TO DO
# relationstabeller / genre 
# genre: behöver en gengre minst (db, NOTnil) ha knappar i movies som man kan välja mellan olika gengers använd movies/show 
# Yardoc
# helper funktioner vet ej vad jag ska använda dom till
#BUG: 
#


before do 

  if (session[:id] == nil) && (request.path_info != '/') && (request.path_info != '/login') && (request.path_info != '/showregister') && (request.path_info != '/users/new')
    
    redirect('/')
  end

end

before('/movies/:id/edit') do
  id = params[:id].to_i

  user_id_from_movie = get_userid_from_movie(id)
  p get_admin_info_from_user(session[:id])
  if user_id_from_movie[0][0].to_i != session[:id] && get_admin_info_from_user(session[:id])[0][0] != "true"
    session[:error] = "You don't have access to that content"
    redirect('/')
  end
end

before('/reviews/:id/edit') do
  id = params[:id].to_i

  user_id_from_review = get_userid_from_review(id)

  if user_id_from_review[0][0].to_i != session[:id] && get_admin_info_from_user(session[:id])[0][0] != "true"
    session[:error] = "You don't have access to that content"
    redirect('/')
  end
end

before('/users/:id/edit') do
  id = params[:id].to_i
  current_id = session[:id]
  
  if id != current_id && get_admin_info_from_user(session[:id])[0][0] != "true"
    session[:error] = "You don't have access to that content"
    redirect('/')
  end
end

before('/admin') do
  id = session[:id]
  if get_admin_info_from_user(id)[0][0] != "true"
    session[:error] = "You don't have access to that content"
    redirect('/')
  end
end

get('/') do
    slim(:"users/login")
end

get('/showregister') do
  slim(:register)

end


post('/login') do

  cooldown_minutes = 10
  max_recent_attemps = 3

  username = params[:username]
  password = params[:password]

  result = get_info_user(username)
  p result
  if result == nil
    session[:error] = "Incorrect username or password"
    redirect('/')
  end
  pwdigest = result["pwdigest"]
  id = result["Id"]
  
  
  attempts = get_attemps(id)


  recent_attemps = []

  attempts.each do |attempts|


    if (Time.now - Time.parse(attempts[0])) < cooldown_minutes*60
      recent_attemps << attempts
    end
  end



  if recent_attemps.length <= max_recent_attemps

    if password_check(pwdigest,password)
      session[:id] = id
      session[:error] = nil
      redirect("/movies")

    else
      session[:error] = "Incorrect username or password"
      time_allfail_user_login(id)
      redirect('/')
    end

  else
    session[:error] = "Incorrect username or password, try again later"
    redirect('/')
  end

end

get('/users') do

  userid = session[:id].to_i

  user_data = get_user_data(userid)
  movie_data = get_user_movie_data(userid)
  review_data = get_user_review_data(userid)
  
  
  #Hämtar data om filmerna som userna har gjort en review på
  reviewed_movie_data = []
  review_data.each do |rev|
    temp = rev["MovieId"]
    reviewed_movie_data << getreviewed_movie_data(temp, userid)

  end

  slim(:"users/index", locals:{info:user_data, movie:movie_data, review:review_data, movie_review:reviewed_movie_data})
end

post("/users/new") do 
  username = params[:username]
  password = params[:password]
  confirm_password = params[:confirm_password]
  admin = 0

  temp = id_from_user(username)
  
  if temp.empty?
    if (password == confirm_password)
      password_digest = create_user(username,password,admin)
      session[:error] = nil
      redirect("/")

    else
      session[:error] = "Passwords didn't match"
      redirect("/showregister")
    end
  
  else
    session[:error] = "Username already exist"
    redirect("/showregister")
  end
end

get("/movies") do
  userid = session[:id].to_i
  rating = medel_rating()
  result = get_movies_from_db()
  user_reviews = get_user_review_data(userid)
  slim(:"movies/index", locals:{movie:result,review:user_reviews})

end

get('/movies/new') do

  slim(:"movies/new")
end

post("/movie/new") do
  movie_name = params[:movie_name]
  user_id = session[:id]  
  desc = params[:description]
  org_filename = params[:file][:filename]
  file_ending = search_file_ending(org_filename)
  filename = SecureRandom.uuid + file_ending 
  save_path = File.join("./public/img/uploaded_pictures/", filename)
  dbpath = File.join("/img/uploaded_pictures/", filename)

  FileUtils.cp(params[:file][:tempfile], "./public/img/uploaded_pictures/#{filename}")
  add_movie(movie_name, desc, dbpath, user_id)
  redirect("/users")
end

get('/admin') do

  all_user_data = get_all_user_data()
  all_movie_data = get_movies_from_db()
  all_review_data = get_all_review_data()


  #Hämtar data om filmerna som userna har gjort en review på
  reviewed_movie_data = []
  all_review_data.each do |rev|
    temp = rev["MovieId"]
    reviewed_movie_data << get_all_reviewed_movie_data(temp)

  end 
  slim(:admin, locals:{info:all_user_data, movie:all_movie_data, movie_review:reviewed_movie_data})
end

post('/reviews') do
  title = params[:review_name]
  desc = params[:description]
  rating = params[:rating].to_i
  movieId = session[:movieId]
  user_id = session[:id] 
  time = Time.now.to_i
  create_review(title, desc, rating, movieId, user_id)
  redirect('/users')
end

post('/reviews/:id/delete') do
  id = params[:id].to_i
  delete_review(id)
  redirect('/users')
end

post('/movies/:id/delete') do
  id = params[:id].to_i
  delete_movie(id)
  redirect('/users')
end

post('/users/:id/delete') do
  id = params[:id].to_i
  delete_user(id)
  redirect('/')
end

get('/reviews/:id/new') do
  id = params[:id].to_i
  session[:movieId] = id
  result = specific_movie(id)
  slim(:"reviews/new",locals:{movie:result})
end

get('/movies/:id/edit') do
  id = params[:id].to_i
  result = specific_movie(id)
  slim(:"movies/edit",locals:{result:result})
end

get('/users/:id/edit') do
  id = params[:id].to_i
  result = user_and_desc(id)
  slim(:"users/edit",locals:{result:result})
end

get('/reviews/:id/edit') do
  id = params[:id].to_i
  result = review_movie(id)
  slim(:"reviews/edit",locals:{result:result})
end

post('/movies/:id/edit') do
  id = params[:id].to_i
  title = params[:titel]
  desc = params[:desc]
  update_movie(title,id,desc)
  redirect('/users')

end

post('/reviews/:id/edit') do
  id = params[:id].to_i
  titel = params[:titel]
  desc = params[:desc]
  rating = params[:rating]
  update_review(id,titel,desc,rating)
  redirect('/users')

end

post('/users/:id/edit') do
  id = params[:id].to_i
  username = params[:username]
  desc = params[:desc]
  update_user(id,username,desc)
  redirect('/users')

end

