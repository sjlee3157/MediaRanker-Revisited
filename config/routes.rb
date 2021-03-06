Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'works#root'

  get "/auth/:provider/callback", to: "sessions#create", as: 'login'
  delete "/logout", to: "sessions#destroy", as: "logout"

  resources :works
  post '/works/:id/upvote', to: 'works#upvote', as: 'upvote'

  resources :users, only: [:index, :show]
end




# Deprecated routes from before OAuth implementation:

# get '/login', to: 'sessions#login_form', as: 'login'
# post '/login', to: 'sessions#login'
# post '/logout', to: 'sessions#logout', as: 'logout'
