BarclampNetwork::Engine.routes.draw do
  #"/api/v2/networks"
  scope :defaults => {:format=> 'json'} do
    constraints( :id => /([a-zA-Z0-9\-\.\_]*)/, :version => /v[1-9]/ ) do
      scope ':version' do
        resources :networks do
          member do
            post 'allocate_ip'
          end
        end
      end
    end
  end
end
