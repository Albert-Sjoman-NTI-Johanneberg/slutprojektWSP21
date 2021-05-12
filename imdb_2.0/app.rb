require 'sinatra'
require 'byebug'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'
require 'fileutils'
require 'securerandom'

enable :sessions

# TO DO
# validate så man inte kan edita andras reviews/movies
# Admin. Kanske gör en i db 
# relationstabeller / genre 
# Yardoc
# projectplan.md beskriv ark
# cooldown o allmänna valideringar
# titta egenom namn givning
# ON DELTE CASCADE / kanske har gjort det redan




before do 
  # Validerar att du har loggat in
  p session[:id]
  if (session[:id] == nil) && (request.path_info != '/') && (request.path_info != '/login') && (request.path_info != '/showregister')
    session[:error] = "You have to log in to view this content"
    # p session[:error]
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
  username = params[:username]
  password = params[:password]

  result = get_info_user(username)

  pwdigest = result["pwdigest"]
  id = result["Id"]

  if password_check(pwdigest,password)
    session[:id] = id
    redirect("/movies")

  else
    "FEL LÖSENORD!!"
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
    reviewed_movie_data << getreviewed_movie_data(temp)

  end

  p reviewed_movie_data
  slim(:"users/index", locals:{info:user_data, movie:movie_data, review:review_data, movie_review:reviewed_movie_data})
end

post("/users/new") do 
  username = params[:username]
  password = params[:password]
  confirm_password = params[:confirm_password]
  
  temp = id_from_user(username)
  
  if temp.empty?
    if (password == confirm_password)
      password_digest = create_user(username,password)
      redirect("/")

    else
      redirect("/showregister")
    end
  
  else
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

get('/reviews/new') do

  slim(:"reviews/new")
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

get('/review/new/:id') do
  id = params[:id].to_i
  session[:movieId] = id
  result = specific_movie(id)
  slim(:"reviews/new",locals:{movie:result})
end

post('/review') do
  title = params[:review_name]
  desc = params[:description]
  rating = params[:rating].to_i
  movieId = session[:movieId]
  user_id = session[:id] 
  time = Time.now.to_i
  create_review(title, desc, rating, movieId, user_id)
  redirect('/users')
end

get('/movies/edit/:id') do
  id = params[:id].to_i
  result = specific_movie(id)
  slim(:"movies/edit",locals:{result:result})
end

get('/users/edit/:id') do
  id = params[:id].to_i
  result = user_and_desc(id)
  slim(:"users/edit",locals:{result:result})
end

get('/reviews/edit/:id') do
  id = params[:id].to_i
  result = review_movie(id)
  slim(:"reviews/edit",locals:{result:result})
end

post('/movies/edit/:id') do
  id = params[:id].to_i
  title = params[:titel]
  desc = params[:desc]
  update_movie(title,id,desc)
  redirect('/users')

end

post('/reviews/edit/:id') do
  id = params[:id].to_i
  titel = params[:titel]
  desc = params[:desc]
  rating = params[:rating]
  update_review(id,titel,desc,rating)
  redirect('/users')

end

post('/reviews/edit/delete/:id') do
  id = params[:id].to_i
  delete_review(id)
  redirect('/users')
end

post('/movies/edit/delete/:id') do
  id = params[:id].to_i
  delete_movie(id)
  redirect('/users')
end