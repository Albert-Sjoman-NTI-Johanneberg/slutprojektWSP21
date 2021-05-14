def get_info_user(username)
  db = db_conect("db/imdb.db")
  result = db.execute("SELECT * FROM users WHERE username = ?", username).first
end

def password_check(pwdigest,password)
  BCrypt::Password.new(pwdigest) == password
end

def time_allfail_user_login(id)

time = Time.now.to_s
db = db_conect("db/imdb.db")
db.execute('INSERT INTO logins_failed (time,Userid) Values (?,?)', time,id)

end

def get_attemps(id)
  db = db_conect_without_hash("db/imdb.db")
  times = db.execute('Select time FROM logins_failed WHERE Userid = ?', id)
  return times
end

def create_user(username,password,admin)
  password_digest = BCrypt::Password.create(password)
  db = db_conect_without_hash("db/imdb.db")
  db.execute('INSERT INTO Users (username,pwdigest,admin) VALUES (?,?,?)', username,password_digest,admin)
  password_digest = BCrypt::Password.create(password)
end

def id_from_user(username)
  db = db_conect_without_hash("db/imdb.db")
  ids = db.execute("SELECT Id FROM users WHERE username = ?", username)
  return ids
end

def get_admin_info_from_user(id)
  db = db_conect_without_hash("db/imdb.db")
  admin = db.execute("SELECT admin FROM users WHERE Id = ?", id)
  return admin
end

def update_movie(title,id,desc)
  db = db_conect_without_hash("db/imdb.db")
  db.execute('UPDATE movie SET titel = ?, Content = ? WHERE Id = ?',title,desc,id)
end

def update_review(id,titel,desc,rating)
  db = db_conect_without_hash("db/imdb.db")
  db.execute('UPDATE review SET Titel = ?, Content = ?, Rating = ? WHERE Id = ?',titel,desc,rating,id)
end

def delete_review(id)
  db = db_conect_without_hash("db/imdb.db")
  db.execute("DELETE FROM review WHERE Id = ?", id)

end

def delete_movie(id)
  db = db_conect_without_hash("db/imdb.db")
  img_path = db.execute("SELECT img FROM movie WHERE Id = ?", id)
  if File.exist?("public#{img_path[0][0]}")    
    File.delete("public#{img_path[0][0]}")
  end

  db.execute("DELETE FROM movie WHERE Id = ?", id)
  db.execute("DELETE FROM review WHERE MovieId = ?", id)
end

def db_conect_without_hash(data)
  db = SQLite3::Database.new(data)
  return db
end

def db_conect(data)
  db = SQLite3::Database.new(data)
  db.results_as_hash = true
  return db
end

def get_movies_from_db()
  db = db_conect("db/imdb.db")
  
  result = db.execute("SELECT * FROM movie")
end

def get_user_data(userId);
  db = db_conect("db/imdb.db")
  user_data = db.execute('SELECT username,description,admin From users Where Id = ? ', userId).first
end

def review_movie(id)
  db = db_conect("db/imdb.db")
  result = db.execute("SELECT * FROM review WHERE Id = ?", id).first
end

def specific_movie(id)
  db = db_conect("db/imdb.db")
  result = db.execute("SELECT * FROM movie WHERE Id = ?",id).first
end

def user_and_desc(id)
  db = db_conect("db/imdb.db")
  result = db.execute("SELECT username, description FROM users WHERE Id = ?", id).first
end

def get_user_movie_data(userId);
  db = db_conect("db/imdb.db")
  user_movie_data = db.execute('SELECT * FROM movie WHERE userId = ?', userId)
  
end

def get_user_review_data(userId);
  db = db_conect("db/imdb.db")
  user_review_data = db.execute('SELECT * FROM review WHERE userId = ?', userId)

end

def search_file_ending(original_filename)
  array = original_filename.split(".")
  result = "." + array[1]
  return result
end

def get_userid_from_movie(id)
  db = db_conect_without_hash("db/imdb.db")
  db.execute("SELECT UserId FROM movie WHERE Id=?",id)  
end

def get_userid_from_review(id)
  db = db_conect_without_hash("db/imdb.db")
  db.execute("SELECT UserId FROM review WHERE Id=?",id)  
end

def add_movie(movie_name, description, img_path, user_id) 
  db = db_conect("db/imdb.db")
  db.execute("INSERT INTO movie (Titel, Content, img, UserId) VALUES (?,?,?,?)",movie_name,description,img_path,user_id)
end

def create_review(title, desc, rating, movieId, user_id) 
  db = db_conect("db/imdb.db")
  db.execute("INSERT INTO review (Titel, Content, Rating, MovieId, UserId) VALUES (?,?,?,?,?)",title, desc, rating, movieId, user_id)
end

def getreviewed_movie_data(temp, userId)
  db = db_conect("db/imdb.db")
  reviewmovie_data = db.execute('SELECT * FROM movie WHERE Id = ?', temp)
  review_data = db.execute('SELECT * FROM review WHERE MovieId = ? AND userId = ?', temp, userId)
  temp2 = reviewmovie_data + review_data

  return temp2
end

def get_all_user_data() 
  db = db_conect("db/imdb.db")
  user_data = db.execute('SELECT username, description, Id, admin FROM users')
  return user_data
end

def get_all_review_data()
 db = db_conect("db/imdb.db")
 review_data = db.execute('SELECT * FROM review')
end

def get_all_reviewed_movie_data(temp)
  db = db_conect("db/imdb.db")
  reviewmovie_data = db.execute('SELECT * FROM movie WHERE Id = ?', temp)
  review_data = db.execute('SELECT * FROM review WHERE MovieId = ?', temp)
  data = reviewmovie_data + review_data

  return data
end


def medel_rating() 
  db = db_conect("db/imdb.db")
  total = 0.0
  i = 0
  movieId = []
  medel = []
  movie = get_movies_from_db()
  movie.each do |movie|
    movieId << movie["Id"]
  end

  movieId.each do |movie|
    all_rating_from_one_movie = db.execute('SELECT Rating FROM review WHERE MovieId = ?', movie) 
        
      all_rating_from_one_movie.each do |rating|

        temp = rating["Rating"]
        total += temp
        i += 1

      end

    if i != 0
      total = total / i
      total = total.round(1)
      db.execute('UPDATE movie SET Rating = ? WHERE Id = ?',total,movie)

    else
      total = 0
      db.execute('UPDATE movie SET Rating = ? WHERE Id = ?',total,movie)  
    end

    total = 0
    i = 0

  end
end


