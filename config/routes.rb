Rails.application.routes.draw do
  resources :projects do
    resources :reminders do
      collection do
        get :search_issues
      end
    end
  end
end 
