module MagicLinkAuth
  class ApplicationMailer < ActionMailer::Base
    default from: -> { MagicLinkAuth.configuration.resolved_mailer_from }
    layout "mailer"
  end
end
