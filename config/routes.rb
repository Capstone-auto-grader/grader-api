Rails.application.routes.draw do
  resources :containers
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  post '/grade', to: 'test#runtests'
  post '/batch', to: 'test#batchfile'
  post '/moss', to: 'test#moss'
  get '/get_container_from_name', to: 'containers#get_id_from_name'
end
