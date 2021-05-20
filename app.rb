require 'sinatra'
require 'byebug'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'
require 'fileutils'
require 'securerandom'

enable :sessions

# inport model
include Model

# Helper funktioner, display all movies and genres from those movies
#
# @see model#db_conect
helpers do

  def movies_from_db
    db = db_conect("db/imdb.db")
      
    result = db.execute("SELECT * FROM movie")

    return result
  end

  def genre_to_movies(movieid)
    db = db_conect("db/imdb.db")
    movie_genre = db.execute('SELECT 
      movie.Titel, genre.Name
    FROM((movie_genre_rel
      INNER JOIN movie ON movie_genre_rel.movie_id = movie.Id)
      INNER JOIN genre ON movie_genre_rel.genre_id = genre.Id)
    WHERE movie_id = ?',movieid)
    genres = []
    movie_genre.each do |genre|
      genres << genre[1]

    end
    genres = genres.join(", ")

    if genres == ""
      genres = "None"
    end

    return genres
  end
end

# Before every route check if session[:id] != nil  

before do 

  if (session[:id] == nil) && (request.path_info != '/') && (request.path_info != '/login') && (request.path_info != '/showregister') && (request.path_info != '/users/new')
    
    redirect('/')
  end

end

# Before display edit movies check if you own movie or you are admin
#
# @see model#get_userid_from_movie
# @see model#get_admin_info_from_user
#
# @param[integer] id, Movie id

before('/movies/:id/edit') do
  id = params[:id].to_i

  user_id_from_movie = get_userid_from_movie(id)
  if user_id_from_movie[0][0].to_i != session[:id] && get_admin_info_from_user(session[:id])[0][0] != "true"
    session[:error] = "You don't have access to that content"
    redirect('/')
  end
end

# Before display edit review check if you own review or you are admin
#
# @see model#get_userid_from_review
# @see model#get_admin_info_from_user
#
# @param [integer] id, Review id
before('/reviews/:id/edit') do
  id = params[:id].to_i

  user_id_from_review = get_userid_from_review(id)

  if user_id_from_review[0][0].to_i != session[:id] && get_admin_info_from_user(session[:id])[0][0] != "true"
    session[:error] = "You don't have access to that content"
    redirect('/')
  end
end

# before display edit user check if you are user or you are admin
#
# @see model#get_admin_ifno_from_user
#
# @param [integer] id, User id

before('/users/:id/edit') do
  id = params[:id].to_i
  current_id = session[:id]
  
  if id != current_id && get_admin_info_from_user(session[:id])[0][0] != "true"
    session[:error] = "You don't have access to that content"
    redirect('/')
  end
end

# before display admin panel check if user is admin
#
# @see model#get_admin_info_from_user
#
# @param [Integer] id, User id 

before('/admin') do
  id = session[:id]
  if get_admin_info_from_user(id)[0][0] != "true"
    session[:error] = "You don't have access to that content"
    redirect('/')
  end
end

# Display login form

get('/') do
    slim(:"users/login")
end

# Display register form

get('/showregister') do
  slim(:register)

end

# Attemps login and updates session
#
# @see model#get_info_user
# @see model#calculate_recent_attemps
# @see model#password_check
# @see model#time_allfail_user_login
# @see model#cooldown_timer
#
# @param [String] username, Inputed username
# @param [String] password, Inputed password
# @param [String] pwdigest, Inputed repeted password
# @param [Integer] cooldown_minutes, cooldown minutes

post('/login') do

  cooldown_minutes = 5
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
  

  recent_attemps = calculate_recent_attemps(id, cooldown_minutes)


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
    cooldown_timer = cooldown_timer(id, cooldown_minutes)
    session[:error] = "Inputed to many incorrect username or password, try again in #{cooldown_timer.round(1)} minutes"
    redirect('/')
  end

end

# Display user page
#
# @see model#get_user_data
# @see model#get_user_movie_data
# @see model#get_user_review_data
# @see model#getreviewed_movie_data
#
# @param [Integer] userid, User id
# @param [Integer] temp, Movie id

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

# Creates a new user 
#
# @see model#id_from_user
# @see model#create_user
#
# @param [String] username, Username
# @param [String] password, Password
# @param [String] confirm_password, repeted password
# @param [String] admin, admin rights

post("/users/new") do 
  username = params[:username]
  password = params[:password]
  confirm_password = params[:confirm_password]
  admin = "false"

  #validering att det finns input
  if username != "" && password != ""

    temp = id_from_user(username)
    
    if temp.empty?
      if (password == confirm_password)
        password_digest = create_user(username,password,admin)
        session[:error] = nil
        redirect("/")

      else
        session[:create_error] = "Passwords didn't match"
        redirect("/showregister")
      end
    
    else
      session[:create_error] = "Username already exist"
      redirect("/showregister")
    end

  else
    session[:create_error] = "Input username and password"
    redirect("/showregister")
  end
end

# Displays Main page
#
# @see model#medel_rating
# @see model#get_user_review_data
#
# @param [Integer] userid, User id

get("/movies") do
  userid = session[:id].to_i
  rating = medel_rating()
  user_reviews = get_user_review_data(userid)
  slim(:"movies/index", locals:{review:user_reviews})

end

# Dispaly create movie form

get('/movies/new') do

  slim(:"movies/new")
end

# Creates movie
#
# @see model#get_genres
# @see model#genres_that_are_checked
# @see model#search_file_ending
# @see model#add_movie
# @see model#get_movieid_from_user_id_and_movie_name
# @see model#add_genres_to_movie
#
# @param [Array] allgenre, All available genres
# @param [String] org_filename, img filename
# @param [String] movie_name, movies name
# @param [String] desc, movie description
# @param [String] dbpath, path to img string in database
# @param [Integer] user_id, User id
# @param [Array] genres_that_are_checked, all genres clicked in checkbox
# @param [Integer] movieid, Movie id
#
post("/movie/new") do
  movie_name = params[:movie_name]
  user_id = session[:id]  
  desc = params[:description]

  genres = get_genres()
  allgenre = Hash.new
  allgenre["action"] = params[:action]
  allgenre["horror"] = params[:horror]
  allgenre["drama"] = params[:drama]
  allgenre["romance"] = params[:romance]
  allgenre["comedy"] = params[:comedy]
  allgenre["science_fiction"] = params[:sciencefiction]

  genres_that_are_checked = genres_that_are_checked(allgenre)


  org_filename = params[:file][:filename]
  file_ending = search_file_ending(org_filename)
  filename = SecureRandom.uuid + file_ending 
  save_path = File.join("./public/img/uploaded_pictures/", filename)
  dbpath = File.join("/img/uploaded_pictures/", filename)

  FileUtils.cp(params[:file][:tempfile], "./public/img/uploaded_pictures/#{filename}")
  add_movie(movie_name, desc, dbpath, user_id)

  movieid = get_movieid_from_user_id_and_movie_name(movie_name,user_id)
  add_genres_to_movie(genres_that_are_checked, movieid[0][0])
  redirect("/users")
end

# Display admin page
#
# @see model#get_all_user_data
# @see model#get_all_review_data
# @see model#get_all_reviewd_movie_data
#
# @param [Integer] temp, Movie id

get('/admin') do

  all_user_data = get_all_user_data()
  all_review_data = get_all_review_data()


  #Hämtar data om filmerna som userna har gjort en review på
  reviewed_movie_data = []
  all_review_data.each do |rev|
    temp = rev["MovieId"]
    reviewed_movie_data << get_all_reviewed_movie_data(temp)

  end 
  slim(:admin, locals:{info:all_user_data, movie_review:reviewed_movie_data})
end

# Creats review
#
# @see model#create_review
#
# @param [String] title, Review titel
# @param [String] desc, review description
# @param [Integer] rating, review rating
# @param [Integer] movieId, Movie id
# @param [Integer] user_id, User id

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

# Display a genre
#
# @see model#get_user_review_data
# @see model#get_movies_with_genre
# @see model#get_genre_name_from_genre_id
# @see model#movies_with_genre
#
# @param [Integer] userid, User id
# @param [Integer] genre_id, genre id
# @param [Array] movies_with_genre,  All movies with genre id

post('/genres/show') do
  userid = session[:id].to_i
  user_reviews = get_user_review_data(userid)

  genre_id = params[:genre].to_i

  movies_with_genre = get_movies_with_genre(genre_id)
  genre_name = get_genre_name_from_genre_id(genre_id)
  
  movies = movies_with_genre(movies_with_genre)

  slim(:"movies/show",locals:{genre:genre_name, review:user_reviews, movies:movies})
end

# delete existing review and redirects to user
#
# @see model#delete_review
#
# @param [Integer] :id, review id

post('/reviews/:id/delete') do
  id = params[:id].to_i
  delete_review(id)
  redirect('/users')
end

# delete existing movie and redirects to user
#
# @see model#delete_movie
#
# @param [Integer] :id, movie id

post('/movies/:id/delete') do
  id = params[:id].to_i
  delete_movie(id)
  redirect('/users')
end

# delete existing user and redirects to login or if admin to admin panel
#
# @see model#delete_user
# @see model#get_admin_from_user
#
# @param [Integer] :id, user id

post('/users/:id/delete') do
  id = params[:id].to_i
  delete_user(id)

  if get_admin_info_from_user(session[:id])[0][0] == "true"
    redirect('/admin')
  end
  redirect('/')
end

# Displays review form 
#
# @see model#specific_movie
#
# @param [Integer] :id, movie id

get('/reviews/:id/new') do
  id = params[:id].to_i
  session[:movieId] = id
  result = specific_movie(id)
  slim(:"reviews/new",locals:{movie:result})
end

# Displays edit movies form
#
# @see model#specific_movie
#
# @param [Integer] :id, Movie id

get('/movies/:id/edit') do
  id = params[:id].to_i
  result = specific_movie(id)
  slim(:"movies/edit",locals:{result:result})
end

# Displays edit user form
#
# @see model#user_and_desc
#
# @param [Integer] :id, user id

get('/users/:id/edit') do
  id = params[:id].to_i
  result = user_and_desc(id)
  slim(:"users/edit",locals:{result:result})
end

# Displays edit reviews form
#
# @see model#review_movie
#
# @param [Integer] :id, Review id

get('/reviews/:id/edit') do
  id = params[:id].to_i
  result = review_movie(id)
  slim(:"reviews/edit",locals:{result:result})
end

# Edits movie redirecting to users
#
# @see model#get_genres
# @see model#genres_that_are_checked
# @see model#delete_movie_img
# @see model#search_file_ending
# @see model#update_dbpath
# @see model#update_movie
# @see model#edit_genres_to_movie
#
# @param [Array] allgenre, All available genres
# @param [String] org_filename, img filename
# @param [String] titel, Movie title
# @param [String] desc, Movie description
# @param [String] dbpath, path to img string in database
# @param [Integer] :id, movie id
# @param [Array] genres_that_are_checked, all genres clicked in checkbox
#

post('/movies/:id/edit') do
  id = params[:id].to_i
  title = params[:titel]
  desc = params[:desc]

  genres = get_genres()
  allgenre = Hash.new
  allgenre["action"] = params[:action]
  allgenre["horror"] = params[:horror]
  allgenre["drama"] = params[:drama]
  allgenre["romance"] = params[:romance]
  allgenre["comedy"] = params[:comedy]
  allgenre["science_fiction"] = params[:sciencefiction]

  genres_that_are_checked = genres_that_are_checked(allgenre)

  if params[:file] != ""
    delete_movie_img(id)
    org_filename = params[:file][:filename]
    file_ending = search_file_ending(org_filename)
    filename = SecureRandom.uuid + file_ending 
    save_path = File.join("./public/img/uploaded_pictures/", filename)
    dbpath = File.join("/img/uploaded_pictures/", filename)

    FileUtils.cp(params[:file][:tempfile], "./public/img/uploaded_pictures/#{filename}")
    update_dbpath(dbpath, id)
  end

  update_movie(title,id,desc)
  edit_genres_to_movie(genres_that_are_checked, id)
  redirect('/users')

end

# Edits review and redirects to user
#
# @see model#update_review
#
# @param [Integer] id, review id
# @param [String] titel, review title
# @param [String] desc, review description
# @param [Integer] rating, review rating

post('/reviews/:id/edit') do
  id = params[:id].to_i
  titel = params[:titel]
  desc = params[:desc]
  rating = params[:rating]
  update_review(id,titel,desc,rating)
  redirect('/users')

end

# Edits user and redirects to user
#
# @see model#update_user
#
# @param [Integer] id, user id
# @param [String] username, username
# @param [String] desc, users description
#

post('/users/:id/edit') do
  id = params[:id].to_i
  username = params[:username]
  desc = params[:desc]
  update_user(id,username,desc)
  redirect('/users')

end

