# MagicLinkAuth

A mountable Rails engine that adds **passwordless magic-link authentication** to any Rails application — with no passwords, no OAuth dependencies, and no lock-in.

Drop it in, mount the engine, run one generator, and your app gains:

- A complete **web sign-in flow** (cookie-based sessions, Hotwire-friendly)
- A complete **API/mobile sign-in flow** (stateless JWT, single-use tokens)
- **Deep-link support** for iOS (Universal Links) and Android (App Links)
- A **token denylist** for immediate revocation of JWTs and spent magic links
- Fully **overridable views** for total control over the look and feel

---

## Why passwordless?

Passwords are the leading cause of account takeovers. Users forget them, reuse them across sites, and write them on sticky notes. Password reset flows are just passwordless auth with extra steps — so why not skip straight to the end?

Magic links are:

- **Safer** — there is no password to steal, leak, or brute-force
- **Simpler** — no registration form, no "confirm password" field, no reset flow to build
- **Better UX** — one tap in an email gets the user in, on any device
- **Easy to audit** — every sign-in is a single-use token with an expiry and a denylist entry

MagicLinkAuth gives you all of this as a self-contained Rails engine. The engine owns its own tables and routes; your app keeps owning users.

---

## How it works

```
User enters email
       │
       ▼
POST /auth/session
       │  Engine looks up your User model
       │  Encodes a short-lived JWT (default: 15 min) with purpose: "magic_link"
       │  Sends email via ActionMailer
       ▼
User clicks link in email
       │
       ├─── Web browser ──────────────────────────────────────────────────┐
       │    GET /auth/session/verify?token=…                              │
       │    Token validated (not expired, not denylisted, right purpose)  │
       │    "Open in app" page rendered (with deep-link redirect)         │
       │                                                                  │
       └─── Mobile app ────────────────────────────────────────────────── ┘
            POST /auth/api/session/verify  { session: { token: "…" } }
            Token validated + immediately denylisted (single-use)
            Long-lived API JWT returned (default: 7 days)
            App stores JWT, sends as Bearer token on every request
```

---

## Quick start

### 1. Add the gem

```ruby
# Gemfile
gem "magic_link_auth", github: "securehq/magic_link_auth"
# or, once published:
gem "magic_link_auth"
```

```bash
bundle install
```

### 2. Mount the engine

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount MagicLinkAuth::Engine, at: "/auth"
  # …rest of your routes
end
```

### 3. Run the install generator

```bash
bin/rails generate magic_link_auth:install
bin/rails db:migrate
```

This copies the engine's migrations (creating `magic_link_auth_sessions` and `magic_link_auth_token_denylists`) and creates a commented initializer at `config/initializers/magic_link_auth.rb`.

### 4. Include the concerns

Add the authentication concerns to your controllers and user model:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include MagicLinkAuth::Authentication
  # …
end
```

```ruby
# app/controllers/api/base_controller.rb  (or whatever your API base is)
class Api::BaseController < ActionController::API
  include MagicLinkAuth::JwtAuthentication
  # …
end
```

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include MagicLinkAuth::Authenticatable
  # …
end
```

That's it. Your app now has fully working magic-link sign-in at `/auth/session/new`.

---

## Configuration

All configuration lives in an initializer. Every option has a sensible default — you only need to set what differs from those defaults.

```ruby
# config/initializers/magic_link_auth.rb
MagicLinkAuth.configure do |config|
  # …
end
```

### User model

| Option | Default | Description |
|---|---|---|
| `user_class` | `"User"` | String class name of your user model. Change this if your model is `Account`, `Member`, etc. |
| `user_lookup_by` | `:email` | The attribute used to find a user when they submit the sign-in form. Must be a unique attribute on the model. |

```ruby
config.user_class    = "Account"
config.user_lookup_by = :email_address
```

### Tokens & expiry

| Option | Default | Description |
|---|---|---|
| `jwt_secret` | `nil` | HMAC-SHA256 signing secret for all JWTs. When `nil`, falls back to `Rails.application.credentials.api_jwt_secret`. **Never commit this value.** Use Rails credentials or an environment variable. |
| `token_expiry` | `15.minutes` | How long a magic-link token stays valid after it is issued. Keep this short — the link is single-use anyway. |
| `session_expiry` | `7.days` | Lifetime of the long-lived API JWT returned after a successful mobile verify. |

```ruby
config.jwt_secret    = Rails.application.credentials.dig(:magic_link, :secret)
config.token_expiry  = 10.minutes
config.session_expiry = 30.days
```

**JWT secret resolution order:**
1. `config.jwt_secret` (explicit)
2. `Rails.application.credentials.api_jwt_secret`
3. Raises at boot if neither is set

### Email

| Option | Default | Description |
|---|---|---|
| `mailer_from` | `nil` | The "From" address for magic-link emails. When `nil`, falls back to `ENV["MAILER_FROM"]`, then `"no-reply@example.com"`. |
| `mailer_subject` | `"Your sign-in link"` | Subject line of the magic-link email. Shown verbatim in the recipient's inbox — make it clear and recognisable. |
| `app_name` | `"My App"` | Your application's display name, used in email copy and views. |

```ruby
config.mailer_from    = "hello@myapp.com"
config.mailer_subject = "Sign in to MyApp"
config.app_name       = "MyApp"
```

### Web session cookie

| Option | Default | Description |
|---|---|---|
| `session_cookie_name` | `"magic_link_session_id"` | Name of the signed cookie that stores the web session ID. Change this if you need to preserve an existing cookie name when migrating from another auth system. |

```ruby
config.session_cookie_name = "myapp_session"
```

### Deep links (mobile)

These options enable iOS Universal Links and Android App Links so that clicking a magic-link email on a mobile device opens your app directly instead of the browser.

Set `deep_link_scheme` to enable the feature. Leave it `nil` (the default) to skip all deep-link and `.well-known` routes entirely.

| Option | Default | Description |
|---|---|---|
| `deep_link_scheme` | `nil` | Your app's URL scheme or Universal Link host segment. Example: `"myapp"` produces deep links like `myapp://session/verify?token=…`. Set to `nil` to disable. |
| `ios_app_id` | `nil` | Your iOS App ID in `TEAMID.BUNDLE_ID` format. Served in `/.well-known/apple-app-site-association`. |
| `android_package` | `nil` | Your Android package name. Served in `/.well-known/assetlinks.json`. |
| `android_sha256_fingerprints` | `[]` | Array of SHA-256 certificate fingerprints for your Android signing key(s). Required for App Links verification. |

```ruby
config.deep_link_scheme             = "myapp"
config.ios_app_id                   = "ABCDE12345.com.example.myapp"
config.android_package              = "com.example.myapp"
config.android_sha256_fingerprints  = ["AA:BB:CC:…"]
```

When `deep_link_scheme` is set, the engine automatically serves:

- `GET /auth/.well-known/apple-app-site-association` — used by iOS to verify Universal Links
- `GET /auth/.well-known/assetlinks.json` — used by Android to verify App Links

---

## Routes reference

All engine routes are nested under the mount point (e.g. `/auth`).

### Web (cookie session)

| Method | Path | Description |
|---|---|---|
| `GET` | `/auth/session/new` | Sign-in form |
| `POST` | `/auth/session` | Submit email, send magic link |
| `GET` | `/auth/session/magic_link_sent` | Confirmation screen shown after submission |
| `GET` | `/auth/session/verify?token=…` | Validate token, render deep-link redirect page |
| `DELETE` | `/auth/session` | Sign out (destroys session cookie and DB record) |

### API / mobile (JWT)

| Method | Path | Description |
|---|---|---|
| `POST` | `/auth/api/session` | Request a magic link for the given email |
| `POST` | `/auth/api/session/verify` | Exchange magic-link token for a long-lived Bearer JWT |
| `DELETE` | `/auth/api/session` | Revoke current Bearer token (sign out) |

### Route helpers in host-app code

Because the engine uses `isolate_namespace`, its route helpers are namespaced. Prefix them with `magic_link_auth.` in your views and controllers:

```erb
<%= link_to "Sign in", magic_link_auth.new_session_path %>
<%= button_to "Sign out", magic_link_auth.session_path, method: :delete %>
```

---

## Protecting controllers

### Web controllers

`include MagicLinkAuth::Authentication` in `ApplicationController` applies `before_action :require_authentication` globally. Unauthenticated requests are redirected to the sign-in page, with the original URL saved for post-login redirect.

To allow unauthenticated access to specific actions:

```ruby
class WelcomeController < ApplicationController
  allow_unauthenticated_access only: :index
end
```

The current user is available anywhere as `MagicLinkAuth::Current.user`. If you prefer the bare constant `Current`, add an alias after initialisation:

```ruby
# config/initializers/magic_link_auth.rb
Rails.application.config.after_initialize do
  Current = MagicLinkAuth::Current unless defined?(Current)
end
```

### API controllers

`include MagicLinkAuth::JwtAuthentication` in your API base controller applies `before_action :authenticate_request` globally. Requests without a valid `Authorization: Bearer <token>` header receive a `401 Unauthorized` JSON response.

The current user is available as `current_user` (an instance variable set by the concern):

```ruby
class Api::V1::PostsController < Api::BaseController
  def index
    render json: current_user.posts
  end
end
```

To skip authentication on specific actions:

```ruby
class Api::V1::PublicController < Api::BaseController
  skip_authentication only: :index
  # or the alias:
  allow_unauthenticated_access only: :index
end
```

---

## Customising views

The engine ships with functional, unstyled HTML views. You will almost certainly want to replace them with views that match your application's design.

### Override individual views

Copy any engine view into your application under the same relative path and Rails will use your version automatically:

```
app/views/magic_link_auth/sessions/new.html.erb           # sign-in form
app/views/magic_link_auth/sessions/magic_link_sent.html.erb  # "check your email" screen
app/views/magic_link_auth/sessions/open_in_app.html.erb   # deep-link redirect page
app/views/magic_link_auth/magic_link_mailer/login_link.html.erb  # email (HTML)
app/views/magic_link_auth/magic_link_mailer/login_link.text.erb  # email (plain text)
```

You only need to copy the files you want to change — the engine provides fallbacks for any you leave out.

### Sign-in form (`new.html.erb`)

The minimum required markup: a form that `POST`s to `magic_link_auth.session_path` with an `email` field.

```erb
<%= form_with url: magic_link_auth.session_path do |f| %>
  <%= f.email_field :email, placeholder: "you@example.com", autofocus: true %>
  <%= f.submit "Send sign-in link" %>
<% end %>
```

You have full control over layout, styling, and copy. The engine's own action handles the rest.

### "Check your email" screen (`magic_link_sent.html.erb`)

Rendered after a user submits the form, regardless of whether the email exists (to prevent user enumeration). No instance variables are set — it is a static confirmation page.

### Deep-link redirect page (`open_in_app.html.erb`)

Rendered when the web `verify` endpoint receives a valid token. One instance variable is available:

| Variable | Value | Present when |
|---|---|---|
| `@app_deep_link` | Full deep-link URL, e.g. `myapp://session/verify?token=…` | `deep_link_scheme` is configured |

Use `@app_deep_link` to render a button that opens the native app, or an inline script that attempts to redirect automatically:

```erb
<% if @app_deep_link %>
  <a href="<%= @app_deep_link %>">Open in the app</a>
<% else %>
  <p>You may close this tab.</p>
<% end %>
```

### Email templates

Both HTML and plain-text variants are rendered by `MagicLinkAuth::MagicLinkMailer`. The following instance variables are available in both:

| Variable | Value |
|---|---|
| `@user` | The user record (your model instance) |
| `@token` | The raw magic-link JWT string |
| `@verify_url` | Full URL to the web verify endpoint, with token embedded |
| `@expiry_minutes` | Token lifetime in minutes (derived from `config.token_expiry`) |

```erb
<%# app/views/magic_link_auth/magic_link_mailer/login_link.html.erb %>
<p>Hi <%= @user.email %>,</p>
<p>
  <%= link_to "Sign in to #{MagicLinkAuth.configuration.app_name}", @verify_url %>
</p>
<p>This link expires in <%= @expiry_minutes %> minutes and can only be used once.</p>
```

### Using a custom layout

To wrap engine views in your own application layout, create an `ApplicationController` override inside a `magic_link_auth` directory:

```ruby
# app/controllers/magic_link_auth/application_controller.rb
module MagicLinkAuth
  class ApplicationController < MagicLinkAuth::ApplicationController
    layout "application"  # or whatever your layout is called
  end
end
```

---

## The `MagicLinkAuth::Authenticatable` concern

Including this concern in your user model adds:

- `has_many :magic_link_sessions` — the user's active web sessions (`MagicLinkAuth::Session` records)
- `normalizes :email` — strips whitespace and downcases before saving
- `validates :email, presence: true, uniqueness: { case_sensitive: false }`

If your model already has email validations, you can omit the concern and wire up the `has_many` yourself:

```ruby
class User < ApplicationRecord
  has_many :magic_link_sessions,
           class_name:  "MagicLinkAuth::Session",
           foreign_key: :user_id,
           dependent:   :destroy
end
```

---

## Token security model

### Magic-link tokens

- Encoded as HS256 JWTs signed with your `jwt_secret`
- Carry a `purpose: "magic_link"` claim — a regular API token is **never** accepted as a magic link
- Short-lived (default 15 minutes)
- **Single-use**: immediately added to `magic_link_auth_token_denylists` upon redemption via the API verify endpoint
- The web `verify` endpoint does **not** consume the token; it only validates and renders the deep-link page. The native app is responsible for calling the API verify endpoint, which performs consumption.

### API tokens (JWT Bearer)

- Long-lived (default 7 days)
- Carry a `jti` (JWT ID) UUID claim used for revocation
- Revoked immediately via `DELETE /auth/api/session`; the `jti` is added to the denylist
- Every `decode` call checks the denylist — a token cannot be used after revocation even if not yet expired

### Denylist maintenance

Spent and revoked tokens accumulate in `magic_link_auth_token_denylists`. Clean them up periodically with:

```ruby
MagicLinkAuth::TokenDenylist.cleanup_expired!
```

This deletes all rows whose `exp` timestamp is in the past. Run it from a scheduled job (e.g. Solid Queue, Sidekiq, or a cron task):

```ruby
# app/jobs/cleanup_expired_tokens_job.rb
class CleanupExpiredTokensJob < ApplicationJob
  def perform
    MagicLinkAuth::TokenDenylist.cleanup_expired!
  end
end
```

---

## Tables created

### `magic_link_auth_sessions`

Tracks active web sessions. Created when a user completes the web flow; destroyed on sign-out.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | Primary key |
| `user_id` | bigint | Foreign key to your users table |
| `user_agent` | string | Browser user-agent string |
| `ip_address` | string | Request remote IP |
| `created_at` | datetime | |
| `updated_at` | datetime | |

### `magic_link_auth_token_denylists`

Revocation list for magic-link tokens and API JWTs.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | Primary key |
| `jti` | string | JWT ID claim; indexed, unique |
| `exp` | datetime | Token expiry; indexed for efficient cleanup |
| `created_at` | datetime | |
| `updated_at` | datetime | |

---

## Development

```bash
git clone https://github.com/securehq/magic_link_auth
cd magic_link_auth
bundle install
bin/rails db:test:prepare
bin/rails test
```

To test the engine against a host application, add the gem via a local path as shown in the Quick start section.

---

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/securehq/magic_link_auth.

---

## License

MIT
