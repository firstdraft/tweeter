class Status < ActiveRecord::Base
  validates :user, :presence => true
  validates :content, :presence => true

  belongs_to :user
end
