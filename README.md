# Tweeter

In this project, we'll learn how to build a social network. It will be a simple clone of Twitter.

To get started, we'll create Users with Devise and Statuses (tweets) with Starter Generators. A user has many statuses, a status belongs to a user.

## So Far

The steps I took so far in the application are:

 1. `rails new tweeter`
 1. Add the `devise` and `starter_generators` gems to the `Gemfile`.
 1. `rails generate devise:install`
 1. `rails generate devise user username`
 1. `rails generate starter:resource status content:string user_id:integer`
 1. `rake db:migrate`
 1. `rails generate starter:style default`
 1. Set the homepage `root 'statuses#index'` in `config/routes.rb`.
 1. Force someone to be signed in at all times in `app/controllers/application_controller.rb`:

        before_action :authenticate_user!

 1. `rails generate devise:views`
 1. Add an input for username to both `app/views/devise/registrations/new.html.erb` and `app/views/devise/registrations/edit.html.erb`:

        <div class="field">
          <%= f.label :username %><br />
          <%= f.text_field :username %>
        </div>

 1. Allow username through security in `app/controllers/application_controller.rb`:

        before_action :configure_permitted_parameters, if: :devise_controller?

        protected

        def configure_permitted_parameters
          devise_parameter_sanitizer.for(:sign_up) << :username

          devise_parameter_sanitizer.for(:account_update) << :username
        end

 1. Add one-to-many associations:
  1. User has many statuses, Status belongs to user.
 1. Add validations:
  1. User usernames should be unique.
  1. Status content should be present.
  1. Status user should be present.
 1. Automatically associate statuses to signed-in user: remove `user_id` `<input>` from users#new and users#edit forms, and instead assign directly in the `create` and `update` actions:

        @status.user_id = current_user.id
        @status.content = params[:content]

 1. Replace raw foreign keys with usernames in `statuses#index` and `statuses#show`.
 1. Fix the navbar to show sign-out and edit profile links at the appropriate time in `app/views/layouts/application.html.erb`.
 1. Some visual formatting; replaced Pinterest-style layout with a simple table.

## Setup

 1. Clone.
 1. `bundle install`
 1. `rake db:migrate`
 1. `rake db:seed`
 1. `rails server`
 1. Open the code in Sublime.
 1. Go to [http://localhost:3000](http://localhost:3000) in Chrome.
 1. Sign in with the user "alice@example.com", password "12341234".
 1. You should see a list of random tweets.

## Adding Friend Requests

At this stage, we have an app where users can sign in and add statuses, but the index page just shows a list of all statuses globally.

What we want instead is the ability for users to follow other users, and narrow the index of statuses to only show the ones that belong to people that I follow.

So, we need a many-to-many relationship between Users and Users. Like any many-to-many, this means we need a join model, which will have two foreign key columns, and we'll establish two one-to-many relationships first.

## Generate the join model

I'm going to call the join model "friend requests". Each row in this table will represent the connection between two users.

```bash
rails generate starter:resource friend_request sender_id:integer receiver_id:integer
```

Notice that since I can't have two columns both called `user_id`, I've made up two different and descriptive column names instead.

Next, as usual, we should immediately add our validations and one-to-many relationships:

```ruby
# app/models/friend_request.rb
belongs_to :sender, :class_name => "User", :foreign_key => "sender_id"

belongs_to :receiver, :class_name => "User", :foreign_key => "receiver_id"

validates :sender, :presence => true, :uniqueness => { :scope => :receiver }
validates :receiver, :presence => true
```

Notice the uniqueness validation on `:sender` ensures that you can't accidentally follow the same person twice.

The associations in `FriendRequest` are pretty straightforward; we just have to use the non-shortcut form of `belongs_to` so that we can specify a column name that's different from the default for each one-to-many.

The `has_many`s in `User` are slightly trickier, but not bad:

```ruby
# app/models/user.rb
has_many :friend_requests_where_sender, :class_name => "FriendRequest", :foreign_key => "sender_id"

has_many :friend_requests_where_receiver, :class_name => "FriendRequest", :foreign_key => "receiver_id"
```

So, now each `User` has many `friend_requests_where_sender` as well as many `friend_requests_where_receiver`.

The last step is to establish the many-to-many on top of these two one-to-manies:

```ruby
# app/models/user.rb
has_many :friend_requests_where_sender, :class_name => "FriendRequest", :foreign_key => "sender_id"

has_many :friends_where_sender, :through => :friend_requests_where_sender, :source => :receiver


has_many :friend_requests_where_receiver, :class_name => "FriendRequest", :foreign_key => "receiver_id"

has_many :friends_where_receiver, :through => :friend_requests_where_receiver, :source => :sender
```

So we're saying: when someone calls `.friends_where_receiver` on me, walk through the `friend_requests` table to find the people who sent me requests (in other words, my followers). Vice versa when someone calls `.friends_where_sender` (in other words, people that I follow).

Finally, let's set up one more `:through` association to make our lives really easy:


```ruby
# app/models/user.rb
has_many :timeline_statuses, :through => :friends_where_sender, :source => :statuses
```

This additional method will walk directly through the people that I follow to their statuses, which is the main thing that we want.

That's it for the setup. Now let's use these powerful associations to make our app do what we want:

 1. On the `friend_requests#new` form, let's get rid of the `<input>` for `sender_id` and instead associate it automatically in the `create` and `update` actions to `current_user`.
 1. Narrow the `statuses#index` to only show statuses from people that the current user is following:

        def index
          @statuses = current_user.timeline_statuses.order("created_at DESC")
        end

That's it! If you want to, you can also place a follower count (`current_user.friends_where_receiver.count`) and following count (`current_user.friends_where_sender.count`) in a sidebar or something.

## Solutions

A completed version is [here](../../../tweeter_solutions).
