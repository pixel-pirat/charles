defmodule VisoBackendWeb.MediaController do
  use VisoBackendWeb, :controller

  alias VisoBackend.Media

  @doc """
  POST /api/media (multipart form, field "file") — uploads a photo,
  video, or voice note and returns its public URL. Used for avatars,
  posts, stories, and chat attachments; the caller uploads here first,
  then passes the returned URL to e.g. POST /api/posts.
  """
  def upload(conn, %{"file" => %Plug.Upload{} = upload}) do
    bytes = File.read!(upload.path)
    extension = upload.filename |> Path.extname() |> String.trim_leading(".")

    case Media.upload(conn.assigns.current_user.id, bytes, extension) do
      {:ok, url} ->
        conn |> put_status(:created) |> json(%{url: url})

      {:error, reason} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: reason})
    end
  end

  def upload(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "expected a multipart form with a \"file\" field"})
  end
end
