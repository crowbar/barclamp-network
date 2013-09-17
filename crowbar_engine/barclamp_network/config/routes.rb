BarclampNetwork::Engine.routes.draw do

  # UI scope

  resources :networks

  #/api/v2/networks
  scope :defaults => {:format=> 'json'} do
    constraints( :id => /([a-zA-Z0-9\-\.\_]*)/, :version => /v[1-9]/ ) do
      scope 'api' do
        scope ':version' do
          resources :routers
          resources :ranges
          resources :allocations
          resources :networks do
            member do
              match 'ip'
              post 'allocate_ip'
            end
          end
        end
      end
    end
  end
end
