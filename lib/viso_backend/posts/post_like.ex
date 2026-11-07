defmodule VisoBackend.Posts.PostLike do
  use Ecto.Schema

  schema "post_likes" do
    belongs_to :post, VisoBackend.Posts.Post
    belongs_to :user, VisoBackend.Accounts.User

    timestamps(type: :utc_datetime)
  end
end
