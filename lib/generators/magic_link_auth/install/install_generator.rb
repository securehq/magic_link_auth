require "rails/generators"
require "rails/generators/migration"

module MagicLinkAuth
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Copies MagicLinkAuth initializer and migrations to your application."

      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def copy_initializer
        copy_file "initializer.rb", "config/initializers/magic_link_auth.rb"
      end

      def copy_migrations
        migration_template(
          "../../../../../db/migrate/20260430000001_create_magic_link_auth_sessions.rb",
          "db/migrate/create_magic_link_auth_sessions.rb"
        )
        migration_template(
          "../../../../../db/migrate/20260430000002_create_magic_link_auth_token_denylists.rb",
          "db/migrate/create_magic_link_auth_token_denylists.rb"
        )
      end

      def show_readme
        readme "README" if behavior == :invoke
      rescue
        # README file is optional
      end

      def show_instructions
        say "\n"
        say "MagicLinkAuth installed!", :green
        say "\n"
        say "Next steps:", :bold
        say "  1. Run migrations:            bin/rails db:migrate"
        say "  2. Mount the engine in config/routes.rb:"
        say "       mount MagicLinkAuth::Engine, at: \"/auth\""
        say "  3. Include the concern in your User model:"
        say "       include MagicLinkAuth::Authenticatable"
        say "  4. Include the web concern in ApplicationController (optional):"
        say "       include MagicLinkAuth::Authentication"
        say "  5. Include the API concern in your API base controller (optional):"
        say "       include MagicLinkAuth::JwtAuthentication"
        say "  6. Edit config/initializers/magic_link_auth.rb with your settings."
        say "\n"
      end
    end
  end
end
