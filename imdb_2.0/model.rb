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
    #result = db.execute("SELECT * FROM To_do WHERE UserId = ?", id)
    #p "Alla todosfrån resultat #{result}"
    slim(:"movies/index")#, locals:{todos:result})
  
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
      "lösenorden matchade inte"
    end
  
  else
    "Username already exist"
  end
end