class Setting < ActiveRecord::Base
  attr_accessor :categories_attributes
  attr_accessible :name,:status,:categories_attributes
  belongs_to :client

  def set_cutoff(percentages)
    self.client.categories.all.each do |cat|
        cat.update_attribute(:cutoff,percentages[cat.id.to_s].to_i)
      end
  end
end
