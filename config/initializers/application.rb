#
# Wo sollen generierte Daten abgelegt werden (insb. PDF-Dateien)?
#
config = Rails.application.config
if Rails.env.test?
  config.data_root = Rails.root.join('tmp/data')
else
  config.data_root = Rails.root.join('public/data')
end
