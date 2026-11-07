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
