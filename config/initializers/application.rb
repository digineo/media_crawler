#
# Wo sollen generierte Daten abgelegt werden (insb. PDF-Dateien)?
#
config = Rails.application.config
if Rails.env.test?
  config.data_root        = Rails.root.join('tmp/data')
  config.public_data_root = Rails.root.join('tmp/public_data')
else
  config.data_root        = Rails.root.join('data')
  config.public_data_root = Rails.root.join('public/data')
end
