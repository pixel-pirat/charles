defmodule VisoBackendWeb.Router do
  use VisoBackendWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug VisoBackendWeb.ApiAuthPlug
  end

  # Unauthenticated, outside the :api pipeline — just a plain 200 for
  # Render's health check, nothing JSON-related needed.
  get "/health", VisoBackendWeb.HealthController, :show

  scope "/api", VisoBackendWeb do
    pipe_through :api

    post "/register", AuthController, :register
    post "/login", AuthController, :login
  end

  scope "/api", VisoBackendWeb do
    pipe_through [:api, :api_auth]

    delete "/logout", AuthController, :logout
    get "/me", AuthController, :me
    patch "/me", AuthController, :update_profile

    # Order matters: "/search" must be matched before "/:id" below, or
    # Phoenix will treat "search" as a user id.
    get "/users/search", UsersController, :search
    get "/users/:id", UsersController, :show

    post "/media", MediaController, :upload

    # Order matters: static segments ("feed", "mine") before "/:id/...".
    get "/posts/feed", PostsController, :feed
    get "/posts/mine", PostsController, :mine
    post "/posts", PostsController, :create
    post "/posts/:id/like", PostsController, :like
    post "/posts/:id/view", PostsController, :view

    post "/stories", StoriesController, :create
    get "/stories", StoriesController, :feed
    post "/stories/:id/view", StoriesController, :mark_viewed

    get "/chat/conversations", ChatController, :conversations
    get "/chat/conversations/archived", ChatController, :archived_conversations
    post "/chat/conversations/:partner_id/read", ChatController, :mark_read

    get "/chat/messages/:partner_id", ChatController, :messages
    post "/chat/messages", ChatController, :send_message
    post "/chat/messages/:id/forward", ChatController, :forward
    patch "/chat/messages/:id", ChatController, :edit
    delete "/chat/messages/:id", ChatController, :delete
    post "/chat/messages/:id/delete_for_me", ChatController, :delete_for_me
    post "/chat/messages/:id/react", ChatController, :react

    get "/chat/blocks", ChatController, :blocked_users
    post "/chat/blocks/:user_id", ChatController, :block
    delete "/chat/blocks/:user_id", ChatController, :unblock

    post "/chat/mutes/:partner_id", ChatController, :mute
    delete "/chat/mutes/:partner_id", ChatController, :unmute
    post "/chat/pins/:partner_id", ChatController, :pin
    delete "/chat/pins/:partner_id", ChatController, :unpin
    post "/chat/archives/:partner_id", ChatController, :archive
    delete "/chat/archives/:partner_id", ChatController, :unarchive

    get "/chat/stars", ChatController, :starred_messages
    post "/chat/stars/:message_id", ChatController, :star
    delete "/chat/stars/:message_id", ChatController, :unstar
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:viso_backend, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: VisoBackendWeb.Telemetry
    end
  end
end
