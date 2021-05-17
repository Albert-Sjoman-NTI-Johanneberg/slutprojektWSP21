module Model

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

  def cooldown_timer(id, cooldown_minutes)
    attempts = get_attemps(id)
    recent_attempt = attempts[attempts.length - 1]
    temp = Time.now - Time.parse(recent_attempt[0])
    cooldown_time = cooldown_minutes*60 - temp
    return cooldown_time
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

    db.execute("DELETE FROM movie_genre_rel WHERE movie_id = ?", id)
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

  def get_user_data(userId);
    db = db_conect("db/imdb.db")
    user_data = db.execute('SELECT username,description,admin From users Where Id = ? ', userId).first
  end

  def update_user(id,username,desc)
    db = db_conect_without_hash("db/imdb.db")
    p id
    p username
    db.execute('UPDATE users SET username = ?, description = ? WHERE Id = ?',username,desc,id)
  end

  def delete_user(id)
    db = db_conect("db/imdb.db")
    
    #Deletes your reviews
    db.execute("DELETE FROM review WHERE UserId = ?", id)

    #Deletes movies and reviews conected to that movie
    img_path = db.execute("SELECT img, Id FROM movie WHERE UserId = ?", id)
    if img_path.empty? == false
      img_path.each do |img|
        if File.exist?("public#{img["img"]}")
          File.delete("public#{img["img"]}")
        end
        
        db.execute("DELETE FROM movie_genre_rel WHERE movie_id = ?", img["Id"])
        db.execute("DELETE FROM movie WHERE Id = ?", img["Id"])
        db.execute("DELETE FROM review WHERE MovieId = ?", img["Id"])      
      end
    end

    #Deletes User
    db.execute('DELETE FROM users WHERE Id = ?', id)
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
    result = db.execute("SELECT username, description, Id FROM users WHERE Id = ?", id).first
  end

  def get_user_movie_data(userId);
    db = db_conect("db/imdb.db")
    user_movie_data = db.execute('SELECT * FROM movie WHERE userId = ?', userId)
    
  end

  def get_user_review_data(userId);
    db = db_conect("db/imdb.db")
    user_review_data = db.execute('SELECT * FROM review WHERE userId = ?', userId)

  end


  def get_movies_with_genre(genre_id)
    db = db_conect_without_hash("db/imdb.db")
    movie_ids_with_genre = db.execute('SELECT movie_id FROM movie_genre_rel WHERE genre_id =?', genre_id)
   
    return movie_ids_with_genre
  end

  def get_genre_name_from_genre_id(genre_id)
    db = db_conect_without_hash("db/imdb.db")
    result = db.execute('SELECT Name FROM genre WHERE Id =?', genre_id)
    return result[0][0]

  end

  def movies_with_genre(movie_ids_with_genre)
    db = db_conect("db/imdb.db")
    result = []
    movie_ids_with_genre.each do |movie|

      temp = db.execute("SELECT * FROM movie WHERE Id =?", movie[0])
      result << temp[0]
    end
    return result
  end

  def get_genre_name_from_genre_id(genre_id)
    db = db_conect_without_hash("db/imdb.db")
    result = db.execute('SELECT Name FROM genre WHERE Id =?', genre_id)
    return result[0][0]

  end

  def get_genres()
    db = db_conect_without_hash("db/imdb.db")
    result = db.execute('SELECT Name FROM genre')
    return result
  end

  def genres_that_are_checked(allgenre)
    checked_boxes = []
    allgenre.each do |genre|
      p genre 
      if genre[1] == "on"
        checked_boxes << genre[0]
      end
    end
    p checked_boxes
    return checked_boxes
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

  def get_movieid_from_user_id_and_movie_name(movie_name,user_id)
    db = db_conect_without_hash("db/imdb.db")
    movie_id = db.execute('SELECT Id FROM movie WHERE Titel = ? AND UserId = ?', movie_name, user_id)
    return movie_id

  end

  def add_genres_to_movie(genres_that_are_checked, movieid)
    db = db_conect_without_hash("db/imdb.db")
    genres_that_are_checked.each do |genre|
      genre_id = db.execute('SELECT Id FROM genre WHERE Name = ?', genre)
      db.execute("INSERT INTO movie_genre_rel (movie_id, genre_id) VALUES (?,?)", movieid[0][0], genre_id[0][0])
    end
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
    movie = movies_from_db()
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

  
end


