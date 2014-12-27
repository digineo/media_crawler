# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

Server.create! \
  name:      'server A',
  addresses: '192.168.178.52'

Server.create! \
  name:      'chloe',
  addresses: '172.23.198.239'

Server.create! \
  name:      'tim',
  addresses: '172.23.198.152'
