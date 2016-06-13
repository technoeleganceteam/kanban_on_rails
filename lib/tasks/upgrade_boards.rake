desc 'Upgrade projects to boards'
task :upgrade_boards => :environment do
  IssueToSectionConnection.find_each do |connection|
    next if connection.board.present?
  
    next unless connection.project.present?
  
    if (board = connection.project.boards.first).present?
      connection.update_attributes(:board_id => board.id)
    else
      board = connection.project.boards.create :name => connection.project.name,
        :column_width => connection.project.column_width, :column_height => connection.project.column_height

      connection.update_attributes(:board_id => board.id)
    end
  end

  Column.find_each do |column|
    next if column.board.present?

    next unless column.project.present?
    
    if (board = column.project.boards.first).present?
      if !(column.tags & board.columns.map(&:tags).flatten).present?
        column.update_attributes(:board_id => board.id) 
      end
    else
      board = column.project.boards.create :name => column.project.name,
        :column_width => column.project.column_width, :column_height => column.project.column_height

      if !(column.tags & board.columns.map(&:tags).flatten).present?
        column.update_attributes(:board_id => board.id)
      end
    end
  end

  Section.find_each do |section|
    next if section.board.present? 
  
    next unless section.project.present?

    if (board = section.project.boards.first).present?
      section.update_attributes(:board_id => board.id)
    else
      board = section.project.boards.create :name => section.project.name,
        :column_width => section.project.column_width, :column_height => section.project.column_height

      section.update_attributes(:board_id => board.id)
    end
  end

  Section.where(:board_id => nil).destroy_all

  Column.where(:board_id => nil).destroy_all

  IssueToSectionConnection.where(:board_id => nil).destroy_all

  Issue.all.map(&:save)
end
