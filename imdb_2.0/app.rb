require 'sinatra'
require 'byebug'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

get('/') do
    slim(:"users/login")
end

get('/showregister') do
  slim(:register)

end

get('/users') do
  Userid = session[:id].to_i
  user_data = get_allinfo_from_user(Userid)
  p user_data
  slim(:"users/index", locals:{info:user_data})
end