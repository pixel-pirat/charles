defmodule VisoBackendWeb.ChangesetJSON do
  @moduledoc """
  Renders an invalid `Ecto.Changeset` as `%{errors: %{field: ["msg"]}}`
  — e.g. a registration attempt with a taken email.
  """

  def error(%{changeset: changeset}) do
    %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
  end

  # Only interpolates opts that are actually part of the message
  # template (e.g. "%{count}" for length validations) — some
  # validations (like unsafe_validate_unique's `fields: [:email]`)
  # carry opts that aren't meant to be stringified at all.
  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      if is_binary(value) or is_atom(value) or is_number(value) do
        String.replace(acc, "%{#{key}}", to_string(value))
      else
        acc
      end
    end)
  end
end
