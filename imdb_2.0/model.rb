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

  

  get("/movies") do
    id = session[:id].to_i
    db = SQLite3::Database.new("db/imdb.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM movie WHERE UserId = ?", id)
    p result
    slim(:"movies/index", locals:{movie:result})
  
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

def get_allinfo_from_user(userId);
  db = SQLite3::Database.new("db/imdb.db")
  db.results_as_hash = true
  user_review_data = db.execute('SELECT * FROM review WHERE userId = ?', userId).first
  user_movie_data = db.execute('SELECT * FROM movie WHERE userId = ?', userId).first
  user_data = db.execute('SELECT username,description From users Where Id = ? ', userId).first

  p user_review_data
  p user_movie_data
  p user_data

  #Validering om man inte har gjort en review eller en movie (För ERROR, hash NIL)

  if user_review_data == nil 
    if user_movie_data == nil
      result = user_data
      return result
    else
      result = user_movie_data.merge(user_data)
      return result
    end
  else
    if user_movie_data == nil
      result = user_review_data.merge(user_data)
      return result
    else
      temp = user_movie_data.merge(user_data)
      result = temp.merge(user_review_data)
      return result
    end
  end
end
