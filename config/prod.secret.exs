use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
config :swarm_brain, SwarmBrain.Endpoint, secret_key_base: "${SECRET_KEY_BASE}"
