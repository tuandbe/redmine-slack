Rails.application.routes.draw do
  resources :projects do
    resources :reminders
  end
end 
