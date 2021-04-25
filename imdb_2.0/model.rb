post('/login') do
    username = params[:username]
    password = params[:password]
  
    db = SQLite3::Database.new("db/imdb.db")
    db.results_as_hash = true
  
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first
    
    pwdigest = result["pwdigest"]
    id = result["Id"]
  
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      redirect("/movies")
  
    else
      "FEL LÖSENORD!!"
    end
  
  end




post("/users/new") do 
  username = params[:username]
  password = params[:password]
  confirm_password = params[:confirm_password]
  
  db = SQLite3::Database.new("db/imdb.db")
  temp = db.execute("SELECT Id FROM users WHERE username = ?", username)
  
  if temp.empty?
    if (password == confirm_password)
      password_digest = BCrypt::Password.create(password)
      db.execute('INSERT INTO Users (username,pwdigest) VALUES (?,?)', username,password_digest)
      redirect("/")

    else
      redirect("/showregister")
    end
  
  else
    redirect("/showregister")
  end
end


def get_movies_from_db(id)
  db = SQLite3::Database.new("db/imdb.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM movie WHERE UserId = ?", id)
end

def get_user_data(userId);
  db = SQLite3::Database.new("db/imdb.db")
  db.results_as_hash = true
  user_data = db.execute('SELECT username,description From users Where Id = ? ', userId).first

  p user_data
end

def get_user_movie_data(userId);
  db = SQLite3::Database.new("db/imdb.db")
  db.results_as_hash = true
  user_movie_data = db.execute('SELECT * FROM movie WHERE userId = ?', userId)
  
  p user_movie_data
end

def get_user_review_data(userId);
  db = SQLite3::Database.new("db/imdb.db")
  db.results_as_hash = true
  user_review_data = db.execute('SELECT * FROM review WHERE userId = ?', userId)

  p user_review_data
end

def search_file_ending(original_filename)
  array = original_filename.split(".")
  result = "." + array[1]
  return result
end


def add_movie(movie_name, description, img_path, user_id) 
  db = SQLite3::Database.new("db/imdb.db")
  db.results_as_hash = true
  db.execute("INSERT INTO movie (Titel, Content, img, UserId) VALUES (?,?,?,?)",movie_name,description,img_path,user_id)
end