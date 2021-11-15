# frozen_string_literal: true

class CreateJobs < ActiveRecord::Migration[5.2]
  def change
    create_table :jobs do |t|
      t.string :aasm_state, index: true
      t.string :priority, index: true
      t.string :name
      t.timestamps
    end
  end
end
