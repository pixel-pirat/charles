defmodule VisoBackend.Repo.Migrations.AddProfileFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :image_url, :string
      add :bio, :string, size: 280
    end
  end
end
