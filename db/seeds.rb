# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

["alice", "bob", "carol"].each do |name|
  user = User.new
  user.username = name
  user.email = "#{name}@example.com"
  user.password = "12341234"
  user.password_confirmation = "12341234"
  user.save
end

7.times do
  user = User.new
  name = Faker::Name.first_name
  user.username = Faker::Internet.user_name(name)
  user.email = Faker::Internet.safe_email(name)
  user.password = "12341234"
  user.password_confirmation = "12341234"
  user.save
end

User.all.each do |user|
  rand(10..30).times do
    status = Status.new
    status.user_id = user.id
    status.content = Faker::Hacker.say_something_smart
    status.created_at = Faker::Time.between(1.year.ago, Time.now)
    status.save
  end
end
