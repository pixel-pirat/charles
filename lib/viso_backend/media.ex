defmodule VisoBackend.Media do
  @moduledoc """
  Uploads raw bytes to Cloudflare R2 (S3-compatible) and returns a
  public URL — the one piece shared by avatar uploads, posts, stories,
  and chat attachments. Mirrors the old vibe_server's MediaEndpoint,
  which used Serverpod's built-in database-backed storage; R2 is the
  equivalent for this stack since Render's own filesystem doesn't
  persist across deploys.
  """

  @doc """
  Uploads `bytes` under a path namespaced by `user_id`, and returns its
  public URL. `file_extension` should be a plain extension like "jpg"
  or "mp4" (no leading dot).
  """
  def upload(user_id, bytes, file_extension) when is_binary(bytes) do
    safe_extension = String.replace(file_extension, ~r/[^a-zA-Z0-9]/, "")
    key = "media/#{user_id}/#{System.os_time(:microsecond)}.#{safe_extension}"

    config = r2_config()

    request =
      ExAws.S3.put_object(config.bucket, key, bytes,
        content_type: content_type_for(safe_extension)
      )

    case ExAws.request(request, ex_aws_config(config)) do
      {:ok, %{status_code: status}} when status in 200..299 ->
        {:ok, public_url(config, key)}

      {:ok, %{status_code: status, body: body}} ->
        {:error, "R2 upload failed (#{status}): #{inspect(body)}"}

      {:error, reason} ->
        {:error, "R2 upload failed: #{inspect(reason)}"}
    end
  end

  defp public_url(%{public_base_url: base_url}, key) when is_binary(base_url) do
    String.trim_trailing(base_url, "/") <> "/" <> key
  end

  defp public_url(%{public_base_url: nil}, _key) do
    raise """
    R2 public_base_url isn't configured yet. Enable public access on
    the bucket (R2 dashboard -> bucket -> Settings -> Public access),
    then set its pub-<hash>.r2.dev URL (or a custom domain) in
    config :viso_backend, :r2, public_base_url: "..."
    """
  end

  defp r2_config do
    Application.fetch_env!(:viso_backend, :r2) |> Map.new()
  end

  defp ex_aws_config(config) do
    [
      access_key_id: config.access_key_id,
      secret_access_key: config.secret_access_key,
      host: "#{config.account_id}.r2.cloudflarestorage.com",
      scheme: "https://",
      region: "auto"
    ]
  end

  defp content_type_for(extension) do
    case String.downcase(extension) do
      "jpg" -> "image/jpeg"
      "jpeg" -> "image/jpeg"
      "png" -> "image/png"
      "gif" -> "image/gif"
      "webp" -> "image/webp"
      "mp4" -> "video/mp4"
      "mov" -> "video/quicktime"
      "m4a" -> "audio/mp4"
      "mp3" -> "audio/mpeg"
      _ -> "application/octet-stream"
    end
  end
end
