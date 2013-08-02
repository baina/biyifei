# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_biyifeidemo_session',
  :secret      => 'ca4993ae1028479bd48260f48ffba93dde81753cac6988b0726e5a4a6cd3eef24dcddef1adc077cca925f7e067d0f4919bda9dc6d0d2dd0de08ca1a2f54705d7'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
